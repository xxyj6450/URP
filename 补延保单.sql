		DECLARE @Sdgroup VARCHAR(20),@SdgroupName VARCHAR(50),@Sdorgid VARCHAR(20),@sdorgname VARCHAR(200),@docdate DATETIME,
		@cltCode VARCHAR(20),@cltName VARCHAR(50),@phoneNumber VARCHAR(50),@stcode VARCHAR(20),@stName VARCHAR(200),@remark VARCHAR(500),
		@CompanyId VARCHAR(20),@DocStatus INT,@newDocStatus INT,@SeriesNumber VARCHAR(30)
		DECLARE 	@FormID INT,
	@doccode VARCHAR(20),
	@userCode VARCHAR(20),
	@userName VARCHAR(50),
	@NewFormID int,
	@OptionID VARCHAR(100) ,
	@NewDoccode VARCHAR(20)   ,
	@LinkDocInfo VARCHAR(50)

/*
清除多余的数据
BEGIN TRAN
DELETE FROM Unicom_OrderDetails
WHERE DocCode='PS20120101002936'
AND DocItem=10
COMMIT
SELECT uod.doccode,COUNT(uod.doccode) FROM Unicom_OrderDetails uod,unicom_orders b 
WHERE uod.MatName LIKE '%延保%'
AND uod.DocCode=b.DocCode
AND b.DocStatus<>0
AND  not EXISTS(SELECT 1 FROM SeriesCode_HD sch WHERE sch.refcode=uod.DocCode AND sch.DocStatus=1)
GROUP BY uod.doccode
ORDER BY 2 DESC
*/
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRAN
SET NOCOUNT on
SELECT @NewFormID=2447
DECLARE abc CURSOR READ_ONLY FORWARD_ONLY FOR 
SELECT  TOP 100  b.sdgroup,b.sdgroupname,sdorgid,sdorgname,b.stcode,b.stname,b.cltCode,b.cltName,
b.SeriesNumber,b.Companyid, b.DocStatus,b.DocDate,b.FormID,uod.DocCode,b.Companyid
FROM Unicom_OrderDetails uod,unicom_orders b 
WHERE uod.MatName LIKE '%延保%'
AND uod.DocCode=b.DocCode
AND b.DocStatus<>0
AND not EXISTS(SELECT 1 FROM SeriesCode_HD sch WHERE sch.refcode=uod.DocCode )
AND uod.DocCode NOT IN('PS20120101002936')
OPEN abc
FETCH NEXT FROM abc INTO @Sdgroup,@SdgroupName,@Sdorgid,@sdorgname,@stcode,
@stName,@cltCode,@cltName,@SeriesNumber,@CompanyId,@DocStatus,@docdate,
@FormID,@doccode,@CompanyId
--生成延保单
/*SELECT @Sdgroup=sdgroup,@SdgroupName=sdgroupname,@Sdorgid=sdorgid,@sdorgname=sdorgname,@stcode=stcode,@stName=stname,
@cltCode=sph.cltCode,@cltName=sph.cltName,@phoneNumber=sph.SeriesNumber,@CompanyId=sph.Companyid,@docdate=CONVERT(VARCHAR(10),GETDATE(),120),
@DocStatus=sph.DocStatus
FROM Unicom_Orders   sph WHERE sph.DocCode=@doccode
IF @DocStatus =(SELECT g.postdocstatus 
   FROM gform g WHERE g.formid=@FormID)
    BEGIN
    	RAISERROR('单据已确认,不允许执行此功能.',16,1)
    	return
    END*/
    WHILE @@FETCH_STATUS=0
		BEGIN
			--生成单据
			EXEC sp_newdoccode @NewFormID,'',@NewDoccode output
			INSERT INTO SeriesCode_HD(Doccode,DocDate,FormID,RefFormid,RefCode,DocStatus,DocType,EnterName,EnterDate,
			CompanyId,stCode,stName,SdorgID,SdorgName,SdGroup,SdGroupName,cltcode,cltname,phonenumber,ExtendWarrantyMatcode,
			ExtendWarrantyMatName,ExtendWarrantyMonth,Totalmoney,Remark,SeriesCode,MatCode,MatName)--,ExtendWarrantyDate)
			SELECT top 1 @newdoccode,@docdate,@NewFormID,@FormID,@doccode,1,'延保单','SYSTEM',getdate(),
			@companyid,@stcode,@stName,@Sdorgid,@sdorgname,@Sdgroup,@SdgroupName,@cltCode,@cltname,
			@phoneNumber,c.ExtendMatcode,c.ExtendMatName,c.ExtendWarrantyMonth,0,'延保单数据异常,管理员补单',uod.seriescode,img.matcode,img.matname
			FROM Unicom_OrderDetails uod
			LEFT JOIN iMatGeneral img ON uod.MatCode=img.MatCode
			LEFT JOIN iMatGroup img2 ON img.MatGroup=img2.matgroup
			INNER JOIN T_ExtendWarrantyConfig c ON uod.MatCode=c.Matcode
			WHERE uod.DocCode=@doccode
			AND EXISTS(SELECT 1 FROM dbo.fn_sysGetNumberAllocationConfig('手机大类') x where img2.path LIKE '%/'+x.propertyvalue+'/%')
			--PRINT @NewDoccode
			--确认单据
			EXEC sp_PostSeriesCodeDoc 2447,@NewDoccode,'SYSTEM','管理员',NULL,@LinkDocInfo output
			--将零售单批量确认
			INSERT INTO gtaskdocpost(FormID,Doccode,Usercode,Createtime,formtype,docmemo)
			SELECT 2419,@LinkDocInfo,'SYSTEM',GETDATE(),5,'延保单数据异常,管理员补单'
			--更新状态
			--UPDATE SeriesCode_HD
			--	SET DocStatus = 1
			--WHERE Doccode=@NewDoccode
			FETCH NEXT FROM abc INTO @Sdgroup,@SdgroupName,@Sdorgid,@sdorgname,@stcode,
			@stName,@cltCode,@cltName,@SeriesNumber,@CompanyId,@DocStatus,@docdate,
			@FormID,@doccode,@CompanyId
		END
	CLOSE abc
	DEALLOCATE abc
	SET NOCOUNT OFF
	
	SELECT * FROM SeriesCode_HD sch WHERE sch.Remark='延保单数据异常,管理员补单'
	
	SELECT * FROM Unicom_OrderDetails uod WHERE uod.DocCode='PS20120101000109'
	SELECT * FROM gtaskdocpost g
	ROLLBACK
	
	DELETE FROM SeriesCode_HD WHERE  Remark='延保单数据异常,管理员补单'
	
 COMMIT
 
 SELECT * FROM SeriesCode_HD sch WHERE sch.Doccode='YBD2012020100295'