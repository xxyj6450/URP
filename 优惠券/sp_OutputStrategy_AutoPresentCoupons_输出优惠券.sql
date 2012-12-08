 
 
/*
过程名称：sp_OutputStrategy_AutoPresentCoupons
功能：策略处理接口
参数：见声名
返回：
编写：三断笛
时间：2012-02-18
备注：
示例：
----------------------------------------------
*/
create PROC [sp_OutputStrategy_AutoPresentCoupons]
	@FormID varchar(50),
	@Doccode VARCHAR(20),
	@FieldFormID varchar(10)='',					--字段映射功能号
	@StrategyGroup VARCHAR(20),				--策略组
	@ComputeType VARCHAR(50)='',			--计算类型：累加，覆盖
	@OutputType VARCHAR(50)='',				--输出类型：提示，写数据表
	@OutputTable VARCHAR(50)='',				--输出表
	@OutputFields VARCHAR(500)='',			--输出的字段
	@RowFlag VARCHAR(100)='',					--输出数据的行标志，与输入数据源相匹配
	@StrategyCode VARCHAR(20)='',			--策略编码
	@Optionid VARCHAR(100)='',					--扩展选项
	@UserCode VARCHAR(50)='',					--执行人
	@TerminalID VARCHAR(50)='',				--执行终端
	@Result XML='' output							--返回值
AS
	BEGIN
		SET NOCOUNT ON;
		DECLARE @sql VARCHAR(8000),@tips varchar(max)
		 DECLARE @Newdoccode VARCHAR(50)
		 EXEC sp_newdoccode 9201,''
		return
	END
	
