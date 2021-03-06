 
 
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
ALTER proc [dbo].[sp_FilterStrategy]
	@FormID varchar(50),			--功能号
	@Doccode VARCHAR(20),			--单号
	@FieldFormID varchar(50)='',	--字段映射功能号
	@StrategyGroup VARCHAR(20),		--策略组编码
	@MatchType VARCHAR(20)='',		--匹配模式
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
			StratetyValueExpression=commondb.dbo.REGEXP_Replace(StratetyValueExpression,  '(?:^|\b)(?<!&|''|#)((\d:)?[\u4e00-\u9fa5]+)(?!&|''|#)(?:$|\b)','&$1&'),
			DocFilter=commondb.dbo.REGEXP_Replace(DocFilter,  '(?:^|\b)(?<!&|''|#)((\d:)?[\u4e00-\u9fa5]+)(?!&|''|#)(?:$|\b)','#$1#')
			where isnull(strategyfilter,'')<>'' or isnull(StratetyValueExpression,'')<>'' or isnull(DocFilter,'')<>''
		end try
		begin catch
			select @tips='策略组'+@StrategyGroup+'执行失败。'+dbo.crlf()+
			'关键字替换失败。'+dbo.crlf()+
			'错误发生于'+isnull(error_procedure(),'')+'第'+convert(varchar(10),isnull(error_line(),0))+'行'+dbo.crlf()+
			isnull(error_message(),'')+dbo.crlf() 
			raiserror(@tips,16,1)
			return
		end catch
		--根据策略表头的扩展条件过滤策略数据
		begin try
			SET @sql = 'DELETE from #Strategy ' + char(10)
			 + 'WHERE convert(bit,dbo.ExecuteScalar(0,StrategyFilter, ''Select * From #DataSource'','''+@RowFlag+'=''''''+docrowFlag+'''''''',-1,''Select * from fn_getFormulaFields('''''+convert(varchar(50),COALESCE(@FieldFormID,@FormID,'''') )+''''')'',1))=0 ' + char(10)
			 + 'And isnull(StrategyFilter,'''')<>'''''+CHAR(10)
			exec(@sql)
		end try
		begin catch

			select @tips='执行策略过滤失败!'+dbo.crlf()+isnull(error_Message(),'')+dbo.crlf()+ISNULL(@sql,'')
			raiserror(@tips,16,1)
			return
		end catch
		--select *   from #Strategy
		/*if object_id('Strategy_test') is null
			begin
  				select * into Strategy_test from #Strategy
  				select * into Datasource_test from #Datasource
  			end*/
		--根据策略明细的扩展条件过滤单据数据
		begin try
			SET @sql =  'DELETE from #Strategy ' + char(10)
			 + 'WHERE convert(bit,dbo.ExecuteScalar(0,DocFilter, ''Select * From #DataSource'','''+@RowFlag+'=''''''+docrowFlag+'''''''',-1,''Select * from fn_getFormulaFields('''''+convert(varchar(50),COALESCE(@FieldFormID,@FormID,'''') )+''''')'',1))=0 ' + char(10)
			 + 'And Isnull(DocFilter,'''')<>'''''+CHAR(10)
		   exec(@sql)
		   print @sql
		end try
		
		begin catch
			 --select * into T_#Strategy From #Strategy
			 --Select * into T_#DataSource from  #DataSource
			select @tips='执行策略明细条件过滤失败!'+dbo.crlf()+isnull(error_Message(),'')+dbo.crlf()+ISNULL(@sql,'')
 
			raiserror(@tips,16,1)
			return
		end catch
		return
		
	end
