 BEGIN TRAN
 UPDATE a
	SET	price2=data8,
	ScorePrice=ISNULL(data9,ScorePrice),
	a.usertxt2 = ISNULL(a.usertxt2,'')+'管理员调整积分。原积分价为'+convert(varchar(20),isnull(a.scoreprice,0))+',原积分为'+CONVERT(VARCHAR(20),ISNULL(price2,0))
 FROM sPickorderitem a,_sysImportData b
 WHERE a.doccode=b.Data1
 AND a.matcode=b.data3
 
 ;WITH cte AS(
 	SELECT a.DocCode,SUM(ISNULL(price2,0)) AS score1 FROM sPickorderitem a
 	WHERE a.DocCode IN(SELECT data1 FROM _sysImportData sid1)
 	GROUP BY a.DocCode
 	)
 UPDATE sPickorderHD
	SET Score1 = b.score1,
	sPickorderHD.TotalScore = ISNULL(a.Score,0)+ISNULL(b.Score1,0)
 FROM spickorderhd a,cte b
 WHERE a.DocCode=b.doccode
 
 UPDATE SaleLog
	SET SaleLog.ScorePrice = b.ScorePrice,
	SaleLog.totalprice=case a.formid when 2419 then b.price2 WHEN 2420 THEN b.price2 end,
	SaleLog.Score1 =CASE a.FormID  WHEN 2419 THEN  a.Score1 WHEN 2420 THEN a.Score1  end,
	SaleLog.TotalScore =CASE a.formid WHEN 2419 THEN  a.TotalScore  WHEN 2420 THEN a.TotalScore end
 FROM sPickorderHD a,sPickorderitem b,SaleLog c 
 WHERE a.DocCode=b.DocCode
 AND a.DocCode IN(SELECT data1 FROM _sysImportData sid1)
 AND b.DocCode=c.DocCode
 AND b.MatCode=c.MatCode
 AND ISNULL(b.seriesCode,'')=ISNULL(c.seriesCode,'')
 COMMIT
 ROLLBACK
 
SELECT data1,COUNT(*) FROM _sysImportData sid1
GROUP BY sid1.Data1
HAVING COUNT(*)>1
 
 
 