return
--��ʼ������
begin tran
--��ʼ����ͨ�����ڳ��ɱ�
delete iMatsdorgLedger where MatCode in('S6.04.14.01.01.1')
	INSERT INTO iMatsdorgLedger(plantid,sdorgid,matcode,stock,stockvalue,ratevalue)
	SELECT t.plantid,e.sdorgid,t.matcode,SUM(t.digit) digit,SUM(t.digit)*isnull(price,0) AS stockvalue,
	(case when t.plantid not in ('101','115') then (SUM(t.digit)*isnull(price,0))*(100+isnull(l.addpresent,0))/100 else SUM(t.digit)*price END) AS ratevalue 
	FROM ckdigit t LEFT JOIN vstorage e ON t.stcode=e.stcode LEFT JOIN imatgeneral l ON t.matcode=l.matcode
	--where t.plantid<>'115' and left(t.matcode,2) in ('1.','S1','Y1') 
	where  l.MatCode in('S6.04.14.01.01.1')
	GROUP BY t.plantid,e.sdorgid,t.matcode,price,addpresent

	commit
	rollback
 


--�����ڲ��˻�������ʱд��˾�벿������
begin tran
update a
	set a.sdorgid=b.sdorgid,a.sdorgname=os.SDOrgName,
	a.sdorgid2=c.sdorgid,a.sdorgname2=os1.SDOrgName
--select top 10 a.*
 from sPickorderHD a with(nolock) inner join oStorage   b with(nolock) on   a.stcode=b.stcode
 inner join oSDOrg os with(nolock) on b.sdorgid=os.SDOrgID
 inner join oStorage c with(nolock) on a.instcode=c.stCode
 inner join osdorg os1 with(nolock) on c.sdorgid=os1.SDOrgID
where a.FormID=4031
and isnull(a.sdorgid,'')<>b.sdorgid
and a.DocDate>='2013-01-01'
commit
 select * from iMatsdorgLedger iml where iml.sdorgid='101.05.02' and iml.MatCode='1.11.020.1.1.1'
 
 ------------------------------------------------------------�޸����γ��ⵥplantidΪ��------------------------------------------------------------
 begin tran
 update a
	set plantid=Companyid
--select *
from sPickorderHD a
 where FormID=2424
 and isnull(plantid,'')=''
 --������ϸ�˵Ĳ���
 update a
	set a.sdorgid=b.sdorgid
 from istockledgerlog a with(nolock),oStorage b with(nolock)
 where a.stcode=b.stCode
 and isnull(a.sdorgid,'')=''
 and a.docdate>='2012-06-01'
 commit
 rollback
 --����©д����ϸ��
 exec sp_AddMatStockLedger 4062,'ICT2013020400920',''
 --������ϸ�˵Ĳ��ű���
 			update a
					set a.sdorgid=os.sdorgid
				from istockledgerlog a with(nolock),oStorage os with(nolock)
				where a.stcode=os.stCode
				--and isnull(a.sdorgid,'')=''
				and a.docdate between '2012-06-01' and  '2012-08-01'
--���¾��յ������Ĳ���
begin tran
 update d set sdorgid=e.sdorgid,sdorgname=e.sdorgname

--select * 
from spickorderhd d left join vstorage e on d.stcode=e.stcode where periodid>'2012-12' and formid=2424
and d.sdorgid<>e.sdorgid
commit
------------------------------------------------------------------�������γ��ⵥ����ʱ��-------------------------------------------------------------
begin tran
--�ȸĵ�����ⵥ
--��������ⵥ�����ں��ڼ�ĳɹ�������
update a
	set a.docdate=convert(varchar(10),postdate,120),
	a.PeriodID=convert(varchar(7),postdate,120)
--select doccode,a.DocDate,a.PostDate
from imatdoc_h a
where a.FormID in(1507,4061,4032)
and a.DocDate>='2013-01-01'
and datepart(mm,a.DocDate)<>datepart(mm,a.PostDate)

update a
	set a.docdate=convert(varchar(10),postdate,120),
	a.PeriodID=convert(varchar(7),postdate,120)
--select doccode,a.DocDate,a.PostDate
from spickorderhd a
where a.FormID in(1507,4061,4032)
and a.DocDate>='2013-01-01'
and datepart(mm,a.DocDate)<>datepart(mm,a.PostDate)
--�ٴ������,���������ڸĳ��������
update sph
	set sph.docdate=a.DocDate,sph.periodid=a.PeriodID
--select a.doccode,a.docdate,sph.doccode,sph.DocDate
from imatdoc_h a with(nolock),sPickorderHD sph with(nolock)
where a.refCode=sph.DocCode
and a.FormID=1507
and sph.FormID=2424
and a.DocDate>='2013-02-01'
and sph.DocDate <'2013-02-01' and sph.DocDate>='2013-01-01'
update i
	set inserttime =sph1.PostDate,
	periodid = sph1.PeriodID,
	docdate = sph1.DocDate
from istockledgerlog i with(nolock)  
inner join imatdoc_h sph1 with(nolock) on sph1.refcode=i.doccode
where i.formid in(2424,4031)
and sph1.FormID in(1507,4061)
and i.docdate>='2013-01-01'
--�ٸ��µ�����ϸ�ˣ��ӵ��뵥����
update i
	set inserttime =sph1.PostDate,
	periodid = sph1.PeriodID,
	docdate = sph1.DocDate
from istockledgerlog i with(nolock)  
inner join spickorderhd sph1 with(nolock) on sph1.doccode=i.doccode
where sph1.formid in(1507,4061,4032)
and i.docdate>='2013-01-01'
update i
	set inserttime =sph1.PostDate,
	periodid = sph1.PeriodID,
	docdate = sph1.DocDate
from istockledgerlog i with(nolock)  
inner join imatdoc_h sph1 with(nolock) on sph1.doccode=i.doccode
where sph1.formid in(1507,4061,4032)
and i.docdate>='2013-01-01'
--���µ�������ϸ��ֱ��ʹ�õ��뵥������
update i
	set inserttime =sph1.PostDate,
	periodid = sph1.PeriodID,
	docdate = sph1.DocDate
	-- select i.*
from istockledgerlog i with(nolock)  
inner join imatdoc_h sph1 with(nolock) on sph1.refcode=i.doccode
where i.formid in(2424,4062,4031)
and sph1.FormID in(4032,1507,4061)
and i.docdate>='2013-01-01'
update i
	set inserttime =sph1.PostDate,
	periodid = sph1.PeriodID,
	docdate = sph1.DocDate
from istockledgerlog i with(nolock)  
inner join spickorderhd sph1 with(nolock) on sph1.refcode=i.doccode
where i.formid in(2424,4062,4031)
and sph1.FormID in(4032,1507,4061)
and i.docdate>='2013-01-01'
rollback
commit
-------------------------------------------------------------��ϸ��ȱʧ����޷�����----------------------------------------------------------
--���Ϻ�����ڼ�����
begin tran
begin tran
;with cte(id) as(
	select 1
	union all 
	select 2
	union all 
	select 3
	union all 
	select 4
	union all 
	select 5
	union all 
	select 6
	union all 
	select 7
)
insert into imatstbalance(plantid,stcode,periodid,matcode,batchcode,prestock,indigit,outdigit,preispstock,ispindigit,ispoutdigit,prelmtstock,lmtindigit,lmtoutdigit,prertnstock,rtnoutdigit,onorderstock)
select plantid,stcode,dbo.PeriodAdd('month',row_number() OVER (order by (select 1)),i.periodid) as  periodid,matcode,batchcode,prestock,indigit,outdigit,preispstock,ispindigit,ispoutdigit,prelmtstock,lmtindigit,lmtoutdigit,prertnstock,rtnoutdigit,onorderstock
from imatstbalance i cross JOIN cte
where i.matcode='1.01.002.1.1.1'
and i.stcode='1.1.756.01.01'
and i.periodid='2012-06'

 
/*
declare @sql varchar(max)
select @sql=''
select @sql=@sql+name+','
from syscolumns s where s.id=object_id('imatstbalance')
print @sql
*/
--�޸����ϵ��ڼ�����
update i 
set i.prestock = 0,i.indigit = 1,i.outdigit = 0
 from imatstbalance i
where i.matcode='1.01.002.1.1.1'
and i.stcode='1.1.756.01.01'
and i.periodid='2012-07'

update i 
set i.prestock = 1,i.indigit = 0,i.outdigit = 0
from imatstbalance i
where i.matcode='1.01.002.1.1.1'
and i.stcode='1.1.756.01.01'
and i.periodid between '2012-08' and '2012-12'
update i
 set i.prestock = 1,i.indigit = 0,i.outdigit =1
 from imatstbalance i
	
where i.matcode='1.01.002.1.1.1'
and i.stcode='1.1.756.01.01'
and i.periodid ='2013-01'

commit

--���ϳɱ�
insert into iMatsdorgLedger(PlantID,sdorgid,MatCode,Stock,StockValue)
select '108','1.1.756.01.01','1.01.002.1.1.1',1,427.35
commit
------------------------------------------------------------------��д�ֿ��ڼ����-------------------------------------------------------
begin tran
;with cte as(
	select i.companyid, stcode,matcode,periodid,sum(isnull(i.indigit,0)) as indigit,sum(isnull(i.outdigit,0)) outdigit
from istockledgerlog i with(nolock)
where i.periodid='2013-01'
	group by i.companyid,i.stcode,matcode,PeriodID
	) 
update a
	set a.indigit=b.indigit,a.outdigit=b.outdigit
from imatstbalance a,cte b 
where a.stcode=b.stcode
and a.periodid=b.periodid
and a.matcode=b.matcode
rollback
 
------------------------------------------------------------------��д�����ڼ����-------------------------------------------------------
begin tran
;with cte as(
	select i.plantid, sdorgid,matcode,periodid,sum(isnull(i.indigit,0)) as indigit,sum(isnull(i.outdigit,0)) outdigit,
	sum(isnull(i.inledgeramount,0)) as inledgeramount,sum(isnull(i.inrateamount,0)) as inrateamount,
	sum(isnull(i.outledgeramount,0)) as outledgeramount,sum(isnull(i.outrateamount,0)) as outrateamount
from istockledgerlog i with(nolock)
where i.periodid='2013-01'
	group by i.plantid,i.sdorgid,matcode,PeriodID
	) 
update a
	set a.indigit=b.indigit,a.outdigit=b.outdigit,a.outamount=b.outledgeramount,a.outrateamount=b.outrateamount,
	a.inamount=b.inledgeramount,a.inrateamount=b.inrateamount
from imatsdorgbalance  a,cte b 
where a.sdorgid=b.sdorgid
and a.periodid=b.periodid
and a.matcode=b.matcode
commit
---�޸���ϸ��RowID����
update istockledgerlog set docrowid=docrowid+'ZY' where doccode like '%ZY'
--�޸�������ⵥû�е��γ��ⵥ
begin tran
update imatdoc_h
	set refCode = 'KY20130122000200'
where DocCode='DR20130122001680'
-------------------------------
--��ѯ��ϸ���뵥�ݲ�ƥ�������
 begin tran
 update i
  set i.docrowid=sp.rowid
 --select a.formid, sp.DocCode,sp.MatCode,sp.rowid,i.doccode,i.matcode,i.docrowid 

 from sPickorderhd a with(nolock) inner join  sPickorderitem sp with(nolock)  on a.doccode=sp.doccode
 left join istockledgerlog i with(nolock) on sp.DocCode=i.doccode and sp.MatCode=i.matcode and sp.rowid=i.docrowid
   inner join iMatGeneral img on sp.MatCode=img.MatCode
 where sp.DocCode like '%201301%'
 and a.FormID in(2419,2450,2418,4031,4032,4061,4062,2424)
 and sp.rowid<>isnull(i.docrowid,'')
 and img.MatState=1
 and a.DocStatus=case when a.formid in(4062,4061) then 100 when a.formid in(2418,2419,2450,4031) then 200 when a.formid in(2424) then 150 end   
 --and a.FormID=2450
 order by a.DocDate
 commit
 --���붪ʧ����ϸ��
insert into istockledgerlog 
				   (inserttime,companyid,sdorgid,periodid,plantid,matcode,stcode,batchcode,formid,doccode,docdate,doctype,
					cltcode,vndcode,docitem,docrowid,digit,uom,baseuomrate,uomrate,baseuom,
					indigit,outdigit,inledgerdigit,inledgeramount,outledgerdigit,outledgeramount,
					incspdigit,outcspdigit,invspdigit,outvspdigit,salesflag,cspflag,vspflag,inouttype,end4,matcost,outrateamount)
				   select  a.postdate,
					companyid,sdorgid,periodid,plantid,matcode,a.stcode,batchcode,formid,a.doccode,docdate,doctype,
					cltcode,vndcode,docitem,rowid,digit,uom,baseuomrate,uomrate,baseuom,
					0 indigit,basedigit outdigit,0 inledgerdigit,0 inledgeramount,basedigit outledgerdigit,matcost outledgeramount,
					0,0,0,0,1,0,0,pricememo,end4,MatCost,ratemoney
				   from spickorderhd  a with(nolock),sPickorderitem b
				WHERE  a.doccode in('RE20130104033700')
	       and b.MatCode in('1.01.010.1.1.3')
	       and a.DocCode=b.DocCode
 commit