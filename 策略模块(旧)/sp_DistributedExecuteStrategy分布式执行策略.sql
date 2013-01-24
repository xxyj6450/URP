/*
�������ƣ�sp_DistributedExecuteStrategy
�����������ֲ�ʽִ�в��ԡ�������Դ���䵽ָ�����������м��㣬����󷵻ؽ����
������������
��д�����ϵ�
ʱ�䣺2013-01-15
��ע:�������XML�ֱ�ת����������ʱ���ڲ���������������Դʱ������ֱ��ʹ�ô���ʱ��
ʾ����
*/
alter proc sp_DistributedExecuteStrategy
	@FormID varchar(20),											--���ܺ�
	@Doccode VARCHAR(20),									--����
	@Event INT=0,													--ִ��ʱ�䣬1������ʱ 2��ȷ��ʱ 3���ύʱ 4���Զ���
	@Optionid VARCHAR(100)='',								--ѡ��
	@UserCode VARCHAR(50)='',								--ִ����
	@TerminalID VARCHAR(50)='',							--�ն˱���
	@DocDataXML nvarchar(max)=NULL,					--���Ե�������Դ,��XML����,������For XML RAW��ʽ,��<root>Ϊ���ڵ�.
	@DataSourceXML nvarchar(max)=NULL,				--��������Դ����XML���룬��ʽ��<root><DataTable TableName="����" Definition="����"><row �������/></DataTable></root>
	@Result varchar(max)='' OUTPUT
as
	BEGIN
		set NOCOUNT on;
		DECLARE @sql nVARCHAR(MAX),@ret int,@ret1 int,@tips varchar(max)
		declare @TableName varchar(50),@Definition varchar(max),@TableCount int
		declare @sql_xml nvarchar(max)
		if object_id('tempdb.dbo.#Docdata') is null 
			if  @DocDataXML is not NULL
				BEGIN
					Create TABLE #DocData(
						Doccode varchar(20),
						FormID int,
						DocDate datetime,
						SDOrgID varchar(50),
						SDOrgName varchar(200),
						stcode varchar(50),
						stName varchar(200),
						dptType varchar(50),
						AreaID varchar(50),
						SDOrgPath varchar(200),
						AreaPath varchar(200)
						)
					declare @hDoc INT
					exec sp_xml_preparedocument @hDoc output,@DocDataXML
					Insert   Into #Docdata
					Select * From OpenXML(@hDoc,N'/root/row',1)
					with #DocData--(SDORGID varchar(50),AreaID varchar(50),FormID int,Doccode varchar(50),DocDate datetime,Dpttype varchar(50),SDOrgPath varchar(200),AreaPath varchar(200),CompanyID varchar(50))
					exec sp_xml_removedocument @hDoc

				END
			else
				BEGIN
					raiserror('��������Դ������,�޷�ƥ�������.',16,1)
					return
				END
		--�������
		SELECT @sql='Declare @hXMLDataSource int' +dbo.crlf()
		--��XML����Դ��Ϊ��,���XML����Դ���н���.
		if isnull(@DataSourceXML,'')<>''
			BEGIN
				begin try
					declare @xml XML,@i int
					select @xml=convert(xml,@DataSourceXML),@i=1
					--�������ݱ����
					select @TableCount=@xml.value('count(root/DataTable)','int')
					--�������ݱ�
					if isnull(@TableCount,0)>0
						BEGIN
							while @i<=@TableCount
								BEGIN
									
									--ȡ�����ݱ�ı����Ͷ���
									select @sql_xml='Select @tableName=@XML.value(''(/root/DataTable/@TableName)['+convert(varchar(10),@i)+']'',''varchar(50)'') ,@Definition=@XML.value(''(/root/DataTable/@Definition)['+convert(varchar(10),@i)+']'',''varchar(max)'')'
									exec sp_executesql @sql_xml,N'@TableName varchar(50) output,@Definition varchar(max) output,@XML xml',@Definition=@Definition output,@xml=@xml,@tableName=@tableName output
									--�����ұ���Ϊ��,���Զ�Ϊ������
									if isnull(@TableName,'')='' set @TableName='#DataTable'+convert(varchar(5),@i)
 
									--����XML�ĵ�,��ת������ʱ��
									set @sql=@sql+'exec sp_XML_PrepareDocument @hXMLDataSource Output,@DataSourceXML' +dbo.crlf()
									set @sql=@sql+'Select * Into '+@tableName+' From OpenXML(@hXMLDataSource,N''/root/DataTable['+convert(varchar(5),@i)+']/row'',1) with('+@Definition+')' +dbo.crlf()
									set @sql=@sql+'exec sp_XML_RemoveDocument @hXMLDataSource'+dbo.crlf()
									set @i=@i+1
								END
						END
				end try
				begin catch
					select @tips=dbo.getLastError('��������Դʧ��.')+dbo.crlf()+replace(@DataSourceXML,'>','>'+char(10))
					raiserror(@tips,16,1)
					return
				end catch
			END
			select @sql=@sql+'EXEC @ret= sp_ExecuteStrategy ''' +convert(varchar(20),ISNULL(@FormID,0))+''','''+isnull(@Doccode,'')+''','+convert(varchar(10),isnull(@Event,0))+','''+isnull(@OptionID,'')+''','''+isnull(@Usercode,'')+''','''+isnull(@TerminalID,'')+''',@Result output' +dbo.crlf()
			BEGIN TRY
				print @sql
				EXEC sp_executesql @sql,N'@DataSourceXML nvarchar(max),@Result varchar(max) output,@ret int output',
				@DataSourceXML=@DataSourceXML,@Result=@Result output ,@ret=@ret  output
			END TRY
			BEGIN CATCH
				select @tips=dbo.getLastError('�ֲ�ʽִ�в���ʧ��.')
				raiserror(@tips,16,1)
				return 0
			END CATCH
			return @ret
	END
	