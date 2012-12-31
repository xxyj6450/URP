/*

set XACT_ABORT on;
begin tran
exec sp_deliverydoc 6093,'GFH2012112800066','2.1.769.09.29','SYSTEM','SYSTEM'


exec   sp_UpdateCredit 6093,'GFH2012111600306','2.1.769.01.02',1,'1','�ֻ�������.'
begin tran
exec sp_Update_ChildrenGHPT 'GFH2012112300166'
commit
rollback
 
 select * from osdorgcreditlog where doccode='GFH2012111600306'
begin tran
exec sp_UpdateCredit 6093,'GFH2012112500006','2.1.769.09.29',1,'1','�ֻ�������.','SYSTEM'

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
		--������������ݲ�����ʱ��,�Թ���һ������.
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
		and isnull(a.phflag,'')='δ����'
		--���ֻ�״̬
		if @@ROWCOUNT=0
			BEGIN
				raiserror('����״̬���ڿɷֻ�״̬��������ȷ�ϣ�����ϵ�ƻ�����',16,1)
				return
			END
		--ȡ��������Ϣ
		select @LocalInstanceID=sli.InstanceID from _sysLocalInfo sli
		if @@ROWCOUNT=0
			BEGIN
				raiserror('���ط�������Ϣȱʧ,�޷���������.',16,1)
				return
			END
		 
		exec sp_Update_ChildrenGHPT @doccode
 
		--��������
		select @trancount=@@TRANCOUNT
		if @trancount=0 		
			BEGIN
				set XACT_ABORT on;
				begin tran
			END
		begin try
 
			--�α�������ֻ�ƽ̨
			declare cur_SYSTEM cursor READ_ONLY fast_forward forward_only for
			select  a.AccessName,a.fhstcode,a.InstanceID
			from #t a
			group by a.AccessName,a.fhstcode,a.InstanceID
			open cur_SYSTEM
			fetch next from cur_SYSTEM into @Accessname,@fhstcode,@InstanceID
			while @@FETCH_STATUS=0	
				BEGIN
					--�����µ���,�Ա������Ź�������.���Ӷ���������.
					exec sp_newdoccode 4459,'',@Newdoccode output
					--print @Newdoccode
					--�����������
					select @Accessname1=''
					--׼����������Ϣ.������ƽ̨��Ϣ��Ϊ������Ϣ,���ڷ������ƺ�����".",�Թ�Զ�̷��ʵ���Ҫ.
					if isnull(@InstanceID,@LocalInstanceID)<>@LocalInstanceID select @Accessname1=@Accessname+'.'
		 
					--д�뵥��
					/*insert into fh_deliverydoc(doccode,formid,docstatus,refcode,refformid,doctype,instcode,instname,entername,enterdate,postname,postdate,
					ps_stcode,ps_stname,companyid,sdtype)
					output a.doccode,inserted.instcode into @table
					select @Newdoccode,4459,0,@Doccode,@FormID,'�ֻ�����������',a.instcode,a.instname,@username,getdate(),@username,getdate(),
					a.ps_stcode,a.ps_stname,a.companyid,'���˵�'
					from #t a 
					where a.AccessName=@Accessname
					group by a.instcode,a.instname,a.ps_stcode,a.ps_stname,a.companyid*/
					
					SET @sql = ' ' + char(10)
							 + '				insert into '+ @Accessname1+ 'dbo.fh_deliverydoc(doccode,formid,docstatus,docdate,refcode,refformid,doctype,instcode,instname,entername,enterdate,postname,postdate, ' + char(10)
							 + '				ps_stcode,ps_stname,companyid,sdtype) ' + char(10)
							 --+ '				output a.doccode,inserted.instcode into @table ' + char(10)
							 + '				select @Newdoccode,4459,1,convert(varchar(10),getdate(),120),a.refcode,a.refformid,''�ֻ�����������'',a.instcode,a.instname,@username,getdate(),@username,getdate(), ' + char(10)
							 + '				a.ps_stcode,a.ps_stname,a.PlantID,''���˵�'' ' + char(10)
							 + '				from #t a  ' + char(10)
							 + '				where a.AccessName='''+@Accessname +'''' + char(10)
							 +'				AND a.fhstcode='''+@fhstcode+''''+char(10)
							 + '				group by a.refcode,a.refformid,a.instcode,a.instname,a.ps_stcode,a.ps_stname,a.PlantID;'
					--print @sql
					EXEC sp_executesql @sql,N'@Newdoccode varchar(50),@Doccode varchar(50),@FormID int,@username varchar(200)',
					@Newdoccode=@Newdoccode,@Doccode=@Doccode,@FormID=@FormID,@Username=@UserName
					if @@ROWCOUNT=0
						BEGIN
							raiserror('�ֻ�������ʧ��,������!',16,1)
							return
						END
					--д�뵥����ϸ
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
							raiserror('�ֻ�����ϸ����ʧ��,������!',16,1)
							return
						END
					--����ָ�
					set @sql='EXEC ' +@Accessname1+ 'dbo.sp_createfhzl @Newdoccode,@Newdoccode1'
					EXEC sp_executesql @sql,N'@Newdoccode varchar(50),@Doccode varchar(50),@FormID int,@username varchar(200),@Newdoccode1 varchar(50) out',
					@Newdoccode=@Newdoccode,@Doccode=@Doccode,@FormID=@FormID,@Username=@UserName,@Newdoccode1=@Newdoccode1
					fetch next from cur_SYSTEM into @Accessname,@fhstcode,@InstanceID
				END
				close cur_SYSTEM
				deallocate cur_system
				--�������ö��
				--exec sp_UpdateCredit @FormID,@Doccode,@SDorgid,1,'1','�ֻ�������.'
				--exec [sp_UpdateCredit] 6093,'GFH2012112300166','2.1.769.06.12',1,'1'
				if xact_state()=1 and @trancount =0 commit
			end try
			begin catch
				select @tips='�ֻ������쳣.'+dbo.crlf()+isnull(error_message(),'')+dbo.crlf()+'�쳣������'+isnull(error_procedure(),'')+'��'+convert(varchar(10),isnull(error_line(),0))+'��'
 
				if  @@trancount>0 rollback
				raiserror(@tips,16,1)
				return
			end catch
		
		return
	END
	
