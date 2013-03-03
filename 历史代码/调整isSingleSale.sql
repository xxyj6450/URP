BEGIN TRAN
UPDATE a
--SELECT d.packageid,a.* 
--SET issinglesale=0,
--usertxt2=ISNULL(a.usertxt2,'')+'|数据调整'
FROM unicom_orders d,Unicom_OrderDetails a --OUTER APPLY fn_getmatgroup(a.matcode,1) b
WHERE a.isSingleSale=1
AND d.FormID=9146
AND d.DocCode=a.doccode
AND d.dptType<>'加盟店'
AND NOT EXISTS(SELECT 1 FROM policy_d c WHERE c.DocCode=d.PackageID AND ISNULL(c.isSingleSale,0)=1)
ORDER by a.doccode DESC

ROLLBACK
COMMIT

--更新零售销售单
BEGIN tran
UPDATE A
SET a.issinglesale=0,
usertxt2=ISNULL(a.usertxt2,'')+'|数据调整'
--SELECT a.*
FROM sPickorderitem a,sPickorderHD b,Unicom_OrderDetails d
WHERE a.DocCode=b.DocCode
AND b.refcode=d.DocCode
AND a.MatCode=d.MatCode
AND a.isSingleSale=1
AND isnull(d.isSingleSale,0) =0
ORDER BY a.DocCode DESC

--更新零售退货
UPDATE a
	SET issinglesale=0,
	usertxt2=ISNULL(a.usertxt2,'')+'|数据调整'
--SELECT b.refrefcode,a.*
FROM sPickorderitem a,sPickorderHD b,sPickorderitem c
WHERE a.doccode=b.DocCode
AND b.ClearDocCode=c.DocCode
AND b.FormID=2420
AND a.seriesCode=c.seriesCode
AND a.isSingleSale=1
AND ISNULL(c.isSingleSale,0)=0
ORDER BY a.DocCode DESC

ALTER TABLE spickorderitem ALTER COLUMN usertxt2 VARCHAR(200)
BEGIN tran
UPDATE SaleLog
	SET isSingleSale = 0
	--SELECT b.*
FROM sPickorderitem a,salelog b
WHERE a.DocCode=b.DocCode
AND a.seriesCode=b.seriesCode
AND b.isSingleSale=1
AND ISNULL(a.isSingleSale,0)=0
	ORDER BY b.DocCode DESC
	
	COMMIT
	
	SELECT * FROM oStorage os WHERE os.stCode LIKE '111.769'
	
	SELECT * FROM oSDOrg os WHERE os.SDOrgID='2.2'
	
	
	SELECT *  FROM iSeries is1 WHERE is1.SeriesCode='8986011067580457778'
	
DELETE FROM gDocPostQueue


SELECT * FROM Unicom_OrderDetails uod WHERE uod.seriesCode='8986011067580457778'