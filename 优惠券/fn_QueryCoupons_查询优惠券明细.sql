--SELECT * FROM [fn_QueryCoupons]('1.4.755.03.01','','','','')

alter FUNCTION [dbo].[fn_QueryCoupons](
	@stcode VARCHAR(20),
	@CouponsCode VARCHAR(30),
	@CouponsBarcode VARCHAR(50),
	@state VARCHAR(20),
	@CouponsGroup VARCHAR(20),
	@CouponsOwner varchar(50),
	@Option varchar(50)
)
--select *from iCoupons ic where ic.CouponsBarcode='HYQ201304120000000235'
RETURNS @table TABLE(
	stcode VARCHAR(40),
	stname VARCHAR(200),
	CouponsCode VARCHAR(20),
	CouponsName VARCHAR(50),
	CouponsGroup VARCHAR(20),
	CouponsGroupName VARCHAR(50),
	CouponsBarcode VARCHAR(30),
	STATE VARCHAR(20),
	Price MONEY,
	DeductDoccode varchar(50),
	DeductDate datetime,
	DeductStcode varchar(50),
	Deductstname varchar(50),
	DeductAmout MONEY,
	DeductSeriescode varchar(30),
	deducedMatcode VARCHAR(50),
	DeducedMatName VARCHAR(200),
	DeducedDigit INT,
	InDate DATETIME,
	InDoccode VARCHAR(30),
	OutDoccode VARCHAR(30),
	OutFormID INT,
	OutDate DATETIME,
	OutStcode VARCHAR(50),
	OutStName VARCHAR(200),
	RETURNDoccode VARCHAR(20),
	RETURNFormID INT,
	ReturnStcode VARCHAR(50),
	RETURNStName VARCHAR(200),
	ReturnDate DATETIME,
	valid BIT,
	BeginvalidDate DATETIME,
	EndValidDate datetime,
	Remark	VARCHAR(500)
	)
AS
	BEGIN
		INSERT INTO @table
		SELECT i.stCode,b.name40,i.CouponsCode,c.CouponsName,c.GroupCode,d.GroupName,i.CouponsBarcode,i.[State],i.Price,i.DeducedDoccode,i.DeducedDate,
		i.DeducedStcode,i.DeducedStName, i.DeductAmout,i.DeducedSeriescode,i.DeducedMatcode,i.DeducedMatName,i.DeducedDigit,
		i.InDate,indoccode,i.OutDoccode,outformid,i.OutDate,outstcode,OutstName,returndoccode,returnformid,returnstcode,returnstname,returndate,
		i.valid,c.BeginDate,c.EndDate,i.remark
		FROM iCoupons i with(nolock)
		inner JOIN iCouponsGeneral c with(nolock) ON i.CouponsCode=c.CouponsCode
		inner JOIN gCouponsGroup d with(nolock) ON c.GroupCode=d.GroupCode
		LEFT JOIN oStorage b with(nolock) ON i.stCode=b.stCode 
		WHERE   (@stcode='' or @stcode='119.769' OR b.stCode=@stcode)
		AND (@CouponsCode='' OR i.CouponsCode=@CouponsCode)
		AND (@CouponsBarcode='' OR i.CouponsBarcode=@CouponsBarcode)
		AND (@CouponsGroup='' OR d.GroupCode LIKE @CouponsGroup +'%')
		AND (@state='' OR exists(select 1 from commondb.dbo.split(isnull(@state,''),',') s where s.List= i.[State]))
		and (@CouponsOwner='' or c.CouponsOWNER=@CouponsOwner)

 
		return
	END
	
	