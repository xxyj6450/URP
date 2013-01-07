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
				--���ܵ���
				if @OptionID=''
					BEGIN
						--��ɾ�������Ѿ����ܹ��ĵ���
						delete from T_AggregatedDoc  where RefDoccode=@Doccode
						delete from ppoitem  where DocCode=@Doccode
						begin tran
						begin try
							--���������ɻ���
							select @sql='insert into T_AggregatedDoc(Doccode,FormID,RefFormID,RefDoccode,EnterDate,InstanceID)'+char(10)+
							'select os.doccode,os.formid,@FormID,@Doccode,getdate(),os.instanceid'+char(10)+
							'from openquery(GHPT62,''Select Doccode,FormID,InstanceID From URPDB01.dbo.ord_shopbestgoodsdoc os'+char(10)+
							' Where os.Purchase=1'+char(10)+
							' and os.phflag=''''δ����'''''+char(10)+
							' and os.DocDate between ''''' +convert(varchar(10),@BeginDate,120) +''''' And '''''+ convert(varchar(10),@EndDate,120)+''''''+char(10)+
							' and os.DocStatus=100'+char(10)+
							' and os.formid=6090'') os'+char(10)+
							' Where not exists(select 1 from T_AggregateResult tar with(nolock) where os.DocCode=tar.Doccode)'
							print @sql
							exec sp_executesql @sql,N'@FormID int,@Doccode varchar(20)',@FormID=@FormID,@Doccode=@Doccode
							if @@ROWCOUNT=0
								BEGIN
									raiserror('�в����ڴ����ܵĶ���,���Ժ�����.',16,1)
									return
								END
							--���������ӳ��ַ���
							select @sql_Doccode=''
							select @sql_Doccode=@sql_Doccode+''''''+doccode+''''','
							From T_AggregatedDoc with(nolock)
							where RefDoccode=@Doccode
							select @sql_Doccode=left(@sql_Doccode,len(@sql_Doccode)-1)
							--���������ݲ���ص���
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
							select @msg=dbo.getLastError('��������ʧ��,������.')
							raiserror(@msg,16,1)
							return
						end catch
					END
				--�����ܵ���д����ܽ����
				/*if @OptionID='1'
					BEGIN
						BEGIN TRY
							insert into T_AggregateResult(Doccode,FormID,RefFormID,RefCode,EnterDate,Status,InstanceID)
							select tad.Doccode,tad.FormID,tad.RefFormID,tad.RefDoccode,tad.EnterDate,0,tad.InstanceID
							from T_AggregatedDoc tad with(nolock)
							where tad.RefDoccode=@Doccode
						END TRY
						BEGIN CATCH
							select @msg=dbo.getLastError('���ܶ���ʧ��,�����»��ܶ���!.')
							raiserror(@msg,16,1)
							return
						END CATCH
					END*/
				--���ɲɹ�����
				if @OptionID='2'
					BEGIN
						--ȡ����Ӧ��
						select @vndCode=vndcode from ppohd p with(nolock) where p.DocCode=@Doccode
						select @msg=''
						--��鵥�����Ƿ�����Ʒ��δ����
						select @msg=@msg+'��'+convert(varchar(10),p.docitem)+'����Ʒ['+p.matname+']��δ����,�޷����ܲɹ�,���ȱ��ۺ��ٲ���.'+dbo.crlf()
						From ppoitem p with(nolock)
						where p.DocCode=@Doccode
						and not exists(select 1 from sMatStorage_VND s with(nolock) where s.Matcode=p.MatCode and s.vndCode=@vndCode)
						if @@ROWCOUNT>0
							BEGIN
								raiserror(@msg,16,1)
								return
							END
						--ȡ����Ӧ��˰��
						select @taxRate= pvg.taxrate from pVndGeneral pvg with(nolock)
						exec sp_newdoccode 4401,'',@newdoccode output
						begin TRAN
						BEGIN TRY
							insert into ppohd(DocCode,FormID,DocType,DocDate,docstatus,periodid,refcode,Companyid,CompanyName,vndcode,vndName,
							stcode,stname,purgroup,purgroupname,usertxt3,HDText,usertxt1,usertxt2,entername,EnterDate,PostName,PostDate,cwsh,planpickdate)
							Select @NewDocCode,4401,'�ֻ�',convert(varchar(10),getdate(),120),100,convert(varchar(7),getdate(),120) ,@Doccode,
							Companyid,CompanyName,vndcode,vndName,stcode,stname,purgroup,purgroupname,
							'Ԥ����','�����������ɲɹ�����.','SYSTEM','SYSTEM',entername,EnterDate,PostName,PostDate,1,planpickdate
							from ppohd p with(nolock) 
							where p.DocCode=@doccode
							insert into ppoitem(DocCode,DocItem,rowid,MatCode,MatName,uom,price,netprice,digit,totalmoney,vatrate,netmoney,usertxt2,usertxt3,FormGroup)
							select @NewDoccode,p.DocItem,newid(),p.MatCode,p.MatName,img.UOM,smsv.Price,smsv.Price,p.digit,smsv.Price*p.Digit,@taxrate,smsv.Price*p.Digit,p.usertxt3,'����','����'
							from ppoitem p with(nolock) inner join iMatGeneral img on p.MatCode=img.MatCode
							inner join sMatStorage_VND smsv on smsv.Matcode=img.MatCode
							where p.DocCode=@Doccode
							and smsv.vndCode=@vndCode
							if @@ROWCOUNT=0
								BEGIN
									rollback
									raiserror('δ���ɲɹ�������ϸ,�����޷�����.',16,1)
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
							select @msg=dbo.getLastError('���ɲɹ�����ʧ��,������.')
							raiserror(@msg,16,1)
							return
						END CATCH
						print @newdoccode
					END
			END
		--�ɹ���ⵥ�������
		if @FormID in(1509)
			BEGIN
				--ȡ������
				select @refcode=refCode from imatdoc_h with(nolock) where DocCode=@Doccode
				if isnull(@Refcode,'')='' return 
				set XACT_ABORT on
				begin tran
				begin try
					--�α�������������϶�����,��ȡ����ɹ����̱�־
					declare cur_Doc CURSOR READ_ONLY   forward_only fast_forward FOR
					select  tar.InstanceID 
					from T_AggregateResult tar with(nolock)
					where tar.PurchaseOrderDoccode=@Refcode
					open cur_Doc
					fetch next FROM cur_Doc into  @ordering_InstanceID 
					while @@FETCH_STATUS=0
						BEGIN
							print @ordering_InstanceID
							--�ж��Ƿ����Ա���
							if @ordering_InstanceID<>dbo.InstanceID()
								BEGIN
									--ȡ���÷�����������Ϣ
									select @AccessName=si.AccessName
									from _sysInstances si with(nolock)
									where si.InstanceID=@ordering_InstanceID
									if isnull(@AccessName,'')='' 
										BEGIN
											raiserror('������ʵ����Ϣ������,�޷����¶�����,����ϵϵͳ����Ա.',16,1)
											return
										END
									--�ֽ�÷����������ݿ�����
									SELECT @ServerName=SUBSTRING(@AccessName,0,CHARINDEX('.',@AccessName))
									SELECT @DBName=SUBSTRING(@AccessName,CHARINDEX('.',@AccessName)+1,50)
									print @ServerName
									print @DBName
									if isnull(@ServerName,'')=''  
										BEGIN
											raiserror('��������ϢΪ��,�޷����¶���,����ϵϵͳ����Ա.',16,1)
											return
										END
									if isnull(@DBName,'')=''  
										BEGIN
											raiserror('���������ݿ���ϢΪ��,�޷����¶���,����ϵϵͳ����Ա.',16,1)
											return
										END
									--���÷������ϵ����ж������ƴ�ӳ��ַ���
									select @sql_Doccode=''
									select @sql_Doccode=@sql_Doccode+''''''+doccode+''''','
										From T_AggregateResult with(nolock)
									where PurchaseOrderDoccode=@Refcode
										and InstanceID=@ordering_InstanceID
										select @sql_Doccode=left(@sql_Doccode,len(@sql_Doccode)-1)
									--���¶���
									/*Update OpenQuery(@ServerName,'Select Purchase From  '+@ServerName +'.dbo.ord_shopbestgoodsdoc Where Doccode in('+@sql_Doccode+')')
									Set PurChase=1
									*/
									SET @sql = 'Update OpenQuery('+@ServerName+',''Select Purchase From  '+@DBName +'.dbo.ord_shopbestgoodsdoc Where Doccode in('+@sql_Doccode+')'') ' + char(10)
											 + '								Set PurChase=0'
									print @sql
									EXEC(@sql)
									--�ٸ���״ֵ̬
									update tar
										set tar.PurchaseDoccode = @Doccode,
										tar.PurchaseInstanceID=dbo.InstanceID(),
										tar.Status = 1
									from T_AggregateResult tar with(nolock)
									where tar.InstanceID=@Ordering_InstanceID
									and tar.PurchaseOrderDoccode=@Refcode
								END
							else	---�������ڱ���,�򱨸���.
								BEGIN
 
									raiserror('��,��ô�����ڱ�����?��̫����Ŷ,�Ͻ���ϵϵͳ����Ա!',16,1)
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
					select @msg=dbo.getLastError('֪ͨ�������뵥�쳣.')
					raiserror(@msg,16,1)
					return
				end catch
			END
	END
	 
 
 