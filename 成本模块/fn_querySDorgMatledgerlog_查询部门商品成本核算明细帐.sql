/*

select * From fn_querySDorgMatledgerlog('2013-01-01','2013-01-31','','1.1.769.13.02','1.01.079.1.1.1')
select i.sdorgid,stcode, * from istockledgerlog i where docdate>'2013-1-30'
*/

alter function fn_querySDorgMatledgerlog(
	@beginday datetime,    
	@endday datetime,    
	@companyid varchar(20),
	@sdorgID varchar(50),
	@matcode varchar(100) 
  )    
returns  @table table  (    
	id int ,    
	inserttime datetime,    
	docdate datetime,    
	formname varchar(200),    
	inledgerdigit money,    
	outledgerdigit money,    
	inledgeramount money,    
	outledgeramount money,     
	stock money,    
	amount money,    
	oldcode varchar(200),    
	prdflag varchar(200),    
	bunitname varchar(200),    
	inouttype varchar(200),    
	doccode varchar(200),    
	formid int,    
	doctype varchar(200),    
	docitem int,    
	period varchar(120),
	companyid varchar(200),
	sdorgid varchar(200),
	stcode varchar(50),
	INPRICE MONEY,    
	OUTPRICE MONEY,    
	COSTPRICE MONEY    
)    
as
begin    
	/*    
	if @matcode=''    
	return    
	if @matcode='*'    
	select @matcode=''    
    
	*/    
	declare @prestock money,@prebalance money,@stock money,@balance money,@PeriodID varchar(7),@preperiodend varchar(7)
	--取出期间
	   SELECT distinct @periodid = periodid,@preperiodend = begindate
	   FROM   gperiod
	   WHERE  periodtype = '库存事务'
	          AND @beginday between begindate and enddate
 
	--select @prestock=prestock,@prebalance=prebalance,@stock=stock,@balance=balance from dbo.freeperiodmatledger(@companyid,@beginday,@endday,@matcode,'','','','','')    
    --取出部门成本期间表
    ;with cte as(
    	select sdorgid,i.matcode,sum(isnull(i.stock,0)) as stock,sum(isnull(i.stockvalue,0)) as stockvalue
    	from imatsdorgbalance i with(nolock)
    	where i.sdorgid=@sdorgID
    	and i.matcode=@matcode
    	and i.periodid=dbo.preperiod(@PeriodID)
    	group by i.sdorgid,i.matcode
    	)
select @prestock = b.stock,@prebalance = b.stockvalue         
from cte b
    
	insert into @table (docdate,formname,inledgerdigit,outledgerdigit,inledgeramount,outledgeramount,stock,amount,companyid)    
	values( @beginday,'期初余额',0,0,0,0,@prestock,@prebalance,@companyid)    
    
	insert into @table    
	select a.id,a.inserttime,a.docdate,a.formname,a.inledgerdigit / b.baseuomrate as  inledgerdigit,    
	a.outledgerdigit / b.baseuomrate as  outledgerdigit,a.inledgeramount,outledgeramount,0,0,    
	(select top 1 oldcode from imatbarcode kk where kk.matcode = a.matcode and kk.prdno = a.batchcode and kk.oldcode <> '') as oldcode,    
	case when d.prdno is null then '外购' else '自产' end as prdflag,isnull(c.cltname,'')+isnull(e.vndname,'')+isnull(g.workshopname,'') as bunitname,    
	a.inouttype,a.doccode,    
	a.formid,a.doctype,a.docitem,a.plantid,a.sdorgid ,a.stcode, 0,0,0,0    
	from istockledgerlog a with (nolock)    
	inner join imatgeneral b on a.matcode = b.matcode    
	inner join ocompany dd on a.companyid = dd.companyid    
	left join ostorage f on a.stcode = f.stcode    
	left join prdline d on a.companyid = d.companyid and a.batchcode = d.prdno    
	left join scltgeneral c on a.cltcode = c.cltcode    
	left join pvndgeneral e on a.vndcode = e.vndcode    
	left join oWorkshop g on a.workshopid = g.workshopid    
	where docdate between @beginday and @endday     
	and (@companyid = '' or a.plantid=@companyid)     
	and (@matcode = '' or exists(select * from getinstr(@matcode) where list = a.matcode))
	and (@sdorgID='' or a.sdorgid=@sdorgID)
	and formid not in (1541,2424,1507)    
	-- and (inledgerdigit<>0 or outledgerdigit<>0)  lzy 2004-06-04修改    
	order by inserttime    
    
    
	insert into @table (docdate,formname,inledgerdigit,outledgerdigit,inledgeramount,outledgeramount,stock,amount,companyid)    
	values( @endday,'期末余额',0,0,0,0,@stock,@balance,@companyid)    
    
	update @table set period=dbo.getperiodlongname(docdate)    
    
    
	declare @inledgerdigit money    
	 declare @outledgerdigit money    
	 --declare @stock money    
	 declare @inledgeramount money    
	 declare @outledgeramount money    
	 declare @id int    
	 --declare cur cursor scroll    
    
	declare cur cursor scroll     
	 for select inledgerdigit,outledgerdigit,stock,isnull(inledgeramount,0),isnull(outledgeramount,0),id from @table     
	 where id is not null order by inserttime asc    
	 declare @i money    
	 declare @G money    
	 select @i=isnull(@prestock ,0)    
	 select @g=isnull(@prebalance,0)    
	 open cur    
	  fetch first  from cur  into  @inledgerdigit,@outledgerdigit,@stock,@inledgeramount,@outledgeramount,@id    
	 while @@fetch_status=0      
	 begin     
	   update @table set stock=@i+isnull(inledgerdigit,0)-isnull(outledgerdigit,0) where id=@id     
	  select @i=@i+isnull(@inledgerdigit,0)-isnull(@outledgerdigit,0)     
	  update @table set amount=@G+isnull(@inledgeramount,0)-isnull(@outledgeramount,0) where id=@id     
	  select @G=@G+@inledgeramount-@outledgeramount    
		 fetch next from cur into @inledgerdigit,@outledgerdigit,@stock,@inledgeramount,@outledgeramount,@id    
	 end    
    
	 close cur    
	 deallocate cur    
    
    
	--价格需要保持正数 2013-02-01 三断笛
	UPDATE @table SET INPRICE=abs(inledgeramount/inledgerdigit) where isnull(inledgerdigit,0)<>0    
	UPDATE @table SET outPRICE=abs(outledgeramount/outledgerdigit) where isnull(outledgerdigit,0)<>0    
	UPDATE @table SET costPRICE=abs(amount/stock) where  stock<>0    

	return    
end