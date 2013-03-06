--��鲿���ڼ����ֿ��ڼ���ڳ��Ƿ�һ��,��804������
with cte as(
	select i.periodid, os.sdorgid,i.matcode,sum(isnull(i.prestock,0)) as prestock,sum(isnull(i.indigit,0)) as indigit,sum(isnull(i.outdigit,0)) as outdigit,sum(isnull(i.stock,0)) as stock
	from imatstbalance i with(nolock) inner join oStorage os with(nolock) on i.stcode=os.stCode
	where i.periodid='2013-01'
	group by i.periodid, os.sdorgid,i.matcode)
select  i.periodid,i.plantid,i.sdorgid,i.matcode,i.stock,b.stock
from imatsdorgbalance i with(nolock) left join cte b on i.periodid=b.periodid and i.sdorgid=b.sdorgid and i.matcode=b.matcode 
where isnull(i.prestock,0)<>isnull(b.prestock,0)
and i.periodid='2013-01'
order by i.periodid,i.plantid,b.matcode
--��鲿�ſ���ڼ����ֿ����ڼ���Ƿ�һ��,��805
with cte as(
	select i.periodid, os.sdorgid,i.matcode,sum(isnull(i.prestock,0)) as prestock,sum(isnull(i.indigit,0)) as indigit,sum(isnull(i.outdigit,0)) as outdigit,sum(isnull(i.stock,0)) as stock
	from imatstbalance i with(nolock) inner join oStorage os with(nolock) on i.stcode=os.stCode
	where i.periodid='2013-01'
	group by i.periodid, os.sdorgid,i.matcode)
select  i.periodid,i.plantid,i.sdorgid,i.matcode,i.stock,b.stock
from imatsdorgbalance i with(nolock) left join cte b on i.periodid=b.periodid and i.sdorgid=b.sdorgid and i.matcode=b.matcode 
where isnull(i.stock,0)<>isnull(b.stock,0)
and i.periodid='2013-01'
order by i.periodid,i.plantid
--1.�����ڳ������,��鲿�ſ���ڼ����ֿ����ڼ���Ƿ�һ��,ֻһ��,����һ���ֻ�.
with cte as(
	select i.periodid, os.sdorgid,i.matcode,sum(isnull(i.prestock,0)) as prestock,sum(isnull(i.indigit,0)) as indigit,sum(isnull(i.outdigit,0)) as outdigit,sum(isnull(i.stock,0)) as stock
	from imatstbalance i with(nolock) inner join oStorage os with(nolock) on i.stcode=os.stCode
	where i.periodid='2013-01'
	group by i.periodid, os.sdorgid,i.matcode)
select  i.periodid,i.plantid,i.sdorgid,i.matcode,i.stock,b.stock
from imatsdorgbalance i with(nolock) left join cte b on i.periodid=b.periodid and i.sdorgid=b.sdorgid and i.matcode=b.matcode 
where isnull(i.stock,0)<>isnull(b.stock,0)+isnull(i.prestock,0)-isnull(b.prestock,0)
and i.periodid='2013-01'
order by i.periodid,i.plantid