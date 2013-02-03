 
Create proc sp_outputMatLedgerResult
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
  @mode CHAR,     --1出库正数，2出库负数，3入库正数，4入库负数
  @type varchar(50),   --计算模式
  @map money,
  @rateMap money
as
	BEGIN
		set NOCOUNT on
		--回填原单
 		IF @formid IN (4631)
 		begin
 			update Commsales_d SET netprice=@map,netmoney=@map*@digit,rateprice = @ratemap,ratemoney=@ratemap*@digit,matcost=@map*@digit
 			WHERE doccode=@doccode AND rowid=@rowid AND matcode=@matcode
 		END
 		IF @formid IN (2401,2419,2450,4950,4031,2424)
 		BEGIN 
 			UPDATE spickorderitem SET netprice=@map,netmoney=@map*@digit,rateprice = @ratemap,ratemoney=@ratemap*@digit,matcost=@map*@digit
 			WHERE doccode=@doccode AND rowid=@rowid AND matcode=@matcode
 		END
 		IF @formid IN (1523,1501)
 		BEGIN
 			UPDATE imatdoc_d SET netprice=@map,netmoney=@map*@digit,rateprice = @ratemap,ratemoney=@ratemap*@digit
 			WHERE doccode=@doccode AND rowid=@rowid AND matcode=@matcode
 		END
 		--回填原单
 		IF @formid IN (1504,4062)
 		BEGIN
 			UPDATE imatdoc_d SET netprice=@map,netmoney=@map*@digit,rateprice = @ratemap,ratemoney=@ratemap*@digit,matcost=@map*@digit
 			WHERE doccode=@doccode AND rowid=@rowid AND matcode=@matcode
 		END
 		IF @formid IN (1553,1557)
 		BEGIN
 			UPDATE iserieslogitem SET netprice=@map,netmoney=@map*@digit,rateprice = @ratemap,ratemoney=@ratemap*@digit
 			WHERE doccode=@doccode AND rowid=@rowid AND matcode=@matcode
 		END
 		
		return
	END