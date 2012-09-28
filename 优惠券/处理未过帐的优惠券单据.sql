--查询所有包括优惠券的单据
begin tran
declare @doccode varchar(20),@formid int
declare abc CURSOR FOR
select formid,uo.doccode--,uo.matcouponsbarcode,uod.couponsbarcode
from Unicom_Orders uo left join Unicom_OrderDetails uod on uo.DocCode=uod.DocCode
where ( isnull(uo.matCouponsbarcode,'')<>''
or isnull( uod.CouponsBarCode,'')<>''
)
and uo.DocDate>='2012-09-21'
and not exists(
	select  1 from Coupons_H ch where uo.DocCode=ch.RefCode)-- and ch.DocStatus!=0)
order by uo.DocDate
open abc
fetch next FROM abc into @formid,@doccode
while @@FETCH_STATUS=0
	BEGIN
		begin tran
		BEGIN TRY
			exec sp_PostCouponsDoc 'system','system',@formid,@doccode
			commit
		END TRY
		BEGIN CATCH
			 rollback
			 print error_message()
		END CATCH
		fetch next FROM abc into @formid,@doccode
	END
close abc
deallocate abc

commit
rollback
select * from iCoupons ic where ic.CouponsBarcode='66911050062451'

select  formid,uo.doccode,coalesce(nullif(uo.matcouponsbarcode,''),nullif(uod.couponsbarcode,''),''),case when isnull(uo.matCouponsbarcode,'')<>'' then uo.MatName else uod.MatName end
 from Unicom_Orders uo left join Unicom_OrderDetails uod on uo.DocCode=uod.DocCode
where ( isnull(uo.matCouponsbarcode,'')<>''
or isnull( uod.CouponsBarCode,'')<>''
)
and uo.DocDate>='2012-09-21'

and not exists(
	select  1 from Coupons_H ch where uo.DocCode=ch.RefCode and ch.DocStatus!=0)
and coalesce(uo.matcouponsbarcode,uod.couponsbarcode,'')<>''
order by uo.DocDate

select  deductamout,  * from Unicom_Orders uo where isnull(uo.matCouponsbarcode,'')<>''
and exists(select  1 from Unicom_OrderDetails uod where uo.DocCode=uod.DocCode and isnull(uod.CouponsBarCode,'')<>'')

select * from iCoupons ic where ic.CouponsBarcode='66911050059171'

select uod.CouponsBarCode,uod.DeductAmout,totalmoney, *
  from Unicom_OrderDetails uod where uod.DocCode='PS20120926000603'
begin tran
update Unicom_Orders
	set matDeductAmount = 0,
	DeductAmout = 28,
 
	matCouponsbarcode = null
where DocCode='PS20120926000603'
	
	commit
rollback
select  formid,uo.doccode,uo.matCouponsbarcode,uo.MatName
 from Unicom_Orders uo 
where  isnull(uo.matCouponsbarcode,'')<>''
and uo.DocDate>='2012-09-21'

begin tran
update iCoupons
	set State = '在库',
	remark='此券已出库,但门店又用此券制单,新系统上线,允许此券再次出库'
from 
(
select uo.DocCode, isnull(nullif(uo.matCouponsbarcode,''),uod.CouponsBarCode) as CouponsBarCode,ic.State,case when  isnull(nullif(uo.matCouponsbarcode,''),'')<>'' then uo.MatName else uod.MatName end as matname
from Unicom_Orders uo left join Unicom_OrderDetails uod on uo.DocCode=uod.DocCode
inner join iCoupons ic on isnull(nullif(uo.matCouponsbarcode,''),uod.CouponsBarCode)=ic.CouponsBarcode
where ( isnull(uo.matCouponsbarcode,'')<>''
or isnull( uod.CouponsBarCode,'')<>''
)
and uo.DocDate>='2012-09-21'
and not exists(
	select  1 from Coupons_H ch where uo.DocCode=ch.RefCode)-- and ch.DocStatus!=0)
	) a
where iCoupons.CouponsBarcode=a.CouponsBarCode
order by uo.DocDate
 
 commit
rollback
select ch.Refcode, *
  from Coupons_H ch, Coupons_d b where ch.Doccode=b.Doccode and b.CouponsBarCode='66912030027210'
  
  select sph.refcode, *
    from sPickorderHD sph where sph.DocCode='RE20120927007140'
    
    rollback
    
    