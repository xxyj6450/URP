--����2������ϸ�˵����ڳ�������
select i.sdorgid,i.matcode
from istockledgerlog i with(nolock) 
where i.periodid='2013-02'
and not exists(select 1 from imatsdorgbalance i1 with(nolock) where i.sdorgid=i1.sdorgid and i1.periodid='2013-01'  and i.matcode=i1.matcode)

group by  i.sdorgid,i.matcode