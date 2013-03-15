/*
过程:sp_BatchComputeSdorgMatLedger
功能描述:按单批量重算成本,前提是单据上无重复商品.

 按部门级成本处理过程  
 按功能模块来处理成本 
  
 采购入库单1509，采购退货单1504，代销入库4630，代销退货4631，批发销售出库2401，批发销售退货2418，
 零售出库单2419，零售退货单2420，促销出库单2450，送货单4950，退货单4951，调拨出库单2424，调拨入库单1507，
 领料出库单1523，盘亏单1501，盘盈单1520，成本补差单2136，成本调价单1512，内部销售出库单4031，内部销售退货单4032，
 内部采购入库单4061，内部采购退货单4062，返厂返回单1557，串号调整单1553
 select top 100 * from istockledgerlog where formid=1553
 现在记1512调价借方，负数
 1557,1553调价借方，负数
 SELECT doccode,formid,rowid,matcode,plantid,sdorgid,periodid,digit,netmoney,ratemoney FROM vCommsales WHERE doccode='GDR2013020200000'
 */  

 alter PROC sp_BatchComputeSdorgMatLedger(  
  @doccode VARCHAR(50),		--单号  
  @formid VARCHAR(10),		--功能号
  @DocDate datetime,			--单据日期
  @plantid VARCHAR(50),		--公司编号  
  @sdorgid VARCHAR(50),		--部门编号  
  @periodid VARCHAR(10),		--期间
  @Mode int,
  @ComputeType varchar(50)='',
  @OptionID varchar(50)='',
  @ResultXML nvarchar(max)='' output
 )  
 AS  
 BEGIN
 	 SET NOCOUNT ON  
 	 declare @tips varchar(max)
 	 --用于输出计算结果的表变量
	 /* Create Table #ResultTable (
	 	FormID int,
	 	Doccode varchar(20),
	 	Refformid int,
	 	RefCode varchar(30),
	 	plantID varchar(20),
	 	SDOrgID varchar(50),
	 	Periodid varchar(7),
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
		ComputeType  varchar(50),				--计算模式
		OptionID varchar(50)
	 ) 
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
	*/

	IF isnull(@plantid,'')=''  
	 BEGIN  
		 RAISERROR('出库时,公司为空值,过帐错误!',16,1)  
		 RETURN  
	 END  
	  IF isnull(@sdorgid,'')=''  
	 BEGIN  
		 RAISERROR('出库时,部门为空值,过帐错误!',16,1)  
		 RETURN  
	 END  
	  IF isnull(@formid,'') NOT IN (4631,2401,2419,2450,4950,2424,1523,1501,4031,1598,1504,4062,1553,1557,1509,4630,1507,1520,1512,4061,1599,2418,2420,4951,4032)  
	 BEGIN  
		 RAISERROR('业务功能未添加，请检查!',16,1)  
		 RETURN  
	 END
	 if exists(Select 1 from #table where isnull(matcode,'')='')
	 BEGIN
		 RAISERROR('出库时,商品为空值,过帐错误!',16,1)  
		 RETURN 
	 END
--用于输出计算结果的表变量
 declare @table table(
 	SDorgID varchar(50),
 	Matcode varchar(50),
 	Seriescode varchar(50),
	RowID varchar(50),
 	OldStock int,
 	OldStockValue money,
 	OldRateValue money,
	Digit int,
	Totalmoney money,
	RateMoney money,
 	Stock int,
 	StockValue money,
 	RateValue money,
	Mode char,
	ComputeType  varchar(50)
 )
 
 
  ---------------------出库 取移动加权平均成本-------------------------
  --出库  贷方正数     4631,2401,2419,2450,4950,2424,1523,1501,4031,1598   
    IF @MODE=1 
 	BEGIN
 		
 		UPDATE  a
 		SET stock=isnull(stock,0)-isnull(b.digit,0),StockValue =isnull(stockvalue,0)-isnull(map,0)*isnull(b.digit,0),ratevalue = isnull(ratevalue,0)-isnull(ratemap,0)*isnull(b.digit,0),
 		ModifyDate=getdate(),ModifyDoccode=@doccode
 		output @sdorgid, inserted.matcode,b.seriescode,b.RowID,deleted.stock,deleted.stockvalue,deleted.ratevalue,b.Digit,
 		b.TotalMoney,b.Ratemoney,inserted.stock,inserted.stockvalue,inserted.ratevalue,@MODE,b.ComputeType into @table
 		From iMatsdorgLedger a with(nolock) inner join #table b on a.sdorgid=@sdorgid and a.MatCode=b.matcode
		SET @tips='部门['+@sDOrgID+']'
 		select @tips=@tips+'商品['+a.matcode+']无成本数据，无法处理出库成本.'+char(10)
 		from #table a 
		where not exists(select 1 from @table b where a.matcode=b.Matcode)  
 		if @@Rowcount<>0
			begin
				raiserror(@tips,16,1)
			end 
 		END
  --出库  借方负数     1504,4062      1553,1557--出库商品
  IF @MODE=2
 	BEGIN
 		UPDATE a SET stock=isnull(stock,0)-isnull(b.digit,0),StockValue =isnull(stockvalue,0)-isnull(map,0)*isnull(b.digit,0),ratevalue = isnull(ratevalue,0)-isnull(ratemap,0)*isnull(b.digit,0),
 		ModifyDate=getdate(),ModifyDoccode=@doccode
 		output @sdorgid,inserted.matcode,b.seriescode,b.rowid,deleted.stock,deleted.stockvalue,deleted.ratevalue,b.digit,b.totalmoney,
 		b.ratemoney,inserted.stock,inserted.stockvalue,inserted.ratevalue,@MODE,b.ComputeType into @table
 		From iMatsdorgLedger a with(nolock) inner join #table b on a.sdorgid=@sdorgid and a.MatCode=b.matcode
 		SET @tips='部门['+@sDOrgID+']'
 		select @tips=@tips+'商品['+a.matcode+']无成本数据，无法处理出库成本.'+char(10)
 		from #table a 
		where not exists(select 1 from @table b where a.matcode=b.Matcode)  
 		if @@Rowcount<>0
			begin
				raiserror(@tips,16,1)
			end 
 		END
  ---------------------入库 取入库成本------------------------
  --入库  借方正数    1509,4630,1507,1520,1512,4061,1599    1553,1557--入库商品
  IF @MODE=3
 	BEGIN
 		UPDATE a 
 		SET stock=isnull(stock,0)+isnull(b.digit,0),StockValue =isnull(stockvalue,0)+isnull(b.totalmoney,0),ratevalue = isnull(ratevalue,0)+isnull(b.ratemoney,0),
 		ModifyDate=getdate(),ModifyDoccode=@doccode
		output @sdorgid,inserted.matcode,b.seriescode,b.rowid,deleted.stock,deleted.stockvalue,deleted.ratevalue,
		b.digit,b.totalmoney,b.ratemoney,inserted.stock,inserted.stockvalue,inserted.ratevalue,@MODE,b.ComputeType 
		into @table
		From iMatsdorgLedger a with(nolock) inner join #table b on a.sdorgid=@sdorgid and a.MatCode=b.matcode
 
 		--将未更新到的行插入至成本表
		if @@rowcount = 0
			BEGIN
				insert into iMatsdorgLedger (plantid,sdorgid,matcode,stock,stockvalue,ratevalue,modifydate,modifydoccode)           
				output @sdorgid,inserted.matcode,0,0,0,inserted.stock,inserted.stockvalue,inserted.ratevalue,@MODE,@ComputeType
				 into @table(SDorgID,Matcode,OldStock,OldStockValue,OldRateValue,Stock,StockValue,RateValue,Mode,ComputeType)
				select @plantid,@sdorgid,a.matcode,isnull(a.digit,0),isnull(a.totalmoney,0),isnull(a.ratemoney,0),getdate(),@doccode
				from #table as a  
				where not exists(select 1 from @table b where a.matcode=b.Matcode)   
				update a
					set a.Seriescode=b.seriescode,a.rowid=b.rowid,a.Digit=b.digit,a.Totalmoney=b.totalmoney,a.RateMoney=b.ratemoney
				from @table a,#table b
				where a.matcode=b.matcode
			END
 	END
  --入库  贷方负数    2418,2420,4951,4032
  IF @MODE=4
 	BEGIN
 		UPDATE a
 		 SET stock=isnull(stock,0)+b.digit,StockValue =isnull(stockvalue,0)+isnull(b.totalmoney,0),ratevalue = isnull(ratevalue,0)+isnull(b.ratemoney,0),
 		ModifyDate=getdate(),ModifyDoccode=@doccode
		output @sdorgid,inserted.matcode,b.seriescode,b.rowid,deleted.stock,deleted.stockvalue,deleted.ratevalue,b.digit,
		b.totalmoney,b.ratemoney,inserted.stock,inserted.stockvalue,inserted.ratevalue,@MODE,b.ComputeType into @table
		From iMatsdorgLedger a with(nolock) inner join #table b on a.sdorgid=@sdorgid and a.MatCode=b.matcode
		if @@rowcount = 0
			BEGIN
				insert into iMatsdorgLedger (plantid,sdorgid,matcode,stock,stockvalue,ratevalue,modifydate,modifydoccode)           
				output @sdorgid,inserted.matcode,0,0,0,inserted.stock,inserted.stockvalue,inserted.ratevalue,@MODE,@ComputeType
				 into @table(SDorgID,Matcode,OldStock,OldStockValue,OldRateValue,Stock,StockValue,RateValue,Mode,ComputeType)
				 select @plantid,@sdorgid,a.matcode,isnull(a.digit,0),isnull(a.totalmoney,0),isnull(a.ratemoney,0),getdate(),@doccode
				from #table as a  
				where not exists(select 1 from @table b where a.matcode=b.Matcode)   
				update a
					set a.Seriescode=b.seriescode,a.rowid=b.rowid,a.Digit=b.digit,a.Totalmoney=b.totalmoney,a.RateMoney=b.ratemoney
				from @table a,#table b
				where a.matcode=b.matcode
			END
		
		--values (@plantid,@sdorgid,b.matcode,b.digit,b.totalmoney,b.ratemoney,getdate(),@doccode) 
	
	END 
	select *from @table
    insert into #ResultTable(Doccode,FormID,Docdate, SDOrgID,Matcode,Seriescode,RowID,OldStock,OldStockValue,OldRateValue,Digit,Totalmoney,ratemoney,Stock,StockValue,RateValue,Mode,ComputeType,OptionID)
    select @doccode,@formid,@DocDate, @sdorgid,a.Matcode,a.seriescode,a.RowID,a.OldStock,a.OldStockValue,a.OldRateValue,a.Digit,a.Totalmoney,a.RateMoney,a.Stock,a.StockValue,a.RateValue,a.Mode,a.ComputeType,@OptionID
    from @table a
     select @resultxml=(select * From @table For XML RAW)
     print @ResultXML
END