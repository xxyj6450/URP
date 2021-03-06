set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

--select * from vfarledgerlog where cltcode in (select * from getinstr('010100003'))            
            
---drop table zpp            
---select *  from freeperiodfarlog('1','2006-07-01','2006-07-26','','010100003','','')            
            
ALTER               function [dbo].[freeperiodfarlog2]            
                                    (@companyid  varchar(200),            
     @cltcode varchar(50),          
                                      @beginday datetime,            
                          @endday   datetime )            
returns @table table(            
cltname varchar(100),            
companyid varchar(50),            
glcode varchar(50),            
subcode varchar(50),            
dcflag varchar(100),             
amount_debit money,             
amount_credit money,            
totalamount money,             
formid varchar(10),             
formname varchar(50) ,             
doctype varchar(120),             
doccode varchar(50),             
docitem varchar(50),             
detail varchar(200),             
docdate datetime,             
cltcode varchar(50),             
gltype varchar(120),             
fhsum money,            
thsum money, --新增备注            
sksum money,  --已核金额            
preamount money,          
prebalance money,          
balance money)          
as            
begin          
declare @prebalance money,@endbalance money          
      --select * from dbo.freeperiodfarlog2('101','2.1.769.290','2010-10-01','2010-10-13')    
  select @prebalance = -dbo.getfarprebalance1(@companyid,@cltcode,'113107',@beginday)    
  --select @prebalance = dbo.getfarbalance(@companyid,@cltcode,'113107',@beginday)            
  select @endbalance = dbo.getfarbalance1(@companyid,@cltcode,'113107',@endday)     
      --select dbo.getfarbalance1('101','2.1.769.290','2010-10-01','2010-10-13')        
  insert into @table(docdate,formname,prebalance,cltcode,companyid)            
  values (@beginday,'期初余额',-isnull(@prebalance,0),@cltcode,@companyid)            
          
 insert into @table(cltname, companyid, glcode, subcode, dcflag,amount_debit, amount_credit,totalamount, formid, formname, doctype,doccode, docitem, detail,  docdate, cltcode, gltype,fhsum,thsum,sksum,preamount)          
      select cv1name, companyid, glcode, subcode, dcflag,             
      amount_debit, amount_credit,(amount_debit- amount_credit) totalamount, formid, formname, doctype,             
      doccode, docitem, detail,  docdate, cv1, gltype,null as fhsum,null as thsum,null as sksum,null as preamount--, checkedmoney,nocheckmoney,  sdorgid,sdorgname              
from fsubledgerlog  b            
where docdate between @beginday and @endday             
and (@companyid ='' or companyid in (select * from getinstr(@companyid)))            
and (@cltcode = '' or b.cv1 in (select * from getinstr(@cltcode)))            
--and  ( @sdorgid=''  or  b.sdorgid in (            
--select cc.sdorgid from osdorg  aa,dbo.getinstr(@sdorgid) bb,osdorg cc             
--where aa.sdorgid=bb.list and left(cc.treecontrol,len(aa.treecontrol))=aa.treecontrol   ) )             
and b.glcode='113107'  order by docdate,doccode        
 --计算错误注释掉   
insert into @table(docdate,formname,balance,cltcode,companyid)            
  values (@endday,'期末余额',-isnull(@endbalance,0),@cltcode,@companyid)        
            
          
--计算期末余额            
 declare @amount_debit money,             
       @amount_credit money,@doccode varchar(50)            
            
declare cur cursor scroll             
 for select amount_debit,amount_credit,doccode from @table             
 where doccode is not null  order by docdate,doccode            
 declare @i money            
 declare @G money            
              
 select @G=@prebalance            
 open cur            
  fetch first  from cur  into @amount_debit,@amount_credit,@doccode            
 while @@fetch_status=0              
 begin             
               
  update @table set balance=@G-@amount_debit+@amount_credit where doccode=@doccode            
 select @G=@G-@amount_debit+@amount_credit       
    
     fetch next from cur into @amount_debit,@amount_credit,@doccode            
 end            
            
 close cur            
 deallocate cur 
return          
end          
--select * from vfarledgerlog where glcode='113107'          
/*           
--and ( @artype = '' or charindex('调整',@artype) <> 0 and formid = 2040             
--or charindex('收款',@artype) <> 0 and formid in (2041,2055)            
--or charindex('销售',@artype)<> 0 and not formid in (2040,2041,2055))            
and ( @checktype =''            
 or     @checktype='全部'             
 or (charindex('已核销',@checktype) <> 0 and isnull(nocheckmoney,0)=0 )            
 or (charindex('未核销',@checktype) <> 0 and isnull(nocheckmoney,0)<>0 ))             
            
           
insert into @table            
select gltype, companyid,companyname, glcode, vndcode,vndname, dcflag, amount_debit,             
      case  formname when '往来付款单' then -amount_debit  else amount_credit end,             
amount_credit-amount_debit totalamount, formname, doctype, itemtype, doccode, docdate, detail, formid,             
      docitem, docrowid, nodetail,checkedmoney,nocheckmoney,            
case formname when '供应商返利单' then '返利补差款' when '供应商补差应收'  then '返利补差款'             
when '采购入库' then '采购款' when '采购退货' then '采购款' else '其它款' end as fapType            
 from vfpleadgerlog            
where (@compid='' or companyid in (select * from getinstr(@compid))) and            
          ( @vndid='' or vndcode in (select * from  getinstr(@vndid)))  and             
           docdate between @beginday and @endday            
and (@fapType=''            
 or charindex('采购款',@fapType)<>0 and formname in ('采购入库','采购退货')            
 or charindex('返利补差款',@fapType)<>0 and formname in ('供应商返利单','供应商补差应收')            
 or charindex('其它款',@fapType)<>0 and formname in ('应付款调整单','往来付款单')            
*/            
            
          
        
      
    
  
