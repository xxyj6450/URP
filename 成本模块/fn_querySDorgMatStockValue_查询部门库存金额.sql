--drop function dbo.frptmatstorage            
--select * from dbo.[fn_querySDorgMatStockValue]('','1.1.769.01.03','','','','','','','','')            
       
            
alter  FUNCTION [dbo].[fn_querySDorgMatStockValue]            
 (            
  @companyid varchar(200),--公司            
  @sdorgid varchar(200),                    
  @matcode varchar(8000),--物料                      
  @matgroup varchar(200) ,--物料类别                     
  @mattype varchar(50)             
)            
RETURNS @table TABLE             
         (        
companyid varchar(200),            
companyname varchar(200),            
stcode varchar(200),            
stname varchar(200),            
sdorgid varchar(200),            
sdorgname varchar(200),            
matgroup varchar(200),            
matcode varchar(200),            
matname varchar(200),                      
unlimitStock money,            
packagecode varchar(200),            
onorderstock money,    
onordermoney money,    
totaldigit money,    
totalmoney money,            
costprice money,            
stockvalue money,matgroupname varchar(50))            
AS            
BEGIN            
  
     if @companyid='' and @sdorgid=''  and @matcode='' return       
	insert into @table (companyid,companyname ,sdorgid,sdorgname,            
			matgroup,matgroupname,matcode,matname,unlimitStock )            
	select op.plantid,op.plantname ,v.sdorgid,o.sdorgname,            
			img.matgroup,ll.matgroupname,v.matcode,img.matname,  v.selfstock
	from iMatsdorgPlant  v with(nolock)
	inner join oPlant op with(nolock) on v.PlantID=op.plantid
	inner join osdorg o with(nolock) on v.sdorgid=o.sdorgid
	inner join imatgeneral img with(nolock) on v.matcode=img.matcode
	inner join imatgroup ll with(nolock) on img.matgroup=ll.matgroup            
	where   (@companyid = '' or v.PlantID in (select * from getinstr(@companyid)))
	and  (@sdorgid='' or o.path like '%/'+@sdorgid+'/%')
	and (@matcode = '' or v.matcode like @matcode + '%')          
	and (@matgroup='' or  ll.PATH like '%/'+@matgroup+'/%')
	and (@mattype = '' or img.mattype in (select * from getinstr(@mattype)))                     
	and v.selfstock<>0            
	update @table set costprice=map,stockvalue=b.StockValue, --(case when isnull(stock,0)=0 then 0 else b.stockvalue/stock end)*unlimitStock ,
	totaldigit=isnull(unlimitStock,0) ,totalmoney=b.StockValue-- isnull((case when isnull(stock,0)=0 then 0 else b.stockvalue/stock end)*unlimitStock,0)+isnull(onordermoney,0)    
	from @table a,iMatsdorgLedger  b with(nolock)          
	where   a.matcode=b.matcode  
	and a.companyid=b.plantid
	and a.sdorgid=b.sdorgid
	--update @table set totaldigit=isnull(unlimitStock,0)+isnull(onorderstock,0),totalmoney=isnull(stockvalue,0)+isnull(onordermoney,0)    
 
  RETURN             
end