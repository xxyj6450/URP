/*
2012-11-02 改从已售串号表取数据 三断笛
*/
alter function ord_sellfulfill (  
       @beginday varchar(10),  
 @endday  varchar(10),  
 @stcode varchar(50),  
 @matgroup varchar(50),  
 @mattype varchar(50),  
 @matcode varchar(50) )  
       
returns  @table table (  
 stcode varchar(50),  
 stname varchar(150),  
 matcode varchar(50),  
 matname varchar(50),  
 matgroup varchar(50),  
 matgroupname varchar(50),  
 mattype varchar(50),  
 firstdigit int,--期初量  
 digit float,--到货量  
 stockdigit int,--订货量  
 selldigit float,--销售量  
 fulfill float,--达成率  
 hdtext varchar(100)  
)  
begin  
  
if @stcode=''  
return  
if @stcode='*'  
select @stcode=''  
   
insert into @table (stcode,stname,matcode,matname,matgroup,matgroupname,mattype,firstdigit,digit,stockdigit)  
select m.sdorgid,m.sdorgname,d.matcode,d.matname,i.matgroup,g.matgroupname,i.mattype,0,d.instknum,d.ask_digit  
from ord_shopbestgoodsdoc m inner join ord_shopbestgoodsdtl d on m.doccode=d.doccode  
 inner join imatgeneral i on d.matcode=i.matcode  
 left outer join imatgroup g on i.matgroup=g.matgroup  
where m.docdate between @beginday and @endday and m.docstatus=100    
 and (@stcode = '' or exists(select * from getinstr(@stcode) where list = m.sdorgid))   
 and (@matgroup = '' or exists(select * from imatgroup aa,getinstr(@matgroup) bb,imatgroup cc  
        where aa.matgroup = bb.list and left(cc.treecontrol,len(aa.treecontrol)) = aa.treecontrol and cc.matgroup = i.matgroup))   
 and (@mattype = '' or exists(select * from getinstr(@mattype) where list = i.mattype))    
 and (@matcode = '' or exists(select * from getinstr(@matcode) where list = d.matcode))    
  
update @table set selldigit=k.salsum  
from @table t inner join (select o.sdorgid,i.matgroup,i.mattype,d.matcode,count(*) as salsum  
   from spickorderhd m with(nolock) inner join spickorderitem d with(nolock)  on m.doccode=d.doccode  
    inner join iseriessaled s with(nolock)  on d.seriescode=s.seriescode						--2012-11-02 修改从iseriessaled表取数据
    inner join ostorage o  with(nolock) on m.stcode=o.stcode  
    inner join imatgeneral i  with(nolock) on d.matcode=i.matcode  
   where m.formid=2419 and m.docstatus=200 and m.docdate between @beginday and @endday  
    and (@stcode = '' or exists(select * from getinstr(@stcode) where list=o.sdorgid))  
    and (@matgroup = '' or exists(select * from imatgroup aa,getinstr(@matgroup) bb,imatgroup cc  
           where aa.matgroup = bb.list and left(cc.treecontrol,len(aa.treecontrol)) = aa.treecontrol and cc.matgroup = i.matgroup))  
    and (@mattype = '' or exists(select * from getinstr(@mattype) where list = i.mattype))    
    and (@matcode = '' or exists(select * from getinstr(@matcode) where list = d.matcode))  
    and s.state='已售' and s.isbg=1  
  group by o.sdorgid,i.matgroup,i.mattype,d.matcode) k on t.stcode=k.sdorgid and t.matcode=k.matcode  
  
update @table set fulfill=(selldigit/digit)*100  
where digit>0  
  
return  
end