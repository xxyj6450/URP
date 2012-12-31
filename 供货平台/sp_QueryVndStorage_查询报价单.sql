/*
����:sp_QueryVndStorage
����:��ѯ��������
����:������
����ֵ:
��д:���ϵ�
ʱ��:2012-12-24
��ע:
ʾ��:
exec sp_QueryVndStorage '','ŵ����,iphone','','2.1.020.32.25','','',''
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
			PurchaseFlag money
		)
		--��û�д���ؼ���,��ֱ���˳�
		if (isnull(@MatGroup,'')='' and isnull(@Matcode,'')='' and isnull(@MatName,'')='') or @SDorgID =''
			BEGIN
				Select NULL as Matcode ,NULL as MatName,NULL as Matgroup,NULL as Stock,NULL as Price,NULL as PurchaseFlag
				return
			END
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
		select top 5000 img.MatCode,img.matname,img.MatGroup,0 as stock,convert(money,0.00) as Price,isnull(img.PurchaseFlag,0) as PurchaseFlag 
		From iMatGeneral img with(nolock) --inner join iMatGroup img2 with(nolock) on img.MatGroup=img2.matgroup
		--outer APPLY dbo.uf_salesSDOrgpricecalcu3(img.matcode,@SDorgID,'') uss
		where (@MatName='' or  exists(select 1 from @keywords x where img.matname like '%'+x.data+'%' and x.data<>''))
		and (@MatGroup='' or img.MatGroup=@MatGroup)
		and (@Matcode='' or img.MatCode=@Matcode)
		and img.matfor=1
		and  isactived=1
		and matstatus in ('�ص�����','��������') 
		--�ٸ��¼۸�
		update a
		set a.price=uss.saleprice
		from #MatInfo a outer APPLY dbo.uf_salesSDOrgpricecalcu3(a.matcode,@SDorgID,'') uss
 
		--��ʾ����
		Select Matcode,MatName,Matgroup,Stock  ,Price   From #MatInfo a with(nolock)
		where (isnull(@Minprice,0)=0 or  a.price>=@Minprice)
		and (isnull(@maxPrice,0)=0 or  a.price<=@maxPrice)
		order by a.Matgroup
	END
	/*
     SELECT *, ( MatCode + ',' + matname ) AS name
     FROM   iMatGeneral WITH ( NOLOCK )
     WHERE  matfor = 1
            AND ( matstatus IN (
                  SELECT    list
                  FROM      getinstr(CASE WHEN '��������ģʽ' = '��������ģʽ'
                                          THEN ( '�ص�����,��������' )
                                          ELSE ( '�������,��Ʒ,��ͣ��,ȱ��' )
                                     END) )
                  AND ISNULL(isactived, 0) = 1
                )
            AND ( MatCode LIKE 'XXX%'
                  OR matname LIKE '%XXX%'
                )
     ORDER BY MATCODE
     
     */