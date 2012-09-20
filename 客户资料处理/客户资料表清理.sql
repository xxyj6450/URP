SELECT commondb.dbo.regexp_replace('13922914184``','\D','')

BEGIN TRAN
--去除号码中的非数字
UPDATE sPickorderHD
	SET usertxt2 = commondb.dbo.regexp_replace(usertxt2,'\D','')
WHERE FormID IN(2419,2420)
AND dbo.isValidSeriesNumber(usertxt2,0)=0
AND usertxt2 IS NOT NULL
--1.有引用单号,则从引用单号中更新号码
UPDATE sPickorderHD
	SET usertxt2 = b.seriesnumber,
	cltCode = b.cltcode,
	cltname=b.cltname
	--SELECT a.usertxt2,b.SeriesNumber, *   
FROM spickorderhd a,Unicom_Orders b
WHERE a.refcode=b.DocCode
AND dbo.isValidSeriesNumber(a.usertxt2,0)=0
--2.有引用单号,则从引用单号中更新号码
UPDATE sPickorderHD
	SET usertxt2 = b.seriesnumber,
	cltCode = b.CustomerCode ,
	cltname=b.CustomerName
	--SELECT a.usertxt2,b.SeriesNumber, *   
FROM spickorderhd a,BusinessAcceptance_H  b
WHERE a.refcode=b.DocCode
AND dbo.isValidSeriesNumber(a.usertxt2,0)=0
--从退货源单中取号码数据
UPDATE sPickorderHD
	SET usertxt2=uo.seriesnumber,
	cltCode = uo.cltcode,
	cltname=uo.cltname
FROM spickorderhd a,Unicom_Orders uo
WHERE a.ClearDocCode=uo.DocCode
AND dbo.isValidSeriesNumber(a.usertxt2,0)=0
--
UPDATE sPickorderHD
	SET usertxt2=uo.seriesnumber,
	cltCode = uo.CustomerCode ,
	cltname=uo.CustomerName
FROM spickorderhd a,BusinessAcceptance_H uo
WHERE a.ClearDocCode=uo.DocCode
AND dbo.isValidSeriesNumber(a.usertxt2,0)=0
--
UPDATE a
	SET usertxt2=uo.usertxt2,
	cltCode = uo.cltcode,
	cltname=uo.cltname
FROM spickorderhd a,spickorderhd uo
WHERE a.ClearDocCode=uo.DocCode
AND dbo.isValidSeriesNumber(a.usertxt2,0)=0
AND dbo.isValidSeriesNumber(uo.usertxt2,0)=1
--3.无区号的号码把区号补上
UPDATE sPickorderHD
	SET usertxt2 = '0'+b.areaid+a.usertxt2
	--SELECT a.usertxt2, '0'+b.areaid+a.usertxt2,a.*
FROM spickorderhd a,oSDOrg b
WHERE a.FormID IN(2419,2420)
AND dbo.isValidSeriesNumber(a.usertxt2,0)=0
AND a.sdorgid=b.SDOrgID
AND LEN(a.usertxt2)=8
--4.取前11位或12位,可以组成正确与号码的数据
UPDATE sPickorderHD
	SET usertxt2=CASE 
					when dbo.isValidSerdbo.getsubcashprebalanceiesNumber(LEFT(usertxt2,12),0)=1 THEN LEFT(usertxt2,12) 
					WHEN dbo.isValidSeriesNumber(LEFT(usertxt2,11),0)=1 THEN LEFT(usertxt2,11) 
	             END
WHERE FormID IN(2419,2420)
AND dbo.isValidSeriesNumber(usertxt2,0)=0


SELECT usertxt2, * FROM sPickorderHD sph
WHERE sph.FormID IN(2419,2420)
and dbo.isValidSeriesNumber(usertxt2,0)=0
--and sph.DocCode='RE20100819000237'
ROLLBACK

COMMIT
RT20100819000004
RE20100819000237
076987884513
135415866714

SELECT dbo.isValidSeriesNumber('076987884513',0)

select Commondb.dbo.regexp_like('076987884513','^0\d{2,3}(-)?\d{7,8}(-\d{4})?$')