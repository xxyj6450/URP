SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*        
过程名称:sp_PostServiceConfigurationDoc        
参数:见声名        
功能:商品业务功能过帐        
编写:三断笛        
时间:2011-11-16        
备注:        
begin tran         
exec [sp_PostServiceConfigurationDoc] 1813,'TJ20120713000001'        

SELECT * FROM sMatSDOrgPricelog ssp WHERE ssp.matcode='6.002.01.045' ORDER BY ssp.lastmodifydate desc

SELECT * FROM dbo.uf_salesSDOrgpricecalcu3('9060301','1','012564867989497')        
SELECT * FROM iSeriesPriceCalcu ispc        
         
SELECT * FROM dbo.uf_salesSDOrgpricecalcu3('6.002.01.045','1.1.871.01.04','')     
   
UPDATE CommonDoc_HD SET DocStatus = 0  

commit
rollback

exec [sp_PostServiceConfigurationDoc] 1813,'TJ20120315000001'       

select * from serviceconfiguration  

delete serviceconfiguration

BEGIN TRAN
UPDATE CommonDoc_HD
	SET DocStatus = 0
WHERE Doccode='TJ20120523000005'
         
   COMMIT
         ROLLBACK
*/        

ALTER PROC [dbo].[sp_PostServiceConfigurationDoc]        
 @formid INT,        
 @Doccode VARCHAR(20),
 @userCode VARCHAR(50)='',
 @TerminalID VARCHAR(50)=''
AS        
BEGIN
	SET NOCOUNT ON;
	DECLARE @tips VARCHAR(5000)
	--商品业务控制        
	IF @formid IN (1203)
	BEGIN
	    --更新已经存在的rowid        
	    UPDATE ServiceConfiguration
	    SET    vndcode = a.vndcode,
	           ServiceConfiguration.areaid = a.areaid,
	           ServiceConfiguration.SeriesCode = a.seriescode,
	           ServiceConfiguration.matcode = a.matcode,
	           ServiceConfiguration.MatGroup = a.matgroup,
	           ServiceConfiguration.FormGroup = a.formgroup,
	           ServiceConfiguration.PurchaseBeginDate = a.PurchaseBeginDate,
	           ServiceConfiguration.PurchaseEndDate = a.PurchaseEndDate,
	           ServiceConfiguration.RecoverSettings = a.RecoverSettings,
	           ServiceConfiguration.BeginDate = a.BeginDate,
	           ServiceConfiguration.EndDate = a.EndDate,
	           ServiceConfiguration.Valid = a.Valid,
	           ServiceConfiguration.memo = a.memo,
	           ServiceConfiguration.ModifyDate = GETDATE(),
	           ServiceConfiguration.ModifyName = a.modifyname,
	           modifydoccode = a.doccode,
	           ServiceConfiguration.purdoccode = a.PurDoccode
	    FROM   ServiceConfiguration_DT a
	    WHERE  a.doccode = @Doccode
	           AND a.refrowid = ServiceConfiguration.RowID
	    
	    INSERT INTO ServiceConfiguration( RowID, vndcode, areaid, matcode, 
	           MatGroup, memo, FormGroup, PurchaseBeginDate, PurchaseEndDate, 
	           BeginDate, EndDate, Valid, EnterName, EnterDate, enterdoccode, 
	           ModifyName, ModifyDate, Title, ModifyDoccode, purdoccode)
	    SELECT RowID,vndcode,areaid,matcode,MatGroup,memo,FormGroup,
	           PurchaseBeginDate,PurchaseEndDate,BeginDate,EndDate,Valid,a.entername,
	           a.EnterDate,b.doccode,a.modifyname,b.ModifyDate,a.Title,a.Doccode,
	           b.PurDoccode
	    FROM   ServiceConfiguration_HD a,ServiceConfiguration_DT b
	    WHERE  a.Doccode = b.doccode
	           AND NOT EXISTS(SELECT 1
	                          FROM   ServiceConfiguration sc
	                          WHERE  sc.RowID = b.refrowid
	               ) 
	               -- AND b.refrowid IS NULL
	           AND a.Doccode = @Doccode
	END 
	--采购入库写配置表    
	IF @formid IN (1509)
	   AND EXISTS(SELECT 1
	              FROM   imatdoc_d
	              WHERE  doccode = @doccode
	                     AND ISNULL(FormGroup,'') <> ''
	       )
	BEGIN
	    --select * from alter table ServiceConfiguration add purdoccode varchar(50)    
	    INSERT INTO ServiceConfiguration( RowID, vndcode, matcode, memo, 
	           FormGroup, EnterName, EnterDate, enterdoccode, ModifyName, 
	           ModifyDate, Title, purdoccode)
	    SELECT b.RowID,a.vndcode,b.matcode,HDMemo,FormGroup,a.entername,a.EnterDate,
	           b.doccode,a.modifyname,a.ModifyDate,a.doctype,a.Doccode
	    FROM   imatdoc_h a,imatdoc_d b
	    WHERE  a.Doccode = b.doccode
	           AND a.doccode = @doccode
	           AND ISNULL(FormGroup,'') <> ''
	           AND ISNULL(FormGroup,'') <> '所有'
	END 
	--价格管理        
	IF @formid IN (1813)
	BEGIN
	    DECLARE @sdorgid            VARCHAR(50),
	            @matcode            VARCHAR(50),
	            @matGroup           VARCHAR(50)
	    
	    DECLARE @CostPriceText      VARCHAR(2000),
	            @PurpriceText       VARCHAR(2000),
	            @OperatingcostText  VARCHAR(2000),
	            @SalePriceText      VARCHAR(2000),
	            @DiscountPriceText  VARCHAR(2000),
	            @MovePriceText      VARCHAR(2000),
	            @ReservePriceText   VARCHAR(2000),
	            @ScorePriceText		VARCHAR(2000)
	    --declare @CostPrice money,@Purprice money,@Operatingcost money,@SalePrice  money,@DiscountPrice money,@MovePrice  money,@ReservePrice  MONEY        
	    DECLARE @CostPrice          MONEY,
	            @Purprice           MONEY,
	            @OperatingCost      MONEY,
	            @DiscountPrice      MONEY,
	            @SalePrice          MONEY,
	            @MovePrice          MONEY,
	            @ReservePrice       MONEY,    
				@ScorePrice			MONEY
	    DECLARE @ModifyName         VARCHAR(50),
	            @beginDate          DATETIME,
	            @EndDate            DATETIME,
	            @MatCode1           VARCHAR(50),
	            @RecoverSubNOdes                                                                                                                                                                                                                              BIT,
	            @remark                                                                                                                                                                                                                                       VARCHAR(200),
	            @seriescode                                                                                                                                                                                                                                   VARCHAR(50) 
	    --声名游标,遍历单据中的行        
	    DECLARE abc                                                                                                                                                                                                                                           CURSOR READ_ONLY FORWARD_ONLY 
	    FOR
	        SELECT doccode,SeriesCode,apd.SdorgID,apd.MatCode,apd                                                                                                                                                                                             .MatGroup,
	               ISNULL(apd.curPurPrice,''),ISNULL(apd.curOperatingcost,''),ISNULL(apd.curSalePrice,''),
	               ISNULL(apd.curDiscountPrice,''),ISNULL(apd.curMovePrice,''),
	               ISNULL(apd.curReservePrice,''),isnull(apd.curscorePrice,''), apd.Remark,apd.ModifyName,
	               apd.BeginDate,apd.EndDate,apd.bitRecoverChildNodes,Terminalid
	        FROM   AdjustPrice_DT apd
	        WHERE  apd.Doccode = @Doccode
	    
	    OPEN abc 
	    FETCH NEXT FROM abc INTO @Doccode,@seriescode,@sdorgid,@matcode,@matGroup,
	    @PurpriceText,@OperatingcostText,@SalePriceText, 
	    @DiscountPriceText,@MovePriceText,@ReservePriceText,@ScorePriceText,@remark,@ModifyName, 
	    @beginDate,@EndDate,@RecoverSubNOdes,@TerminalID                                                                                                                                                              
	    WHILE @@FETCH_STATUS = 0
	    BEGIN
	        --SELECT CommonDB.dbo.REGEXP_Replace('经营成本价-200','((\d:)?[\u4e00-\u9fa5])+','&经营成本价&')
	        --先将表达式加上&        
	        /*DECLARE @PurpriceText VARCHAR(50),@PurpriceText1 VARCHAR(50)        
	        SELECT @PurpriceText='经营成本价-200+采购价'         
	        SELECT CommonDB.dbo.REGEXP_Replace(@PurpriceText,'((\d:)?[\u4e00-\u9fa5]+)','&$1&')        
	        --PRINT @PurpriceText        
	        */        
	        SELECT @PurpriceText = commondb.dbo.REGEXP_Replace(@PurpriceText, '((\d:)?[\u4e00-\u9fa5]+)','&$1&'),
	               @OperatingcostText = commondb.dbo.REGEXP_Replace(@OperatingcostText, '((\d:)?[\u4e00-\u9fa5]+)','&$1&'),
	               @SalePriceText = commondb.dbo.REGEXP_Replace(@SalePriceText, '((\d:)?[\u4e00-\u9fa5]+)','&$1&'),
	               @DiscountPriceText = commondb.dbo.REGEXP_Replace(@DiscountPriceText, '((\d:)?[\u4e00-\u9fa5]+)','&$1&'),
	               @MovePriceText = commondb.dbo.REGEXP_Replace(@MovePriceText, '((\d:)?[\u4e00-\u9fa5]+)','&$1&'),
	               @ReservePriceText = commondb.dbo.REGEXP_Replace(@ReservePriceText, '((\d:)?[\u4e00-\u9fa5]+)','&$1&'),
	               @ScorePriceText = commondb.dbo.REGEXP_Replace(@ScorePriceText, '((\d:)?[\u4e00-\u9fa5]+)','&$1&') 
	        --先处理有串号的,串号必须存在        
	        IF ISNULL(@seriescode,'') <> '' --AND EXISTS(SELECT 1 FROM iSeries is1 WHERE is1.SeriesCode=@seriescode) 性能比较低,暂时注释
	        BEGIN
  
	            -- select * from UF_SALESSDORGPRICECALCU3('9060301','1','012564867989497')
	            --计算表达式,同时将值传出.        
	            SELECT @SalePrice = NULLIF(convert(money,data4),''),@DiscountPrice = NULLIF(convert(money,data5),''),@ReservePrice = NULLIF(convert(money,data7),''),
	            @MovePrice = NULLIF(convert(money,data6),''),@OperatingCost = NULLIF(convert(money,data3),''),@CostPrice = NULLIF(convert(money,data1),''),
	            @Purprice = NULLIF(convert(money,data2),''),@ScorePrice=NULLIF(CONVERT(MONEY,data8),'') 
	            FROM   dbo.ExecuteTable(0,ISNULL(@CostPriceText,'') + ';' + ISNULL(@PurpriceText,'') + ';' + ISNULL(@OperatingcostText,'') + ';' + ISNULL(@SalePriceText,'') + ';' +
	                    ISNULL(@DiscountPriceText,'') + ';' + ISNULL(@MovePriceText,'') + ';' + ISNULL(@ReservePriceText,'')+';'+ISNULL(@ScorePriceText,''),
	                    'SELECT * FROM dbo.uf_salesSDOrgpricecalcu3(''' + @matcode1 + ''',''' + ISNULL(@sdorgid,'')+ ''',''' + ISNULL(@seriescode,'') + ''')','',-1,
	                    'Select * from fn_getFormulaFields(2801)',1)
	            UPDATE iSeriesPriceCalcu
	            SET    salesprice = ISNULL(@SalePrice,salesprice),
	                   salePrice1 = ISNULL(@DiscountPrice,salePrice1),
	                   selfprice = ISNULL(@ReservePrice,selfprice),
	                   selfprice1 = ISNULL(@MovePrice,selfprice1),
	                   end4 = ISNULL(@OperatingCost,end4),
	                   lastmodifydate = GETDATE(),
	                   lastmodifyname = @ModifyName,
	                   Begindate = ISNULL(@begindate,Begindate),
	                   EndDate = ISNULL(@EndDate,EndDate),
	                   terminalid=@TerminalID,
	                   ScorePrice = isnull(@ScorePrice,ScorePrice)
	                   
	            WHERE  seriescode = @seriescode
				--生成商品串号跌价记录
				if exists(select 1 from AdjustPrice_DT where doccode=@doccode and seriescode = @seriescode and isnull(curOperatingcost,0)<>isnull(orgOperatingcost,0))
				begin
					insert into Loss_price(seriescode,doctype,companyid,sdorgid,stcode,matcode,digit,price,price1,totalmoney,totalmoney1,allmoney,userdate,username)          
					select m.seriescode,'跌价损失',e.plantid,v.sdorgid,v.stcode,m.matcode,1,m.curOperatingcost,m.orgOperatingcost,          
					m.curOperatingcost as totalmoney,orgOperatingcost as totalmoney1,(m.curOperatingcost-m.orgOperatingcost) as allmoney,getdate(),@ModifyName          
					from AdjustPrice_DT m left join imatstorage e on m.matcode=e.matcode           
					left join vStorage v on e.stcode=v.stcode left join oSDOrg b on v.sdorgid=b.sdorgid
					where m.doccode=@doccode and isnull(curOperatingcost,0)<>isnull(orgOperatingcost,0) 
					and isnull(curOperatingcost,0)<>0 and isnull(orgOperatingcost,0)<>0          
					and b.[PATH] LIKE '%/' + @sdorgid + '/%' and m.seriescode=@seriescode
	            end
	            --如果未更新到行的话,则说明无此串号,插入之
	            IF @@ROWCOUNT = 0
	            BEGIN
	                INSERT INTO iSeriesPriceCalcu( seriescode, salesprice, 
	                       salePrice1, selfprice, selfprice1, end4, Begindate, 
	                       EndDate, lastmodifydate, lastmodifyname,terminalid,ScorePrice)
	                SELECT @seriescode,ISNULL(@SalePrice,a.saleprice),ISNULL(@DiscountPrice,a.saleprice1),ISNULL(@ReservePrice,a.selfprice),
	                ISNULL(@MovePrice,a.selfprice1),ISNULL(@OperatingCost,a.end4),ISNULL(@beginDate,
	                GETDATE()),ISNULL(@EndDate,'2050-12-31'),GETDATE(),isnull(nullif(@userCode,'@usercode'),@ModifyName),@TerminalID,ISNULL(@ScorePrice,a.ScorePrice)
	                FROM   dbo.uf_salesSDOrgpricecalcu3(@matcode,@sdorgid,@seriescode) a
	            END
	            
	            UPDATE CommonDoc_HD
	            SET    docstatus = 0
	            
	            DELETE 
	            FROM   iSeriesPriceCalcu 
	            --插入价格修改log表 salesprice,selfprice,selfprice1,end4,tobesalesprice,tobeselfprice,tobeselfprice1,money4      
	            INSERT INTO sMatSdorgPricelog( doccode, matgroup, matgroupname, 
	                   seriescode, bitRecoverChildNodes, matcode, costprice, 
	                   lastinprice, salesprice, selfprice, selfprice1, end4, 
	                   tobesalesprice, tobeselfprice, tobeselfprice1, money4, 
	                   lastmodifydate, lastmodifyname, rowid, SDOrgID, beginday, 
	                   endday,tobeScorePrice,scorePrice)
	            SELECT @Doccode,matgroup,matgroupname,seriescode,
	                   bitRecoverChildNodes,matcode,orgCostPrice,orgPurPrice,
	                   orgSalePrice,orgReservePrice,orgMovePrice,
	                   orgOperatingcost,curSalePrice,curReservePrice,
	                   curMovePrice,curOperatingcost,GETDATE(),d.PostName,rowid,SDOrgID,BeginDate,EndDate,t.orgScorePrice,t.curScorePrice
	            FROM   AdjustPrice_DT t
	                   LEFT JOIN CommonDoc_HD d ON  t.doccode = d.doccode
	            WHERE  t.doccode = @doccode
	                   AND t.sdorgid = @sdorgid
	                   AND t.matcode = @MatCode1
	        END
	        ELSE
	        BEGIN
	            --定义游标,取出该行的商品
	            --若该行只有商品编码,则直接取此商品编码
	            --若该行无商品编码,只有商品大类,则取该大类下的所有商品
	            --遍历取到的商品 逐个求值        
	            DECLARE curMatCode                  CURSOR READ_ONLY FORWARD_ONLY 
	            FOR
	                SELECT matcode
	                FROM   iMatGeneral a,iMatGroup  b
	                WHERE  a.MatGroup = b.matgroup
	                       AND ((ISNULL(@matcode,'') <> '' AND a.MatCode = @matcode)
	                               OR (ISNULL(@matcode,'') = ''
	                                      AND ISNULL(@matGroup,'') <> ''
	                                      AND b.path LIKE '%/'+ @matGroup+'/%'
	                                  )
	                           )
	            
	            OPEN curMatcode 
	            FETCH NEXT FROM curmatcode INTO @MatCode1        
	            
	            WHILE @@FETCH_STATUS = 0
	            BEGIN
	                --SELECT * FROM iSeriesPriceCalcu ispc WHERE ispc.seriescode='012564867989497'
	                --取出价格数据        
    
	                SELECT @SalePrice = NULLIF(convert(money,data4),''),@DiscountPrice = NULLIF(convert(money,data5),''),@ReservePrice = NULLIF(convert(money,data7),''),
	                @MovePrice = NULLIF(convert(money,data6),''),@OperatingCost = NULLIF(convert(money,data3),''),@CostPrice = NULLIF(convert(money,data1),''),
	                @Purprice = NULLIF(convert(money,data2),''),@ScorePrice=NULLIF(CONVERT(MONEY,data8),'')
	                FROM   dbo.ExecuteTable(0,ISNULL(@CostPriceText,'') + ';' + ISNULL(@PurpriceText,'') + ';' + ISNULL(@OperatingcostText,'') + ';' + ISNULL(@SalePriceText,'') + ';' +
	                        ISNULL(@DiscountPriceText,'') + ';' + ISNULL(@MovePriceText,'') + ';' + ISNULL(@ReservePriceText,'')+';'+ISNULL(@ScorePriceText,''),
	                        'SELECT * FROM dbo.uf_salesSDOrgpricecalcu3(''' + @matcode1 + ''',''' + ISNULL(@sdorgid,'') + ''',''' + ISNULL(@seriescode,'') + ''')','',-1,
	                        'Select * from fn_getFormulaFields(2801)',0) 
					--如果选择了覆盖子节点,则将子节点设置删除.        
	                /*IF @RecoverSubNOdes = 1
	                BEGIN
	                    DELETE sMatSDOrgPrice
	                    FROM   sMatSDOrgPrice a,
	                           oSDOrg b
	                    WHERE  a.sdorgid = b.SDOrgID
	                           AND a.matcode = @matcode
	                           AND b.[PATH] LIKE '%/' + @sdorgid + '/%'
	                           and b.SDOrgID<>@sdorgid
	                    IF @sdorgid IN(SELECT propertyvalue FROM dbo.fn_sysGetNumberAllocationConfig('价格管理根结点门店编号'))
							BEGIN
								DELETE FROM sMatSDOrgPrice WHERE matcode=@matcode AND SDOrgID<>@sdorgid
							END
	                END*/
					/*PRINT '零售价'
					PRINT ISNULL(@SalePrice,'')
					PRINT '优惠价'
					PRINT  ISNULL(@DiscountPrice,'')
					PRINT @ReservePriceText
					PRINT '底价'
					PRINT ISNULL(@ReservePrice,'')
					PRINT '调拔价'
					PRINT ISNULL(@MovePrice,'')
					PRINT '经营成本价'
					PRINT ISNULL(@OperatingCost,'')
					PRINT '采购价'
					PRINT ISNULL(@Purprice,'')
					PRINT '积分价'
					PRINT ISNULL(@ScorePrice,'')
	                --更新价格表    
	                PRINT '执行了修改'    */
	                UPDATE a
	                SET    salesprice = ISNULL(@SalePrice,salesprice),
	                       saleprice1 = ISNULL(@DiscountPrice,saleprice1),
	                       selfprice = ISNULL(@ReservePrice,selfprice),
	                       selfprice1 = ISNULL(@MovePrice,selfprice1),
	                       end4 = ISNULL(@OperatingCost,end4),
	                       a.crprice = ISNULL(@Purprice,a.crprice),
	                       beginday = ISNULL(@beginDate,GETDATE()),
	                       endday = ISNULL(@EndDate,'2050-12-31'),
	                       lastmodifydate = GETDATE(),
	                       lastmodifyname=isnull(nullif(@userCode,'@usercode'),@ModifyName),
	                       a.TerminalID = @TerminalID,
	                       scoreprice=ISNULL(@ScorePrice,a.ScorePrice)
	                FROM   sMatSDOrgPrice a
	                WHERE  matcode = @matcode1
	                       AND SDOrgID = @sdorgid
	                
	                IF @@ROWCOUNT = 0
	                BEGIN
	                	--PRINT '执行了新增'
	                    INSERT INTO sMatSDOrgPrice( matcode, SDOrgID, CompanyID, 
	                           salesprice, saleprice1, selfprice, selfprice1, 
	                           end4, beginday, endday, lastmodifydate, 
	                           lastmodifyname, crprice,TerminalID,ScorePrice)
	                    SELECT @MatCode1,@sdorgid,ops.PlantID,@SalePrice,@DiscountPrice,
	                           @ReservePrice,@MovePrice,@OperatingCost,@beginDate,
	                           @EndDate,GETDATE(),isnull(nullif(@userCode,'@usercode'),@ModifyName),@Purprice,@TerminalID,@ScorePrice
	                    FROM   oPlantSDOrg ops
	                    WHERE  ops.SDOrgID = @sdorgid
	                    IF @@ROWCOUNT=0
							BEGIN
								SELECT @tips='部门'+@sdorgid+'未设置公司，无法修改此部门价格。'
								RAISERROR(@tips,16,1)
								RETURN
							END
	                END 
	                --PRINT '插入记录'
	                --插入价格修改log表 salesprice,selfprice,selfprice1,end4,tobesalesprice,tobeselfprice,tobeselfprice1,money4      
	                /*INSERT INTO sMatSdorgPricelog( doccode, matgroup, 
	                       matgroupname, seriescode, bitRecoverChildNodes, 
	                       matcode, costprice, lastinprice, salesprice, 
	                       selfprice, selfprice1, end4, tobesalesprice, 
	                       tobeselfprice, tobeselfprice1, money4, lastmodifydate, 
	                       lastmodifyname, rowid, SDOrgID, beginday, endday)
	                SELECT @Doccode,matgroup,matgroupname,seriescode,
	                       bitRecoverChildNodes,matcode,orgCostPrice,orgPurPrice,
	                       orgSalePrice,orgReservePrice,orgMovePrice,
	                       orgOperatingcost,curSalePrice,curReservePrice,
	                       curMovePrice,curOperatingcost,GETDATE(),d.PostName,rowid,SDOrgID,BeginDate,EndDate
	                FROM   AdjustPrice_DT t
	                       LEFT JOIN CommonDoc_HD d ON  t.doccode = d.doccode
	                WHERE  t.doccode = @doccode
	                       AND t.sdorgid = @sdorgid
	                       AND t.matcode = @MatCode1*/
	                 --PRINT '覆盖节点'
	                
					--生成商品跌价记录
					/*if exists(select 1 from AdjustPrice_DT where doccode=@doccode and matcode=@MatCode1 and isnull(curOperatingcost,0)<>isnull(orgOperatingcost,0))
					begin
						INSERT INTO Loss_price( doctype, companyid, sdorgid, 
						       stcode, matcode, digit, ontrandigit, price, 
						       price1, totalmoney, totalmoney1, allmoney, 
						       userdate, username)
						SELECT '跌价损失',e.plantid,v.sdorgid,v.stcode,m.matcode,
						       unlimitstock,e.onorderstock,m.curOperatingcost,m.orgOperatingcost,
						       unlimitstock * m.curOperatingcost AS totalmoney,(unlimitstock + ISNULL(onorderstock,0))
						       * orgOperatingcost AS totalmoney1,((unlimitstock + ISNULL(onorderstock,0))
						        * (m.curOperatingcost -m.orgOperatingcost)
						       ) AS allmoney,GETDATE(),@ModifyName
						FROM   AdjustPrice_DT m
						       LEFT JOIN imatstorage e ON  m.matcode = e.matcode
						       LEFT JOIN vStorage v ON  e.stcode = v.stcode
						       LEFT JOIN oSDOrg b ON  v.sdorgid = b.sdorgid
						WHERE  m.doccode = @doccode
						       AND e.matcode = @MatCode1
						       AND ISNULL(curOperatingcost,0) <> ISNULL(orgOperatingcost,0)
						       AND ISNULL(curOperatingcost,0) <> 0
						       AND ISNULL(orgOperatingcost,0) <> 0
						       AND (ISNULL(unlimitstock,0) + ISNULL(onorderstock,0)) <> 0
						       AND b.[PATH] LIKE '%/' + @sdorgid + '/%'
	                end*/

	                FETCH NEXT FROM curmatcode INTO @MatCode1
	            END 
	            CLOSE curMatcode 
	            DEALLOCATE curMatCode
	        END 
	        FETCH NEXT FROM abc INTO @Doccode,@seriescode,@sdorgid,@matcode,@matGroup,
	        @PurpriceText,@OperatingcostText,@SalePriceText, 
	        @DiscountPriceText,@MovePriceText,@ReservePriceText,@ScorePriceText,@remark,@ModifyName, 
	        @beginDate,@EndDate,@RecoverSubNOdes,@TerminalID
	    END 
	    CLOSE abc 
	    DEALLOCATE abc 
	    RETURN
	END
END