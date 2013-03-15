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
  @doccode VARCHAR(50),		--����  
  @formid VARCHAR(10),		--���ܺ�
  @DocDate datetime,			--��������
  @plantid VARCHAR(50),		--��˾���  
  @sdorgid VARCHAR(50),		--���ű��  
  @periodid VARCHAR(10),		--�ڼ�
  @Mode int,
  @ComputeType varchar(50)='',
  @OptionID varchar(50)='',
  @ResultXML nvarchar(max)='' output
 )  
 AS  
 BEGIN
 	 SET NOCOUNT ON  
 	 declare @tips varchar(max)
 	 --��������������ı����
	 /* Create Table #ResultTable (
	 	FormID int,
	 	Doccode varchar(20),
	 	Refformid int,
	 	RefCode varchar(30),
	 	plantID varchar(20),
	 	SDOrgID varchar(50),
	 	Periodid varchar(7),
 		Matcode varchar(50),						--��Ʒ����
		RowID varchar(50),							--x
 		OldStock int,									--ԭ���
 		OldStockValue money,					--ԭ�����
 		OldRateValue money,						--ԭ�ӳɽ��
		Digit int,										--�޸Ŀ����
		Totalmoney money,						--�޸Ŀ����
		RateMoney money,						--�޸ļӳɽ��
 		Stock int,										--��������
 		StockValue money,							--��������
 		RateValue money,							--����ӳɽ��
		Mode char,									--�����ģʽ 1����������2���⸺����3���������4��⸺��
		ComputeType  varchar(50),				--����ģʽ
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
 
 
  ---------------------���� ȡ�ƶ���Ȩƽ���ɱ�-------------------------
  --����  ��������     4631,2401,2419,2450,4950,2424,1523,1501,4031,1598   
    IF @MODE=1 
 	BEGIN
 		
 		UPDATE  a
 		SET stock=isnull(stock,0)-isnull(b.digit,0),StockValue =isnull(stockvalue,0)-isnull(map,0)*isnull(b.digit,0),ratevalue = isnull(ratevalue,0)-isnull(ratemap,0)*isnull(b.digit,0),
 		ModifyDate=getdate(),ModifyDoccode=@doccode
 		output @sdorgid, inserted.matcode,b.seriescode,b.RowID,deleted.stock,deleted.stockvalue,deleted.ratevalue,b.Digit,
 		b.TotalMoney,b.Ratemoney,inserted.stock,inserted.stockvalue,inserted.ratevalue,@MODE,b.ComputeType into @table
 		From iMatsdorgLedger a with(nolock) inner join #table b on a.sdorgid=@sdorgid and a.MatCode=b.matcode
		SET @tips='����['+@sDOrgID+']'
 		select @tips=@tips+'��Ʒ['+a.matcode+']�޳ɱ����ݣ��޷��������ɱ�.'+char(10)
 		from #table a 
		where not exists(select 1 from @table b where a.matcode=b.Matcode)  
 		if @@Rowcount<>0
			begin
				raiserror(@tips,16,1)
			end 
 		END
  --����  �跽����     1504,4062      1553,1557--������Ʒ
  IF @MODE=2
 	BEGIN
 		UPDATE a SET stock=isnull(stock,0)-isnull(b.digit,0),StockValue =isnull(stockvalue,0)-isnull(map,0)*isnull(b.digit,0),ratevalue = isnull(ratevalue,0)-isnull(ratemap,0)*isnull(b.digit,0),
 		ModifyDate=getdate(),ModifyDoccode=@doccode
 		output @sdorgid,inserted.matcode,b.seriescode,b.rowid,deleted.stock,deleted.stockvalue,deleted.ratevalue,b.digit,b.totalmoney,
 		b.ratemoney,inserted.stock,inserted.stockvalue,inserted.ratevalue,@MODE,b.ComputeType into @table
 		From iMatsdorgLedger a with(nolock) inner join #table b on a.sdorgid=@sdorgid and a.MatCode=b.matcode
 		SET @tips='����['+@sDOrgID+']'
 		select @tips=@tips+'��Ʒ['+a.matcode+']�޳ɱ����ݣ��޷��������ɱ�.'+char(10)
 		from #table a 
		where not exists(select 1 from @table b where a.matcode=b.Matcode)  
 		if @@Rowcount<>0
			begin
				raiserror(@tips,16,1)
			end 
 		END
  ---------------------��� ȡ���ɱ�------------------------
  --���  �跽����    1509,4630,1507,1520,1512,4061,1599    1553,1557--�����Ʒ
  IF @MODE=3
 	BEGIN
 		UPDATE a 
 		SET stock=isnull(stock,0)+isnull(b.digit,0),StockValue =isnull(stockvalue,0)+isnull(b.totalmoney,0),ratevalue = isnull(ratevalue,0)+isnull(b.ratemoney,0),
 		ModifyDate=getdate(),ModifyDoccode=@doccode
		output @sdorgid,inserted.matcode,b.seriescode,b.rowid,deleted.stock,deleted.stockvalue,deleted.ratevalue,
		b.digit,b.totalmoney,b.ratemoney,inserted.stock,inserted.stockvalue,inserted.ratevalue,@MODE,b.ComputeType 
		into @table
		From iMatsdorgLedger a with(nolock) inner join #table b on a.sdorgid=@sdorgid and a.MatCode=b.matcode
 
 		--��δ���µ����в������ɱ���
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
  --���  ��������    2418,2420,4951,4032
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