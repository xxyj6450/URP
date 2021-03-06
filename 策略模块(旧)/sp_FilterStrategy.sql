/*
过程名称：sp_FilterStrategy
功能：策略结果过滤，将上一步策略匹配的结果再进行一次梳理，保证数据有的效性和简洁性
参数：见声名
返回：
编写：三断笛
时间：2012-03-03
备注：此过程不放在策略匹配过程中，而作为一个公用的模块，简化策略匹配接口的实现。
示例：
----------------------------------------------
*/
ALTER proc [sp_FilterStrategy]
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
		--关键字替换
		begin try
			update #Strategy
			set strategyfilter= commondb.dbo.REGEXP_Replace(strategyfilter, '(?:^|\b)(?<!&|''|#)((\d:)?[\u4e00-\u9fa5]+)(?!&|''|#)(?:$|\b)','#$1#'),
			StrategyValueExpression=commondb.dbo.REGEXP_Replace(StrategyValueExpression,  '(?:^|\b)(?<!&|''|#)((\d:)?[\u4e00-\u9fa5]+)(?!&|''|#)(?:$|\b)','&$1&'),
			DocFilter=commondb.dbo.REGEXP_Replace(DocFilter,  '(?:^|\b)(?<!&|''|#)((\d:)?[\u4e00-\u9fa5]+)(?!&|''|#)(?:$|\b)','#$1#')
			where isnull(strategyfilter,'')<>'' or isnull(StrategyValueExpression,'')<>'' or isnull(DocFilter,'')<>''
		end try
		begin catch
			select @tips='策略组'+@StrategyGroup+'执行失败。'+dbo.crlf()+
			'关键字替换失败。'+dbo.crlf()+
			'错误发生于'+error_procedure()+'第'+convert(varchar(10),error_line())+'行'+dbo.crlf()+
			error_message()+dbo.crlf() 
			raiserror(@tips,16,1)
			return
		end catch
		--SELECT * FROM #strategy
		--根据策略表头的扩展条件过滤策略数据
		begin try
			SET @sql = 'DELETE from #Strategy ' + char(10)
			 + 'WHERE convert(bit,dbo.ExecuteScalar(0,StrategyFilter, ''Select * From #DataSource'','''+@RowFlag+'=''''''+docrowFlag+'''''''',-1,''Select * from fn_getFormulaFields('''''+convert(varchar(50),COALESCE(@FieldFormID,@FormID,'''') )+''''')'',1))=0 ' + char(10)
			 + 'And isnull(StrategyFilter,'''')<>'''''+CHAR(10)
			 --SELECT * FROM #strategy
			exec(@sql)
			--print @sql
		end try
		begin catch

			select @tips='执行策略过滤失败!'+dbo.crlf()+error_Message()+dbo.crlf()+@sql
			raiserror(@tips,16,1)
			return
		end CATCH
		--SELECT * FROM #strategy
		--SELECT * FROM #strategy
  		--select * from #Datasource
		--根据策略明细的扩展条件过滤单据数据
		begin try
			SET @sql =  'DELETE from #Strategy ' + char(10)
			 + 'WHERE convert(bit,dbo.ExecuteScalar(0,DocFilter, ''Select * From #DataSource'','''+@RowFlag+'=''''''+docrowFlag+'''''''',-1,''Select * from fn_getFormulaFields('''''+convert(varchar(50),COALESCE(@FieldFormID,@FormID,'''') )+''''')'',1))=0 ' + char(10)
			 + 'And Isnull(DocFilter,'''')<>'''''+CHAR(10)
			 --PRINT @sql
		   exec(@sql)

		end try

		begin catch
			 --select * into T_#Strategy From #Strategy
			 --Select * into T_#DataSource from  #DataSource
			select @tips='执行策略明细条件过滤失败!'+dbo.crlf()+error_Message()+dbo.crlf()+@sql
 
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
		--2012-06-30 三断笛 将DocRowFlag也加入分组条件.因为只有当一条业务对应多条策略时才算重复.
		--而没有DocRowFlag条件时,可能出现单据本身有多条同样的业务内容,而导致在这里被删除掉,不能正确计算数据.
		;with cte as(SELECT DocRowFlag, StrategyRowID,Max(StrategyID) as StrategyID FROM #Strategy 
		GROUP BY DocRowFlag,StrategyRowID HAVING(COUNT(*)>=2))		
		Delete #Strategy From #Strategy a,cte b where a.strategyRowID=b.StrategyRowID and a.StrategyID<b.StrategyID

		--再次检测是否单据还匹配到多个策略
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

