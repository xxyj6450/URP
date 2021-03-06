/*
过程名称：sp_ExecuteStrategy
功能：策略处理接口
参数：见声名
返回：策略被完全执行的次数。若策略在执行过程中被完全过滤掉，或出错，则返回0.每个策略被完全执行一次返回值将累加1
编写：三断笛
时间：2012-02-18
备注：在调用此过程前，必须将单据数据存储至#DocData,而且必须包含SdorgPath,AreaPath,MatgroupMath,Formid等基本字段
在本模块中#DocData,#StrategyGroup,#Strategy,输入数据源,输出数据源之间的关系是:
#DocData:一般是业务数据,必须含有DocCode,SdorgPath,AreaPath,MatgroupMath,Formid等字段,用于匹配策略组,也仅用于匹配策略组.
		此数据可以是一行,也可以是多行,但是,单号必须唯一.
		调用此过程前,必须仔细准备好这份数据,而且名字也必须一致!
#DataSource:

#StrategyGroup:包含策略数据与单据数据.是单据对策略组进行过滤后的结果.
			在这里,策略编码是唯一的,而单号不一定唯一了,因为一个单可以匹配到多个策略组.
输入数据源:也是业务数据.但它是用于匹配策略的,而不是策略组.策略包含的信息一般比策略组更多,因此它包含的信息一般也比#DocData多.
			当然,如果输入数据源本身就是表头,那输入数据源可以不传入,组件会自动以#DocData作为输入数据源.
			输入数据源必须要有行标志.
#Strategy:策略结果数据.它存储的是输入数据源与策略数据匹配过后的结果.它包含输入数据源的所有列与相匹配的策略信息.
		还包含用于存储计算结果的空结果列,这些列会在计算结果是填充.
输出数据源:策略计算完毕后,将数据输出至此表的一些字段.它与输入数据源用唯一行标志关联(如Doccode,RowID).

示例：
----------------------------------------------
*/
ALTER PROC [sp_ExecuteStrategy]
	@FormID varchar(20),											--功能号
	@Doccode VARCHAR(20),									--单号
	@Event INT=0,													--执行时间，1：提交时 2：保存时 4：确认时  其余：自定义
	@Optionid VARCHAR(100)='',								--选项
	@UserCode VARCHAR(50)='',								--执行人
	@TerminalID VARCHAR(50)='',							--终端编码
	@Result varchar(max)='' OUTPUT
AS
	BEGIN
		--SET NOCOUNT ON;
 
		DECLARE @sql nVARCHAR(MAX),@ret int,@ret1 int
		DECLARE @StrategyGroup VARCHAR(50),@DocFilter VARCHAR(500),@StrategyCondition VARCHAR(500),@DataSource VARCHAR(500),
		@StrategyMatch VARCHAR(500),@StrategyOutput VARCHAR(500),@StrategyCompute VARCHAR(500),@MapFormID varchar(200),@OutputTable VARCHAR(50),
		@OutputFields VARCHAR(500),@ComputeProc VARCHAR(500),@ComputeType VARCHAR(50),@OutputType VARCHAR(50),
		@RowFlag VARCHAR(100),@FormID1 VARCHAR(20),@Doccode1 VARCHAR(20),@DataSourceRowFlag VARCHAR(50),@tips varchar(max),@bitRecordLog bit
		
		declare @retXML varchar(max)
		
		--为保证效率,#DocData中的单据编号必须唯一.
		 IF EXISTS(SELECT Doccode FROM #DocData GROUP BY Doccode HAVING COUNT(doccode)>1)
			BEGIN
 
				RAISERROR('输入的业务数据主键不唯一,请与系统管理员联系!',16,1)
				return
			END 
		--匹配策略组,将匹配结果插入临时表
		--策略组只与单据的表头进行关联.
		SELECT a.*,b.strategygroup,b.Datasource,b.RowFlag,b.Expression as StrategyGroupFilter,b.ComputeProc,b.Computetype,
		b.FilterProc,b.OutputProc,b.OutputType,b.OutputFields,b.MapFormID,b.outputtable,b.dataSourceRowFlag,b.bitRecordLog
		INTO #Strategygroup
		FROM #DocData a, T_StrategyGroup b
			WHERE b.enable=1
			AND EXISTS(SELECT 1 FROM SPLIT(b.formid,',') x WHERE x.list=a.formid)
			AND (ISNULL(b.sdorgid,'')='' OR a.sdorgPath LIKE '%/'+b.sdorgid+'/%')
			AND (ISNULL(b.areaid,'')='' OR a.areaPath LIKE '%/'+b.areaid+'/%')
			AND (ISNULL(b.BeginDay,'')='' or b.BeginDay<=a.docdate)
			AND (ISNULL(b.EndDay,'')='' OR b.EndDay>=a.docdate)
			AND ((b.RunAfterSave=1 AND @Event&2=2) OR (b.RunAtPost=1 AND @Event&4=4) or ( b.RunAtSubmit=1 and @Event&1=1) or isnull(b.RunByCustomer,0)=@Event)
		if @@rowcount=0 return 0
 
		--剔除不符合其他条件,可以将此条件直接放在上一句中执行，但是为性能考虑，必须保证传入动态表达式的数据最少,故分开执行。
		--因为匹配后的策略组必须是唯一的,所以可以把策略组当成动态表达式的活动行.
		begin try
			DELETE from #Strategygroup
			WHERE dbo.ExecuteScalar(0,StrategyGroupFilter, 'Select * From #Strategygroup','Strategygroup='''+Strategygroup+'''',-1,
			'Select * from fn_getFormulaFields('''+convert(varchar(50),COALESCE(MapFormID,@FormID,'') )+''')',1)=0
			AND ISNULL(StrategyGroupFilter,'')<>''
		end try
		begin catch
			select @tips='执行策略组过滤失败!'+dbo.crlf()+error_Message()+dbo.crlf()+@sql
			raiserror(@tips,16,1)
			return
		end catch
		
		--如果没有策略组数据，则直接返回  
		IF NOT exists(SELECT 1 FROM #Strategygroup) return 0
		
		--游标开始时准备输出XML的根节点
		set @retXML='<root>'
 
		--游标遍历所有匹配的政策，为了更高效使用游标，这里使用的是只读，仅向前游标。
		DECLARE curStrategyGroup CURSOR READ_ONLY FORWARD_ONLY FORWARD_ONLY FOR
		SELECT  Doccode,FormID,strategygroup,DataSource,nullif(rtrim(ltrim(FilterProc)),''), RowFlag,nullif(rtrim(ltrim(ComputeProc)),''),ComputeType,nullif(rtrim(ltrim(OutputProc)),''),
			OutputType,OutputFields,MapFormID,OutputTable,dataSourceRowFlag,isnull(bitRecordLog,0) as bitRecordLog FROM #Strategygroup
		OPEN curStrategyGroup
		--注意在此游标中,将单号和功能号存入了@Doccode1和@FormID1,而不使用@Doccode和@FormID,这是为了处理输入的数据源不止一个单号的问题.
		FETCH NEXT FROM curStrategyGroup INTO @Doccode1,@FormID1 ,@StrategyGroup,@DataSource,@StrategyMatch ,@RowFlag,@ComputeProc,
			@ComputeType,@StrategyOutput,@OutputType,@OutputFields,@MapFormID,@OutputTable,@DataSourceRowFlag,@bitRecordLog

		WHILE @@FETCH_STATUS=0
			BEGIN
				--定义变量
				SELECT @sql='Declare @ObjectID int' +dbo.crlf()
				--生成策略数据源
				if object_id('tempdb.dbo.#DataSource') is NULL
					BEGIN
						if isnull(@DataSource,'')<>''
							BEGIN
								--可以在输入数据源中直接使用@Doccode,@FormID关键字,将在这里替换成实际的值.
								SET @DataSource=REPLACE(@DataSource,'@Doccode',''''+  ISNULL(@Doccode1,'') +'''' )
								SET @DataSource=REPLACE(@DataSource,'@FormID',CONVERT(VARCHAR(10),ISNULL(@FormID1,'')))
								--SET @DataSource=REPLACE(@DataSource,'''','''''''')
								SET @sql=@sql+'Select * Into #DataSource From ('+@DataSource+') a' +dbo.crlf()
							END
						else
							BEGIN
								raiserror('策略组未设置数据源,无法继续执行,请联系系统管理员.',16,1)
								return
							END
					END
				--补充不存在的字段
				SET @sql = @sql+'SELECT @ObjectID=OBJECT_ID(''tempdb.dbo.#DataSource'')				--取出对象ID，不使用后面再使用Object_ID函数' + dbo.crlf()
				 + 'if not exists(SELECT 1 FROM tempdb.dbo.syscolumns s WHERE s.id=OBJECT_ID(''tempdb.dbo.#DataSource'') AND NAME=''PackageID'')	ALTER TABLE #DataSource ADD PackageID VARCHAR(20) ' + dbo.crlf()
				 + 'if not exists(SELECT 1 FROM tempdb.dbo.syscolumns s WHERE s.id=OBJECT_ID(''tempdb.dbo.#DataSource'') AND NAME=''ComboCode'')	ALTER TABLE #DataSource ADD ComboCode int ' + dbo.crlf()
				 + 'if not exists(SELECT 1 FROM tempdb.dbo.syscolumns s WHERE s.id=OBJECT_ID(''tempdb.dbo.#DataSource'') AND NAME=''areaPath'')		ALTER TABLE #DataSource ADD areaPath VARCHAR(500) ' + dbo.crlf()
				 + 'if not exists(SELECT 1 FROM tempdb.dbo.syscolumns s WHERE s.id=OBJECT_ID(''tempdb.dbo.#DataSource'') AND NAME=''sdorgPath'')	ALTER TABLE #DataSource ADD sdorgPath VARCHAR(500) ' + dbo.crlf()
				 + 'if not exists(SELECT 1 FROM tempdb.dbo.syscolumns s WHERE s.id=OBJECT_ID(''tempdb.dbo.#DataSource'') AND NAME=''seriescode'')	ALTER TABLE #DataSource ADD seriescode VARCHAR(50) ' + dbo.crlf()
				 + 'if not exists(SELECT 1 FROM tempdb.dbo.syscolumns s WHERE s.id=OBJECT_ID(''tempdb.dbo.#DataSource'') AND NAME=''matgroupPath'')	ALTER TABLE #DataSource ADD matgroupPath VARCHAR(500) ' + dbo.crlf()
				 + 'if not exists(SELECT 1 FROM tempdb.dbo.syscolumns s WHERE s.id=OBJECT_ID(''tempdb.dbo.#DataSource'') AND NAME=''matcode'')		ALTER TABLE #DataSource ADD matcode VARCHAR(50) ' + dbo.crlf()
				 + 'if not exists(SELECT 1 FROM tempdb.dbo.syscolumns s WHERE s.id=OBJECT_ID(''tempdb.dbo.#DataSource'') AND NAME=''companyid'')	ALTER TABLE #DataSource ADD companyid VARCHAR(50) ' + dbo.crlf()
				 + 'if not exists(SELECT 1 FROM tempdb.dbo.syscolumns s WHERE s.id=OBJECT_ID(''tempdb.dbo.#DataSource'') AND NAME=''docdate'')		ALTER TABLE #DataSource ADD docdate DATETIME'+dbo.crlf()
				--匹配策略，再将结果插入临时表#Strategy
				SET @sql =@sql+'--装配策略数据临时表#Strategy'+char(10)
						 + '				SELECT  Replicate('''',4000)  as StrategyID,Replicate('''',4000)  as DocRowFlag,Replicate('''',4000)  as StrategyCode,'
						 +'						Replicate('''',4000)  as StrategyName,Replicate('''',4000)  as StrategyRowID, ' + char(10)
						 + '					NULL AS StrategyPriority, Replicate('''',4000)  as StrategyFilter, ' + char(10)
						 + '					Replicate('''',4000)  as DocFilter,Replicate('''',4000)  AS StrategyValueExpression, ' + char(10)
						 + '					CONVERT(SQL_VARIANT,'''')  AS StrategyValue  ' + char(10)
						 + '				INTO #Strategy  ' + char(10)
						 + '				FROM #Datasource a WHERE 1=2 ' + char(10)
						 + '	--执行策略匹配、策略计算与策略输出 ' + char(10)
						 + '				EXEC @ret= sp_ProcessStrategy '+Convert(varchar(10),ISNULL(@FormID1,0))+','''
											+ISNULL(@Doccode1,'')+''','''+Convert(varchar(10),ISNULL(@MapFormID,@FormID1))+''','''
											+ISNULL(@StrategyGroup,'')+''','''+ISNULL(@StrategyMatch,'sp_MatchStrategy')+''',''' 
											+ISNULL(@StrategyCompute,'sp_ComputeStrategy')+''','''+ISNULL(@StrategyOutput,'sp_OutputStrategy')+''',''' 
											+ISNULL(@ComputeType,'覆盖')+''','''+ISNULL(@OutputType,'至数据表')+''','''
											+ISNULL(@OutputTable,'')+''','''+ISNULL(@OutputFields,'')+''','''+ISNULL(@DataSourceRowFlag,'')+''','''
											+ISNULL(@RowFlag,'')+''','+convert(varchar(10),isnull(@bitRecordLog,0))+','''+ISNULL(@Optionid,'')+''','''+ISNULL(@UserCode,'')+''','''
											+ISNULL(@TerminalID,'')+''',@ResultXML output' +CHAR(10)
				SET @sql=@sql+'Drop Table #Strategy;'+CHAR(10)
				+'Drop Table #DataSource;'
				BEGIN TRY
					--print @sql
					--在返回XML中加入策略组信息
					set @retXML=@retXML+'<Strategygroup Strategygroup="'+@StrategyGroup+'">'
					EXEC sp_executesql @sql,N'@ResultXML varchar(max)   output ,@ret int output',@ResultXML= @Result output, @ret=@ret1 output
					set @ret=isnull(@ret,0)+isnull(@ret1,0)
					--再补上本次策略组输出的信息
					set @retXML=@retXML+ ISNULL(@Result,'') +'</Strategygroup>' 
				END TRY
				BEGIN CATCH
						select @tips=dbo.getLastError('策略执行失败.')
						raiserror(@tips,16,1)
						return 0
				END CATCH

				FETCH NEXT FROM curStrategyGroup INTO @Doccode1,@FormID1 ,@StrategyGroup,@DataSource,@StrategyMatch ,@RowFlag,@ComputeProc,
					@ComputeType,@StrategyOutput,@OutputType,@OutputFields,@MapFormID,@OutputTable,@dataSourceRowFlag,@bitRecordLog
			END
		Drop Table #Strategygroup
		ExitLine:
		CLOSE curStrategyGroup
		DEALLOCATE curStrategyGroup
		--结束本次策略执行,加入结束根节点.
		set @Result=@retXML+'</root>'
		return isnull(@ret,0)
END
 

