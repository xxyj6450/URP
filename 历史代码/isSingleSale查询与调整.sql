SELECT a.old,b.MatName, d.MatGroup,c.matgroup,a.PackageName,appname,a.PackageID, * 
 /*BEGIN tran
 UPDATE b
 SET b.issinglesale=1  */
FROM 
unicom_orders a,unicom_orderdetails b,policy_d c,iMatGeneral d
WHERE a.DocCode=b.DocCode
AND a.PackageID=c.DocCode
AND ISNULL(b.isSingleSale,0)=0
AND c.isSingleSale=1
AND b.DocItem=c.MatItem
AND a.FormID =9146
AND b.MatCode=d.MatCode
AND d.MatGroup=c.matgroup
AND a.dptType<>'加盟店'
--ORDER BY a.DocDate DESC

ROLLBACK

COMMIT

SELECT * FROM _sysUser su WHERE su.username='吴卫国'

SELECT b.isSingleSale, b.seriesCode,a.sdorgname, a.PackageID,a.PackageName,b.MatCode,b.MatName, *
  FROM Unicom_Orders a,unicom_orderdetails b
WHERE a.DocCode=b.DocCode
AND a.PackageName LIKE '%裸机%'
AND b.seriesCode IS NOT NULL
AND LEFT (b.MatCode,2)='1.'
AND isnull(b.isSingleSale,0)=0
AND a.dptType<>'加盟店'

SELECT issinglesale FROM Unicom_OrderDetails uod WHERE uod.DocCode='PS20110524000019'

BEGIN tran
UPDATE A
	SET a.issinglesale=c.issinglesale
--SELECT *   
FROM sPickorderitem a,sPickorderHD b,Unicom_OrderDetails c
WHERE a.doccode=b.DocCode
AND b.refcode=c.DocCode
AND b.FormID=2419
AND a.seriescode=c.seriesCode
AND ISNULL(a.issinglesale,0)=0
AND c.isSingleSale=1

COMMIT
预存话费送手机5880,购机入网送话费4999


 SELECT * FROM policy_h WHERE DocType LIKE '%4999%'
 
 SELECT * FROM _sysLastName sln WHERE grade=0
 BEGIN tran
UPDATE A
	SET issinglesale=1
--SELECT b.refrefcode,* 
FROM sPickorderitem a,sPickorderHD b,spickorderitem c
WHERE a.doccode=b.DocCode
AND b.ClearDocCode=c.DocCode
AND a.seriescode=c.seriesCode
AND b.FormID=2420
AND isnull(a.issinglesale,0)=0
AND c.isSingleSale=1

COMMIT
BEGIN tran
UPDATE b	
	SET isSingleSale = a.issinglesale
	--SELECT b.*
FROM sPickorderitem a,SaleLog b
WHERE a.DocCode=b.DocCode
AND a.seriesCode=b.seriesCode
AND a.isSingleSale=1
AND ISNULL(b.isSingleSale,0)=0

COMMIT

SELECT issinglesale FROM Unicom_OrderDetails uod WHERE uod.seriesCode='012758004668868'
ROLLBACK
BEGIN TRAN

UPDATE Unicom_OrderDetails
	SET isSingleSale = 1
WHERE seriesCode IN('012550008310666','012550008050114','012368001701132')
AND LEFT(doccode,2) IN('PS')