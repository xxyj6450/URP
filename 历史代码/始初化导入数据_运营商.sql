--导入号码池
INSERT INTO SeriesPool
SELECT * FROM ierp..SeriesPool sp
WHERE sp.[STATE] IN('待选','已选')
AND sp.Actived='未激活'
--更新预约部门
BEGIN tran
UPDATE a
SET a.PrivateSdorgid = b.sdorgid
FROM SeriesPool a,sop10.ierp.dbo.SDOrg_bak b 
WHERE a.privatesdorgid=b.oldsdorgid
BEGIN tran
UPDATE SeriesPool
	SET PrivateSdorgid = NULL
	--SELECT sp.PrivateSdorgid, * FROM SeriesPool sp
WHERE PrivateSdorgid NOT IN(SELECT sdorgid FROM oSDOrg os)

--更新预占门店
BEGIN tran
UPDATE a
SET sdorgid=b.sdorgid
FROM SeriesPool a,sop10.ierp.dbo.SDOrg_bak b 
WHERE a.sdorgid=b.oldsdorgid
AND a.state='已选'
--延长预占时间
BEGIN tran
UPDATE SeriesPool
	SET ReleaseDate = '2012-01-01 15:00:00'
WHERE  state='已选'

TRUNCATE TABLE Seriespool_D
TRUNCATE TABLE SeriesPool_H

SELECT os.[PATH], * FROM oSDOrg os WHERE os.SDOrgID='1.2.576.09.01'
 

 
 
 
 
BEGIN tran
SET IDENTITY_INSERT sMatSDOrgPrice  on
INSERT INTO sMatSDOrgPrice( matcode, costprice, lastinprice, salesprice, 
       selfprice, selfprice1, end4, tobesalesprice, tobeselfprice, money4, 
       tobeselfprice1, lastmodifydate, lastmodifyname, rowid, cv30, SDOrgID, 
       crprice, beginday, endday, recover, CompanyID, CompanyName, entername, 
       enterdate, saleprice1, DiscountPrice, ID)
SELECT matcode,costprice,lastinprice,salesprice,selfprice,selfprice1,end4,
       tobesalesprice,tobeselfprice,money4,tobeselfprice1,lastmodifydate,
       lastmodifyname,rowid,cv30,SDOrgID,crprice,beginday,endday,recover,
       CompanyID,CompanyName,entername,enterdate,saleprice1,DiscountPrice,ID
FROM sop10.ierp.dbo.sMatSDOrgPrice a
WHERE NOT EXISTS(SELECT 1 FROM sMatSDOrgPrice b WHERE a.matcode=b.matcode AND a.sdorgid=b.SDOrgID)

SET IDENTITY_INSERT sMatSDOrgPrice  OFF
COMMIT
DECLARE @sql VARCHAR(4000)
SELECT @sql=''
SELECT @sql=@sql+NAME+',' FROM syscolumns s WHERE id=OBJECT_ID('sMatSDOrgPrice')
PRINT @sql
 ROLLBACK
 SELECT * FROM sMatSDOrgPrice
 
 
 ---------------------------------------------------------------
 