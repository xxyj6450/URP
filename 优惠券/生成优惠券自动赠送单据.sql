/*
* 过程名称:[sp_CreateAUTOCouponsDoc]
* 功能描述:创建优惠券自动赠送单据
* 参数:见声明
* 编写:三断笛
* 时间:2011-03-28
* 备注:无
* begin tran exec sp_createcouponsdoc 2419,'RE20110725000736',9201,0 rollback
* select * from coupons_d where doccode='QTH2011051000002'
*/
ALTER PROC [dbo].[sp_CreateAUTOCouponsDoc]
	@FormID	INT,
	@doccode VARCHAR(20),
	@optionID	INT=9201,
	@DocStatus INT=0,
	@LinkDocInfo VARCHAR(200)='' output
AS
	BEGIN
		SET NOCOUNT ON
		DECLARE @newDoccode VARCHAR(20)
		CREATE TABLE #DocData(
					Doccode VARCHAR(20),
					DocDate DATETIME,
					FormID INT,
					Doctype VARCHAR(50),
					RefFormID INT,
					Refcode VARCHAR(20),
					packageID VARCHAR(20),
					ComboCode VARCHAR(50),
					SdorgID VARCHAR(50),
					dptType VARCHAR(50),
					SdorgPath VARCHAR(500),
					AreaID VARCHAR(50),
					AreaPath VARCHAR(500),
					stcode VARCHAR(50),
					companyID VARCHAR(50),
					cltCode VARCHAR(50),
					CouponsBarcode VARCHAR(50),
					[STATE]  VARCHAR(20),
					CouponsCode VARCHAR(50),
					CouponsName VARCHAR(200),
					CouponsgroupCode VARCHAR(50),
					CodeMode VARCHAR(50),
					CodeLength INT,
					SourceMode VARCHAR(20),
					PresentMode VARCHAR(50),
					PresentCount VARCHAR(500),
					PresentMoney VARCHAR(500),
					ExchangeMode VARCHAR(50),
					ExchangeCount VARCHAR(500),
					ExchangeMoney VARCHAR(500),
					ForceCheckStock BIT,
					BeginDate DATETIME,
					EndDate DATETIME,
					Valid BIT,
					Price VARCHAR(500),
					Matcode VARCHAR(50),
					Matgroup VARCHAR(50),
					MatType VARCHAR(50),
					MatgroupPath VARCHAR(500),
					salePrice MONEY,
					totalMoney MONEY,
					digit INT,
					deductAmount MONEY,
					PackageType varchar(50))
		--套包销售单
		IF @FormID IN(9102,9146,9237)
			BEGIN
				INSERT INTO #DocData
						  (  Doccode,   DocDate,   FormID,   Doctype,   
						     RefFormID,   Refcode,   packageID,   ComboCode,   
						     SdorgID,   dptType,   SdorgPath,   
						     AreaID,   AreaPath,   stcode,   companyID,   
						     cltCode,   CouponsBarcode,   STATE,   CouponsCode,   
						     CouponsName,   CouponsgroupCode,   CodeMode,   
						     CodeLength,   SourceMode,   PresentMode,   
						     PresentCount,   PresentMoney,   ExchangeMode,   
						     ExchangeCount,   ExchangeMoney,   ForceCheckStock,   
						     BeginDate,   EndDate,   Valid,   Price,   Matcode,   
						     Matgroup,   MatType,   MatgroupPath,   salePrice,   
						     totalMoney,   digit,   deductAmount )
						select ch.Doccode,ch.docdate,ch.FormID,vso.DocType,vso.FormID,vso.DocCode,vso.PackageID,vso.ComboCode AS combocode,
						o2.SDOrgID,o2.dptType, o2.[PATH],g.areaid,g.[PATH],o.stCode,o.PlantID,ch.cltCode,
						cd.CouponsBarCode,i.[State],i.CouponsCode,cd.CouponsName,ig.GroupCode,ig.CodeMode,ig.CodeLength,
						ig.SourceMode,ig.PresentMode,ig.PresentCount,ig.PresentMoney,ig.ExchangeMode,ig.ExchangeCount,ig.ExchangeMoney,
						ig.ForceCheckStock,ig.BeginDate,ig.EndDate,ig.Valid,ig.price,
						cd.MatCode,ig2.MatGroup,ig2.mattype,ig3.[PATH],cd.Amount,cd.Amount,cd.DeductAmout,cd.DeductAmout
						FROM Coupons_H ch  with(nolock) INNER JOIN oStorage o  with(nolock) ON ch.Stcode=o.stCode
						INNER JOIN oSDOrg o2  with(nolock) ON o.sdorgid=o2.SDOrgID
						INNER JOIN gArea g  with(nolock) ON o2.AreaID=g.areaid
						INNER JOIN Coupons_D cd  with(nolock) ON ch.Doccode=cd.Doccode
						INNER JOIN iCouponsGeneral ig  with(nolock) ON cd.CouponsCode=ig.CouponsCode
						left JOIN iCoupons i  with(nolock) ON cd.CouponsBarCode=i.CouponsBarcode						--优惠券不一定存在,此处要用Left Join 
						--不一定有关联单据,所以要用Left Join
						LEFT JOIN Unicom_Orders  vso  with(nolock) ON ch.RefCode=vso.DocCode 
						--LEFT JOIN Unicom_OrderDetails  s  with(nolock) ON vso.DocCode=s.DocCode AND  cd.RefRowID=s.rowid
						LEFT JOIN iMatGeneral ig2  with(nolock) ON cd.MatCode=ig2.MatCode
						LEFT JOIN iMatGroup ig3  with(nolock) ON ig2.MatGroup=ig3.matgroup
						WHERE ch.Doccode=@doccode
			END
		
		set @LinkDocInfo=CONVERT(VARCHAR(10),@optionID)+';5;'+@newDoccode
		return
	END