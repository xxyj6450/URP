/*  
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

 alter PROC sp_ComputeSdorgMatLedger(
  @doccode VARCHAR(50),  --����  
  @formid VARCHAR(10),     --���ܺ�  
  @DocDate datetime,
  @rowid VARCHAR(50),   --�к�  
  @matcode VARCHAR(50),  --��Ʒ���
  @Seriescode varchar(50),
  @plantid VARCHAR(50),  --��˾���  
  @sdorgid VARCHAR(50),  --���ű��  
  @periodid VARCHAR(10),  --�ڼ�  
  @digit MONEY,    --����  
  @totalmoney MONEY,   --���  
  @ratemoney MONEY,   --��˰����  
  @mode int,     --1����������2���⸺����3���������4��⸺��
  @type varchar(50),   --����ģʽ
  @OptionID varchar(50)='',
  @ResultXML nvarchar(max)='' output
 )  
 AS  
 SET NOCOUNT ON  
 --DECLARE @map MONEY ,@ratemap money
 BEGIN
 	IF @formid IN (1512) SET @digit=0
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
	  IF ISNULL(@matcode,'')=''
	 BEGIN
		 RAISERROR('����ʱ,��ƷΪ��ֵ,���ʴ���!',16,1)  
		 RETURN 
	 END
--��������������ı����
 declare @table table(
 	SDOrgID varchar(50),
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
 
  ---------------------���� ȡ�ƶ���Ȩƽ���ɱ�-------------------------
  /*
  �ɹ��˻�1504,�����˻�4631,���۳��ⵥ2419,�������ⵥ2450,�ͻ���4950,�������ⵥ2424,���ϳ��ⵥ1523,�̿���1501,
  �ڲ����۳��ⵥ4031,�ڲ��ɹ��˻���4062,
  */
  --����  ��������     4631,2401,2419,2450,4950,2424,1523,1501,4031,1598   
  IF @mode=1 
 	BEGIN
 		
 		UPDATE iMatsdorgLedger 
 		SET stock=isnull(stock,0)-@digit,StockValue =isnull(stockvalue,0)-map*@digit,ratevalue = isnull(ratevalue,0)-ratemap*@digit,
 		ModifyDate=getdate(),ModifyDoccode=@doccode
 		output @sdorgid, inserted.matcode,@Seriescode ,@RowID,deleted.stock,deleted.stockvalue,deleted.ratevalue,@Digit,@TotalMoney,@Ratemoney,inserted.stock,inserted.stockvalue,inserted.ratevalue,@Mode,@Type into @table
 		WHERE   sdorgid=@sdorgid AND matcode=@matcode
		if @@Rowcount=0
			begin
				raiserror('�޳ɱ����ݣ��޷��������ɱ���',16,1)
				return
			end 
 		END
  --����  �跽����     1504,4062      1553,1557--������Ʒ
  IF @mode=2
 	BEGIN
 		UPDATE iMatsdorgLedger SET stock=isnull(stock,0)-@digit,StockValue =isnull(stockvalue,0)-map*@digit,ratevalue = isnull(ratevalue,0)-ratemap*@digit,
 		ModifyDate=getdate(),ModifyDoccode=@doccode
 		output @sdorgid,inserted.matcode,@Seriescode ,@RowID,deleted.stock,deleted.stockvalue,deleted.ratevalue,@Digit,@TotalMoney,@Ratemoney,inserted.stock,inserted.stockvalue,inserted.ratevalue,@Mode,@Type into @table
 		WHERE  sdorgid=@sdorgid AND matcode=@matcode
		if @@Rowcount=0
			begin
				raiserror('�޳ɱ����ݣ��޷��������ɱ���',16,1)
			end 
 		END
  ---------------------��� ȡ���ɱ�------------------------
  --���  �跽����    1509,4630,1507,1520,1512,4061,1599    1553,1557--�����Ʒ
  IF @mode=3
 	BEGIN
 		UPDATE iMatsdorgLedger SET stock=isnull(stock,0)+@digit,StockValue =isnull(stockvalue,0)+@totalmoney,ratevalue = isnull(ratevalue,0)+@ratemoney,
 		ModifyDate=getdate(),ModifyDoccode=@doccode
		output @sdorgid,inserted.matcode,@Seriescode ,@RowID,deleted.stock,deleted.stockvalue,deleted.ratevalue,@Digit,@TotalMoney,@Ratemoney,inserted.stock,inserted.stockvalue,inserted.ratevalue,@Mode,@Type into @table
		WHERE   sdorgid=@sdorgid AND matcode=@matcode
 		
		if @@rowcount = 0                
		insert into iMatsdorgLedger (plantid,sdorgid,matcode,stock,stockvalue,ratevalue,modifydate,modifydoccode)      
		output @sdorgid,inserted.matcode,@Seriescode ,@RowID,0,0,0,@Digit,@totalmoney,@RateMoney,inserted.stock,inserted.stockvalue,inserted.ratevalue,@Mode,@Type into @table          
		values (@plantid,@sdorgid,@matcode,@digit,@totalmoney,@ratemoney,getdate(),@doccode) 
     
		--����ԭ��
 	END
  --���  ��������    2418,2420,4951,4032
  IF @mode=4
 	BEGIN
 		UPDATE iMatsdorgLedger SET stock=isnull(stock,0)+@digit,StockValue =isnull(stockvalue,0)+isnull(@totalmoney,0),ratevalue = isnull(ratevalue,0)+@ratemoney,
 		ModifyDate=getdate(),ModifyDoccode=@doccode
		output @sdorgid,inserted.matcode,@Seriescode ,@RowID,deleted.stock,deleted.stockvalue,deleted.ratevalue,@Digit,@TotalMoney,@Ratemoney,inserted.stock,inserted.stockvalue,inserted.ratevalue,@Mode,@Type into @table
		WHERE   sdorgid=@sdorgid AND matcode=@matcode
		if @@rowcount = 0                
		insert into iMatsdorgLedger (plantid,sdorgid,matcode,stock,stockvalue,ratevalue,modifydate,modifydoccode)           
		output @sdorgid,inserted.matcode,@Seriescode ,@RowID,0,0,0,@Digit,@totalmoney,@RateMoney,inserted.stock,inserted.stockvalue,inserted.ratevalue,@Mode,@Type into @table        
		values (@plantid,@sdorgid,@matcode,@digit,@totalmoney,@ratemoney,getdate(),@doccode) 
	
 	END
 	select *from @table
 	insert into #ResultTable(Doccode,FormID,DocDate, SDOrgID,Matcode,Seriescode,RowID,OldStock,OldStockValue,OldRateValue,Digit,Totalmoney,ratemoney,Stock,StockValue,RateValue,Mode,ComputeType,OptionID)
    select @doccode,@formid,@DocDate, @sdorgid,a.Matcode,a.seriescode,a.RowID,a.OldStock,a.OldStockValue,a.OldRateValue,a.Digit,a.Totalmoney,a.RateMoney,a.Stock,a.StockValue,a.RateValue,a.Mode,a.ComputeType,@OptionID
    from @table a
    select @resultxml=(select * From @table For XML RAW)
    print @ResultXML
END