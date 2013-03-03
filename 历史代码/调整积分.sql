--1.将除套包单外的其余单据中不需要计算积分的商品，积分清零
BEGIN tran
UPDATE a
	SET a.price2 = 0,
	usertxt2='重新调整积分,置为零,原积分为' +convert(varchar(50),isnull(Price2,0))
--SELECT a.doccode,sh.refcode ,a.MatCode,a.MatName,a.ScorePrice,a.price2
FROM sPickorderitem a WITH(NOLOCK),sPickorderHD sh  WITH(NOLOCK),iMatGeneral ig
WHERE a.doccode=sh.DocCode
AND a.matcode=ig.MatCode
AND ISNULL(ig.deduct,0)=0
AND sh.FormID IN(2419,2420)
AND ISNULL(sh.refformid,0)!=9146
AND ISNULL(sh.refrefformid,0)!=9146
AND ISNULL(a.price2,0)!=0
AND sh.DocDate>='2012-04-01'
ORDER BY sh.DocDate DESC
COMMIT

/*
SELECT sum(isnull(price2,0))
FROM sPickorderitem a WITH(NOLOCK),sPickorderHD sh  WITH(NOLOCK),iMatGeneral ig
WHERE a.doccode=sh.DocCode
AND a.matcode=ig.MatCode
AND ISNULL(ig.deduct,0)=0
AND sh.FormID IN(2419,2420)
AND ISNULL(sh.refformid,0)!=9146
AND ISNULL(sh.refrefformid,0)!=9146
AND ISNULL(a.price2,0)!=0
AND sh.DocDate>='2012-04-01'
ORDER BY sh.DocDate

SELECT a.matname
FROM sPickorderitem a WITH(NOLOCK),sPickorderHD sh  WITH(NOLOCK),iMatGeneral ig
WHERE a.doccode=sh.DocCode
AND a.matcode=ig.MatCode
AND ISNULL(ig.deduct,0)=0
AND sh.FormID IN(2419,2420)
AND ISNULL(sh.refformid,0)!=9146
AND ISNULL(sh.refrefformid,0)!=9146
AND ISNULL(a.price2,0)!=0
AND sh.DocDate>='2012-04-01'
group by a.matname
*/
--2.将所有单据中的虚拟商品，重新计算积分。
BEGIN tran
UPDATE a
	SET a.price2 = ISNULL(a.totalmoney,0)*(1-isnull(d.ScorePrice,0)),
	a.ScorePrice = d.ScorePrice,
	usertxt2='重新调整积分,原积分为'+convert(varchar(50),isnull(Price2,0))
--SELECT a.doccode,sh.refcode,a.MatCode,a.MatName,a.totalmoney,a.ScorePrice,a.price2,d.scoreprice, isnull(a.totalmoney,0)*(1-isnull(d.scoreprice,0))
FROM sPickorderitem a WITH(NOLOCK)
inner join sPickorderHD sh  WITH(NOLOCK) ON a.doccode=sh.DocCode
inner join iMatGeneral ig ON a.matcode=ig.MatCode
outer apply dbo.uf_salesSDOrgpricecalcu3(a.matcode, sh.sdorgid, '') d 
WHERE  ISNULL(ig.deduct,0)=1
AND sh.FormID IN(2419,2420)
AND sh.DocDate>='2012-04-01'
AND ISNULL(ig.MatState,0)=0
ORDER BY sh.DocDate desc
 COMMIT
/*
SELECT sum(isnull(a.price2,0)-isnull(a.totalmoney,0)*(1-isnull(d.scoreprice,0)))
FROM sPickorderitem a WITH(NOLOCK)
inner join sPickorderHD sh  WITH(NOLOCK) ON a.doccode=sh.DocCode
inner join iMatGeneral ig ON a.matcode=ig.MatCode
outer apply dbo.uf_salesSDOrgpricecalcu3(a.matcode, sh.sdorgid, '') d 
WHERE  ISNULL(ig.deduct,0)=1
AND sh.FormID IN(2419,2420)
AND sh.DocDate>='2012-04-01'
AND ISNULL(ig.MatState,0)=0

*/
--3.重新计算合计
BEGIN tran
;WITH cte AS(
	SELECT a.doccode,SUM(ISNULL(price2,0)) AS Score1
	FROM spickorderhd a WITH(NOLOCK),sPickorderitem s  WITH(NOLOCK)
	WHERE a.DocCode=s.DocCode
	AND a.FormID IN(2419,2420)
	AND a.DocDate >='2012-04-01'
	GROUP BY a.DocCode)
UPDATE a
	SET a.Score1 = b.score1,
	a.TotalScore = ISNULL(a.Score,0)+ISNULL(b.score1,0)
FROM sPickorderHD a  WITH(NOLOCK),cte b 
WHERE a.DocCode=b.doccode

commit
--4.更新salelog表
BEGIN tran
UPDATE a
	SET a.totalprice = c.price2,
	a.Score1=b.Score ,
	a.TotalScore = b.TotalScore
	--SELECT a.DocCode,a.totalprice,c.price2,c.matname,c.totalmoney
FROM SaleLog a,sPickorderHD b,sPickorderitem c
WHERE a.DocCode=b.DocCode
AND b.DocCode=c.DocCode
AND a.MatCode=c.MatCode
AND a.doccode=c.DocCode
AND b.FormID IN(2419,2420)
AND b.DocDate>='2012-04-01'
AND ISNULL(b.dpttype,'')<>'加盟店'
AND ISNULL(c.price2,0)<>isnull(a.totalprice,0)

COMMIT

SELECT COUNT(*) FROM SaleLog sl

SELECT uo.PackageID, * FROM Unicom_Orders uo WHERE uo.DocCode='RS20120410000381'

TBD2012022800005
TBD2011051700003
