create proc sp_ReComputeSDorgMatLedger
	@FormID int,											--单据功能号
	@Doccode varchar(50),							--单据编码
	@CompanyID varchar(50),						--公司
	@PeriodID varchar(50),							--期间
	@SDOrgID varchar(50)='',						--部门编码
	@DocDate datetime='',							--单据日期
	@InputMatgroup varchar(200)='',			--待重算的大类
	@InputMatcode varchar(200)='',				--待重算的商品编码
	@RefFormID int  =0,								--引用功能号
	@RefCode varchar(50)='',						--引用单号
	@OptionID varchar(max)='',					--选项
	@InsertTime datetime ='',						--明细账重算时间
	@Usercode varchar(50)='',						--执行人
	@TerminalID varchar(50)=''						--执行终端编码
as
BEGIN
	set NOCOUNT on
	DECLARE @map MONEY,@ratemap MONEY,@matcode VARCHAR(50), @matcode1 VARCHAR(50),@rowid VARCHAR(50)
	declare @RefDate datetime,@RefPlantID varchar(50),@RefSdorgID varchar(50)
	declare @plantid varchar(50),@digit int,@totalmoney money,@ratemoney money,@mode money,@type int,@i int,@Count int
	declare @XMLResult nvarchar(max),@XMLData nvarchar(max)
	declare @hDocument int
	declare @tips varchar(max)
	--用户保存待处理成本的信息
	create table #table  (
		ID int identity(1,1),
		FormID int,
		Doccode varchar(50),
		PeriodID varchar(50),
		PlantID varchar(50),
		SDOrgID varchar(50),
		Seriescode varchar(50),
		matcode varchar(50),
		Rowid varchar(50),
		digit int DEFAULT 0,
		totalmoney money default 0,
		ratemoney money DEFAULT 0,
		Mode int DEFAULT 0,
		ComputeType varchar(50) DEFAULT ''
	)
	--用于输出计算结果的表变量
	 Create Table #XMLDataTable (
 		Matcode varchar(50),						--商品编码
		RowID varchar(50),							--x
 		OldStock int,									--原库存
 		OldStockValue money,					--原库存金额
 		OldRateValue money,						--原加成金额
		Digit int,										--修改库存量
		Totalmoney money,						--修改库存金额
		RateMoney money,						--修改加成金额
 		Stock int,										--结果库存量
 		StockValue money,							--结果库存金额
 		RateValue money,							--结果加成金额
		Mode char,									--出入库模式 1出库正数，2出库负数，3入库正数，4入库负数
		ComputeType  varchar(50)				--计算模式
	 )
	print '计算成本:'+isnull(convert(varchar(30),@InsertTime ,120),'')+'--->'+@Companyid +','+@PeriodID +','+@SDOrgID +','+convert(varchar(10),@FormID)+','+ @Doccode+','+'>>>>'+convert(varchar(30),getdate(),120)
	--1509采购入库单，以采购单的成本/加成成本入库,来源于sp_countcost
	--1520盘盈入库，以工手录入成本入库
	--1599其它入库单，以手录入成本入库
 	IF @formid IN (1509,1520,1599) --采购入库单、盘盈入库单
	BEGIN
		insert into #table(matcode,Rowid,digit,totalmoney,ratemoney,Mode,ComputeType)
		select  a.matcode,a.rowid,a.Digit,a.netmoney,a.netmoney,3,''
		From imatdoc_d a with(nolock)
		where a.DocCode=@Doccode
		 
		--UPDATE imatdoc_d SET rateprice = netprice,ratemoney = netmoney WHERE doccode=@doccode
		--SELECT netprice,ratemoney,* FROM vCommsales WHERE doccode='GDR2013020200000'
	END
	--领料出库单,直接取单据的金额,领料出库单
	if @FormID in(1504,1523)
		BEGIN
			insert into #table(matcode,Rowid,digit,totalmoney,ratemoney,Mode,ComputeType)
			select  a.matcode,a.rowid,a.Digit,a.netmoney,a.ratemoney,2,''
			From imatdoc_d a with(nolock)
			where a.DocCode=@Doccode
		END
	--1501,1598其他出库单,盘亏出库单,以单据金额计算成本
	if @FormID in(1501,1598)
		BEGIN
			insert into #table(matcode,Rowid,digit,totalmoney,ratemoney,Mode,ComputeType)
			select  a.matcode,a.rowid,a.Digit,a.netmoney,a.ratemoney,1,''
			From imatdoc_d a with(nolock)
			where a.DocCode=@Doccode
		END
	--4630受托代销入库单，以入库的成本/加成成本入库,来源于[sp_countcost]
	IF @formid IN (4630)  --代销入库单
	BEGIN
		insert into #table(matcode,Rowid,digit,totalmoney,ratemoney,Mode,ComputeType)
		select a.matcode,a.rowid,a.Digit,a.netmoney,a.netmoney,3,''
		from Commsales_d a with(nolock) 
		where a.DocCode=@Doccode 
		--UPDATE Commsales_d SET rateprice = netprice,ratemoney = netmoney WHERE doccode=@doccode
	END
	--4631 供应商代销退货单,以单据上金额出库
	if @FormID in(4631)
		BEGIN
			insert into #table(matcode,Rowid,digit,totalmoney,ratemoney,Mode,ComputeType)
			select a.matcode,a.rowid,a.Digit,a.netmoney,a.ratemoney,1,''
			from Commsales_d a with(nolock) 
			where a.DocCode=@Doccode 
		END
	--零售销售单
	if @FormID in(2419,2401,2450,4950)
		BEGIN
			insert into #table(matcode,Rowid,digit,totalmoney,ratemoney,Mode,ComputeType)
			select sp.MatCode,sp.rowid,digit,netmoney,sp.ratemoney,1,''					
			from sPickorderitem sp with(nolock)
			where sp.DocCode=@Doccode
		END
	--有库存就取库存成本,没库存就取源销售单成本,若无源销售单,则取最近一次销售成本.
	IF @formid IN (2420) --销售退货单取销售出库单成本入库
	BEGIN
		--取库存成本
		--技巧,如何判断是否有库存成本。
		--是否有库存成本的标准是，库存成本无记录，或库存成本的数量为0或NULL，若有库存，而stockvalue为NULL，则算库存金额为0
		--下面代码中，用isnull(iml.StockValue,0)/nullif(iml.Stock,0)计算成本，这个表达式只有在stock为0或NULL时才会得到NULL值，其余情况都不会。
		--将此值更新到totalmoney字段
		--后续只需判断Totalmoney是否为NULL即可判断是否有库存成本
		insert into #table(Doccode,FormID,Seriescode,matcode,Rowid,digit,totalmoney,ratemoney,Mode,ComputeType)
						select @Doccode,@FormID, sp.seriesCode, sp.MatCode,sp.rowid,sp.digit,1.00*sp.digit*isnull(iml.StockValue,0)/nullif(iml.Stock,0),1.00*sp.digit*isnull(iml.ratevalue,0)/nullif(iml.Stock,0),4,''			 
						from spickorderitem sp with(nolock) Left join iMatsdorgLedger iml with(nolock) on sp.MatCode=iml.MatCode and iml.sdorgid=@SDOrgID
						inner join iMatGeneral img with(nolock) on sp.matcode=img.MatCode
						where sp.DocCode=@Doccode
						and img.MatState=1								--只处理做库存管理的商品
		--若有商品无库存成本，则尝试从源单据取
		if exists(select 1 from #table where totalmoney is null)
			BEGIN
				--有源单号则从源单据取成本
				if isnull(@refcode,'')<>'' 
					BEGIN
						--不考虑一张销售单上同一个商品出现多行,也不考虑退货的商品在零售单中不存在
						--insert into #table(matcode,Rowid,digit,totalmoney,ratemoney,Mode,ComputeType)
						--select sp.MatCode,sp.rowid,sp.digit,sph.MatCost,sph.ratemoney,4,''			--改用matcost,不用netmoney,因为前期许多单据没写netmoney
						update sp
							set totalmoney = sph.MatCost,ratemoney = sph.ratemoney
						from #table sp with(nolock) 
						inner join sPickorderitem  sph with(nolock) on sp.DocCode=@Doccode  AND sph.DocCode=@refcode AND   sp.MatCode=sph.MatCode And isnull(sp.seriesCode,'')=isnull(sph.seriesCode,'')
						where sp.totalmoney is null						--只处理金额为NULL的数据
						if @@ROWCOUNT=0
							BEGIN
								raiserror('未能正常关联退货单与销售单,无法处理退货成本.',16,1)
								return
							END	
					END
				--若没有退货单,则取此商品在此门店的最后一次出库成本
				else
				BEGIN
					;with cte as(
						select max(i.id) as id,sp.MatCode,sp.rowid,sp.Digit
						from #table sp with(nolock) inner join istockledgerlog i with(nolock) on  i.sdorgid=@sdorgid and i.matcode=sp.MatCode		 
						inner join istockledgerlog i2 with(nolock) on sp.DocCode=i2.doccode and i2.matcode=sp.MatCode
						where sp.DocCode=@Doccode
						and (i.indigit<0 or i.outdigit>0)						--出库数量大于0,或入库数量小于0,则认为是出库
						and i.inserttime<i2.inserttime								--只取当前退货日期前的最后一次出库
						group by sp.MatCode,sp.rowid,sp.Digit
						) 
						--insert into #table(matcode,Rowid,digit,totalmoney,ratemoney,Mode,ComputeType)
						--select b.MatCode,b.rowid,b.digit,
						--关于下面这个坑爹表达式的说明.取出库成本和加成出库成本.成本为正数,所以取绝对值.出库金额有可能记录在出库项,也可能记录在入库项(用负数记录),当然优先取出库项,若出库项为0,则转取入库项.
						--出库成本为出库金额除以出库数量,所以有个除号,而除数可能为0,所以用nullif处理除数为0的情况,作用是将0转换成NULL,防止除数为0的错误
						--当然除了除数为0或为NULL,金额也可能为0,就将金额转成NULL,然后转向取inledgeramount,这个转向是靠coalesce实现的
						--当然,任何表达式的结果可能为NULL,而我们不希望成本为NUL,所以最外层有一个ISNULL,将可能的NULL转换成0
						--要是还看不懂的话你可以骂我,但千恨不要来问我,因为明天我也会完全忘记这段表达式的含义,同时也包括上面的说明文字.
						--2013-02-02 03:26 三断笛
						update a
							set a.totalmoney=isnull(abs(coalesce(nullif(1.0000*i.outledgeramount/nullif(i.outledgerdigit,0),0),nullif(1.0000*i.inledgeramount/nullif(i.inledgerdigit,0),0))),0),
						ratemoney=isnull(abs(coalesce(nullif(1.0000*i.outrateamount/nullif(i.outledgerdigit,0),0),nullif(1.0000*i.inrateamount/nullif(i.inledgerdigit,0),0))),0)
						from   istockledgerlog i with(nolock)  inner join cte b on i.id=b.id inner join #table a on b.rowid=a.Rowid and a.matcode=b.matcode
						where a.totalmoney is null
				END
			END
			--select * From #table
			--若经匹配后,发现有商品没有最后一次出库记录,则抛出异常,没有成本也想退货?
			select @tips=''
			select @tips=@tips+'商品'+ a.matcode+'未取到出库成本，无法退货。'+char(10)
			from #table a
			if @@ROWCOUNT=0
				BEGIN
					raiserror(@tips,16,1)
					return
				END
	END
	--调拔出库单,公司内销售单,来源于sp_delloutcost
	if @FormID in(2424,4031)
		BEGIN
			insert into #table(Doccode,Formid,plantid,periodid,sdorgid,matcode,Rowid,digit,totalmoney,ratemoney,Mode,ComputeType)
				select @Doccode,@FormID, @CompanyID,@PeriodID,@SDOrgID, sp.MatCode,sp.rowid,isnull(digit,0),isnull(sp.netmoney,0),isnull(sp.ratemoney,0),1,''
				from sPickorderitem sp with(nolock) 
				where sp.DocCode=@Doccode
				--and isnull(sp.Digit,0)<>0
		END
	--公司内采购退货,来源于sp_delloutcost
	IF @formid=4062
	BEGIN
		insert into #table(matcode,Rowid,digit,totalmoney,ratemoney,Mode,ComputeType)
				select sp.MatCode,sp.rowid,isnull(digit,0),isnull(sp.netmoney,0),isnull(sp.ratemoney,0),2,''
				from imatdoc_d sp with(nolock) 
				where sp.DocCode=@Doccode
				--select * from iMatsdorgLedger iml where iml.sdorgid='101.05.02' and matcode='1.11.013.1.1.1'
	END
	--调拔入库单,先处理出库,再处理入库.
	--调拨入库，取调拨出库的成本，如调拨出库单为2012-12期间前，则取2012-12初始成本imatledger_bak
	IF @formid IN (1507) --从调拨出库单取成本
	BEGIN
		---------------------------------------------------------调出处理----------------------------------------------------
		--取得调拨出库信息
		update ih set @RefPlantID=ih.companyid,@RefSdorgID=ih.sdorgid,@RefDate=ih.DocDate,ih.DocDate = @Docdate,ih.periodid = @PeriodID
		from sPickorderHD  ih with(nolock)
		where ih.DocCode=@Refcode
		and ih.FormID=@RefFormID
		if @@ROWCOUNT=0
			BEGIN
				raiserror('不存在调拔出库单,成本处理无法继续,请联系系统管理员.',16,1)
				return
			END
		--SELECT @rowid=rowid,@matcode=matcode,@plantid=companyid,@sdorgid=sdorgid,@periodid=periodid,@digit=digit,@totalmoney=totalmoney,@ratemoney=ratemoney
		--先处理调出的成本
		exec sp_ReComputeSDorgMatLedger 2424,@RefCode,@RefPlantID,@PeriodID,@RefSdorgID,@DocDate,@InputMatgroup,@InputMatcode ,default,default,default,@Usercode,@TerminalID
		--调拨入库，取调拨出库的成本，如调拨出库单为2012-12期间前，则取2012-12初始成本imatledger_bak
		if @refDate<'2013-01-01'
			BEGIN
				insert into #table( Doccode,FormID,plantid,periodid,sdorgid,matcode,Rowid,digit,totalmoney,ratemoney,Mode,ComputeType)
				select  @Doccode,@FormID,@CompanyID,@PeriodID,@SDOrgID, sp.MatCode,sp.rowid,sp.Digit,isnull(1.0000*iml.stockvalue/nullif(iml.stock,0),0),isnull(1.0000*iml.ratevalue/nullif(iml.stock,0),0),3,''
				from sPickorderitem sp with(nolock) inner join imatsdorgbalance  iml with(nolock)
				on sp.MatCode=iml.MatCode
				and iml.sdorgid=@SDOrgID
				and iml.periodid='2012-12'
				and sp.DocCode=@Refcode
			END
		else
			BEGIN
				insert into #table( Doccode,FormID,plantid,periodid,sdorgid,matcode,Rowid,digit,totalmoney,ratemoney,Mode,ComputeType)
				select  @Doccode,@FormID,@CompanyID,@PeriodID,@SDOrgID,sp.MatCode,sp.rowid,isnull(sp.digit,0),isnull(sph.netmoney,0),isnull(sph.ratemoney,0),3,''
				from imatdoc_d sp with(nolock) inner join sPickorderitem sph with(nolock)
				on sp.DocCode=@Doccode and sph.DocCode=@RefCode and sp.MatCode=sph.MatCode
			END
	END
	--4061内部采购入库，以内部批发销售出库成本入库，子公司加成成本加点数
	IF @formid IN (4061) --内部采购入库取销售出库成本
	BEGIN
		--先处理公司内销售单成本
		if isnull(@RefCode,'')='' 
			begin 
				raiserror('未传入公司内销售单信息,无法处理公司内采购入库成本',16,1)
				return
			end
		--取出公司内销售单信息
		update a set  @RefDate=a.DocDate,@RefPlantID=a.plantid,@RefSdorgID=a.sdorgid,docdate=@DocDate,a.periodid = @PeriodID
		From spickorderhd a with(nolock)
		where a.FormID=@RefFormID
		and a.DocCode=@RefCode
		if @@ROWCOUNT=0
			BEGIN
				raiserror('不存在对应的公司内部销售单,无法处理公司内采购入库成本.',16,1)
				return
			END
		exec sp_ReComputeSDorgMatLedger 4031,@RefCode,@RefPlantID,@PeriodID,@RefSdorgID,@DocDate,@InputMatgroup,@InputMatcode ,default,default,default,@Usercode,@TerminalID
		--再计算内部采购入库成本
		insert into #table(matcode,Rowid,digit,totalmoney,ratemoney,Mode,ComputeType)
		select a.MatCode,a.rowid,b.digit,b.netmoney,1.0000*b.digit*b.rateprice*(100+img.addpresent)/100,3,''
		from imatdoc_d a with(nolock) inner join sPickorderitem  b with(nolock)
		inner join iMatGeneral img with(nolock) on b.MatCode=img.MatCode
		on a.MatCode=b.MatCode
		and a.DocCode=@Doccode
		and b.DocCode=@RefCode
	END
	--4032内部销售退货，以内部采购退货的出库成本入库
	IF @formid IN (4032)
	BEGIN
		--先处理公司内销售单成本
		if isnull(@RefCode,'')='' 
			begin 
				raiserror('未传入公司内采购退货单信息,无法处理公司内销售退货成本',16,1)
				return
			end
		--取出公司内销售单信息
		update a set @RefDate=a.DocDate,@RefPlantID=a.plantid,@RefSdorgID=a.sdorgid,a.DocDate = @DocDate,a.PeriodID = @PeriodID
		From imatdoc_h a with(nolock)
		where a.FormID=@RefFormID
		and a.DocCode=@RefCode
		if @@ROWCOUNT=0
			BEGIN
				raiserror('不存在对应的公司内采购退货单,无法处理公司内销售退货成本.',16,1)
				return
			END
		
		exec sp_ReComputeSDorgMatLedger 4062,@RefCode,@RefPlantID,@PeriodID,@RefSdorgID,@DocDate,@InputMatgroup,@InputMatcode ,default,default,default,@Usercode,@TerminalID
		
		insert into #table(matcode,Rowid,digit,totalmoney,ratemoney,Mode,ComputeType)
		select b.MatCode,b.rowid,b.digit,a.netmoney,1.0000*b.digit*a.rateprice/(100+img.addpresent)/100,4,''
		from imatdoc_d a with(nolock) inner join sPickorderitem  b with(nolock) 
			on a.MatCode=b.MatCode
			and b.DocCode=@Doccode
			and a.DocCode=@RefCode
		inner join iMatGeneral img with(nolock) 
			on a.MatCode=img.MatCode
		if @@ROWCOUNT=0
			BEGIN
				raiserror('内部销售退货单未取得对应的采购退货单据',16,1)
				return
			END
		--select * from #table a,iMatsdorgLedger iml where a.matcode=iml.MatCode and iml.sdorgid=@SDOrgID
		
	END
	--2418批发退货，4951加盟商退货单若库存有，则以库存成本退货入库，若没有，则以该部门最后一次出库成本入库
	IF @formid IN (2418,4951)
	BEGIN
		--取出单据所有商品最后一次出库记录
		;with cte as(
				select max(i.id) as id,sp.MatCode,sp.rowid,sp.Digit
				from sPickorderitem sp with(nolock) Left join istockledgerlog i with(nolock) on  i.sdorgid=@sdorgid and i.matcode=sp.MatCode		--此处用Left Join 取出单据所有商品的数据。
				inner join istockledgerlog i2 with(nolock) on sp.DocCode=i2.doccode and i2.matcode=sp.MatCode
				where sp.DocCode=@Doccode
				and (i.indigit<0 or i.outdigit>0)						--出库数量大于0,或入库数量小于0,则认为是出库
				and i.inserttime<i2.inserttime
				group by sp.MatCode,sp.rowid,sp.Digit
				) 
				insert into #table(matcode,Rowid,digit,totalmoney,ratemoney,Mode,ComputeType)
				select b.MatCode,b.rowid,b.digit,
				--关于下面这个坑爹表达式的说明.取出库成本和加成出库成本.成本为正数,所以取绝对值.出库金额有可能记录在出库项,也可能记录在入库项(用负数记录),当然优先取出库项,若出库项为0,则转取入库项.
				--出库成本为出库金额除以出库数量,所以有个除号,而除数可能为0,所以用nullif处理除数为0的情况,作用是将0转换成NULL,防止除数为0的错误
				--当然除了除数为0或为NULL,金额也可能为0,就将金额转成NULL,然后转向取inledgeramount,这个转向是靠coalesce实现的
				--当然,任何表达式的结果可能为NULL,而我们不希望成本为NUL,所以最外层有一个ISNULL,将可能的NULL转换成0
				--要是还看不懂的话你可以骂我,但千恨不要来问我,因为明天我也会完全忘记这段表达式的含义,同时也包括上面的说明文字.
				--2013-02-02 03:26 三断笛
				isnull(abs(coalesce(nullif(1.0000*i.outledgeramount/nullif(i.outledgerdigit,0),0),nullif(1.0000*i.inledgeramount/nullif(i.inledgerdigit,0),0))),0),
				isnull(abs(coalesce(nullif(1.0000*i.outrateamount/nullif(i.outledgerdigit,0),0),nullif(1.0000*i.inrateamount/nullif(i.inledgerdigit,0),0))),0),4,''
				from istockledgerlog i with(nolock)  right join cte b on i.id=b.id			--此处用外连接,取出单据所有商品的最后出库数据
			--将有库存商品的成本更新为及时成本
			update a
				set a.totalmoney=a.digit*isnull(1.0000*iml.StockValue/nullif(iml.Stock,0),0),
				a.ratemoney=a.digit*isnull(1.0000*iml.ratevalue/nullif(iml.Stock,0),0)
			from #table a Inner join  iMatsdorgLedger iml with(nolock)
			on a.matcode=iml.MatCode
			and iml.sdorgid=@SDOrgID
			and iml.Stock>0
	END
	--串号调整，返厂返回
	--1553串号调整单，1557返厂返回单，以库存成本入库，如没库存，则以出库成本入库,不管商品是否相同
	--OptionID为1表示出库,为2表示入库
	IF @formid IN (1553,1557)
	BEGIN
		--先处理出库的成本，以即时成本出库
		if @OptionID=1
			BEGIN
				--插入记录
				insert into #table(matcode,Rowid,digit,totalmoney,ratemoney,Mode,ComputeType)
				Select i.matcode1,i.rowid,1,0,0,2,''
				From iserieslogitem i with(nolock)
				where i.doccode=@Doccode
				--更新成本,因为iSerieslogItem表很大,所以不直接与成本表关联,而是取出少量数据后再更新成本
				update a
					set a.totalmoney=a.digit*isnull(1.0000*iml.StockValue/nullif(iml.Stock,0),0),
					a.ratemoney=a.digit*isnull(1.0000*iml.ratevalue/nullif(iml.Stock,0),0)
				from #table a inner join iMatsdorgLedger iml with(nolock)
					on a.matcode=iml.MatCode
					and iml.sdorgid=@SDOrgID
					--注：执行完这里后，会执行成本计算，并输出成本到出库成本字段，供入库使用
			END
		--再处理入库 以库存成本入库，如没库存，则以出库成本入库,不管商品是否相同
		else if @OptionID=2 
			BEGIN
				--先默认全部以出库成本入库
				insert into #table(matcode,Rowid,digit,totalmoney,ratemoney,Mode,ComputeType)
				Select i.matcode,i.rowid,1,netmoney,netmoney,3,''
				From iserieslogitem i with(nolock)
				where i.doccode=@Doccode
				/*--若有库存，则更新至即时成本
				update a
					set a.totalmoney=a.digit*isnull(1.0000*iml.StockValue/nullif(iml.Stock,0),0),
					a.ratemoney=a.digit*isnull(1.0000*iml.ratevalue/nullif(iml.Stock,0),0)
				from #table a inner join iMatsdorgLedger iml with(nolock)
					on a.matcode=iml.MatCode
					and iml.sdorgid=@SDOrgID*/
			END
		else
			BEGIN
				raiserror('无效的选项值,无法处理成本.',16,1)
				return
			END

	END
 
	----------------------------------------------------------------开始计算成本-------------------------------------------------------------------
	/*
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
	*/
	--Select * From #table
	select @XMLResult='<root>'
	--下面用游标循环重算成本
	declare cur CURSOR READ_ONLY fast_forward forward_only for
	select a.matcode,a.Rowid,a.digit,a.totalmoney,a.ratemoney,a.Mode,a.ComputeType
	From #table a  inner join iMatGeneral img with(nolock) on a.MatCode=img.MatCode
		inner join iMatGroup img2 with(nolock) on img.MatGroup=img2.matgroup
	where  (@InputMatcode='' or exists(select 1 from commondb.dbo.SPLIT(isnull(@InputMatcode,''),',') s where img.MatCode=s.List))
		and (@InputMatgroup='' or  exists(select 1 from commondb.dbo.SPLIT(isnull(@InputMatgroup,''),',') s where img2.PATH like '%/'+s.List+'/%'))
		and isnull(a.digit,0)<>0										--数量为0的商品忽略
		and isnull(img.MatState,0)=1								--非库存商品过滤
	order by a.ID
	open cur
	fetch next FROM cur into @matcode,@rowid,@digit,@totalmoney,@ratemoney,@mode,@type
	while @@FETCH_STATUS=0
		BEGIN
			BEGIN TRY
				--print '发生异常:'+isnull(@Companyid,'') +','+isnull(@PeriodID,'') +','+isnull(@SDOrgID,'') +','+convert(varchar(10),@FormID)+','+ @Doccode+','+@matcode+','+convert(varchar(10),isnull(@Digit,0))+','+convert(varchar(10),isnull(@totalmoney,0))+','+convert(varchar(10),isnull(@ratemoney,0))+'>>>>'+convert(varchar(30),getdate(),120)
				exec sp_ComputeSdorgMatLedger @Doccode,@FormID,@rowid,@matcode,@Companyid,@sdorgid,@PeriodID,@digit,@totalmoney,@ratemoney,@mode,@type,@XMLData output
			END TRY
			BEGIN CATCH
				 --select * from #table
				 --select * from iMatsdorgLedger iml where iml.sdorgid=@SDOrgID and iml.MatCode=@matcode
				select @tips= '发生异常:'+isnull(@Companyid,'') +','+isnull(@PeriodID,'') +','+isnull(@SDOrgID,'') +','+convert(varchar(10),@FormID)+','+ @Doccode+','+@matcode+','+convert(varchar(10),isnull(@Digit,0))+','+convert(varchar(10),isnull(@totalmoney,0))+','+convert(varchar(10),isnull(@ratemoney,0))+','+convert(varchar(50),@mode)+'>>>>'+convert(varchar(30),getdate(),120)
				select @tips=@tips +char(10)+dbo.getLastError('成本计算发生错误.')
				if error_number()=8134 or @matcode like '2.%'
					BEGIN
						print @tips
					END
				else
				BEGIN
						raiserror(@tips,16,1)
						return
					END
			END CATCH
			
			--若输出了数据,则连接到XML结果串
			if @XMLData<>'' Select @XMLResult=@XMLResult+@XMLData
			fetch next FROM cur into @matcode,@rowid,@digit,@totalmoney,@ratemoney,@mode,@type
		END
	close cur
	deallocate cur
	--循环完毕,补上XML结束串
	select @XMLResult=@XMLResult+'</root>'
	--将XML还原成临时表,供数据输出
	exec sp_xml_preparedocument @hDocument output,@XMLResult
	Insert Into #XMLDataTable
	Select * From OpenXML(@hDocument,'/root/row',1) with #XMLDataTable
	exec sp_XML_RemoveDocument @hDocument
	--print @XMLResult
	--select * From #XMLDataTable
	/*insert into #ResultTable(Doccode,Formid,refformid,refcode,plantid,sdorgid,periodid,matcode,rowid,
	oldstock,oldstockvalue,oldratevalue,
	digit,totalmoney,ratemoney,
	stock,stockvalue,ratevalue,
	mode,computetype,optionid)
	select @Doccode,@FormID,@RefFormID,@RefCode,@CompanyID,@SDOrgID,@PeriodID,Matcode,RowID,
	OldStock,OldStockValue,OldRateValue,Digit,Totalmoney,RateMoney,
	Stock,StockValue,RateValue,Mode,ComputeType,@OptionID 
	From #XMLDataTable*/
	--执行输出
	begin try
		
		exec sp_outputMatLedgerResult @Doccode,@FormID,@DocDate,@Companyid,@SDOrgID ,@PeriodID,@OptionID,@Usercode,@TerminalID
	end try
	BEGIN catch
		--select * from #table
		select @tips= '发生异常:'+isnull(@Companyid,'') +','+isnull(@PeriodID,'') +','+isnull(@SDOrgID,'') +','+convert(varchar(10),@FormID)+','+ isnull(@Doccode,'')+','+isnull(@matcode,'')+','+convert(varchar(10),isnull(@Digit,0))+','+convert(varchar(10),isnull(@totalmoney,0))+','+convert(varchar(10),isnull(@ratemoney,0))+'>>>>'+convert(varchar(30),getdate(),120)
		select @tips=@tips+char(10)+dbo.getLastError('输出成本数据错误.')
		raiserror(@tips,16,1)
		return
	END catch
	return
END