/*
begin tran
exec sp_AggregateOrders 4483,'HZCG201301030046','2013-01-02','2013-01-02','2'
rollback
commit
begin tran
exec sp_AggregateOrders 1509,'CR20130107000006','2012-12-31','2012-12-31','2'
rollback
commit
select * from T_AggregateResult tar with(nolock)
 select * from T_AggregateResult tar where tar.PurchaseOrderDoccode ='CG20130100000286'
 select * from _sysInstances si where si.InstanceID='DE98658F-4487-4DDA-A1EB-1E5130371B0F'
*/

alter proc sp_AggregateOrders
	@FormID int,
	@Doccode varchar(50),
	@BeginDate datetime='',
	@EndDate datetime='',
	@OptionID varchar(200)=''
as
	BEGIN
		set NOCOUNT on;
		set XACT_ABORT on;
		declare @sql_Doccode varchar(max),@sql nvarchar(max),@msg varchar(max),@NewDoccode varchar(50),@Trancount int
		declare @vndCode varchar(50),@Price money,@taxRate money,@Refcode varchar(50)
		declare @Ordering_Doccode varchar(50),@Ordering_FormID int,@Ordering_InstanceID varchar(50),
		@PurchaseDoccode varchar(50),@PurchaseInstanceID varchar(50)
		declare @AccessName varchar(200),@ServerName varchar(50),@DBName varchar(50)
		if @FormID in(4483)
			BEGIN
				--汇总单据
				if @OptionID=''
					BEGIN
						--先删除本单已经汇总过的单据
						delete from T_AggregatedDoc  where RefDoccode=@Doccode
						delete from ppoitem  where DocCode=@Doccode
						begin tran
						begin try
							--再重新生成汇总
							select @sql='insert into T_AggregatedDoc(Doccode,FormID,RefFormID,RefDoccode,EnterDate,InstanceID)'+char(10)+
							'select os.doccode,os.formid,@FormID,@Doccode,getdate(),os.instanceid'+char(10)+
							'from openquery(GHPT62,''Select Doccode,FormID,InstanceID From URPDB01.dbo.ord_shopbestgoodsdoc os'+char(10)+
							' Where os.Purchase=1'+char(10)+
							' and os.phflag=''''未处理'''''+char(10)+
							' and os.DocDate between ''''' +convert(varchar(10),@BeginDate,120) +''''' And '''''+ convert(varchar(10),@EndDate,120)+''''''+char(10)+
							' and os.DocStatus=100'+char(10)+
							' and os.formid=6090'') os'+char(10)+
							' Where not exists(select 1 from T_AggregateResult tar with(nolock) where os.DocCode=tar.Doccode)'
							print @sql
							exec sp_executesql @sql,N'@FormID int,@Doccode varchar(20)',@FormID=@FormID,@Doccode=@Doccode
							if @@ROWCOUNT=0
								BEGIN
									raiserror('尚不存在待汇总的订单,请稍后再试.',16,1)
									return
								END
							--将单号连接成字符串
							select @sql_Doccode=''
							select @sql_Doccode=@sql_Doccode+''''''+doccode+''''','
							From T_AggregatedDoc with(nolock)
							where RefDoccode=@Doccode
							select @sql_Doccode=left(@sql_Doccode,len(@sql_Doccode)-1)
							--将汇总数据插入回单据
							select @sql='insert into ppoitem(DocItem,rowid,doccode,MatCode,matname,Digit,userdigit3)'+char(10)+
							'select row_number() over(order by (select 1)),newid(),'''+@Doccode+''' ,os2.matcode,os2.matname,os2.ask_digit,os2.ask_digit'+char(10)+
							'from Openquery(GHPT62,''Select os2.matcode,os2.matname,sum(isnull(ask_digit,0)) as ask_digit From URPDB01.dbo.ord_shopbestgoodsdtl os2,URPDB01.dbo.iMatGeneral img'+char(10)+
							'where os2.DocCode in(' +@sql_Doccode +')'+char(10)+
							'and os2.matcode=img.MatCode'+char(10)+
							'and img.PurchaseFlag=1'+char(10)+
							'group by os2.MatCode,os2.matname'') os2'
							--print @sql
							exec(@sql)
							if xact_state()<>-1 commit
						end try
						begin catch
							if xact_state()<>-1 rollback
							select @msg=dbo.getLastError('订单汇总失败,请重试.')
							raiserror(@msg,16,1)
							return
						end catch
					END
				--将汇总单据写入汇总结果表
				/*if @OptionID='1'
					BEGIN
						BEGIN TRY
							insert into T_AggregateResult(Doccode,FormID,RefFormID,RefCode,EnterDate,Status,InstanceID)
							select tad.Doccode,tad.FormID,tad.RefFormID,tad.RefDoccode,tad.EnterDate,0,tad.InstanceID
							from T_AggregatedDoc tad with(nolock)
							where tad.RefDoccode=@Doccode
						END TRY
						BEGIN CATCH
							select @msg=dbo.getLastError('汇总订单失败,请重新汇总订单!.')
							raiserror(@msg,16,1)
							return
						END CATCH
					END*/
				--生成采购订单
				if @OptionID='2'
					BEGIN
						--取出供应商
						select @vndCode=vndcode from ppohd p with(nolock) where p.DocCode=@Doccode
						select @msg=''
						--检查单据中是否有商品尚未报价
						select @msg=@msg+'第'+convert(varchar(10),p.docitem)+'行商品['+p.matname+']尚未报价,无法汇总采购,请先报价后再操作.'+dbo.crlf()
						From ppoitem p with(nolock)
						where p.DocCode=@Doccode
						and not exists(select 1 from sMatStorage_VND s with(nolock) where s.Matcode=p.MatCode and s.vndCode=@vndCode)
						if @@ROWCOUNT>0
							BEGIN
								raiserror(@msg,16,1)
								return
							END
						--取出供应商税率
						select @taxRate= pvg.taxrate from pVndGeneral pvg with(nolock)
						exec sp_newdoccode 4401,'',@newdoccode output
						begin TRAN
						BEGIN TRY
							insert into ppohd(DocCode,FormID,DocType,DocDate,docstatus,periodid,refcode,Companyid,CompanyName,vndcode,vndName,
							stcode,stname,purgroup,purgroupname,usertxt3,HDText,usertxt1,usertxt2,entername,EnterDate,PostName,PostDate,cwsh,planpickdate)
							Select @NewDocCode,4401,'手机',convert(varchar(10),getdate(),120),100,convert(varchar(7),getdate(),120) ,@Doccode,
							Companyid,CompanyName,vndcode,vndName,stcode,stname,purgroup,purgroupname,
							'预付款','订单汇总生成采购订单.','SYSTEM','SYSTEM',entername,EnterDate,PostName,PostDate,1,planpickdate
							from ppohd p with(nolock) 
							where p.DocCode=@doccode
							insert into ppoitem(DocCode,DocItem,rowid,MatCode,MatName,uom,price,netprice,digit,totalmoney,vatrate,netmoney,usertxt2,usertxt3,FormGroup)
							select @NewDoccode,p.DocItem,newid(),p.MatCode,p.MatName,img.UOM,smsv.Price,smsv.Price,p.digit,smsv.Price*p.Digit,@taxrate,smsv.Price*p.Digit,p.usertxt3,'购入','所有'
							from ppoitem p with(nolock) inner join iMatGeneral img on p.MatCode=img.MatCode
							inner join sMatStorage_VND smsv on smsv.Matcode=img.MatCode
							where p.DocCode=@Doccode
							and smsv.vndCode=@vndCode
							if @@ROWCOUNT=0
								BEGIN
									rollback
									raiserror('未生成采购订单明细,操作无法继续.',16,1)
									return
								END
							insert into T_AggregateResult(Doccode,FormID,RefFormID,RefCode,EnterDate,Status,InstanceID,PurchaseOrderDoccode,PurchaseOrderInstanceID)
								select tad.Doccode,tad.FormID,tad.RefFormID,tad.RefDoccode,tad.EnterDate,0,tad.InstanceID,@NewDoccode,dbo.InstanceID()
								from T_AggregatedDoc tad with(nolock)
								where tad.RefDoccode=@Doccode
							 	commit					
						END TRY
						BEGIN CATCH
							 if @@trancount>0 rollback
							select @msg=dbo.getLastError('生成采购订单失败,请重试.')
							raiserror(@msg,16,1)
							return
						END CATCH
						print @newdoccode
					END
			END
		--采购入库单回填订货单
		if @FormID in(1509)
			BEGIN
				--取出订单
				select @refcode=refCode from imatdoc_h with(nolock) where DocCode=@Doccode
				if isnull(@Refcode,'')='' return 
				set XACT_ABORT on
				begin tran
				begin try
					--游标遍历各服务器上订货单,并取消其采购流程标志
					declare cur_Doc CURSOR READ_ONLY   forward_only fast_forward FOR
					select  tar.InstanceID 
					from T_AggregateResult tar with(nolock)
					where tar.PurchaseOrderDoccode=@Refcode
					open cur_Doc
					fetch next FROM cur_Doc into  @ordering_InstanceID 
					while @@FETCH_STATUS=0
						BEGIN
							print @ordering_InstanceID
							--判断是否来自本机
							if @ordering_InstanceID<>dbo.InstanceID()
								BEGIN
									--取出该服务器访问信息
									select @AccessName=si.AccessName
									from _sysInstances si with(nolock)
									where si.InstanceID=@ordering_InstanceID
									if isnull(@AccessName,'')='' 
										BEGIN
											raiserror('服务器实例信息不存在,无法更新订货单,请联系系统管理员.',16,1)
											return
										END
									--分解得服务器与数据库名称
									SELECT @ServerName=SUBSTRING(@AccessName,0,CHARINDEX('.',@AccessName))
									SELECT @DBName=SUBSTRING(@AccessName,CHARINDEX('.',@AccessName)+1,50)
									print @ServerName
									print @DBName
									if isnull(@ServerName,'')=''  
										BEGIN
											raiserror('服务器信息为空,无法更新订单,请联系系统管理员.',16,1)
											return
										END
									if isnull(@DBName,'')=''  
										BEGIN
											raiserror('服务器数据库信息为空,无法更新订单,请联系系统管理员.',16,1)
											return
										END
									--将该服务器上的所有订单编号拼接成字符串
									select @sql_Doccode=''
									select @sql_Doccode=@sql_Doccode+''''''+doccode+''''','
										From T_AggregateResult with(nolock)
									where PurchaseOrderDoccode=@Refcode
										and InstanceID=@ordering_InstanceID
										select @sql_Doccode=left(@sql_Doccode,len(@sql_Doccode)-1)
									--更新订单
									/*Update OpenQuery(@ServerName,'Select Purchase From  '+@ServerName +'.dbo.ord_shopbestgoodsdoc Where Doccode in('+@sql_Doccode+')')
									Set PurChase=1
									*/
									SET @sql = 'Update OpenQuery('+@ServerName+',''Select Purchase From  '+@DBName +'.dbo.ord_shopbestgoodsdoc Where Doccode in('+@sql_Doccode+')'') ' + char(10)
											 + '								Set PurChase=0'
									print @sql
									EXEC(@sql)
									--再更新状态值
									update tar
										set tar.PurchaseDoccode = @Doccode,
										tar.PurchaseInstanceID=dbo.InstanceID(),
										tar.Status = 1
									from T_AggregateResult tar with(nolock)
									where tar.InstanceID=@Ordering_InstanceID
									and tar.PurchaseOrderDoccode=@Refcode
								END
							else	---若订单在本机,则报个错.
								BEGIN
 
									raiserror('咦,怎么订单在本机呢?不太正常哦,赶紧联系系统管理员!',16,1)
									return
								END
							fetch next FROM cur_Doc into  @ordering_InstanceID
						END
					close cur_Doc
					deallocate cur_doc
					commit
				end try
				begin catch
					--if @@TRANCOUNT>0 rollback
					select @msg=dbo.getLastError('通知订货申请单异常.')
					raiserror(@msg,16,1)
					return
				end catch
			END
	END
	 
 
 