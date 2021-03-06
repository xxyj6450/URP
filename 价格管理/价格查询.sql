SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
/*  
函数名称:[uf_salesSDOrgpricecalcu3]  
功能描述:门店价格查询  
参数:见声名  
返回值:见声名  
编写:  
创建时间:  
备注:采用递归的方式逐级取出门店价格.  
-------------------------------------------------------  
修改:三断笛  
时间:2012-01-13  
备注:修改移动加权成本,采购价,最新采购价的取值方式.这几项价格不随递归而改变,而取决于传入门店所在的公司.  
对于串号,以串号所以部门及串号的编码为准,会忽略传入参数中的门店和商品编码  
  
*/  
--select *,saleprice as price,saleprice as discountprice,totalmoney as netprice from UF_SALESSDORGPRICECALCU3('1.20.001.1.1.1','1.1.769.07.05','81299')   
ALTER FUNCTION [uf_salesSDOrgpricecalcu3]  
(  
 @matcode     matcode,  
 @sdorgid     VARCHAR(50),  
 @seriescode  VARCHAR(20)  
)  
RETURNS @table TABLE(saleprice MONEY,saleprice1 MONEY,selfprice MONEY,selfprice1   
         MONEY,end4 MONEY,totalmoney MONEY,CostPrice MONEY,Purprice MONEY,LastPurprice MONEY,ScorePrice money,ID INT,  
         LastModifyName VARCHAR(20),LastModifyDate DATETIME,BeginDate DATETIME,EndDate DATETIME,  
        sdorgid VARCHAR(200))  
AS  
   
BEGIN  
 --单价，优惠价，低价，调拨价，经营成本价，金额  
 --     price;salesprice1;selfprice;selfprice1;end4;totalmoney           
 DECLARE @sdorgid1 VARCHAR(50),@Companyid VARCHAR(20)  
 DECLARE @Purprice MONEY,@stCode VARCHAR(50),@CostPrice MONEY,@LastPurprice MONEY  
 --去年参数两边的空白字符,本函数非常重要,不使用正则表达式.  
 SELECT @matcode=LTRIM(RTRIM(@matcode)),@sdorgid=LTRIM(RTRIM(@sdorgid)),@seriescode=LTRIM(RTRIM(@seriescode))  
 SELECT @matcode=REPLACE(@matcode,CHAR(10),''),@sdorgid=REPLACE(@sdorgid,CHAR(10),''),@seriescode=REPLACE(@seriescode,CHAR(10),'')  
 SELECT @matcode=REPLACE(@matcode,CHAR(13),''),@sdorgid=REPLACE(@sdorgid,CHAR(13),''),@seriescode=REPLACE(@seriescode,CHAR(13),'')  
 --如串号不为空，取卡串号价格管理表                
  IF isnull(@seriescode,'')<>''  
 BEGIN  
  --取出串号的信息,注意,此处若查询到串号,会覆盖参数中的商品编码  
  SELECT @matcode=matcode,@Purprice=purprice,@stCode=stcode  
    FROM iseries WITH(NOLOCK) WHERE SeriesCode=@seriescode  
    --如果该串号不存在,则不取串号价格,改从商品编码取价格  
    IF @@ROWCOUNT<>0    
   begin  
     --取出公司信息  
     SELECT @Companyid=plantid,@sdorgid=os.sdorgid  
    FROM oStorage os  WITH(NOLOCK) WHERE os.stCode=@stCode  
     /*  
     SELECT * FROM iSeries is1 WHERE is1.SeriesCode='012564867989497'  
     SELECT os.PlantID,sdorgid, * FROM oStorage os WHERE os.stCode='101.31.769'  
     SELECT * FROM iMatLedger iml  
     WHERE iml.MatCode='9060301'  
     AND iml.PlantID='101'  
     SELECT *  
     FROM   dbo.uf_salesSDOrgpricecalcu3('9060301','101.3.1', '012564867989497')   
     */  
     --取出移动加权平均价  
   SELECT @CostPrice=map,@LastPurprice=iml.crprice  
     FROM iMatLedger iml  WITH(NOLOCK) WHERE iml.PlantID=@Companyid AND iml.MatCode=@matcode  
   --取出串号价格  
   INSERT INTO @table( saleprice, selfprice, selfprice1, end4,CostPrice,ScorePrice,Purprice,LastPurprice,LastModifyName,LastModifyDate,BeginDate,EndDate,sdorgid)  
   SELECT ISNULL(salesprice,0),ISNULL(selfprice,0),ISNULL(selfprice1,0),ISNULL(end4,0),ISNULL(@CostPrice,0),  
   isnull(ScorePrice,0),ISNULL(@Purprice,isnull(@LastPurprice,0)),isnull(@LastPurprice,0),  
   a.lastmodifyname,a.lastmodifydate,a.Begindate,a.EndDate,a.seriescode  
   FROM   iSeriesPriceCalcu a   WITH(NOLOCK)  
   WHERE  seriescode = @seriescode  
   AND (a.begindate IS NULL OR a.begindate<=convert(varchar(10),GETDATE(),120))  
   AND (a.enddate IS NULL OR a.enddate>=convert(varchar(10),GETDATE(),120))  
   --并且不能所有的价格均为空  
   AND NOT(a.salesprice IS NULL AND a.selfprice1 IS NULL AND a.selfprice IS NULL AND a.selfprice1 IS NULL AND a.end4 IS NULL AND a.ScorePrice IS NULL)   
   --如果有数据的话就直接退出,不再进一步查询了,否则程序继续往下执行,将以商品编码进行判断  
   IF @@ROWCOUNT>0   RETURN  
  end  
   
 END  
 --取出公司  
 IF ISNULL(@Companyid,'')='' SELECT @Companyid=plantid FROM oPlantSDOrg ops with(nolock) WHERE ops.SDOrgID=@sdorgid  
 --取出成本与最新采购价信息  
 SELECT @CostPrice=map,@LastPurprice=iml.crprice  
   FROM iMatLedger iml with(nolock) WHERE iml.PlantID=@Companyid AND iml.MatCode=@matcode  
 ;WITH cte_sdorg(sdorgid,sdorgname,areaid,rowid,parentrowid,LEVEL)AS(--门店树          
  SELECT a.sdorgid,sdorgname,areaid,rowid,parentrowid,0   
  FROM   osdorg a    with(nolock)
  WHERE  a.SDOrgID = @sdorgid   
    
  UNION ALL          
  SELECT a.sdorgid,a.sdorgname,a.areaid,a.rowid,a.parentrowid,b.level + 1  
  FROM   cte_sdorg b  
         JOIN osdorg a WITH(NOLOCK) ON  b.parentrowid = a.rowid  
 )   
    
 --SELECT * FROM cte_sdorg  
 --取门店价格树中最低级别门店的价格 门店树已经是按级别从低到高排序，故只需取第一个能取到价格的门店价格即可（top 1)          
 INSERT INTO @table( saleprice,saleprice1, selfprice, selfprice1, end4,totalmoney,CostPrice,Purprice,ScorePrice, LastPurprice,  
 ID,LastModifyName,LastModifyDate,BeginDate,EndDate,sdorgid)  
 SELECT TOP 1  salesprice,saleprice1, selfprice, selfprice1 , end4  , salesprice  , @CostPrice  , isnull(b.crprice, @lastpurprice ),isnull(ScorePrice,0),  
  @lastpurprice ,b.id,b.lastmodifyname,b.lastmodifydate,b.beginday,b.endday,a.sdorgid  
 FROM   cte_sdorg a  with(nolock)
        LEFT JOIN sMatSdorgPrice b with(nolock)  ON  a.sdorgid = b.SDOrgID  
 WHERE  b.matcode = @matcode  
        AND(b.beginday IS NULL OR b.beginday<=GETDATE())
        AND (b.endday IS NULL OR b.endday>=convert(varchar(10),GETDATE(),120))  
         --并且不能所有的价格均为空 2012-04-08 三断笛 防止价格管理新增价格，但未确认。  
   AND NOT(b.salesprice IS NULL AND b.saleprice1 IS NULL AND b.selfprice IS NULL AND b.selfprice1 IS NULL AND b.end4 IS NULL AND b.ScorePrice IS NULL)   
                                                      --如果未取到价格，则再尝试取门店价格根节点的价格设置           
 if @@ROWCOUNT=0  
 BEGIN  
     SELECT @sdorgid = propertyvalue  
     FROM   _sysNumberAllocationCfgValues snacv  
     WHERE  snacv.PropertyName = '价格管理根结点门店编号'  
        
     INSERT INTO @table( saleprice,saleprice1, selfprice, selfprice1, end4,totalmoney,CostPrice,Purprice, LastPurprice,ScorePrice,ID,LastModifyName,LastModifyDate,BeginDate,EndDate,sdorgid)  
     SELECT  salesprice ,saleprice1, selfprice,  selfprice1, end4, salesprice,  @costprice,ISNULL( b.crprice,@LastPurprice),  
     @LastPurprice,isnull(ScorePrice,0),b.ID,b.lastmodifyname,b.lastmodifydate,b.beginday,b.endday,@sdorgid  
     FROM   sMatSDOrgPrice b  with(nolock)
     WHERE  b.SDOrgID = @sdorgid  
     --2012-06-22 对价格管理根结点也启用有效期限制 三断笛  
     AND(b.beginday IS NULL OR b.beginday<=GETDATE())
     AND (b.endday IS NULL OR b.endday>=convert(varchar(10),GETDATE(),120))  
     AND b.matcode = @matcode  
     --并且不能所有的价格均为空 2012-04-08 三断笛 防止价格管理新增价格，但未确认。  
  AND NOT(b.salesprice IS NULL AND b.saleprice1 IS NULL AND b.selfprice IS NULL AND b.selfprice1 IS NULL AND b.end4 IS NULL AND b.ScorePrice IS NULL)   
 END  
 IF NOT EXISTS(SELECT 1  
               FROM   @table  
    )  
     INSERT INTO @table( saleprice,saleprice1, selfprice, selfprice1, end4,totalmoney,CostPrice,Purprice, LastPurprice,ScorePrice,ID,LastModifyName,LastModifyDate,BeginDate,EndDate)  
     SELECT $0,($ -9999),$0,$0,$0,$0,@CostPrice,@Purprice,@LastPurprice,0,0,0,null,NULL,NULL  
     /*FROM   imatgeneral l,oSDOrg g  
     WHERE  l.deduct = 1  
            AND l.matcode = @matcode  
            AND LEFT(l.matcode,1) <> '1'  
            AND g.sdorgid = (SELECT sdorgid  
                             FROM   vStorage  
                             WHERE  stcode = @sdorgid  
                )  
            AND g.mdf = 1  
 */  
 RETURN  
END