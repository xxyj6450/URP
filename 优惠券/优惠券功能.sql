set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go
 
ALTER proc [dbo].[sp_ExcuteAfterSave_Coupons]
	@usercode VARCHAR(20),
	@username VARCHAR(20),
	@Formid INT,
	@doccode VARCHAR(20),
	@optionID INT=0
AS
	BEGIN
		/*
		优惠券使用有如下基本规则:
		1.兑换模式为"一对一"的,只允许每个商品一个优惠券,即@tableMat的CountNum必须为1,@tableCoupons的CountNum也为1
		2.兑换模式为"一对多"时,一个商品允许多个优惠券,即@tableMat的CountNum可以不为1,但@tableCoupons的CountNum必须为1
		3.兑换模式为"多对一"时,一张券允许兑换多个商品,即@tableMat的CountNum必须为1,但@tableCoupons的CountNum可不为1
		4.兑换模式为"多对多"时,多张券可兑换多个商品,@tableMat,@tableCoupons的CountNum均可不为1
		5.同一张券抵扣金额之和不得大于面额之和
		6.抵扣金额之和不得大于商品实收金额
		*/
		DECLARE @totalmoney MONEY
		--商品数据
		DECLARE @tableMat table(
			seriesCode VARCHAR(50),
			matcode VARCHAR(50),
			price MONEY,
			totalmoney MONEY,
			digit INT,
			CountNum int)
		--优惠券数据
		DECLARE @tableCoupons table(
			couponsBarcode VARCHAR(50),
			couponsCode VARCHAR(20),
			DeductMoney MONEY,
			CountNum int)
		--取得唯一商品列表,因为同一个商品每一行的数量,金额,单价都一样,所以直接用max可以取出该商品的相关信息.
		INSERT INTO @tablemat(seriescode,matcode,price,totalmoney,digit,CountNum)
		SELECT seriescode,matcode,MAX(matprice),MAX(amount),MAX(digit),COUNT(doccode)
		FROM Coupons_D cd WHERE cd.Doccode=@doccode
		GROUP BY cd.SeriesCode,cd.Matcode
		--取得唯一优惠券列表
		IF @Formid =9201
			BEGIN
				SELECT @totalmoney = sUM(cd.DeductAmout)
					FROM   Coupons_D cd
					WHERE  cd.Doccode = @doccode
					AND cd.UseImmediate=1
					GROUP BY  cd.Doccode
				UPDATE coupons_h 
					SET TotalDeductAmout = @totalmoney
				WHERE Doccode=@doccode
				return
			END
		IF @Formid=9207
			BEGIN
				SELECT @totalmoney = sUM(cd.DeductAmout)
					FROM   Coupons_D cd
					WHERE  cd.Doccode = @doccode
					GROUP BY  cd.Doccode
				UPDATE coupons_h 
					SET TotalDeductAmout = @totalmoney
				WHERE Doccode=@doccode
				return
			END
		return
	END
	

