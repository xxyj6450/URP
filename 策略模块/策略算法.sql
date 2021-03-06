/*
过程名称：sp_ProcessStrategy
功能：策略处理接口
参数：见声名
返回：
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
Alter PROC sp_ExecuteStrategy
	@FormID varchar(20),			--功能号
	@Doccode VARCHAR(20),			--单号
	@Event INT=0,					--执行时间，1：保存时 2：确认时
	@Optionid VARCHAR(100)='',		--选项
	@UserCode VARCHAR(50)='',		--执行人
	@TerminalID VARCHAR(50)='',		--终端编码
	@Result XML='' OUTPUT
AS
	BEGIN
		SET NOCOUNT ON;
		 
		DECLARE @sql nVARCHAR(MAX)
		DECLARE @StrategyGroup VARCHAR(50),@DocFilter VARCHAR(500),@StrategyCondition VARCHAR(500),@DataSource VARCHAR(500),
		@StrategyMatch VARCHAR(500),@StrategyOutput VARCHAR(500),@StrategyCompute VARCHAR(500),@MapFormID varchar(200),@OutputTable VARCHAR(50),
		@OutputFields VARCHAR(500),@ComputeProc VARCHAR(500),@ComputeType VARCHAR(50),@OutputType VARCHAR(50),
		@RowFlag VARCHAR(100),@FormID1 VARCHAR(20),@Doccode1 VARCHAR(20),@DataSourceRowFlag VARCHAR(50),@tips varchar(max)
		--为保证效率,#DocData中的单据编号必须唯一.
		 IF EXISTS(SELECT Doccode FROM #DocData GROUP BY Doccode HAVING COUNT(doccode)>1)
			BEGIN
				RAISERROR('输入的业务数据主键不唯一,请与系统管理员联系!',16,1)
				return
			END 
		--匹配策略组,将匹配结果插入临时表
		--策略组只与单据的表头进行关联.
		SELECT a.*,b.strategygroup,b.Datasource,b.RowFlag,b.Expression as StrategyGroupFilter,b.ComputeProc,b.Computetype,
		b.FilterProc,b.OutputProc,b.OutputType,b.OutputFields,b.MapFormID,b.outputtable,b.dataSourceRowFlag
		INTO #Strategygroup
		FROM #DocData a, T_StrategyGroup b
			WHERE b.enable=1
			AND EXISTS(SELECT 1 FROM SPLIT(b.formid,',') x WHERE x.list=a.formid)
			AND (ISNULL(b.sdorgid,'')='' OR a.sdorgPath LIKE '%/'+b.sdorgid+'/%')
			AND (ISNULL(b.areaid,'')='' OR a.areaPath LIKE '%/'+b.areaid+'/%')
			AND ((b.RunAfterSave=1 AND @Event&1=1) OR (b.RunAtPost=1 AND @Event&2=2))
		if @@rowcount=0 return
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
		IF NOT exists(SELECT 1 FROM #Strategygroup) return
		--游标遍历所有匹配的政策，为了更高效使用游标，这里使用的是只读，仅向前游标。
		DECLARE curStrategyGroup CURSOR READ_ONLY FORWARD_ONLY FORWARD_ONLY FOR
		SELECT  Doccode,FormID,strategygroup,DataSource,FilterProc, RowFlag,ComputeProc,ComputeType,OutputProc,
			OutputType,OutputFields,MapFormID,OutputTable,dataSourceRowFlag FROM #Strategygroup
		OPEN curStrategyGroup
		--注意在此游标中,将单号和功能号存入了@Doccode1和@FormID1,而不使用@Doccode和@FormID,这是为了处理输入的数据源不止一个单号的问题.
		FETCH NEXT FROM curStrategyGroup INTO @Doccode1,@FormID1 ,@StrategyGroup,@DataSource,@StrategyMatch ,@RowFlag,@ComputeProc,
			@ComputeType,@StrategyOutput,@OutputType,@OutputFields,@MapFormID,@OutputTable,@DataSourceRowFlag
			
		WHILE @@FETCH_STATUS=0
			BEGIN
 
				--定义变量
				SELECT @sql='Declare @ObjectID int' +dbo.crlf()
				
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
				--匹配策略，再将结果插入临时表#Strategy
				SET @sql =@sql+'--装配策略数据临时表#Strategy'+char(10)
						 + '				SELECT  Replicate('''',500)  as StrategyID,Replicate('''',500)  as DocRowFlag,Replicate('''',500)  as StrategyCode,'
						 +'						Replicate('''',500)  as StrategyName,Replicate('''',500)  as StrategyRowID, ' + char(10)
						 + '					NULL AS StrategyPriority, Replicate('''',500)  as StrategyFilter, ' + char(10)
						 + '					Replicate('''',500)  as DocFilter,Replicate('''',500)  AS StratetyValueExpression, ' + char(10)
						 + '					CONVERT(SQL_VARIANT,'''')  AS StratetyValue  ' + char(10)
						 + '				INTO #Strategy  ' + char(10)
						 + '				FROM #Datasource a WHERE 1=2 ' + char(10)
						 + '	--执行策略匹配、策略计算与策略输出 ' + char(10)
						 + '				EXEC sp_ProcessStrategy '+Convert(varchar(10),ISNULL(@FormID1,0))+','''
											+ISNULL(@Doccode1,'')+''','''+Convert(varchar(10),ISNULL(@MapFormID,@FormID1))+''','''
											+ISNULL(@StrategyGroup,'')+''','''+ISNULL(@StrategyMatch,'sp_MatchStrategy')+''',''' 
											+ISNULL(@StrategyCompute,'sp_ComputeStrategy')+''','''+ISNULL(@StrategyOutput,'sp_OutputStrategy')+''',''' 
											+ISNULL(@ComputeType,'覆盖')+''','''+ISNULL(@OutputType,'至数据表')+''','''
											+ISNULL(@OutputTable,'')+''','''+ISNULL(@OutputFields,'')+''','''+ISNULL(@DataSourceRowFlag,'')+''','''
											+ISNULL(@RowFlag,'')+''','''+ISNULL(@Optionid,'')+''','''+ISNULL(@UserCode,'')+''','''
											+ISNULL(@TerminalID,'')+'''' +CHAR(10)
				SET @sql=@sql+'Drop Table #Strategy'+CHAR(10)
				+'Drop Table #DataSource;'
				EXEC( @sql)
				FETCH NEXT FROM curStrategyGroup INTO @Doccode1,@FormID1 ,@StrategyGroup,@DataSource,@StrategyMatch ,@RowFlag,@ComputeProc,
					@ComputeType,@StrategyOutput,@OutputType,@OutputFields,@MapFormID,@OutputTable,@dataSourceRowFlag
			END
		Drop Table #Strategygroup
		ExitLine:
		CLOSE curStrategyGroup
		DEALLOCATE curStrategyGroup
			
	END
 
go

/*
过程名称：sp_MatchStrategy
功能：策略处理接口
参数：见声名
返回：
编写：三断笛
时间：2012-02-18
备注：在此过程中，可以引用#DataSource数据源和#StrategyGroup策略数据。
	其中#Strategygroup策略数据已经包含数据源。将计算后的结果输出至#Strategy临时表
示例：
----------------------------------------------
*/
Alter PROC sp_MatchStrategy
	@FormID INT,											--功能号
	@Doccode VARCHAR(20),									--单号
	@FieldFormID varchar(10)='',							--字段映射功能号
	@StrategyGroup VARCHAR(20),								--策略组编码
	@RowFlag VARCHAR(500)='',								--行唯一标志
	@Optionid VARCHAR(100)='',								--选项
	@UserCode VARCHAR(50)='',								--执行人
	@TerminalID VARCHAR(50)='',								--终端编码
	@Result XML=''
AS
	BEGIN
		set nocount on;
		Declare  @sql VARCHAR(MAX),@tips varchar(max)
		--接下来匹配策略
		SET @sql = 'Insert Into #Strategy ' + char(10)
         + '		SELECT  NewID(),a.'+@rowFlag+',b.Doccode as StrategyCode,b.StrategyName,c.RowID,c.Priority,b.Filter as StrategyFilter,c.Filter as DocFilter,'+char(10)
         +'			c.Expression as StratetyValueExpression,Replicate('''',500) as StratetyValue ' + char(10)
         + '		From #Datasource a,Strategy_HD b,Strategy_DT c ' + char(10)
         + '		Where b.Strategygroup='''+@StrategyGroup +'''' + char(10)
         + '		and b.Doccode=c.Doccode ' + char(10)
         + '		And (ISNULL(b.beginday,'''')='''' OR b.beginday>=a.docdate) ' + char(10)
         + '		AND (ISNULL(b.endday,'''')='''' OR b.endday<=a.docdate) ' + char(10)
         + '		AND b.[enable]=1 ' + char(10)
         + '		AND (ISNULL(b.sdorgid,'''')='''' OR exists(select 1 from split(b.sdorgid,'','') x where a.sdorgPath LIKE ''%/''+x.list+''/%'')) ' + char(10)
         + '		AND (ISNULL(b.areaid,'''')='''' OR exists(select 1 from split(b.areaid,'','') x where a.areaPath LIKE ''%/''+x.list+''/%'')) ' + char(10)
         + '		and (Isnull(b.CompanyID,'''')='''' or exists(select 1 From split(b.companyid,'','') x where x.list=a.CompanyID)) ' + char(10)
         + '		and (isnull(c.Matcode,'''')='''' or a.matcode=c.matcode) ' + char(10)
         + '		and (isnull(c.matgroup,'''')='''' or exists(select 1 from split(c.matgroup,'','') x where a.matgroupPath like ''%/''+x.list+''/%'')) ' + char(10)
         + '		and (isnull(c.seriescode,'''')='''' or a.seriescode=c.seriescode) ' + char(10)
         + '		AND (ISNULL(c.sdorgid,'''')='''' OR a.sdorgPath LIKE ''%/''+c.sdorgid+''/%'') ' + char(10)
         + '		AND (ISNULL(c.areaid,'''')='''' OR exists(select 1 from split(c.areaid,'','') x where a.areaPath LIKE ''%/''+x.list+''/%'')) ' + char(10)
         + '		AND (ISNULL(c.ComboCode,'''')='''' OR a.combocode=c.ComboCode) ' + char(10)
         + '		AND (ISNULL(b.PackageID,'''')='''' OR EXISTS(SELECT 1 FROM SPLIT(ISNULL(b.PackageID,''''),'','') x WHERE x.list=a.packageid))' +CHAR(10)
 
           EXEC(@sql)
           
  		--select * from #Datasource
		update #Strategy
			set strategyfilter= commondb.dbo.REGEXP_Replace(strategyfilter,   '(?:^|\b)(?<!&|''|#)((\d:)?[\u4e00-\u9fa5]+)(?!&|''|#)(?:$|\b)','#$1#'),
			StratetyValueExpression=commondb.dbo.REGEXP_Replace(StratetyValueExpression, '(?:^|\b)(?<!&|''|#)((\d:)?[\u4e00-\u9fa5]+)(?!&|''|#)(?:$|\b)','&$1&'),
			DocFilter=commondb.dbo.REGEXP_Replace(DocFilter,  '(?:^|\b)(?<!&|''|#)((\d:)?[\u4e00-\u9fa5]+)(?!&|''|#)(?:$|\b)','#$1#')
			--select * into t_#Strategy from #Strategy 
           --select * into t_#DataSource from #DataSource
		
		--根据策略表头的扩展条件过滤策略数据
		begin try
			SET @sql = 'DELETE from #Strategy ' + char(10)
			 + 'WHERE convert(bit,dbo.ExecuteScalar(0,StrategyFilter, ''Select * From #DataSource'','''+@RowFlag+'=''''''+docrowFlag+'''''''',-1,''Select * from fn_getFormulaFields('''''+convert(varchar(50),COALESCE(@FieldFormID,@FormID,'''') )+''''')'',1))=0 ' + char(10)
			 + 'And isnull(StrategyFilter,'''')<>'''''+CHAR(10)
			exec(@sql)
		end try
		begin catch

			select @tips='执行策略过滤失败!'+dbo.crlf()+error_Message()+dbo.crlf()+@sql
			raiserror(@tips,16,1)
			return
		end catch
  		--select * from #Strategy
  		--select * from #Datasource
		--根据策略明细的扩展条件过滤单据数据
		begin try
			SET @sql =  'DELETE from #Strategy ' + char(10)
			 + 'WHERE dbo.ExecuteScalar(0,DocFilter, ''Select * From #DataSource'','''+@RowFlag+'=''''''+docrowFlag+'''''''',-1,''Select * from fn_getFormulaFields('''''+convert(varchar(50),COALESCE(@FieldFormID,@FormID,'''') )+''''')'',1)=0 ' + char(10)
			 + 'And Isnull(DocFilter,'''')<>'''''+CHAR(10)
		   exec(@sql)
		end try
		begin catch
			 --select * into T_#Strategy From #Strategy
			 --Select * into T_#DataSource from  #DataSource
			select @tips='执行策略明细条件过滤失败!'+dbo.crlf()+error_Message()+dbo.crlf()+@sql
 
			raiserror(@tips,16,1)
			return
		end catch

	  
	END
GO
alter proc sp_FilterStrategy
	@FormID varchar(50),			--功能号
	@Doccode VARCHAR(20),			--单号
	@FieldFormID varchar(50)='',	--字段映射功能号
	@StrategyGroup VARCHAR(20),		--策略组编码
	@RowFlag VARCHAR(500)='',		--行唯一标志
	@Optionid VARCHAR(100)='',		--选项
	@UserCode VARCHAR(50)='',		--执行人
	@TerminalID VARCHAR(50)='',		--终端编码
	@Result XML=''
as
	begin
		set nocount on;
		declare @sql varchar(max),@tips varchar(max)
			update #Strategy
			set strategyfilter= commondb.dbo.REGEXP_Replace(strategyfilter, '(?:^|\b)(?<!&|''|#)((\d:)?[\u4e00-\u9fa5]+)(?!&|''|#)(?:$|\b)','#$1#'),
			StratetyValueExpression=commondb.dbo.REGEXP_Replace(StratetyValueExpression,  '(?:^|\b)(?<!&|''|#)((\d:)?[\u4e00-\u9fa5]+)(?!&|''|#)(?:$|\b)','&$1&'),
			DocFilter=commondb.dbo.REGEXP_Replace(DocFilter,  '(?:^|\b)(?<!&|''|#)((\d:)?[\u4e00-\u9fa5]+)(?!&|''|#)(?:$|\b)','#$1#')
		--过滤单据数据,注意此处活动行的使用.
		begin try
			DELETE from #Strategy
			WHERE convert(bit,dbo.ExecuteScalar(0,DocFilter, 'Select * From #DataSource','RowID='''+DocRowFlag+'''',-1,
			'Select * from fn_getFormulaFields('''+convert(varchar(50),COALESCE(@FieldFormID,@FormID,''))+''')',0))=0
			And Isnull(DocFilter,'')<>''
			 EXEC(@sql)
		end try
		begin catch
			select @tips='策略组'+@StrategyGroup+'执行失败。'+dbo.crlf()+
			'错误发生于'+error_procedure()+'第'+convert(varchar(10),error_line())+'行'+dbo.crlf()+
			error_message()+dbo.crlf()+@sql
			raiserror(@tips,16,1)
			return
		end catch
		--过滤低优先级策略项
		  ;WITH cte AS( 
					SELECT  DocRowFlag,max(ISNULL(a.Strategypriority,0)) AS Strategypriority FROM  #Strategy a 
					GROUP BY DocRowFlag 
					) 

		 DELETE #Strategy FROM #Strategy a,cte b  
		 WHERE a.DocRowFlag=b.DocRowFlag  
		  AND ISNULL(a.Strategypriority,0)<b.Strategypriority
		--删除重复的策略
		;with cte as(SELECT StrategyRowID,Max(StrategyID) as StrategyID FROM #Strategy 
		GROUP BY StrategyRowID HAVING(COUNT(*)>=2))
		Delete #Strategy From #Strategy a,cte b where a.strategyRowID=b.StrategyRowID and a.StrategyID<b.StrategyID
		--检测是否单据还匹配到多个策略
		SELECT @sql='以下策略设置有重复项，请设置适当优先级别执行：'+dbo.crlf()
		;with cte as(SELECT DocRowFlag,StrategyCode,StrategyName FROM #Strategy GROUP BY DocRowFlag,StrategyCode,StrategyName HAVING(COUNT(*)>=2))
		SELECT @sql=@sql+StrategyCode+':'+StrategyName FROM CTE
		IF @@ROWCOUNT>0
			begin
				RAISERROR(@sql,16,1)
				return
			end

			return
	end
	go
/*
过程名称：sp_ProcessStrategy
功能：策略处理接口,对策略所有的处理都在此过程中。
参数：见声名
返回：
编写：三断笛
时间：2012-02-18
备注：
示例：
----------------------------------------------
*/
Alter PROC sp_ProcessStrategy
	@FormID varchar(50),									--功能号
	@Doccode VARCHAR(20),									--单号
	@MapFormID varchar(50)='',								--字段映射功能号
	@StrategyGroup VARCHAR(20),								--策略组编码
	@StrategyMatch VARCHAR(500)='sp_MatchStrategy',
	@ComputeProc VARCHAR(500)='sp_ComputeStrategy',
	@StrategyOutput VARCHAR(500)='sp_OutputStrategy',
	@ComputeType VARCHAR(50)='覆盖',
	@OutputType VARCHAR(50)='至数据表',
	@OutputTable VARCHAR(500)='',
	@OutputFields VARCHAR(500)='',
	@dataSourceRowFlag VARCHAR(500),						--输入数据源唯一行标志
	@RowFlag VARCHAR(500)='',								--输出表行唯一标志
	@Optionid VARCHAR(100)='',								--选项
	@UserCode VARCHAR(50)='',								--执行人
	@TerminalID VARCHAR(50)='',								--终端编码
	@Result XML=''
AS
	BEGIN
		SET NOCOUNT ON;
		DECLARE @sql VARCHAR(MAX),@tips varchar(max)
		begin try
			--装配匹配过程
			SELECT @sql=ISNULL(@StrategyMatch,'sp_MatchStrategy') +' '+CONVERT(VARCHAR(10),@FormID)+','''+@Doccode+''','''+
			Convert(varchar(50),COALESCE(@MapFormID,@FormID,'')) +''','''+
			@StrategyGroup+''','''+@dataSourceRowFlag +''','''+@Optionid+''','''+@UserCode+''','''+@TerminalID+''''
			--执行匹配，匹配过程可以引用#DataSource,#Strategy，#Strategygroup。匹配必须将结果输出至Strategy
			EXEC(@sql)
			--若未匹配到政策,则直接返回.
			IF NOT EXISTS(SELECT 1 FROM #Strategy) RETURN 1
			--执行策略过滤
			set @MapFormID=COALESCE(@MapFormID,@FormID,'')
			exec sp_FilterStrategy @Formid,@Doccode,@MapFormID  ,@Strategygroup,@DatasourceRowFlag,@OptionID,@UserCode,@TerminalID
			--若未匹配到政策,则直接返回.
			IF NOT EXISTS(SELECT 1 FROM #Strategy) RETURN 1
			--执行计算,不再用游标到策略的每一行进行计算了,效率低,直接使用一次批量计算即可.
			SELECT @sql=ISNULL(@ComputeProc,'sp_ComputeStrategy') +' '+CONVERT(VARCHAR(10),@FormID)+','''+@Doccode+''','''+
			Convert(varchar(50),COALESCE(@MapFormID,@FormID,'')) +''','''+
			@StrategyGroup+''','''+@OutputFields +''','''+''','''+ISNULL(@dataSourceRowFlag ,'')+''','''+@Optionid+''','''+@UserCode+''','''+@TerminalID+''''
			EXEC(@sql)
			--执行输出
			SELECT @sql=ISNULL(@StrategyOutput,'sp_OutputStrategy') +' '+CONVERT(VARCHAR(10),@FormID)+','''+@Doccode+''','''+
			Convert(varchar(50),COALESCE(@MapFormID,@FormID,''))  +''','''+@StrategyGroup+''',''' +@ComputeType+''','''+
			@OutputType+''','''+@OutputTable+''','''+@OutputFields+''','''+
			@RowFlag+''',NULL,'''+@Optionid+''','''+@UserCode+''','''+@TerminalID+''''
			EXEC(@sql)
		end try
 		begin catch
			select @tips='策略组'+@StrategyGroup+'执行失败。'+dbo.crlf()+
			'错误发生于'+error_procedure()+'第'+convert(varchar(10),error_line())+'行'+dbo.crlf()+
			error_message()+dbo.crlf()+@sql
			raiserror(@tips,16,1)
			return
		end catch
		RETURN -1
	END
go
/*
过程名称：sp_ComputeStrategy
功能：策略处理接口
参数：见声名
返回：
编写：三断笛
时间：2012-02-18
备注：
示例：
----------------------------------------------
*/
alter PROC sp_ComputeStrategy
	@FormID varchar(20),
	@Doccode VARCHAR(20),
	@FieldFormID varchar(50)='',	--字段映射功能号
	@StrategyGroup VARCHAR(20),
	@OutputFields VARCHAR(500)='',	--输出的字段
	@StrategyCode VARCHAR(20)='',
	@RowFlag VARCHAR(50)='',
	@Optionid VARCHAR(100)='',
	@UserCode VARCHAR(50)='',
	@TerminalID VARCHAR(50)='',
	@Result XML=''
AS
	BEGIN
		SET NOCOUNT ON;
		DECLARE @sql VARCHAR(4000),@Filter VARCHAR(max),@tips varchar(max)
		--拼装活动行,当单据明细中有多行,而需要逐行计算时,需要在动态表达式的Filter参数中确定活动行.
		--在本模块中,唯一行(@Rowflag)参数即为活动行.
		--但每次调用本模块的唯一行标志并不确定,故采用动态SQL方式执行.
		--若看不明白此动态SQL的写法,可以参考下面的固定SQL写法.
		--另外要注意在动态表达式中使用活动行与直接在数据源中过程的区别.具体请参阅动态表达式说明文档.
 		IF ISNULL(@RowFlag,'')=''
 			begin
 				set @Filter=''
 			end
 		ELSE
 			BEGIN
 				--注意理解此处的单引号数量
 				SET @Filter=''''+@RowFlag+'=''''''+a.DocRowFlag+'''''''''
 			end
 		
		SET @sql = '		Update a ' + char(10)
				 + '			set StratetyValue=dbo.ExecuteScalar(0,StratetyValueExpression, ''Select * From #DataSource b'''
				 + '		,'+@Filter+',-1,''Select * from fn_getFormulaFields('''''  
				 + 			convert(varchar(50),COALESCE(@FieldFormID,@FormID,''))+''''')'',0) ' + char(10)
				 + '		from #Strategy a ' + char(10)
				 + '		WHERE ISNULL(StratetyValueExpression,'''')<>'''''
		begin try
			EXEC(@sql)
		end try
		begin catch
			select @tips='执行策略计算失败!'+dbo.crlf()+error_Message()+dbo.crlf()+@sql
			raiserror(@tips,16,1)
			return
		end catch
		--以下是活动行固定为RowID时的SQL写法,供参考.
		/*
		Update a 
			set StratetyValue=dbo.ExecuteScalar(0,StratetyValueExpression, 'Select * From #Strategy','RowID='''+a.RowID+'''',-1,'Select * from fn_getFormulaFields(''9146,2801'')',0) 
		from #Strategy a 
		WHERE ISNULL(StratetyValueExpression,'')<>''*/
 
		Return
	END
go
/*
过程名称：sp_OutputStrategy
功能：策略处理接口
参数：见声名
返回：
编写：三断笛
时间：2012-02-18
备注：
示例：
----------------------------------------------
*/
Alter PROC sp_OutputStrategy
	@FormID varchar(50),
	@Doccode VARCHAR(20),
	@FieldFormID varchar(10)='',	--字段映射功能号
	@StrategyGroup VARCHAR(20),		--策略组
	@ComputeType VARCHAR(50)='',	--计算类型：累加，覆盖
	@OutputType VARCHAR(50)='',		--输出类型：提示，写数据表
	@OutputTable VARCHAR(50)='',	--输出表
	@OutputFields VARCHAR(500)='',	--输出的字段
	@RowFlag VARCHAR(100)='',		--输出数据的行标志，与输入数据源相匹配
	@StrategyCode VARCHAR(20)='',	--策略编码
	@Optionid VARCHAR(100)='',		--扩展选项
	@UserCode VARCHAR(50)='',		--执行人
	@TerminalID VARCHAR(50)='',		--执行终端
	@Result XML='' output			--返回值
AS
	BEGIN
		SET NOCOUNT ON;
		DECLARE @sql VARCHAR(8000),@tips varchar(max)
 
 
		IF @OutputType='抛出异常'
			BEGIN
				SELECT @sql='当前业务不符合公司政策：'+dbo.crlf()
				SELECT @sql=@sql+CONVERT(VARCHAR(5000),isnull(StratetyValue,''))+dbo.crlf()
				FROM #Strategy
				WHERE isnull(StratetyValue,'')<>''
				SELECT @sql=@sql+'请重新修改单据.'
				RAISERROR(@sql,16,1)
				return
			END
		ELSE IF @OutputType='至数据表'
			BEGIN
				
				select @sql='Update b Set '+@OutputFields+'='+	CASE 
																			when @ComputeType='累加' then 'ISNULL(b.'+@OutputFields +',0)+ISNULL(Convert(money,a.StratetyValue),0)'
																			ELSE 'Convert(money, StratetyValue)'
				                                                             	END+
				' From #Strategy a,'+@OutputTable+' b Where b.'+@RowFlag+'=a.DocRowFlag'
				begin try
					EXEC(@sql)
				end try
				begin catch
					 select @tips='执行策略结果输出失败!'+dbo.crlf()+error_Message()+dbo.crlf()+@sql
					raiserror(@tips,16,1)
					return
				end catch
 
				return
			END
		ELSE
		BEGIN
				RAISERROR('错误的输出方式！',16,1)
				return
			END
		return
	END
	
