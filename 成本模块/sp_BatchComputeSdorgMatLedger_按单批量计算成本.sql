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
  @doccode VARCHAR(50),  --单号  
  @formid VARCHAR(10),     --功能号  
  @plantid VARCHAR(50),  --公司编号  
  @sdorgid VARCHAR(50),  --部门编号  
  @periodid VARCHAR(10)  --期间  
  @ResultXML nvarchar(max)='' output
 )  
 AS  
 BEGIN
 	 SET NOCOUNT ON  
 	 declare @tips varchar(max)
 	IF @formid IN (1512) SET b.digit=0
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
 	Matcode varchar(50),
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
  IF b.mode=1 
 	BEGIN
 		UPDATE a 
 		SET stock=isnull(stock,0)-b.digit,StockValue =isnull(stockvalue,0)-map*b.digit,ratevalue = isnull(ratevalue,0)-ratemap*b.digit 
 		output inserted.matcode,b.rowid,deleted.stock,deleted.stockvalue,deleted.ratevalue,b.digit,b.totamoney,b.ratemoney,inserted.stock,inserted.stockvalue,inserted.ratevalue,b.mode,b.type into @table
 		from iMatsdorgLedger a inner join #table b
 		on plantid=@plantid and sdorgid=@sdorgid AND matcode=b.matcode
		if @@Rowcount=0
			begin
				raiserror('无成本数据，无法处理出库成本！',16,1)
				return
			end 
 		END
  --出库  借方负数     1504,4062      1553,1557--出库商品
  IF b.mode=2
 	BEGIN	
 		UPDATE a SET stock=isnull(stock,0)-b.digit,StockValue =isnull(stockvalue,0)-map*b.digit,ratevalue = isnull(ratevalue,0)-ratemap*b.digit 
 		output inserted.matcode,b.rowid,deleted.stock,deleted.stockvalue,deleted.ratevalue,b.digit,b.totamoney,b.ratemoney,inserted.stock,inserted.stockvalue,inserted.ratevalue,b.mode,b.type into @table
 		from iMatsdorgLedger a,#table b
 		on plantid=@plantid and sdorgid=@sdorgid AND matcode=@matcode
		if @@Rowcount=0
			begin
				raiserror('无成本数据，无法处理出库成本！',16,1)
			end 
 	END
  ---------------------入库 取入库成本------------------------
  --入库  借方正数    1509,4630,1507,1520,1512,4061,1599    1553,1557--入库商品
  IF b.mode=3
 	BEGIN
 		UPDATE a SET stock=isnull(stock,0)+b.digit,StockValue =isnull(stockvalue,0)+b.totamoney,ratevalue = isnull(ratevalue,0)+b.ratemoney 
		output inserted.matcode,b.rowid,deleted.stock,deleted.stockvalue,deleted.ratevalue,b.digit,b.totamoney,b.ratemoney,inserted.stock,inserted.stockvalue,inserted.ratevalue,b.mode,b.type into @table
 		from iMatsdorgLedger a inner join #table b
 		on plantid=@plantid and sdorgid=@sdorgid AND matcode=@matcode
 		
		if @@rowcount = 0                
		insert into iMatsdorgLedger (plantid,sdorgid,matcode,stock,stockvalue,ratevalue)      
		output inserted.matcode,b.rowid,0,0,0,b.digit,b.totamoney,b.ratemoney,inserted.stock,inserted.stockvalue,inserted.ratevalue,b.mode,b.type into @table          
		Select @plantid,@sdorgid,@matcode,b.digit,b.totamoney,b.ratemoney
		From #table b 
      
		--回填原单
 	END
  --入库  贷方负数    2418,2420,4951,4032
  IF b.mode=4
 	BEGIN
 		UPDATE iMatsdorgLedger SET stock=isnull(stock,0)+b.digit,StockValue =isnull(stockvalue,0)+isnull(b.totamoney,0),ratevalue = isnull(ratevalue,0)+b.ratemoney 
		output inserted.matcode,b.rowid,deleted.stock,deleted.stockvalue,deleted.ratevalue,b.digit,b.totamoney,b.ratemoney,inserted.stock,inserted.stockvalue,inserted.ratevalue,b.mode,b.type into @table
		WHERE plantid=@plantid and sdorgid=@sdorgid AND matcode=@matcode
		if @@rowcount = 0                
		insert into iMatsdorgLedger (plantid,sdorgid,matcode,stock,stockvalue,ratevalue)           
		output inserted.matcode,b.rowid,0,0,0,b.digit,b.totamoney,b.ratemoney,inserted.stock,inserted.stockvalue,inserted.ratevalue,b.mode,b.type into @table        
		values (@plantid,@sdorgid,@matcode,b.digit,b.totamoney,b.ratemoney) 
		
	END 
    select @resultxml=(select * From @table For XML RAW)
END