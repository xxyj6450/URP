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
exec sp_ComfirmReceipt 'JDC2012112800026',4950,'SYSTEM','102','2.1.769.09.29','','1243010B-4C4E-40FE-AAC5-B3AD367AA74D','1',''

select instanceid,stcode,instcode from spickorderhd where doccode='JDC2012112800026'
print dbo.instanceid()
rollback
1.868429010299206[����A60+��ɫ]
2.862726019083960[����V889D-WCDMA��ɫ]
3.867439011788645[����W619�������ɫ]
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
		@AccessName varchar(200),@SYSTEMNAME varchar(50)
		
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
		
		/************************************************��ʼ������******************************************************************/
		
		/***********************************************************ҵ����****************************************************/
		select @TRANCOUNT=@@TRANCOUNT
		if @trancount=0 begin tran
		begin try
			--�����ͻ���
			if @InstanceID=dbo.InstanceID()
				BEGIN
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
				END
			else
				BEGIN
						select @sql='Update '+@AccessName+'.dbo.spickorderhd'+dbo.crlf()+
						'set getok=''���ջ�'','+dbo.crlf()+
						'	getday=convert(varchar(30),getdate(),120),'+dbo.crlf()+
						'	getname = '''+@Usercode+''''+dbo.crlf()+
						'where DocCode='''+@Doccode+''''+dbo.crlf()+
						'and getok=''δ�ջ�'''
						PRINT @sql
						exec(@sql)
						if @@ROWCOUNT=0
							BEGIN
								raiserror('�Ҳ����ͻ������ͻ������ڿ��ջ�״̬,���ʵ�˵��Ƿ��ѷ���,������������ϵ�����ܲ�.',16,1)
								return
							END
				END
			--PRINT 'ִ�е�����'
			--�������ƽ̨(������Դ)����URP����ϵͳ(Ŀ��ϵͳ),�Ͳ��ٶԴ��Ž��д�����
			if @AccessName='URP11.JTURP' return
			--ȡ�����ű��ֶ�
			select @sql_Fields=''
			select @sql_Fields=@sql_Fields+s.name+','
			from syscolumns s
			where s.id=object_id('iSeries')
			select @sql_Fields=left(@sql_Fields,len(@sql_Fields)-1)
			
			--ȡ�����ŵ�
			select @refcode=doccode from iseriesloghd i with(nolock) where i.refCode=@Doccode
			--ȡ�����Ż�������ʱ��,�Թ�����ʹ��.
			select i2.seriescode,i2.rowid,i2.matcode,i2.matname,i2.docitem,convert(varchar(20),'') as state
			into #iSeries 
			from iserieslogitem i2 with(nolock)
			where i2.doccode=@refcode
			--ȡ����Щ������URP�еĴ���״̬
			update a
				set a.state=b.state
			from #iseries a inner join URP11.JTURP.dbo.iSeries b with(nolock) on a.seriescode=b.seriescode
			
			--�жϴ�����URPϵͳ���Ƿ����,�����ڷ����۵Ĵ���,���׳��쳣.
			select @tips='���´�������URPϵͳ���Ѵ���,�޷���������.'+dbo.crlf()
			select @tips=@tips+convert(varchar(5),b.docitem)+'.'+b.seriescode+'['+b.matname+']'+dbo.crlf()
			from   #iSeries b
			where isnull(b.state,'����') not in('����','')
			if @@ROWCOUNT>0
				BEGIN
					raiserror(@tips,16,1)
					return
				END
		
			--��URP�����۵Ĵ�������
			select @SQL_Seriescode=''
			select @SQL_Seriescode=@SQL_Seriescode+''''+seriescode+''''+','
			from #iseries 
			where state='����'
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
								return
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
							 + '			where b.state='''''
					--print @sql
					EXEC sp_executesql @sql,N'@sql_Fields varchar(max)',@sql_Fields=@sql_Fields
					
					--��¼������־
					if @@ROWCOUNT>0
						BEGIN
							SET @sql = 'insert into openquery(URP11,''Select Seriescode,Formid,Formtype,doccode,doctype,stcode,instcode,remark  From JTURP.dbo.iSeriesLog'') ' + char(10)
									 + '				select  seriescode,4950 as formid,5 as formtype,'''+@doccode+''' as doccode,'+dbo.crlf()+
									 '''�������ͻ���'' as doctype,'''+@stcode+''' as instcode,'''+@fhstcode+''' as stcode,''�������ջ�ת�����۴���'' as remark '+dbo.crlf()+
									 ' From #iSeries where state='''''
									-- print @sql
									exec sp_executesql @sql/*,N'@Formid int,@SQL_Seriescode varchar(max),@doccode varchar(30),@stcode varchar(50),@fhstcode varchar(50)',
									@formid=@formid,@SQL_Seriescode=@SQL_Seriescode,@Doccode=@Doccode,@stcode=@stcode,@fhstcode=@fhstcode,@remark=@remark*/
						END		
					--������ϻ�������
					if @TRANCOUNT=0 commit
			END TRY
			begin catch
				if @TRANCOUNT=0 and xact_state()!=-1 rollback
				select @tips='�ջ������쳣.'+dbo.crlf()+isnull(error_message(),'')+dbo.crlf()+'�쳣������'+isnull(error_procedure(),'')+'��'+convert(varchar(10),isnull(error_line(),0))+'��'
				raiserror(@tips,16,1)
				return
			end catch
	END
	
	 