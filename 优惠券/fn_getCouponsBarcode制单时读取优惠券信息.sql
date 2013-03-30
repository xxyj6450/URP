/*
* 
select * from dbo.fn_getCouponsBarcode('2.1.791.02.17','1.007.1.1.1','MATGROUP','','','已赠','','1')
select * from icoupons
*/
alter FUNCTION [dbo].[fn_getCouponsBarcode](
	@stcode VARCHAR(20),					--仓库
	@matcode VARCHAR(20),					--商品
	@matgroup VARCHAR(20),
	@CouponsCode VARCHAR(30),
	@CouponsBarcode VARCHAR(50),
	@state VARCHAR(20),
	@CouponsGroup VARCHAR(20),
	@optionID varchar(5)
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
	validDate DATETIME,
	Remark	VARCHAR(500) 
	)
AS
	BEGIN
		--供零售单,开户单,套包单直接选择,
		IF @optionID=0
			BEGIN
				INSERT INTO @table
				SELECT i.stCode,b.name40,i.CouponsCode,c.CouponsName,c.GroupCode,d.GroupName,i.CouponsBarcode,i.[State],i.Price,i.DeductAmout,
				i.InDate,indoccode,i.OutDoccode,outformid,i.OutDate,outstcode,OutstName,returndoccode,returnformid,returnstcode,returnstname,returndate,
				i.valid,i.validdate,i.remark 
				FROM iCoupons i
				LEFT JOIN oStorage b ON i.stCode=b.stCode
				LEFT JOIN iCouponsGeneral c ON i.CouponsCode=c.CouponsCode
				LEFT JOIN gCouponsGroup d ON c.GroupCode=d.GroupCode
				WHERE   (@CouponsCode='' OR i.CouponsCode=@CouponsCode)
				AND (@CouponsBarcode='' OR i.CouponsBarcode like @CouponsBarcode+'%')
				AND (@CouponsGroup='' OR d.GroupCode LIKE @CouponsGroup +'%')
				and c.valid=1
				and isnull(i.Valid,1)=1
				AND ((ISNULL(c.BeginDate,'')='' OR c.BeginDate<=GETDATE()) and(isnull(i.beginValidDate,'')='' or i.beginValidDate<=getdate()))
				AND ((ISNULL(c.EndDate,'')='' OR c.EndDate>=GETDATE()) and isnull(i.ValidDate,'')='' or i.ValidDate>=getdate())
				and isnull(i.Occupyed,0)=0
			END
		ELSE IF @optionID=1
			BEGIN
				INSERT INTO @table
				SELECT i.stCode,b.name40,i.CouponsCode,c.CouponsName,c.GroupCode,d.GroupName,i.CouponsBarcode,i.[State],i.Price,i.DeductAmout,
				i.InDate,indoccode,i.OutDoccode,outformid,i.OutDate,outstcode,OutstName,returndoccode,returnformid,returnstcode,returnstname,returndate,
				i.valid,i.validdate,i.remark 
				FROM iCoupons i
				LEFT JOIN oStorage b ON i.stCode=b.stCode
				LEFT JOIN iCouponsGeneral c ON i.CouponsCode=c.CouponsCode
				LEFT JOIN gCouponsGroup d ON c.GroupCode=d.GroupCode
				WHERE (@state='' or i.State=@state)
				AND (@CouponsCode='' OR i.CouponsCode=@CouponsCode)
				AND (@CouponsBarcode='' OR i.CouponsBarcode=@CouponsBarcode)
				AND (@CouponsGroup='' OR d.GroupCode LIKE @CouponsGroup +'%')
				AND (@stcode='' OR i.stCode=@stcode)
				and c.valid=1
				and isnull(i.Valid,1)=1
				AND ((ISNULL(c.BeginDate,'')='' OR c.BeginDate<=GETDATE()) and(isnull(i.beginValidDate,'')='' or i.beginValidDate<=getdate()))
				AND ((ISNULL(c.EndDate,'')='' OR c.EndDate>=GETDATE()) and isnull(i.ValidDate,'')='' or i.ValidDate>=getdate())
				 and isnull(i.Occupyed,0)=0
			END

		return
	END