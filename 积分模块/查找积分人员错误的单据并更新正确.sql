with cte as(
select sl.DocCode,sl.DocDate,sl.sdorgid,sl.sdorgname, sl.sdgroup,sl.sdgroupname,sdgroup2,sdgroupname2,sl.DocType,sl.HDText,
case when sl.sdgroup='system' and sl.sdgroup2='system' then os.SDGroup
when sl.sdgroup='SYSTEM' and sl.sdgroup2<>'SYSTEM' and len(sl.sdgroup2)=11 then y.sdgroup
when sl.sdgroup='SYSTEM' and sl.sdgroup2<>'SYSTEM' and len(sl.sdgroup2)!=11 then sl.sdgroup
when len(sl.sdgroup)=11 then x.sdgroup
end as sdgroup1
  from SaleLog sl with(nolock)
  left join oSDGroup os  with(nolock) on sl.EnterName=os.SDGroupName
  left join oSDGroup x with(nolock)  on sl.sdgroup=x.usercode
  left join oSDGroup y with(nolock) on sl.sdgroup2=y.usercode
where (sl.sdgroup in('SYSTEM') or len(sl.sdgroup)=11 or len(sl.sdgroup2)=11 or sl.sdgroup2='system')
and sl.DocDate between '2013-02-01' and '2013-03-01'
and sl.sdorgid<>'101.07.04'
)
 select sl.DocCode,sl.DocDate,sl.sdorgid,sl.sdorgname, sl.sdgroup,sl.sdgroupname,sdgroup2,sdgroupname2,sl.DocType,sl.HDText,sdgroup1
 from cte sl  
--where sdgroupname='王强' 
 group by sl.DocCode,sl.DocDate,sl.sdorgid,sl.sdorgname, sl.sdgroup,sl.sdgroupname,sdgroup2,sdgroupname2,sl.DocType,sl.HDText,sdgroup1
 
select c.sdgroup,c.sdgroupname,c.sdgroup2,c.sdgroupname2,c.sdgroup1,os.SDGroupName,os.sdorgname
from cte c left join oSDGroup os on c.sdgroup1=os.SDGroup
group by c.sdgroup,c.sdgroupname,c.sdgroup2,c.sdgroupname2,c.sdgroup1,os.SDGroupName,os.sdorgname

select sl.DocCode,sl.DocDate,sl.sdorgid,sl.sdorgname, sl.sdgroup,sl.sdgroupname,sdgroup2,sdgroupname2,sl.DocType,sl.HDText,sdgroup1
 from cte sl  
--where sdgroupname='王强' 
 group by sl.DocCode,sl.DocDate,sl.sdorgid,sl.sdorgname, sl.sdgroup,sl.sdgroupname,sdgroup2,sdgroupname2,sl.DocType,sl.HDText,sdgroup1

1001002


  select * from Getsdgroupall('18666855382')
  
  select * from oSDGroup os where os.usercode='18666855382'
  select su.sdgroup, * from _sysUser su where su.UserCode='18666855382'
  
  select sl.DocCode,sl.DocDate,sl.sdorgid,sl.sdorgname, sl.sdgroup,sl.sdgroupname,sdgroup1,sdgroupname1,sl.DocType,sl.HDText,
case when sl.sdgroup='system' and sl.sdgroup1='system' then os.SDGroup
when sl.sdgroup='SYSTEM' and sl.sdgroup1<>'SYSTEM' and len(sl.sdgroup1)=11 then y.sdgroup
when sl.sdgroup='SYSTEM' and sl.sdgroup1<>'SYSTEM' and len(sl.sdgroup1)!=11 then sl.sdgroup
when len(sl.sdgroup)=11 then x.sdgroup
end as sdgroup1
  from Unicom_Orders  sl with(nolock)
  left join oSDGroup os  with(nolock) on sl.EnterName=os.SDGroupName
  left join oSDGroup x with(nolock)  on sl.sdgroup=x.usercode
  left join oSDGroup y with(nolock) on sl.sdgroup1=y.usercode
  where
 (sl.sdgroup in('SYSTEM') or len(sl.sdgroup)=11 or len(sl.sdgroup1)=11 or sl.sdgroup1='system')
and sl.DocDate between '2013-01-01' and '2013-01-31'
and sl.sdorgid<>'101.07.04'
  
  begin tran
delete FROM _sysImportData

commit

begin TRAN
update b
	set sdgroup = a.data10 ,
	sdgroup1 = a.data10,HDText = isnull(b.HDText,'')+',系统调整销售人员，原销售人员为'+isnull(b.sdgroup,'')
from sPickorderHD  b ,_sysImportData a
where a.Data1=b.DocCode

update b
	set sdgroup = a.data10 ,
	sdgroup2 = a.data10,HDText = isnull(b.HDText,'')+',系统调整销售人员，原销售人员为'+isnull(b.sdgroup,'')
from SaleLog b ,_sysImportData a
where a.Data1=b.DocCode

rollback


   begin tran
 update a
	set a.sdgroup=b.sdgroup,
	a.sdgroupname=b.sdgroupname,
	a.sdgroup1=b.sdgroup1,
	a.sdgroupname1=b.sdgroupname1
 from Unicom_Orders a with(nolock),sPickorderHD b with(nolock),_sysImportData c
 where a.DocCode=b.refcode
 and b.DocCode=c.Data1 
  update a
	set a.sdgroup=b.sdgroup,
	a.sdgroupname=b.sdgroupname 
  from NumberAllocation_Log  a with(nolock),sPickorderHD b with(nolock),_sysImportData c
 where a.DocCode=b.refcode
 and b.DocCode=c.Data1 
 
 --更新返销单
 begin tran
update a
	set a.sdgroup=b.sdgroup
from Unicom_Orders a inner join Unicom_Orders b on a.refcode=b.DocCode
and a.FormID=9244 and b.FormID=9146
and a.DocDate>='2013-02-01'
and a.sdgroup<>b.sdgroup

 begin tran
update a
	set a.sdgroup=b.sdgroup
from NumberAllocation_Log  a inner join Unicom_Orders b on a.Doccode=b.DocCode
 
and a.DocDate>='2013-02-01'
and a.sdgroup<>b.sdgroup
 rollback
 
 commit
 
 select uo.sdgroup, *from Unicom_Orders uo where uo.DocCode='KHFX201302240001'
 
 update