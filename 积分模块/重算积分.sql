set NOCOUNT on
begin tran
declare @doccode varchar(30),@formid int,@cnt int,@begindate datetime,@enddate datetime
select @cnt=0,@begindate='2013-04-01',@enddate='2013-04-30'
--遍历单据,计算积分
declare cur CURSOR READ_ONLY fast_forward for
--套包单积分
select  uo.DocCode,uo.FormID
from Unicom_Orders uo with(nolock) inner join oSDOrg os with(nolock) on uo.sdorgid=os.SDOrgID
where os.dptType<>'加盟店'
and uo.DocDate >= '2013-04-1' 
and uo.FormID=9146
and uo.DocStatus=100
and uo.DocDate between @begindate and @enddate
union all
--其它业务受理积分
select     uo.DocCode,uo.FormID
from BusinessAcceptance_H  uo with(nolock) inner join oSDOrg os with(nolock) on uo.sdorgid=os.SDOrgID
where os.dptType<>'加盟店'
and uo.DocDate >= '2013-04-1' 
and uo.DocStatus=1
and uo.DocDate between @begindate and @enddate
union all
--零售销售单积分
select     uo.DocCode,uo.FormID
from sPickorderHD   uo with(nolock)  
where uo.DocDate >= '2013-04-1' 
and uo.DocStatus=200
and uo.FormID=2419
and isnull(uo.refcode,'')=''
and uo.DocDate between @begindate and @enddate
 open cur
 fetch next FROM cur into @doccode,@formid
 while @@FETCH_STATUS=0
	BEGIN
		if @formid in(9146)  select * into #Unicom_OrderDetails from Unicom_OrderDetails where doccode=@doccode
		--执行积分计算
		exec sp_ExecScoreDoc @formid,@doccode
		if @formid in(9146)   drop TABLE #Unicom_OrderDetails
		fetch next FROM cur into @doccode,@formid		
	END
close cur
deallocate cur
-----------------------------------------------------------统一更新积分---------------------------------------------------
--更新套包单积分
;with cte as(
	select sll.Doccode,sum(isnull(sll.Score,0)) as score1 from ScoreLedgerLog sll
	where sll.DocDate>='2013-04-01'
	group by sll.Doccode
)
update a
	set Score1 = b.score1,TotalScore = isnull(a.Score,0)+isnull(b.score1,0)
from Unicom_Orders a with(nolock) inner join cte b on a.DocCode=b.Doccode
where a.DocDate>='2013-04-01'
--更新套包单对应零售单的积分
update a
	set a.price2=sll.Score
from sPickorderHD sph with(nolock)   inner join  sPickorderitem a with(nolock) on sph.DocCode=a.DocCode
inner join ScoreLedgerLog sll with(nolock) on  a.refcode=sll.Doccode and a.MatCode=sll.Matcode
where sph.refformid=9146
and sph.FormID=2419
and sph.DocDate>='2013-04-01'
--更新缴费与补卡的积分
update a
	set a.price2=sll.Score
from sPickorderHD sph with(nolock)   inner join  sPickorderitem a with(nolock) on sph.DocCode=a.DocCode
inner join BusinessAcceptance_H  sll with(nolock) on  a.refcode=sll.Doccode and a.MatCode=sll.Matcode
where sph.refformid in(9158,9167,9267)
and sph.DocDate>='203-04-01'
--更新退货单积分
update sp
	set sp.price2=c.price2
from sPickorderHD sph with(nolock) inner join sPickorderitem sp with(nolock) on sph.DocCode=sp.DocCode
inner join sPickorderitem c with(nolock) on sph.ClearDocCode=c.DocCode and sp.MatCode=c.MatCode and isnull(sp.seriesCode,'')=isnull(c.seriesCode,'')
where sph.FormID=2420
and sph.DocDate >='2013-04-01'
and sph.FormID=200
--更新零售单与退货单单据表头合计
;with cte as(
	select sp2.DocCode,sum(sp2.price2) as price2 
	from sPickorderitem sp2 with(nolock)
)
update a
	set a.TotalScore=b.price2
from sPickorderHD a with(nolock) inner join cte b WITH (nolock) on a.DocCode=b.doccode
where a.FormID in(2419,2420)
and a.DocCode>='2013-04-01'
--更新积分明细表积分
update a
	set a.totalprice=sp.price2,a.Score1=sp.price2
from SaleLog a inner join sPickorderitem sp with(nolock) on a.DocCode=sp.DocCode and a.MatCode=sp.MatCode and isnull(a.seriesCode,'')=isnull(sp.seriesCode,'')
where a.DocDate>='2013-04-01'
and a.FormID in(2419,2420)
--更新其他业务受理的积分
delete from SaleLog where FormID in (9153,9159,9160,9165,9180,9752,9755) and DocDate>='2013-04-01'

INSERT INTO Salelog
			  ( doccode, formid, doctype, docdate, periodid, refcode, companyid, plantid, sdorgid, sdorgname,   cltcode, cltname,  stcode, 
				stname, sdgroup, sdgroupname,  HDText,totalmoney, entername, enterdate, modifyname, modifydate, postname, postdate, auditing, 
				auditingname, auditingdate,   dpttype, BusiType,docitem,rowid,matcode,matname,Score, Score1, TotalScore,totalprice  )
			--增加memo2字段，对应b.usertxt3,手机号码 memo3套餐
			--调整RefCode,如果为退货单,则取ClearCode,否则取Refcode      
			SELECT a.doccode, a.formid, a.doctype, a.docdate, a.periodid, null as refcode, a.companyid, a.companyid ,
				 a.sdorgid, a.sdorgname,a.CustomerCode,a.CustomerName,  a.stcode, a.stname,  a.sdgroup, a.sdgroupname , 
				   a.Remark,a.TotalMoney,  a.entername, a.enterdate, a.modifyname, 
				   a.modifydate, a.postname, a.postdate, a.Audits, a.auditingname, a.auditingdate, 
				    a.dpttype, a.BusiType,1,newid(),c.MatCode,c.matname,  isnull(0,0),isnull( a.TotalScore,0), isnull(TotalScore,0),isnull(TotalScore,0)
				   --into #tableXXX
			FROM BusinessAcceptance_H a(NOLOCK)
				   LEFT JOIN _sysNumberAllocationCfgValues     b 
				   ON b.PropertyName=case when a.FormID in(9153) then '代办-过户'
															when a.formid in(9159) then '代办-客户资料变更'
															when a.formid in(9160) then '代办-套餐变更'
															when a.formid in(9165) then '代办-报开报停'
															when a.formid in(9180) then '代办-银行托收'
															when a.formid in(9752) then '代办-SP业务'
															when a.formid in(9755) then '代办-亲情业务'
														end
				   LEFT JOIN imatgeneral c ON  b.PropertyValue = c.matcode
			WHERE  a.doccode = @doccode --and c.matgroup <> 'P10'
				   AND a.formid IN (9153,9159,9160,9165,9180,9752,9755) --限制在销售业务'
				   and a.DocDate >='2013-04-01'
				   
  rollback
  
 100 14
 200 27
 400 58
 
  