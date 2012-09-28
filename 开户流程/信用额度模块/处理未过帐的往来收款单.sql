declare @doccode varchar(20),@Formid int,@sdorgid varchar(50)
begin TRAN
set NOCOUNT on;
declare abc cursor for 
select doccode,a.FormID,a.cltcode
  from farcashindoc  a where DocDate>='2012-09-23' and DocStatus<>0
and not exists(select 1 from oSdorgCreditLog oscl where a.DocCode=oscl.Doccode)
and a.FormID=2041
 open abc
 fetch next from abc into @doccode,@Formid,@sdorgid
 while @@FETCH_STATUS=0
	BEGIN
		print @doccode + ','+@sdorgid
		exec sp_UpdateCredit  @formid,@doccode,@sdorgid,0,'','管理员补回未处理的往来收款单','SYSTEM'
		 fetch next from abc into @doccode,@Formid,@sdorgid
	END
close abc
deallocate abc
rollback

commit
 select * from oSDOrgCredit osc where osc.SDOrgID='2.020.1803'
select * from oSdorgCreditLog oscl where oscl.Doccode='BR20120926000500'
begin tran
update FARcashindoc
set DocStatus = 50
where DocCode='BR20120925002100'

commit

select * from osdorgcredit where sdorgid='2.755.580'
select * from oSdorgCreditLog oscl where oscl.Doccode='BR20120925000100'
select * from oSDOrg os where os.SDOrgID='2.791.043'

select * from FARcashindoc f where f.DocCode='BR20120924001460'
select * from oSdorgCreditLog oscl where oscl.Doccode='BR20120924001460'

select * from fsubledgerlog f where f.doccode='BR20120925000080'