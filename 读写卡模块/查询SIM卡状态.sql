 
/*
函数名称:fn_QuerySIMInfo
功能:查询SIM卡状态
参数:见声名
返回值:
编写:三断笛
时间:2012-01-30
示例:
备注:

*/
ALTER FUNCTION [fn_QuerySIMInfo](
	@ICCID VARCHAR(30),
	@SeriesCode VARCHAR(30),
	@Doccode VARCHAR(20),
	@SeriesNumber VARCHAR(20),
	@isLocked VARCHAR(10),
	@isActived VARCHAR(10),
	@isWriteen VARCHAR(10),
	@isValid VARCHAR(10)
)
RETURNS table /*@table TABLE(
	ICCID VARCHAR(30),
	SeriesCode VARCHAR(30),
	Doccode VARCHAR(20),
	Formid INT,
	FormType INT,
	SeriesNumber VARCHAR(20),
	EVENT VARCHAR(50),
	EventTime DATETIME,
	Sdgroup VARCHAR(20),
	sdgroupname VARCHAR(50),
	sdrogid VARCHAR(50),
	sdorgname VARCHAR(200),
	TerminalId VARCHAR(50),
	appName VARCHAR(500),
	sUserName VARCHAR(200),
	Remark VARCHAR(500))
AS
	BEGIN*/
	as
		return --INSERT INTO @table
		SELECT  a.iccid,a.seriescode,SeriesNumber,a.doccode,Formid,a.[Status],case when isnull(imsi,IMSI_Safe) is null then '无数据' else '有数据' end as IMSI,
		islocked,isactived,isWriteen,isvalid,writendate,writeencount,appname,a.remark
		FROM iSIMInfo a
		WHERE (@ICCID='' OR iccid=@ICCID)
		AND (@SeriesCode='' OR seriescode=@SeriesCode)
		AND (@SeriesNumber='' OR seriesnumber=@SeriesNumber)
		AND (@Doccode='' OR doccode=@Doccode)
		AND (@isLocked='' OR ISNULL(a.isLocked,0)=CASE WHEN @isLocked='是' then 1 else 0 END)
		AND (@isActived='' OR ISNULL(a.isActived,0)=CASE WHEN @isActived='是' then 1 else 0 END)
		AND (@isWriteen='' OR ISNULL(a.isWriteen,0)=CASE WHEN @isWriteen='是' then 1 else 0 END) 
		AND (@isValid='' OR ISNULL(a.isValid,0)=CASE WHEN @isValid='是' then 1 else 0 END) 