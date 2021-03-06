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
	@StrategyMatch VARCHAR(500)='sp_MatchStrategy',
	@ComputeProc VARCHAR(500)='sp_ComputeStrategy',
	@StrategyOutput VARCHAR(500)='sp_OutputStrategy',
	@ComputeType VARCHAR(50)='覆盖',
	@OutputType VARCHAR(50)='至数据表',
	@OutputTable VARCHAR(500)='',
	@OutputFields VARCHAR(500)='',
	@dataSourceRowFlag VARCHAR(500),						--输入数据源唯一行标志
	@RowFlag VARCHAR(500)='',								--输出表行唯一标志
	@bitRecordLog bit=0,
	@Optionid VARCHAR(100)='',								--选项
	@UserCode VARCHAR(50)='',								--执行人
	@TerminalID VARCHAR(50)='',								--终端编码
	@Result varchar(max)='' output
AS
	BEGIN
		SET NOCOUNT ON;
		DECLARE @sql nVARCHAR(MAX),@tips varchar(max),@retXML varchar(max),
		@ret int			--过程返回值。若有执行策略则返回1,若策略全部被过滤掉，则返回0
		
		begin try
			select @Result=''
			if @bitRecordLog=1  Select @Result='<StrategyDataSource>'+convert(varchar(max),(select * From #DataSource for XML RAW))+'</StrategyDataSource>'
			/*********************************************************执行策略匹配*************************************************************************/
			--装配匹配过程
			SELECT @sql=ISNULL(@StrategyMatch,'sp_MatchStrategy') +' '+CONVERT(VARCHAR(10),@FormID)+','''+@Doccode+''','''+
			Convert(varchar(50),COALESCE(@MapFormID,@FormID,'')) +''','''+
			@StrategyGroup+''','''+@dataSourceRowFlag +''','''+@Optionid+''','''+@UserCode+''','''+@TerminalID+''''
			--执行匹配，匹配过程可以引用#DataSource,#Strategy，#Strategygroup。匹配必须将结果输出至Strategy
			EXEC(@sql)
			if @bitRecordLog=1  select @Result=@Result+'<MatchStrategy>'+ISNULL(convert(varchar(max),(select * From #Strategy for XML RAW)),'')+'</MatchStrategy>'
			--若未匹配到政策,则直接返回.
			IF NOT EXISTS(SELECT 1 FROM #Strategy)
				BEGIN
					set @ret=0
					goto ExitLine
				END
			/***************************************************************执行策略过滤*************************************************************/
			--执行策略过滤
			set @MapFormID=COALESCE(@MapFormID,@FormID,'')
			exec sp_FilterStrategy @Formid,@Doccode,@MapFormID  ,@Strategygroup,@DatasourceRowFlag,@OptionID,@UserCode,@TerminalID
			if @bitRecordLog=1  select @Result=@Result+'<FilterStrategy>'+ISNULL(convert(varchar(max),(select * From #Strategy for XML RAW)),'')+'</FilterStrategy>'
			--若未匹配到政策,则直接返回.
			
			IF NOT EXISTS(SELECT 1 FROM #Strategy)
				BEGIN
					set @ret=0
					--若策略被完全过滤，则转到日志记录。需要记录为什么策略被完全过滤掉。
					goto ExitLine
				END
			--若能通过策略过滤，则返回值为1
			set @ret=1
			
			/***************************************************************执行策略计算*****************************************************************/
			--执行计算,不再用游标到策略的每一行进行计算了,效率低,直接使用一次批量计算即可.
			SELECT @sql='EXEC '+ISNULL(@ComputeProc,'sp_ComputeStrategy') +' '+CONVERT(VARCHAR(10),@FormID)+','''+@Doccode+''','''+
			Convert(varchar(50),COALESCE(@MapFormID,@FormID,'')) +''','''+
			@StrategyGroup+''','''+@OutputFields +''','''+''','''+ISNULL(@dataSourceRowFlag ,'')+''','''+@Optionid+''','''+@UserCode+''','''+@TerminalID+''''
			EXEC sp_executesql @sql,N'@ResultXML varchar(max) output',@ResultXML=@retXML output
			--若未返回结果ＸＭＬ，则自动取当前计算的#Strategy
			if isnull(@retXML,'')=''	 Select @retXML=ISNULL( convert(varchar(max),(select * From #Strategy for XML RAW)),'')
			--添加结果集
			select @Result=@Result+'<ComputeStrategy>'+ISNULL(@retXML,'')+'</ComputeStrategy>'
			
			/***********************************************************执行策略输出*********************************************************************/
			--执行输出
			SELECT @sql='EXEC '+ISNULL(@StrategyOutput,'sp_OutputStrategy') +' '+CONVERT(VARCHAR(10),@FormID)+','''+@Doccode+''','''+
			Convert(varchar(50),COALESCE(@MapFormID,@FormID,''))  +''','''+@StrategyGroup+''',''' +@ComputeType+''','''+
			@OutputType+''','''+@OutputTable+''','''+@OutputFields+''','''+
			@RowFlag+''',NULL,'''+@Optionid+''','''+@UserCode+''','''+@TerminalID+''',@ResultXML output'
			EXEC sp_executesql @sql,N'@ResultXML varchar(max) output',@ResultXML=@retXML output
			--输出结果
			select @Result=@Result+'<OutputStrategy>'+ISNULL(@retXML,'')+'</OutputStrategy>'
			--print @Result
		end try
 		begin catch
			select @tips=dbo.getLastError('策略组'+@StrategyGroup+'执行失败。' +dbo.crlf()+@sql)
			raiserror(@tips,16,1)
			return 0
		end CATCH
	/******************************************************************记录日志***********************************************/
--退出策略处理，处理后事
ExitLine:
		--记录日志
		if @bitRecordLog=1
			BEGIN
				insert into StrategyLog(Doccode,FormID,StrategyID,DocRowFlag,StrageyGroup,StrategyCode,StrategyName,StrategyRowID,StrategyPriority,DocFilter,
				StrategyValueExpression,StrategyValue,EnterDate,EnterName,OptionID,TerminalID,ResultXML)
				select @Doccode,@FormID,a.StrategyID,a.DocRowFlag,@StrategyGroup,a.StrategyCode,a.StrategyName,a.StrategyRowID,a.StrategyPriority,a.DocFilter,
				a.StrategyValueExpression,a.StrategyValue,getdate(),@UserCode,@Optionid,@TerminalID,@Result
				from  #Strategy a
				--当没有任何策略数据时也要记录
				if @@ROWCOUNT=0
					BEGIN
						insert into StrategyLog(Doccode,FormID,StrategyID,DocRowFlag,StrageyGroup,StrategyCode,StrategyName,StrategyRowID,StrategyPriority,DocFilter,
						StrategyValueExpression,StrategyValue,EnterDate,EnterName,OptionID,TerminalID,ResultXML)
						select @Doccode,@FormID,NULL as StrategyID,NULL as DocRowFlag,@StrategyGroup,NULL StrategyCode,NULL StrategyName,NULL StrategyRowID,NULL StrategyPriority,NULL DocFilter,
						NULL StrategyValueExpression,NULL StrategyValue,getdate(),@UserCode,@Optionid,@TerminalID,@Result
					END
			END
		RETURN @ret
	END