/*
ʾ��:
begin tran
exec sp_ExecuteRecomputeSDorgMatLedger '2013-02-01','2013-02-28','','','','1.09.015.1.2.3.3','','',''
 
rollback
commit
 
*/
alter proc sp_ExecuteRecomputeSDorgMatLedger
	@BeginDate DATETIME='',									--������ʼʱ��
	@EndDate datetime='',										--�������ʱ��
	@CompanyID varchar(200)='',								--���㹫˾,���ö��ŷָ������˾
	@SDorgID varchar(200)='',									--���㲿��,���������ⲿ�Žڵ�,���ö��ŷָ��������
	@Matgroup varchar(max)='',								--������Ʒ����,�������������ڵ�,���ö��ŷָ��������
	@Matcode varchar(max)='',									--������Ʒ����,���ö��ŷָ������Ʒ����
	@OptionID varchar(200)='',									--ѡ��ֵ
	@StartID int=0,													--��ʼID,�ɴӿ����ϸ��ָ����ID��ʼ����
	@Usercode varchar(50)='',									--ִ����
	@TerminalID varchar(50)=''									--ִ���ն�
as
	BEGIN
		set NOCOUNT ON
		declare @Doccode varchar(50),@FormID int,@DocDate datetime,@SDorgID1 varchar(50),@InsertTime datetime,@Stcode varchar(50)
		declare @CompanyID1 varchar(50),@PeriodID varchar(7),@RefCode varchar(50),@RefFormID int,@tips varchar(max),@ID int
		declare @i int,@speed money,@count int
		--��������������ı����
	 Create Table #ResultTable (
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
		declare cur_Doc CURSOR READ_ONLY fast_forward forward_only  for
		--��InsertTime����,ÿ�����ݵ�Inserttime��ͬ,��Inserttime�������
		Select  i.Doccode,i.formid,i.docdate,i.companyid,i.periodid,i.sdorgid, max(i.inserttime) as inserttime,max(id) as id
		From istockledgerlog i with(nolock)
		inner join iMatGeneral img with(nolock) on i.matcode=img.MatCode
		inner join iMatGroup img2 with(nolock) on img.MatGroup=img2.matgroup
		where (@BeginDate='' or i.docdate>=@BeginDate)
		and (@EndDate='' or i.docdate<=@EndDate)
		and (@CompanyID='' or exists(select 1 from commondb.dbo.split(isnull(@CompanyID,''),',') x where  i.companyid=x.List))
		and (@SDorgID='' or exists(select 1 from commondb.dbo.split(isnull(@SDorgID,''),',') x where  i.sdorgid=x.List))
		and (@Matcode='' or exists(select 1 from commondb.dbo.split(isnull(@Matcode,''),',') x where  iMG.matcode=x.List))
		and (@Matgroup='' or exists(select 1 from commondb.dbo.split(isnull(@Matgroup,''),',') x where  img2.path like '%/'+x.List+'/%'))
		and i.formid in(1501,1504,1507,1509,1520,1523,1553,1557,1598,1599,2401,2418,2419,2420,2450,4032,4061,4630,4631,4950,4951)
		and (@OptionID='' or i.doccode=@OptionID)
		and i.ID>=@StartID
		and isnull(digit,0)<>0														--���˵�����Ϊ����
		group by i.doccode,i.formid,i.docdate,i.CompanyID,i.PeriodID,i.SDorgID--,inserttime
		order by inserttime,id
 
		open cur_Doc
		fetch next FROM cur_Doc into @Doccode,@FormID,@DocDate,@CompanyID1,@PeriodID,@SDorgID1,@InsertTime,@ID
		select @count=@@CURSOR_ROWS,@i=1
		while @@FETCH_STATUS=0
			BEGIN
				--print 100.00*@i/@count
				--print @CompanyID1 +','+@PeriodID +','+convert(varchar(10),@FormID)+','+ @Doccode
				--������ⵥȡ�����γ�����Ϣ
				if @FormID  in(1507)
					BEGIN
						select @RefCode=refCode,@RefFormID=2424
						from imatdoc_h with(nolock)
						where DocCode=@Doccode
					END
				--�����˻���ȡ��ԭ�˻���
				if @FormID in(2420)
					BEGIN
						select @RefFormID=2419,@RefCode=sph.ClearDocCode
						from sPickorderHD sph with(nolock)
						where sph.DocCode=@Doccode
					END
				--��˾�ڲɹ����ȡ����˾�����۳��ⵥ��Ϣ
				if @FormID in(4061)
					BEGIN
						select @RefFormID=4031,@RefCode=refcode
						from imatdoc_h a with(nolock)
						where a.DocCode=@Doccode
					END
				--4032�ڲ������˻������ڲ��ɹ��˻��ĳ���ɱ����
				if @FormID in(4032)
					BEGIN
						select @RefFormID=4062,@RefCode=refcode
						From spickorderhd a with(nolock)
						where a.DocCode=@Doccode
					END
				--���ŵ������������� �ȼ������
				if @FormID in(1553,1557)
					BEGIN
						select @Optionid=1
					END
				BEGIN TRY
					exec sp_ReComputeSDorgMatLedger @FormID,@Doccode,@CompanyID1,@PeriodID,@SDorgID1,
					@DocDate,@Matgroup,@Matcode,@RefFormID,@RefCode,@Optionid,@InsertTime ,@Usercode,@TerminalID
					--���ŵ������������� ����Ҫ�ټ������
					if @FormID in(1553,1557)
						BEGIN
							select @Optionid=2
							exec sp_ReComputeSDorgMatLedger @FormID,@Doccode,@CompanyID1,@PeriodID,@SDorgID1,
							@DocDate,@Matgroup,@Matcode,@RefFormID,@RefCode,@Optionid,@InsertTime ,@Usercode,@TerminalID
						END
				END TRY
				BEGIN CATCH
					select @tips=dbo.getLastError('')
					close cur_Doc
					deallocate cur_doc
					raiserror(@tips,16,1)
					return
				END CATCH
				fetch next FROM cur_Doc into @Doccode,@FormID,@DocDate,@CompanyID1,@PeriodID,@SDorgID1,@InsertTime,@ID
			END
		close cur_Doc
		deallocate cur_doc
		--select * from #ResultTable
		----------------------------------------------------------------��������------------------------------------------------------------------------------
		/*
		--����ԭ��                  
		--�ɹ���ⵥ 1509 ��ӯ�� 1520 ��ӯ��ⵥ 1599 �ɹ��˻��� 1504 ���ϳ��ⵥ 1523 �̿��� 1501 �ڲ��ɹ��˻��� 4062 �̿����ⵥ 1598                  
		IF @formid IN (1509,1520,1599)                  
		BEGIN                  
		 UPDATE imatdoc_d SET  netmoney=isnull(a.StockValue,0)-isnull(a.OldStockValue,0), matcost=isnull(a.StockValue,0)-isnull(a.OldStockValue,0),    
		  rateprice=(isnull(a.RateValue,0)-isnull(a.OldRateValue,0))/isnull(a.Digit,0),ratemoney =isnull( a.RateValue,0)-isnull(a.OldRateValue,0)                 
		 FROM imatdoc_d d with(nolock) inner join #ResultTable  a on d.rowid=a.docrowid AND d.MatCode=a.Matcode AND d.DocCode=a.doccode                  
		END                      
		IF @formid IN (1504,1523,1501,4062,1598)      --            
		BEGIN                  
		 UPDATE imatdoc_d SET netprice =(isnull(a.OldStockValue,0)-isnull(a.StockValue,0))/isnull(a.Digit,0),netmoney =isnull(a.OldStockValue,0)-isnull(a.StockValue,0),                
			 matcost=isnull(a.OldStockValue,0)-isnull(a.StockValue,0),rateprice = (isnull(a.OldRateValue,0)-isnull(a.RateValue,0))/isnull(a.Digit,0),ratemoney = isnull(a.OldRateValue,0)-isnull(a.RateValue,0)                   
		 FROM imatdoc_d d with(nolock) inner join #XMLDataTable a on d.rowid=a.RowID AND d.MatCode=a.Matcode AND d.DocCode=a.doccode          
		 --UPDATE imatdoc_h SET PeriodID = @periodid,DocDate =@DocDate WHERE DocCode=@doccode AND FormID=4062               
		END                  
		IF @formid IN (1507,4061) --������ⵥ,�ڲ��ɹ���ⵥ                  
		BEGIN                  
		 UPDATE imatdoc_d SET matcost= isnull(a.StockValue,0)-isnull(a.OldStockValue,0),price=(isnull(a.StockValue,0)-isnull(a.OldStockValue,0))/isnull(a.Digit,0),totalmoney=isnull( a.StockValue,0)-isnull(a.OldStockValue,0),                  
		 netprice=(isnull(a.StockValue,0)-isnull(a.OldStockValue,0))/isnull(a.Digit,0),netmoney=isnull(a.StockValue,0)-isnull(a.OldStockValue,0),          
		 rateprice=(isnull(a.RateValue,0)-isnull(a.OldRateValue,0))/isnull(a.Digit,0),ratemoney=isnull(a.RateValue,0)-isnull(a.OldRateValue,0)                  
		 FROM imatdoc_d d with(nolock) inner join #ResultTable a on d.rowid=a.RowID AND d.MatCode=a.Matcode AND d.DocCode=a.doccode                  
		END                  
                  
		--������� 4630 �����˻� 4631                  
		IF @formid IN (4630)                  
		BEGIN                  
		 UPDATE Commsales_d SET netmoney=isnull(a.StockValue,0)-isnull(a.OldStockValue,0), matcost=isnull(a.StockValue,0)-isnull(a.OldStockValue,0),rateprice = (isnull(a.RateValue,0)-isnull(a.OldRateValue,0))/isnull(a.Digit,0),          
		 ratemoney = isnull(a.RateValue,0)-isnull(a.OldRateValue,0)                  
		 FROM Commsales_d d with(nolock) inner join #ResultTable a on d.rowid=a.RowID AND d.MatCode=a.Matcode AND d.DocCode=@doccode                  
		END                  
                  
		IF @formid IN (4631)                  
		BEGIN                  
		 UPDATE Commsales_d SET netmoney=isnull(a.OldStockValue,0)-isnull(a.StockValue,0), matcost=isnull(a.OldStockValue,0)-isnull(a.StockValue,0),rateprice = (isnull(a.OldRateValue,0)-isnull(a.RateValue,0))/isnull(a.Digit,0),          
		 ratemoney = isnull(a.OldRateValue,0)-isnull(a.RateValue,0)          
		 FROM Commsales_d d with(nolock) inner join #ResultTable a on d.rowid=a.RowID AND d.MatCode=a.Matcode AND d.DocCode=@doccode                  
		END                 
                  
		-- �������ص� 1557 ���ŵ����� 1553                   
		IF @formid IN (1557,1553)                  
		BEGIN            
		 IF @OptionID='1'          
		 BEGIN          
		  UPDATE iserieslogitem SET netprice = abs(isnull(a.StockValue,0)-isnull(a.OldStockValue,0))/isnull(a.Digit,0), netmoney=abs(isnull(a.StockValue,0)-isnull(a.OldStockValue,0)),                
		   rateprice = abs(isnull(a.RateValue,0)-isnull(a.OldRateValue,0))/isnull(a.Digit,0),ratemoney = abs(isnull(a.RateValue,0)-isnull(a.OldRateValue,0))          
		  FROM iserieslogitem d with(nolock) inner join #ResultTable a on d.rowid=a.RowID AND d.MatCode1=a.Matcode AND d.DocCode=@doccode          
		 END          
            
		 IF @OptionID='2'          
		 BEGIN          
		  UPDATE iserieslogitem SET netprice1 =abs(isnull(a.StockValue,0)-isnull(a.OldStockValue,0))/isnull(a.Digit,0),netmoney1=abs(isnull(a.StockValue,0)-isnull(a.OldStockValue,0)),           
		   rateprice1 = abs(isnull(a.RateValue,0)-isnull(a.OldRateValue,0))/isnull(a.Digit,0),ratemoney1 = abs(isnull(a.RateValue,0)-isnull(a.OldRateValue,0))                  
		  FROM iserieslogitem d with(nolock) inner join #XMLDataTable a on d.rowid=a.RowID AND d.MatCode=a.Matcode AND d.DocCode=@doccode          
		 END           
		END                  
                  
		--�������۳��� 2401 ���������˻� 2418 ���۳��ⵥ 2419 �����˻��� 2420 �������ⵥ 2450 �ͻ��� 4950 �˻��� 4951                   
		--�ڲ����۳��ⵥ 4031 �ڲ������˻��� 4032 �������ⵥ 2424                  
		IF @formid IN (2401,2418,2419,2420,2450,4950,4951,4031,4032,2424)                  
		BEGIN                  
		 UPDATE spickorderitem SET netprice = abs(isnull(a.StockValue,0)-isnull(a.OldStockValue,0))/isnull(a.Digit,0),netmoney =abs(isnull(a.StockValue,0)-isnull(a.OldStockValue,0)),                   
			MatCostPrice = abs(isnull(a.StockValue,0)-isnull(a.OldStockValue,0))/isnull(a.Digit,0),MatCost =abs(isnull(a.StockValue,0)-isnull(a.OldStockValue,0)),                
			rateprice = abs(isnull(a.RateValue,0)-isnull(a.OldRateValue,0))/isnull(a.Digit,0),ratemoney =abs(isnull(a.RateValue,0)-isnull(a.OldRateValue,0))                  
		 FROM spickorderitem d with(nolock) inner join #XMLDataTable a on d.rowid=a.RowID AND d.MatCode=a.Matcode AND d.DocCode=@doccode              
           
		  --UPDATE sPickorderHD SET periodid = @periodid,DocDate =@DocDate WHERE DocCode=@doccode AND FormID IN (2424,4031)                 
		END                  
 */
	END