/*                                                                
* 函数名称：fn_checkAllocationDoc                                                  
* 功能描述：运营商模块单据检查函数                                              
* 参数:见声名部分                                                                
* 编写：三断笛                                                                
* 时间：2010/06/22                                                               
* 备注：                                              
* 示例：select * from [fn_checkAllocationDoc](9128,'CST2011080700162')                                                 
                            
* --------------------------------------------------------------------                                                                
* 修改：                                                                
* 时间：                                                                
* 备注：                                                                
*                                                                 
*/                                               
ALTER FUNCTION [fn_checkAllocationDoc]              
(              
 @formid   INT,              
 @doccode  VARCHAR(50)              
)              
RETURNS @table TABLE (warnflag INT,errorflag INT,infomessage VARCHAR(4000))              
AS              
                                                   
BEGIN              
 /*****************************************************************公共变量声名区开始********************************************/                                              
 DECLARE @tips            VARCHAR(4000),              
         @seriesnumber    VARCHAR(20),              
         @stcode          VARCHAR(20),              
         @preallocation   BIT,              
         @seriesCode      VARCHAR(30)              
               
 DECLARE @refcode         VARCHAR(20),              
         @refformid       INT,              
         @FileName        VARCHAR(500),              
         @sdorgid         VARCHAR(50),              
         @areaid          VARCHAR(50),              
         @NoNeedAllocate  BIT              
               
 DECLARE @birthday        DATETIME,              
         @voucherType     VARCHAR(50),              
         @voucherCode     VARCHAR(50),              
         @customerGrade   VARCHAR(20),              
         @company         VARCHAR(200),              
         @CompanyLicense  VARCHAR(50),              
         @validDate       DATETIME,              
         @grade           VARCHAR(50),              
         @curaddress      NVARCHAR(800),              
         @docDate         DATETIME,              
         @phoneNumber     VARCHAR(50),              
         @phoneNumber1    VARCHAR(50),              
         @customerName    VARCHAR(50),              
         @intype          VARCHAR(50),              
         @NodeCode        VARCHAR(20),              
         @Address         VARCHAR(500),              
         @checkState      VARCHAR(20),              
         @dpttype         VARCHAR(50),              
         @docstatus       INT,              
         @CltCode         VARCHAR(50),              
         @cltName         VARCHAR(50),            
         @Minage    int            
               
 /*****************************************************************公共变量声名结束********************************************/               
               
 /*****************************************************************号码录入单检验开始********************************************/                                              
 IF @formid IN (9118, 9138)--号码录入单              
 BEGIN              
 if @formid in (9118)            
 begin            
  insert into @table            
  SELECT 1, 1,'号码'+sd.seriesnumber+'已在号码池,不允许重复导入.'            
         FROM Seriespool_D sd WHERE sd.DocCode=@doccode             
         AND EXISTS(SELECT 1 FROM seriespool s WITH(NOLOCK) WHERE sd.SeriesNumber=s.SeriesNumber)              end            
            
     --预开户号码必须绑定套餐并输入卡号                                              
     INSERT INTO @table              
     SELECT 1,1,'第' + CONVERT(VARCHAR(4),sd.docitem) + '为预开户,必须输入框套餐信息及SIM卡信息.'              
     FROM   Seriespool_D sd              
     WHERE  sd.DocCode = @doccode              
     AND ISNULL(sd.oldcode,0) = 0              
            AND sd.preAllocation = 1              
            AND ISNULL(sd.ComboName,'') = ''            
     --非预开户号码不允许录入卡号套餐等资料                                              
     INSERT INTO @table              
     SELECT 1,0,'第' + CONVERT(VARCHAR(4),sd.docitem) +               
            '行不是预开户号码,不需要录入套餐及SIM信息,当前录入的相关数据将不会录入号码池.'              
     FROM   Seriespool_D sd              
     WHERE  sd.DocCode = @doccode              
            AND sd.preAllocation = 0              
            AND ISNULL(sd.ComboName,'') <> ''               
     --检测输入的套餐及区域是否全法                                              
     INSERT INTO @table              
     SELECT 1,1,'第' + CONVERT(VARCHAR(4),a.docitem) + '项中套餐信息[' + a.comboname + ']不存在或套餐信息有误,请重新选择正确的套餐!'              
     FROM   seriespool_d a              
            LEFT  JOIN Combo_H ch ON  a.Comboname = ch.Comboname              
     WHERE  a.DocCode = @doccode              
            AND ISNULL(ch.ComboName,'') = ''              
            AND ISNULL(a.ComboName,'') <> ''               
     -- select * from combo_h where comboname='3G 96元B套餐'              
     --检测输入的归属地是否合法 select * from g                                              
     INSERT INTO @table              
     SELECT 1,1,'第' + CONVERT(VARCHAR(4),a.docitem) + '项中归属地信息[' + a.areaid + ']不存在,请重新选择正确的归属地!'              
     FROM   Seriespool_D a              
            LEFT JOIN gArea g ON  a.AreaID = g.areaid              
     WHERE  a.DocCode = @doccode              
            AND (g.areaid IS NULL AND ISNULL(a.areaid,'') <> '')               
     --检查串号是否存在                                                  
     INSERT INTO @table              
     SELECT 1,1,'第' + CONVERT(VARCHAR(4),a.docitem) + '项中SIM卡[' + ISNULL(a.cardnumber,'') + ']不存在或已售,请重新输入正确的SIM卡!'              
     FROM   Seriespool_D a              
            LEFT JOIN iSeries g  WITH(NOLOCK) ON  a.cardnumber = g.SeriesCode              
     WHERE  a.DocCode = @doccode              
            AND ((g.SeriesCode IS NULL OR g.[state] = '已售')              
                    AND ISNULL(a.cardnumber,'') <> ''              
                )               
     /*--检查串号长度                                              
     INSERT INTO @table                                              
     SELECT 1,1,'第'+CONVERT(VARCHAR(4),a.docitem) +'项中SIM卡['+isnull(cardnumber,'')+']非预开户号码,SIM卡号长度不正确.'                                               
     FROM Seriespool_D a                                               
     WHERE (preallocation=19 AND LEN(isnull(a.CardNumber,''))<>19                                              
     OR (preallocation=0 and LEN(isnull(a.CardNumber,''))<>0))                                  
     and a.DocCode=@doccode*/               
     --已经存在的号码而且已经被门店所选中的,不会导入号码池,提示用户                                              
     INSERT INTO @table              
     SELECT 1,0,'第' + CONVERT(VARCHAR(4),a.docitem) + '项中号码正在被使用中,此次入库将不会导入或修改这些号码.'              
     FROM   Seriespool_D a              
     WHERE  EXISTS(SELECT 1              
                   FROM   SeriesPool sp  WITH(NOLOCK)              
                   WHERE  a.SeriesNumber = sp.SeriesNumber              
                          AND sp.[STATE] = '已选'              
            )              
            AND a.DocCode = @doccode              
 END               
 /*****************************************************************号码录入单检验结束********************************************/               
               
 /*****************************************************************客户新入网检验开始********************************************/                                              
 IF @formid IN (9102, 9146,9237,9244) --客户新入网单              
 BEGIN              
     SELECT @sdorgid = sdorgid,@docDate = uo.DocDate,@Seriesnumber =               
            seriesnumber,@stcode = stcode,@NoNeedAllocate = uo.NONeedAllocate,              
            @preallocation = uo.preAllocation,@checkState = uo.checkState,@dpttype =               
            uo.dptType,@docstatus = docstatus,@CltCode = uo.cltCode,@cltName =               
            uo.cltName,@voucherCode = uo.usertxt2              
     FROM   Unicom_Orders uo  WITH(NOLOCK)              
     WHERE  uo.DocCode = @doccode                
	if isnull(@checkState,'')<>'通过审核'
		BEGIN
			insert into @table
			select 1,1,'单据尚未通过审核,不允许确认.'
			return
		END
end
if @formid in(9102,9146,9237)
begin
     INSERT INTO @table              
     SELECT 1,1,a.matcode + '  ' + ISNULL(SeriesCode,'') + '串号长度为' + CONVERT(VARCHAR(10),LEN(ISNULL(SeriesCode,''))) + '位不对应该是' + CONVERT(VARCHAR(6),b.MatImeiLong) + '位'             FROM   Unicom_OrderDetails a  WITH(NOLOCK),imatgeneral b              
     WHERE  a.doccode = @doccode              
            AND a.matcode = b.matcode              
            AND LEN(ISNULL(a.SeriesCode,'')) <> b.MatImeiLong              
            AND b.MatFlag = 1              
            AND ISNULL(MatImeiLong,0) <> 0           
                   
     --零售销售单（退）无串号管理的商品不可录入串号                                                
     INSERT INTO @table              
     SELECT 1,1,a.matcode + '不是串号管理商品，不可以录入串号'              
     FROM   Unicom_OrderDetails a  WITH(NOLOCK),imatgeneral b              
     WHERE  a.doccode = @doccode              
            AND a.matcode = b.matcode              
 AND b.MatFlag = 0              
            AND ISNULL(RTRIM(LTRIM(SeriesCode)),'') <> ''              
            AND b.MatCode NOT IN ('1.08')               
     --       select * from Unicom_OrderDetails where doc              
     --select stcode,* from update Unicom_OrderDetails set stcode='1.4.769.09.05' where doccode='ps20100913000011' and isnull(stcode,'')=''              
     --零售销售单有串号管理的商品的串号需满足在库条件              
     --select stcode,* from Unicom_OrderDetails where doccode='PS20100917000011'              
     --    select stcode,* from Unicom_Orders where doccode='PS20100917000011'              
     --select stcode,* from spickorderitem where doccode='RE20100917000317'                                  
     INSERT INTO @table              
     SELECT 1,1,'串号' + CONVERT(VARCHAR(50),ISNULL(a.SeriesCode,'')) + '不在仓库，项号：' + CONVERT(VARCHAR(6),docitem) + ', 不能出库确认，请检查！'              
     FROM   Unicom_OrderDetails a  WITH(NOLOCK),imatgeneral b              
     WHERE  a.seriescode NOT IN (SELECT seriescode              
                                 FROM   iseries  WITH(NOLOCK)              
                                 WHERE  stcode = @stcode              
                                        AND matcode = a.matcode              
                                        AND STATE = '在库')              
            AND a.matcode = b.matcode              
            AND a.doccode = @doccode              
            AND ISNULL(a.seriescode,'') <> ''              
            AND b.MatFlag = 1              
            AND ISNULL(@dpttype,'') <> '加盟店'              
     ORDER BY a.seriescode,a.docitem               
     /*                                            
     --再次检查仓库！                                      
     insert into @table select 1,1,'表头仓库和明细仓库不相同，不能确认！请联系系统管理员！'                                      
     from  Unicom_OrderDetails s left join Unicom_Orders u on s.doccode=u.doccode                                      
     where u.doccode=@doccode and isnull(s.stcode,'')<>isnull(u.stcode,'')                                      
     */               
                   
                   
     --取预开户的信息                                              
     SELECT @preallocation = preallocation              
     FROM   SeriesPool sp  WITH(NOLOCK)              
     WHERE  sp.SeriesNumber = @seriesnumber               
     --取预开户的白卡,以串号表中的信息为准                  
     IF @preallocation = 1              
         SELECT @seriescode = seriescode              
         FROM   iSeries i  WITH(NOLOCK)              
         WHERE  i.Seriesnumber = @seriesnumber              
                   
    /* IF dbo.fn_checkSeriesnumber(@Seriesnumber) = 0              
        AND ISNULL(@NoNeedAllocate,0) = 0              
     BEGIN              
         --  select dbo.fn_checkseriesnumber('14529802155')                                              
         INSERT INTO @table              
         SELECT 1,1,'非法的手机号码,请重新输入!'              
     END   */            
     --检查单据状态是否可确认                                              
     IF NOT (ISNULL(@checkState,'') = '通过审核'  )              
     BEGIN              
         INSERT INTO @table              
         SELECT 1,1,'单据尚未通过审核,不允许确认.' +@checkState+convert(varchar(20),@docstatus)         
     END               
     --检查号码是否存在,需要提示用户                                              
     IF NOT EXISTS(SELECT 1              
                   FROM   SeriesPool sp  WITH(NOLOCK)              
                   WHERE  seriesnumber = @Seriesnumber              
        )              
     BEGIN              
         INSERT INTO @table              
         SELECT 1,0,'提示:号码[' + @seriesnumber + ']不在号码池.请慎重输入'              
     END          
     --检查有没有录入白卡                                              
     /*IF NOT EXISTS(SELECT 1 FROM Unicom_Orders uos left join Unicom_OrderDetails uod on uos.doccode=uod.doccode WHERE uod.DocCode=@doccode AND uod.matgroup1 IN(                                              
     SELECT propertyvalue FROM _sysNumberAllocationCfgValues snacv WHERE snacv.PropertyName='SIM卡大类') and uos.old=0)                                              
     BEGIN                                              
     INSERT INTO @table                                              
     SELECT 1,1,'您还没有录入SIM卡信息,不能开户,新检查单据.'                                               
     END    */               
     --检查客户资料是否录入                                              
     INSERT INTO @table              
     SELECT 1,1,'您未录入完整的客户资料!'              
     WHERE  (--@cltcode IS NULL              
                --OR           
                @cltname IS NULL              
                OR @voucherCode IS NULL              
            )               
     --检查客户资料录入单是否确认               
     /*INSERT INTO @table              
     SELECT 1,1,'客户资料单据录入单尚未确认,不能确认该单.'              
     FROM   Customers_H ch  WITH(NOLOCK)              
     WHERE  ch.RefCode2 = @doccode              
            AND ch.RefFormID = @formid              
            AND customercode IS NULL  */             
     --检查单据客户信息是否与客户资料录入单一致                                              
     /*INSERT INTO @table                                              
     SELECT 1,1,'您录入的客户信息与客户资料登记单不一致,请修改客户信息或删除客户资料登记单!'                                              
     FROM Unicom_Orders uo inner JOIN Customers_H ch  ON uo.DocCode=ch.RefCode                                              
     AND uo.cltCode<>ch.CustomerCode                                               
     AND uo.DocCode=@doccode*/               
     --检查预开户的号码白卡是否正确                                              
     /*IF @preallocation = 1              
     BEGIN              
         INSERT INTO @table              
         SELECT 1,1,'预开户白卡输入不正确!'              
         FROM   unicom_orderdetails  WITH(NOLOCK)              
         WHERE  doccode = @doccode              
                AND matgroup1 IN (SELECT propertyvalue              
                                  FROM   _sysNumberAllocationCfgValues snacv              
                                  WHERE  snacv.PropertyName = 'SIM卡大类')              
                AND seriesCode <> @seriesCode              
     END*/            
     --限制有串号的商品销售数量不能大于1                                              
     IF EXISTS(SELECT 1              
               FROM   Unicom_OrderDetails uod  WITH(NOLOCK)              
               WHERE  uod.DocCode = @doccode              
                      AND ISNULL(uod.seriesCode,'') <> ''              
                      AND uod.Digit > 1              
        )              
     BEGIN              
         INSERT INTO @table              
         SELECT 1,1,'有串码的商品销售数量不能大于1个!'              
     END               
     --无效的商品编码不允许录入录入                                              
    /* INSERT INTO @table              
     SELECT 1,1,b.matname + '为无效的商品编码，请检查'              
     FROM   Unicom_OrderDetails b  WITH(NOLOCK)              
            INNER JOIN imatgeneral c ON  b.MatCode = c.matcode              
     WHERE  b.doccode = @doccode              
            AND b.matcode = c.matcode              
            AND c.isactived = 0              
            AND @DocDate >= '2010-08-20'   */            
     --封库的商品不允许销售                                              
     INSERT INTO @table              
     SELECT 1,1,'该商品串号已封库，不能销售，请更换串号销售!'              
     FROM   Unicom_OrderDetails a  WITH(NOLOCK)              
            INNER JOIN iseries i  WITH(NOLOCK) ON  a.seriescode = i.seriescode              
     WHERE  i.fk = 1              
            AND a.doccode = @doccode               
     ;WITH cte AS(SELECT @doccode AS doccode,@stcode AS stcode,b.matcode,SUM(b.digit) AS               
                         digit              
                  FROM   Unicom_OrderDetails b  WITH(NOLOCK)              
                  WHERE  b.DocCode = @doccode              
                         AND ISNULL(@dpttype,'') <> '加盟店'              
                  GROUP BY doccode,stcode,b.matcode              
     )               
     --库存不足，不允许确认                                        
     INSERT INTO @table              
     SELECT 1,1,'您输入的商品[' + ig.matname + ']库存不足，请仔细检查!'              
     FROM   iMatStorage is1  WITH(NOLOCK)              
            INNER JOIN cte uod ON  is1.matcode = uod.MatCode AND is1.stCode =               
                 uod.stcode              
            INNER JOIN iMatGeneral ig ON  uod.MatCode = ig.MatCode              
     WHERE  ig.MatState = 1              
            AND ISNULL(is1.unlimitStock,0) < ISNULL(uod.Digit,0)              
            AND uod.DocCode = @doccode              
 END               
  /*          
if @formid in (9146)            
begin            
 insert into @table            
 select 1,1,'组合商品单不允许使用优惠券！！！'            
 from Unicom_Orders d WITH(NOLOCK) left join Unicom_OrderDetails m WITH(NOLOCK) on d.doccode=m.doccode            
 where d.doccode=@doccode and ISNULL(d.packagecode,'')<>'' and isnull(m.Deductamout,0)<>0            
end     */       
            
 --延保功能控制                
 IF @formid IN (9146)              
 BEGIN              
     --延保的串号不能不在明细表中                
     INSERT INTO @table              
     SELECT 1,1,'延保串号[' + a.seriescode + ']与销售串号不一致.'              
     FROM   SeriesCode_HD a              
     WHERE  a.FormID = 2445              
            AND a.Refcode = @doccode              
            AND NOT EXISTS(SELECT 1              
                           FROM   Unicom_OrderDetails b  WITH(NOLOCK)              
                           WHERE  b.DocCode = @doccode              
                                  AND a.SeriesCode = b.seriesCode              
                )               
     --延保产品不一致                
     INSERT INTO @table              
     SELECT 1,1,'销售单据延保产品与延保单延保产品不一致'              
     FROM   SeriesCode_HD a              
     WHERE  a.formid = 2445              
            AND a.RefCode = @doccode              
            AND NOT EXISTS(SELECT 1              
                           FROM   Unicom_OrderDetails b  WITH(NOLOCK)              
                           WHERE  a.ExtendWarrantyMatcode = b.MatCode              
                                  AND b.DocCode = @doccode              
                )               
     --延保单必须要确认                
     INSERT INTO @table    
     SELECT 1,1,'延保单尚未确认,请先确认延保单.'              
     FROM   SeriesCode_HD sch  WITH(NOLOCK)              
     WHERE  sch.RefCode = @doccode              
            AND sch.FormID = 2445              
            AND sch.DocStatus = 0              
    --必须有延保单              
    IF EXISTS(SELECT 1 FROM Unicom_OrderDetails uod  WITH(NOLOCK) WHERE uod.DocCode=@doccode and uod.MatName LIKE '%延保%' and digit>0)              
    AND NOT EXISTS(SELECT 1 FROM SeriesCode_HD sch WHERE sch.RefCode=@doccode)              
  BEGIN              
   INSERT INTO @table              
   SELECT 1,1,'您选择了延保产品但是尚未制延保单,请单击窗中顶部的[延保]按钮制延保单'              
  END              
 END               
 --检查配件券                
 IF @formid IN (9102, 9146)              
 BEGIN              
     INSERT INTO @table              
     SELECT 1,1,'您输入的配件券' + ISNULL(a.couponsbarcode,'') + '不在库或已赠送'              
     FROM   unicom_orderdetails a  WITH(NOLOCK)              
            LEFT JOIN icoupons b ON  a.couponsbarcode = b.couponsbarcode              
            LEFT JOIN Coupons_H ch ON ch.refcode=a.DocCode AND b.DeducedDoccode=ch.Doccode              
     WHERE  a.doccode = @doccode              
     AND ISNULL(a.couponsbarcode,'') <> ''              
     AND b.CouponsCode='1001'            
   AND (              
     (ch.Doccode IS NULL                 
       AND ISNULL(b.state,'') <> '在库'              
       )              
                 
   )             
   --SELECT * FROM iCoupons ic WHERE ic.CouponsBarcode='66911050017505'              
   --SELECT RefCode, * FROM Coupons_h WHERE Doccode='QDH2012010100038'              
                 
     INSERT INTO @table              
     SELECT 1,1,'您输入的配件券重复！'              
     FROM   unicom_orderdetails  WITH(NOLOCK)              
     WHERE  doccode = @doccode              
            AND ISNULL(CouponsBarCode,'') <> ''            
     GROUP BY couponsbarcode              
     HAVING (COUNT(couponsbarcode) > 1)              
                   
     INSERT INTO @table              
     SELECT 1,1,'配件券抵扣金额不得大于配件券面额，且不得大于实收金额的50%'              
     FROM   unicom_orderdetails a  WITH(NOLOCK),icoupons b              
     WHERE  a.doccode = @doccode              
            AND a.couponsbarcode = b.couponsbarcode              
            AND (a.deductamout > ISNULL(b.price,0)              
                    OR a.deductamout > ISNULL(a.price,0) / 2              
            )            
   AND b.CouponsCode='1001'            
     INSERT INTO @table              
     SELECT 1,1,'配件券仅能抵扣配件!'              
     FROM   unicom_orderdetails a  WITH(NOLOCK)              
            LEFT JOIN iMatGroup img ON  a.MatGroup = img.matgroup            
            INNER JOIN iCoupons i ON a.CouponsBarCode=i.CouponsBarcode            
     WHERE  doccode = @doccode              
            AND ISNULL(a.couponsbarcode,'') <> ''              
            AND NOT EXISTS(SELECT * FROM dbo.fn_sysGetNumberAllocationConfig('配件券相关_可用商品大类') x WHERE img.path LIKE '%/'+x.propertyvalue+'/%')              
            AND i.CouponsCode='1001'            
     --配件券必须绑定手机              
     INSERT INTO @table              
     SELECT TOP (1) 1,1,'配件券必须绑定手机!'              
     FROM   unicom_orderdetails a inner join iCoupons i ON a.CouponsBarCode=i.CouponsBarcode           
     WHERE  doccode = @doccode              
            AND ISNULL(a.couponsbarcode,'') <> ''              
            AND i.CouponsCode='1001'            
            AND NOT EXISTS(              
             SELECT 1 FROM unicom_orderdetails b  WITH(NOLOCK) LEFT JOIN iMatGroup img ON b.MatGroup=img.matgroup WHERE a.DocCode=@DocCode              
             AND EXISTS(SELECT 1 FROM dbo.fn_sysGetNumberAllocationConfig('手机大类') x WHERE img.path LIKE '%/'+x.propertyvalue+'/%')              
             )              
 END               
 --检查预约编号                
 IF @formid IN (9102, 9146)              
 BEGIN              
     INSERT INTO @table              
     SELECT 1,1,'该客户为预约客户,请从预约客户服务做单'              
     FROM   Unicom_Orders a  WITH(NOLOCK),PotentialCustomer b  WITH(NOLOCK)              
     WHERE  a.UserTxt2 = b.VoucherCode              
            AND a.ReservedDoccode IS NULL              
            AND ISNULL(b.ReservedResult,'') IN ('成功')              
            AND ISNULL(b.[Status],'') IN ('预约成功', '预约成功,等待上门处理')              
            AND a.DocCode = @doccode              
            AND b.ReservationDate >= @docDate + 1              
 END              
               
 IF @formid IN (9102, 9146)              
 BEGIN              
     INSERT INTO @table              
     SELECT 1,1,'此商品' + m.matname +               
            '为代销配件，请到商品资料为此商品添加主代应商！'              
     FROM   Unicom_OrderDetails m  WITH(NOLOCK)              
            LEFT JOIN iMatGeneral l ON  m.matcode = l.matcode              
     WHERE  l.matgroup = 'P10'              
            AND doccode = @doccode              
            AND ISNULL(l.vndcode,'') = ''              
 END              
               
 IF @formid IN (9102, 9146)              
 BEGIN              
     --刷卡金额                                              
     INSERT INTO @table              
     SELECT 1,1,'刷卡商品中，刷卡金额不能小于0，请在填写正确的刷卡金额！'              
     FROM   Unicom_Orders d  WITH(NOLOCK)              
            LEFT JOIN Unicom_OrderDetails m  WITH(NOLOCK) ON  d.doccode = m.doccode              
     WHERE  d.doccode = @doccode              
            AND ISNULL(d.UserDigit2,0) <= 0              
            AND brush = 1               
     --发票号检查                                              
     DECLARE @cancelflag VARCHAR(50)                                              
     SELECT @cancelflag = cancelflag              
     FROM   spickorderhd              
     WHERE  doccode = @doccode              
            AND ISNULL(cancelflag,'') <> ''              
                   
     IF ISNULL(@cancelflag,'') <> ''              
         INSERT INTO @table              
         SELECT 1,1,'发票号已录入，不能重复录入'              
         FROM   Unicom_Orders  WITH(NOLOCK)              
         WHERE  doccode <> @doccode              
                AND cancelflag = @cancelflag              
                AND formid IN (9102, 9146)              
 END              
               
 IF @formid IN (9102, 9146)              
 BEGIN              
     INSERT INTO @table              
     SELECT 1,0,'单据中实收金额为0，并不是礼品或加价更换商品，是否确认'              
     FROM   Unicom_OrderDetails  WITH(NOLOCK)              
     WHERE  doccode = @doccode              
            AND ISNULL(totalmoney,0) = 0              
            AND ISNULL(gift,0) = 0              
 END                                               
               
 IF @formid IN (9102, 9146)              
 BEGIN              
     INSERT INTO @table              
     SELECT 1,1,'单据中实收金额不为0，礼品不能打勾，请确认！'              
     FROM   Unicom_OrderDetails uod  WITH(NOLOCK)              
   WHERE  doccode = @doccode              
            AND ISNULL(totalmoney,0) <> 0              
            AND ISNULL(gift,0) = 1              
            AND weave <> 1              
 END               
 --日结控制              
 --SELECT * FROM dbo.fn_checkAllocationDoc(9102,'RW20110516000056') fcad              
 --SELECT dbo.fn_getSDOrgConfig('2.1.769.285.01','LockCheckOut')                
               
 IF @formid IN (9102, 9146)              
    AND @doccode NOT IN ('PS20111128000741', 'PS20111125000637', 'PS20111206000719')              
    AND EXISTS(SELECT 1              
               FROM   Unicom_Orders  WITH(NOLOCK)              
               WHERE  doccode = @doccode              
                      AND ISNULL(node,0) = 0              
        )              
 BEGIN              
     INSERT INTO @table              
     SELECT 1,1,'单据当前日期已日结,不允许再制单!若要取消日结,请联系财务.'              
     FROM   Unicom_Orders a  WITH(NOLOCK),rj_baltag b,osdorg c  WITH(NOLOCK)              
     WHERE  a.DocCode = @doccode              
            AND b.checkflag = 1              
            AND CONVERT(VARCHAR(10),a.DocDate,120) = b.baldate              
            AND a.sdorgid = b.sdorgid              
            AND a.sdorgid = c.SDOrgID              
            AND c.reckoning = 1              
            AND dbo.fn_getSDOrgConfig(a.sdorgid,'LockCheckOut') = 1    AND docdate>'2012-09-23'           
                   
     INSERT INTO @table              
     SELECT 1,1,'门店前一天尚未日结,不允许制单,请先日结!'              
     FROM   rj_baltag b,osdorg c  WITH(NOLOCK)              
     WHERE  b.checkflag = 0              
            AND CONVERT(VARCHAR(10),@DocDate,120) > CONVERT(VARCHAR(10),b.baldate,120)              
            AND @sdorgid = b.sdorgid              
            AND @sdorgid = c.SDOrgID              
            AND c.reckoning = 1              
            AND dbo.fn_getSDOrgConfig(@sdorgid,'LockCheckOut') = 1    AND baldate>'2012-09-23'           
 END               
 --控制补卡和缴费                
 IF @formid IN (9158, 9167,9267)              
    AND @doccode NOT IN ('BK20111023000069')              
 BEGIN              
     INSERT INTO @table              
     SELECT 1,1,'单据当前日期已日结,不允许再制单!若要取消日结,请联系财务.'              
     FROM   BusinessAcceptance_H a  WITH(NOLOCK),rj_baltag b,osdorg c  WITH(NOLOCK)              
     WHERE  a.DocCode = @doccode              
            AND b.checkflag = 1              
            AND CONVERT(VARCHAR(10),a.DocDate,120) = b.baldate              
            AND a.SdorgID = b.sdorgid              
            AND a.sdorgid = c.SDOrgID              
            AND c.reckoning = 1              
            AND dbo.fn_getSDOrgConfig(a.sdorgid,'LockCheckOut') = 1   AND docdate>'2012-09-23'            
                   
     INSERT INTO @table              
     SELECT 1,1,'门店前一天尚未日结,不允许制单,请先日结!'              
     FROM   BusinessAcceptance_H a  WITH(NOLOCK),rj_baltag b,osdorg c  WITH(NOLOCK)              
     WHERE  a.DocCode = @doccode              
            AND b.checkflag = 0              
            AND CONVERT(VARCHAR(10),a.DocDate,120) > b.baldate              
            AND a.sdorgid = b.sdorgid              
            AND a.sdorgid = c.SDOrgID              
            AND c.reckoning = 1              
        AND dbo.fn_getSDOrgConfig(a.sdorgid,'LockCheckOut') = 1   AND docdate>'2012-09-23'           
 END               
               
 --SELECT * FROM rj_baltag rb ORDER BY rb.baldate desc              
 --不充许客户联系电话与受理号码一样                                            
               
 /*if @formid =9128                                             
 begin                                                
 insert into @table                                              
 select 1,1, '不充许客户联系电话与受理号码一样，请检查！'                                              
 FROM Customers_H  where    doccode=@doccode and  PhoneNumber=PhoneNumber1                                              
 end*/               
 /*****************************************************************客户新入网单检验结束********************************************/               
               
 --SELECT * FROM customers_h WHERE dbo.isValidSeriesNumber(PhoneNumber,0)=0 AND Formid=9128 AND customercode IS NOT NULL ORDER BY DocDate desc                
 /*****************************************************************客户资料修改和录入检验开始********************************************/                                              
 IF @formid IN (9128, 9136) --客户资料修改和录入              
 BEGIN              
     --取出单据中待检查信息                
     SELECT @vouchercode = vouchercode,@vouchertype = vouchertype,@birthday =               
            birthday,@company = company,@companyLicense = companyLicense,@grade =               
            grade,@seriesnumber = SeriesNumber,@validDate = ValidDate,@sdorgid =               
            developsdorgid,@phoneNumber = PhoneNumber,@phoneNumber1 =               
            PhoneNumber1,@refcode = refcode2,@curaddress = curAddress,@customerName =               
            NAME,@refformid=refformid2,@refcode=refcode2              
     FROM   customers_h WITH(NOLOCK)              
     WHERE  doccode = @doccode              
            AND formid = @formid              
                   
     SELECT @areaid = areaid              
     FROM   oSDOrg os  WITH(NOLOCK)              
     WHERE  os.SDOrgID = @sdorgid               
     --检查联系电话                
     IF dbo.isValidSeriesNumber(@phoneNumber,0) = 0              
            
     BEGIN              
         INSERT INTO @table              
         SELECT 1,1,              
                '您输入的联系电话'+isnull(@phoneNumber,'')+'格式不正确!,请输入正确的移动电话或固定电话,固话请按[区号](-)[电话](-)[分机号(可选)]格式录入,如076989972111'              
     END              
     if ISNULL(@phoneNumber1,'') <> ''              
               AND dbo.isValidSeriesNumber(@phoneNumber1,0) = 0              
             
     BEGIN              
         INSERT INTO @table              
         SELECT 1,1,              
                '您输入的联系电话'+isnull(@phoneNumber1,'')+'格式不正确!,请输入正确的移动电话或固定电话,固话请按[区号](-)[电话](-)[分机号(可选)]格式录入,如076989972111'              
     END               
     IF @phoneNumber = @seriesnumber              
        AND (SELECT ISNULL(old,0)              
             FROM   Unicom_Orders uo  WITH(NOLOCK)         
             WHERE  uo.DocCode = @refcode              
            ) = 0              
     BEGIN              
         INSERT INTO @table              
         SELECT 1,1,'联系电话不能为开户受理号码!'              
     END               
     --对身份证进行检查                     
             
     IF @vouchertype = '身份证'              
     BEGIN              
         /* IF EXISTS(SELECT 1              
                   FROM   CheckIDCard(@vouchercode)              
                   WHERE   convert(varchar(10),Birthday,120) <> convert(varchar(10),@birthday,120)            
            )              
         BEGIN              
             INSERT INTO @table              
             SELECT 1,1,'身份证出生日期与您录入的出生日期不一致!'  +convert(varchar(10),@birthday,120)+','+ISNULL(@vouchercode,'')            
         END    */            
         --检查身份证长度                 
         IF LEN(@VoucherCode) NOT IN (15, 18)              
         BEGIN              
             INSERT INTO @table              
             SELECT 1,1,'您输入的身份证号码长度不对，请检查！'              
         END               
         --检查身份证号码是否正确 select * from  customers                                              
         IF EXISTS(SELECT 1              
                   FROM   checkidcard(@vouchercode) b              
    WHERE  b.Valid = 0              
            )              
         BEGIN              
             INSERT INTO @table              
             SELECT 1,0,'您输入的身份证号码非法,请提供正确的身份证信息.'              
         END              
     END               
     --检查企业客户是否有录入营业执照,营业执照长度为13                
     IF @Grade IN ('VIP企业客户', '普通企业客户')              
        AND (ISNULL(@Company,'') = '' OR LEN(@CompanyLicense) < 13)              
     BEGIN              
         INSERT INTO @table              
         SELECT 1,1,'企业客户必须录入正确的公司信息及营业执照!'              
     END               
     --证件号码长度太短                
     IF LEN(@VoucherCode) < 6              
     BEGIN              
         INSERT INTO @table              
         SELECT 1,1,'您输入的证件号码太短!'              
     END               
                   
     --检查用户是否已经存在 select * from [fn_checkAllocationDoc](9128,'CST2010070500001')                 
     IF EXISTS(SELECT 1              
               FROM   Customers_H ch2 WITH(NOLOCK)              
               WHERE  ch2.VoucherCode = @VoucherCode              
                      AND ch2.doccode <> @doccode              
                      AND ISNULL(ch2.CustomerCode,'') <> ''              
        )              
     BEGIN              
         INSERT INTO @table              
         SELECT 1,1,'您录入的用户证件[' + @vouchercode +               
                ']已经在系统登记过,不需要重复登记!'              
     END               
                   
               
                   
     --限制用户上传图片大小不能超过50K delete customers where vouchercode like '%3615'                                               
     /*IF EXISTS(SELECT 1 FROM Customers_H ch WHERE ch.DocCode=@doccode AND DATALENGTH(ch.Photo)*1.0>200*1024)                         
                   
     BEGIN                                                                            
     INSERT INTO @table                                              
     SELECT 1,1,'上传的图像大小不能超过200KB,新重新上传!'                                              
     end*/               
     --限制用户上传图片大小不能超过小于5000字节                                              
     IF EXISTS(SELECT 1              
               FROM   Customers_H_files chf WITH(NOLOCK)              
               WHERE  chf.DocCode = @doccode              
                      AND chf.FileSize <= 5000              
        )               
        --OR EXISTS(SELECT 1 FROM Customers_H ch WITH(NOLOCK) WHERE ch.DocCode=@doccode AND DATALENGTH(ch.Photo)<=5000)  --2011-08-08 不再检查单据中图像控件中的照片 三断笛              
     BEGIN              
         --清空图像                                              
         INSERT INTO @table              
         SELECT 1,1,'您上传的图像清晰度不够,请使用更高的分辨率上传图片!'              
     END               
     --检查是否上传附件                
     IF dbo.fn_getSDOrgConfig(@sdorgid,'uploadvoucher') = 1 AND ISNULL(@refformid,'') NOT IN(9237)              
     BEGIN              
         IF NOT EXISTS(SELECT 1              
                       FROM   Customers_H a WITH(NOLOCK)              
                              INNER JOIN Customers_H_files b WITH(NOLOCK)ON  a.DocCode = b.DocCode AND a.DocCode = @doccode              
            )               
            --and exists(SELECT 1 FROM Customers_H ch WITH(NOLOCK) WHERE ch.DocCode=@doccode AND ch.Photo IS NULL) --2011-08-08 不再检查单据中图像控件中的照片 三断笛              
            AND @formid IN (9128)              
         BEGIN              
             INSERT INTO @table              
             SELECT 1,1,'您尚未上传客户证件资料,请重新上传!'              
         END              
     END               
     --检查附件格式                                              
     INSERT INTO @table              
     SELECT 1,1,'您上传的附件[' + chf.filename +               
            ']不是合法的图片,新删除后重新上传!'              
     FROM   Customers_H_files chf WITH(NOLOCK)              
     WHERE  chf.DocCode = @doccode              
            AND RIGHT(FILENAME,4) NOT IN (--'.jpg','.tif','.gif','.bmp','.png')                                              
                                         SELECT b.list              
                                         FROM   _sysNumberAllocationCfgValues               
                                                snacv              
                                                OUTER APPLY getinstr(snacv.propertyvalue) b       
                                         WHERE  snacv.PropertyName =               
                                                '附件格式限制')               
     --限制客户地址格式                
     INSERT INTO @table              
     SELECT 1,1,'您输入的“现地址”格式不正确,“现地址”请以：' + CASE areaid              
                                                                       WHEN               
                                                                            '755' THEN               
                                                                            '深圳市××区××镇(村路园厦)××号(室)%'              
                                                                       ELSE               
                                                                            '××市(州)××镇(区)××村××路(巷)××号'              
                                                                            +               
                                                                            '“格式录入'              
                                                                  END              
     FROM   oSDOrg WITH(NOLOCK)              
     WHERE  sdorgid = @sdorgid              
            AND ((areaid <> '755'              
        AND PATINDEX('%[市州县]%[镇区]%[路巷村]%号%',@curaddress) = 0              
                 )              
                    OR (areaid = '755'              
                           AND PATINDEX('%深圳市%区%[镇村路园厦]%[号室]%',@curaddress) = 0              
                       )              
  )               
                   
     --检查姓氏是否合法                
                   
     /*INSERT INTO @table              
     SELECT 1,1,b.remark --,hrc.doccode,hrc.name,hrc.vouchertype              
     FROM   customers_h hrc WITH(NOLOCK)              
            CROSS APPLY fn_CheckName(hrc.name) b              
     WHERE  b.valid = 0              
            AND hrc.vouchertype <> '护照'              
            AND hrc.Doccode = @doccode              
            AND @doccode NOT IN ('CST2010091800071')               
     */              
     --禁止18周岁以下用户操作            
                  
     SELECT @Minage=dbo.fn_getSDOrgConfig(@sdorgid,@Minage)             
     IF @Minage>0 and DATEDIFF(YEAR,@birthday,GETDATE()) < @Minage              
        --AND ISNULL(@areaid,'') NOT IN ('020', '574', '576', '576.01', '576.02', '576.03', '576.04', '791','020.01','020.02','020.03','020.04','020.05','020.06','020.07','020.08','020.09','020.10')              
     BEGIN            
            
         INSERT INTO @table              
         SELECT 1,1,'未满'+convert(varchar(10),@minage)+'周岁不允许办理此业务!'            
     END               
                 
     --证件有效期已过时不允许办理                
     IF @validDate <= GETDATE()              
     BEGIN              
         INSERT INTO @table              
         SELECT 1,1,'证件已过有效期，不允许办理此业务！'              
     END                
                   
                   
     /*IF EXISTS(SELECT 1              
               FROM   t_seriesnumberblacklist              
               WHERE  seriesnumber IN (ISNULL(@phoneNumber,''), ISNULL(@phoneNumber1,''))              
        )              
     BEGIN              
         INSERT INTO @table              
         SELECT 1,1,              
                '您输入的联系电话使用次数太多已被限制,请重新输入或联系系统管理员!'              
     END*/              
 END               
 /******************************************************************其他业务受理****************************************************/                                              
 IF @formid IN (9153, 9158, 9159, 9160, 9165, 9180) --过户              
 BEGIN              
     --检查手机号码是否合法                                  
     SELECT @seriesnumber = SeriesNumber,@sdorgid = bah.SdorgID,@customerName = CASE               
                                                 WHEN   formid IN (9153, 9159) THEN  customername1 ELSE customername END              
     FROM   BusinessAcceptance_H bah  WITH(NOLOCK)              
     WHERE  bah.docCode = @doccode              
                   
     IF dbo.isValidSeriesNumber(@Seriesnumber,2) = 0              
     BEGIN              
         --  select dbo.fn_checkseriesnumber('14529802155')                                              
         INSERT INTO @table              
         SELECT 1,1,'非法的手机号码,请重新输入!'              
     END               
     --检查单据审核状态                                              
     /*IF EXISTS(SELECT 1              
               FROM   BusinessAcceptance_H bah  WITH(NOLOCK)              
               WHERE  bah.docCode = 'BK201209200000621' --AND docstatus=0  
                      AND isnull(bah.CheckState,'') <> '通过审核'            
        ) */          
        IF EXISTS(SELECT 1 FROM BusinessAcceptance_H WHERE doccode=@doccode AND isnull(CheckState,'') <> '通过审核')     
   BEGIN              
     INSERT INTO @table              
     SELECT 1,1,'单据尚未通过审核,不允许确认!'              
    END                   
                   
     SELECT @areaid = areaid              
     FROM   oSDOrg os  WITH(NOLOCK)              
     WHERE  os.SDOrgID = @sdorgid              
                   
     IF @areaid = '769'              
     BEGIN              
         IF EXISTS(SELECT 1              
               FROM   BusinessAcceptance_H bah  WITH(NOLOCK)              
                   WHERE  bah.docCode = @doccode              
                          AND formid = 9158              
                          AND matcode <> '14.769.13'              
                          AND totalmoney = 0              
                          AND dptType <> '加盟店'              
            )              
         BEGIN            
             INSERT INTO @table              
             SELECT 1,1,'非ipad卡补卡金额不能为0,不允许确认!'              
         END              
     END/*IF EXISTS(SELECT 1 FROM t_seriesnumberblacklist WHERE seriesnumber=@seriesnumber)                
        BEGIN                
        INSERT INTO @table SELECT 1,1,'您输入的联系电话使用次数太多已被限制,请重新输入或联系系统管理员!'                
        END*/              
 END              
               
 IF @formid IN (9167,9267) --充值分门店和总部充值，门店充值不用提交              
 BEGIN              
     --检查手机号码是否合法                                              
     SELECT @seriesnumber = SeriesNumber,@intype = bah.intype              
     FROM   BusinessAcceptance_H bah  WITH(NOLOCK)              
     WHERE  bah.docCode = @doccode              
                   
     IF dbo.isValidSeriesNumber(@Seriesnumber,66) = 0              
     BEGIN              
         --  select dbo.fn_checkseriesnumber('14529802155')                             
         INSERT INTO @table              
         SELECT 1,1,'非法的手机号码,请重新输入!'              
     END               
                   
     --检查单据审核状态                                              
     IF EXISTS(SELECT 1              
               FROM   BusinessAcceptance_H bah  WITH(NOLOCK)              
               WHERE  bah.docCode = @doccode AND formid IN (9167,9267)             
                      AND (ISNULL(bah.CheckState,'') <> '通过审核')              
                      AND intype = '总部充值'              
        )              
     BEGIN              
         INSERT INTO @table              
         SELECT 1,1,'单据尚未通过审核,不允许确认!'              
     END              
                   
    /* IF EXISTS(SELECT seriesnumber,customername,COUNT(*)              
               FROM   BusinessAcceptance_H uo              
               WHERE  uo.SeriesNumber NOT IN (SELECT SeriesNumber              
                                              FROM   t_seriesnumberblacklist)              
                      AND uo.FormID = 9167              
                      AND uo.DocDate >= DATEADD(MONTH,-1,GETDATE())              
                     AND intype = '门店充值'              
                      AND uo.SeriesNumber = @seriesnumber              
                      AND uo.SeriesNumber <> '13138168380'              
               GROUP BY uo.SeriesNumber,uo.customername              
               HAVING COUNT(*) >= 15              
        )              
        AND @doccode NOT IN ('JF20111002000006', 'JF20111002000005',               
                            'JF20111002000355', 'JF20111002000191')              
         INSERT INTO @table              
         SELECT 1,1,              
                '您输入的受理号码本月操作次数太多被限制,请联系系统管理员!'              
                   
     IF EXISTS(SELECT 1              
               FROM   t_seriesnumberblacklist              
               WHERE  seriesnumber = @seriesnumber              
        )          AND @intype = '门店充值'              
        AND @doccode NOT IN ('JF20111002000355', 'JF20111002000191')              
     BEGIN              
         INSERT INTO @table              
         SELECT 1,1,              
                '您输入的联系电话使用次数太多已被限制,请重新输入或联系系统管理员!'              
     END */              
     --下面的检查有漏洞,需要重写 2011-08-20 三断笛              
     --检查加盟店不能确认单据  2010-12-01                
     /*if exists(select 1 from BusinessAcceptance_H where doccode=@doccode and isnull(CheckState,'')='' and dptType='加盟店')                                  
     begin                
     INSERT INTO @table    
     SELECT 1,1,'加盟店充值缴费,未提交审核，不允许确认!，请选择“总部充值”，再提交请求审核缴费！'                  
     end */               
     --2011-08-20 限制未通过审核及门店充值的加盟店业务不允许通过                
     IF EXISTS(SELECT 1              
               FROM   BusinessAcceptance_H  WITH(NOLOCK)              
               WHERE  doccode = @doccode              
                      AND (ISNULL(CheckState,'') <> '通过审核' OR intype = '门店充值')              
                      AND dptType = '加盟店'              
        )              
     BEGIN              
         INSERT INTO @table              
         SELECT 1,1,              
                '加盟店充值缴费,未提交审核，不允许确认!，请选择“总部充值”，再提交请求审核缴费！'              
     END               
     --检查空中充值                                        
     IF EXISTS(SELECT 1              
               FROM   BusinessAcceptance_H h  WITH(NOLOCK)              
                      LEFT JOIN imatgeneral l ON  h.matcode = l.matcode              
               WHERE  doccode = @doccode              
                      AND ISNULL(price,0) <> ISNULL(totalmoney,0)              
                      AND ISNULL(l.matgroup,'') = '4.03'              
        )              
     BEGIN              
         INSERT INTO @table              
         SELECT 1,1,'空中充值实收金额不允许修改'              
     END              
 END              
               
 IF @formid IN (9158) ---补卡              
 BEGIN              
     /*                                              
     SELECT @refcode=null                                              
     select @refformid =formid,@refcode=doccode from spickorderhd where refcode='&doccode&' and formid=2419                                              
     IF @refcode IS NULL                                              
     INSERT INTO @table                                              
     SELECT 1,1,'未生成补卡零售单,请重试!'                                              
     INSERT INTO @table                                              
     SELECT * FROM checkdocpost(@refformid,@refcode) */               
     --检查白卡是否在仓库                                               
     IF EXISTS(SELECT 1              
               FROM   iSeries i  WITH(NOLOCK)              
                      INNER JOIN BusinessAcceptance_H bah  WITH(NOLOCK) ON  (i.SeriesCode = bah.SimCode1 AND i.stcode = bah.Stcode)              
               WHERE  bah.docCode = @doccode              
                      AND i.state <> '在库'              
                      AND bah.dptType <> '加盟店'              
        )               
        --select dpttype,* from      BusinessAcceptance_H where doccode='BK20101015000004'              
     BEGIN              
         INSERT INTO @table              
         SELECT 1,1,'您选择的新白卡不在仓库1,请重新输入!'              
     END              
                   
     IF EXISTS(SELECT 1              
               FROM   iSeries i  WITH(NOLOCK)              
                      INNER JOIN BusinessAcceptance_H bah  WITH(NOLOCK) ON  (i.SeriesCode = bah.SimCode1 AND i.stcode = bah.Stcode)              
               WHERE  bah.docCode = @doccode              
                      AND i.state <> '应收'              
                      AND bah.dptType = '加盟店'              
        )              
     BEGIN              
         INSERT INTO @table              
         SELECT 1,1,'您选择的新白卡不在仓库2,请重新输入!'              
     END              
                   
     /*IF EXISTS(SELECT 1              
               FROM   iSeries i  WITH(NOLOCK)              
                      INNER JOIN BusinessAcceptance_H bah  WITH(NOLOCK) ON  (i.SeriesCode = bah.SimCode1 AND i.stcode = bah.Stcode)              
               WHERE  bah.docCode = @doccode              
                      AND i.state = '应收'              
                      AND ISNULL(i.isava,0) = 1              
                      AND bah.dptType = '加盟店'              
        )              
     BEGIN              
         INSERT INTO @table              
         SELECT 1,1,'您选择的新白卡不在仓库3,请重新输入!'      
     END */             
 END               
 --------------------------------------------------------------------------宽带业务------------------------------------------------------------                
 IF @formid IN (9224)              
 BEGIN              
     SELECT @voucherType = upa.VoucherType,@voucherCode = upa.VoucherCode,@NodeCode =               
            upa.NodeCode,@phoneNumber = upa.PhoneNumber,@Address = upa.InstallationAddress,              
  @customerName = upa.CustomerName              
     FROM   Unicom_PreAcceptance upa  WITH(NOLOCK)              
     WHERE  upa.Doccode = @doccode              
                   
     IF dbo.isValidSeriesNumber(@phoneNumber,0) = 0              
         INSERT INTO @table              
         SELECT 1,1,              
                '您输入的联系电话格式不正确!,请输入正确的移动电话或固定电话,固话请按[区号](-)[电话](-)[分机号(可选)]格式录入,如076989972111'              
                   
     IF @NodeCode IS NULL              
         INSERT INTO @table              
         SELECT 1,1,'尚未核实节点资源!'              
                   
     INSERT INTO @table              
     SELECT 1,1,b.remark              
     FROM   dbo.fn_CheckName(@customerName) b              
     WHERE  valid = 0              
            AND b.[LANGUAGE] IN (0, -1)              
            AND @customerName IS NOT NULL              
                   
     IF @voucherType = '身份证'              
     BEGIN              
         IF EXISTS(SELECT *              
                   FROM dbo.CheckIDCard(@voucherCode) ci              
               WHERE  ci.Valid = 0              
            )              
             INSERT INTO @table              
             SELECT 1,1,'您输入的证件编码未能通过系统检验,请重试!'            
     END              
 END              
               
 RETURN              
END