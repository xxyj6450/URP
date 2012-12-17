alter FUNCTION [dbo].[fn_getSaledMats](
	@refformid INT,
	@refcode VARCHAR(20),
	@mattype VARCHAR(20))
RETURNS @table TABLE(
	matcode varchar(50),
	matname VARCHAR(100),
	matgroup VARCHAR(50),
	seriescode VARCHAR(40),
	rowid VARCHAR(50),
	price MONEY,
	totalmoney MONEY,
	digit int)
AS
	BEGIN
		IF @refformid IN(0,2419,2420)
			BEGIN
				INSERT INTO @table
					SELECT sp.matcode,sp.matname,img.matgroup,seriescode,rowid,price,totalmoney,digit 
					FROM sPickorderitem sp with(nolock)
					 LEFT JOIN iMatGeneral img with(nolock) ON sp.MatCode=img.MatCode
					WHERE sp.DocCode=@refcode
					--AND EXISTS(SELECT 1 FROM _sysNumberAllocationCfgValues x WHERE x.PropertyName='配件券相关_可用商品大类'  and sp.MatGroup LIKE x.PropertyValue +'%'   )
			END
		IF @refformid IN(9102,9146)
			BEGIN
				;with cte(matcode,matname,seriescode,rowid,price,totalmoney,digit)
				as(
					select uo.MatCode,uo.MatName,uo.SeriesCode,'B8B9BDD8-5F7A-4E4F-9D47-D435DB4E08C1',uo.MatPrice,uo.MatMoney,1
					from Unicom_Orders uo with(nolock) 
					where uo.DocCode=@refcode
					union all
					SELECT sp.matcode,sp.matname,seriescode,rowid,price,totalmoney,digit 
					FROM Unicom_OrderDetails sp with(nolock)
						WHERE sp.DocCode=@refcode
				)
				INSERT INTO @table(matcode,matname,img.matgroup,seriescode,rowid,price,totalmoney,digit )
				SELECT sp.matcode,sp.matname,img.matgroup,seriescode,rowid,price,totalmoney,digit 
				FROM cte sp with(nolock)
				LEFT JOIN iMatGeneral img with(nolock) ON sp.MatCode=img.MatCode
					--AND EXISTS(SELECT 1 FROM _sysNumberAllocationCfgValues x WHERE x.PropertyName='配件券相关_可用商品大类'  and  sp.MatGroup LIKE x.PropertyValue +'%')
			END
 
		if @refformid in(6090)
			BEGIN
				INSERT INTO @table
				SELECT sp.matcode,sp.matname,img.matgroup,NULL,rowid,salesprice,totalmoney,ask_digit 
				FROM ord_shopbestgoodsdtl  sp with(nolock)
				LEFT JOIN iMatGeneral img with(nolock) ON sp.MatCode=img.MatCode
					WHERE sp.DocCode=@refcode
			END
		return
	END