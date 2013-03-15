/*
示例:
begin tran
exec sp_ExecuteRecomputeSDorgMatLedger '2013-02-01','2013-02-28','','','','1.09.015.1.2.3.3','','',''
 
rollback
commit
 
*/
alter proc sp_ExecuteRecomputeSDorgMatLedger
	@BeginDate DATETIME='',									--重算起始时间
	@EndDate datetime='',										--重算结束时间
	@CompanyID varchar(200)='',								--重算公司,可用逗号分隔多个公司
	@SDorgID varchar(200)='',									--重算部门,可以是任意部门节点,可用逗号分隔多个部门
	@Matgroup varchar(max)='',								--重算商品大类,可以是任意大类节点,可用逗号分隔多个大类
	@Matcode varchar(max)='',									--重算商品编码,可用逗号分隔多个商品编码
	@OptionID varchar(200)='',									--选项值
	@StartID int=0,													--起始ID,可从库存明细账指定的ID开始重算
	@Usercode varchar(50)='',									--执行人
	@TerminalID varchar(50)=''									--执行终端
as
	BEGIN
		set NOCOUNT ON
		declare @Doccode varchar(50),@FormID int,@DocDate datetime,@SDorgID1 varchar(50),@InsertTime datetime,@Stcode varchar(50)
		declare @CompanyID1 varchar(50),@PeriodID varchar(7),@RefCode varchar(50),@RefFormID int,@tips varchar(max),@ID int
		declare @i int,@speed money,@count int
		--用于输出计算结果的表变量
	 Create Table #ResultTable (
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
		declare cur_Doc CURSOR READ_ONLY fast_forward forward_only  for
		--按InsertTime排序,每个单据的Inserttime相同,按Inserttime排序计算
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
		and isnull(digit,0)<>0														--过滤掉数量为０的
		group by i.doccode,i.formid,i.docdate,i.CompanyID,i.PeriodID,i.SDorgID--,inserttime
		order by inserttime,id
 
		open cur_Doc
		fetch next FROM cur_Doc into @Doccode,@FormID,@DocDate,@CompanyID1,@PeriodID,@SDorgID1,@InsertTime,@ID
		select @count=@@CURSOR_ROWS,@i=1
		while @@FETCH_STATUS=0
			BEGIN
				--print 100.00*@i/@count
				--print @CompanyID1 +','+@PeriodID +','+convert(varchar(10),@FormID)+','+ @Doccode
				--调拔入库单取出调拔出库信息
				if @FormID  in(1507)
					BEGIN
						select @RefCode=refCode,@RefFormID=2424
						from imatdoc_h with(nolock)
						where DocCode=@Doccode
					END
				--零售退货单取出原退货单
				if @FormID in(2420)
					BEGIN
						select @RefFormID=2419,@RefCode=sph.ClearDocCode
						from sPickorderHD sph with(nolock)
						where sph.DocCode=@Doccode
					END
				--公司内采购入库取出公司内销售出库单信息
				if @FormID in(4061)
					BEGIN
						select @RefFormID=4031,@RefCode=refcode
						from imatdoc_h a with(nolock)
						where a.DocCode=@Doccode
					END
				--4032内部销售退货，以内部采购退货的出库成本入库
				if @FormID in(4032)
					BEGIN
						select @RefFormID=4062,@RefCode=refcode
						From spickorderhd a with(nolock)
						where a.DocCode=@Doccode
					END
				--串号调整，返厂返回 先计算出库
				if @FormID in(1553,1557)
					BEGIN
						select @Optionid=1
					END
				BEGIN TRY
					exec sp_ReComputeSDorgMatLedger @FormID,@Doccode,@CompanyID1,@PeriodID,@SDorgID1,
					@DocDate,@Matgroup,@Matcode,@RefFormID,@RefCode,@Optionid,@InsertTime ,@Usercode,@TerminalID
					--串号调整，返厂返回 还需要再计算入库
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
		----------------------------------------------------------------回填数据------------------------------------------------------------------------------
		/*
		--回填原单                  
		--采购入库单 1509 盘盈单 1520 盘盈入库单 1599 采购退货单 1504 领料出库单 1523 盘亏单 1501 内部采购退货单 4062 盘亏出库单 1598                  
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
		IF @formid IN (1507,4061) --调拨入库单,内部采购入库单                  
		BEGIN                  
		 UPDATE imatdoc_d SET matcost= isnull(a.StockValue,0)-isnull(a.OldStockValue,0),price=(isnull(a.StockValue,0)-isnull(a.OldStockValue,0))/isnull(a.Digit,0),totalmoney=isnull( a.StockValue,0)-isnull(a.OldStockValue,0),                  
		 netprice=(isnull(a.StockValue,0)-isnull(a.OldStockValue,0))/isnull(a.Digit,0),netmoney=isnull(a.StockValue,0)-isnull(a.OldStockValue,0),          
		 rateprice=(isnull(a.RateValue,0)-isnull(a.OldRateValue,0))/isnull(a.Digit,0),ratemoney=isnull(a.RateValue,0)-isnull(a.OldRateValue,0)                  
		 FROM imatdoc_d d with(nolock) inner join #ResultTable a on d.rowid=a.RowID AND d.MatCode=a.Matcode AND d.DocCode=a.doccode                  
		END                  
                  
		--代销入库 4630 代销退货 4631                  
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
                  
		-- 返厂返回单 1557 串号调整单 1553                   
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
 */
	END