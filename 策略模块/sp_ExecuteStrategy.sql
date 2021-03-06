/*
过程名称：[sp_ExecuteStrategy]
功能：策略执行入口
参数：见声名
返回：
编写：三断笛
时间：2012-02-18
备注：在调用此过程前，必须将单据数据存储至#DocData,而且必须包含SdorgPath,AreaPath,MatgroupMath,Formid等基本字段
该模块的基本原理是:
1.存储过程可使用过程外的临时表,这样以实现将关键数据缓存后供后续多个过程进行处理,最终得到需要的数据
2.调用表达式解析引擎对表达式进行运算.

在本模块中#DocData,#StrategyGroup,#Strategy,输入数据源,输出数据源之间的关系是:
#DocData:一般是业务数据,必须含有DocCode,SdorgPath,AreaPath,MatgroupMath,Formid等字段,用于匹配策略组,也仅用于匹配策略组.获得匹配成功的策略组后才能进行策略匹配.
		此数据可以是一行,也可以是多行,但是,单号必须唯一.
		调用此过程前,必须仔细准备好这份数据,而且名字也必须一致!
#DataSource:
	数据来源.一般是业务数据源,指需要用来与策略进行条件匹配的数据.若此处不提供,则会默认采用#DocData作为数据输入.#DataSource必须有唯一的行标志,这样才能区分每一行.
	进行策略匹配后
#StrategyGroup:包含策略数据与单据数据.是单据对策略组进行过滤后的结果.
			在这里,策略编码是唯一的,而单号不一定唯一了,因为一个单可以匹配到多个策略组.
输入数据源:也是业务数据.但它是用于匹配策略的,而不是策略组.策略包含的信息一般比策略组更多,因此它包含的信息一般也比#DocData多.
			当然,如果输入数据源本身就是表头,那输入数据源可以不传入,组件会自动以#DocData作为输入数据源.
			输入数据源必须要有行标志.
#Strategy:策略结果数据.它存储的是输入数据源与策略数据匹配过后的结果.它包含输入数据源的所有列与相匹配的策略信息.
		还包含用于存储计算结果的空结果列,这些列会在计算结果是填充.
输出数据源:策略计算完毕后,将数据输出至此表的一些字段.它与输入数据源用唯一行标志关联(如Doccode,RowID).
一个策略组可以有多个策略.每个策略可以有多个策略明细.
StrategyID:一般直接用NEWID(),用于唯一标志整个策略组中的每一行策略明细.
DocRowFlag:单据的唯一行标志
StrategyCode:策略编码.每一个策略有若干项策略明细组成.
StrategyName:策略名称
StrategyRowID:策略明细的唯一标志.和StrategyID不同的是,StrategyID在一个策略组中的所有策略明细的唯一标志,而StrategyRowID只是一个策略的策略明细行标志.StrategyRowID整个策略组,不同的策略中,可以有重复.
StrategyPriority:策略明细优先级别.
StrategyFilter:策略过滤表达式.策略过滤时,会先过滤策略的表达式,当策略符合条件时,再进一步匹配策略明细.
DocFilter:策略明细过滤表达式.
StratetyValueExpression:策略结果值表达式
StratetyValue:计算后的策略值.

本模块执行流程:
1.准备#DocData基本业务单据,调用[sp_ExecuteStrategy],开启策略执行
2.在sp_ExecuteStrategy,先匹配出业务数据(#DocData)与策略组匹配的数据,得到策略组合#StrategyGroup,用于做策略匹配.
3.游标遍历所有得到策略组.对每一个策略组执行ProcessStrategy过程,对策略进行进一步过滤器.
4.执行MatchStrategy对策略和#Datasource进行匹配,将匹配结果(包含策略唯一标志,业务唯一标志,及策略表达式)写入#Strategy.此步只将策略中的固定部分(即非动态表达式部分)与#Datasource进行匹配
5.执行FilterStrategy,对策略结果#Strategy的动态表达式部分进行匹配,并且依照优先级等去除重复数据.判断是否重复的标准是保证每个策略只匹配到一行业务数据的唯一标志,最后只留下需要进行计算的策略
6.执行ComputeStrategy对策略(#Strategy)的值进行计算,并将计算结果写入#Strategy
7.执行OutputStrategy,按照输出表唯一标志将#Strategy中的结果输出至指定表的指定字段.
示例：
----------------------------------------------
*/
ALTER PROC [dbo].[sp_ExecuteStrategy]
	@FormID varchar(20),			--功能号
	@Doccode VARCHAR(20),			--单号
	@Event INT=0,					--执行时间，1：保存时 2：确认时 3：提交时 4：自定义
	@Optionid VARCHAR(100)='',		--选项
	@UserCode VARCHAR(50)='',		--执行人
	@TerminalID VARCHAR(50)='',		--终端编码
	@Result nvarchar(max)='' OUTPUT
AS
	BEGIN
		SET NOCOUNT ON;
		 
		DECLARE @sql nVARCHAR(MAX)								--动态执行的语句
		DECLARE @StrategyGroup VARCHAR(50),						--策略组编码
		@StrategyGroupName VARCHAR(200),						--策略级名称
		--@DocFilter VARCHAR(500),								--策略组过滤条件
		--@StrategyCondition VARCHAR(500),						--策略组过滤条件
		@DataSource VARCHAR(500),								--数据源SQL语句
		@StrategyMatch VARCHAR(500),							--策略匹配接口过程
		@StrategyOutput VARCHAR(500),							--策略输出接口过程
		@StrategyCompute VARCHAR(500),							--策略计算接口过程
		@MapFormID varchar(200),								--字段映射表功能号
		@OutputTable VARCHAR(50),								--输出表
		@OutputFields VARCHAR(500),								--输出字段
		@ComputeProc VARCHAR(500),								--策略计算接口过程
		@ComputeType VARCHAR(50),								--计算类型
		@OutputType VARCHAR(50),								--输出类型
		@RowFlag VARCHAR(100),									--输出表标志
		@FormID1 VARCHAR(20),
		@Doccode1 VARCHAR(20),
		@DataSourceRowFlag VARCHAR(50),							--数据源行标志
		@DatasourceOutputRowFlag varchar(50),					--数据源往输出表输出数据时,数据源的输出字段,这个字段与输出表的输出字段值对应
		@tips varchar(max),										--提示信息,一般用于记录异常信息以抛出.
		@MatchType VARCHAR(20),									--匹配方式
		@ErrorText VARCHAR(2000),								--策略组异常信息

		@RowCount int											--临时记录数据行数
		
		--为保证效率,#DocData中的单据编号必须唯一.
		 IF EXISTS(SELECT Doccode FROM #DocData GROUP BY Doccode HAVING COUNT(doccode)>1)
			BEGIN
				RAISERROR('输入的业务数据主键不唯一,请与系统管理员联系!',16,1)
				return
			END 
			
		--匹配策略组,将匹配结果插入临时表
		--策略组只与单据的表头进行关联.
		SELECT a.*,b.strategygroup,b.Datasource,b.RowFlag,b.Expression as StrategyGroupFilter,b.ComputeProc,b.Computetype,
		b.FilterProc,b.OutputProc,b.OutputType,b.OutputFields,b.MapFormID,b.outputtable,b.dataSourceRowFlag,b.MatchType,b.ErrorText,
		b.StrategyGroupName,b.DatasourceOutputRowFlag
		INTO #Strategygroup
		FROM #DocData a, T_StrategyGroup b
			WHERE b.enable=1
			AND EXISTS(SELECT 1 FROM SPLIT(b.formid,',') x WHERE x.list=a.formid)
			AND (ISNULL(b.sdorgid,'')='' OR a.sdorgPath LIKE '%/'+b.sdorgid+'/%')
			AND (ISNULL(b.areaid,'')='' OR a.areaPath LIKE '%/'+b.areaid+'/%')
			AND (ISNULL(b.BeginDay,'')='' or b.BeginDay<=a.docdate)
			AND (ISNULL(b.EndDay,'')='' OR b.EndDay>=a.docdate)
			AND ((b.RunAfterSave=1 AND @Event&1=1) OR (b.RunAtPost=1 AND @Event&2=2))				--状态检查
		--记录匹配到的数据行数
		select @RowCount=@@ROWCOUNT
		--若没有匹配到数据
		if @RowCount=0 RETURN
					
		--剔除不符合其他条件,可以将此条件直接放在上一句中执行，但是为性能考虑，必须保证传入动态表达式的数据最少,故分开执行。
		--因为匹配后的策略组必须是唯一的,所以可以把策略组当成动态表达式的活动行.
		begin try
			DELETE from #Strategygroup
			WHERE dbo.ExecuteScalar(0,StrategyGroupFilter, 'Select * From #Strategygroup','Strategygroup='''+Strategygroup+'''',-1,
			'Select * from fn_getFormulaFields('''+convert(varchar(50),COALESCE(MapFormID,@FormID,'') )+''')',1)=0
			AND ISNULL(StrategyGroupFilter,'')<>''
			--若删除的行数大于(事实上不可能)或等于原有数据行数,则直接退出
			if @@ROWCOUNT>=@RowCount return
		end try
		begin catch
			select @tips='执行策略组过滤失败!'+dbo.crlf()+isnull(error_Message(),'')+dbo.crlf()
			raiserror(@tips,16,1)
			return
		end CATCH
		--select * from #Strategygroup
		--如果没有策略组数据，则直接返回  
		IF NOT exists(SELECT 1 FROM #Strategygroup) return
		--游标遍历所有匹配的政策，为了更高效使用游标，这里使用的是只读，仅向前游标。
		DECLARE curStrategyGroup CURSOR READ_ONLY FORWARD_ONLY  FOR
		SELECT  Doccode,FormID,strategygroup,DataSource,FilterProc, RowFlag,ComputeProc,ComputeType,OutputProc,
			OutputType,OutputFields,MapFormID,OutputTable,dataSourceRowFlag,MatchType,errortext,StrategyGroupName,
			coalesce(nullif(DatasourceOutputRowFlag,''),DatasourceRowFlag) as DatasourceOutputRowFlag
			FROM #Strategygroup
		OPEN curStrategyGroup
		--注意在此游标中,将单号和功能号存入了@Doccode1和@FormID1,而不使用@Doccode和@FormID,这是为了处理输入的数据源不止一个单号的问题.
		FETCH NEXT FROM curStrategyGroup INTO @Doccode1,@FormID1 ,@StrategyGroup,@DataSource,@StrategyMatch ,@RowFlag,@ComputeProc,
			@ComputeType,@StrategyOutput,@OutputType,@OutputFields,@MapFormID,@OutputTable,@DataSourceRowFlag,@MatchType,@ErrorText,
			@StrategyGroupName,@DatasourceOutputRowFlag
			
		WHILE @@FETCH_STATUS=0
			BEGIN

				--定义变量
				SELECT @sql='Declare @ObjectID int' +dbo.crlf()
				--print @StrategyGroup
				--创建数据源临时表，若未设置数据源，则直接使用单据数据
				IF isnull(@DataSource,'')=''
					begin
						SET @sql=@sql+'Select * Into #DataSource From #DocData' +dbo.crlf()
					end
				ELSE
				BEGIN
					--可以在输入数据源中直接使用@Doccode,@FormID关键字,将在这里替换成实际的值.
					SET @DataSource=REPLACE(@DataSource,'@Doccode',''''+  ISNULL(@Doccode1,'') +'''' )
					SET @DataSource=REPLACE(@DataSource,'@FormID',CONVERT(VARCHAR(10),ISNULL(@FormID1,'')))
					--SET @DataSource=REPLACE(@DataSource,'''','''''''')
					SET @sql=@sql+'Select * Into #DataSource From ('+@DataSource+') a' +dbo.crlf()
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
				/*
					#Strategy表结构
					StrategyID	UNIQUEIDENTIFIER					NEWID()自动生成,用以区分匹配结果的每一行
					DocRowFlag	varchar(20)							数据源唯一行标志.
					DatasourceOutputRowFlag	varchar(50)				数据源与输出表唯一标志列的对应字段,用于输出
					StrategyCode	varchar(20)						策略编码
					StrategyName	varchar(50)						策略名称
					StrategyRowID	varchar(50)						策略明细唯一标志,即策略行的RowID
					StrategyPriority	int							策略优先级
					StrategyFilter	varchar(5000)					策略表头过滤表达式
					DocFilter	varchar(5000)						策略明细表过滤表达式
					StratetyValueExpression	varchar(5000)			策略计算表达式
					StratetyValue	SQL_VARIANT						策略计算结果输出值
					
				*/
				--匹配策略，再将结果插入临时表#Strategy
				SET @sql =@sql+'--装配策略数据临时表#Strategy'+char(10)
						 + '				SELECT  Replicate('''',5000)  as StrategyID,Replicate('''',5000)  as DocRowFlag,Replicate('''',5000)  as DatasourceOutputRowFlag,Replicate('''',5000)  as StrategyCode,'
						 +'						Replicate('''',5000)  as StrategyName,Replicate('''',5000)  as StrategyRowID, ' + char(10)
						 + '					NULL AS StrategyPriority, Replicate('''',5000)  as StrategyFilter, ' + char(10)
						 + '					Replicate('''',5000)  as DocFilter,Replicate('''',5000)  AS StratetyValueExpression, ' + char(10)
						 + '					CONVERT(SQL_VARIANT,'''')  AS StratetyValue  ' + char(10)
						 + '				INTO #Strategy  ' + char(10)
						 + '				FROM #Datasource a WHERE 1=2 ' + char(10)
						 + '	--执行策略匹配、策略计算与策略输出 ' + char(10)
						 + '				EXEC sp_ProcessStrategy '+Convert(varchar(10),ISNULL(@FormID1,0))+','''
											+ISNULL(@Doccode1,'')+''','''+Convert(varchar(10),ISNULL(@MapFormID,@FormID1))+''','''
											+ISNULL(@StrategyGroup,'')+''','''+ ISNULL(@StrategyGroupName,'')+''',''' 
											+ISNULL(@StrategyMatch,'sp_MatchStrategy')+''','''+ISNULL(@MatchType,'1')+''','''
											+ISNULL(@StrategyCompute,'sp_ComputeStrategy')+''','''+ISNULL(@StrategyOutput,'sp_OutputStrategy')+''',''' 
											+ISNULL(@ComputeType,'覆盖')+''','''+ISNULL(@OutputType,'至数据表')+''','''
											+ISNULL(@OutputTable,'')+''','''+ISNULL(@OutputFields,'')+''','''
											+ISNULL(@ErrorText,'')+''',''' +ISNULL(@DataSourceRowFlag,'')+''','''+ISNULL(@DatasourceOutputRowFlag,'')+''','''
											+ISNULL(@RowFlag,'')+''','''+ISNULL(@Optionid,'')+''','''+ISNULL(@UserCode,'')+''','''
											+ISNULL(@TerminalID,'')+'''' +CHAR(10)
				SET @sql=@sql+'Drop Table #Strategy'+CHAR(10)
				+'Drop Table #DataSource;'
				EXEC( @sql)
				FETCH NEXT FROM curStrategyGroup INTO @Doccode1,@FormID1 ,@StrategyGroup,@DataSource,@StrategyMatch ,@RowFlag,@ComputeProc,
					@ComputeType,@StrategyOutput,@OutputType,@OutputFields,@MapFormID,@OutputTable,@dataSourceRowFlag,@MatchType,@ErrorText,
					@StrategyGroupName,@DatasourceOutputRowFlag
			END
		Drop Table #Strategygroup
		ExitLine:
		CLOSE curStrategyGroup
		DEALLOCATE curStrategyGroup
			
	END
 
