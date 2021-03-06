SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
函数名称:[getSerialNumberInfo]
功能描述:读取开户信息供后台读写卡用
编写:三断笛
修改:空白卡不作串号管理,修改SIM卡读取方式 三断笛 2012-08-05
Select * From dbo.getSerialNumberInfo('','512224196512236019')
*/
--SELECT * FROM [getSIMInfo]('18664063140')
ALTER FUNCTION [dbo].[getSerialNumberInfo](
	@SeriesNumber VARCHAR(20),
	@Vouchercode VARCHAR(30)
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
	SdorgName VARCHAR(200),
	Sdorgid varchar(50),
	NetID VARCHAR(50),
	NetPassword VARCHAR(50),
	AgentID VARCHAR(50),
	AgentPassword VARCHAR(50)
	
)
AS
	BEGIN
		INSERT INTO @table
		SELECT uo.seriesnumber,COALESCE(uo.CardNumber,LEFT(uo.ICCID,19)),
		uo.iccid,uo.DocCode,uo.Formid,uo.DocType,
		uo.UserTxt2,uo.drivername  ,uo.contactaddress,uo.ValidDate,uo.PhoneNumber,uo.ZipCode,
		uo.BirthDay,uo.cltcode,uo.cltName,uo.PackageName,uo.sdgroupname,uo.sdorgname,uo.sdorgid,'',NULL,'',''
		  FROM Unicom_Orders_2 uo with(nolock) /*left join Unicom_OrderDetails uod with(nolock) ON uo.DocCode=uod.DocCode
		left JOIN iMatGroup img ON uod.MatGroup=img.matgroup*/
		LEFT JOIN OsdorgExtInfo oei ON uo.sdorgid=oei.SdorgID
		WHERE (uo.SeriesNumber=@SeriesNumber OR uo.UserTxt2=@Vouchercode)
		AND uo.checkState='待审核'
		AND uo.DocStatus=0
		/*AND ( (uo.FormID in(9102,9146,9237) 
									and EXISTS(SELECT 1 FROM dbo.fn_sysGetNumberAllocationConfig('SIM卡大类') x 
												where img.path LIKE '%/' +x.propertyvalue + '/%')
									)
			)*/
		--AND uo.formid IN(9102,9146,9237)
		INSERT INTO @table(SeriesNumber,seriesCode,ICCID,Doccode,FormID,DocType,SdGroupName,SdorgName,sdorgid,CustomerName)
		SELECT uo.seriesnumber,uo.SimCode1,uo.iccid,uo.DocCode,uo.Formid,uo.DocType,uo.sdgroupname,uo.sdorgname,uo.sdorgid,uo.CustomerName 
		FROM BusinessAcceptance_H_2  uo with(nolock)  
		WHERE uo.SeriesNumber=@SeriesNumber
		AND uo.checkState='待审核'
		AND uo.DocStatus=0
		AND uo.FormID=9158
		return
	END