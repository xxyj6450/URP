/*
* 函数名称：fn_getComboType 
* 功能描述：获取套餐类型。该函数从原套餐读取函数中取出套餐计划，供套餐信息连动。
* 参数：见声名
* 返回值：见声名
* 编写：三断笛
* 时间：2012-03-19
* 备注：
*/
ALTER FUNCTION [dbo].[fn_getComboType](
	@PackageID VARCHAR(20),				--套包编码
	@seriesnumber VARCHAR(20),			--受理号码
	@Sdorgid varchar(50)				--部门编码
)
RETURNS  @table TABLE(
	ComboPlan VARCHAR(50)				--返回套餐计划
	)
AS
	BEGIN
		INSERT INTO @table
		SELECT comboplan   From fn_getPackageCombo(@PackageID,@SeriesNumber,@sdorgid) a
		GROUP BY comboplan
		return
	END