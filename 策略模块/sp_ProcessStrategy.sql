SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
 
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
ALTER PROC [dbo].[sp_ProcessStrategy]
	@FormID varchar(50),									--功能号
	@Doccode VARCHAR(20),									--单号
	@MapFormID varchar(50)='',								--字段映射功能号
	@StrategyGroup VARCHAR(20),								--策略组编码
	@StrategyGroupName VARCHAR(200)='',						--策略组名称
	@StrategyMatch VARCHAR(500)='sp_MatchStrategy',			--匹配接口
	@Matchtype VARCHAR(20)='1',								--匹配模式
	@ComputeProc VARCHAR(500)='sp_ComputeStrategy',			--进行计算的过程
	@StrategyOutput VARCHAR(500)='sp_OutputStrategy',		--进行输出的过程
	@ComputeType VARCHAR(50)='覆盖',						--计算方式
	@OutputType VARCHAR(50)='至数据表',						--输出方式
	@OutputTable VARCHAR(500)='',							--输出表
	@OutputFields VARCHAR(500)='',							--输出字段
	@ErrorText VARCHAR(2000)='',							--异常提示文本
	@dataSourceRowFlag VARCHAR(500),						--输入数据源唯一行标志
	@DatasourceOutputRowFlag varchar(500),					--输入表与输出表行标志对应的字段			
	@RowFlag VARCHAR(500)='',								--输出表行唯一标志
	@Optionid VARCHAR(100)='',								--选项
	@UserCode VARCHAR(50)='',								--执行人
	@TerminalID VARCHAR(50)='',								--终端编码
	@Result XML=''
AS
	BEGIN
		SET NOCOUNT ON;
		DECLARE @sql VARCHAR(MAX),@tips varchar(max)

		BEGIN TRY
			
			--装配匹配过程
			SELECT @sql=ISNULL(@StrategyMatch,'sp_MatchStrategy') +' '+CONVERT(VARCHAR(10),@FormID)+','''+@Doccode+''','''+
			Convert(varchar(50),COALESCE(@MapFormID,@FormID,'')) +''','''+
			@StrategyGroup+''','''+ISNULL(@Matchtype,'1')+''','''+@dataSourceRowFlag +''','''+@DatasourceOutputRowFlag+''','''+@Optionid+''','''+@UserCode+''','''+@TerminalID+''''
			--执行匹配，匹配过程可以引用#DataSource,#Strategy，#Strategygroup。匹配必须将结果输出至Strategy
			EXEC(@sql)
			--select* from #strategy
			--唯一匹配模式
			IF ISNULL(@Matchtype,'1') IN('1','')
				BEGIN
					--若未匹配到政策,则直接返回.
					IF NOT EXISTS(SELECT 1 FROM #Strategy) RETURN 1
				END
			--存在匹配模式
			IF ISNULL(@Matchtype,'1')='2'
				BEGIN
					--若未匹配到政策,则抛出异常.
					IF NOT EXISTS(SELECT 1 FROM #Strategy)
						begin
							SELECT @tips=@ErrorText
							IF LTRIM(RTRIM(ISNULL(@tips,'')))='' 
								begin
									SELECT @tips='未匹配到允许的业务数据，不允许进一步操作，请仔细检查！'
								END
							RAISERROR(@tips,16,1)
							RETURN
						end
				END
			--完全匹配模式
			IF ISNULL(@Matchtype,'1')='3' 
				BEGIN
					--若未匹配到政策,则抛出异常.
					IF NOT EXISTS(SELECT 1 FROM #Strategy)
						BEGIN
							SELECT @tips=@ErrorText
							IF LTRIM(RTRIM(ISNULL(@tips,'')))='' 
								begin
									SELECT @tips='业务数据不符合策略组['+@StrategyGroup+']'+ISNULL(@StrategyGroupName,'')+',不允许进一步操作，请仔细检查！'
								END
							RAISERROR(@tips,16,1)
						END
				END
			--赋值映射字段功能号
			set @MapFormID=COALESCE(@MapFormID,@FormID,'')
			--对策略进行进一步过滤
			exec sp_FilterStrategy @Formid,@Doccode,@MapFormID  ,@Strategygroup, @Matchtype , @DatasourceRowFlag,@OptionID,@UserCode,@TerminalID
			
			--过滤低优先级策略项
		  /*;WITH cte AS( 
					SELECT  DocRowFlag,max(ISNULL(a.Strategypriority,0)) AS Strategypriority FROM  #Strategy a 
					GROUP BY DocRowFlag 
					) 

		 DELETE #Strategy FROM #Strategy a,cte b  
		 WHERE a.DocRowFlag=b.DocRowFlag  
		  AND ISNULL(a.Strategypriority,0)<b.Strategypriority*/
		  ;WITH cte AS( 
					SELECT  DatasourceOutputRowFlag,StrategyCode,max(ISNULL(a.Strategypriority,0)) AS Strategypriority FROM  #Strategy a 
					GROUP BY DatasourceOutputRowFlag,StrategyCode
					) 

		 DELETE #Strategy FROM #Strategy a,cte b  
		 WHERE a.DatasourceOutputRowFlag=b.DatasourceOutputRowFlag
		 and a.StrategyCode=b.StrategyCode
		 AND ISNULL(a.Strategypriority,0)<b.Strategypriority
		--select * from #Strategy
		/*--删除重复的策略
		;with cte as(SELECT StrategyRowID,Max(StrategyID) as StrategyID FROM #Strategy 
		GROUP BY StrategyRowID HAVING(COUNT(*)>=2))
		Delete #Strategy From #Strategy a,cte b where a.strategyRowID=b.StrategyRowID and a.StrategyID<b.StrategyID*/
		--删除重复的策略
		--2012-06-30 三断笛 将DocRowFlag也加入分组条件.因为只有当一条业务对应多条策略时才算重复.
		--而没有DocRowFlag条件时,可能出现单据本身有多条同样的业务内容,而导致在这里被删除掉,不能正确计算数据.
		/*;with cte as(SELECT DocRowFlag, StrategyRowID,Max(StrategyID) as StrategyID FROM #Strategy 
		GROUP BY DocRowFlag,StrategyRowID HAVING(COUNT(*)>=2))		
		Delete #Strategy From #Strategy a,cte b where a.strategyRowID=b.StrategyRowID and a.StrategyID<b.StrategyID*/
		;with cte as(SELECT DatasourceOutputRowFlag, StrategyRowID,Max(StrategyID) as StrategyID FROM #Strategy 
		GROUP BY DatasourceOutputRowFlag,StrategyRowID HAVING(COUNT(*)>=2))		
		Delete #Strategy From #Strategy a,cte b where a.strategyRowID=b.StrategyRowID and a.StrategyID<b.StrategyID
		--select * from #Strategy
		--任意匹配模式
		IF ISNULL(@Matchtype,'1') IN('1','')
			BEGIN
				--若未匹配到政策,则直接返回.
				IF NOT EXISTS(SELECT 1 FROM #Strategy) RETURN 1
				--再次检测是否单据还匹配到多个策略
				SELECT @sql='以下策略设置有重复项，请设置适当优先级别执行：'+dbo.crlf()
				--;with cte as(SELECT DocRowFlag,StrategyCode,StrategyName FROM #Strategy GROUP BY DocRowFlag,StrategyCode,StrategyName HAVING(COUNT(*)>=2))
				;with cte as(SELECT DatasourceOutputRowFlag,StrategyCode,StrategyName FROM #Strategy GROUP BY DatasourceOutputRowFlag,StrategyCode,StrategyName HAVING(COUNT(*)>=2))
				SELECT @sql=@sql+StrategyCode+':'+StrategyName FROM CTE
				IF @@ROWCOUNT>0
					begin
						RAISERROR(@sql,16,1)
						return
					end
			end
			
			--存在匹配模式
			IF ISNULL(@Matchtype,'1')='2'
				BEGIN
					--若未匹配到政策,则抛出异常.
					IF NOT EXISTS(SELECT 1 FROM #Strategy)
						begin
							SELECT @tips=@ErrorText
							IF LTRIM(RTRIM(ISNULL(@tips,'')))='' 
								begin
									SELECT @tips='策略组['+@StrategyGroup+']'+ISNULL(@StrategyGroupName,'')+'未匹配到允许的业务数据，不允许进一步操作，请仔细检查！'
								END
							RAISERROR(@tips,16,1)
							RETURN
						end
				END
			--完全匹配模式
			IF ISNULL(@Matchtype,'1')='3' 
				BEGIN
					--若未匹配到政策,则抛出异常.
					IF NOT EXISTS(SELECT 1 FROM #Strategy)
						BEGIN
							SELECT @tips=@ErrorText
							IF LTRIM(RTRIM(ISNULL(@tips,'')))='' 
								begin
									SELECT @tips='业务数据不符合策略组['+@StrategyGroup+']'+ISNULL(@StrategyGroupName,'')+',不允许进一步操作，请仔细检查！'
								END
							RAISERROR(@tips,16,1)
						END
					--若有数据，则需要判断是否完全满足条件
					IF OBJECT_ID('tempdb..#Strategy_ALL') IS NULL
						BEGIN
							SELECT @tips='策略组['+@StrategyGroup+']'+ISNULL(@StrategyGroupName,'')+'使用了完全匹配模式，但未设置完全匹配列表，无法判断业务是否完全满足策略，请联系联系管理员。'
							RAISERROR(@tips,16,1)
							return
						END
				END

			--执行计算,不再用游标到策略的每一行进行计算了,效率低,直接使用一次批量计算即可.
			SELECT @sql=ISNULL(@ComputeProc,'sp_ComputeStrategy') +' '+CONVERT(VARCHAR(10),@FormID)+','''+@Doccode+''','''+
			Convert(varchar(50),COALESCE(@MapFormID,@FormID,'')) +''','''+
			@StrategyGroup+''','''+@OutputFields +''','''+''','''+ISNULL(@dataSourceRowFlag ,'')+''','''+@Optionid+''','''+@UserCode+''','''+@TerminalID+''''
			EXEC(@sql)
			--select * from #Strategy
			--执行输出
			SELECT @sql=ISNULL(@StrategyOutput,'sp_OutputStrategy') +' '+CONVERT(VARCHAR(10),@FormID)+','''+@Doccode+''','''+
			Convert(varchar(50),COALESCE(@MapFormID,@FormID,''))  +''','''+@StrategyGroup+''',''' +@ComputeType+''','''+
			@OutputType+''','''+@OutputTable+''','''+@OutputFields+''','''+
			@RowFlag+''',NULL,'''+@Optionid+''','''+@UserCode+''','''+@TerminalID+''''
			EXEC(@sql)
		end try
 		begin catch
			select @tips='策略组['+@StrategyGroup+']'+@strategygroupname+'执行失败。'+dbo.crlf()+
			'错误发生于'+isnull(ERROR_PROCEDURE(),'')+'第'+convert(varchar(10),isnull(error_line(),0))+'行'+dbo.crlf()+
			isnull(error_message(),'')+dbo.crlf()+isnull(@sql,'')
			raiserror(@tips,16,1)
			return
		end catch
		RETURN -1
	END
