-- select * from shiftaccreditID('','')  
  /*
  2012-11-02 改从已售串号表读数据 三断笛
  
  */
alter       function shiftaccreditID(  
 @beginday datetime,  
 @endday datetime,  
 @seriescode varchar(50),  
 @gift varchar(100),  
 @sdorgid varchar(20)  
)  
RETURNS @table TABLE   
 (seriescode varchar(20),  
  gift varchar(20),  
  sdorgname varchar(120),  
  docdate datetime,  
  matname varchar(50),  
  sdorgname1 varchar(20))  
AS  
BEGIN  
  
  insert into @table(seriescode,gift,sdorgname,docdate,matname,sdorgname1)  
select s.seriescode,s.gift,g.SDOrgName,d.docdate,m.matname,d.sdorgname as sdorgname1   
from iseriessaled s with(nolock)   
inner join osdorg g with(nolock) on s.gift=g.internat and state='已售' and isnull(s.gift,'')<>'' and isnull(internat,'')<>''  
left join spickorderitem m with(nolock) on s.seriescode=m.seriescode   
left join spickorderhd d with(nolock) on m.doccode=d.doccode and d.formid=2419  
where d.docdate between @beginday and @endday  
and (@seriescode='' or s.seriescode like '%' +@seriescode +'%')  
and (@gift='' or exists(select * from getinstr(@gift) where list = g.internat))  
and (@sdorgid='' or exists(select * from getinstr(@sdorgid) where list = d.sdorgid))  
  
  RETURN   
end