/*
过程:sp_QueryVndStorage
功能:查询报价数据
参数:见声名
返回值:
编写:三断笛
时间:2012-12-24
备注:
示例:
exec sp_QueryVndStorage '','诺基亚 电池','','2.1.020.32.25','','',''
 exec sp_QueryVndStorage '','','','2.1.020.01.01','','0','0' 
*/
alter proc sp_QueryVndStorage
	@Matcode varchar(50)='',				--商品编码
	@MatName varchar(50)='',				--商品名称,可以用空格,逗号等分隔符传入多个关键字
	@MatGroup varchar(50)='',				--商品大类
	@SDorgID varchar(50)='',				--部门编码
	@VndCode varchar(50)='',				--供应商编码
	@Minprice money=0,						--最高价
	@MaxPrice money=0,						--最低价
	@SearchText varchar(max)='',			
	@Orderby varchar(max)=''
as
	BEGIN
		declare @AreaID varchar(50),@sql varchar(max)
		declare @keywords table( data varchar(50))						--关键字列表,将关键字分解成一个结果集
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
		--若没有传入关键字,则直接退出
		/*if (isnull(@MatGroup,'')='' and isnull(@Matcode,'')='' and isnull(@MatName,'')='') or @SDorgID =''
			BEGIN
				Select NULL as Matcode ,NULL as MatName,NULL as Matgroup,NULL as Stock,NULL as Price,NULL as PurchaseFlag
				return
			END
			*/
		--处理关键字
		if isnull(@MatName,'')<>''
			BEGIN
				select @MatName=replace(@MatName,' ',',')
				select @MatName=replace(@MatName,'，',',')
				insert into @keywords(data)
				select ltrim(rtrim(isnull(s.List,''))) from commondb.dbo.SPLIT(@MatName,',') s where ltrim(rtrim(isnull(s.List,'')))<>''
			END
		--取出区域
		select @AreaID=os.AreaID
		  from oSDOrg os with(nolock) where os.SDOrgID=@SDorgID
		--取出前5000行
		Insert Into #MatInfo 
		select top 5000 img.MatCode,img.matname,img.MatGroup,0 as stock,convert(money,0.00) as Price,isnull(img.PurchaseFlag,0) as PurchaseFlag,isnull(img.HotLevel,0)
		From iMatGeneral img with(nolock) --inner join iMatGroup img2 with(nolock) on img.MatGroup=img2.matgroup
		--outer APPLY dbo.uf_salesSDOrgpricecalcu3(img.matcode,@SDorgID,'') uss
		where (@MatName='' or  exists(select 1 from @keywords x where img.matname like '%'+x.data+'%' and x.data<>''))
		and (@MatGroup='' or img.MatGroup=@MatGroup)
		and (@Matcode='' or img.MatCode like @Matcode+'%')
		and img.matfor=1
		and  isactived=1
		and matstatus in ('重点主推','正常销售') 
		--再更新价格
		update a
		set a.price=uss.selfprice1
		from #MatInfo a outer APPLY dbo.uf_salesSDOrgpricecalcu3(a.matcode,@SDorgID,'') uss 
		--更新库存
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
		--显示数据
		Select Matcode,MatName,Matgroup,case when Stock>0 then '有' else '无' end as Stock  ,Price,a.HotLevel  
		  From #MatInfo a with(nolock)
		where (isnull(@Minprice,0)=0 or  a.price>=@Minprice)
		and (isnull(@maxPrice,0)=0 or  a.price<=@maxPrice)
		and isnull(a.Stock,0)>0
		and isnull(a.Price,0)>0
		order by a.HotLevel DESC, a.Matgroup
	END