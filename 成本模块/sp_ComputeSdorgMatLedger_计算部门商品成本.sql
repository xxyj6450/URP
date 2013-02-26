/*  
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

 alter PROC sp_ComputeSdorgMatLedger(
  @doccode VARCHAR(50),  --单号  
  @formid VARCHAR(10),     --功能号  
  @rowid VARCHAR(50),   --行号  
  @matcode VARCHAR(50),  --商品编号  
  @plantid VARCHAR(50),  --公司编号  
  @sdorgid VARCHAR(50),  --部门编号  
  @periodid VARCHAR(10),  --期间  
  @digit MONEY,    --数量  
  @totalmoney MONEY,   --金额  
  @ratemoney MONEY,   --加税点金额  
  @mode int,     --1出库正数，2出库负数，3入库正数，4入库负数
  @type varchar(50),   --计算模式
  @ResultXML nvarchar(max)='' output
 )  
 AS  
 SET NOCOUNT ON  
 --DECLARE @map MONEY ,@ratemap money
 BEGIN
 	IF @formid IN (1512) SET @digit=0
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
	  IF ISNULL(@matcode,'')=''
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
  /*
  采购退货1504,代销退货4631,零售出库单2419,促销出库单2450,送货单4950,调拨出库单2424,领料出库单1523,盘亏单1501,
  内部销售出库单4031,内部采购退货单4062,
  select * from imatbalance
  select inledgeramount,inrateamount,outledgeramount,outrateamount,* from istockledgerlog where formid=1557
  select netmoney,ratemoney,netprice,rateprice,netmoney1,ratemoney1,netprice1,rateprice1,* from iserieslogitem
  select * from VSPICKORDER where doccode='RE20130125000000'  select * from iMatsdorgLedger where sdorgid='101.05.02' and matcode='1.06.019.1.1.9'
  */
  --出库  贷方正数     4631,2401,2419,2450,4950,2424,1523,1501,4031,1598   
  IF @mode=1 
 	BEGIN
 		/*SELECT @map= isnull(stockvalue,0)/stock ,
 		@ratemap= isnull(ratevalue,0)/stock  
 		FROM iMatsdorgLedger WHERE plantid=@plantid and sdorgid=@sdorgid AND matcode=@matcode*/
 		UPDATE iMatsdorgLedger 
 		SET stock=isnull(stock,0)-@digit,StockValue =isnull(stockvalue,0)-map*@digit,ratevalue = isnull(ratevalue,0)-ratemap*@digit 
 		output inserted.matcode,@RowID,deleted.stock,deleted.stockvalue,deleted.ratevalue,@Digit,@TotalMoney,@Ratemoney,inserted.stock,inserted.stockvalue,inserted.ratevalue,@Mode,@Type into @table
 		WHERE plantid=@plantid and sdorgid=@sdorgid AND matcode=@matcode
		if @@Rowcount=0
			begin
				raiserror('无成本数据，无法处理出库成本！',16,1)
				return
			end 
 		--UPDATE imatledger SET stock=stock-@digit,StockValue =stockvalue-@map*@digit,ratevalue = ratevalue-@ratemap*@digit WHERE plantid=@plantid AND matcode=@matcode  
 		/*update imatsdorgbalance SET outdigit=isnull(outdigit,0)+@digit,outamount=isnull(outamount,0)+@map*@digit,outrateamount =isnull( outrateamount,0)+@ratemap*@digit
 		WHERE plantid=@plantid and sdorgid=@sdorgid AND periodid=@periodid and matcode=@matcode*/
 		--update imatbalance SET outdigit=outdigit+@digit,outamount=outamount+@map*@digit,outrateamount = outrateamount+@ratemap*@digit  		WHERE plantid=@plantid AND periodid=@periodid and matcode=@matcode
 	END
  --出库  借方负数     1504,4062      1553,1557--出库商品
  IF @mode=2
 	BEGIN
 		/*SELECT @map= isnull(stockvalue,0)/stock ,
 		@ratemap= isnull(ratevalue,0)/stock  
 		FROM iMatsdorgLedger 
 		WHERE plantid=@plantid and sdorgid=@sdorgid AND matcode=@matcode
 		*/
 		UPDATE iMatsdorgLedger SET stock=isnull(stock,0)-@digit,StockValue =isnull(stockvalue,0)-map*@digit,ratevalue = isnull(ratevalue,0)-ratemap*@digit 
 		output inserted.matcode,@RowID,deleted.stock,deleted.stockvalue,deleted.ratevalue,@Digit,@TotalMoney,@Ratemoney,inserted.stock,inserted.stockvalue,inserted.ratevalue,@Mode,@Type into @table
 		WHERE plantid=@plantid and sdorgid=@sdorgid AND matcode=@matcode
		if @@Rowcount=0
			begin
				raiserror('无成本数据，无法处理出库成本！',16,1)
			end 
 		--UPDATE imatledger SET stock=stock-@digit,StockValue =stockvalue-@map*@digit,ratevalue = ratevalue-@ratemap*@digit WHERE plantid=@plantid AND matcode=@matcode  
 		/*update imatsdorgbalance SET indigit=isnull(indigit,0)-@digit,inamount=isnull(inamount,0)-@map*@digit,inrateamount = isnull(inrateamount,0)-@ratemap*@digit
 		WHERE plantid=@plantid and sdorgid=@sdorgid AND periodid=@periodid and matcode=@matcode*/
 		--update imatbalance SET indigit=indigit-@digit,inamount=inamount-@map*@digit,inrateamount = inrateamount-@ratemap*@digit 	WHERE plantid=@plantid AND periodid=@periodid and matcode=@matcode
 	END
  ---------------------入库 取入库成本------------------------
  --入库  借方正数    1509,4630,1507,1520,1512,4061,1599    1553,1557--入库商品
  IF @mode=3
 	BEGIN
 		UPDATE iMatsdorgLedger SET stock=isnull(stock,0)+@digit,StockValue =isnull(stockvalue,0)+@totalmoney,ratevalue = isnull(ratevalue,0)+@ratemoney 
		output inserted.matcode,@RowID,deleted.stock,deleted.stockvalue,deleted.ratevalue,@Digit,@TotalMoney,@Ratemoney,inserted.stock,inserted.stockvalue,inserted.ratevalue,@Mode,@Type into @table
		WHERE plantid=@plantid and sdorgid=@sdorgid AND matcode=@matcode
 		
		if @@rowcount = 0                
		insert into iMatsdorgLedger (plantid,sdorgid,matcode,stock,stockvalue,ratevalue)      
		output inserted.matcode,@RowID,0,0,0,@Digit,@totalmoney,@RateMoney,inserted.stock,inserted.stockvalue,inserted.ratevalue,@Mode,@Type into @table          
		values (@plantid,@sdorgid,@matcode,@digit,@totalmoney,@ratemoney) 
      
 		/*
 		UPDATE imatledger SET stock=stock+@digit,StockValue =stockvalue+@totalmoney,ratevalue = ratevalue+@ratemoney 
		WHERE plantid=@plantid AND matcode=@matcode  
		if @@rowcount = 0                
		insert into imatledger (plantid,matcode,matvalue,stock,stockvalue,ratevalue)                
		values (@plantid,@matcode,'',@digit,@totalmoney,@ratemoney) 
		*/
      --SELECT * FROM iMatsdorgLedger where matcode='1.01.020.1.1.2'
 		/*update imatsdorgbalance SET indigit=isnull(indigit,0)+@digit,inamount=isnull(inamount,0)+@totalmoney,inrateamount =isnull( inrateamount,0)+@ratemoney
 		WHERE plantid=@plantid and sdorgid=@sdorgid AND periodid=@periodid and matcode=@matcode
		if @@rowcount = 0                
		insert into imatsdorgbalance (plantid,sdorgid,periodid,matcode,prestock,prestockvalue,preratevalue,indigit,inamount,inrateamount)                
		values (@plantid,@sdorgid,@periodid,@matcode,0,0,0,@digit,@totalmoney,@ratemoney) */
 		/*
 		update imatbalance SET indigit=indigit+@digit,inamount=inamount+@totalmoney,inrateamount = inrateamount+@ratemoney
 		WHERE plantid=@plantid AND periodid=@periodid and matcode=@matcode
		if @@rowcount = 0                
		insert into imatbalance (plantid,periodid,matcode,matvalue,prestock,prestockvalue,indigit,inamount,inrateamount)                
		values (@plantid,@periodid,@matcode,'',0,0,@digit,@totalmoney,@ratemoney)
		*/
		--回填原单
 	END
  --入库  贷方负数    2418,2420,4951,4032
  IF @mode=4
 	BEGIN
 		UPDATE iMatsdorgLedger SET stock=isnull(stock,0)+@digit,StockValue =isnull(stockvalue,0)+isnull(@totalmoney,0),ratevalue = isnull(ratevalue,0)+@ratemoney 
		output inserted.matcode,@RowID,deleted.stock,deleted.stockvalue,deleted.ratevalue,@Digit,@TotalMoney,@Ratemoney,inserted.stock,inserted.stockvalue,inserted.ratevalue,@Mode,@Type into @table
		WHERE plantid=@plantid and sdorgid=@sdorgid AND matcode=@matcode
		if @@rowcount = 0                
		insert into iMatsdorgLedger (plantid,sdorgid,matcode,stock,stockvalue,ratevalue)           
		output inserted.matcode,@RowID,0,0,0,@Digit,@totalmoney,@RateMoney,inserted.stock,inserted.stockvalue,inserted.ratevalue,@Mode,@Type into @table        
		values (@plantid,@sdorgid,@matcode,@digit,@totalmoney,@ratemoney) 
		/*
 		UPDATE imatledger SET stock=stock+@digit,StockValue =stockvalue+@totalmoney,ratevalue = ratevalue+@ratemoney WHERE plantid=@plantid AND matcode=@matcode  
		if @@rowcount = 0                
		insert into imatledger (plantid,matcode,matvalue,stock,stockvalue,ratevalue)                
		values (@plantid,@matcode,'',@digit,@totalmoney,@ratemoney)
		*/
 		/*update imatsdorgbalance SET outdigit=isnull(outdigit,0)-@digit,outamount=isnull(outamount,0)-@totalmoney,outrateamount = isnull(outrateamount,0)-@ratemoney
		WHERE plantid=@plantid and sdorgid=@sdorgid AND periodid=@periodid and matcode=@matcode
		if @@rowcount = 0                
		insert into imatsdorgbalance (plantid,sdorgid,periodid,matcode,prestock,prestockvalue,preratevalue,outdigit,outamount,outrateamount)                
		values (@plantid,@sdorgid,@periodid,@matcode,0,0,0,@digit,@totalmoney,@ratemoney) */
		/*
		update imatbalance SET outdigit=outdigit-@digit,outamount=outamount-@totalmoney,outrateamount = outrateamount-@ratemoney
		WHERE plantid=@plantid AND periodid=@periodid and matcode=@matcode
		if @@rowcount = 0
		insert into imatbalance (plantid,periodid,matcode,matvalue,prestock,prestockvalue,outdigit,outamount,outrateamount)                
		values (@plantid,@periodid,@matcode,'',0,0,@digit,@totalmoney,@ratemoney)
		*/
	END 
    select @resultxml=(select * From @table For XML RAW)
END