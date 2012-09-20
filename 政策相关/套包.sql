/*
* 函数名称:[fn_getPackage]
* 功能描述:根据条件获取套包
* 参数:见声名部分
* 编写:三断笛
* 2010/5/28
* 备注:
* ------------------------------------------------
* 
*/
alter FUNCTION [dbo].[fn_getPackage](
 @begindate DATETIME,
 @enddate DATETIME,
 @PackageID  VARCHAR(50),
 @companyID VARCHAR(20),
 @AreaID VARCHAR(20),
 @sdorgid VARCHAR(30)
)  
RETURNS @table TABLE (
	PackageID VARCHAR(20),
	PackageName VARCHAR(50),
	begindate DATETIME,
	ENDDate DATETIME,
	CompanyID VARCHAR(20),
	CompanyName VARCHAR(40),
	AreaID VARCHAR(20),
	AreaName VARCHAR(40),
	SdorgID VARCHAR(20),
	SdorgName VARCHAR(40),
	HdMemo VARCHAR(255)
	)
as  
	BEGIN
		INSERT INTO @table
			SELECT doccode,doctype,begindate,enddate,companyid,companyname,areaid,areaName,SdOrgID,SdorgName,HdMemo
			FROM policy_h a
			WHERE formid=9110
			AND (@begindate='' OR @begindate BETWEEN a.begindate AND a.enddate)
			AND (@enddate='' OR @enddate BETWEEN a.begindate AND a.enddate)
			AND (@PackageID='' OR a.doccode=@PackageID)
			AND (@companyID='' OR a.companyid=@companyID)
			AND (@SdorgID='' OR a.sdorgid=@SdorgID +'%')
			AND (@AreaID='' OR a.sdorgid like @AreaID+'%' )
			OR a.areaid IN(SELECT areaid FROM osdrog WHERE a.sdorgid = @sdorgid )
		RETURN 
	END

alter FUNCTION fn_getPackageMat(
	@Matgroup VARCHAR(20),
	@matcode VARCHAR(20),
	@matname VARCHAR(20),
	@PackageID VARCHAR(20),
	@seriescode VARCHAR(40)
)
RETURNs @table TABLE(
	matcode VARCHAR(20),
	MatName VARCHAR(40),
	Seriescode VARCHAR(40))
AS
	BEGIN
		IF @Matgroup IN('SS' 
			BEGIN
					INSERT INTO @table
					SELECT b.matcode,b.matname,i.SeriesCode 
					FROM policy_d  b LEFT JOIN iSeries i ON b.matcode=i.matcode
					WHERE doccode=@PackageID
					AND (@matcode='' OR b.matcode LIKE '%' +@matcode +'%')
					AND (@matname='' OR b.matname LIKE '%'+@matname+'%')
					AND b.detailrowid =(SELECT rowid FROM policy_d1 WHERE DocCode=@PackageID AND matgroup=@Matgroup)	
					AND (@seriescode='' OR i.SeriesCode LIKE '%'+@seriescode +'%')	                 	    	
			END
		ELSE
			BEGIN 
				INSERT INTO @table
					SELECT b.matcode,b.matname,''  FROM policy_d  b 
					WHERE doccode=@PackageID
					AND (@matcode='' OR b.matcode LIKE '%' +@matcode +'%')
					AND (@matname='' OR b.matname LIKE '%'+@matname+'%')
					AND b.detailrowid =(SELECT rowid FROM policy_d1 WHERE DocCode=@PackageID AND matgroup=@Matgroup)
			end
		return
	END
	
	ALTER TABLE PackageSelect_HD ADD Seriescode VARCHAR(20)
  
--select * from dbo.fn_getPackage('TBD2010052600005')


CREATE proc sp_CreateSelectPackageDoc
	@refcode VARCHAR(20),
	@refdate DATETIME,
	@refformId INT,
	@companyid VARCHAR(20),
	@companyname VARCHAR(40),
	@sdorgid VARCHAR(30),
	@sdorgname VARCHAR(40),
	@user VARCHAR(20),
	@linkinfo VARCHAR(200)
AS
	BEGIN
		DECLARE @OldDocCode VARCHAR(20)			---原套包单
		DECLARE @newDoccode VARCHAR(20)			--新套包单
		                               			--
		--查找是否已有套包单
		SELECT @OldDocCode=doccode FROM PackageSelect_HD WHERE refcode=@refcode
		IF @OldDocCode IS NOT NULL				--当已经存在套包单时
			BEGIN
				--直接打开套包单
				SELECT @linkinfo='9113;5;'+ @olddoccode
			end
		ELSE	--如果还没有套包单,则新建一个
		   begin
				exec sp_newdoccode 9113,'',@newDoccode output  
				INSERT INTO PackageSelect_HD(
					doccode,docdate,refcode,refdate,formid,docstatus,
					companyid,companyname,sdorgid,sdorgname,EnterName)
				VALUES(@newDoccode,GETDATE(),@refcode,@refdate,9113,0,
						@companyid,@companyname,@sdorgid,@sdorgname,@user)
				--打开单据
				SELECT @linkinfo='9113;5;'+ @newdoccode
			end
		END
		
	