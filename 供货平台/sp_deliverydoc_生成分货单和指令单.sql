/*

set XACT_ABORT on;
begin tran
exec sp_deliverydoc 6093,'GFH2012112800066','2.1.769.09.29','SYSTEM','SYSTEM'


exec   sp_UpdateCredit 6093,'GFH2012111600306','2.1.769.01.02',1,'1','分货处理额度.'
begin tran
exec sp_Update_ChildrenGHPT 'GFH2012112300166'
commit
rollback
 
 select * from osdorgcreditlog where doccode='GFH2012111600306'
begin tran
exec sp_UpdateCredit 6093,'GFH2012112500006','2.1.769.09.29',1,'1','分货处理额度.','SYSTEM'

*/
alter proc sp_deliverydoc
	@FormID int,
	@Doccode varchar(30),
	@SDorgID varchar(50),
	@Usercode varchar(50)='',
	@UserName varchar(200)=''
as
	BEGIN
		set NOCOUNT on;
		set xact_abort on;
		declare @Newdoccode varchar(30),@Accessname varchar(200),@sql nvarchar(max),@refcode varchar(50),@trancount int,
		@Newdoccode1 varchar(50),@tips varchar(5000),@fhstcode varchar(50),@Accessname1 varchar(200),@InstanceID varchar(50),@LocalInstanceID varchar(50)
		--将待处理的数据插入临时表,以供进一步处理.
		Select a.DocCode,b.rowid, a.sdorgid as instcode,a.sdorgname as instname,a.ps_st ps_stcode,a.ps_stname as  ps_stname,
		os.stCode as fhstcode,os.name40 as fhstname,os.PlantID,a.RefDoc as refcode,6090 as refformid,
		b.matcode,b.matname,b.ask_digit as plandigit,b.deliverdigt1 as digit,b.salesprice,si.AccessName,a.phflag,ss.InstanceID
		Into #t 
		From ord_shopbestgoodsdoc a with(nolock) 
		inner join ord_shopbestgoodsdtl b with(nolock) on a.DocCode=b.doccode
		inner join oStorage os with(nolock) on b.fhstcode=os.stCode
		 inner join _sysSYSTEMS ss on os.systemid=ss.ID
		inner join  _sysInstances si on ss.InstanceID=si.InstanceID
		where a.FormID=@FormID
		and a.DocCode=@Doccode
		--and isnull(b.deliverdigt1,0)>0
		and isnull(a.phflag,'')='未处理'
		--检查分货状态
		if @@ROWCOUNT=0
			BEGIN
				raiserror('订单状态不在可分货状态，不允许确认，请联系计划部！',16,1)
				return
			END
		--取出本机信息
		select @LocalInstanceID=sli.InstanceID from _sysLocalInfo sli
		if @@ROWCOUNT=0
			BEGIN
				raiserror('本地服务器信息缺失,无法继续操作.',16,1)
				return
			END
		 
		exec sp_Update_ChildrenGHPT @doccode
 
		--启动事务
		select @trancount=@@TRANCOUNT
		if @trancount=0 		
			BEGIN
				set XACT_ABORT on;
				begin tran
			END
		begin try
 
			--游标遍历各分货平台
			declare cur_SYSTEM cursor READ_ONLY fast_forward forward_only for
			select  a.AccessName,a.fhstcode,a.InstanceID
			from #t a
			group by a.AccessName,a.fhstcode,a.InstanceID
			open cur_SYSTEM
			fetch next from cur_SYSTEM into @Accessname,@fhstcode,@InstanceID
			while @@FETCH_STATUS=0	
				BEGIN
					--生成新单号,以本机单号规则生成.增加订单利用率.
					exec sp_newdoccode 4459,'',@Newdoccode output
					--print @Newdoccode
					--清除已有数据
					select @Accessname1=''
					--准备服务器信息.若发货平台信息不为本机信息,则在访问名称后增加".",以供远程访问的需要.
					if isnull(@InstanceID,@LocalInstanceID)<>@LocalInstanceID select @Accessname1=@Accessname+'.'
		 
					--写入单据
					/*insert into fh_deliverydoc(doccode,formid,docstatus,refcode,refformid,doctype,instcode,instname,entername,enterdate,postname,postdate,
					ps_stcode,ps_stname,companyid,sdtype)
					output a.doccode,inserted.instcode into @table
					select @Newdoccode,4459,0,@Doccode,@FormID,'分货单（按单）',a.instcode,a.instname,@username,getdate(),@username,getdate(),
					a.ps_stcode,a.ps_stname,a.companyid,'加盟店'
					from #t a 
					where a.AccessName=@Accessname
					group by a.instcode,a.instname,a.ps_stcode,a.ps_stname,a.companyid*/
					
					SET @sql = ' ' + char(10)
							 + '				insert into '+ @Accessname1+ 'dbo.fh_deliverydoc(doccode,formid,docstatus,docdate,refcode,refformid,doctype,instcode,instname,entername,enterdate,postname,postdate, ' + char(10)
							 + '				ps_stcode,ps_stname,companyid,sdtype) ' + char(10)
							 --+ '				output a.doccode,inserted.instcode into @table ' + char(10)
							 + '				select @Newdoccode,4459,1,convert(varchar(10),getdate(),120),a.refcode,a.refformid,''分货单（按单）'',a.instcode,a.instname,@username,getdate(),@username,getdate(), ' + char(10)
							 + '				a.ps_stcode,a.ps_stname,a.PlantID,''加盟店'' ' + char(10)
							 + '				from #t a  ' + char(10)
							 + '				where a.AccessName='''+@Accessname +'''' + char(10)
							 +'				AND a.fhstcode='''+@fhstcode+''''+char(10)
							 + '				group by a.refcode,a.refformid,a.instcode,a.instname,a.ps_stcode,a.ps_stname,a.PlantID;'
					--print @sql
					EXEC sp_executesql @sql,N'@Newdoccode varchar(50),@Doccode varchar(50),@FormID int,@username varchar(200)',
					@Newdoccode=@Newdoccode,@Doccode=@Doccode,@FormID=@FormID,@Username=@UserName
					if @@ROWCOUNT=0
						BEGIN
							raiserror('分货单生成失败,请重试!',16,1)
							return
						END
					--写入单据明细
					/*insert into fh_deliverydtl(doccode,docitem,rowid,matcode,matname,plandigit,digit,price,FHstcode,FHstname)
					select @Newdoccode,row_number() over(order  by (select 1) ),newid(),a.matcode,a.matname,a.plandigit,a.digit,a.price,a.fhstcode,a.fhstname
					from #t a,@table b
					where a.doccode=b.doccode
					and a.instcode=b.stcode*/
					SET @sql = 'insert into '+@Accessname1+ 'dbo.fh_deliverydtl(doccode,docitem,rowid,matcode,matname,plandigit,digit,price,FHstcode,FHstname) ' + char(10)
							 + '				select @Newdoccode,row_number() over(order  by (select 1) ),newid(),a.matcode,a.matname,a.plandigit,a.digit,a.salesprice,a.fhstcode,a.fhstname ' + char(10)
							 + '				from #t  a' + char(10)
							 + '				where a.fhstcode='''+@fhstcode+'''' + char(10)
							 +'				AND a.AccessName='''+@Accessname +'''' + char(10)
 
					EXEC sp_executesql @sql,N'@Newdoccode varchar(50),@Doccode varchar(50),@FormID int,@username varchar(200)',
					@Newdoccode=@Newdoccode,@Doccode=@Doccode,@FormID=@FormID,@Username=@UserName
					if @@ROWCOUNT=0
						BEGIN
							raiserror('分货单明细生成失败,请重试!',16,1)
							return
						END
					--生成指令单
					set @sql='EXEC ' +@Accessname1+ 'dbo.sp_createfhzl @Newdoccode,@Newdoccode1'
					EXEC sp_executesql @sql,N'@Newdoccode varchar(50),@Doccode varchar(50),@FormID int,@username varchar(200),@Newdoccode1 varchar(50) out',
					@Newdoccode=@Newdoccode,@Doccode=@Doccode,@FormID=@FormID,@Username=@UserName,@Newdoccode1=@Newdoccode1
					fetch next from cur_SYSTEM into @Accessname,@fhstcode,@InstanceID
				END
				close cur_SYSTEM
				deallocate cur_system
				--处理信用额度
				--exec sp_UpdateCredit @FormID,@Doccode,@SDorgid,1,'1','分货处理额度.'
				--exec [sp_UpdateCredit] 6093,'GFH2012112300166','2.1.769.06.12',1,'1'
				if xact_state()=1 and @trancount =0 commit
			end try
			begin catch
				select @tips='分货发生异常.'+dbo.crlf()+isnull(error_message(),'')+dbo.crlf()+'异常发生于'+isnull(error_procedure(),'')+'第'+convert(varchar(10),isnull(error_line(),0))+'行'
 
				if  @@trancount>0 rollback
				raiserror(@tips,16,1)
				return
			end catch
		
		return
	END
	
