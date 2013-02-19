select * from imatsdorgbalance i
select * from iMatsdorgPlant imp
select * from iMatsdorgLedger iml

insert into iMatsdorgPlant(PlantID,sdorgid,MatCode,physicalStock,selfstock,OnOrderStock,transStock)
select ims.PlantID,os.sdorgid,ims.MatCode,sum(ims.unlimitStock),sum(ims.unlimitStock),0,0 from 
iMatStorage ims with(nolock) inner join oStorage os on ims.stCode=os.stCode
where ims.unlimitStock>0
group by  ims.PlantID,os.sdorgid,ims.MatCode

insert into iMatsdorgLedger(PlantID,sdorgid,MatCode,Stock,StockValue,ratevalue,MAP,ratemap)
select ims.PlantID,os.sdorgid,ims.MatCode,sum(ims.unlimitStock),sum(ims.unlimitStock*iml.MAP),sum(case when ims.plantid<>'101' then ims.unlimitStock*iml.MAP*(1+1.00000*img.addpresent/100) else  (ims.unlimitStock*iml.MAP) end),
avg(iml.MAP),avg(case when ims.plantid<>'101' then iml.MAP*(1+1.00000*img.addpresent/100) else iml.MAP end) from 
iMatStorage ims with(nolock) inner join oStorage os on ims.stCode=os.stCode
left join iMatLedger iml with(nolock) on ims.PlantID=iml.PlantID and ims.MatCode=iml.MatCode
inner join iMatGeneral img on ims.MatCode=img.MatCode
where ims.unlimitStock>0
group by  ims.PlantID,os.sdorgid,ims.MatCode


with cte(plantid,matcode,digit) as(
	select plantid,ims.MatCode,sum(ims.unlimitStock)
	from iMatStorage ims with(nolock)
	group by plantid,ims.MatCode
),
cte1(plantid,matcode,digit) as(
	select plantid,matcode,sum(i.indigit-i.outdigit)
	from istockledgerlog i with(nolock)
	group by i.plantid,i.matcode
)
select a.plantid,a.matcode,a.digit,imp.digit
from cte a full join cte1 imp on a.plantid=imp.PlantID and a.matcode=imp.MatCode 
where isnull(a.digit,0)<>imp.digit

select a.plantid,a.matcode,a.digit,imp.physicalStock
from cte a full join iMatPlant imp on a.plantid=imp.PlantID and a.matcode=imp.MatCode 
where isnull(a.digit,0)<>imp.physicalStock

select * from imatbalance i
select * from imatstbalance i

