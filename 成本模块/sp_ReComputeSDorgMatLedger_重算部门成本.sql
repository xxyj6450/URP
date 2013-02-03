alter proc sp_ReComputeSDorgMatLedger
	@FormID int,
	@Doccode varchar(50),
	@OptionID varchar(max)='',
	@Usercode varchar(50)='',
	@TerminalID varchar(50)=''
as
BEGIN
	DECLARE @map MONEY,@ratemap MONEY,@refcode VARCHAR(50),@sdorgid VARCHAR(50),
	@matcode VARCHAR(50),@companyid VARCHAR(50),@matcode1 VARCHAR(50),@rowid VARCHAR(50),@PeriodID varchar(50)
	declare @plantid varchar(50),@digit int,@totalmoney money,@ratemoney money,@mode money,@type int,@i int,@Count int
	declare @RefDate DATETIME
	create table #table  (
		ID int identity(1,1),
		matcode varchar(50),
		Rowid varchar(50),
		digit int DEFAULT 0,
		totalmoney money default 0,
		ratemoney money DEFAULT 0,
		Mode int DEFAULT 0,
		ComputeType varchar(50) DEFAULT ''
	)
	
 	IF @formid IN (1509,1520) --采购入库单、盘盈入库单
	BEGIN
		insert into #table
		select  matcode,a.rowid,a.Digit,a.netmoney,a.netmoney,a.netmoney,3,''
		From imatdoc_d a with(nolock)
		where a.DocCode=@Doccode
		--UPDATE imatdoc_d SET rateprice = netprice,ratemoney = netmoney WHERE doccode=@doccode
		--SELECT netprice,ratemoney,* FROM vCommsales WHERE doccode='GDR2013020200000'
	END
	
	IF @formid IN (4630)  --代销入库单
	BEGIN
		insert into #table
		select matcode,a.rowid,a.Digit,a.totalmoney,a.netmoney,a.netmoney,3,''
		from Commsales_d a with(nolock)
		where a.DocCode=@Doccode
		--UPDATE Commsales_d SET rateprice = netprice,ratemoney = netmoney WHERE doccode=@doccode
	END
	IF @formid IN (2420) --销售退货单取销售出库单成本入库
	BEGIN
		--取得销售单号
		SELECT @refcode=ClearDocCode,@sdorgid=sdorgid
		  FROM spickorderhd with(nolock) WHERE doccode=@doccode
		--取得销售信息
		if isnull(@refcode,'')<>''
			BEGIN
				select @RefDate=sph.DocDate
				from sPickorderHD sph with(nolock) 
				where sph.DocCode=@refcode
				--按照业务规则,若销售日期在于2012年12月以前,则取2012年12月份的期末余额,否则取销售单的销售成本
				if @RefDate<'2013-01-01'
					BEGIN
						insert into #table(matcode,Rowid,totalmoney,ratemoney,Mode,ComputeType)
						select sp.MatCode,sp.rowid,isnull(i.stockvalue/nullif(stock,0),0),isnull(i.ratevalue/nullif(stock,0),0),4,''
						from sPickorderitem sp with(nolock) inner join imatsdorgbalance i with(nolock) on sp.MatCode=i.matcode and i.sdorgid=@sdorgid and i.periodid='2012-12'
						where sp.DocCode=@Doccode
					END
				else
				BEGIN
						--不考虑一张销售单上同一个商品出现多行,也不考虑退货的商品在零售单中不存在
						insert into #table(matcode,Rowid,totalmoney,ratemoney,Mode,ComputeType)
						select sp.MatCode,sp.rowid,sp.netmoney,sph.ratemoney,4,''
						from spickorderitem sp with(nolock),sPickorderitem  sph with(nolock)    
						where sph.DocCode=@refcode
						and sp.DocCode=@Doccode
						and sp.MatCode=sph.MatCode
						and isnull(sp.seriesCode,'')=isnull(sph.seriesCode,'')
					END
				
			END
		--若没有退货单,则取此商品在此门店的最后一次出库成本
		else
		BEGIN
			;with cte as(
				select max(id) as id,sp.MatCode,sp.rowid,sp.Digit
				from sPickorderitem sp with(nolock) inner join istockledgerlog i with(nolock) on  i.sdorgid=@sdorgid and i.matcode=sp.MatCode		 
				where sp.DocCode=@Doccode
				and (i.indigit<0 or i.outdigit>0)						--出库数量大于0,或入库数量小于0,则认为是出库
				group by sp.MatCode,sp.rowid,sp.Digit
				) 
				--insert into #table(matcode,Rowid,totalmoney,ratemoney,Mode,ComputeType)
				select b.MatCode,b.rowid,b.digit,
				--关于下面这个坑爹表达式的说明.取出库成本和加成出库成本.成本为正数,所以取绝对值.出库金额有可能记录在出库项,也可能记录在入库项(用负数记录),当然优先取出库项,若出库项为0,则转取入库项.
				--出库成本为出库金额除以出库数量,所以有个除号,而除数可能为0,所以用nullif处理除数为0的情况,作用是将0转换成NULL,防止除数为0的错误
				--当然除了除数为0或为NULL,金额也可能为0,就将金额转成NULL,然后转向取inledgeramount,这个转向是靠coalesce实现的
				--当然,任何表达式的结果可能为NULL,而我们不希望成本为NUL,所以最外层有一个ISNULL,将可能的NULL转换成0
				--要是还看不懂的话你可以骂我,但不要来问我,因为明天我也会完全忘记这段表达式的含义,同时也包括上面的说明文字.
				--2013-02-02 03:26 三断笛
				isnull(abs(coalesce(nullif(1.0000*i.outledgeramount/nullif(i.outledgerdigit,0),0),nullif(1.0000*i.inledgeramount/nullif(i.inledgerdigit,0),0))),0),
				isnull(abs(coalesce(nullif(1.0000*i.outrateamount/nullif(i.outledgerdigit,0),0),nullif(1.0000*i.inrateamount/nullif(i.inledgerdigit,0),0))),0),4,''
				from istockledgerlog i  inner join cte b on i.id=b.id
				--若经匹配后,发现有商品没有最后一次出库记录,则抛出异常,没有成本也想退货?
				if (select count(*) from sPickorderitem sp with(nolock) where sp.DocCode=@Doccode)<>(select count(*) from #table)
					BEGIN
						raiserror('商品未有出库记录,无法取得最后一次出库成本,无法退货.',16,1)
						return
					END
			END
		
		--SELECT @map=netprice,@ratemap= FROM spickorderitem where doccode=@refcode
		--更新退货入库单成本
		--SELECT m.rateprice,m.ratemoney,s.rateprice,s.ratemoney,m.netprice,m.netmoney,s.netprice,s.netmoney,*
		/*UPDATE m SET netprice=s.netprice,netmoney=s.netmoney,rateprice=s.rateprice,ratemoney=s.ratemoney,matcost=s.netmoney
		FROM spickorderhd d left join spickorderitem m ON d.doccode=m.doccode LEFT JOIN spickorderitem s ON d.ClearDocCode=s.DocCode
		AND m.matcode=s.matcode AND ISNULL(m.seriescode,'')=ISNULL(s.seriesCode,'') WHERE d.doccode=@doccode--'RT20130106000480'*/
	END
	IF @formid IN (1507) --从调拨出库单取成本
	BEGIN
		--取得调拨出库单号
		
		--取得调拨入库单成本
		UPDATE d SET matcost=s.netmoney,price=s.netprice,totalmoney=s.netmoney,netprice=s.netprice,netmoney=s.netmoney,rateprice=s.rateprice,ratemoney=s.ratemoney
		FROM imatdoc_h h left join imatdoc_d d ON h.doccode=d.doccode LEFT JOIN spickorderitem s ON h.refCode=s.DocCode
		AND d.matcode=s.matcode WHERE d.doccode=@doccode--'RT20130106000480'
	END
	
	IF @formid IN (4061) --内部采购入库取销售出库成本
	BEGIN

		--取得调拨入库单成本
		UPDATE d SET matcost=s.netprice,price=s.netprice,totalmoney=s.netmoney,netprice=s.netprice,netmoney=s.netmoney,rateprice=s.rateprice*(100+l.addpresent)/100,ratemoney=s.digit*s.rateprice*(100+l.addpresent)/100
		FROM imatdoc_h h left join imatdoc_d d ON h.doccode=d.doccode LEFT JOIN spickorderitem s ON h.refCode=s.DocCode
		AND d.matcode=s.matcode LEFT JOIN imatgeneral l ON s.matcode=l.matcode WHERE d.doccode=@doccode--'RT20130106000480'
	END
	IF @formid IN (4032) --内部批发销售退货取内部采购退货成本
	BEGIN

		--取得调拨入库单成本
		UPDATE d SET price=s.netprice,totalmoney=s.netmoney,netprice=s.netprice,netmoney=s.netmoney,rateprice=s.rateprice/(100+l.addpresent)/100,ratemoney=s.digit*s.rateprice/(100+l.addpresent)/100
		FROM imatdoc_h h left join imatdoc_d d ON h.doccode=d.doccode LEFT JOIN spickorderitem s ON h.refCode=s.DocCode
		AND d.matcode=s.matcode LEFT JOIN imatgeneral l ON s.matcode=l.matcode WHERE d.doccode=@doccode--'RT20130106000480'
	END
	IF @formid IN (2418,4951)
	BEGIN
		SELECT @companyid=companyid,@sdorgid=sdorgid FROM spickorderhd WHERE doccode=@doccode
		
		declare cur cursor scroll for
		select distinct matcode from spickorderitem WHERE doccode=@doccode
		open cur
		fetch first from cur into @matcode
		while @@fetch_status=0
		begin
		 SELECT @map=stockvalue/stock,@ratemap=ratevalue/stock FROM iMatsdorgLedger WHERE plantid=@companyid AND sdorgid=@sdorgid AND matcode=@matcode AND stock>0
		 UPDATE spickorderitem SET netprice=@map,netmoney=digit*@map,rateprice=digit*@ratemap,ratemoney=digit*@ratemap,matcost=digit*@map
		 WHERE doccode=@doccode
		 --取不到库存成本，则取最后一次入库成本
		 IF @map IS NULL
		 begin
		 SELECT TOP 1 @map=(case when formid in (2418,2420,4951,4032) then outledgeramount/outledgerdigit else inledgeramount/inledgerdigit END) 
		 FROM istockledgerlog WHERE formid IN (1509,4630,1507,1520,1512,4061,1599,2418,2420,4951,4032) and sdorgid=@sdorgid ORDER BY inserttime desc
		 END
		 --否则报错，不允许错误
		 IF @map IS NULL
		 BEGIN
		 	RAISERROR('取不到成本！不能确认，请检查!',16,1)
		 	return
		 END
		 fetch next from cur into @matcode
		end
		close cur
		deallocate cur
	END
	--串号调整，返厂返回
	IF @formid IN (1553,1557)
	BEGIN
		declare cur cursor scroll for
		select distinct e.sdorgid,m.rowid,m.matcode,m.matcode1 from iseriesloghd d left join iserieslogitem m ON d.doccode=m.doccode 
		LEFT JOIN vStorage e ON d.stcode=e.stcode
		--WHERE d.doccode='IC20130106000120'
		WHERE d.doccode=@doccode
		open cur
		fetch first from cur into @sdorgid,@rowid,@matcode,@matcode1
		while @@fetch_status=0
		BEGIN
			SELECT @map=stockvalue/stock FROM iMatsdorgLedger WHERE sdorgid=@sdorgid AND matcode=@matcode1		--出库商品的成本
			--入库商品的成本
			SELECT @ratemap=stockvalue/stock FROM iMatsdorgLedger WHERE sdorgid=@sdorgid AND matcode=@matcode AND stock>0	--入库商品的成本
			IF  @ratemap IS NULL
			BEGIN
				SET @ratemap=@map
			END
			UPDATE iserieslogitem SET netmoney=@ratemap,netmoney1=@map WHERE doccode=@doccode AND rowid=@rowid
		 fetch next from cur into @sdorgid,@rowid,@matcode,@matcode1
		end
		close cur
		deallocate cur
	END
	----------------------------------------------------------------开始计算成本-------------------------------------------------------------------
	select @i=1,@count=count(*) from #table
	if @Count<=0 return
	
	while @i<=@count 
		BEGIN
			select @digit=digit,@totalmoney=totalmoney,@ratemoney=ratemoney
			from #table
			where id=@i
			exec sp_ComputeSdorgMatLedger @Doccode,@FormID,@rowid,@matcode,@plantid,@sdorgid,@PeriodID,@digit,@totalmoney,@ratemoney,@mode,@type
			set @i=@i+1
		END
	
	return
END