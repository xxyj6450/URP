/*
����:sp_QueryVndStorage
����:��ѯ��������
����:������
����ֵ:
��д:���ϵ�
ʱ��:2012-12-24
��ע:
ʾ��:
exec sp_QueryVndStorage '','ŵ���� ���','','2.1.020.32.25','','',''
 exec sp_QueryVndStorage '','','','2.1.020.01.01','','0','0' 
*/
alter proc sp_QueryVndStorage
	@Matcode varchar(50)='',				--��Ʒ����
	@MatName varchar(50)='',				--��Ʒ����,�����ÿո�,���ŵȷָ����������ؼ���
	@MatGroup varchar(50)='',				--��Ʒ����
	@SDorgID varchar(50)='',				--���ű���
	@VndCode varchar(50)='',				--��Ӧ�̱���
	@Minprice money=0,						--��߼�
	@MaxPrice money=0,						--��ͼ�
	@SearchText varchar(max)='',			
	@Orderby varchar(max)=''
as
	BEGIN
		declare @AreaID varchar(50),@sql varchar(max)
		declare @keywords table( data varchar(50))						--�ؼ����б�,���ؼ��ַֽ��һ�������
		create TABLE #MatInfo(
			Matcode varchar(50) primary key,
			MatName varchar(200),
			Matgroup varchar(200),
			Stock int,
			Price money,
			PurchaseFlag money,
			HotLevel int
		)
		if @Matcode='' and @MatGroup='' and @MatName='' select @Matcode='1.'
		--��û�д���ؼ���,��ֱ���˳�
		/*if (isnull(@MatGroup,'')='' and isnull(@Matcode,'')='' and isnull(@MatName,'')='') or @SDorgID =''
			BEGIN
				Select NULL as Matcode ,NULL as MatName,NULL as Matgroup,NULL as Stock,NULL as Price,NULL as PurchaseFlag
				return
			END
			*/
		--����ؼ���
		if isnull(@MatName,'')<>''
			BEGIN
				select @MatName=replace(@MatName,' ',',')
				select @MatName=replace(@MatName,'��',',')
				insert into @keywords(data)
				select ltrim(rtrim(isnull(s.List,''))) from commondb.dbo.SPLIT(@MatName,',') s where ltrim(rtrim(isnull(s.List,'')))<>''
			END
		--ȡ������
		select @AreaID=os.AreaID
		  from oSDOrg os with(nolock) where os.SDOrgID=@SDorgID
		--ȡ��ǰ5000��
		Insert Into #MatInfo 
		select top 5000 img.MatCode,img.matname,img.MatGroup,0 as stock,convert(money,0.00) as Price,isnull(img.PurchaseFlag,0) as PurchaseFlag,isnull(img.HotLevel,0)
		From iMatGeneral img with(nolock) --inner join iMatGroup img2 with(nolock) on img.MatGroup=img2.matgroup
		--outer APPLY dbo.uf_salesSDOrgpricecalcu3(img.matcode,@SDorgID,'') uss
		where (@MatName='' or  exists(select 1 from @keywords x where img.matname like '%'+x.data+'%' and x.data<>''))
		and (@MatGroup='' or img.MatGroup=@MatGroup)
		and (@Matcode='' or img.MatCode like @Matcode+'%')
		and img.matfor=1
		and  isactived=1
		and matstatus in ('�ص�����','��������') 
		--�ٸ��¼۸�
		update a
		set a.price=uss.selfprice1
		from #MatInfo a outer APPLY dbo.uf_salesSDOrgpricecalcu3(a.matcode,@SDorgID,'') uss 
		--���¿��
		;with cte (matcode,stock) AS (
			select matcode,im.unlimitStock
			from iMatstorage im with(nolock) inner join oStorage os with(nolock) on im.stcode=os.stcode
			where os.mainmark=1
			union all
			select matcode,im.unlimitStock 
			from iMatstorage_URP im with(nolock) inner join oStorage os with(nolock) on im.stcode=os.stcode
			where os.mainmark=1
			union all
			select matcode,im.Stock
			from sMatStorage_VND  im with(nolock)
		)
		,cte_Stock(matcode,stock) as(
			select matcode,sum(stock)
			from cte
			group by matcode
			)
		update a
			set a.Stock=b.stock
		from #MatInfo a inner join cte_Stock b with(nolock) on a.Matcode=b.matcode
		--��ʾ����
		Select Matcode,MatName,Matgroup,case when Stock>0 then '��' else '��' end as Stock  ,Price,a.HotLevel  
		  From #MatInfo a with(nolock)
		where (isnull(@Minprice,0)=0 or  a.price>=@Minprice)
		and (isnull(@maxPrice,0)=0 or  a.price<=@maxPrice)
		and isnull(a.Stock,0)>0
		and isnull(a.Price,0)>0
		order by a.HotLevel DESC, a.Matgroup
	END