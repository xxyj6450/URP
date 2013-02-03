alter function fn_query_SDorg_StockInAndOut(
	@begindate DATETIME,
	@enddate datetime,
	@companyid varchar(500),
	@sdorgid varchar(500),
	@matcode varchar(50),
	@matgroup varchar(200)
)
returns @table table(
	companyid varchar(50),											--��˾����
	companyname varchar(200),									--��˾����
	sdorgid varchar(50),												--�ŵ����
	sdorgname varchar(200),										--�ŵ�����
	matcode varchar(50),												--��Ʒ����
	matname varchar(200),											--��Ʒ����
	matgroup varchar(50),											--��Ʒ�������
	matgroupname varchar(200),									--��Ʒ��������
	BeginPeriod_stock int,											--�ڳ����
	BeginPeriod_stockvalue money,								--�ڳ������
	cur_Stock int,															--��ʱ���
	cur_StockValue money,											--��ʱ�����
	EndPeriod_Stock int,												--��ĩ���
	EndPeriod_StockValue money,									--��ĩ�����
	In_Purchase_stock int,												--�ɹ��������
	In_Purchase_stockValue money,								--�ɹ������
	In_Counting_stock int,												--��ӯ�������
	In_Counting_StockValue money,								--��ӯ�����
	In_Moving_Stock int,												--�����������
	In_Moving_StockValue money,									--���������
	Out_Counting_Stock int,											--�̿���������
	Out_Counting_StockValue money,							--�̿�������
	Out_AdjustPriceStock int,											--��������
	Out_AdjustPriceStockValue money,							--���۽��
	Out_MovingStock int,												--���γ�������
	Out_MovingStockValue money,								--���γ�����
	Out_SalesStock int,													--��������
	Out_SalesStockValue money,									--���۽��
	Out_JM_Stock int,													--��������������
	Out_JM_StockValue money,										--���������۽��
	Out_BatchSaleStock int,											--������������
	Out_BatchSaleStockValue money								--�������۽��
)
as
	BEGIN
		INSERT into @table( companyid, companyname, sdorgid, sdorgname, matcode, matname, 
		       matgroup, matgroupname, BeginPeriod_stock, BeginPeriod_stockvalue, 
		       cur_Stock, cur_StockValue, EndPeriod_Stock, EndPeriod_StockValue, 
		       In_Purchase_stock, In_Purchase_stockValue, In_Counting_stock, 
		       In_Counting_StockValue, In_Moving_Stock, In_Moving_StockValue, 
		       Out_Counting_Stock, Out_Counting_StockValue, Out_AdjustPriceStock, 
		       Out_AdjustPriceStockValue, Out_MovingStock, Out_MovingStockValue, 
		       Out_SalesStock, Out_SalesStockValue, Out_JM_Stock, 
		       Out_JM_StockValue, Out_BatchSaleStock, Out_BatchSaleStockValue)
		Select i.plantid,op.plantname,i.sdorgid,os.SDOrgname,i.matcode,img.matname,
		img.MatGroup,img2.matgroupname,0 as BeginPeriod_stock,0 as BeginPeriod_stockvalue,
		0 as cur_Stock,0 as cur_StockValue,0 as EndPeriod_Stock,0 as EndPeriod_StockValue,
		sum(case when i.formid in(1509,1504,4630,4631) then i.indigit else 0 end ) as In_Purchase_stock,
		sum(case when i.formid in(1509,1504,4630,4631) then i.inledgeramount else 0 end ) as In_Purchase_stockValue,
		sum(case when i.formid in(1559,1520) then i.indigit else 0 end ) as In_Counting_stock,
		sum(case when i.formid in(1559,1520) then i.inledgeramount else 0 end ) as In_Counting_StockValue,
		sum(case when i.formid in(1507,4061,4032) then i.indigit else 0 end ) as In_Moving_Stock,
		sum(case when i.formid in(1507,4061,4032) then i.inledgeramount else 0 end ) as In_Moving_StockValue,
		sum(case when i.formid in(1501,1598) then i.outdigit else 0 end ) as Out_Counting_Stock,
		sum(case when i.formid in(1501,1598) then i.outledgeramount else 0 end ) as Out_Counting_Stock,
		sum(case when i.formid in(1512,2136) then -i.indigit else 0 end ) as Out_AdjustPriceStock,
		sum(case when i.formid in(1512,2136) then -i.inledgeramount else 0 end ) as Out_AdjustPriceStock,
		sum(case when i.formid in(2424,4031,4062,1523) then i.outdigit else 0 end ) as Out_MovingStock,
		sum(case when i.formid in(2424,4031,4062,1523) then i.outledgeramount else 0 end ) as Out_MovingStock,
		sum(case when i.formid in(2419,2420) then i.outdigit   else 0 end ) as Out_SalesStock,
		sum(case when i.formid in(2419,2420) then i.outdigit   else 0 end )  as Out_SalesStockValue,
		sum(case when i.formid in(4950,4951) then i.outdigit   else 0 end ) as Out_JM_Stock,
		sum(case when i.formid in(4950,4951) then i.outdigit   else 0 end )  as Out_JM_StockValue,
		sum(case when i.formid in(2401,2418) then i.outdigit   else 0 end ) as Out_BatchSaleStock,
		sum(case when i.formid in(2401,2418) then i.outdigit   else 0 end )  as Out_BatchSaleStockValue		
		From istockledgerlog i with(nolock) 
		inner join oPlant op with(nolock) on i.plantid=op.plantid
		inner join oSDOrg os with(nolock) on i.sdorgid=os.SDOrgID
		inner join iMatGeneral img with(nolock) on img.MatCode=i.matcode
		inner join iMatGroup img2 with(nolock) on img.matgroup=img2.matgroup
		group by i.plantid,op.plantname,i.sdorgid,os.SDOrgname,i.matcode,img.matname,
		img.MatGroup,img2.matgroupname
		--���Ͽ��
		update a
			set a.cur_stock=imp.Stock,
			a.cur_stockvalue=imp.StockValue
		from @table a,iMatsdorgLedger  imp with(nolock)
		where a.sdorgid=imp.sdorgid

		return 
	END
	/*
declare @sql varchar(max)
select @sql=''
select @sql=@sql+name+','
from syscolumns s where id=object_id('fn_query_SDorg_StockInAndOut')
print @sql
*/