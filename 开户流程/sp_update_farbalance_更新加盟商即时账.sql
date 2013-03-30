/*    
select e.debit,b.debit,e.credit,b.credit,*     
--update e set debit=b.debit,credit=b.credit     
from farbalance e left join (select companyid,periodid,cv1,glcode,sum(amount_debit)debit,sum(amount_credit)credit    
from fsubledgerlog group by companyid,periodid,cv1,glcode) b on e.companyid=b.companyid and e.periodid=b.periodid    
and e.cltcode=b.cv1 and e.account=b.glcode where (isnull(e.debit,0)<>isnull(b.debit,0) or isnull(e.credit,0)<>isnull(b.credit,0))    
and e.cltcode in (select sdorgid from osdorg where osdtype='º”√À') and e.account='113107'    
*/    
alter PROC [dbo].[sp_update_farbalance](@doccode VARCHAR(50))                
AS                
BEGIN  
 SET NOCOUNT ON                
   
 UPDATE e  
 SET    debit =CASE   
         
     when s.FormID IN(9244) THEN (isnull(e.debit,0)-isnull(s.totalmoney2,0))  
     else isnull(e.debit,0)+isnull(s.totalmoney2,0)  
               END,  
       credit = case   
      when s.FormID IN(9244) THEN (isnull(e.credit,0)-(ISNULL(s.commission,0)+isnull(s.deductamout,0)+ISNULL(s.rewards ,0))   )  
      ELSE isnull(e.credit,0)+(ISNULL(s.commission,0)+isnull(s.deductamout,0)+ISNULL(s.rewards ,0))     
     end  
 FROM   Unicom_Orders s  
        LEFT JOIN oSDOrg g ON  s.sdorgid = g.sdorgid  
        LEFT JOIN osDOrg o ON  g.parentrowid = o.rowid  
        LEFT JOIN farbalance e ON  o.sdorgid = e.cltcode  AND s.periodid = e.periodid  AND   
             e.companyid = s.companyid  
 WHERE  s.doccode = @doccode  
        AND s.dpttype = 'º”√ÀµÍ'  
        AND account = '113107'             
   
 IF @@rowcount = 0  
 BEGIN  
     INSERT INTO farbalance( companyid, periodid, cltcode, account, debit,   
            credit)  
     SELECT s.companyid, s.periodid, o.sdorgid, '113107',  
     CASE   
   WHEN s.FormID IN(9244) then -ISNULL(s.totalmoney2, 0)  
      else ISNULL(s.totalmoney2, 0)  
     END,  
     CASE  
   WHEN s.FormID IN(9244) THEN -(ISNULL(s.commission, 0) +isnull(s.deductamout,0)+ ISNULL(s.rewards, 0))  
   ELSE (ISNULL(s.commission, 0) +isnull(s.deductamout,0)+ ISNULL(s.rewards, 0))  
  END  
     FROM   Unicom_Orders s  
            LEFT JOIN oSDOrg g ON  s.sdorgid = g.sdorgid  
            LEFT JOIN osDOrg o ON  g.parentrowid = o.rowid --and o.sdorgid=s.sdorgid --and s.periodid=e.periodid and e.companyid = s.companyid  
     WHERE  s.doccode = @doccode  
            AND s.dpttype = 'º”√ÀµÍ' --and account='113107'  
 END          
   
 UPDATE farinstbalance  
 SET    balance =CASE s.FormID  
      WHEN 9244 THEN -(ISNULL(balance, 0) -ISNULL(s.totalmoney2, 0) +isnull(s.deductamout,0)+ (ISNULL(s.commission, 0) + ISNULL(s.rewards, 0)))  
      else ISNULL(balance, 0) -ISNULL(s.totalmoney2, 0) +isnull(s.deductamout,0)+ (ISNULL(s.commission, 0) + ISNULL(s.rewards, 0))  
     end  
 FROM   Unicom_Orders s  
        LEFT JOIN oSDOrg g ON  s.sdorgid = g.sdorgid  
        LEFT JOIN osDOrg o ON  g.parentrowid = o.rowid  
        LEFT JOIN farinstbalance e ON  o.sdorgid = e.cltcode  AND e.companyid =   
             s.companyid  
 WHERE  s.doccode = @doccode  
        AND s.dpttype = 'º”√ÀµÍ'  
        AND account = '113107'  
END