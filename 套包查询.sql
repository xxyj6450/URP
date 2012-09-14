/*  
* 函数名称:[fn_getPackageEX]  
* 功能描述:根据条件获取套包  
* 参数:见声名部分  
* 编写:三断笛  
* 2010/5/28  
* 备注: 查询条件比较灵活，请翻阅MSDN的cross apply部分
* 示例:select * from dbo.fn_getPackage('2010-06-07','2010-06-07','','','','')
*-------------------------------------------------------------------------------
*修改时间：2012/04/11
*修改人：三断笛
*修改说明：对此功能进行扩展升级，新增参数，并新调整查询条件。可以根据商品信息反查政策。
*备注：匹配方式从大小至小的方式逐层过滤查询
*示例：select * from dbo.fn_getPackageEX('2012-04-11','2012-04-11','','','','','','','354847048649269','','','','是','','')
select * from dbo.fn_getPackageEX('2012-04-11','2012-04-13','','','','','769','','','','','','是','','')
*/  
ALTER  FUNCTION [dbo].[fn_getPackageEX](  
	@begindate DATETIME,  
	@enddate DATETIME,  
	@PackageID  VARCHAR(50), 
	@PackageName VARCHAR(200),
	@PackageType VARCHAR(200), 
	@companyID VARCHAR(20),  
	@AreaID VARCHAR(20),  
	@sdorgid VARCHAR(30),
	@Seriescode VARCHAR(50),
	@Matcode VARCHAR(50),
	@Mattype VARCHAR(50),
	@Matgroup VARCHAR(50),
	@Valid VARCHAR(10),
	@Old VARCHAR(50),
	@Reserved VARCHAR(50)
)    
RETURNS @table TABLE (  
	PackageID VARCHAR(20),						--政策编码
	PackageName VARCHAR(200),					--政策名称
	PackageType VARCHAR(200),					--政策类型
	begindate DATETIME,							--起始时间
	ENDDate DATETIME,							--结束时间
	CompanyID VARCHAR(100),						--公司编码
	CompanyName VARCHAR(200),					--公司名称
	AreaID VARCHAR(100),						--区域编码
	AreaName VARCHAR(200),						--区域名称
	SdorgID VARCHAR(500),						--部门编码
	SdorgName VARCHAR(200),						--部门名称
	Valid BIT,									--是否有效
	Old BIT,									--是否老客户套包
	Reserved BIT,								--是否预约套包
	HdMemo VARCHAR(255),						--备注
	StockState VARCHAR(100)						--库存状态
 )  
as    
 BEGIN  
 	DECLARE @stcode VARCHAR(50),@State VARCHAR(50),@SdorgID1 VARCHAR(50)
 	
	--若串号不为空，则取串号的信息
	IF ISNULL(@Seriescode,'')!=''
		BEGIN
			return
			SELECT  @matcode=matcode,@stcode=i.stcode,@State=i.[state]
			FROM iSeries i WITH(NOLOCK) WHERE i.SeriesCode=@Seriescode
			--如果没有匹配到串号,则返回包含无状态的政策
			IF @@ROWCOUNT=0 
				BEGIN
					INSERT INTO @table  
					SELECT a.doccode,a.PackageName,a.doctype,a.begindate,a.enddate,a.companyid,a.companyname,a.areaid,a.areaName,a.SdOrgID,a.SdorgName,
					a.actived,a.old,a.OnlyReservedCustomer, a.HdMemo,@State
					FROM policy_h a  WITH(NOLOCK) inner join policy_d pd  WITH(NOLOCK) ON a.DocCode=pd.DocCode
					WHERE formid=9110  
					AND (@PackageID='' or a.DocCode=@PackageID)
					AND (@PackageName='' or a.PackageName LIKE '%'+@PackageName+'%')
					AND (@PackageType='' OR a.DocType=@PackageType)
					AND (@begindate='' OR a.begindate<=@begindate)
					AND (@enddate='' OR a.enddate>=@enddate)
					AND (@Valid='' OR ISNULL(a.actived,0)=CASE @Valid WHEN '是' then 1 else 0 END)
					AND (@Old='' OR ISNULL(a.old,0)=CASE @Old WHEN '是' then 1 else 0 END)
					AND (@Reserved='' OR ISNULL(a.OnlyReservedCustomer,0)=CASE @Reserved WHEN '是' then 1 else 0 END)
					AND pd.inStock='无状态'
					--匹配公司
					AND (@companyID=''  OR ISNULL(a.companyid,'')='' 
							--直接匹配公司
							OR (ISNULL(a.companyid,'')!='' AND @companyID!='' 
								AND  exists(select 1 from split(ISNULL(a.companyid,''),',') WHERE list=@companyID)
							)
							--部门也是与公司相关，所以再尝试从部门列表中取出公司来匹配
							OR (isnull(a.sdorgid,'')!='' AND @companyID!='' 
								and EXISTS(SELECT 1 FROM SPLIT(ISNULL(a.sdorgid,''),',') x,oPlantSDOrg os  WITH(NOLOCK) WHERE x.list=os.SDOrgID AND os.PlantID=@companyID)
							)
					)
					--匹配区域
						AND (@AreaID=''
								--直接匹配区域，并可按区域级别查询
								OR (ISNULL(a.areaid,'')!='' AND @AreaID!='' AND ISNULL(a.sdorgid,'')='' 
									AND (
											EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.areaid,''),',') x,gArea g  WITH(NOLOCK) WHERE g.areaid=@AreaID AND g.[PATH] LIKE '/%'+x.list+'/%')
											OR EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.areaid,''),',') x,gArea g  WITH(NOLOCK) WHERE g.areaid=x.list AND g.[PATH] LIKE '/%'+@AreaID+'/%')
											)
								)
								--再尝试从部门资料中取出区域,不再用部门所在的区域进行区域级联查询
								OR (ISNULL(a.sdorgid,'')!='' AND @AreaID!='' 
									AND (
											EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.sdorgid,''),',') x 
													inner join oSDOrg o WITH(NOLOCK) on o.path like '%/'+x.list+'/%' 
													inner join gArea g WITH(NOLOCK) ON  g.areaid=o.AreaID
													where g.path LIKE '%/'+@AreaID+'/%')
											OR EXISTS(SELECT 1 FROM commondb.dbo.[Split](isnull(a.sdorgid,''),',') x inner join oSDOrg o WITH(NOLOCK)   on o.path LIKE '%/'+x.list+'/%' 
													where o.areaid=@AreaID)
									)
								)
						)
					--匹配门店
					AND(@sdorgid='' OR ISNULL(a.sdorgid,'')='' 
							--匹配门店，并按层级匹配
							OR(ISNULL(a.sdorgid,'')!='' AND @sdorgid!='' 
								AND EXISTS(SELECT 1 FROM SPLIT(ISNULL(a.sdorgid,''),',') x,oSDOrg o  WITH(NOLOCK) WHERE o.SDOrgID=@sdorgid AND o.path LIKE '%/'+x.list+'/%')
							)
					)
					GROUP BY a.doccode,a.PackageName,a.doctype,a.begindate,a.enddate,a.companyid,a.companyname,a.areaid,a.areaName,a.SdOrgID,a.SdorgName,
					a.actived,a.old,a.OnlyReservedCustomer, a.HdMemo 
					return
				END
			--再取出部门，区域和公司信息
			SELECT @sdorgid1=isnull(sdorgid,''),@AreaID=isnull(areaid,''),@companyID=isnull(plantid,'') FROM oStorage o WITH(NOLOCK) WHERE o.stCode=@stcode
			IF @sdorgid!='' AND @sdorgid!=@SdorgID1 SELECT @State='查询仓库与串号仓库不一致'
			SELECT @sdorgid=@SdorgID1
			--再取出商品信息
			SELECT @Matgroup=isnull(matgroup,''),@Mattype=isnull(mattype,'') FROM iMatGeneral ig WITH(NOLOCK) WHERE ig.MatCode=@Matcode
		END
	INSERT INTO @table  
	SELECT a.doccode,a.PackageName,a.doctype,a.begindate,a.enddate,a.companyid,a.companyname,a.areaid,a.areaName,a.SdOrgID,a.SdorgName,
	a.actived,a.old,a.OnlyReservedCustomer, a.HdMemo,@State
	FROM policy_h a  WITH(NOLOCK) inner join policy_d pd  WITH(NOLOCK) ON a.DocCode=pd.DocCode
	WHERE formid=9110  
	AND (@PackageID='' or a.DocCode=@PackageID)
	AND (@PackageName='' or a.PackageName LIKE '%'+@PackageName+'%')
	AND (@PackageType='' OR a.DocType=@PackageType)
	AND (@begindate='' OR a.begindate<=@begindate)
	AND (@enddate='' OR a.enddate>=@enddate)
	AND (@Valid='' OR ISNULL(a.actived,0)=CASE @Valid WHEN '是' then 1 else 0 END)
	AND (@Old='' OR ISNULL(a.old,0)=CASE @Old WHEN '是' then 1 else 0 END)
	AND (@Reserved='' OR ISNULL(a.OnlyReservedCustomer,0)=CASE @Reserved WHEN '是' then 1 else 0 END)
	--匹配公司
	AND (@companyID=''  OR ISNULL(a.companyid,'')='' 
			--直接匹配公司
			OR (ISNULL(a.companyid,'')!='' AND @companyID!='' AND ISNULL(a.sdorgid,'')=''
				AND  exists(select 1 from commondb.dbo.split(ISNULL(a.companyid,''),',') WHERE list=@companyID)
			)
			--部门也是与公司相关，所以再尝试从部门列表中取出公司来匹配
			OR (isnull(a.sdorgid,'')!='' AND @companyID!='' 
				and EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.sdorgid,''),',') x,oPlantSDOrg os  WITH(NOLOCK) WHERE x.list=os.SDOrgID AND os.PlantID=@companyID)
			)
	)
	--匹配区域
	AND (@AreaID=''
			--直接匹配区域，并可按区域级别查询
			OR (ISNULL(a.areaid,'')!='' AND @AreaID!='' AND ISNULL(a.sdorgid,'')='' 
				AND (
						EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.areaid,''),',') x,gArea g  WITH(NOLOCK) WHERE g.areaid=@AreaID AND g.[PATH] LIKE '/%'+x.list+'/%')
						OR EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.areaid,''),',') x,gArea g  WITH(NOLOCK) WHERE g.areaid=x.list AND g.[PATH] LIKE '/%'+@AreaID+'/%')
						)
			)
			--再尝试从部门资料中取出区域,不再用部门所在的区域进行区域级联查询
			OR (ISNULL(a.sdorgid,'')!='' AND @AreaID!='' 
				AND (
						EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.sdorgid,''),',') x 
								inner join oSDOrg o WITH(NOLOCK) on o.path like '%/'+x.list+'/%' 
								inner join gArea g WITH(NOLOCK) ON  g.areaid=o.AreaID
								where g.path LIKE '%/'+@AreaID+'/%')
						OR EXISTS(SELECT 1 FROM commondb.dbo.[Split](isnull(a.sdorgid,''),',') x inner join oSDOrg o WITH(NOLOCK)   on o.path LIKE '%/'+x.list+'/%' 
								where o.areaid=@AreaID)
				)
			)
	)
	--匹配门店
	AND(@sdorgid='' OR ISNULL(a.sdorgid,'')='' 
			--匹配门店，并按层级匹配
			OR(ISNULL(a.sdorgid,'')!='' AND @sdorgid!='' 
				AND EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.sdorgid,''),',') x,oSDOrg o  WITH(NOLOCK) WHERE o.SDOrgID=@sdorgid AND o.path LIKE '%/'+x.list+'/%')
			)
	)
	--匹配大类
	AND(@Matgroup='' OR ISNULL(pd.matgroup,'')=''
			--按层级匹配大类
			OR (ISNULL(pd.matgroup,'')!='' AND @Matgroup!='' 
				AND EXISTS(SELECT 1 FROM iMatGroup ig  WITH(NOLOCK) WHERE ig.matgroup=@Matgroup AND ig.[PATH] LIKE '%/'+pd.matgroup+'/%')
			)
			--有商品编码的话,再匹配商品编码的大类
			OR (ISNULL(pd.MatCode,'')!='' AND @Matgroup!='' AND ISNULL(pd.MatCode,'')!='' 
				AND EXISTS(SELECT 1 FROM iMatGeneral ig  WITH(NOLOCK) WHERE pd.MatCode=ig.MatCode AND ig.MatGroup=@Matgroup)
			)
	)
	--匹配型号
	AND(@Mattype='' OR ISNULL(pd.mattype,'')=''
		--直接匹配型号
		OR (ISNULL(pd.mattype,'')!='' AND @Mattype!='' AND pd.mattype like '%'+@Mattype+'%')
		--若未设置型号，而设置了商品编码，则匹配商品编码的大类
		OR (ISNULL(pd.mattype,'')='' AND @Mattype!='' AND ISNULL(pd.MatCode,'')!='' 
			AND EXISTS(SELECT 1 FROM iMatGeneral ig  WITH(NOLOCK) WHERE pd.MatCode=ig.MatCode AND ig.MatType like '%'+@Mattype+'%')
		)
		--若未设置型号，也未设置商品编码，则匹配商品大类下的型号
		OR(ISNULL(pd.mattype,'')='' AND @Mattype!='' AND ISNULL(pd.MatCode,'')='' AND ISNULL(pd.matgroup,'')!='' 
			AND EXISTS(SELECT 1 FROM MatType mt  WITH(NOLOCK) inner join iMatGroup ig WITH(NOLOCK) ON mt.matgroup=ig.matgroup 
							WHERE ig.path LIKE '%/'+ig.matgroup+'/%' AND mt.MatTypeName LIKE '%'+ @Mattype +'%'
			)
		)
	)
	--匹配商品编码
	AND(@Matcode='' OR ISNULL(pd.MatCode,'')='' 
		--直接匹配商品编码
		OR (ISNULL(pd.MatCode,'')!='' AND @Matcode!='' AND pd.MatCode=@Matcode)
		--若商品编码为1.08,且没有设置型号和大类
		OR(ISNULL(pd.MatCode,'')='1.08' AND ISNULL(pd.matgroup,'')='' AND ISNULL(pd.mattype,'')='')
 
		--若政策中无商品编码,无型号，但有大类，则将录入的商品编码与大类下（含层级）的商品编码匹配
		OR (ISNULL(pd.MatCode,'1.08')='1.08' AND @Matcode!='' AND ISNULL(pd.matgroup,'')!=''  AND ISNULL(pd.mattype,'')=''
			AND EXISTS(SELECT 1 FROM iMatGeneral ig  WITH(NOLOCK),iMatGroup ig2  WITH(NOLOCK)
								WHERE ig.MatCode=@Matcode AND ig.MatGroup=ig2.matgroup
								AND ig2.[PATH] LIKE '%/'+ISNULL(pd.matgroup,'')+'/%')
		)
		--若政策中无商品编码，但有大类，而且有型号，则按型号匹配
		OR(ISNULL(pd.MatCode,'1.08')='1.08' AND @Matcode!='' AND ISNULL(pd.matgroup,'')!='' AND ISNULL(pd.mattype,'')!=''
			AND EXISTS(SELECT 1 FROM iMatGeneral ig WITH(NOLOCK) WHERE ig.MatType=pd.mattype AND ig.MatCode=@Matcode)
		)
	)
	GROUP BY a.doccode,a.PackageName,a.doctype,a.begindate,a.enddate,a.companyid,a.companyname,a.areaid,a.areaName,a.SdOrgID,a.SdorgName,
	a.actived,a.old,a.OnlyReservedCustomer, a.HdMemo
  RETURN   
 END
