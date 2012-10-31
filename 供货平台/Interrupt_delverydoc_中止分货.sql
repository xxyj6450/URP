--中止分货单  
-- exec Interrupt_deliverydoc 'FHD2012092900000','URP12','管理员','DD20120929000001'  
-- exec Interrupt_deliverydoc 'FHD2012092900040','URP12','管理员','DD20120929000021'  
-- exec Interrupt_deliverydoc 'FHD2012092802760','URP51','管理员','DD20120928000420'
-- exec Interrupt_deliverydoc 'FHD2012100200000','URP12','管理员','DD20121002000001'  
CREATE PROC Interrupt_deliverydoc  
(@doccode VARCHAR(50),@source VARCHAR(50),@user VARCHAR(50),@refcode VARCHAR(50)  
)  
AS  
SET NOCOUNT ON  
SET XACT_ABORT ON  
BEGIN  
 DECLARE @gooddoccode VARCHAR(50),@sdorgid VARCHAR(50),@Source1 VARCHAR(50),@companyid VARCHAR(50)  
 DECLARE @sql VARCHAR(2000)  
 DECLARE @formid VARCHAR(50)  
 SELECT @companyid=companyid FROM fh_deliverydoc WHERE doccode=@doccode        
 SELECT @Source1=ODBC FROM VisitConfig WHERE companyid=@companyid  
 raiserror('此功能已取消,禁止操作.',16,1)
 return
 SELECT @gooddoccode=refcode,@sdorgid=sdorgid FROM fh_deliverydoc WHERE doccode=@doccode  
 if left(@refcode,2)='DD' SET @formid='6090'  
 IF left(@refcode,2)<>'DD' SET @formid='6091'  
  --SELECT top 1 docstatus,* FROM fh_deliverydoc WHERE doccode='FHD2012100200000'
 IF EXISTS(SELECT 1 FROM fh_deliverydoc WHERE doccode=@doccode AND docstatus=0)
 BEGIN
 	RAISERROR('单据未确认，不允许中止！',16,1)
 	return
 END  
 --检查是否已送货  
 IF EXISTS(SELECT 1 FROM fh_deliverydoc WHERE doccode=@doccode AND FHstatus='已发货')  
 BEGIN  
  RAISERROR('此分货单已发货，不能中止流程！',16,1)  
  RETURN  
 END  
 ELSE  
 BEGIN  
  DELETE imatdoc_h WHERE isnull(usertxt3,'')=@doccode  
  --处理原单，作标识  
  UPDATE fh_deliverydoc SET memo='中止分货单'+@user+convert(varchar(20),getdate(),120) WHERE doccode=@doccode  
 END  
 PRINT @Source  
 PRINT @doccode  
 --执行取消确认分货单  
 --exec sp_caceldeliverydoc @doccode,@Source  
 set @sql='update l set canceldigit=isnull(canceldigit,0)-isnull(m.digit,0),fitnum=isnull(fitnum,0)-isnull(m.digit,0)--,salesprice=isnull(n.price,0)                             
        from '+@Source+'.'+@Source1+'.dbo.ord_shopbestgoodsdtl l,fh_deliverydtl m,fh_deliverydoc n                   
 where m.doccode='''+@doccode+''' and m.doccode=n.doccode and l.matcode=m.matcode and l.doccode=n.refcode'    
 --PRINT '1:'+    @sql                          
 exec(@sql)                
                               
 ---更新明细金额                                
 set @sql='update '+@Source+'.'+@Source1+'.dbo.ord_shopbestgoodsdtl set totalmoney=isnull(ask_digit,0)*isnull(salesprice,0) 
           where doccode in(select refcode from fh_deliverydoc where doccode='''+@doccode+''')'              
 --PRINT '2:'+    @sql
 exec(@sql)
 ---更新表头汇总数据
 set @sql='update a set docdigit=b.digit,SumNetMoney=b.totalmoney                                
        from '+@Source+'.'+@Source1+'.'+'dbo.ord_shopbestgoodsdoc a,                                
          (select doccode, sum(canceldigit) digit,sum(totalmoney) totalmoney from '+@Source+'.'+@Source1+'.dbo.ord_shopbestgoodsdtl  
			where  doccode in(select refcode from fh_deliverydoc where doccode='''+@doccode+''')         
           group by doccode) b where a.doccode=b.doccode'         
 --PRINT '3:'+    @sql         
 exec(@sql)                  

 set @sql='update '+@Source+'.'+@Source1+'.'+'dbo.ord_shopbestgoodsdoc   set phflag=''未处理'' where doccode in(select refcode from fh_deliverydoc where doccode='''+@doccode+''')'                          
 exec(@sql)               
 --PRINT '4:'+    @sql             
 --set @sql='update fh_deliverydoc set docstatus=0 where doccode='''+@doccode+''''              
 --exec(@sql)      
 --执行作废订单  
 SELECT @sql=@source+'.'+@Source1+'.dbo.sp_updatetpoff '+@formid+','''+@refcode+''','''+@sdorgid+''','''+@user+''','''''  
 --PRINT '5:'+    @sql     
 EXEC (@sql)  
 --EXEC(URP12.URPDB01.dbo.sp_updatetpoff 6090,'FHD2012092900000','2.1.769.03.11','管理员','')  
 --SELECT * FROM oSDOrgCredit WHERE sdorgid='2.769.517'  
END