select osc.SDOrgID,osc.Balance,osc.FrozenAmount,osc.AvailableBalance,b.balance
  from oSDOrgCredit osc outer apply freeperiodfarlog2('',osc.SDOrgID,getdate(),getdate()) b
where osc.Balance<>b.balance
and formname='期末余额'

select * from oSDOrgCredit osc where osc.SDOrgID='2.755.579'
select * from oSdorgCreditLog oscl where oscl.SDorgID='2.755.579' or oscl.AccountSDorgID='2.755.579' 
order by docdate desc


select * from sPickorderHD sph where sph.FormID=4951
and not exists(select 1 from oSdorgCreditLog oscl where sph.DocCode=oscl.Doccode)
and sph.DocStatus<>0
and sph.DocDate>='2012-09-23'

select sph.instcode,doccode
  from sPickorderHD sph where sph.DocCode in('JDR2012092800000','JDR2012092800020')

begin tran
exec sp_UpdateCredit  4951,'JDR2012092800000','2.1.020.13.58',0,'','system','管理员处理未过帐的退货单'

rollback

commit