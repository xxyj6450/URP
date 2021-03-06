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
ALTER PROC [dbo].[sp_OutputStrategy]
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
	@Result varchar(max)=NULL output			--返回值
AS
	BEGIN
		SET NOCOUNT ON;
		DECLARE @sql VARCHAR(8000),@tips varchar(max)
		IF @OutputType='抛出异常'
			BEGIN
				SELECT @sql='当前业务不符合公司政策：'+dbo.crlf()
				SELECT @sql=@sql+CONVERT(VARCHAR(5000),isnull(StrategyValue,''))+dbo.crlf()
				FROM #Strategy
				WHERE isnull(StrategyValue,'')<>''
				SELECT @sql=@sql+'请重新修改单据.'
				RAISERROR(@sql,16,1)
				return
			END
		ELSE IF @OutputType='至数据表'
			BEGIN
				select @sql='Update b Set '+@OutputFields+'='+	CASE 
																			when @ComputeType='累加' then 'ISNULL(b.'+@OutputFields +',0)+ISNULL(Convert(money,a.StrategyValue),0)'
																			ELSE 'Convert(money, StrategyValue)'
				                                                             	END+
				' From #Strategy a,'+@OutputTable+' b WITH(NOLOCK) Where b.'+@RowFlag+'=a.DocRowFlag'
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
	
