SELECT uo.doccode,docdate,seriesnumber,comboname,packagename,uo.sdorgid,uo.sdorgname,commission,
COALESCE(uo.SeriesCode,uod.seriesCode) AS seriescode,COALESCE(uo.MatCode,uod.MatCode) AS matcode,COALESCE(uo.MatName,uod.MatName) AS matname,
uo.HDText,uod.usertxt2,uo.bitReturnd
FROM Unicom_Orders uo LEFT JOIN Unicom_OrderDetails uod ON uo.DocCode=uod.DocCode AND uod.doccode LIKE 'PS%'
LEFT JOIN oSDOrg os ON uo.sdorgid=os.SDOrgID
 
WHERE uo.DocDate BETWEEN '2012-08-01' AND '2012-08-13'
AND uo.DocStatus<>0
AND os.dptType='º”√ÀµÍ'
AND (
	uo.MatName LIKE '%806%'
	OR uo.MatName LIKE '%688%'
	OR uo.HDText LIKE '%806%'
	OR uo.HDText LIKE '%688%'
	OR uod.MatName LIKE '%806%'
	OR uod.MatName LIKE '%688%'
	OR uod.usertxt2 LIKE '%806%'
	OR uod.usertxt2 LIKE '%688%'
)
AND (uo.matcode LIKE '1.%' OR uod.MatCode LIKE  '1.%')
--AND uo.DocCode='RS20120713000028'
order by docdate DESC

SELECT * FROM Unicom_OrderDetails uod WHERE uod.DocCode='RS20120713000028'

BEGIN TRAN

UPDATE NumberAllocation_Log
	SET MatName = b.matname
FROM NumberAllocation_Log a,iMatGeneral b
WHERE a.matcode=b.MatCode
AND a.MatCode IS NOT NULL
AND isnull(a.MatName,'')=''
COMMIT