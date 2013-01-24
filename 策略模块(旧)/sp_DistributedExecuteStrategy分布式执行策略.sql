/*
过程名称：sp_DistributedExecuteStrategy
功能描述：分布式执行策略。将数据源传输到指定服务器进行计算，计算后返回结果。
参数：见声名
编写：三断笛
时间：2013-01-15
备注:将传入的XML分别转换到两个临时表。在策略组中设置数据源时，可以直接使用此临时表。
示例：
*/
alter proc sp_DistributedExecuteStrategy
	@FormID varchar(20),											--功能号
	@Doccode VARCHAR(20),									--单号
	@Event INT=0,													--执行时间，1：保存时 2：确认时 3：提交时 4：自定义
	@Optionid VARCHAR(100)='',								--选项
	@UserCode VARCHAR(50)='',								--执行人
	@TerminalID VARCHAR(50)='',							--终端编码
	@DocDataXML nvarchar(max)=NULL,					--策略单据数据源,以XML传入,必须是For XML RAW格式,以<root>为根节点.
	@DataSourceXML nvarchar(max)=NULL,				--策略数据源，以XML传入，格式如<root><DataTable TableName="表名" Definition="表定义"><row 表格数据/></DataTable></root>
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
					raiserror('单据数据源不存在,无法匹配策略组.',16,1)
					return
				END
		--定义变量
		SELECT @sql='Declare @hXMLDataSource int' +dbo.crlf()
		--若XML数据源不为空,则对XML数据源进行解析.
		if isnull(@DataSourceXML,'')<>''
			BEGIN
				begin try
					declare @xml XML,@i int
					select @xml=convert(xml,@DataSourceXML),@i=1
					--解析数据表个数
					select @TableCount=@xml.value('count(root/DataTable)','int')
					--遍历数据表
					if isnull(@TableCount,0)>0
						BEGIN
							while @i<=@TableCount
								BEGIN
									
									--取出数据表的表名和定义
									select @sql_xml='Select @tableName=@XML.value(''(/root/DataTable/@TableName)['+convert(varchar(10),@i)+']'',''varchar(50)'') ,@Definition=@XML.value(''(/root/DataTable/@Definition)['+convert(varchar(10),@i)+']'',''varchar(max)'')'
									exec sp_executesql @sql_xml,N'@TableName varchar(50) output,@Definition varchar(max) output,@XML xml',@Definition=@Definition output,@xml=@xml,@tableName=@tableName output
									--若不幸表名为空,则自动为其命名
									if isnull(@TableName,'')='' set @TableName='#DataTable'+convert(varchar(5),@i)
 
									--生成XML文档,并转换成临时表
									set @sql=@sql+'exec sp_XML_PrepareDocument @hXMLDataSource Output,@DataSourceXML' +dbo.crlf()
									set @sql=@sql+'Select * Into '+@tableName+' From OpenXML(@hXMLDataSource,N''/root/DataTable['+convert(varchar(5),@i)+']/row'',1) with('+@Definition+')' +dbo.crlf()
									set @sql=@sql+'exec sp_XML_RemoveDocument @hXMLDataSource'+dbo.crlf()
									set @i=@i+1
								END
						END
				end try
				begin catch
					select @tips=dbo.getLastError('解析数据源失败.')+dbo.crlf()+replace(@DataSourceXML,'>','>'+char(10))
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
				select @tips=dbo.getLastError('分布式执行策略失败.')
				raiserror(@tips,16,1)
				return 0
			END CATCH
			return @ret
	END
	