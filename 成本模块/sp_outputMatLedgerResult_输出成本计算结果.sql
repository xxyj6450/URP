CREATE  proc sp_outputMatLedgerResult                  
  @doccode VARCHAR(50),  --单号                      
  @formid VARCHAR(10),     --功能号            
  @DocDate DATETIME,                       --                      
  @plantid VARCHAR(50),  --公司编号                      
  @sdorgid VARCHAR(50),  --部门编号                      
  @periodid VARCHAR(10),  --期间                    
  @OptionID varchar(200)='',                    
  @Usercode varchar(50)='',                    
  @TerminalID varchar(50)=''                    
as                    
SET NOCOUNT ON                  
 --DECLARE @matcode VARCHAR(50), @stcode VARCHAR(20),@Docdate DATETIME,@Doctype VARCHAR(20)               
                
--回填原单                  
--采购入库单 1509 盘盈单 1520 盘盈入库单 1599 采购退货单 1504 领料出库单 1523 盘亏单 1501 内部采购退货单 4062 盘亏出库单 1598                  

IF @formid IN (1509,1520,1599)                  
BEGIN                  
 UPDATE imatdoc_d SET  netmoney=isnull(a.StockValue,0)-isnull(a.OldStockValue,0), matcost=isnull(a.StockValue,0)-isnull(a.OldStockValue,0),    
  rateprice=(isnull(a.RateValue,0)-isnull(a.OldRateValue,0))/isnull(a.Digit,0),ratemoney =isnull( a.RateValue,0)-isnull(a.OldRateValue,0)                 
 FROM imatdoc_d d with(nolock) inner join #XMLDataTable a on d.rowid=a.RowID AND d.MatCode=a.Matcode AND d.DocCode=@doccode                  
END                  
                  
IF @formid IN (1504,1523,1501,4062,1598)      --            
BEGIN                  
 UPDATE imatdoc_d SET netprice =(isnull(a.OldStockValue,0)-isnull(a.StockValue,0))/isnull(a.Digit,0),netmoney =isnull(a.OldStockValue,0)-isnull(a.StockValue,0),                
     matcost=isnull(a.OldStockValue,0)-isnull(a.StockValue,0),rateprice = (isnull(a.OldRateValue,0)-isnull(a.RateValue,0))/isnull(a.Digit,0),ratemoney = isnull(a.OldRateValue,0)-isnull(a.RateValue,0)                   
 FROM imatdoc_d d with(nolock) inner join #XMLDataTable a on d.rowid=a.RowID AND d.MatCode=a.Matcode AND d.DocCode=@doccode          
           
 --UPDATE imatdoc_h SET PeriodID = @periodid,DocDate =@DocDate WHERE DocCode=@doccode AND FormID=4062               
END                  
                  
IF @formid IN (1507,4061) --调拨入库单,内部采购入库单                  
BEGIN                  
 UPDATE imatdoc_d SET matcost= isnull(a.StockValue,0)-isnull(a.OldStockValue,0),price=(isnull(a.StockValue,0)-isnull(a.OldStockValue,0))/isnull(a.Digit,0),totalmoney=isnull( a.StockValue,0)-isnull(a.OldStockValue,0),                  
 netprice=(isnull(a.StockValue,0)-isnull(a.OldStockValue,0))/isnull(a.Digit,0),netmoney=isnull(a.StockValue,0)-isnull(a.OldStockValue,0),          
 rateprice=(isnull(a.RateValue,0)-isnull(a.OldRateValue,0))/isnull(a.Digit,0),ratemoney=isnull(a.RateValue,0)-isnull(a.OldRateValue,0)                  
 FROM imatdoc_d d with(nolock) inner join #XMLDataTable a on d.rowid=a.RowID AND d.MatCode=a.Matcode AND d.DocCode=@doccode                  
END                  
                  
--代销入库 4630 代销退货 4631                  
IF @formid IN (4630)                  
BEGIN                  
 UPDATE Commsales_d SET netmoney=isnull(a.StockValue,0)-isnull(a.OldStockValue,0), matcost=isnull(a.StockValue,0)-isnull(a.OldStockValue,0),rateprice = (isnull(a.RateValue,0)-isnull(a.OldRateValue,0))/isnull(a.Digit,0),          
 ratemoney = isnull(a.RateValue,0)-isnull(a.OldRateValue,0)                  
 FROM Commsales_d d with(nolock) inner join #XMLDataTable a on d.rowid=a.RowID AND d.MatCode=a.Matcode AND d.DocCode=@doccode                  
END                  
                  
IF @formid IN (4631)                  
BEGIN                  
 UPDATE Commsales_d SET netmoney=isnull(a.OldStockValue,0)-isnull(a.StockValue,0), matcost=isnull(a.OldStockValue,0)-isnull(a.StockValue,0),rateprice = (isnull(a.OldRateValue,0)-isnull(a.RateValue,0))/isnull(a.Digit,0),          
 ratemoney = isnull(a.OldRateValue,0)-isnull(a.RateValue,0)          
 FROM Commsales_d d with(nolock) inner join #XMLDataTable a on d.rowid=a.RowID AND d.MatCode=a.Matcode AND d.DocCode=@doccode                  
END                 
                  
-- 返厂返回单 1557 串号调整单 1553                   
IF @formid IN (1557,1553)                  
BEGIN            
 IF @OptionID='1'          
 BEGIN          
  UPDATE iserieslogitem SET netprice = abs(isnull(a.StockValue,0)-isnull(a.OldStockValue,0))/isnull(a.Digit,0), netmoney=abs(isnull(a.StockValue,0)-isnull(a.OldStockValue,0)),                
   rateprice = abs(isnull(a.RateValue,0)-isnull(a.OldRateValue,0))/isnull(a.Digit,0),ratemoney = abs(isnull(a.RateValue,0)-isnull(a.OldRateValue,0))          
  FROM iserieslogitem d with(nolock) inner join #XMLDataTable a on d.rowid=a.RowID AND d.MatCode1=a.Matcode AND d.DocCode=@doccode          
 END          
            
 IF @OptionID='2'          
 BEGIN          
  UPDATE iserieslogitem SET netprice1 =abs(isnull(a.StockValue,0)-isnull(a.OldStockValue,0))/isnull(a.Digit,0),netmoney1=abs(isnull(a.StockValue,0)-isnull(a.OldStockValue,0)),           
   rateprice1 = abs(isnull(a.RateValue,0)-isnull(a.OldRateValue,0))/isnull(a.Digit,0),ratemoney1 = abs(isnull(a.RateValue,0)-isnull(a.OldRateValue,0))                  
  FROM iserieslogitem d with(nolock) inner join #XMLDataTable a on d.rowid=a.RowID AND d.MatCode=a.Matcode AND d.DocCode=@doccode          
 END           
END                  
                  
--批发销售出库 2401 批发销售退货 2418 零售出库单 2419 零售退货单 2420 促销出库单 2450 送货单 4950 退货单 4951                   
--内部销售出库单 4031 内部销售退货单 4032 调拨出库单 2424                  
IF @formid IN (2401,2418,2419,2420,2450,4950,4951,4031,4032,2424)                  
BEGIN                  
 UPDATE spickorderitem SET netprice = abs(isnull(a.StockValue,0)-isnull(a.OldStockValue,0))/isnull(a.Digit,0),netmoney =abs(isnull(a.StockValue,0)-isnull(a.OldStockValue,0)),                   
    MatCostPrice = abs(isnull(a.StockValue,0)-isnull(a.OldStockValue,0))/isnull(a.Digit,0),MatCost =abs(isnull(a.StockValue,0)-isnull(a.OldStockValue,0)),                
    rateprice = abs(isnull(a.RateValue,0)-isnull(a.OldRateValue,0))/isnull(a.Digit,0),ratemoney =abs(isnull(a.RateValue,0)-isnull(a.OldRateValue,0))                  
 FROM spickorderitem d with(nolock) inner join #XMLDataTable a on d.rowid=a.RowID AND d.MatCode=a.Matcode AND d.DocCode=@doccode              
           
  --UPDATE sPickorderHD SET periodid = @periodid,DocDate =@DocDate WHERE DocCode=@doccode AND FormID IN (2424,4031)                 
END                  
                 
---写库存明细账                  
IF @formid IN (1509,1520,1599,1507,4061,4630) --借方正                  
BEGIN                  
 UPDATE istockledgerlog SET inledgeramount=isnull(a.StockValue,0)-isnull(a.OldStockValue,0),inrateamount=isnull(a.RateValue,0)-isnull(a.OldRateValue,0),matcost=isnull(a.StockValue,0)-isnull(a.OldRateValue,0)                 
 FROM istockledgerlog d with(nolock) inner join #XMLDataTable a on d.docrowid=a.RowID AND d.MatCode=a.Matcode AND d.DocCode=@doccode                  
END                  
IF @formid IN (1504,4062) --借方负         --         
BEGIN                  
 UPDATE istockledgerlog SET inledgeramount=-1*(isnull(a.OldStockValue,0)-isnull(a.StockValue,0)),inrateamount=-1*(isnull(a.OldRateValue,0)-isnull(a.RateValue,0)),                
       matcost=-1*(isnull(a.OldStockValue,0)-isnull(a.StockValue,0)),periodid=@periodid,docdate=@DocDate                  
 FROM istockledgerlog d with(nolock) inner join #XMLDataTable a on d.docrowid=a.RowID AND d.MatCode=a.Matcode AND d.DocCode=@doccode            
END      
      
IF @formid IN (4631)      
BEGIN      
 UPDATE istockledgerlog SET outledgeramount=abs(isnull(a.OldStockValue,0)-isnull(a.StockValue,0)),outrateamount=abs(isnull(a.OldRateValue,0)-isnull(a.RateValue,0)),            
    matcost=abs(isnull(a.OldStockValue,0)-isnull(a.StockValue,0)),periodid=@periodid,docdate=@DocDate                  
 FROM istockledgerlog d with(nolock) inner join #XMLDataTable a on d.docrowid=a.RowID AND d.MatCode=a.Matcode AND d.DocCode=@doccode        
END                
                  
IF @formid IN (1523,1501,1598,2401,2419,2450,4950,4031,2424) --贷方正                  
BEGIN                  
 UPDATE istockledgerlog SET outledgeramount=isnull(a.OldStockValue,0)-isnull(a.StockValue,0),outrateamount=isnull(a.OldRateValue,0)-isnull(a.RateValue,0),            
    matcost=isnull(a.OldStockValue,0)-isnull(a.StockValue,0),periodid=@periodid,docdate=@DocDate                  
 FROM istockledgerlog d with(nolock) inner join #XMLDataTable a on d.docrowid=a.RowID AND d.MatCode=a.Matcode AND d.DocCode=@doccode
 
END                  
                  
IF @formid IN (2418,2420,4951,4032) --贷方负                  
BEGIN       
 UPDATE istockledgerlog SET outledgeramount=-1*(isnull(a.StockValue,0)-isnull(a.OldStockValue,0)),outrateamount=-1*(isnull(a.RateValue,0)-isnull(a.OldRateValue,0)),                
        matcost=-1*(isnull(a.StockValue,0)-isnull(a.OldStockValue,0))                  
 FROM istockledgerlog d with(nolock) inner join #XMLDataTable a on d.docrowid=a.RowID AND d.MatCode=a.Matcode AND d.DocCode=@doccode                 
           
 --select * from istockledgerlog i where i.doccode=@Doccode          
 --select * from #XMLDataTable          
END                  
                  
IF @formid IN (1557,1553) --借方负 返厂返回单,串号调整单                   
BEGIN          
        
 IF @OptionID='1'          
 BEGIN          
  UPDATE  istockledgerlog  SET inledgeramount= -1*isnull(a.netmoney,0),inrateamount= -1*isnull(a.ratemoney,0),matcost= -1*isnull(a.netmoney,0)                  
  FROM istockledgerlog d with(nolock) inner join iserieslogitem a on d.doccode=a.doccode AND d.MatCode=a.matcode1 AND a.DocCode=@doccode AND isnull(d.indigit,0)<0        
          
  UPDATE  istockledgerlog  SET indigit = -1, inledgeramount= -1*isnull(a.netmoney,0),inrateamount= -1*isnull(a.ratemoney,0),matcost= -1*isnull(a.netmoney,0)                  
  FROM istockledgerlog d with(nolock) inner join iserieslogitem a on d.doccode=a.doccode AND d.MatCode=a.matcode1 AND a.DocCode=@doccode AND isnull(d.outdigit,0)<>0        
 END          
            
 IF @OptionID='2'          
 BEGIN          
  UPDATE  istockledgerlog  SET inledgeramount= isnull(a.netmoney1,0),inrateamount= isnull(a.ratemoney1,0),matcost=isnull(a.netmoney1,0)                  
  FROM istockledgerlog d with(nolock) inner join iserieslogitem a on d.doccode=a.doccode AND d.MatCode=a.matcode AND a.DocCode=@doccode AND isnull(d.indigit,0)>0          
 END           
END                  
                  /*
---写销售明细账                  
IF @formid IN (2401,2419,2450,4950)                  
BEGIN                  
 UPDATE isaleledgerlog SET netprice=(isnull(a.OldStockValue,0)-isnull(a.StockValue,0))/isnull(a.Digit,0),netmoney =isnull(a.OldStockValue,0)-isnull(a.StockValue,0),                
     salesnetmoney =isnull(a.OldStockValue,0)-isnull(a.StockValue,0) ,ratemoney = isnull(a.OldRateValue,0)-isnull(a.RateValue,0)                 
 FROM isaleledgerlog d with(nolock) inner join #XMLDataTable a on d.rowid=a.RowID AND d.MatCode=a.Matcode AND d.DocCode=@doccode                  
                   
 UPDATE salelog SET  netprice=(isnull(a.OldStockValue,0)-isnull(a.StockValue,0))/isnull(a.Digit,0),netmoney =isnull(a.OldStockValue,0)-isnull(a.StockValue,0),          
 ratemoney = isnull(a.OldRateValue,0)-isnull(a.RateValue,0)                  
 FROM salelog d with(nolock) inner join #XMLDataTable a on d.rowid=a.RowID AND d.MatCode=a.Matcode AND d.DocCode=@doccode                  
END                  
                  
IF @formid IN (2418,2420,4951)                  
BEGIN                  
 UPDATE isaleledgerlog SET netprice=-1*(isnull(a.StockValue,0)-isnull(a.OldStockValue,0))/isnull(a.Digit,0),netmoney =-1*(isnull(a.StockValue,0)-isnull(a.OldStockValue,0)),                
     salesnetmoney =-1*(isnull(a.StockValue,0)-isnull(a.OldStockValue,0)),ratemoney = -1*(isnull(a.RateValue,0)-isnull(a.OldRateValue,0))                 
 FROM isaleledgerlog d with(nolock) inner join #XMLDataTable a on d.rowid=a.RowID AND d.MatCode=a.Matcode AND d.DocCode=@doccode                  
                   
 UPDATE salelog SET netprice=-1*(isnull(a.StockValue,0)-isnull(a.OldStockValue,0))/isnull(a.Digit,0),netmoney =-1*(isnull(a.StockValue,0)-isnull(a.OldStockValue,0)),          
 ratemoney = -1*(isnull(a.RateValue,0)-isnull(a.OldRateValue,0))                  
 FROM salelog d with(nolock) inner join #XMLDataTable a on d.rowid=a.RowID AND d.MatCode=a.Matcode AND d.DocCode=@doccode                  
END
*/