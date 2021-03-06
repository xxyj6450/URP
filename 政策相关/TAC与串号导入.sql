SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- select * from checkdoc_stock(2424,'KY20101213000047')              
              
ALTER FUNCTION [dbo].[checkdoc_stock]
(
	@formid   INT,
	@doccode  doccode
)
RETURNS @table TABLE (warnflag INT,errorflag INT,infomessage VARCHAR(400))
AS
BEGIN
	DECLARE @refcode   VARCHAR(20),
	        @outcode1  VARCHAR(500)
	        declare @RowCount int
	--取单据基本数据              
	IF @formid IN (1507)
	BEGIN
	    SELECT @refcode = refcode,@outcode1 = outcode1
	    FROM   imatdoc_h
	    WHERE  DocCode = @doccode
	END
	
	
	IF EXISTS(SELECT 1
	          FROM   gsystemcontrol
	          WHERE  ParamID = 10000
	                 AND paramset = '1'
	   ) --and @formid not in (1512)
	BEGIN
	    INSERT INTO @table
	    VALUES(1,1,
	          '今天上午将进行成本调整，系统停用至上午12点整.所有业务可先做单保存，暂不确认，等系统恢复正常再确认。' )
	END 
	
	
	--系统现在正在升级中,升级过程大约需要10分钟。所有业务单据暂时只能保存,请稍后再进确认。              
	IF @formid IN (4950)
	BEGIN
	    INSERT INTO @table
	    SELECT 1,1,'订货金额不能大于信用额度！'
	    FROM   spickorderhd
	    WHERE  doccode = @doccode
	           AND ISNULL(summoney,0) < ISNULL(cavermoney,0)
	END     
	
	IF @formid IN (4950, 4951)
	BEGIN
	    INSERT INTO @table
	    SELECT 1,1,'单据金额跟明细总金额不相等，请联系管理员！'
	    FROM   spickorderhd d
	           LEFT JOIN (SELECT doccode,SUM(totalmoney) totalmoney
	                      FROM   spickorderitem
	                      WHERE  doccode = @doccode
	                      GROUP BY doccode
	                ) b ON  d.doccode = b.doccode
	    WHERE  d.doccode = @doccode
	           AND ISNULL(d.cavermoney,0) <> ISNULL(b.totalmoney,0)
	END 
	
	---未上线门店与上线门店的检查              
	IF @formid IN (1501, 1532)
	BEGIN
	    INSERT INTO @table
	    SELECT 1,1,'调入仓库为已上系统门店，请使用调拨出库单'
	    FROM   oStorage a,imatdoc_h b
	    WHERE  a.stCode IN (b.outcode1)
	           AND a.insystem = '1'
	           AND b.doccode = @doccode
	END

	if @formid in (1501,1520)
	begin
		insert into @table
		select 1,1,'请检查商品 "'+matname+'" 是否有效或已启用！'
		from imatdoc_d where matcode not in (select matcode from imatgeneral where isactived=1)
		and doccode=@doccode
	end

	IF @formid IN (1520)
	BEGIN
	    INSERT INTO @table
	    SELECT 1,1,'调入门店为已上系统门店，请使用调拨入库单'
	    FROM   oStorage a,imatdoc_h b
	    WHERE  a.stCode IN (b.outcode1)
	           AND a.insystem = '1'
	           AND b.doccode = @doccode
	END               
	
	IF @formid IN (2424)
	BEGIN
	    INSERT INTO @table
	    SELECT 1,1,'调入仓库为未上系统门店，请使用其它出库单'
	    FROM   oStorage a,spickorderhd b
	    WHERE  a.stCode IN (b.instcode)
	           AND a.insystem = '0'
	           AND b.doccode = @doccode
	END               
	
	IF @formid IN (2424)
	BEGIN
	    INSERT INTO @table
	    SELECT 1,1,'调出仓库为未上系统门店，请使用其它出库单'
	    FROM   spickorderhd b
	    WHERE  b.instcode NOT IN (SELECT stcode
	                              FROM   ostorage)
	           AND b.doccode = @doccode
	END               
	
	------
	--    sp_help iserieslogitem         select * from iserieslogitem              
	IF @formid IN (1501, 1520, 1532)
	BEGIN
	    INSERT INTO @table
	    SELECT 1,1,'数量不允许小于1'
	    FROM   imatdoc_d
	    WHERE  doccode = @doccode
	           AND digit < 1
	END
             
IF @formid IN (2424)
BEGIN
	DECLARE @areaid VARCHAR(50)                 
	SELECT @areaid = areaid  FROM spickorderhd d left join vstorage e on d.instcode=e.stcode WHERE  d.doccode=@doccode
    INSERT INTO @table
    SELECT 1,1,'串号' + m.seriescode + '属于区域:' + e.areaname + 
           '不能调到仓库:' + d.instname + '，请检查!'
    FROM   spickorderhd d
           LEFT JOIN iseriesloghd i ON  d.doccode = i.refcode
           LEFT JOIN iserieslogitem m ON  i.doccode = m.doccode
           LEFT JOIN vstorage e ON  d.instcode = e.stcode
           LEFT JOIN iseries s ON  m.seriescode = s.seriescode
    WHERE  d.doccode = @doccode
           AND d.formid = 2424
           AND ISNULL(s.areaid,'全部') <> '全部'
           AND ISNULL(s.areaid,'') <> ''
           AND ISNULL(e.areaid,'') <> ISNULL(s.areaid,'')
			and not exists(select 1 from gArea where areaid=@areaid and treecontrol like (select treecontrol from gArea where areaid=s.areaid)+'%')
           AND d.instcode NOT IN (SELECT stcode
                                  FROM   vstorage
                                  --改从系统配置表读取数据 2011-11-07 三断笛
                                  WHERE  sdorgid IN(SELECT propertyvalue FROM dbo.fn_sysGetNumberAllocationConfig('总仓部门节点') a)
           )
END
   
if @formid in (4950,4951)
	begin
		insert into @table
		select 1,1,'仓库不存在，不允许确认，请检查加盟店编号！'
		from spickorderhd where doccode=@doccode and instcode not in (select stcode from vstorage)
	end

if @formid in (4950,4951)
	begin
		insert into @table
		select 1,0,'商品:'+m.matname+' 金额为0，请检查！'
		from spickorderhd d left join spickorderitem m on d.doccode=m.doccode left join imatgeneral l on m.matcode=l.matcode
		where d.doccode=@doccode and isnull(m.totalmoney,0)=0
		and l.matgroup1 in (SELECT propertyvalue FROM dbo.fn_sysGetNumberAllocationConfig('手机大类'))
	end

IF @formid IN (2424)
BEGIN
    INSERT INTO @table
    SELECT 1,1,'单据未财务审核,请检查!'
    FROM   spickorderhd
    WHERE  doccode = @doccode
           AND formid = 2424
           AND ISNULL(usertxt3,'') = '是'
           AND ISNULL(sdgroupname1,'') = ''
END              


IF @formid IN (1501, 1520, 1532)
BEGIN
    INSERT INTO @table
    SELECT 1,1,b.matname + '_为无效的商品编码，请检查'
    FROM   imatdoc_d b,imatgeneral c
    WHERE  b.doccode = @doccode
           AND b.matcode = c.matcode
           AND c.isactived = 0
END               

IF @formid IN (1501, 1507, 1520, 1532) --1507
BEGIN
    INSERT INTO @table
    SELECT 1,1,'单据中的单价不允许为负，请检查单价！'
    FROM   imatdoc_d
    WHERE  doccode = @doccode
           AND ISNULL(price,0) < 0
           AND userdigit1 = 0
END 

--检查单据中的手机、配件商品编码基础资料中是否进行库存管理              

--销售退货、销售出库、批发出库、批发退货、调拨出库              
IF @formid IN (2424)
BEGIN
    INSERT INTO @table
    SELECT 1,1,'单据不能确认，请检查商品编码是否进行了库存管理!'
    FROM   vspickorder1
    WHERE  doccode = @doccode
           AND matcode NOT IN (SELECT matcode
                               FROM   imatgeneral
                               WHERE  matstate = 1)
           AND digit > 0--and left(matgroup,1) in ('S','P','K')
END 
 
IF @formid IN (1553)
BEGIN
    INSERT INTO @table
    SELECT 1,1,'串号' + m.seriescode1 + '不在仓库' + a.stname + 
           '内，不允许做串号调整！'
    FROM   iseriesloghd a
           LEFT JOIN iserieslogitem m ON  a.doccode = m.doccode
           LEFT JOIN iseries s ON  m.seriescode1 = s.seriescode
    WHERE  a.doccode = @doccode
           AND ISNULL(s.state,'') <> '在库'
END 
--检查串号长度是否一致        增加盘点单检查串号长度是否一致      
IF @formid IN (1520, 1507, 1541, 2424, 4954, 1125)
BEGIN
    INSERT INTO @table
    SELECT 1,1,b.matcode + '  ' + SeriesCode + '串号长度为' + CONVERT(VARCHAR(10),LEN(SeriesCode)) + '位不对应该是' + CONVERT(VARCHAR(6),c.MatImeiLong) + '位'
    FROM   iseriesloghd a
           INNER JOIN iserieslogitem b ON  a.doccode = b.doccode
           LEFT OUTER JOIN imatgeneral c ON  b.matcode = c.matcode
    WHERE  a.refcode = @doccode
           AND b.matcode = c.matcode
           AND LEN(b.SeriesCode) <> c.MatImeiLong
           AND c.MatFlag = 1
           AND ISNULL(MatImeiLong,0) <> 0
END 

--入库串号已存在              
IF @formid IN (1520)
BEGIN
    INSERT INTO @table
    SELECT 1,1,'串号' + CONVERT(VARCHAR(50),b.SeriesCode) + '已在仓库，项号：' + CONVERT(VARCHAR(6),docitem) + ', 不能入库确认，请检查！'
    FROM   iseriesloghd a
           INNER JOIN iserieslogitem b ON  a.doccode = b.doccode
    WHERE  b.seriescode  IN (SELECT seriescode
                             FROM   iseries
                             WHERE  STATE IN ('在库', '返厂', '在途', '售后', '借出'))
           AND a.refcode = @doccode
    ORDER BY b.seriescode,b.docitem
END              

IF @formid IN (1520)
BEGIN
    INSERT INTO @table
    SELECT 1,0,'商品：' + d.matname + '将以0单价入库，确定吗？'
    FROM   imatdoc_h h
           LEFT JOIN imatdoc_d d ON  h.doccode = d.doccode
    WHERE  h.doccode = @doccode
           AND ISNULL(d.price,0) = 0
END 
-------------------------------------------代销商品出入库、调拨金额必须为0.-----------------------------------              
--代销商品调拨出库必须是0金额，不能有运费。              
IF @formid IN (2424)
BEGIN
    INSERT INTO @table
    SELECT 1,1,'商品：“' + matname + 
           '”为代销商品，代销商品调拨的单价和金额必须是0，请检查！'
    FROM   vspickorderitem
    WHERE  doccode = @doccode
           AND LEFT(matcode,2) = 'S8'
           AND (ISNULL(price,0) <> 0 OR ISNULL(totalmoney,0) <> 0)
END 

 
-------------------------------------------------------------------------------------------------------              
--限制商品不能重复调入
IF @formid IN (1507)
BEGIN
    INSERT INTO @table
    SELECT 1,1,'串号' + CONVERT(VARCHAR(50),b.SeriesCode) + '已在仓库，项号：' + CONVERT(VARCHAR(6),docitem) + ', 不能入库确认，请检查！'
    FROM   iseriesloghd a
           INNER JOIN iserieslogitem b ON  a.doccode = b.doccode
    WHERE  b.seriescode  IN (SELECT seriescode
                             FROM   iseries
                             WHERE  STATE IN ('在库', '返厂', '售后', '借出'))
           AND a.refcode = @doccode
    ORDER BY b.seriescode,b.docitem
END 
 
--出库串号不存在              
IF @formid IN (2424, 1541, 1501, 1532)
BEGIN
    INSERT INTO @table
    SELECT 1,1,'串号' + CONVERT(VARCHAR(50),b.SeriesCode) + '不在仓库，项号：' + CONVERT(VARCHAR(6),docitem) + ', 不能出库确认，请检查！'
    FROM   iseriesloghd a
           INNER JOIN iserieslogitem b ON  a.doccode = b.doccode
    WHERE  b.seriescode NOT IN (SELECT seriescode
                                FROM   iseries
                                WHERE  stcode = a.stcode
                                       AND STATE = '在库'
                                       AND matcode = b.matcode)
           AND a.refcode = @doccode
           AND a.stcode <> '0301'
    ORDER BY b.seriescode,b.docitem
END 


--盘点单中检查批次是否存在              
IF @formid IN (1125)
BEGIN
    INSERT INTO @table
    SELECT 1,1,'盘点批次 ' + UserTxt1 + ' 不存在,不能确认！'
    FROM   imatdoc_h
    WHERE  doccode = @doccode
           AND UserTxt1 NOT IN (SELECT batchmark
                                FROM   checkbatchbuild
                                WHERE  endcheck = 0
                                       AND isactived = 1)
END 
----------------------------- 2011-06-21 1501-----------------------------------------------------------

IF @formid IN (1520, 1541, 1501, 1507, 1125, 1532) --入库数量和串号一致
BEGIN
    INSERT INTO @table
    SELECT 1,1,'单据中的商品' + ISNULL(v1.matcode,'') + '数量 ' + CONVERT(VARCHAR(10),ISNULL(v1.digit,0)) +
           '和 商品' + ISNULL(v2.matcode,'') + '输入的串/卡号数量' + CONVERT(VARCHAR(10),ISNULL(v2.digit,0)) + '不相同，不能确认'
    FROM   (SELECT d.matcode,digit
            FROM   vmatdoc d
                   LEFT JOIN imatgeneral m ON  d.matcode = m.matcode
            WHERE  d.doccode = @doccode
                   AND m.MatFlag = 1
           ) v1
           FULL OUTER  JOIN (SELECT i.matcode,COUNT(*) digit
                             FROM   iserieslogitem i
                                    LEFT JOIN iseriesloghd h ON  i.doccode = h.doccode
                             WHERE  h.refcode = @doccode
                             GROUP BY i.matcode
                ) V2 ON  v1.matcode = v2.matcode
    WHERE  ISNULL(v1.digit,0) <> ISNULL(v2.digit,0)
END 

----------------------------------------------------------------------------------------------  
IF @formid IN (4954) --入库数量和串号一致
BEGIN
    INSERT INTO @table
    SELECT 1,1,'单据中的商品' + ISNULL(v1.matcode,'') + '数量 ' + CONVERT(VARCHAR(10),ISNULL(v1.digit,0)) +
           '和 商品' + ISNULL(v2.matcode,'') + '输入的串/卡号数量' + CONVERT(VARCHAR(10),ISNULL(v2.digit,0)) + '不相同，不能确认'
    FROM   (SELECT d.matcode,digit
            FROM   VSPKOITEM d
                   LEFT JOIN imatgeneral m ON  d.matcode = m.matcode
            WHERE  d.doccode = @doccode
                   AND m.MatFlag = 1
           ) v1
           FULL OUTER  JOIN (SELECT i.matcode,COUNT(*) digit
                             FROM   iserieslogitem i
                                    LEFT JOIN iseriesloghd h ON  i.doccode = h.doccode
                             WHERE  h.refcode = @doccode
                             GROUP BY i.matcode
                ) V2 ON  v1.matcode = v2.matcode
    WHERE  ISNULL(v1.digit,0) <> ISNULL(v2.digit,0)
END 

--2010-10-27----------检查JIA盟端出货，入货时串号  
IF @formid IN (4950)
BEGIN
    INSERT INTO @table
    SELECT 1,1,'串号' + CONVERT(VARCHAR(50),b.SeriesCode) + '已不在仓库，项号：' + CONVERT(VARCHAR(6),docitem) + ', 不能出库确认，请检查！'
    FROM   spickorderhd d
           LEFT JOIN iseriesloghd a ON  d.doccode = a.refcode
           LEFT JOIN iserieslogitem b ON  a.doccode = b.doccode
    WHERE  b.seriescode NOT IN (SELECT seriescode
                                FROM   iseries
                                WHERE  STATE IN ('在库')
                                       AND stcode = d.stcode)
           AND a.refcode = @doccode
    ORDER BY b.seriescode,b.docitem

	insert into @table
	select 1,1,'出库串号商品编号与串号表的商品编号不一致，请与IT部联系！'
	from spickorderhd d
           LEFT JOIN iseriesloghd a ON  d.doccode = a.refcode
           LEFT JOIN iserieslogitem b ON  a.doccode = b.doccode
			left join iseries s on b.seriescode=s.seriescode
	where d.doccode=@doccode and isnull(b.matcode,'')<>isnull(s.matcode,'')
END  

IF @formid IN (4951)
BEGIN
    INSERT INTO @table
    SELECT 1,1,'串号' + CONVERT(VARCHAR(50),b.SeriesCode) + '已在仓库，项号：' + CONVERT(VARCHAR(6),docitem) + ', 不能入库确认，请检查！'
    FROM   iseriesloghd a
           INNER JOIN iserieslogitem b ON  a.doccode = b.doccode
    WHERE  b.seriescode  IN (SELECT seriescode
                             FROM   iseries
                             WHERE  STATE IN ('在库'))
           AND a.refcode = @doccode
    ORDER BY b.seriescode,b.docitem

	insert into @table
	select 1,1,'入库串号商品编号与串号表的商品编号不一致，请与IT部联系！'
	from spickorderhd d
           LEFT JOIN iseriesloghd a ON  d.doccode = a.refcode
           LEFT JOIN iserieslogitem b ON  a.doccode = b.doccode
			left join iseries s on b.seriescode=s.seriescode
	where d.doccode=@doccode and isnull(b.matcode,'')<>isnull(s.matcode,'')
END 
------------------------------ 2011-05-07  2424  

IF @formid IN (2424, 4950, 4951) --入库数量和串号一致
BEGIN
    INSERT INTO @table
    SELECT 1,1,'单据中的商品' + ISNULL(v1.matcode,'') + '数量 ' + CONVERT(VARCHAR(10),ISNULL(v1.digit,0)) +
           '和商品' + ISNULL(v2.matcode,'') + '输入的串/卡号数量' + CONVERT(VARCHAR(10),ISNULL(v2.digit,0)) + '不相同，不能确认'
    FROM   (SELECT d.matcode,digit
            FROM   VSPICKORDER d
                   LEFT JOIN imatgeneral m ON  d.matcode = m.matcode
            WHERE  d.doccode = @doccode
                   AND m.MatFlag = 1
           ) v1
           FULL OUTER  JOIN (SELECT i.matcode,COUNT(*) digit
                             FROM   iserieslogitem i
                                    LEFT JOIN iseriesloghd h ON  i.doccode = h.doccode
                             WHERE  h.refcode = @doccode
                             GROUP BY i.matcode
                ) V2 ON  v1.matcode = v2.matcode
    WHERE  ISNULL(v1.digit,0) <> ISNULL(v2.digit,0)
END 
              
IF @formid IN (1507)
BEGIN
    INSERT INTO @table
    SELECT 1,1,'第' + CONVERT(VARCHAR(6),v.docitem) + '项的调入量超过调出量' +
           CONVERT(VARCHAR(10),(ISNULL(s.ontransdigit,0) - v.basedigit)) + ',不能审核' 
           --SELECT v.doccode,s.doccode,v.sorowid,s.rowid,*
    FROM   VMATDOC v
           LEFT JOIN spickorderitem s
           INNER JOIN sPickorderHD a ON  s.DocCode = a.DocCode ON  v.sorowid = s.rowid
    WHERE  (ISNULL(s.ontransdigit,0) - v.basedigit) < 0
           AND v.doccode = @doccode
           AND a.FormID = 1507
END               

IF @formid IN (2424,4950)
BEGIN
    INSERT INTO @table
    SELECT 1,1,a.matname + ' 库存欠' + CAST(CAST((a.basedigit -ISNULL(b.unlimitstock, 0)) / c.baseuomrate AS MONEY
            ) AS VARCHAR
           ) + c.salesuom
    FROM   vspickorder_TXB a WITH (NOLOCK)
           INNER JOIN imatgeneral c ON  a.matcode = c.matcode
           LEFT OUTER JOIN VmatstoragenoBatch b WITH (NOLOCK)ON  a.stcode = b.stcode AND a.matcode = b.matcode --and a.batchcode = b.batchcode
    WHERE  a.doccode = @doccode
           AND a.basedigit > ISNULL(b.unlimitstock,0)
END 


--单据中同一商品分开做几个明细              
IF @formid IN (2424,4950)
BEGIN
    INSERT INTO @table
    SELECT 1,1,aa.matcode + aa.matname + ' 库存欠' + CAST(CAST((aa.digit -ISNULL(b.unlimitstock,0)) / aa.baseuomrate AS MONEY
            ) AS VARCHAR
           ) + aa.salesuom
    FROM   (SELECT SUM(digit) AS digit,a.stcode,a.matcode,a.matname,c.baseuomrate,c.salesuom
            FROM   vspickorder_TXB a WITH (NOLOCK)
                   INNER JOIN imatgeneral c ON  a.matcode = c.matcode
            WHERE  doccode = @doccode
                   AND c.MatState = 1
                   AND MatFlag = 0
            GROUP BY a.stcode,a.matcode,a.matname,c.baseuomrate,c.salesuom
           )aa
           LEFT OUTER JOIN VmatstoragenoBatch b WITH (NOLOCK)ON  aa.stcode = b.stcode AND aa.matcode = b.matcode
    WHERE  aa.digit > ISNULL(b.unlimitstock,0)
END

IF @formid IN (1501, 1504, 1541, 1532)
BEGIN
    INSERT INTO @table
    SELECT 1,1,a.matname + '库存欠' + CAST(CAST((a.basedigit -ISNULL(b.unlimitstock, 0)) / c.baseuomrate AS MONEY
            ) AS VARCHAR
           ) + c.salesuom
    FROM   vmatdoc a
           INNER JOIN imatgeneral c ON  a.matcode = c.matcode
           LEFT OUTER JOIN imatstorage b WITH (NOLOCK)ON  a.stcode = b.stcode AND a.matcode = b.matcode AND ISNULL(a.batchcode,'') = ISNULL(b.batchcode,'')
    WHERE  doccode = @doccode
           AND a.basedigit > ISNULL(b.unlimitstock,0)
END              

IF @formid IN (1501, 1520, 1532)
BEGIN
    INSERT INTO @table
    SELECT 1,1,CONVERT(VARCHAR(10),docitem) + matname + 'basedigit数据有问题，请联系系统管理员'
    FROM   imatdoc_d
    WHERE  doccode = @doccode
           AND digit <> ISNULL(basedigit,0) 
               --return
END              


IF @formid IN (3101)
BEGIN
    DECLARE @temptable3  TABLE(docitem INT)              
    DECLARE @coacode3    VARCHAR(20),
            @accountid3  VARCHAR(20),
            @rowid3      INT              
    
    DECLARE CURSOR4                           CURSOR  
    FOR
        SELECT b.coacode,a.accountid,docitem  
        FROM   Vfgldoc a
               INNER JOIN ocompany b ON  a.companyid = b.companyid AND a.doccode = 
                    @doccode 
    
    OPEN CURSOR4 
    
    FETCH NEXT FROM CURSOR4 
    INTO @coacode3,@accountid3,@rowid3                                                            
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT INTO @temptable3( docitem)
        SELECT DISTINCT docitem
        FROM   VFcountitemAll c
        WHERE  @accountid3 = c.acctcode
               AND @coacode3 = c.coacode              
        
        INSERT INTO @table
        SELECT 1,1,@accountid3 + '：请输入完整的辅助核算！'
        FROM   fgldocitem
        WHERE  docitem = @rowid3
               AND @accountid3 = accountid
               AND doccode = @doccode
               AND ((ISNULL(cv1,'') = ''
                        AND 1 IN (SELECT docitem
                                  FROM   @temptable3)
                    )
                       OR (ISNULL(cv2,'') = ''
                              AND 2 IN (SELECT docitem
                                        FROM   @temptable3)
                          )
                       OR (ISNULL(cv3,'') = ''
                              AND 3 IN (SELECT docitem
                                        FROM   @temptable3)
                          )
                       OR (ISNULL(cv4,'') = ''
                              AND 4 IN (SELECT docitem
                                        FROM   @temptable3)
                          )
                       OR (ISNULL(cv5,'') = ''
                              AND 5 IN (SELECT docitem
                                        FROM   @temptable3)
                          )
                   )              
        
        IF @@rowcount > 0
            RETURN
        ELSE
            DELETE 
            FROM   @temptable3 
        
        FETCH NEXT FROM CURSOR4 
        INTO @coacode3,@accountid3,@rowid3
    END 
    CLOSE CURSOR4 
    DEALLOCATE CURSOR4
END              

IF @formid IN (3102)
BEGIN
    IF EXISTS(SELECT *
              FROM   vFSubTGldocitem
              WHERE  doccode = @doccode
                     AND refdoccode IN (SELECT DISTINCT doccode
                                        FROM   faccledgerlog
                                        WHERE  loadflag = 1)
       )
    BEGIN
        INSERT INTO @table
        SELECT 1,1,'本集成单已有部分原始单据完成了集成,请检查。'
    END
    
    RETURN
END 

--畅销品定单              
DECLARE @reqsum    AS INT,
        @impsum    INT,
        @stosum    INT,
        @onwaysum  INT,
        @dtemp     AS DATETIME,
        @doccnt    INT

DECLARE @iyear     INT,
        @imonth    INT,
        @sdorgid   VARCHAR(50)

IF @formid = 6062
BEGIN
    SELECT @sdorgid = sdorgid
    FROM   ord_shopbestgoodsdoc
    WHERE  doccode = @doccode
    
    SELECT @dtemp = docdate
    FROM   ord_shopbestgoodsdoc
    WHERE  doccode = @doccode              
    
    SELECT @doccnt = COUNT(*)
    FROM   ord_shopbestgoodsdoc
    WHERE  sdorgid = @sdorgid
           AND docstatus = 100
           AND docdate = @dtemp
    GROUP BY sdorgid,docdate,docstatus
    
    IF @doccnt > 0
    BEGIN
        INSERT INTO @table
        SELECT 1,1,'当日已开定单,系统不允许当日再开定单!'
    END              
    
    IF EXISTS (SELECT TOP 1 *
               FROM   ord_shopbestgoodsdtl o
                      LEFT OUTER JOIN (SELECT matcode
                                       FROM   ord_bestgoodsinit
                                       WHERE  sdorgid = @sdorgid
                                              AND initdate = (SELECT MAX(initdate)
                                                              FROM   
                                                                     ord_bestgoodsinit
                                                              WHERE  sdorgid = @sdorgid
                                                  )
                           ) 
                           i ON  o.matcode = i.matcode
               WHERE  doccode = @doccode
                      AND i.matcode IS NULL
       )
    BEGIN
        INSERT INTO @table
        SELECT 1,1,'单据中包含了本次非畅销品的商品!'
    END               
    
    SELECT @reqsum = SUM(ask_digit)
    FROM   ord_shopbestgoodsdtl
    WHERE  doccode = @doccode
    
    SELECT @impsum = impsum
    FROM   ord_shopbestgoodsinfo
    WHERE  sdorgid = @sdorgid
    
    SELECT @stosum = COUNT(*)
    FROM   iseries i
           INNER JOIN vStorage v ON  i.stcode = v.stcode
    WHERE  i.isbg = 1
           AND i.isava = 1
           AND i.state = '在库'
           AND v.sdorgid = @sdorgid              
    
    SELECT @onwaysum = COUNT(*)
    FROM   iseries i
           INNER JOIN ord_shopbestgoodsdoc o ON  i.reqdoccode = o.doccode
    WHERE  isbg = 1
           AND isava = 1
           AND STATE = '在途'
           AND o.sdorgid = @sdorgid                
    
    IF ISNULL(@impsum,0) < @reqsum + @stosum + @onwaysum
    BEGIN
        INSERT INTO @table
        SELECT 1,1,'本次需求量已超出授权库存量，请联系计划部李经理18688670706!'
    END               
    
    IF EXISTS(SELECT i.plandate,i.plandate,i.sysplandate,i.* 
              FROM   ord_shopbestgoodsdtl i
                     LEFT JOIN ord_shopbestgoodsdoc k ON  i.doccode = k.doccode
              WHERE  i.doccode = @doccode
                     AND i.plandate < k.docdate + sysplandate + reservedays
       )
    BEGIN
        INSERT INTO @table
        SELECT 1,1,'到货日期超出调配周期!'
    END 
    
    --if exists(select top 1 * from ord_shopbestgoodsdtl d inner join imatgeneral i on d.matcode=i.matcode
    --where d.doccode=@doccode and i.matstatus in ('停产','缺货'))
    --begin              
    INSERT INTO @table
    SELECT 1,1,d.matname + '停产或缺货不能下定单!'
    FROM   ord_shopbestgoodsdtl d
           INNER JOIN imatgeneral i ON  d.matcode = i.matcode
    WHERE  d.doccode = @doccode
           AND i.matstatus IN ('停产', '缺货') 
               
               --end
END 

--补货申请单              
IF @formid = 6109
BEGIN
    SELECT @sdorgid = sdorgid
    FROM   sAskGoodsHD
    WHERE  doccode = @doccode
    
    SELECT @dtemp = docdate
    FROM   sAskGoodsHD
    WHERE  doccode = @doccode              
    
    SELECT @doccnt = COUNT(*)
    FROM   sAskGoodsHD
    WHERE  sdorgid = @sdorgid
           AND docstatus = 100
           AND docdate = @dtemp
    GROUP BY sdorgid,docdate,docstatus
    
    IF @doccnt > 0
    BEGIN
        INSERT INTO @table
        SELECT 1,1,'当日已开申请单,系统不允许当日再开申请单!'
    END 
              
    INSERT INTO @table
    SELECT 1,1,'单据中包含了畅销品[' + o.matname + ']的商品!'
    FROM   sAskGoodsItem o
           LEFT OUTER JOIN (SELECT matcode
                            FROM   ord_bestgoodsinit
                            WHERE  sdorgid = @sdorgid
                                   AND initdate = (SELECT MAX(initdate)
                                                   FROM   ord_bestgoodsinit
                                                   WHERE  sdorgid = @sdorgid
                                       )
                ) 
                i ON  o.matcode = i.matcode
    WHERE  doccode = @doccode
           AND i.matcode IS NOT NULL              
    
    INSERT INTO @table
    SELECT 1,1,'单据中包含了停产或缺货的商品[' + o.matname + ']'
    FROM   sAskGoodsItem o
           INNER JOIN imatgeneral i ON  o.matcode = i.matcode
    WHERE  o.doccode = @doccode
           AND i.matstatus IN ('停产', '缺货') 
               --  end
END 


 

DECLARE @refCode1 doccode 
 


--判断往来收款单的收款帐号与结算方式是否一致。              
IF @formid IN (2055)
BEGIN
    IF EXISTS(SELECT 1
              FROM   farcashindoc
              WHERE  doccode = @doccode
                     AND payway = '现金'
       )
    BEGIN
        INSERT INTO @table
        SELECT 1,1,
               '单据无法确认，你选择的“收款帐户”与“结算方式”不一致，请检查!'
        FROM   farcashindoc
        WHERE  LEFT(fcashaccount,4) <> '1001'
               AND doccode = @doccode
    END              
    
    IF EXISTS(SELECT 1
              FROM   farcashindoc
              WHERE  doccode = @doccode
                     AND (payway = '银行' OR payway = '支票')
       )
    BEGIN
        INSERT INTO @table
        SELECT 1,1,
               '单据无法确认，你选择的“收款帐户”与“结算方式”不一致，请检查!'
        FROM   farcashindoc
        WHERE  LEFT(fcashaccount,4) <> '1002'
               AND doccode = @doccode
    END
END 



--判断往来付款单的付款帐号与结算方式是否一致。              
IF @formid IN (4405)
BEGIN
    IF EXISTS(SELECT 1
              FROM   fapcashoutdoc
              WHERE  doccode = @doccode
                     AND paytype = '现金'
       )
    BEGIN
        INSERT INTO @table
        SELECT 1,1,
               '单据无法确认，你选择的“付款帐户”与“结算方式”不一致，请检查!'
        FROM   fapcashoutdoc
        WHERE  LEFT(fcashaccount,4) <> '1001'
               AND doccode = @doccode
    END              
    
    IF EXISTS(SELECT 1
              FROM   fapcashoutdoc
              WHERE  doccode = @doccode
                     AND (paytype = '银行' OR paytype = '支票')
       )
    BEGIN
        INSERT INTO @table
        SELECT 1,1,
               '单据无法确认，你选择的“付款帐户”与“结算方式”不一致，请检查!'
        FROM   fapcashoutdoc
        WHERE  LEFT(fcashaccount,4) <> '1002'
               AND doccode = @doccode
    END
END 



--帐户转账单 判断各种类型。               

IF @formid IN (2054)
BEGIN
    IF EXISTS(SELECT 1
              FROM   Fcashdoc
              WHERE  doccode = @doccode
                     AND ISNULL(transType,'') = '拨款'
       )
    BEGIN
        INSERT INTO @table
        SELECT 1,1,
               '单据无法确认！转账类型为“拨款”的情况下，“转出帐户”和“转入帐户”必须都是银行帐户，请检查！'
        FROM   Fcashdoc
        WHERE  doccode = @doccode
               AND ISNULL(transType,'') = '拨款'
               AND (LEFT(cashCode,4) <> '1002' OR LEFT(cashCode2,4) <> '1002')
    END                
    
    IF EXISTS(SELECT 1
              FROM   Fcashdoc
              WHERE  doccode = @doccode
                     AND (ISNULL(transType,'') = '存款'
                             OR ISNULL(transType,'') = '刷卡'
                             OR ISNULL(transType,'') = '支票'
                         )
       )
    BEGIN
        INSERT INTO @table
        SELECT 1,1,
               '单据无法确认！转账类型为“存款”或“刷卡”或“支票”的情况下，“转出帐户”必须为现金帐户，“转入帐户”必须是银行帐户，请检查！'
        FROM   Fcashdoc
        WHERE  doccode = @doccode
               AND (ISNULL(transType,'') = '存款'
                       OR ISNULL(transType,'') = '刷卡'
                       OR ISNULL(transType,'') = '支票'
                   )
               AND (LEFT(cashCode,4) <> '1001' OR LEFT(cashCode2,4) <> '1002')
    END               
    
    IF EXISTS(SELECT 1
              FROM   Fcashdoc
              WHERE  doccode = @doccode
                     AND ISNULL(transType,'') = '取现'
       )
    BEGIN
        INSERT INTO @table
        SELECT 1,1,
               '单据无法确认！转账类型为“取现”的情况下，“转出帐户”必须为银行帐户，“转入帐户”必须是现金帐户，请检查！'
        FROM   Fcashdoc
        WHERE  doccode = @doccode
               AND ISNULL(transType,'') = '取现'
               AND (LEFT(cashCode,4) <> '1002' OR LEFT(cashCode2,4) <> '1001')
    END               
    
    IF EXISTS(SELECT 1
              FROM   Fcashdoc
              WHERE  doccode = @doccode
                     AND ISNULL(transType,'') = '现金'
       )
    BEGIN
        INSERT INTO @table
        SELECT 1,1,
               '单据无法确认！转账类型为“现金”的情况下，“转出帐户”和“转入帐户”必须都是系统帐户，请检查！'
        FROM   Fcashdoc
        WHERE  doccode = @doccode
               AND ISNULL(transType,'') = '现金'
               AND (LEFT(cashCode,4) <> '1001' OR LEFT(cashCode2,4) <> '1001')
    END
END              

IF @formid IN (2063)
BEGIN
    INSERT INTO @table
    SELECT 1,1,d.glcode + '科目的名称不能随意更改，请检查'
    FROM   fchargedocd d
           LEFT JOIN fcoaledger r ON  d.glcode = r.acctcode
    WHERE  d.doccode = @doccode
           AND d.glname <> r.acctname
END 
--付款单（费用支出单） 判断费用科目是否选择末级，否则不能确认。              

IF @formid IN (2063)
BEGIN
    INSERT INTO @table
    SELECT 1,1,'单据无法确认！单据中选择的科目“' + glname + 
           '”不是末级科目，请检查！'
    FROM   fchargedocd
    WHERE  doccode = @doccode
           AND glcode IN (SELECT acctcode
                          FROM   fcoaledger
                          WHERE  nodetail = 1
                                 AND acctcode IN (SELECT glcode
                                                  FROM   fchargedocd
                                                  WHERE  doccode = @doccode))
END 

--付款单（费用支出单） 判断付款方式是否正确，否则不能确认。              

IF @formid IN (2063)
BEGIN
    IF EXISTS(SELECT 1
              FROM   Fchargedocm
              WHERE  doccode = @doccode
                     AND payway = '现金'
       )
    BEGIN
        INSERT INTO @table
        SELECT 1,1,
               '单据无法确认！结算方式为“现金”的情况下，“付款帐户”必须是系统帐户，请检查！'
        FROM   Fchargedocm
        WHERE  doccode = @doccode
               AND (LEFT(fcashaccount,4) <> '1001')
    END              
    
    IF EXISTS(SELECT 1
              FROM   Fchargedocm
              WHERE  doccode = @doccode
                     AND (payway = '银行' OR payway = '支票')
       )
    BEGIN
        INSERT INTO @table
        SELECT 1,1,
               '单据无法确认！结算方式为“银行”或“支票”的情况下，“付款帐户”必须是银行帐户，请检查！'
        FROM   Fchargedocm
        WHERE  doccode = @doccode
               AND LEFT(fcashaccount,4) <> '1002'
    END
END              

IF @formid IN (2067)
BEGIN
    IF EXISTS(SELECT 1
              FROM   Fcashdoc
              WHERE  doccode = @doccode
                     AND paymethod = '现金'
       )
    BEGIN
        INSERT INTO @table
        SELECT 1,1,
               '单据无法确认！结算方式为“现金”的情况下，“付款帐户”必须是系统帐户，请检查！'
        FROM   Fcashdoc
        WHERE  doccode = @doccode
               AND (LEFT(cashCode,4) <> '1001')
    END              
    
    IF EXISTS(SELECT 1
              FROM   Fcashdoc
              WHERE  doccode = @doccode
                     AND (paymethod = '银行' OR paymethod = '支票')
       )
    BEGIN
        INSERT INTO @table
        SELECT 1,1,
               '单据无法确认！结算方式为“银行”或“支票”的情况下，“付款帐户”必须是银行帐户，请检查！'
        FROM   Fcashdoc
        WHERE  doccode = @doccode
               AND LEFT(cashCode,4) <> '1002'
    END
END              

IF @formid IN (1523)
BEGIN
    IF EXISTS(SELECT 1
              FROM   Vmatdoc
              WHERE  doccode = @doccode
                     AND ISNULL(digit,0) <  = 0
       )
    BEGIN
        INSERT INTO @table
        SELECT 1,1,'确认失败，商品“' + matname + 
               '”的出库数量小于或等于0是不允许的，请检查!'
        FROM   Vmatdoc
        WHERE  doccode = @doccode
               AND ISNULL(digit,0) <  = 0
    END              
    
    IF EXISTS(SELECT 1
              FROM   Vmatdoc a
                     LEFT JOIN v_matstorage b ON  a.stcode = b.stcode AND a.matcode = 
                          b.matcode
              WHERE  doccode = @doccode
                     AND ISNULL(a.digit,0) > ISNULL(b.unlimitStock,0)
       )
    BEGIN
        INSERT INTO @table
        SELECT 1,1,'确认失败，商品“' + a.matname + 
               '”的出库数量大于库存数量，请检查!'
        FROM   Vmatdoc a
               LEFT JOIN v_matstorage b ON  a.stcode = b.stcode AND a.matcode = 
                    b.matcode
        WHERE  doccode = @doccode
               AND ISNULL(a.digit,0) > ISNULL(b.unlimitStock,0)
    END
END              







IF @formid = 3103
BEGIN
    IF NOT EXISTS(SELECT 1
                  FROM   VFardocitem a
                         INNER JOIN vfaccount b ON  a.companyid = b.companyid AND 
                              a.AccountID = b.acctcode
                  WHERE  a.doccode = @doccode
                         AND b.acctsubtype = '应收账款'
       )
        INSERT INTO @table
        VALUES(1,1,'应收凭证里的科目至少有一项为‘应收账款’类科目' )
END              

IF @formid IN (3103)
BEGIN
    BEGIN
    	INSERT INTO @table
    	SELECT 1,1,'请检查科目：' + a.accountid + '的余额！'
    	FROM   (SELECT *
    	        FROM   vfardocitem
    	        WHERE  doccode = @doccode
    	               AND companyid = '01'
    	               AND accountid IN (SELECT staticid
    	                                 FROM   getinstrForStatic('310303'))
    	       ) a
    	       INNER JOIN (SELECT *
    	                   FROM   fsubinstbalance
    	                   WHERE  account IN (SELECT staticid
    	                                      FROM   getinstrForStatic('310303'))
    	            ) b ON  a.companyid = b.companyid AND a.accountid = b.account AND 
    	            ISNULL(a.cv1,'') = b.cv1 AND ISNULL(a.cv2,'') = b.cv2 AND ISNULL(a.cv3,'') = b.cv3 AND ISNULL(a.cv4,'') = b.cv4 AND ISNULL(a.cv5,'') = b.cv5 AND ISNULL(b.balance,0) + ISNULL(a.debit,0) -ISNULL(a.credit,0) > 0              
    	
    	IF @@rowcount > 0
    	    RETURN
    END
END 


--检查限定币种              
IF @formid IN (3105, 3107)
BEGIN
    INSERT INTO @table
    SELECT 1,1,a.cashcode + '：资金帐户的业务币种与限定币种不相符！'
    FROM   fcashdoc a,fCompanyLedger b
    WHERE  a.doccode = @doccode
           AND a.cashcode = b.subacctcode
           AND a.companyid = b.companyid
           AND a.hdcurrency <> b.limitcurrency              
    
    IF @@rowcount > 0
        RETURN
END 

/*       
---收款检查受控制科目              
if @formid in (3105)              
begin              

if exists(select * from v_fcashdoc              
where doccode=@doccode and companyid='01'              
and accountid in (select staticid from getinstrForStatic('310501')))              
if not exists (select 1 from fsubinstbalance where companyid+account+cv1+cv2+cv3+cv4+cv5              

in (select isnull(companyid,'')+isnull(account,'')+isnull(cv1,'')+isnull(cv2,'')+isnull(cv3,'')+isnull(cv4,'')+isnull(cv5,'')              
from v_fcashdoc              
where doccode=@doccode and companyid='01' and accountid in (select staticid from getinstrForStatic('310501'))              
))              
begin              
insert into @table               
select 1,1,'请检查贷方科目辅助核算值！'              
return              
end              
else              
begin              
insert into @table              
select 1,1,'请检查科目：'+a.accountid+'的余额！'               
from              
(              
select * from v_fcashdoc               
where doccode=@doccode and companyid='01'              
and accountid in (select staticid from getinstrForStatic('310501'))              
) a inner join              
(select * from fsubinstbalance              
where account in (select staticid from getinstrForStatic('310501'))              
) b               
on a.companyid=b.companyid and a.accountid=b.account               
and isnull(a.cv1,'')=b.cv1 and isnull(a.cv2,'')=b.cv2 and isnull(a.cv3,'')=b.cv3 and isnull(a.cv4,'')=b.cv4 and isnull(a.cv5,'')=b.cv5                
and isnull(b.balance,0)-isnull(a.Money,0)<0              

if @@rowcount>0            
return              

end              
end              
*/ 
----付款检查受控制科目              

/*              
if @formid in (3106,3107)              
begin               

if exists(select * from v_fcashdoc               
where doccode=@doccode  and companyid='01'              
and accountid in (select staticid from getinstrForStatic('310603')))              

if not exists (select 1 from fsubinstbalance where companyid+account+cv1+cv2+cv3+cv4+cv5              
in (select isnull(companyid,'')+isnull(account,'')+isnull(cv1,'')+isnull(cv2,'')+isnull(cv3,'')+isnull(cv4,'')+isnull(cv5,'')              
from v_fcashdoc              
where doccode=@doccode and companyid='01' and accountid in (select staticid from getinstrForStatic('310603'))              
))              
begin              
insert into @table               
select 1,1,'请检查借方科目辅助核算值！'               
return              
end              
else              
begin              

insert into @table              
select 1,1,'请检查科目：'+a.accountid+'的余额！'               
from              
(              
select * from v_fcashdoc               
where doccode=@doccode and companyid='01'              
and accountid in (select staticid from getinstrForStatic('310603'))              
) a inner join              
(select * from fsubinstbalance              
where account in (select staticid from getinstrForStatic('310603'))              
) b               
on a.companyid=b.companyid and a.accountid=b.account                
and isnull(a.cv1,'')=b.cv1 and isnull(a.cv2,'')=b.cv2 and isnull(a.cv3,'')=b.cv3 and isnull(a.cv4,'')=b.cv4 and isnull(a.cv5,'')=b.cv5               
and isnull(a.Money,0)+isnull(b.balance,0)>0              
--and a.accountid not in ('219101','219108','219109','219102','219111')              

if @@rowcount>0              
return              

end              
end              

--检查辅助核算个数              
if @formid in (3105,3106,3107)              
begin              
insert into @table              
select 1,1,'科目：'+AccountID+'辅助核算输入有误!请删除该行重新输入!'              
from               
(              
select AccountID,              
((case when isnull(cv1,'')='' then 0 else 1 end)              
+(case when isnull(cv2,'')='' then 0 else 2 end)              
+(case when isnull(cv3,'')='' then 0 else 3 end)              
+(case when isnull(cv4,'')='' then 0 else 4 end)              
+(case when isnull(cv5,'')='' then 0 else 5 end)) as               
num              
from v_fcashdoc where doccode=@doccode               
) a              
left outer join              
(              
select acctcode,isnull(sum(DocItem),0) as num From VFcountitemAll   group by acctcode               

) b              
on a.AccountID=b.acctcode       
where isnull(a.num,0)<>isnull(b.num,0) and isnull(a.AccountID,'')<>''              

if @@rowcount>0              
return               

end              
*/              

IF @formid IN (3103, 3104)
BEGIN
    INSERT INTO @table
    SELECT 1,1,'科目：' + AccountID + '辅助核算输入有误!请删除该行重新输入!'
    FROM   (SELECT AccountID,((CASE WHEN ISNULL(cv1,'') = '' THEN 0 ELSE 1 END) 
                    + (CASE WHEN ISNULL(cv2,'') = '' THEN 0 ELSE 2 END) 
                    + (CASE WHEN ISNULL(cv3,'') = '' THEN 0 ELSE 3 END) 
                    + (CASE WHEN ISNULL(cv4,'') = '' THEN 0 ELSE 4 END) 
                    + (CASE WHEN ISNULL(cv5,'') = '' THEN 0 ELSE 5 END)
                   ) AS num
            FROM   vfardocitem
            WHERE  doccode = @doccode
           ) a
           FULL JOIN (SELECT acctcode,ISNULL(SUM(DocItem),0) AS num
                      FROM   VFcountitemAll
                      GROUP BY acctcode
                ) b ON  a.AccountID = b.acctcode
    WHERE  ISNULL(a.num,0) <> ISNULL(b.num,0)
           AND ISNULL(a.AccountID,'') <> ''              
    
    IF @@rowcount > 0
        RETURN
END              

IF @formid IN (3104)
BEGIN
    INSERT INTO @table
    SELECT 1,1,'科目：' + AccountID + '辅助核算输入有误!请删除该行重新输入!'
    FROM   (SELECT AccountID,((CASE WHEN ISNULL(cv1,'') = '' THEN 0 ELSE 1 END) 
                    + (CASE WHEN ISNULL(cv2,'') = '' THEN 0 ELSE 2 END) 
                    + (CASE WHEN ISNULL(cv3,'') = '' THEN 0 ELSE 3 END) 
                    + (CASE WHEN ISNULL(cv4,'') = '' THEN 0 ELSE 4 END) 
                    + (CASE WHEN ISNULL(cv5,'') = '' THEN 0 ELSE 5 END)
                   ) AS num
            FROM   VFapdocitem
            WHERE  doccode = @doccode
           ) a
           FULL JOIN (SELECT acctcode,ISNULL(SUM(DocItem),0) AS num
                      FROM   VFcountitemAll
                      GROUP BY acctcode
                ) b ON  a.AccountID = b.acctcode
    WHERE  ISNULL(a.num,0) <> ISNULL(b.num,0)
           AND ISNULL(a.AccountID,'') <> ''              
    
    IF @@rowcount > 0
        RETURN
END              


IF @formid IN (3103)
BEGIN
    DECLARE @temptable1  TABLE(docitem INT)              
    DECLARE @coacode1    VARCHAR(20),
            @accountid1  VARCHAR(20),
            @rowid1      VARCHAR(40)               
    
    DECLARE CURSOR2                     CURSOR  
    FOR
        SELECT b.coacode,a.accountid,a  .rowid
        FROM   VFardocitem a
               INNER JOIN ocompany b ON  a.companyid = b.companyid AND a.doccode = 
                    @doccode 
    
    OPEN CURSOR2 
    
    FETCH NEXT FROM CURSOR2 
    INTO @coacode1,@accountid1,@rowid1                                                      
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT INTO @temptable1( docitem)
        SELECT DISTINCT docitem
        FROM   VFcountitemAll c
        WHERE  @accountid1 = c.acctcode
               AND @coacode1 = c.coacode              
        
        INSERT INTO @table
        SELECT 1,1,@accountid1 + '：请输入完整的辅助核算！'
        FROM   fardocitem
        WHERE  rowid = @rowid1
               AND doccode = @doccode
               AND ((ISNULL(cv1,'') = ''
                        AND 1 IN (SELECT docitem
                                  FROM   @temptable1)
                    )
                       OR (ISNULL(cv2,'') = ''
                              AND 2 IN (SELECT docitem
                                        FROM   @temptable1)
                          )
                       OR (ISNULL(cv3,'') = ''
                              AND 3 IN (SELECT docitem
                                        FROM   @temptable1)
                          )
                       OR (ISNULL(cv4,'') = ''
                              AND 4 IN (SELECT docitem
                                        FROM   @temptable1)
                          )
                       OR (ISNULL(cv5,'') = ''
                              AND 5 IN (SELECT docitem
                                        FROM   @temptable1)
                          )
                   )              
        
        IF @@rowcount > 0
            RETURN
        ELSE
            DELETE 
            FROM   @temptable1 
        
        FETCH NEXT FROM CURSOR2 
        INTO @coacode1,@accountid1,@rowid1
    END 
    CLOSE CURSOR2 
    DEALLOCATE CURSOR2
END              

IF @formid IN (3108, 3147, 3155, 3109)
BEGIN
    DECLARE @temptable2  TABLE(docitem INT)               
    DECLARE @coacode2    VARCHAR(20),
            @accountid2  VARCHAR(20),
            @rowid2      INT              
    
    DECLARE CURSOR3                           CURSOR  
    FOR
        SELECT b.coacode,a.accountid,docitem  
        FROM   Vfsubdoc a
               INNER JOIN ocompany b ON  a.companyid = b.companyid AND a.doccode = 
                    @doccode 
    
    OPEN CURSOR3 
    
    FETCH NEXT FROM CURSOR3 
    INTO @coacode2,@accountid2,@rowid2                                                            
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT INTO @temptable2( docitem)
        SELECT DISTINCT docitem
        FROM   VFcountitemAll c
        WHERE  @accountid2 = c.acctcode
               AND @coacode2 = c.coacode              
        
        INSERT INTO @table
        SELECT 1,1,@accountid2 + '：请输入完整的辅助核算！'
        FROM   fsubdocitem
        WHERE  docitem = @rowid2
               AND @accountid2 = accountid
               AND doccode = @doccode
               AND ((ISNULL(cv1,'') = ''
                        AND 1 IN (SELECT docitem
                                  FROM   @temptable2)
                    )
                       OR (ISNULL(cv2,'') = ''
                              AND 2 IN (SELECT docitem
                                        FROM   @temptable2)
                          )
                       OR (ISNULL(cv3,'') = ''
                              AND 3 IN (SELECT docitem
                                        FROM   @temptable2)
                          )
                       OR (ISNULL(cv4,'') = ''
                              AND 4 IN (SELECT docitem
                                        FROM   @temptable2)
                          )
                       OR (ISNULL(cv5,'') = ''
                              AND 5 IN (SELECT docitem
                                        FROM   @temptable2)
                          )
                   )              
        
        IF @@rowcount > 0
            RETURN
        ELSE
            DELETE 
            FROM   @temptable2 
        
        FETCH NEXT FROM CURSOR3 
        INTO @coacode2,@accountid2,@rowid2
    END 
    CLOSE CURSOR3 
    DEALLOCATE CURSOR3
END 
/*        
--检查辅助核算              
if @formid in (3105,3106,3107)              
begin              

declare @temptable table(docitem int)              
declare @coacode varchar(20),              
@accountid varchar(20),              
@rowid varchar(40)              

DECLARE CURSOR1 CURSOR FOR              
SELECT b.coacode,a.accountid ,a.rowid              
from v_fcashdoc a  inner join ocompany b  on a.companyid=b.companyid and a.doccode=@doccode              

OPEN CURSOR1               

FETCH NEXT FROM CURSOR1              
INTO @coacode,@accountid,@rowid              

WHILE @@FETCH_STATUS =  0              
BEGIN               
insert into @temptable(docitem)              
select distinct docitem from VFcountitemAll c where @accountid=c.acctcode and @coacode=c.coacode              

insert into @table              
select 1,1,@accountid+'：请输入完整的辅助核算！'              
from fcashdocitem where rowid=@rowid and doccode=@doccode              
and ((isnull(cv1,'')='' and 1 in (select docitem from @temptable))              
or (isnull(cv2,'')='' and 2 in (select docitem from @temptable))               
or (isnull(cv3,'')='' and 3 in (select docitem from @temptable))              
or (isnull(cv4,'')='' and 4 in (select docitem from @temptable))              
or (isnull(cv5,'')='' and 5 in (select docitem from @temptable)))              

if @@rowcount>0               
return              
else              
delete from @temptable              

FETCH NEXT FROM CURSOR1               
INTO @coacode,@accountid,@rowid              
end              
close CURSOR1              
DEALLOCATE CURSOR1              
end              
*/          
IF @formid IN (3107)
BEGIN
    DECLARE @summoney  MONEY,
            @balance   MONEY
    
    SELECT @summoney = summoney
    FROM   fcashdoc
    WHERE  doccode = @doccode
    
    SELECT @balance = balance
    FROM   fsubinstbalance
    WHERE  account IN (SELECT cashcode
                       FROM   fcashdoc
                       WHERE  doccode = @doccode)
    
    IF (ISNULL(@summoney,0) > ISNULL(@balance,0))
    BEGIN
        INSERT INTO @table
        SELECT 1,1,'资金帐户余额不足！'
        
        RETURN
    END
END              

IF @formid IN (3155)
BEGIN
    DECLARE @temptable4  TABLE(docitem INT)              
    DECLARE @coacode4    VARCHAR(20),
            @accountid4  VARCHAR(20),
            @rowid4      INT              
    
    DECLARE CURSOR5                           CURSOR  
    FOR
        SELECT b.coacode,a.accountid,docitem  
        FROM   vFendperiodbusihd a
               INNER JOIN ocompany b ON  a.companyid = b.companyid AND a.doccode = 
                    @doccode 
    
    OPEN CURSOR5 
    
    FETCH NEXT FROM CURSOR5 
    INTO @coacode4,@accountid4,@rowid4                                                            
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT INTO @temptable4( docitem)
        SELECT DISTINCT docitem
        FROM   VFcountitemAll c
        WHERE  @accountid4 = c.acctcode
               AND @coacode4 = c.coacode              
        
        INSERT INTO @table
        SELECT 1,0,@accountid4 + '：请输入完整的辅助核算！'
        FROM   Fendperiodbusitem
        WHERE  docitem = @rowid4
               AND @accountid4 = accountid
               AND doccode = @doccode
               AND ((ISNULL(cv1,'') = ''
                        AND 1 IN (SELECT docitem
                                  FROM   @temptable4)
                    )
                       OR (ISNULL(cv2,'') = ''
                              AND 2 IN (SELECT docitem
                                        FROM   @temptable4)
                          )
                       OR (ISNULL(cv3,'') = ''
                              AND 3 IN (SELECT docitem
                                        FROM   @temptable4)
                          )
                       OR (ISNULL(cv4,'') = ''
                              AND 4 IN (SELECT docitem
                                        FROM   @temptable4)
                          )
                       OR (ISNULL(cv5,'') = ''
                              AND 5 IN (SELECT docitem
                                        FROM   @temptable4)
                          )
                   )              
        
        IF @@rowcount > 0
            RETURN
        ELSE
            DELETE 
            FROM   @temptable4 
        
        FETCH NEXT FROM CURSOR5 
        INTO @coacode4,@accountid4,@rowid4
    END 
    CLOSE CURSOR5 
    DEALLOCATE CURSOR5
END              

IF @formid IN (3101, 3113)
BEGIN
    INSERT INTO @table
    SELECT 1,1,'科目：' + AccountID + '辅助核算输入有误!请删除该行重新输入!'
    FROM   (SELECT AccountID,((CASE WHEN ISNULL(cv1,'') = '' THEN 0 ELSE 1 END) 
                    + (CASE WHEN ISNULL(cv2,'') = '' THEN 0 ELSE 2 END) 
                    + (CASE WHEN ISNULL(cv3,'') = '' THEN 0 ELSE 3 END) 
                    + (CASE WHEN ISNULL(cv4,'') = '' THEN 0 ELSE 4 END) 
                    + (CASE WHEN ISNULL(cv5,'') = '' THEN 0 ELSE 5 END)
                   ) AS num
            FROM   vfgldoc WITH (NOLOCK)
            WHERE  doccode = @doccode
           ) a
           LEFT OUTER JOIN (SELECT acctcode,ISNULL(SUM(DocItem),0) AS num
                            FROM   VFcountitemAll WITH (NOLOCK)
                            GROUP BY acctcode
                ) b ON  a.AccountID = b.acctcode
    WHERE  ISNULL(a.num,0) <> ISNULL(b.num,0)
           AND ISNULL(a.AccountID,'') <> ''              
    
    IF @@rowcount > 0
        RETURN
END 





--已集成过的单据不允许再集成。              
IF @formid IN (3111)
BEGIN
    INSERT INTO @table
    SELECT 1,1,'单据“' + a.refdoccode + '”已经集成过，不能再集成，请检查！'
    FROM   VFSubTGldoc a
           LEFT JOIN fsubledgerlog b ON  a.refdoccode = b.doccode 
                -- and a.refformid = b.formid --有问题再启用这句代码。
    WHERE  a.doccode = @doccode
           AND a.companyid = b.companyid
           AND b.loadflag = 1
    GROUP BY a.refdoccode
END 



--付款单(费用支出单)的凭证日期和发生的年月必须一致              
IF @formid IN (2063)
BEGIN
    DECLARE @glname    VARCHAR(50),
            @brand     VARCHAR(50),
            @periodid  VARCHAR(20)
    
    SELECT @glname = glname,@brand = brand,@periodid = periodid
    FROM   Fchargedocm
    WHERE  doccode = @doccode              
    
    IF dbo.getperiodidex(@glname,@brand) <> @periodid
    BEGIN
        INSERT INTO @table
        VALUES(1,1,'本单据凭证日期和发生的年月不一致,请重新输入' )
    END
END 


--新价成本调整单只能通过确认"功能复制"的哪张单              

-- if @formid in (1512)              
-- begin              
--               
--  insert into @table              
--             select 1,1,'在新价成本调整单中,只有表头:自动生成是:"功能复制完成" 的单才能确认!'              
--                     from imatdoc_h where isnull(usertxt2,'1')='1' and doccode=@doccode              
--                                 
-- end               


IF @formid IN (2054)
BEGIN
    INSERT INTO @table
    SELECT 1,1,'帐户转帐单不能由店面转店面!'
    FROM   Fcashdoc
    WHERE  companyid <> '1'
           AND companyid2 <> '1'
END               

IF @formid IN (2063)
BEGIN
    DECLARE @amount MONEY              
    SELECT @amount = SUM(amount)
    FROM   fchargedocd
    WHERE  doccode = @doccode
    
    INSERT INTO @table
    SELECT 1,1,
           '付款单(费用支出单)的付款帐号为:(100120)财务虚拟现金账,结算方式必须是:非现金业务'
    FROM   Fchargedocm a
           LEFT JOIN fchargedocd b ON  a.doccode = b.doccode
    WHERE  a.fcashaccount = '100120'
           AND (a.payway <> '非现金业务' OR ISNULL(@amount,0) <> 0)
           AND a.doccode = @doccode
END 
--防止单据中的商品数量与串号处理中的商品数量不一致 
IF @formid IN (2424)
BEGIN
    ;WITH ctea AS(SELECT b.matcode,COUNT(seriescode) AS digit
                  FROM   iseriesloghd a,iserieslogitem b
                  WHERE  a.DocCode = b.doccode
                         AND a.refCode = @doccode
                  GROUP BY b.matcode
    )
    , cteb AS(SELECT matcode,SUM(digit) AS digit
              FROM   spickorderitem
              WHERE  DocCode = @doccode
              GROUP BY MatCode
    )
    INSERT INTO @table
    SELECT 1,1,'单据商品[' + a.matcode + ']数量和串号数量不一致,请检查!'
    FROM   cteb a,ctea b
    WHERE  a.MatCode = b.matcode
           AND a.Digit <> b.digit
END

IF @formid IN (1507)
BEGIN
    --串号和商品数量不一致
    ;WITH ctea AS(SELECT b.matcode,COUNT(seriescode) AS digit
                  FROM   iseriesloghd a,iserieslogitem b
                  WHERE  a.DocCode = b.doccode
                         AND a.refCode = @doccode
                  GROUP BY b.matcode
    )
    , cteb AS(SELECT matcode,SUM(digit) AS digit
              FROM   imatdoc_d
              WHERE  DocCode = @doccode
              GROUP BY MatCode
    )
    INSERT INTO @table
    SELECT 1,1,'单据商品[' + a.matcode + ']数量和串号数量不一致,请检查!'
    FROM   cteb a
           FULL JOIN ctea b ON  a.MatCode = b.matcode
    WHERE  a.Digit <> b.digit
           AND @doccode = 'DR20110929000130'
    --数量为零
    INSERT INTO @table
    SELECT 1,1,'第' + CONVERT(VARCHAR(5),docitem) + '项商品数量不能为零!'
    FROM   imatdoc_d
    WHERE  DocCode = @doccode
           AND Digit = 0
END

IF @formid IN (2424)
BEGIN
    --数量为零
    INSERT INTO @table
    SELECT 1,1,'第' + CONVERT(VARCHAR(5),docitem) + '项商品数量不能为零!'
    FROM   sPickorderitem sph
    WHERE  DocCode = @doccode
           AND Digit = 0
END
--严格控制调入数量不得大于调出数量
IF @formid IN (1507)
BEGIN
    ;WITH ctea AS(SELECT matcode,SUM(digit) AS digit
                  FROM   imatdoc_d
                  WHERE  doccode = @doccode
                  GROUP BY matcode
    )
    INSERT INTO @table
    SELECT 1,1,b.MatName + '调入数量大于出库数量,请检查!'
    FROM   ctea a
           RIGHT JOIN sPickorderitem b ON  a.matcode = b.matcode AND b.DocCode = 
                @refcode
    WHERE  a.digit > b.digit
END
--严格限制重复项
IF @formid IN (1507)
BEGIN
    IF EXISTS(SELECT matcode
              FROM   imatdoc_d a
              WHERE  a.doccode = @doccode
              GROUP BY matcode
              HAVING (COUNT(*) > 1)
       )
    BEGIN
        INSERT INTO @table
        SELECT 1,1,'单据中有重复的商品,请检查!'
    END
END
--加盟商串号导入
	if @FormID in(1152)
		begin
			--检查是否有仓库
			insert into @table
			select 1,1,'第'+convert(varchar(10),docitem)+'行串号未匹配商仓库,无法导入,请尝试按工号匹配仓库!'
			from iserieslogitem where doccode=@doccode
			and isnull(stcode,'')=''
			--若未匹配到仓库,则直接退回,不再往下执行
			if @@rowcount>0 return
			--检查仓库是否正确
			insert into @table
			select 1,1,'第'+convert(varchar(10),docitem)+'行仓库不存在,请检查!'
			from iserieslogitem a 
			where doccode=@doccode
			and not exists(select 1 from ostorage where stcode=a.stcode)
			--检查串号是否正确
			INSERT INTO @table
			SELECT 1,1,'第'+convert(varchar(10),docitem)+'行串号长度不正确,请检查!'
			FROM iserieslogitem i,iMatGeneral img
			WHERE i.doccode=@doccode
			AND img.MatCode=i.matcode
			and LEN(i.seriescode)<>img.MatImeiLong
			--检查串号是否存在
			insert into @table
			select 1,1,'第'+convert(varchar(10),docitem)+'行串号已在系统中,请检查!'
			from iserieslogitem a 
			where doccode=@doccode
			and   exists(select 1 FROM iseries x WITH(NOLOCK) where x.SeriesCode=a.seriescode)
		end
	if @formid in(9246)
		begin
			--判断警告信息
			insert into @table
			select 1,1,'第'+convert(varchar(5),docitem)+'行TAC码['+i.seriescode+']长度不足6位,不允许导入.'
			 from iserieslogitem i
			where i.doccode=@doccode
			and len(isnull(i.seriescode,''))<6
			select @RowCount=isnull(@@ROWCOUNT,0)
			--若当前导入的TAC码比已有的TAC码短,但是大类级别比已有TAC码更细,则禁止导入,需要选择更高级别的大类,或调整原有TAC码的大类级别.
			insert into @table
			select 1,1,'第'+convert(varchar(5),docitem)+'行TAC码['+i.seriescode+']已存在更精确的TAC码['+t.taccode+'],但本次导入的TAC大类信息比它的大类级别更低.请选择更高级别的大类,或调整['+t.taccode+']的大类级别.'
			from iserieslogitem i with(nolock),T_TACCode t,iMatGroup img
			where i.doccode=@doccode
			and t.TACCode like i.seriescode+'_%'									--导入的TAC比已有TAC码更短
			and i.Matgroup=img.matgroup											--获取导入TAC的大类级别
			and img.PATH like '%/'+t.Matgroup+'/%'								--但是导入的TAC码大类级别比已有大类级别更低
			select @RowCount=isnull(@RowCount,0)+isnull(@@ROWCOUNT,0)
			--若当前导入的TAC码比已有TAC码长,而当前TAC的大类却比已有TAC码的大类级别高,则禁止导入.需要将当前TAC码的大类设置到更细才允许导入.
			insert into @table
			select 1,0,'第'+convert(varchar(5),docitem)+'行TAC码['+i.seriescode+']已存在型号级别更高的TAC码['+t.taccode+'],本次导入TAC码将不会影响到原TAC码的商品信息.'
			from iserieslogitem i with(nolock),T_TACCode t,iMatGroup img
			where i.doccode=@doccode	
			and i.seriescode like t.TACCode+'_%'									--导入的TAC比已有TAC码更长
			and t.Matgroup=img.matgroup
			and img.PATH like '%/'+i.Matgroup+'/%'								--但是导入TAC的大类比已有TAC的大类级别更高
			select @RowCount=isnull(@RowCount,0)+isnull(@@ROWCOUNT,0)
			--若已经有禁用项,则不再显示提示项,防止提示项过多,影响用户浏览.
			if @Rowcount>0 return
			--下面显示提示信息
			insert into @table 
			select 1,0,'第'+convert(varchar(5),docitem)+'行TAC码['+i.seriescode+']已存在,,本次导入将覆盖原有信息.'
			from iserieslogitem i with(nolock),T_TACCode t
			where i.doccode=@doccode
			and i.seriescode=t.TACCode
			insert into @table
			select 1,0,'第'+convert(varchar(5),docitem)+'行TAC码['+i.seriescode+']已存在更精确的TAC码['+t.taccode+'],本次导入TAC码将无法影响到原TAC码的商品信息.'
			from iserieslogitem i with(nolock),T_TACCode t
			where i.doccode=@doccode
			and t.TACCode like i.seriescode+'_%'
			insert into @table
			select 1,0,'第'+convert(varchar(5),docitem)+'行TAC码['+i.seriescode+']已存在型号级别更高的TAC码['+t.taccode+'],本次导入TAC码将不会影响到原TAC码的商品信息.'
			from iserieslogitem i with(nolock),T_TACCode t
			where i.doccode=@doccode
			and i.seriescode like t.TACCode+'_%'
			
		end
RETURN 
END