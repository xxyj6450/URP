/*
��������:fn_QueryQuotePrices
��������:��ѯ��������
����:������
����ֵ:
��д:���ϵ�
ʱ��:2013-01-02
��ע:select * from fn_QueryQuotePrices('','','','','')
ʾ��:
*/
alter FUNCTION fn_QueryQuotePrices(
	@BeginDate DATETIME,
	@EndDate datetime,
	@Matcode varchar(50),
	@MatGroup varchar(50),
	@VndCode varchar(50)
)/*
returns @table table(
	QuoteDate datetime,
	matcode varchar(50),
	matname varchar(200),
	matgroup varchar(50),
	matgroupname varchar(200),
	vndcode varchar(50),
	vndName varchar(200),
	Price money,
	EnterName varchar(50)
)*/
returns table
return
select docdate,img.matcode,img.matname,img.matgroup,img2.matgroupname,a.vndcode,a.vndname,convert(money,b.curSalePrice) as curSalePrice
from CommonDoc_HD a with(nolock) inner join AdjustPrice_DT b with(nolock) on a.Doccode=b.Doccode
inner join iMatGeneral img with(nolock) on b.Matcode=img.matcode
inner join iMatGroup img2 on img.matgroup=img2.matgroup
where (@BeginDate='' or a.DocDate>=@BeginDate)
and (@EndDate='' or a.DocDate<=@EndDate)
and (@VndCode='' or a.vndcode=@VndCode)
and (@Matcode='' or b.Matcode='')
and (@MatGroup='' or img2.path like '%/'+@MatGroup+'/%')



 