/*
函数名称:fn_QueryDocNotPost
功能:查询未确认单据
参数:见声名
返回:见声名
编写:三断笛
时间:2012-01-15
备注:
*/
alter FUNCTION [dbo].[fn_QueryDocNotPost](
	@SeriesNumber VARCHAR(50),
	@Doccode VARCHAR(20),
	@OpenSdgroup VARCHAR(50),
	@Begindate DATETIME,
	@EndDate DATETIME,
	@DocType VARCHAR(200),
	@Sdorgid VARCHAR(50)
)
RETURNS @table TABLE(
	Doccode VARCHAR(20),
	DocDate DATETIME,
	FormID INT,
	DocType VARCHAR(50),
	FormType INT,
	CheckFormID INT,
	SeriesNumber VARCHAR(50),
	PackageID VARCHAR(50),
	PackageName VARCHAR(200),
	cltCode VARCHAR(50),
	cltName VARCHAR(50),
	OpenSdgroup VARCHAR(20),
	OpenSdgroupName VARCHAR(50),
	AuditDate DATETIME,
	SdorgID VARCHAR(50),
	SdorgName VARCHAR(200)
)
AS
	BEGIN
		INSERT INTO @table
		SELECT doccode,DocDate ,Formid,doctype,CASE WHEN FormID IN(9102) THEN 5 ELSE 16 END,9139,Seriesnumber,
		packageid,PackageName,CltCode,Cltname,isnull(uo.OpenSdgroup,uo.Audits),isnull(uo.OpensdgroupName,uo.Auditingname),isnull(uo.opendate,uo.Auditingdate),
		uo.sdorgid,uo.sdorgname
		FROM Unicom_Orders uo WITH(NOLOCK)
		WHERE (@Doccode='' OR uo.DocCode=@Doccode)
		AND (@Begindate='' OR docdate>=@Begindate)
		AND (@EndDate='' OR docdate<=@EndDate)
		AND (@DocType='' OR doctype=@DocType)
		AND (@Sdorgid='' OR sdorgid=@Sdorgid)
		AND (@OpenSdgroup='' OR isnull(uo.OpenSdgroup,uo.Auditing)=@OpenSdgroup)
		AND uo.DocStatus=0
		AND uo.checkState='通过审核'
		INSERT INTO @table
		SELECT doccode,DocDate ,Formid,doctype,16,9157,Seriesnumber,
		NULL,NULL,CltCode,Cltname,isnull(uo.OpenSdgroup,uo.Audits),isnull(uo.OpensdgroupName,uo.Auditingname),isnull(uo.opendate,uo.Auditingdate),
		uo.sdorgid,uo.sdorgname
		FROM BusinessAcceptance_H uo WITH(NOLOCK)
		WHERE uo.DocStatus=0
		AND uo.CheckState='通过审核'
		and (@Doccode='' OR uo.DocCode=@Doccode)
		AND (@Begindate='' OR docdate>=@Begindate)
		AND (@EndDate='' OR docdate<=@EndDate)
		AND (@DocType='' OR doctype=@DocType)
		AND (@Sdorgid='' OR sdorgid=@Sdorgid)
		AND (@OpenSdgroup='' OR isnull(uo.OpenSdgroup,uo.Audits)=@OpenSdgroup)
		return
	END