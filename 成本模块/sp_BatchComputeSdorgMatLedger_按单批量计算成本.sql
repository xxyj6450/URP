/*
����:sp_BatchComputeSdorgMatLedger
��������:������������ɱ�,ǰ���ǵ��������ظ���Ʒ.

 �����ż��ɱ��������  
 ������ģ��������ɱ� 
  
 �ɹ���ⵥ1509���ɹ��˻���1504���������4630�������˻�4631���������۳���2401�����������˻�2418��
 ���۳��ⵥ2419�������˻���2420���������ⵥ2450���ͻ���4950���˻���4951���������ⵥ2424��������ⵥ1507��
 ���ϳ��ⵥ1523���̿���1501����ӯ��1520���ɱ����2136���ɱ����۵�1512���ڲ����۳��ⵥ4031���ڲ������˻���4032��
 �ڲ��ɹ���ⵥ4061���ڲ��ɹ��˻���4062���������ص�1557�����ŵ�����1553
 select top 100 * from istockledgerlog where formid=1553
 ���ڼ�1512���۽跽������
 1557,1553���۽跽������
 SELECT doccode,formid,rowid,matcode,plantid,sdorgid,periodid,digit,netmoney,ratemoney FROM vCommsales WHERE doccode='GDR2013020200000'
 */  

 alter PROC sp_BatchComputeSdorgMatLedger(  
  @doccode VARCHAR(50),  --����  
  @formid VARCHAR(10),     --���ܺ�  
  @plantid VARCHAR(50),  --��˾���  
  @sdorgid VARCHAR(50),  --���ű��  
  @periodid VARCHAR(10)  --�ڼ�  
  @ResultXML nvarchar(max)='' output
 )  
 AS  
 BEGIN
 	 SET NOCOUNT ON  
 	 declare @tips varchar(max)
 	IF @formid IN (1512) SET b.digit=0
	IF isnull(@plantid,'')=''  
	 BEGIN  
		 RAISERROR('����ʱ,��˾Ϊ��ֵ,���ʴ���!',16,1)  
		 RETURN  
	 END  
	  IF isnull(@sdorgid,'')=''  
	 BEGIN  
		 RAISERROR('����ʱ,����Ϊ��ֵ,���ʴ���!',16,1)  
		 RETURN  
	 END  
	  IF isnull(@formid,'') NOT IN (4631,2401,2419,2450,4950,2424,1523,1501,4031,1598,1504,4062,1553,1557,1509,4630,1507,1520,1512,4061,1599,2418,2420,4951,4032)  
	 BEGIN  
		 RAISERROR('ҵ����δ��ӣ�����!',16,1)  
		 RETURN  
	 END
	 if exists(Select 1 from #table where isnull(matcode,'')='')
	 BEGIN
		 RAISERROR('����ʱ,��ƷΪ��ֵ,���ʴ���!',16,1)  
		 RETURN 
	 END
--��������������ı����
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
 
  ---------------------���� ȡ�ƶ���Ȩƽ���ɱ�-------------------------
  --����  ��������     4631,2401,2419,2450,4950,2424,1523,1501,4031,1598   
  IF b.mode=1 
 	BEGIN
 		UPDATE a 
 		SET stock=isnull(stock,0)-b.digit,StockValue =isnull(stockvalue,0)-map*b.digit,ratevalue = isnull(ratevalue,0)-ratemap*b.digit 
 		output inserted.matcode,b.rowid,deleted.stock,deleted.stockvalue,deleted.ratevalue,b.digit,b.totamoney,b.ratemoney,inserted.stock,inserted.stockvalue,inserted.ratevalue,b.mode,b.type into @table
 		from iMatsdorgLedger a inner join #table b
 		on plantid=@plantid and sdorgid=@sdorgid AND matcode=b.matcode
		if @@Rowcount=0
			begin
				raiserror('�޳ɱ����ݣ��޷��������ɱ���',16,1)
				return
			end 
 		END
  --����  �跽����     1504,4062      1553,1557--������Ʒ
  IF b.mode=2
 	BEGIN	
 		UPDATE a SET stock=isnull(stock,0)-b.digit,StockValue =isnull(stockvalue,0)-map*b.digit,ratevalue = isnull(ratevalue,0)-ratemap*b.digit 
 		output inserted.matcode,b.rowid,deleted.stock,deleted.stockvalue,deleted.ratevalue,b.digit,b.totamoney,b.ratemoney,inserted.stock,inserted.stockvalue,inserted.ratevalue,b.mode,b.type into @table
 		from iMatsdorgLedger a,#table b
 		on plantid=@plantid and sdorgid=@sdorgid AND matcode=@matcode
		if @@Rowcount=0
			begin
				raiserror('�޳ɱ����ݣ��޷��������ɱ���',16,1)
			end 
 	END
  ---------------------��� ȡ���ɱ�------------------------
  --���  �跽����    1509,4630,1507,1520,1512,4061,1599    1553,1557--�����Ʒ
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
      
		--����ԭ��
 	END
  --���  ��������    2418,2420,4951,4032
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