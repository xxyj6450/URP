--                    QueryinventorySeriesCode                          
-- select * from QueryinventorySeriesCode('','','','','*','','售后','','','')                          
             --beginday;endday;vndcode;matcode;mattype;sdorgid;stcode;seriescode;state;returncode;MATGROUP;matlife;issend;station1;preallocation;issale;salemun             
--select top 10 * from iseries where state='应收'      select * from iseries where seriescode='352540040950775'    
/*
分别处理已售串号和非已售串号
修改时间:2012/11/02 
修改人:三断笛

*/               
CREATE                    function [dbo].[QueryinventorySeriesCode_saledate] ( @beginday datetime,@endday datetime,                         
        @vndcode varchar(500),                          
        @matcode varchar(300),                          
        @MatType varchar(200),                          
        @sdorgid varchar(200),                          
        @stcode varchar(100),                          
 @seriescode varchar(500),                          
 @state varchar(20),                          
 @returncode varchar(20),@MATGROUP varchar(50),@matlife varchar(50),@issend varchar(10)                          
 ,@station varchar(50) ,                      
 @preallocation  VARCHAR(20),          
 @issale varchar(30),@salemun varchar(50)                        
         )                          
        returns @table table(                          
        SeriesCode varchar(50),---串号                          
        matcode varchar(50),---物料号                          
        matname varchar(100),---物料名                          
        mattype varchar(50),---手机型号                          
        state varchar(10),----状态                          
        stcode varchar(50),---仓库                          
        stname varchar(150),                          
        vndcode varchar(50),---供应商号                          
        vndname varchar(200),--供应商名                          
        purprice money,--采购价                          
        purGRdate datetime,--采购收货时间                          
        purGRDocCode varchar(20),---采购收货单号                          
        purReturnDate datetime,--退货日期                          
        purReturnPrice datetime,---退货时间                          
        purReturnDocCode varchar(20),---退货单单号                          
        purSPmoney money,--供应商累计保价金额                          
        purAchivePrice money,---                          
        purClearPrice money,--结算金额                          
        payamount money,--付款额                          
 returncode varchar(50), --返厂点                          
--      createdate datetime,---产生串号日期                          
--      createdoccode varchar(20),--产生串号单号,--产生串号单号                               
--  returncode varchar(20),                          
--  returnname varchar(40),                          
  returndoccode varchar(20),                          
--  returndate datetime,                          
  salesuom varchar(50),                           
--  packagecode varchar(20),                          
--  costprice money,                          
  matgroup varchar(20),                           
 YXDATE DATETIME,                          
 gift varchar(50),                          
 fk int,                          
 matlife varchar(50),  --商品状态                          
        digit int ,                           
 matgroupname varchar(50) ,                          
 stcode1 varchar(50), --店面调售后                          
 stname1 varchar(120),                          
 shdjdate datetime, --店面调售后时间                           
 shdjHDMemo varchar(100),   --店面调售后故障说明                          
 station varchar(50),   --岗位                          
 issend varchar(10),                          
 shdjusertxt varchar(100), --售后附加信息                       
 preallocation bit,--预开户                         
 seriesnumber varchar(50),salesdate datetime,salemun varchar(50)         )as                          
begin                          
                    
-- if @stcode=''                          
-- return                          
DECLARE @bpreallocation BIT              
SELECT @bpreallocation=CASE when @preallocation='预开户' then 1 else 0 end                       
if @stcode='*'            
 select @stcode=''                    
----         update iseries set issend = 0 where seriescode in ('358852010023382','356677010433402')                               
if @state='' or @state like '%已售%'
	BEGIN
		insert into @table (SeriesCode , matcode , matname ,mattype ,stcode,stname, state ,vndcode ,purprice , purGRdate ,purGRDocCode ,purReturnDate ,purReturnPrice ,                          
		purReturnDocCode , purSPmoney ,purAchivePrice,purClearPrice,payamount,vndname,matgroup,matgroupname,salesuom,returndoccode,                          
		--returncode,returnname ,returndoccode,returndate,createdate ,createdoccode,                          
		YXDATE,gift,fk ,matlife , digit ,stcode1,shdjdate,shdjHDMemo ,station,issend,shdjusertxt,returncode,seriesnumber,salesdate,salemun)                          
		                          
		select SeriesCode , a.matcode , l.matname ,l.mattype ,a.stcode,e.name40, state ,a.vndcode ,a.purprice , purGRdate ,purGRDocCode ,purReturnDate ,purReturnPrice ,                          
		purReturnDocCode , purSPmoney ,purAchivePrice,purClearPrice,payamount,b.vndname,p.matgroup,p.matgroupname,l.Uom,a.returndoccode,                          
		--returncode,returnname ,returndoccode,returndate ,createdate ,createdoccode ,                          
		YXDATE,gift,fk,l.matlife , 1 ,stcode1,shdjdate,shdjHDMemo,station,                          
		(case isnull(issend,0) when 0 then '未送厂' when 1 then '已送厂' when 2 then '已返回'  end),shdjusertxt,a.returncode,a.seriesnumber,salesdate,(case a.salemun when -1 then '售后机' else '非售后机' end) as salemun                          
		from --vseries a            select * from iseries              
		iseries a                           
		left join imatgeneral l with(nolock) on a.matcode=l.matcode                           
		left join pvndgeneral b with(nolock)  on a.vndcode=b.vndcode                          
		left join imatgroup p with(nolock)  on l.matgroup=p.matgroup                          
		left join oStorage e with(nolock)  on a.stcode=e.stcode                          
		where (salesdate between @beginday and @endday) and salesdate is not null and                                
		and   (@stcode='' or a.stcode in (select * from getinstr(@stcode)))                          
		and   (@matgroup = '' or exists(select * from imatgroup aa,getinstr(@matgroup) bb,imatgroup cc                          
				  where aa.matgroup = bb.list and left(cc.treecontrol,len(aa.treecontrol)) = aa.treecontrol and cc.matgroup = l.matgroup))                          
		and   (@mattype='' or l.mattype like '%'+@mattype+'%')--in (select * from getinstr(@mattype)))                                           
		and   (@vndcode='' or a.vndcode in (select * from getinstr(@vndcode)))                          
		and   (@matcode='' or a.matcode in (select * from getinstr(@matcode)))                          
		and   (a.seriescode like '%'+ @SeriesCode+'%' or @seriescode='')                          
		and   (@returncode='' or a.returncode in (select * from getinstr(@returncode)))                          
		and   (@matlife='' or l.matlife in (select * from getinstr(@matlife)))                          
		and   (@station='' or a.station in (select * from getinstr(@station)))                         
		AND (@preallocation='' OR  isnull(a.preAllocation,0)=@bpreallocation)       
		and  (@salemun='' or (case a.salemun when -1 then '是' else '否' end)=@salemun)                     
		and (@issale='' or (case salemun when 1 then '加盟商已售' when 0 then '加盟商库存' end)=@issale) 
	END
if @state='' and @state<>'已售'
	BEGIN
		insert into @table (SeriesCode , matcode , matname ,mattype ,stcode,stname, state ,vndcode ,purprice , purGRdate ,purGRDocCode ,purReturnDate ,purReturnPrice ,                          
		purReturnDocCode , purSPmoney ,purAchivePrice,purClearPrice,payamount,vndname,matgroup,matgroupname,salesuom,returndoccode,                          
		--returncode,returnname ,returndoccode,returndate,createdate ,createdoccode,                          
		YXDATE,gift,fk ,matlife , digit ,stcode1,shdjdate,shdjHDMemo ,station,issend,shdjusertxt,returncode,seriesnumber,salesdate,salemun)                          
		                          
		select SeriesCode , a.matcode , l.matname ,l.mattype ,a.stcode,e.name40, state ,a.vndcode ,a.purprice , purGRdate ,purGRDocCode ,purReturnDate ,purReturnPrice ,                          
		purReturnDocCode , purSPmoney ,purAchivePrice,purClearPrice,payamount,b.vndname,p.matgroup,p.matgroupname,l.Uom,a.returndoccode,                          
		--returncode,returnname ,returndoccode,returndate ,createdate ,createdoccode ,                          
		YXDATE,gift,fk,l.matlife , 1 ,stcode1,shdjdate,shdjHDMemo,station,                          
		(case isnull(issend,0) when 0 then '未送厂' when 1 then '已送厂' when 2 then '已返回'  end),shdjusertxt,a.returncode,a.seriesnumber,salesdate,(case a.salemun when -1 then '售后机' else '非售后机' end) as salemun                          
		from --vseries a            select * from iseries              
		iseries a                           
		left join imatgeneral l with(nolock)  on a.matcode=l.matcode                           
		left join pvndgeneral b with(nolock)  on a.vndcode=b.vndcode                          
		left join imatgroup p with(nolock)  on l.matgroup=p.matgroup                          
		left join oStorage e with(nolock)  on a.stcode=e.stcode                          
		where (salesdate between @beginday and @endday) and salesdate is not null and               
		(@state='' or a.state in (select * from getinstr(@state)))                          
		and   (@stcode='' or a.stcode in (select * from getinstr(@stcode)))                          
		and   (@matgroup = '' or exists(select * from imatgroup aa,getinstr(@matgroup) bb,imatgroup cc                          
				  where aa.matgroup = bb.list and left(cc.treecontrol,len(aa.treecontrol)) = aa.treecontrol and cc.matgroup = l.matgroup))                          
		and   (@mattype='' or l.mattype like '%'+@mattype+'%')--in (select * from getinstr(@mattype)))                           
		and   (a.state='应收' or a.state='在库' or a.state='在途' or a.state='返厂' or a.state='借出' or a.state='售后' or a.state='已售' or a.state is null)                          
		and   (@vndcode='' or a.vndcode in (select * from getinstr(@vndcode)))                          
		and   (@matcode='' or a.matcode in (select * from getinstr(@matcode)))                          
		and   (a.seriescode like '%'+ @SeriesCode+'%' or @seriescode='')                          
		and   (@returncode='' or a.returncode in (select * from getinstr(@returncode)))                          
		and   (@matlife='' or l.matlife in (select * from getinstr(@matlife)))                          
		and   (@station='' or a.station in (select * from getinstr(@station)))                         
		AND (@preallocation='' OR  isnull(a.preAllocation,0)=@bpreallocation)       
		and  (@salemun='' or (case a.salemun when -1 then '是' else '否' end)=@salemun)                     
		and (@issale='' or (case salemun when 1 then '加盟商已售' when 0 then '加盟商库存' end)=@issale)         
	END
 
-- update @table set vndname=b.vndname from @table a,pvndgeneral b where a.vndcode=b.vndcode                          
--插入配置                          
 update @table set salesuom=b.salesuom                          
 from @table a,imatgeneral b where a.matcode=b.matcode                          
-- update @table set matgroupname = b.matgroupname from @table a ,imatgroup b where a.matgroup = b.matgroup                          
--处理售后调出店面                          
update @table set stname1=name40 from @table e ,vstorage b where e.stcode1=b.stcode and isnull(e.stcode1,'')<>''                          
                          
if isnull(@issend,'') = '未送厂'                          
begin                           
 delete from @table where issend <>'未送厂'                           
end                          
if isnull(@issend,'') = '已送厂'                          
begin                           
 delete from @table where issend <>'已送厂'                           
end                          
if isnull(@issend,'') = '已返回'                          
begin                           
 delete from @table where issend <>'已返回'                           
end                          
          
--select matgroup,* from vseries where matgroup is null                          
--select * from imatgeneral where matcode = 'S0201610002'                          
                
return                          
end                           
                          
-- select * from vseries where mattype='诺N2300'