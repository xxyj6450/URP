/*
�������ƣ�fn_oSDorg_StockMatLedger
������������ѯ���ſ��ɱ���ϸ
������������
����ֵ��
��д�����ϵ�
ʱ�䣺2013-01-30
��ע��
����ʾ����select * from fn_oSDorg_StockMatLedger('','','','')     
*/    
alter   FUNCTION dbo.fn_oSDorg_StockMatLedger
         (
         @companyid varchar(200),      
         @SdorgID varchar(50),
         @matcode varchar(8000),      
         @matgroup varchar(200)  
   )      
RETURNS table /* @table TABLE       
         (companyid varchar(20),      
         companyname varchar(100),
         Sdorgid varchar(50),
         sdorgname varchar(200),
         matcode varchar(60),      
         goodsno varchar(60),      
         matname varchar(200),      
         matgroup varchar(60),         
         physicalstock money,      
         selfstock money,--����      
         cltspstock money,      
         vndspstock money,      
         transledger money,      
         stockvalue money,--���      
         packagecode varchar(50),physicalbasestock money,costprice money,--����      
         matlife varchar(50),dismoney money,crprice money,ontransdigit money,ontransamount money   
)      
AS      
BEGIN      */
 
	return
	select a.PlantID as companyid,oc.plantname as companyname,a.sdorgid,os.SDOrgName,a.MatCode,
	img.matname,img.MatGroup,img2.matgroupname,a.Stock,a.StockValue,a.ratevalue,isnull(1.0000*a.stockvalue/nullif(a.stock,0),0) as MAP,isnull(1.0000*a.ratevalue/nullif(a.stock,0),0) as ratemap
	from iMatsdorgLedger a with(nolock)
	inner join oPlant  oc with(nolock) on a.PlantID=oc.plantid
	inner join oSDOrg os with(nolock) on a.sdorgid=os.SDOrgID
	inner join iMatGeneral img with(nolock) on a.MatCode=img.MatCode
	inner join iMatGroup img2 with(nolock) on img.MatGroup=img2.matgroup
	where (@companyid='' or a.PlantID=@companyid)
	and (@SdorgID='' or os.PATH like '%/'+@SdorgID+'/%')
	and (@matcode='' or a.MatCode=@matcode)
	and (@matgroup='' or img2.PATH like '%/'+@matgroup+'/%')
	/*
RETURN       
END*/      
 