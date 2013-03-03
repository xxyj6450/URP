--QueryinventorySeriesCode                                            
-- select * from QueryinventorySeriesCode('2011-02-01','2011-07-01','','','1.4.769.01.05','','','','','','','','','','','',''  )                     
-- select * from dbo.QueryinventorySeriesCode('2005-11-08','2011-05-01','','','','','1.4.769.01.05','','在库','','','','','','','','')                                         
--beginday;endday;vndcode;matcode;mattype;sdorgid;stcode;seriescode;state;returncode;MATGROUP;matlife;issend;station1;preallocation;issale;salemun                               
--select mattype,* from iseries                                            
alter FUNCTION [dbo].[Query_matcodeSeriesCode]          
(          
 @beginday       DATETIME,          
 @endday         DATETIME,          
 @vndcode        VARCHAR(500),          
 @matcode        VARCHAR(3000),          
 @MatType        VARCHAR(200),          
 @sdorgid        VARCHAR(200),          
 @stcode         VARCHAR(100),          
 @seriescode     VARCHAR(500),          
 @state          VARCHAR(100),          
 @returncode     VARCHAR(20),          
 @MATGROUP       VARCHAR(50),          
 @matlife        VARCHAR(50),          
 @issend         VARCHAR(10),          
 @station        VARCHAR(50),          
 @preallocation  VARCHAR(20),          
 @issale         VARCHAR(30),          
 @salemun        VARCHAR(50),          
 @companyid      VARCHAR(50)          
)          
RETURNS @table TABLE(SeriesCode VARCHAR(50), ---串号                                            
         matcode VARCHAR(50), ---物料号                                            
         matname VARCHAR(100), ---物料名                                            
         mattype VARCHAR(50), ---手机型号                                            
         STATE VARCHAR(10), ----状态                                            
         stcode VARCHAR(50), ---仓库                                            
         stname VARCHAR(150),vndcode VARCHAR(50), ---供应商号                                            
         vndname VARCHAR(200), --供应商名                                            
         purprice MONEY, --采购价                                            
         purGRdate DATETIME, --采购收货时间                                            
         purGRDocCode VARCHAR(20), ---采购收货单号                                            
         purReturnDate DATETIME, --退货日期                                            
         purReturnPrice DATETIME, ---退货时间                                            
         purReturnDocCode VARCHAR(20), ---退货单单号                                            
         purSPmoney MONEY, --供应商累计保价金额                                            
         purAchivePrice MONEY, ---                                            
         purClearPrice MONEY, --结算金额                                            
         payamount MONEY, --付款额                                            
         returncode VARCHAR(50), --返厂点          
                                 --      createdate datetime,---产生串号日期          
                                 --      createdoccode varchar(20),--产生串号单号,--产生串号单号          
                                 --  returncode varchar(20),          
                                 --  returnname varchar(40),                                            
         returndoccode VARCHAR(20),--  returndate datetime,                                            
         salesuom VARCHAR(50),--  packagecode varchar(20),          
                              --  costprice money,                                            
         matgroup VARCHAR(20),YXDATE DATETIME,gift VARCHAR(50),fk INT,matlife VARCHAR(50), --商品状态                                            
         digit INT,matgroupname VARCHAR(50),stcode1 VARCHAR(50), --店面调售后                                            
         stname1 VARCHAR(120),shdjdate DATETIME, --店面调售后时间                                             
         shdjHDMemo VARCHAR(100), --店面调售后故障说明                                       
         station VARCHAR(50), --岗位                              
         issend VARCHAR(10),shdjusertxt VARCHAR(100), --售后附加信息                                         
         preallocation BIT, --预开户                                           
         seriesnumber VARCHAR(50),salesdate DATETIME,salemun VARCHAR(50),          
      areaid VARCHAR(50),areaname VARCHAR(500),PackageID           
         VARCHAR(50),Formgroup VARCHAR(20),isContractSale BIT,           salesprice MONEY,areacode VARCHAR(50),          
         ExtendWarrantyDate DATETIME,          
         ExtendWarrantyDoc VARCHAR(20),    
   seriestype varchar(50),  
  ESSID varchar(50)          
        )          
AS           
  ---增加是否合约机字段，yx          
  --增加销售单价              
              
                                
BEGIN          
 -- if @stcode=''          
 -- return                                            
 DECLARE @bpreallocation BIT                                
 SELECT @bpreallocation = CASE           
                               WHEN @preallocation = '预开户' THEN 1          
                               ELSE 0          
                          END          
           
 IF @stcode = '*'          
     SELECT @stcode = ''           
 ----         update iseries set issend = 0 where seriescode in ('358852010023382','356677010433402')                                                 
if @state='' or @state like '%已售%'
	BEGIN
				INSERT INTO @table( SeriesCode, matcode, matname, mattype, stcode, stname,           
				STATE, vndcode, purprice, purGRdate, purGRDocCode, purReturnDate,           
				purReturnPrice, purReturnDocCode, purSPmoney, purAchivePrice,           
				purClearPrice, payamount, vndname, matgroup, matgroupname, salesuom,           
				returndoccode, --returncode,returnname ,returndoccode,returndate,createdate ,createdoccode,                                            
				YXDATE, gift, fk, matlife, digit, stcode1, shdjdate, shdjHDMemo,           
				station, issend, shdjusertxt, returncode, seriesnumber, salesdate,           
				salemun, areaid, areaname, PackageID, formgroup, isContractSale,           
				salesprice, areacode,ExtendWarrantyDate,ExtendWarrantyDoc,seriestype,ESSID)          
			 SELECT SeriesCode,a.matcode,l.matname,l.mattype,a.stcode,e.name40,STATE,a.vndcode,          
					a.purprice,purGRdate,purGRDocCode,purReturnDate,purReturnPrice,          
					purReturnDocCode,purSPmoney,purAchivePrice,purClearPrice,payamount,b.vndname,          
					p.matgroup,p.matgroupname,l.salesuom,a.returndoccode,--returncode,returnname ,returndoccode,returndate ,createdate ,createdoccode ,                                            
					YXDATE,gift,fk,l.matlife,1,stcode1,shdjdate,shdjHDMemo,station,(CASE           
																						 ISNULL(issend, 0)          
																						 WHEN   0 THEN   '未送厂'          
																						 WHEN   1 THEN   '已送厂'          
																						 WHEN  2 THEN   '已返回'          
																					END          
					),shdjusertxt,a.returncode,a.seriesnumber,salesdate,(CASE a.salemun WHEN -1 THEN '售后机' ELSE '非售后机' END) AS           
					salemun,a.areaid,a.areaname,a.PackageID,a.formgroup,a.isContractSale,          
					a.salesprice,a.areacode,a.ExtendWarrantyDate,a.ExtendWarrantyDoc,a.seriestype,a.ESSID          
			 FROM   --vseries a            select *,areaname from oStorage                                
					iseriesSaled a with(nolock) 
					LEFT JOIN imatgeneral l  with(nolock) ON  a.matcode = l.matcode          
					LEFT JOIN pvndgeneral b  with(nolock) ON  a.vndcode = b.vndcode          
					LEFT JOIN imatgroup p  with(nolock) ON  l.matgroup = p.matgroup          
					LEFT JOIN oStorage e  with(nolock)  ON  a.stcode = e.stcode          
			 WHERE  --(purgrdate between @beginday and @endday or purgrdate is null) and                                   
				(@state = '' or a.state='已售'
				)          
				AND (@stcode = '' OR @stcode = a.stcode)          
				AND (@matgroup = '' OR l.matgroup LIKE @matgroup + '%') --exists(select * from imatgroup aa,getinstr(@matgroup) bb,imatgroup cc          
							 --where aa.matgroup = bb.list and left(cc.treecontrol,len(aa.treecontrol)) = aa.treecontrol and cc.matgroup = l.matgroup))          
				AND (@mattype = '' OR l.mattype LIKE @mattype + '%')--in (select * from getinstr(@mattype)))          
																	--and   (a.state='应收' or a.state='在库' or a.state='在途' or a.state='返厂' or a.state='借出' or a.state='售后' or a.state='已售' or a.state is null)     --此句改成In                 
				AND (@vndcode = '' OR a.vndcode = @vndcode)          
				AND (@matcode = '' OR EXISTS(SELECT 1          
							  FROM   getinstr(@matcode)          
							  WHERE  list = a.matcode))          
				AND (a.seriescode LIKE @SeriesCode + '%' OR @seriescode = '')          
				AND (@returncode = '' OR a.returncode = @returncode)          
				AND (@matlife = '' OR l.matlife = @matlife)          
				AND (@station = '' OR a.station = @station)          
				AND (@preallocation = ''          
						OR ISNULL(a.preAllocation,0) = @bpreallocation          
					)          
				AND (@salemun = ''          
						OR (CASE a.salemun WHEN -1 THEN '是' ELSE '否' END) = @salemun          
					)          
				AND (@issale = ''          
						OR (CASE salemun          
								 WHEN 1 THEN '加盟商已售'          
								 WHEN 0 THEN '加盟商库存'          
							END          
						   ) = @issale          
					)          
				--AND e.insystem = 1          
				AND (@companyid = '' OR e.plantid = @companyid)          
				AND (@issend = '' OR a.issend = @issend) --2011-08-12 将送厂参数调整至查询中 删除后面的Delete操作 三断笛          
														 -- update @table set vndname=b.vndname from @table a,pvndgeneral b where a.vndcode=b.vndcode          
														 --插入配置  在主查询中已经更新了SalesUOM字段,无需在这里额外更新 2011-08-12 三断笛       
	END
	if @state='' or @state<>'已售'
		BEGIN
				INSERT INTO @table( SeriesCode, matcode, matname, mattype, stcode, stname,           
				STATE, vndcode, purprice, purGRdate, purGRDocCode, purReturnDate,           
				purReturnPrice, purReturnDocCode, purSPmoney, purAchivePrice,           
				purClearPrice, payamount, vndname, matgroup, matgroupname, salesuom,           
				returndoccode, --returncode,returnname ,returndoccode,returndate,createdate ,createdoccode,                                            
				YXDATE, gift, fk, matlife, digit, stcode1, shdjdate, shdjHDMemo,           
				station, issend, shdjusertxt, returncode, seriesnumber, salesdate,           
				salemun, areaid, areaname, PackageID, formgroup, isContractSale,           
				salesprice, areacode,ExtendWarrantyDate,ExtendWarrantyDoc,seriestype,ESSID)          
				 SELECT SeriesCode,a.matcode,l.matname,l.mattype,a.stcode,e.name40,STATE,a.vndcode,          
						a.purprice,purGRdate,purGRDocCode,purReturnDate,purReturnPrice,          
						purReturnDocCode,purSPmoney,purAchivePrice,purClearPrice,payamount,b.vndname,          
						p.matgroup,p.matgroupname,l.salesuom,a.returndoccode,--returncode,returnname ,returndoccode,returndate ,createdate ,createdoccode ,                                            
						YXDATE,gift,fk,l.matlife,1,stcode1,shdjdate,shdjHDMemo,station,(CASE           
																							 ISNULL(issend, 0)          
																							 WHEN   0 THEN   '未送厂'          
																							 WHEN   1 THEN   '已送厂'          
																							 WHEN  2 THEN   '已返回'          
																						END          
						),shdjusertxt,a.returncode,a.seriesnumber,salesdate,(CASE a.salemun WHEN -1 THEN '售后机' ELSE '非售后机' END) AS           
						salemun,a.areaid,a.areaname,a.PackageID,a.formgroup,a.isContractSale,          
						a.salesprice,a.areacode,a.ExtendWarrantyDate,a.ExtendWarrantyDoc,a.seriestype,a.ESSID          
				 FROM   --vseries a            select *,areaname from oStorage                                
						iseries a          
						LEFT JOIN imatgeneral l ON  a.matcode = l.matcode          
						LEFT JOIN pvndgeneral b ON  a.vndcode = b.vndcode          
						LEFT JOIN imatgroup p ON  l.matgroup = p.matgroup          
						LEFT JOIN oStorage e ON  a.stcode = e.stcode          
				 WHERE  --(purgrdate between @beginday and @endday or purgrdate is null) and                                   
						(@state = ''          
							OR EXISTS(SELECT 1          
									  FROM   getinstr(@state)          
									  WHERE  list = a.state          
							   )          
						)          
						AND (@stcode = '' OR @stcode = a.stcode)          
						AND (@matgroup = '' OR l.matgroup LIKE @matgroup + '%') --exists(select * from imatgroup aa,getinstr(@matgroup) bb,imatgroup cc          
									 --where aa.matgroup = bb.list and left(cc.treecontrol,len(aa.treecontrol)) = aa.treecontrol and cc.matgroup = l.matgroup))          
						AND (@mattype = '' OR l.mattype LIKE @mattype + '%')--in (select * from getinstr(@mattype)))          
																			--and   (a.state='应收' or a.state='在库' or a.state='在途' or a.state='返厂' or a.state='借出' or a.state='售后' or a.state='已售' or a.state is null)     --此句改成In          
						AND (a.state IN ('应收', '在库', '在途', '返厂', '借出', '售后', '已售','内销')          
							)          
						AND (@vndcode = '' OR a.vndcode = @vndcode)          
						AND (@matcode = '' OR EXISTS(SELECT 1          
									  FROM   getinstr(@matcode)          
									  WHERE  list = a.matcode))          
						AND (a.seriescode LIKE @SeriesCode + '%' OR @seriescode = '')          
						AND (@returncode = '' OR a.returncode = @returncode)          
						AND (@matlife = '' OR l.matlife = @matlife)          
						AND (@station = '' OR a.station = @station)          
						AND (@preallocation = ''          
								OR ISNULL(a.preAllocation,0) = @bpreallocation          
							)          
						AND (@salemun = ''          
								OR (CASE a.salemun WHEN -1 THEN '是' ELSE '否' END) = @salemun          
							)          
						AND (@issale = ''          
								OR (CASE salemun          
										 WHEN 1 THEN '加盟商已售'          
										 WHEN 0 THEN '加盟商库存'          
									END          
								   ) = @issale          
							)          
						--AND e.insystem = 1          
						AND (@companyid = '' OR e.plantid = @companyid)          
						AND (@issend = '' OR a.issend = @issend) --2011-08-12 将送厂参数调整至查询中 删除后面的Delete操作 三断笛          
														 -- update @table set vndname=b.vndname from @table a,pvndgeneral b where a.vndcode=b.vndcode          
														 --插入配置  在主查询中已经更新了SalesUOM字段,无需在这里额外更新 2011-08-12 三断笛            
		END
    
 /*update @table set salesuom=b.salesuom                                            
 from @table a,imatgeneral b where a.matcode=b.matcode                                            
 -- update @table set matgroupname = b.matgroupname from @table a ,imatgroup b where a.matgroup = b.matgroup   */           
 --处理售后调出店面                                            
 UPDATE @table          
 SET    stname1 = name40          
 FROM   @table e,          
        vstorage b          
 WHERE  e.stcode1 = b.stcode          
        AND ISNULL(e.stcode1,'') <> ''           
 /*  2011-08-12 注释此部分 将这段代码放到查询语句中 三断笛                
 if isnull(@issend,'') = '未送厂'                                            
 begin                                             
 delete from @table where issend <>'未送厂'                                             
 end                                            
 if isnull(@issend,'') = '已送厂'                                            
 begin                                             
 delete from @table where issend <>'已送厂'                                             
 end                                            
 if isnull(@issend,'') = '已返回'                                            
 begin                                             
 delete from @table where issend <>'已返回'                                             
 end                                            
 */           
 --select matgroup,* from vseries where matgroup is null          
 --select * from imatgeneral where matcode = 'S0201610002'                                            
           
 RETURN          
END