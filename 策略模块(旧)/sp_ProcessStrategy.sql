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
ALTER PROC [sp_ProcessStrategy]
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
			--SELECT * FROM #strategy
			--若未匹配到政策,则直接返回.
			IF NOT EXISTS(SELECT 1 FROM #Strategy) RETURN 1
			
			--执行策略过滤
			set @MapFormID=COALESCE(@MapFormID,@FormID,'')
			exec sp_FilterStrategy @Formid,@Doccode,@MapFormID  ,@Strategygroup,@DatasourceRowFlag,@OptionID,@UserCode,@TerminalID
	--SELECT * FROM #strategy

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
		end CATCH
		RETURN -1
	END