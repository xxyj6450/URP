begin TRAN
delete FROM _sysImportData

commit

begin TRAN
delete FROM _sysImportData


update _sysImportData
	set data3=left(data1,16)

with cte as(
		select data3 as doccode
		from _sysImportData sids
		group by data3
)
,cte2 as(
	select b.AccountSDorgID, sum(b.ChangeFrozenAmount) as ChangeFrozenAmount,sum(b.Commission) as Commission,sum(b.ChangeCredit) as ChangeCredit,count(*) as count
	from cte a,oSdorgCreditLog b
	where a.doccode=b.Doccode
	and b.Remark='管理员批量调整佣金'	
	group by AccountSDorgID
)
,cte3 as(
	select a.doccode,b.AccountSDorgID, sum(b.ChangeFrozenAmount) as ChangeFrozenAmount,sum(b.Commission) as Commission,sum(b.ChangeCredit) as ChangeCredit,count(*) as count
	from cte a,oSdorgCreditLog b
	where a.doccode=b.Doccode
	and b.Remark='管理员批量调整佣金'	
	group by a.doccode,b.AccountSDorgID
)
/*
select * from cte3 a,oSDOrgCredit osc
where a.AccountSDorgID=osc.SDOrgID 
and a.doccode='RS20120922000244'
*/

select oscl.*,s.* from cte a,oSdorgCreditLog oscl,osdorgcredit s
 where a.doccode=oscl.Doccode
and oscl.Remark='管理员批量调整佣金'	
and s.SDOrgID=oscl.AccountSDorgID
and a.doccode='RS20120922000244'
order by oscl.SDorgID, oscl.Docdate desc


select * from cte3 a,oSDOrgCredit osc
where a.AccountSDorgID=osc.SDOrgID 

select 
select * from cte2 a,oSDOrgCredit osc
where a.AccountSDorgID=osc.SDOrgID

select oscl.*,s.* from cte a,oSdorgCreditLog oscl,osdorgcredit s
 where data3=oscl.Doccode
and oscl.Remark='管理员批量调整佣金'	
and s.SDOrgID=oscl.AccountSDorgID
order by oscl.SDorgID, oscl.Docdate desc

 
 select * into osdorgcredit_1448 from oSDOrgCredit osc
  select * into osdorgcreditlog_1448 from oSDOrgCreditlog osc
  
  select * from oSDOrgCredit osc where osc.SDOrgID='2.752.162'