-- exec PostDocSeriesDoc_ZD 'CS20120911000021',1520                    
-- 整单确认串号                                                          
                                                      
ALTER PROCEDURE [PostDocSeriesDoc_ZD]                                  
 @doccode VARCHAR(20),                                  
 @formid INT                                  
AS                                  
 SET NOCOUNT ON                                   
                                   
 INSERT INTO iseries( matcode, seriescode, createdate, createdoccode)                                  
 SELECT v.matcode,v.seriescode,GETDATE(),@doccode                                  
 FROM   VMatseriesdoc v                                  
 WHERE  v.refcode = @doccode                                  
        AND v.seriescode NOT IN (SELECT seriescode                                  
                                 FROM   iseries)                                  
                                 
 INSERT INTO iseries( matcode, seriescode, createdate, createdoccode)                                  
 SELECT v.matcode,v.seriescode,GETDATE(),@doccode                                  
 FROM   VMatseriescomm v                                  
 WHERE  v.refcode = @doccode                                  
        AND v.seriescode NOT IN (SELECT seriescode                                  
                                 FROM   iseries)                                  
                                                        
                                   
 IF @formid IN (1509) --采购入库                                  
 BEGIN                                  
     IF EXISTS (SELECT 1 FROM   VMatseriesdoc v WHERE  v.refcode = @doccode                                  
                       AND v.seriescode IN (SELECT seriescode FROM   iseries WHERE  STATE IN ('借出', '在途', '在库', '返厂','内销')))                              
     BEGIN                                  
         RAISERROR('请检查是否有串号是借出、在途、在库、返厂，内销不能重复入库!',16,1)                                   
         RETURN                                  
     END                                  
                                       
     UPDATE iseries                                  
     SET    stcode = v.stcode,                                  
            vndcode = v.vndcode,                                  
            purprice = v.price,                                  
            purGRDocCode = @doccode,                                  
            purgrdate = v.docdate,                                  
            STATE = '在库',                                  
            matcode = v.matcode,                                  
            yxdate = v.yxdate,                                  
            gift = v.gift,                                  
            iseries.areaid = v.areaid,                            
            iseries.AreaCode = v.areacode,          
   seriestype=v.seriestype,        
   ESSID=v.ESSID,  
   UNcomID=v.UNcomID  
     FROM   VMatseriesdoc v,                                  
            iseries i                                  
     WHERE  v.seriescode = i.seriescode                                  
            AND v.refcode = @doccode                        
 END                    
-------------------------------------------公司内部采购-----------------------------------------                      
 IF @formid IN (4061) --公司内入库                                  
 BEGIN                                  
     IF EXISTS (SELECT 1 FROM   VMatseriesdoc v WHERE  v.refcode = @doccode                                  
                       AND v.seriescode IN (SELECT seriescode FROM   iseries WHERE  STATE not IN ('内销')))                                  
     BEGIN                                  
         RAISERROR('请检查是否有串号不是内销串号，不能入库，请联系管理员!',16,1)                                   
         RETURN                                  
     END                                  
                    
     UPDATE iseries                                  
     SET    stcode = v.stcode,                   
            STATE = '在库',                                  
            createdate = v.docdate                          
     FROM   VMatseriesdoc v,iseries i                                  
     WHERE  v.seriescode = i.seriescode AND v.refcode = @doccode  and v.matcode=i.matcode                      
 END                   
 IF @formid IN (4062) --内部采购退货                                  
 BEGIN                        
     IF EXISTS (SELECT 1 FROM   VMatseriesdoc v LEFT JOIN iseries s ON v.seriescode=s.SeriesCode WHERE  v.refcode = @doccode                                  
        AND s.STATE not IN ('在库'))                                 
     BEGIN                              
         RAISERROR('请检查是否有串号不在库，不能重复采购退货!',16,1)                                   
         RETURN                                  
     END                   
     UPDATE iseries                                 
     SET    stcode = stcode2,                                  
            STATE = '内销'                    
     FROM   VMatseriesdoc v,                                
            iseries i                                  
     WHERE  v.seriescode = i.seriescode  and v.matcode=i.matcode                                
            AND v.refcode = @doccode                                  
 END                   
----------------------------------------------公司内销售-----------------------------------------                  
 IF @formid IN (4031) --公司内销售                                  
 BEGIN                    
     IF EXISTS (SELECT 1 FROM   VMatseriesdoc v WHERE  v.refcode = @doccode                                  
        AND v.seriescode IN (SELECT seriescode  FROM   iseries WHERE  STATE not IN ('在库')))                                  
     BEGIN                                  
         RAISERROR('请检查是否有串号不在库，不能重复销售出库!',16,1)                                   
         RETURN                                  
     END                    
     UPDATE iseries                                  
     SET    stcode = stcode2,                                
            STATE = '内销',      
   salemun = 0                              
     FROM   VSPICKseriesdoc v,                                  
            iseries i                                  
     WHERE  v.seriescode = i.seriescode  and v.matcode=i.matcode                                
            AND v.refcode = @doccode                                  
 END                      
IF @formid IN (4032) --批发销售退货                                  
 BEGIN                    
     IF EXISTS (SELECT 1 FROM   VSPICKseriesdoc v WHERE  v.refcode = @doccode                                  
        AND v.seriescode IN (SELECT seriescode  FROM   iseries WHERE  STATE IN ('借出', '在途', '在库', '返厂' )))                                  
     BEGIN                                  
         RAISERROR('请检查是否有串号在库，不能重复入库!',16,1)                                   
         RETURN                                  
     END                                  
     UPDATE iseries                                  
     SET    stcode = v.stcode,                                  
            STATE = '在库'                  
   FROM   VSPICKseriesdoc v,                                  
            iseries i                                  
     WHERE  v.seriescode = i.seriescode and v.matcode=i.matcode                  
            AND v.refcode = @doccode                  
 END                                                         
       --select * from VMatseriesdoc where refcode='CR20111216000004'                   
-------------------------------------------------------------------代销-------------------------------                           
 IF @formid IN (4622) --                              
 BEGIN                                  
     IF EXISTS (SELECT 1 FROM   VMatseriescomm v  WHERE  v.refcode = @doccode AND v.seriescode IN (SELECT seriescode                                  
                 FROM   iseries WHERE  STATE IN ('借出', '在途', '在库', '返厂','内销'))                                  
        )                                  
     BEGIN                    
         RAISERROR('请检查是否有串号是借出、在途、在库、返厂，不能重复入库!',                                  
          16,1                                  
         )                                   
         RETURN                                  
     END                                  
                                       
     UPDATE iseries                                  
     SET    --stcode = v.stcode,                                  
            --vndcode = v.vndcode,                                  
            --purprice = v.price,                                  
            --purGRDocCode = @doccode,                                  
            --purgrdate = v.docdate,                           
            --createdate = v.docdate,                                  
            STATE = '在库'--,                                  
            --matcode = v.matcode,                                  
            --yxdate = v.yxdate,                                  
            --gift = v.gift                                  
     FROM   VMatseriescomm v,                                  
            iseries i                                  
     WHERE  v.seriescode = i.seriescode                                  
            AND v.refcode = @doccode                                  
 END                    
 IF @formid IN (4630) --                              
 BEGIN                                  
     IF EXISTS (SELECT 1 FROM   VMatseriescomm v  WHERE  v.refcode = @doccode AND v.seriescode IN (SELECT seriescode                                  
                 FROM   iseries WHERE  STATE IN ('借出', '在途', '在库', '返厂','内销'))                                  
        )                                  
     BEGIN                                  
         RAISERROR('请检查是否有串号是借出、在途、在库、返厂，不能重复入库!',                                  
          16,1                                  
         )                                   
         RETURN                                  
     END                                  
                                     
     UPDATE iseries                                  
     SET    stcode = v.stcode,                                  
            vndcode = v.vndcode,                                  
            purprice = v.price,                                  
            purGRDocCode = @doccode,                                  
            purgrdate = v.docdate,                           
            createdate = v.docdate,                                  
            STATE = '在库',--,                                  
            matcode = v.matcode,                                  
            yxdate = v.yxdate,                                  
            gift = v.gift,        
   ESSID=v.ESSID                                  
     FROM   VMatseriescomm v,                                  
            iseries i                                  
     WHERE  v.seriescode = i.seriescode                                  
            AND v.refcode =@doccode                                 
 END                   
IF @formid IN (4610) --供应商代销                                  
 BEGIN                                  
     IF EXISTS (SELECT 1 FROM   VMatseriescomm v  WHERE  v.refcode = @doccode AND v.seriescode IN (SELECT seriescode                                  
                 FROM   iseries WHERE  STATE IN ('借出', '在途', '在库', '返厂','内销'))                                  
        )                                  
     BEGIN                                  
         RAISERROR('请检查是否有串号是借出、在途、在库、返厂，不能重复入库!',                                  
          16,1                                  
         )                                   
         RETURN                                  
     END    
                                       
     UPDATE iseries                                  
     SET    stcode = v.stcode,                                  
            vndcode = v.vndcode,                                  
            purprice = v.price,                                  
            purGRDocCode = @doccode,         
            purgrdate = v.docdate,                           
            createdate = v.docdate,                                  
            STATE = '在库',                                  
            matcode = v.matcode,                                  
            yxdate = v.yxdate,                                  
            gift = v.gift                                  
     FROM   VMatseriescomm v,                                  
            iseries i                   
     WHERE  v.seriescode = i.seriescode                                  
            AND v.refcode = @doccode                                  
 END                              
 IF @formid IN (4611,4621,4631) --其他入库\供应商代销                                  
 BEGIN                                  
     IF EXISTS (SELECT 1 FROM   VMatseriescomm v  WHERE  v.refcode = @doccode                   
    AND v.seriescode IN (SELECT seriescode  FROM   iseries WHERE  STATE not IN ('在库'))                                  
        )                                  
     BEGIN                                  
         RAISERROR('请检查是否有串号是在库，非库存串号不能出库!',                                  
          16,1                                  
         )                                   
         RETURN                                  
     END                                  
      --select * from VMatseriescomm where refcode='DS20111117000001'                                 
     UPDATE iseries                                  
    SET    stcode = v.stcode2,                                  
            --vndcode = v.vndcode,                                  
            --purprice = v.price,                                  
            --purGRDocCode = @doccode,                            
            --purgrdate = v.docdate,                                  
            --createdate = v.docdate,                                  
            STATE = '出库'                              
            --matcode = v.matcode,                                  
            --yxdate = v.yxdate,                                  
            --gift = v.gift                                  
     FROM   VMatseriescomm v,                                  
            iseries i                                  
     WHERE  v.seriescode = i.seriescode                                  
  AND v.refcode = @doccode                                  
 END                                  
------------------------------------------------------------------------------------------------------------------                           
 IF @formid IN (1520) --其他入库                          
 BEGIN                                  
     IF EXISTS (SELECT 1 FROM   VMatseriesdoc v WHERE  v.refcode = @doccode                                  
        AND v.seriescode IN (SELECT seriescode  FROM   iseries WHERE  STATE IN ('借出', '在途', '在库', '返厂','内销')))                                  
     BEGIN                                  
         RAISERROR('请检查是否有串号是借出、在途、在库、返厂，内销，不能重复入库!',16,1)                                   
         RETURN                                  
     END                                  
                                       
     UPDATE iseries                                  
     SET    stcode = v.stcode,                                  
            vndcode = (case when v.doctype1='初始化' then v.vndcode1 else v.vndcode end),                                  
            purprice = v.price,                                  
            purGRDocCode = @doccode,                                  
            purgrdate = v.docdate,                                  
            createdate = v.docdate,                                  
            STATE = '在库',                                  
            matcode = v.matcode,                                  
            yxdate = v.yxdate,                                  
            gift = v.gift,                              
   isava = 0                                  
     FROM   VMatseriesdoc v,iseries i  WHERE  v.seriescode = i.seriescode AND v.refcode = @doccode            
 END                                  
                                   
 IF @formid IN (1504) --采购退货                                  
 BEGIN                                  
     UPDATE iseries                                  
     SET    stcode = '',                                  
            purreturnprice = v.price,                                  
            purreturndate = v.docdate,                                  
            purreturndoccode = v.doccode,                                  
            STATE = '出库',                                  
            matcode = v.matcode                                 
     FROM   VMatseriesdoc v,                                  
            iseries i                                  
     WHERE  v.seriescode = i.seriescode                                  
            AND v.refcode = @doccode                                  
 END                     
                                                        
           --select * from VMatseriesdoc where refcode='ICT2012010100004'    PostDocSeriesDoc_ZD                    
 IF @formid IN (1501, 4611, 1532) --其它出库、代销退货                 
 BEGIN                                  
     UPDATE iseries                                  
     SET    stcode = '',                                  
            STATE = '出库',                                  
            matcode = v.matcode                                  
     FROM   VMatseriesdoc v,                                  
            iseries i                                  
     WHERE  v.seriescode = i.seriescode                                  
            AND v.refcode = @doccode                                  
 END                                  
                                   
--------------------------------------------------------批发-------------------------------------------                                   
 IF @formid IN (2401) --批发销售出库                                  
 BEGIN                    
     IF EXISTS (SELECT 1 FROM   VMatseriesdoc v WHERE  v.refcode = @doccode                                  
        AND v.seriescode IN (SELECT seriescode  FROM   iseries WHERE  STATE not IN ('在库')))                                  
     BEGIN                                  
         RAISERROR('请检查是否有串号不在库，不能重复批发出库!',16,1)                                   
         RETURN                                  
     END                    
     UPDATE iseries                                  
     SET    --stcode = (case when v.refformid=4031 then stcode2 else '' end),                                  
            STATE = '应收',                                  
            cltcode = v.cltcode,                                  
            salesdate = v.docdate,                                  
            matcode = v.matcode,                                  
            salesdoccode = v.refcode,                                  
            salesprice = v.price,                                  
            sbcmoney = 0,                                  
            payamount = 0                                  
     FROM   VSPICKseriesdoc v,                                  
            iseries i                 
     WHERE  v.seriescode = i.seriescode                                  
            AND v.refcode = @doccode                                  
 END                   
                                  
 IF @formid IN (2418) --批发销售退货                                  
 BEGIN                    
     IF EXISTS (SELECT 1 FROM   VSPICKseriesdoc v WHERE  v.refcode = @doccode                                  
        AND v.seriescode IN (SELECT seriescode  FROM   iseries WHERE  STATE IN ('借出', '在途', '在库', '返厂','内销' )))                                  
     BEGIN                                  
         RAISERROR('请检查是否有串号在库，不能重复入库!',16,1)                                   
         RETURN                                  
     END                                  
     UPDATE iseries                                  
     SET    stcode = v.stcode,                                  
            STATE = '在库',                
            matcode = v.matcode FROM   VSPICKseriesdoc v,                                  
            iseries i                                  
     WHERE  v.seriescode = i.seriescode and v.matcode=i.matcode                  
            AND v.refcode = @doccode                  
 END                  
------------------------------------------------------------------------------------------------------------                  
/*select v.seriescode,i.seriescode,i.matcode, v.matcode,* from VSPICKseriesdoc v,                                  
            iseries i                                  
     WHERE  v.seriescode = i.seriescode and v.matcode=i.matcode                  
            AND v.refcode = 'IFH2012010700116'*/                  
---------------------------------------------------------加盟店串号处理-------------------------------------                  
 IF @formid IN (4950) --加盟商出货单                                  
 BEGIN                                  
     IF EXISTS (SELECT 1                                  
                FROM   spickorderhd s WITH(NOLOCK)                      
                       LEFT JOIN iseriesloghd d WITH(NOLOCK) ON  s.doccode = d.refcode                                  
                       LEFT JOIN iserieslogitem m WITH(NOLOCK) ON  d.doccode = m.doccode                                  
                WHERE  d.refcode = @doccode   
      AND NOT exists (SELECT 1                              
                                                FROM   iseries  x WITH(NOLOCK)                        
                                                WHERE  STATE IN ('在库')                                  
                                                       AND stcode = s.stcode
                      and m.seriescode=x.SeriesCode
      )                                  
        )                                  
     BEGIN                                  
         RAISERROR('请检查是否有串号是出库，不能重复出库!',16,1)                                   
         RETURN                                  
     END                                              
                                       
     UPDATE iseries                                  
     SET    stcode = v.instcode,                     
            STATE = '送货',                                  
            cltcode = v.cltcode2,                                  
            salesdate = v.docdate,                                  
            --matcode = v.matcode,                                  
            salesdoccode = v.refcode,                                  
            salesprice = v.price,                                  
            sbcmoney = 0,                                  
            payamount = 0,
            FHstcode = v.stcode,
            FHStname = v.stname
     FROM   VSPICKseriesdoc v,                                  
            iseries i                                  
     WHERE  v.seriescode = i.seriescode                                  
            AND v.refcode = @doccode                                  
 END                                   
            
 --select * from VSPICKseriesdoc                                                          
                                   
 IF @formid IN (4951) --加盟商退货单                                  
 BEGIN                                  
     IF EXISTS (SELECT 1                                  
                FROM   spickorderhd s                                  
                       LEFT JOIN iseriesloghd d ON  s.doccode = d.refcode                    
                       LEFT JOIN iserieslogitem m ON  d.doccode = m.doccode  
                                        
                WHERE  d.refcode = @doccode                                  
                       AND m.seriescode IN (SELECT seriescode                                  
                                            FROM   iseries                  
                       WHERE  STATE IN ('在库'))                                  
        )                                  
     BEGIN                                  
         RAISERROR('请检查是否有串号是在库，不能重复入库!',16,1)                                   
  RETURN                                  
     END                                  
                                       
     UPDATE iseries                                  
     SET    stcode = v.stcode,                                  
            STATE = '在库'--,                                  
            --matcode = v.matcode                                  
     FROM   VSPICKseriesdoc v,                                  
            iseries i                                  
     WHERE  v.seriescode = i.seriescode                                  
            AND v.refcode = @doccode                                  
 END                                   
 ----------------------------------------------调拨串号处理---------------------------------------------------                  
 IF @formid IN (1541) --快速调拨                                  
 BEGIN                          
     UPDATE iseries                                  
     SET    stcode = v.stcode2,                                  
            STATE = '在库',                                  
   matcode = v.matcode,                                  
            gift = v.gift,                                  
            createdate = v.docdate,                                  
            stcode1 = CASE                                   
                           WHEN stcode2 = 'XYZC01' THEN HDMemo1                                  
                           ELSE NULL                                  
                      END--调拨外借仓时记录外借方是谁                                  
     FROM   VMatseriesdoc v,                                  
            iseries i                                  
     WHERE  v.seriescode = i.seriescode                                  
            AND v.refcode = @doccode                                  
 END                                                          
                                  
 IF @formid IN (2424) --调拨出库       
 BEGIN                                  
     IF EXISTS (SELECT 1                                  
                FROM   VSPICKseriesdoc c                                  
                       LEFT JOIN iseries m ON  c.seriescode = m.seriescode                                  
                WHERE  c.refcode = @doccode and m.STATE<>'在库'            
                       /*AND m.seriescode NOT IN (SELECT seriescode                                  
                                                FROM   iseries                                  
                                                WHERE  STATE IN ('在库'))    */                                
    )                                  
     BEGIN                                  
         RAISERROR('请检查是否有串号不在库，不能重复出库!',16,1)                                   
         RETURN                                  
     END                                           
                                       
     UPDATE iseries                                
     SET    stcode = v.stcode2,                                  
            STATE = '在途',                                  
            matcode = v.matcode,                                  
            gift = v.gift,                                  
            salecompanyid = v.Companyid2,                                  
            fanli = 0,                                  
      isout = 1,                                  
            station = NULL                                  
     FROM   VSPICKseriesdoc v,iseries i                                  
     WHERE  v.seriescode = i.seriescode                                  
     AND v.refcode = @doccode                                   
     --------如果是公司售后调店面，更新串号salenum为正常机                                  
     --select * from vspickseriesdoc where refcode='KY20101109000001'                                          
     UPDATE i                                  
     SET    salemun = 0                                  
     FROM   vspickseriesdoc v,                                  
            iseries i                                  
     WHERE  v.seriescode = i.seriescode                                  
            AND v.refcode = @doccode                                  
            AND ISNULL(i.salemun,0) = -1                                  
            AND v.stcode IN (SELECT stcode                                  
                             FROM   vstorage                                  
                             WHERE  ISNULL([service],0) = 1)      
 /*          2012-09-11暂时取消，测试     
     UPDATE l                                  
     SET    valid = 0                                   
            --select l.valid,l.cardnumber,v.seriescode,seriesnumber,*                                  
     FROM   VSPICKseriesdoc v,                                  
            seriespool l --ON v.seriescode=l.cardnumber                                  
     WHERE  v.refcode = @doccode                                  
            AND v.seriescode = l.cardnumber*/                                  
 END                                                          
             
 IF @formid IN (1507) --调拨入库                                  
 BEGIN                                  
     IF EXISTS (SELECT 1                                  
                FROM   VMatseriesdoc c                                  
                       LEFT JOIN iseries m ON  c.seriescode = m.seriescode                                  
                WHERE  c.refcode = @doccode  and m.STATE<>'在途'                                  
                       /*AND m.seriescode IN (SELECT seriescode                                  
                                            FROM   iseries                                  
                                            WHERE  STATE NOT IN ('在途'))*/                                  
        )                                  
     BEGIN                                  
         RAISERROR('请检查是否有串号是在库，不能重复入库!',16,1)                                   
         RETURN                      
     END                                   
     --select * from VMatseriesdoc where refcode='DR20101121000046'                                    
     UPDATE iseries                                  
     SET    stcode = v.stcode,                                  
            STATE = '在库',                                  
            matcode = v.matcode,                                  
            gift = v.gift,                                  
            createdate = v.docdate                                  
     FROM   VMatseriesdoc v,                                  
            iseries i                                  
     WHERE  v.seriescode = i.seriescode                                  
            AND v.refcode = @doccode                                                         
/*          2012-09-11暂时取消，测试                             
     UPDATE l                                  
     SET    privatesdorgid = c.sdorgid2,                                  
            valid = 1,                                  
            dpttype = (SELECT dpttype                                  
                     FROM   osdorg                                  
                       WHERE  sdorgid = c.sdorgid2                                  
            )                     
            --select l.valid,l.cardnumber,c.seriescode,seriesnumber,*                                  
     FROM   VMatseriesdoc c, seriespool l                                  
     WHERE  c.refcode = @doccode                                  
            AND c.seriescode = l.cardnumber */                                 
 END                                   
 --------如果是店面调公司售后，就将调出店面写入串号表的stcode1，方便跟踪                                                          
 IF @formid IN (2424) --调拨出库                                  
 BEGIN                                  
     UPDATE iseries                                  
     SET    stcode1 = v.stcode,                                  
            shdjdate = v.docdate,                                  
            shdjHDMemo = v.hdmemo1                                  
     FROM   VSPICKseriesdoc v                                  
   INNER JOIN iseries i                                  
                 ON  v.seriescode = i.seriescode                                  
            INNER JOIN vStorage e                                  
                 ON  v.instcode = e.stcode                                  
                 AND e.service = 1                                  
     WHERE  v.refcode = @doccode                                  
            AND STATE = '在途'                       
 END                                   
 ---------如果是公司售后调到店面，就将串号表中的stcode1清空                                                          
 IF @formid IN (2424) --调拨出库                              
 BEGIN                                  
     UPDATE iseries                                  
     SET    stcode1 = NULL,                                  
            shdjdate = NULL,                                  
            shdjHDMemo = NULL                                  
     FROM   VSPICKseriesdoc v                                  
            INNER JOIN iseries i                                  
                 ON  v.seriescode = i.seriescode                           
            INNER JOIN vStorage e                                  
                ON  v.stcode = e.stcode                                  
                 AND e.service = 1                                  
     WHERE  v.refcode = @doccode                                  
            AND STATE = '在途'                                  
 END                                   
---------------------------------------------------------------------------------------------------------------                  
----------------------------------------------补差---------------------------------------------------------                                 
 IF @formid IN (1545) --供应商补差                                  
 BEGIN                                  
     UPDATE iseries                                  
     SET    purSPmoney = ISNULL(purSPmoney,0) + v.price                                  
     FROM   VAssureSeriesdoc v,                                  
            iseries i                                  
     WHERE  v.seriescode = i.seriescode                                  
            AND v.refcode = @doccode                                  
 END                                   
                                  
 UPDATE iseriesloghd                                  
 SET    docstatus = 100                                  
 WHERE  refcode = @doccode                                   
        ---以下是调拨出库转调拨入库串号的处理