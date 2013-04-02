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
	DeductAmout MONEY,
	deducedMatcode VARCHAR(50),
	DeducedMatName VARCHAR(200),
	DeducedDigit INT,
	InDate DATETIME,
	InDoccode VARCHAR(20),
	OutDoccode VARCHAR(20),
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
	Remark	VARCHAR(50)
	)
AS
	BEGIN
		INSERT INTO @table
		SELECT i.stCode,b.name40,i.CouponsCode,c.CouponsName,c.GroupCode,d.GroupName,i.CouponsBarcode,i.[State],i.Price,i.DeductAmout,i.DeducedMatcode,i.DeducedMatName,i.DeducedDigit,
		i.InDate,indoccode,i.OutDoccode,outformid,i.OutDate,outstcode,OutstName,returndoccode,returnformid,returnstcode,returnstname,returndate,
		i.valid,c.BeginDate,c.EndDate,i.remark
		FROM iCoupons i with(nolock)
		inner JOIN iCouponsGeneral c with(nolock) ON i.CouponsCode=c.CouponsCode
		inner JOIN gCouponsGroup d with(nolock) ON c.GroupCode=d.GroupCode
		LEFT JOIN oStorage b with(nolock) ON i.stCode=b.stCode 
		WHERE   (@stcode='' OR b.stCode=@stcode)
		AND (@CouponsCode='' OR i.CouponsCode=@CouponsCode)
		AND (@CouponsBarcode='' OR i.CouponsBarcode=@CouponsBarcode)
		AND (@CouponsGroup='' OR d.GroupCode LIKE @CouponsGroup +'%')
		AND (@state='' OR i.[State]=@state)
		and (@CouponsOwner='' or c.CouponsOWNER=@CouponsOwner)

 
		return
	END