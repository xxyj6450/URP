 
/*
函数名称:[fn_getComboEX]
功能:获取套餐信息
参数:见声名
编写:三断笛
时间:
备注:该函数主要是根据套餐计划来获取套包信息,如果不需要套餐信息,可直接使用fn_getPackageCombo函数.此函数也只是从fn_getPackageCombo读取数据


*/
ALTER FUNCTION [dbo].[fn_getComboEX](
	@Combocde INT,						--套餐编码
	@PackageID VARCHAR(20),				--套包编码
	@SeriesNumber VARCHAR(20),			--受理号码
	@ComboPlan VARCHAR(50),				--套餐计划
	@Sdorgid varchar(50)
)
RETURNS  @table TABLE(
	 combocode varchar(20),					--套餐编码
	 comboname varchar(100),				--套餐名
	 combotype varchar(50),					--套餐类别
	 price money,							--套餐价格
	 areaid varchar(200),					--区域
	 comboplan varchar(50),					--套餐计划
	 DepositsMatcode varchar(50),			--存费送费商品编码
	 DepositsMatName Varchar(200),			--存费送费商品名称
	 Deposits Money							--存费送费金额
)			
AS
	BEGIN
		INSERT INTO @table(combocode,comboname,combotype,comboplan,price,areaid)
		SELECT combocode,comboname,combotype,comboplan,price,areaid
		  From fn_getPackageCombo(@PackageID,@SeriesNumber,@sdorgid) a
		WHERE (@Combocde='' OR a.combocode=@Combocde)
		AND (@comboplan='' OR a.comboplan=@ComboPlan)
		order by a.price
		return
	END