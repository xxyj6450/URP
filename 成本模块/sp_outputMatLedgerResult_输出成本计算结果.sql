 
Create proc sp_outputMatLedgerResult
  @doccode VARCHAR(50),  --����  
  @formid VARCHAR(10),     --���ܺ�  
  @rowid VARCHAR(50),   --�к�  
  @matcode VARCHAR(50),  --��Ʒ���  
  @plantid VARCHAR(50),  --��˾���  
  @sdorgid VARCHAR(50),  --���ű��  
  @periodid VARCHAR(10),  --�ڼ�  
  @digit MONEY,    --����  
  @totalmoney MONEY,   --���  
  @ratemoney MONEY,   --��˰����  
  @mode CHAR,     --1����������2���⸺����3���������4��⸺��
  @type varchar(50),   --����ģʽ
  @map money,
  @rateMap money
as
	BEGIN
		set NOCOUNT on
		--����ԭ��
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
 		--����ԭ��
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