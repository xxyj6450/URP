SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
Select * From dbo.getSerialNumberInfo('','512224196512236019')
*/
--SELECT * FROM [getSIMInfo]('18664063140')
ALTER FUNCTION [dbo].[getSerialNumberInfo_V2](
	@SeriesNumber VARCHAR(20),
	@Vouchercode VARCHAR(30),
	@UserCode VARCHAR(50)
)
RETURNS @table TABLE(
	SeriesNumber VARCHAR(20),
	seriesCode VARCHAR(50),
	ICCID VARCHAR(50),
	Doccode VARCHAR(20),
	FormID INT,
	DocType VARCHAR(50),
	VoucherCode VARCHAR(50),
	VoucherAddress VARCHAR(500),
	CurAddress VARCHAR(500),
	ValidDate DATETIME,
	PhoneNumber VARCHAR(50),
	ZipCode VARCHAR(50),
	BirthDay DATETIME,
	CustomerCode VARCHAR(20),
	CustomerName VARCHAR(50),
	PackageName VARCHAR(200),
	SdGroupName VARCHAR(50),
	SDORGID VARCHAR(50),
	SdorgName VARCHAR(200),
	Audit VARCHAR(50),
	AuditName VARCHAR(50),
	AuditDate DATETIME,
	AuditFlag BIT							--审核人标记,当审核人与@usercode相同时为1,否则为0.这样可以优先将审核人为@usercode的单据排序
)
AS
	BEGIN
		INSERT INTO @table
		SELECT uo.seriesnumber,uo.cardnumber,
		uo.iccid,uo.DocCode,uo.Formid,uo.DocType,
		uo.usertxt2,uo.drivername,uo.ContactAddress,uo.ValidDate,uo.PhoneNumber,uo.ZipCode,
		uo.BirthDay,uo.cltCode,uo.cltName,uo.PackageName,uo.sdgroupname,uo.sdorgid, uo.sdorgname,uo.Audits,uo.Auditingname,uo.Auditingdate,
		CASE WHEN uo.Audits=@UserCode THEN 1 ELSE 0 end
		  FROM Unicom_Orders uo-- left join Unicom_OrderDetails uod ON uo.DocCode=uod.DocCode
		--left JOIN iMatGroup img ON uod.MatGroup=img.matgroup
		WHERE (uo.SeriesNumber=@SeriesNumber OR uo.usertxt2=@Vouchercode)
		AND uo.checkState='待审核'
		AND uo.DocStatus=0
		/*AND ( (uo.FormID in(9102,9146,9237) 
									and EXISTS(SELECT 1 FROM dbo.fn_sysGetNumberAllocationConfig('SIM卡大类') x 
												where img.path LIKE '%/' +x.propertyvalue + '/%')
									)
			)*/
		--AND uo.formid IN(9102,9146,9237)
		INSERT INTO @table(SeriesNumber,seriesCode,ICCID,Doccode,FormID,DocType,SdGroupName,SdorgName,CustomerName,Audit,AuditName,AuditDate,AuditFlag,SDORGID)
		SELECT uo.seriesnumber,uo.SimCode1,uo.iccid,uo.DocCode,uo.Formid,uo.DocType,uo.sdgroupname,uo.sdorgname,uo.CustomerName,uo.Audits,uo.Auditingname,uo.Auditingdate,
		CASE WHEN uo.Audits=@UserCode THEN 1 ELSE 0 END,uo.SdorgID
		FROM BusinessAcceptance_H  uo  
		WHERE uo.SeriesNumber=@SeriesNumber
		AND uo.checkState='待审核'
		AND uo.DocStatus=0
		AND uo.FormID=9158
		return
	END
	
 
	