/*                                  
* 函数名称：fn_QueryDocWaitForAudit                            
* 功能描述：查询待审核的放号单据                
* 参数:见声名部分                                  
* 编写：三断笛                                  
* 时间：2010/06/22                                 
* 备注：                
* 示例：
begin tran
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
select * from fn_QueryDocWaitForAudit('2012-12-01','2012-12-29','','','','','','','','开户审核')   
 rollback
* --------------------------------------------------------------------                                  
* 修改：                                  
* 时间：                                  
* 备注：
* 
*/                 
 
ALTER FUNCTION [fn_QueryDocWaitForAudit]        
(        
 @beginday      DATETIME,        
 @endday        DATETIME,        
 @doccode       VARCHAR(8000),        
 @doctype       VARCHAR(20),        
 @sdorgid       VARCHAR(30),        
 @seriesnumber  VARCHAR(8000),        
 @customercode  VARCHAR(20),        
 @checkstate    VARCHAR(20),        
 @usercode      VARCHAR(20),        
 @checkType  VARCHAR(20)        
)        
RETURNS @table TABLE(OrderNum INT,doctype VARCHAR(60), --业务类型              
         docdate DATETIME, --单据日期              
         doccode VARCHAR(2000), --单号              
         formid INT, --功能号              
         seriesnumber VARCHAR(2000), --手机号              
         areaid VARCHAR(200),areaname VARCHAR(100),sdorgid VARCHAR(300), --门店编码              
         sdorgname VARCHAR(220), --门店名称              
         sdgroup VARCHAR(200), --发展人              
         sdgroupname VARCHAR(500), --发展人              
         grade VARCHAR(300), --客户类型              
         customercode VARCHAR(20), --客户编码              
         customerName VARCHAR(60), --客户姓名              
         sex VARCHAR(500), --性别              
         VoucherType VARCHAR(300), --证件类型              
         VoucherCode VARCHAR(500), --证件编码              
         ValidDate VARCHAR(200), --有效期              
         PhoneNumber VARCHAR(600), --联系电话              
         post VARCHAR(300), --邮编              
         VoucherAddress VARCHAR(500), --证件地址              
         curAddress VARCHAR(500), --当前住址              
         combocode VARCHAR(200), --套餐编码               
         comboName VARCHAR(300), --套餐名称              
         comboFEEType VARCHAR(500), --资费类型              
         cardNumber VARCHAR(500), --ＳＩＭ卡号                
         IPhonePhone VARCHAR(200), --是否Iphone开户              
         SeriesCode VARCHAR(300), --手机串号              
         Phonerate MONEY, --              
         price MONEY,serviceFEE MONEY,otherFEE MONEY,CardFEE MONEY,packagedName         
         VARCHAR(200),PackageFEE MONEY,totalmoney MONEY,checkstate VARCHAR(200),        
         Remark VARCHAR(500),formtype INT,blacklist INT,Consumptioncount INT,        
         applyer VARCHAR(500),applyerName VARCHAR(500),audits VARCHAR(200),        
         Auditingname VARCHAR(500),PreAllocation BIT,BSSUserCode VARCHAR(200),        
         Auditingdate DATETIME,Intype VARCHAR(200),BBSID VARCHAR(500),        
         usertxt1 VARCHAR(500),usertxt2 VARCHAR(500),ESSID VARCHAR(500),systemOption INT,      
         OpenSdgroup VARCHAR(500),OpenSdgroupName VARCHAR(500),usertxt3 VARCHAR(500),  
   ESSIDT VARCHAR(500),UserTxt5 VARCHAR(500),Usertxt6 VARCHAR(500),SeriesESSID varchar(500),instanceID varchar(50)
        )        
AS        
--select * from dbo.fn_QueryDocWaitForAudit('2011-09-13','2011-09-18','','','','','','','SYSTEM','运营商一次审核')        
        
BEGIN        
 SELECT @seriesnumber=REPLACE(@seriesnumber,CHAR(10)+CHAR(13),',')   --将回车换行符替换成逗号        
 SELECT @seriesnumber=REPLACE(@seriesnumber,CHAR(10),',')     --将回车符替换成逗号        
 SELECT @seriesnumber=REPLACE(@seriesnumber,CHAR(13),',')     --将换行符替换成逗号        
 SELECT @seriesnumber=REPLACE(@seriesnumber,';',',')       --将分号替换成逗号        
 SELECT @seriesnumber=REPLACE(@seriesnumber,CHAR(9),',')      --将TAB替换成逗号        
 --SELECT docstatus, usertxt2, * from unicom_orders where seriesnumber='18665109856'        
 --用CTE先取得销售单和套包单                
 ;WITH cte_doc(doctype,docdate,doccode,formid,seriesnumber,sdorgid,sdorgname,        
  sdgroup,sdgroupname,customercode,vouchercode,customername,combocode,        
  comboname,comboFEEtype,CardNumber,IPhonePhone,SeriesCode,Phonerate,price,        
  serviceFEE,otherFEE,CardFEE,packagename,Packageprice,totalmoney,checkstate,        
  remark,formtype,applyer,applyerName,audits,Auditingname,preallocation,        
  Auditingdate,intype,hasCard,systemoption,openSdgroup,OpenSdgroupName,usertxt5,usertxt6,
  --客户资料
   grade,sex,vouchertype,ValidDate ,PhoneNumber,zipcode,VoucherAddress,curAddress,instanceid
 )AS(SELECT CASE       
                 WHEN psh.preallocation  =1 THEN psh.doctype+'(预开户)'        
                 WHEN psh.FormID IN(9102,9237) and ISNULL(psh.PackageID,'')='' THEN '客户新入网'      
                 WHEN psh.FormID IN(9146,9237) and ISNULL(psh.PackageID,'')!='' THEN '套包销售'      
                 ELSE psh.doctype        
            END, psh.docdate, psh.doccode, psh.formid, psh.seriesnumber, psh.sdorgid, psh.sdorgname,         
            psh.sdgroup, psh.sdgroupname, psh.cltcode, psh.usertxt2, psh.cltname, psh.combocode,         
            psh.comboname, psh.comboFEEtype,case 
																		when isnull(cardmatname,'') like '%成%卡%' then LEFT(iccid,19)+'(成卡)'
																		else iccid
																	end,
             matname, seriescode, phonerate, CASE packageid        
                                                                WHEN  'TBD2011061300001' THEN  price- 200        
                                                                ELSE price        
                                                           END, servicefee,         
            otherfee, matname, ph.packagename, packageprice, UserDigit4, checkstate,         
            psh.HDText, case when psh.formid in (9102,9146) then 5 else 16 end, psh.applyer, applyerName, audits, Auditingname,         
            psh.preAllocation, psh.Auditingdate, intype,CASE WHEN ISNULL(psh.ICCID,'')='' THEN 0 ELSE 1 END,0,psh.OpenSdgroup,psh.OpensdgroupName ,     
            usertxt5,usertxt6,
              NULL,psh.sex,psh.vouchertype,psh.ValidDate ,psh.PhoneNumber,psh.zipcode,psh.drivername,psh.ContactAddress,psh.InstanceID
     FROM   Unicom_Orders psh  
       left join policy_h ph WITH(NOLOCK) on psh.PackageID=ph.DocCode
     WHERE  psh.FormID IN (9102, 9146,9237,9244)        
     --AND psh.DocStatus= CASE when @checktype = '开户审核' then 0 ELSE 100 END        
	AND checkstate =CASE WHEN @checkType='开户审核' then  '待审核' ELSE '通过审核' END
	union ALL
	/*
	doctype,docdate,doccode,formid,seriesnumber,sdorgid,sdorgname,        
  sdgroup,sdgroupname,customercode,vouchercode,customername,combocode,        
  comboname,comboFEEtype,CardNumber,IPhonePhone,SeriesCode,Phonerate,price,        
  serviceFEE,otherFEE,CardFEE,packagename,Packageprice,totalmoney,checkstate,        
  remark,formtype,applyer,applyerName,audits,Auditingname,preallocation,        
  Auditingdate,intype,hasCard,systemoption,openSdgroup,OpenSdgroupName,usertxt5,usertxt6,
  --客户资料
   grade,sex,vouchertype,ValidDate ,PhoneNumber,zipcode,VoucherAddress,curAddress
   */
	SELECT doctype,docdate,doccode,formid,seriesnumber,psh.sdorgid,psh.sdorgname,psh.sdgroup,psh.sdgroupname,    
   customercode,vouchercode,customername,NULL ,comboname,NULL,ICCID,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,totalmoney,
   checkstate,remark,16,psh.applyer,applyerName,audits, psh.Auditingname,0,psh.Auditingdate,NULL,NULL,systemoption,psh.OpenSdgroup,psh.OpenSdgroupName,NULL as usertxt5, NULL as usertxt6,
   null,psh.Sex,psh.VoucherType,psh.ValidDate,psh.PhoneNumber,psh.ZipCode,psh.VoucherAddress,psh.CurAddress,psh.InstanceID
   FROM BusinessAcceptance_H   psh WITH(nolock)
   WHERE psh.FormID in(9158,9160,9165,9167,9180,9153,9159) 
     AND checkstate =CASE WHEN @checkType='开户审核' then  '待审核' ELSE '通过审核' END
 )               
 INSERT INTO @table        
 SELECT ROW_NUMBER() OVER(ORDER BY hascard desc,Auditingdate asc), doctype, docdate, doccode, formid, a.seriesnumber, o.areaid, ga.areaname,  a.sdorgid,         
        o.sdorgname, a.sdgroup, a.sdgroupname, a.grade, a.customercode,         
        customername, a.sex, a.VoucherType, a.VoucherCode, CASE LEFT(a.seriesnumber, 3)        
                                                                WHEN '186' THEN         
                                                                     CONVERT(VARCHAR(20), a.ValidDate, 112)        
                                                                ELSE CONVERT(VARCHAR(20), validdate, 120)        
                                                           END, a.PhoneNumber,         
        a.zipcode, a.VoucherAddress, a.curAddress, combocode, comboname, a.comboFEEtype,         
        a.cardnumber, IPhonePhone, a.seriescode, a.phonerate, a.price, a.servicefee, a.otherfee,         
        0, a.packagename, a.Packageprice, totalmoney, checkstate, a.remark,         
        formtype, 0 as BlackList, 0 as ConsumptionCount, a.applyer, a.applyerName,         
        audits, Auditingname, preallocation, o.ExternalAdminID, Auditingdate,         
        intype, o.BBSID, o.usertxt1,case when o.dpttype='加盟店' then d.ESSID else  o.usertxt2 end,      
        case when o.dpttype='加盟店' then esspass else  o.ESSID end,systemoption,      
        a.openSdgroup,a.OpenSdgroupName,o.usertxt3,o.ESSIDT,a.usertxt5,a.usertxt6,'',instanceid
 FROM   cte_doc a
        LEFT JOIN oSDOrg o  WITH (NOLOCK) ON  a.sdorgid = o.sdorgid        
     LEFT JOIN gArea ga  WITH (NOLOCK) ON o.AreaID=ga.areaid        
     left join osdgroup d  WITH (NOLOCK) on a.sdgroup=d.sdgroup        
 WHERE  a.docdate BETWEEN @beginday AND @endday        
     AND (@usercode='system' OR  EXISTS(SELECT 1 FROM NumberAllocationAudits naa  WITH (NOLOCK) outer APPLY commondb.dbo.SPLIT(isnull(naa.areaid,''),',') x         
               WHERE   naa.usercode=@usercode AND( isnull(naa.areaid,'')='' or ga.[PATH] LIKE '%/'+isnull(x.list,'')+'/%' ))        
                )        
        AND (@doccode='' OR exists(select 1 from  commondb.dbo.split(@doccode,',')  WHERE list=a.doccode))        
        AND (@doctype='' OR a.doctype=@doctype)        
        AND (@sdorgid='' OR a.sdorgid=@sdorgid)        
        AND (@seriesnumber='' OR a.seriesnumber IN (SELECT list FROM  commondb.dbo.split(@seriesnumber,',' )  ))        
        AND (@customercode='' OR a.customercode=@customercode)        
        AND (@checkstate='' OR a.checkstate=@checkstate) 
                    
      AND  (         
        (@checktype='开户审核'         
         and (isnull(a.Audits,@usercode) =@usercode         
         or @usercode='system'         
         or exists(select 1 from NumberAllocationAudits where usercode=@usercode and showALldoc=1)))        
        OR   (@checktype IN('运营商一次稽核','运营商二次稽核')  and OPENSDGROUP  <>'SYSTEM')    
                 and a.formid in(9102,9146,9237)
                )            
        ORDER BY hascard desc,Auditingdate asc        
        
   --更新SIM卡信息
           
  /* UPDATE a        
   SET    cardNumber = uod.seriescode        
   FROM   Unicom_OrderDetails uod  WITH(NOLOCK), imatgroup b WITH(NOLOCK),   @table a    
   WHERE  a.doccode = uod.DocCode        
    AND uod.MatGroup=b.matgroup        
       AND EXISTS(SELECT 1 FROM dbo.fn_sysGetNumberAllocationConfig('SIM卡大类') x WHERE b.path LIKE '%/'+x.propertyvalue+'/%')        
   AND a.formid IN(9102,9146)
*/
     
   --更新手机绑定的ESSID  select essid,* from iseries where seriescode='013024001938567'
   --update e set SeriesESSID=s.ESSID from @table e left join iseries s WITH(NOLOCK) on e.SeriesCode=s.seriescode where isnull(s.ESSID,'')<>''  
 
 --如果限制显示单据信息,则隐藏部门和套包        
 if EXISTS(SELECT 1 FROM NumberAllocationAudits naa WITH (NOLOCK) WHERE naa.Usercode=@usercode AND naa.hideDocInfo=1)   
	BEGIN
		 UPDATE @table         
		  SET sdorgname = NULL,        
		  packagedName = NULL,        
		  totalmoney=NULL,        
		  price = NULL, 
		  applyer = NULL,        
		  formtype = 0,        
		  applyerName = NULL,        
		  comboname=NULL,        
		  IPhonePhone=NULL,        
		  SeriesCode = NULL        
		 WHERE Auditingname IS NULL     
	END
 IF @checkType = '运营商一次稽核'
 BEGIN
     DELETE @table
     FROM   @table a
     WHERE  EXISTS(SELECT 1
                   FROM   CheckNumberAllocationDoc_LOG b WITH (NOLOCK)
                   WHERE  a.doccode = b.doccode
                          AND b.checkType = '运营商一次稽核'
                          AND checkstate = '通过审核'
            )
     
     DELETE @table
     WHERE  docdate < '2012-03-29'
 END
 
 IF @checkType = '运营商二次稽核'
 BEGIN
     DELETE @table
     FROM   @table a
     WHERE  EXISTS(SELECT 1
                   FROM   CheckNumberAllocationDoc_LOG b WITH (NOLOCK)
                   WHERE  a.doccode = b.doccode
                          AND b.checkType = '运营商二次稽核'
                          AND checkstate = '通过审核'
            )
     
     DELETE @table
     FROM   @table a
     WHERE  NOT EXISTS(SELECT 1
                       FROM   CheckNumberAllocationDoc_LOG b WITH (NOLOCK)
                       WHERE  a.doccode = b.doccode
                              AND b.checkType = '运营商一次稽核'
                              AND b.checkstate = '通过审核'
            )
            AND not EXISTS(SELECT 1
                           FROM   CheckNumberAllocationDoc_LOG b WITH (NOLOCK)
                           WHERE  a.doccode = b.doccode
                                  AND b.checkType = '开户审核'
                                  AND b.checkstate = '通过审核'
                                  AND EnterName = 'SYSTEM'
                )
     
     DELETE @table
     WHERE  docdate < '2012-03-29'
 END 
    RETURN
 
 END