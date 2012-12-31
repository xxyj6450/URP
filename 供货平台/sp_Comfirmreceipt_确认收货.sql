/*
��������:sp_ComfirmReceipt
����:ȷ���ջ�
����:������
����ֵ:
��д:���ϵ�
ʱ��:2012-11-21
��ע:�ù��̽��ڹ���ƽִ̨��
ҵ���߼�:
	�������Ѿ��ջ�,���׳��쳣
	ȷ���ջ�ʱ,������ƽ̨�����Ĵ���׼����,��д��URP.
	��URPƽ̨�Ѿ�����Ӧ�յĴ˴���,���׳��쳣,��ֹ����.
	�������ֿ�ΪURP����ƽ̨,��ת�ƴ���.������Ҫת�ƴ���.
	��URPƽ̨�Ѿ��������۵Ĵ˴���,��URP���Ѵ��ڵ����۴���ת�������۴��ű�,�ٽ��´���ת����URP���ű�.
	ת��URP���д���ʱ��¼������־;������ת����URPʱ��¼������־.
	�����ͻ����ջ�״̬.
ʾ��:
begin tran
exec sp_ComfirmReceipt 'JDC2012121700326',4950,'SYSTEM','2.1.755.61.12','D101.01','','1243010B-4C4E-40FE-AAC5-B3AD367AA74D','1',''
 
 update iseries
	set state='�ͻ�'
 where seriescode='111222222222222'
 rollback
 set xact_abort on
 begin tran
exec sp_ComfirmReceipt 'JDC2012121802580',4950,'SYSTEM','2.1.020.09.05','001.020','','E36D5919-925A-4C78-95FB-B9E0A2007A6F','1',''

begin tran
exec sp_ComfirmReceipt 'JDC2012121500460',4950,'SYSTEM','2.1.791.03.25','111.769','','E36D5919-925A-4C78-95FB-B9E0A2007A6F','1',''

 
select instanceid,stcode,instcode from spickorderhd where doccode='JDC2012112800026'
print dbo.instanceid()
rollback
1.868429010299206[����A60+��ɫ]
select * from ostorage where stcode='102'2.862726019083960[����V889D-WCDMA��ɫ]
print dbo.instanceid()488EFECF-8488-40D4-A4AF-36B1216D07483.867439011788645[����W619�������ɫ]
 4.866022011488076[����A690��ɫ]
*/
 
alter proc sp_ComfirmReceipt
	@Doccode varchar(20),						--����
	@Formid int,										--���ܺ�
	@Usercode varchar(50),						--�û���
	@stcode varchar(50)='',						--�ջ��ֿ�
	@fhstcode varchar(50)='',					--�ֻ��ֿ�
	@remark varchar(50)='',						--��ע
	@InstanceID varchar(50)='',				--v_spickorderhd_Distributed��InstanceID
	@optionID varchar(50)='',					--�ջ���1
	@TerminalID varchar(50)=''					--�ն˱���
as
	BEGIN
		set NOCOUNT on;
		set XACT_ABORT on;
		
		/***************************************************��������*********************************************************************/
		declare @refcode varchar(20),  @sql nvarchar(max),@tips varchar(max),
		@trancount int,@SQL_Seriescode varchar(max),@sql_Fields varchar(max),
		@AccessName varchar(200),@SYSTEMNAME varchar(50),@SeriesRowcount INT,
		@DatabaseName VARCHAR(50),@ServerName VARCHAR(50),@rowcount int
		
		/**************************************************�������********************************************************************/
		--��ʵ��IDΪ��,���Դ����Ͳֿ���ȡ��������ʵ��ID
		if isnull(@InstanceID,'')=''
			BEGIN
				 select @InstanceID=ss.InstanceID
									from oStorage os with(nolock) inner join _sysSYSTEMS ss with(nolock) on os.SYSTEMID=ss.ID
				 if @@ROWCOUNT=0
					BEGIN
						raiserror('δ�ҵ�����ƽ̨��Ϣ,�޷���������.',16,1)
						return
					END
			END
		--ȡ��������Ϣ
		select @AccessName=si.AccessName
						  from _sysInstances si where si.InstanceID=@InstanceID
		if @@ROWCOUNT=0 or isnull(@AccessName,'')=''
			BEGIN
				raiserror('δ�ҵ�����ƽ̨������Ϣ,�޷���������.',16,1)
				return
			END
		SELECT @ServerName=SUBSTRING(@AccessName,0,CHARINDEX('.',@AccessName))
		SELECT @DatabaseName=SUBSTRING(@AccessName,CHARINDEX('.',@AccessName)+1,50)
 
		/************************************************��ʼ������******************************************************************/
		CREATE TABLE #iSeries (
			Seriescode VARCHAR(50),
			RowID VARCHAR(50),
			Matcode VARCHAR(50),
			MatName VARCHAR(50),
			Docitem INT,
			STATE VARCHAR(50),
			RefState varchar(50)
		)
		IF @InstanceID=dbo.InstanceID()
			BEGIN
				--ȡ�����ŵ�
				select @refcode=doccode from iseriesloghd i with(nolock) where i.refCode=@Doccode
				IF @@ROWCOUNT>0
					BEGIN
						--ȡ�����Ż�������ʱ��,�Թ�����ʹ��.
						INSERT INTO #iSeries
						select i2.seriescode,i2.rowid,i2.matcode,i2.matname,i2.docitem,convert(varchar(20),'') as state,convert(varchar(20),'') as Refstate
						from iserieslogitem i2 with(nolock)
						where i2.doccode=@refcode
						SELECT @SeriesRowcount=@@ROWCOUNT
					END
				ELSE
					BEGIN
						SELECT @SeriesRowcount=0
					END
				 
			END
		ELSE
		BEGIN
 
				SELECT @sql='Select @Refcode=Doccode From Openquery('+@ServerName+','+dbo.crlf()+
				''' Select Doccode From '+@DatabaseName +'.dbo.iSeriesLogHD i with(nolock) Where i.refcode='''''+@Doccode+''''''')'
 
				EXEC sp_executesql @sql,N'@Refcode varchar(50) output',@refcode=@refcode OUTPUT
				IF @@ROWCOUNT>0
					BEGIN
						SELECT @Sql='INSERT INTO #iSeries '+dbo.crlf()+
						' select i2.seriescode,i2.rowid,i2.matcode,i2.matname,i2.docitem,convert(varchar(20),'''') as state, convert(varchar(20),'''') as state'+dbo.crlf()+
						' from OpenQuery('+@ServerName +','+dbo.crlf()+
						''' Select Seriescode,RowID,Matcode,MatName,DocItem From '+@DatabaseName +'.dbo.iserieslogitem i2 with(nolock)'+dbo.crlf()+
						' where i2.doccode='''''+@refcode+''''''') i2'
						print @sql
						EXEC(@sql)
						SELECT @SeriesRowcount=@@ROWCOUNT
					END
				ELSE
					BEGIN
						SELECT @SeriesRowcount=0
					END
			END
 
		--�����ڴ���ʱ,ȡ��������Ϣ
		IF isnull(@SeriesRowcount,0)>0
			BEGIN
				---ȡ����Щ������URP�еĴ���״̬
				if @InstanceID=dbo.InstanceID()     
					BEGIN
 
						update a
							set a.state=b.state
						from #iseries a inner join dbo.iSeries b with(nolock) on a.seriescode=b.seriescode
					END
				ELSE
				BEGIN
 
						---ȡ����Щ������URP�еĴ���״̬
						update a
							set a.state=b.state
						from #iseries a inner join URP11.JTURP.dbo.iSeries b with(nolock) on a.seriescode=b.seriescode
					END
 
			 
				SELECT @tips='���´��Ų����ͻ�״̬,�޷��ջ�.'+dbo.crlf()
				SELECT @tips=@tips+seriescode+'Ŀǰ״̬Ϊ['+ISNULL(STATE,'')+']'+dbo.crlf()
				FROM #iSeries
				WHERE ISNULL(STATE,'')<>'�ͻ�'
				IF @@ROWCOUNT>0
					BEGIN
						RAISERROR(@tips,16,1)
						return
					END
			END
		
		/***********************************************************ҵ����****************************************************/
		select @TRANCOUNT=@@TRANCOUNT
		if @trancount=0 begin tran
		begin try
			--�����ͻ���
			if @InstanceID=dbo.InstanceID()
				BEGIN
					--���µ���״̬
					update sPickorderHD
						set getok='���ջ�',
						getday=convert(varchar(30),getdate(),120),
						getname = @Usercode
					where DocCode=@Doccode
					and isnull(getok,'δ�ջ�')='δ�ջ�'
					if @@ROWCOUNT=0
						BEGIN
							raiserror('�Ҳ����ͻ������ͻ������ڿ��ջ�״̬,���ʵ�˵��Ƿ��ѷ���,������������ϵ�����ܲ�.',16,1)
							return
						END
					IF isnull(@SeriesRowcount,0)>0
						BEGIN
							--�ٸ��´���״̬
							UPDATE A
								SET a.[state]='Ӧ��'
							FROM iSeries a WITH(NOLOCK),#iseries b
							WHERE a.SeriesCode=b.seriescode
							AND a.[state]='�ͻ�'
							IF @@ROWCOUNT=0
								BEGIN
									RAISERROR('û�д����ͻ��ɹ�,������,�����Ժ�������δ�õ����,����ϵ�����ֿ�.',16,1)
									return
								END
							--�ٸ��´���״̬
							UPDATE b
								SET b.[refstate]=a.state
							FROM URP11.JTURP.dbo.iSeries a WITH(NOLOCK),#iseries b
							WHERE a.SeriesCode=b.seriescode
						END
				END
			else
			BEGIN
				 
					--PRINT '���µ���״̬'
					select @sql='Update Openquery('+@ServerName+',''Select getok,getday,getname,doccode From '+dbo.crlf()+
					@DatabaseName+'.dbo.spickorderhd '+dbo.crlf()+
					' where DocCode='''''+@Doccode+''''''+dbo.crlf()+
					' and isnull(getok,''''δ�ջ�'''')=''''δ�ջ�'''''')'+dbo.crlf()+
					' set getok=''���ջ�'','+dbo.crlf()+
					'	getday=convert(varchar(30),getdate(),120),'+dbo.crlf()+
					'	getname = '''+@Usercode+''''+dbo.crlf()
					--PRINT @sql
					exec(@sql)
					if @@ROWCOUNT=0
						BEGIN
							--PRINT @AccessName
							raiserror('�Ҳ����ͻ������ͻ������ڿ��ջ�״̬,���ʵ�˵��Ƿ��ѷ���,������������ϵ�����ܲ�.',16,1)
							return
						END
 
					--�ٸ��´���״̬
					IF isnull(@SeriesRowcount,0)>0
						BEGIN
							--PRINT '���´���״̬'
							select @SQL_Seriescode=''
							select @SQL_Seriescode=@SQL_Seriescode+''''''+seriescode+''''''+','
							from #iseries 
							where state='�ͻ�'
							select @SQL_Seriescode=left(@SQL_Seriescode,len(@SQL_Seriescode)-1)
							select @sql='UPDATE openquery( '+@ServerName+','+ dbo.crlf()
							+'''Select State From '+@DatabaseName+'.dbo.iSeries where State=''''�ͻ�'''' And Seriescode in('+@SQL_Seriescode+')'') '
							+'	SET [state]=''Ӧ��'''+dbo.crlf()
 
							EXEC(@sql)
							IF @@ROWCOUNT=0
								BEGIN
									RAISERROR('û�д����ͻ��ɹ�,������,�����Ժ�������δ�õ����,����ϵ�����ֿ�.',16,1)
									return
								END						
						END
				END
			
			--�������ƽ̨(������Դ)����URP����ϵͳ(Ŀ��ϵͳ),�Ͳ��ٶԴ��Ž��д�����
			if @AccessName='URP11.JTURP' RETURN
			--��û�д���,Ҳ������ִ��
			IF ISNULL(@SeriesRowcount,0)<=0 RETURN
 
			--ȡ�����ű��ֶ�
			select @sql_Fields=''
			select @sql_Fields=@sql_Fields+s.name+','
			from syscolumns s
			where s.id=object_id('iSeries')
			select @sql_Fields=left(@sql_Fields,len(@sql_Fields)-1)
			--�жϴ�����URPϵͳ���Ƿ����,�����ڷ����۵Ĵ���,���׳��쳣.
 
			select @tips='���´�������URPϵͳ���Ѵ���,�޷���������.'+dbo.crlf()
			select @tips=@tips+convert(varchar(5),b.docitem)+'.'+b.seriescode+'['+b.matname+'],���״̬Ϊ[' +isnull(b.refstate,'')+']'+dbo.crlf()
			from   #iSeries b
			where isnull(b.refstate,'����') not in('����','�ͻ�','����','')
			if @@ROWCOUNT>0
				BEGIN
					raiserror(@tips,16,1)
					return
				END
 
			--��URP�����۵Ĵ�������
			select @SQL_Seriescode=''
			select @SQL_Seriescode=@SQL_Seriescode+''''+a.seriescode+''''+','
			from #iseries a
			where a.refstate in('����','����')
 
			if @@ROWCOUNT>0
				BEGIN
					--ȡ�������ַ���
					select @SQL_Seriescode=left(@SQL_Seriescode,len(@SQL_Seriescode)-1)
					--
					/*
					insert into openquery(URP11,'Select '+@sql_Fields +' From JTURP.dbo.iSeriesSales')
					select @sql_Fields From  openquery(URP11,'Select '+@sql_Fields+' From JTURP.iSeries where seriescode in('+@SQL_Seriescode+')')
					*/
 
					
						--�����۴����������۴��ű�
						SET @sql = 'insert into openquery(URP11,''Select '+@sql_Fields +' From JTURP.dbo.iSeriesSales'') ' + char(10)
								 + '				select '+@sql_Fields +' From  openquery(URP11,''Select '+@sql_Fields +' From JTURP.dbo.iSeries where seriescode in('+replace(@SQL_Seriescode,'''','''''')+')'')'
						--print @sql
						
						exec sp_executesql @sql,N'@sql_Fields varchar(max),@SQL_Seriescode varchar(max)',
						@sql_Fields=@sql_Fields,@SQL_Seriescode=@SQL_Seriescode
						if @@ROWCOUNT>0
							BEGIN
								--ɾ������
								/*
								delete from openquery(URP11,'select seriescode from JTURP.dbo.iSeries is2 where seriescode in('+@SQL_Seriescode+')')
								*/
 
 
								SET @sql = 'delete from openquery(URP11,''select seriescode from JTURP.dbo.iSeries is2 where seriescode in('+replace(@SQL_Seriescode,'''','''''')+')'')'
								exec sp_executesql @sql,N'@SQL_Seriescode varchar(max)',@SQL_Seriescode=@SQL_Seriescode
								--��¼������־
								SET @sql = 'insert into openquery(URP11,''Select Seriescode,Formid,Formtype,doccode,doctype,stcode,instcode,remark  From JTURP.dbo.iSeriesLog'') ' + char(10)
								 + '				select Seriescode,Formid,Formtype,doccode,doctype,stcode,instcode,remark '+ dbo.crlf()+
								 ' From  openquery(URP11,''Select seriescode,4950 as formid,5 as formtype,'''''+@doccode + ''''' as doccode,'+dbo.crlf()+
								 '''''�������ͻ���'''' as doctype,'''''+@stcode+''''' as instcode,'''''+@fhstcode+''''' as stcode,''''�������ջ�ת�����۴���'''' as remark '+dbo.crlf()+
								 ' From JTURP.dbo.iSeries where seriescode in(' +replace(@SQL_Seriescode,'''','''''')+')'')'
								 
								exec sp_executesql @sql,N'@Formid int,@doccode varchar(30),@stcode varchar(50),@fhstcode varchar(50)',
								@formid=@formid,@Doccode=@Doccode,@stcode=@stcode,@fhstcode=@fhstcode--,@remark=@remark
							END
					end
					
					--�����മ��д�봮�ű�
					/*insert into openquery(URP11,'Select '+@SQL_Seriescode+' From JTURP.dbo.iseries')
					select is2.* from iSeries is2 with(nolock) inner join #iseries b on is2.SeriesCode=b.seriescode
					where b.state is null*/
 
					
					SET @sql = 'insert into openquery(URP11,''Select '+@sql_Fields+' From JTURP.dbo.iseries'') ' + char(10)
							 + '			select is2.* from iSeries is2 with(nolock) inner join #iseries b on is2.SeriesCode=b.seriescode ' + char(10)
							 + '			where b.state=''�ͻ�'''
  
					EXEC ( @sql)
					select @rowcount=@@ROWCOUNT
 
					--��¼������־
					if @ROWCOUNT>0
						BEGIN
 
							SET @sql = 'insert into openquery(URP11,''Select Seriescode,Formid,Formtype,doccode,doctype,stcode,instcode,remark  From JTURP.dbo.iSeriesLog'') ' + char(10)
									 + '				select  seriescode,4950 as formid,5 as formtype,'''+@doccode+''' as doccode,'+dbo.crlf()+
									 '''�������ͻ���'' as doctype,'''+@stcode+''' as instcode,'''+@fhstcode+''' as stcode,''�������ջ�ת���´���'' as remark '+dbo.crlf()+
									 ' From #iSeries where state=''�ͻ�'''
									-- print @sql
									exec sp_executesql @sql/*,N'@Formid int,@SQL_Seriescode varchar(max),@doccode varchar(30),@stcode varchar(50),@fhstcode varchar(50)',
									@formid=@formid,@SQL_Seriescode=@SQL_Seriescode,@Doccode=@Doccode,@stcode=@stcode,@fhstcode=@fhstcode,@remark=@remark*/
						END
					ELSE
					BEGIN
 
							RAISERROR('δ�ܽ�����ת����URP����ϵͳ,����ϵϵͳ����Ա.',16,1)
							return
						END
					--������ϻ�������
					if @TRANCOUNT=0 and xact_state() =1 commit
			END TRY
			begin catch
 
				if  xact_state() =-1 rollback
				select @tips=dbo.getLastError('�ջ������쳣.')
				raiserror(@tips,16,1)
				return
			end catch
	END
	
	 