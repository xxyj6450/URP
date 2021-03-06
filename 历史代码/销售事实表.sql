USE [BIDB]
GO
/****** Object:  StoredProcedure [dbo].[sp_ImportFactData]    Script Date: 09/08/2011 13:54:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
begin tran 
exec sp_importfactdata 'ItemActivity','','2011-05-01','2011-08-01','2424,1507'
commit
rollback
*/
ALTER PROC [dbo].[sp_ImportFactData]
	@Datasource VARCHAR(50),
	@doccode VARCHAR(20)='',
	@beginDay DATETIME='',
	@endday DATETIME='',
	@FormID VARCHAR(20)='',
	@SDORGID VARCHAR(20)='',
	@Stcode VARCHAR(20)='',
	@AreaID VARCHAR(20)='',
	@Remark VARCHAR(200)=''
AS
	BEGIN
		SET NOCOUNT ON;
		SET XACT_ABORT ON;
		DECLARE @RowCount INT
		DECLARE @table table(ID INT,doccode VARCHAR(20),FormID int)
		BEGIN TRAN
		IF @Datasource LIKE '%SaleLog' OR @Datasource=''
			BEGIN
				DELETE FROM SOP_fact_SaleLog
				WHERE (@beginDay='' OR dtmdocdate >=@beginDay)
				AND (@endday='' OR dtmdocdate<=@endday)
				AND (@SDORGID='' OR strsdorgid=@SDORGID)
				AND (@AreaID='' OR @Areaid=strareaid)
				AND (@Stcode='' OR @Stcode=strstcode)
				AND (@doccode='' OR strdoccode=@doccode)
				DELETE @table
				INSERT INTO SOP_fact_SaleLog(strDocCode, intFormID, strDocType, dtmDocDate, strperiodid, 
				       strrefcode, strCompanyid, 
				       strsdorgid, strcltCode, strstcode,strareaid,
				       strsdgroup, strHDText, strTel, dblCash, dblCreditAmount, 
				       dblAgentRevenue, strEnterName, dtmEnterDate, strModifyName, 
				       dtmModifyDate, strPostName, dtmPostDate, intrefformid, strAuditing, 
				       strAuditingname, dtmAuditingdate, intprdno, strvndcode, 
				        strMatCode, strMatGroup, strseriesCode, intDigit, 
				       dblprice, dbltotalmoney, dblMinPrice, 
				       dblTransPrice, dblDiscountPrice, dbltotalScore, 
				       dblStandardScore, dblLsPrice, bitgift, bitinvoice, 
				       bitbrush, intweave, strPackageID, 
				       dblRewards, dblOperatingCost, 
				       strdpttype, strBusiType, 
				       dblProfit, dblOperatingProfit, dblmatcost, dblProfitRate, 
				       bitisSingleSale, intrefrefformid, strrefrefcode, 
				       strReservedDoccode, strCouponsBarcode, dbldeductAmout, 
				       strAPPName, strsUserName,intDirection)
				select a.DocCode, FormID, DocType, DocDate, periodid, 
				       case  when formid =2419 then a.refcode 
							WHEN formid=2420 THEN a.cleardoccode 
							WHEN formid in(4950,4951) THEN a.UserTxt1 
				       end,
				       Companyid,d.sdorgid, cltCode, a.stcode, d.areaid,
				       sdgroup,a.HDText, a.usertxt2 AS TEL, a.userdigit1 AS dblCash, a.userdigit2 AS dblCreditAmount, 
				       a.userdigit3 AS dblAgentRevenue, a.EnterName, a.EnterDate, a.ModifyName, 
				       a.ModifyDate, a.PostName, a.PostDate, refformid, Auditing, 
				       Auditingname, Auditingdate, case prdno WHEN '开错单冲红' then 1 WHEN '退货' THEN 2 WHEN '换货' THEN 3 ELSE 0 END, b.vndcode, 
				        b.MatCode, c.MatGroup, b.seriesCode, 
				       b.digit,b.price,b.totalmoney,b.selfprice,b.selfprice1,b.salesprice1,b.totalmoney-b.digit*b.selfprice1-isnull(b.userdigit2,0) AS totalScore,
				       --case  when formid in(2419,2401,4950) then b.Digit WHEN formid in(2420,2418,4951) THEN -digit END AS digit, 
				       --case  when formid in(2419,2401,4950) then  b.price WHEN formid in(2420,2418,4951) THEN -b.price END AS price, 
				       --case  when formid in(2419,2401,4950) then  totalmoney WHEN formid in(2420,2418,4951) THEN -totalmoney END AS totalmoney,
				       --case  when formid in(2419,2401,4950) then  selfprice WHEN formid in(2420,2418,4951) THEN -selfprice end as MinPrice, 
				       --case  when formid in(2419,2401,4950) then selfprice1 WHEN formid in(2420,2418,4951) THEN -selfprice1 END  as TransPrice,
				       --case  when formid in(2419,2401,4950) then  salesprice1 WHEN formid in(2420,2418,4951)THEN -salesprice1 end AS  DiscountPrice, 
				       --case  when formid in(2419,2401,4950) then  b.totalmoney-b.digit*b.selfprice1 WHEN formid in(2420,2418) THEN -(b.totalmoney-b.digit*b.selfprice1) end as totalScore, 
				       zcprice as StandardScore, b.LsPrice, gift, invoice, 
				       brush, weave, PackageID, Rewards, 
				       end4 as OperatingCost,dpttype, BusiType,0 as Profit,0 AS  OperatingProfit, matcost,0 as ProfitRate, 
				       isSingleSale, refrefformid, refrefcode,ReservedDoccode, CouponsBarcode, b.deductAmout, 
				       APPName, sUserName,CASE  WHEN formid in(2419,4950) THEN 1 ELSE -1 END AS intDirection
				FROM ierptest..spickOrderHD a,ierptest..spickOrderItem b,ierptest..iMatgeneral c,ierptest..ostorage d
				WHERE a.doccode=b.doccode
				AND a.stcode=d.stcode
				AND b.matcode=c.matcode
				AND a.formid IN(2419,2420,2401,2418)
				AND (@beginDay='' OR a.docdate >=@beginDay)
				AND (@endday='' OR a.docdate<=@endday)
				AND (@SDORGID='' OR d.sdorgid=@SDORGID)
				AND (@AreaID='' OR @Areaid=areaid)
				AND (@Stcode='' OR @Stcode=a.stcode)
				AND (@FormID='' OR EXISTS(SELECT 1 FROM SPLIT(@formid,',') x WHERE x.data=a.formid))
				AND (@doccode='' OR a.doccode=@doccode)
				AND a.docstatus = CASE WHEN a.formid IN(2401,2418,2419,2420) THEN 200 end
				SELECT @RowCount=@@ROWCOUNT
				INSERT INTO _sysImportLog(DataSource,[Event],UserName,parameters) VALUES(@Datasource,'导入销售数据','system',
				'beginday:'+convert(varchar(20),@beginday)+',EndDay:'+convert(varchar(20),@endday)+',SDORGID:'+@sdorgid+',stcode:'+@stcode+',Areaid:'+@areaid)	
			END
--------------------------------------------------------先删除数据------------------------------------------------------------------------------
		IF @Datasource LIKE '%ItemActivity' OR @Datasource='' OR EXISTS(SELECT 1 FROM getinstr(@FormID) WHERE list IN(2401,2418,2419,2420,2424,1507,1501,1520,4950,4951))
			BEGIN
				--删除主表
				PRINT '>>>>>>删除主表数据'
				DELETE @table
				DELETE FROM SOP_FACT_ItemActivity
				OUTPUT  deleted.intActivityID,deleted.varReceiptNO,DELETED.intformid INTO @table
				where (@beginDay='' OR  dtmDate >=@beginDay)
				 AND (@endday='' OR  dtmDate<=@endday)
				 AND intformid IN(2401,2418,2419,2420,2424,1507,1509,1504,1501,1520,4950,4951)
				 AND (@SDORGID='' OR  chvDepartmentCode=@SDORGID)
				 AND (@Stcode='' OR  chvStockCode=@Stcode)
				 AND (@doccode='' OR varReceiptNO=@doccode)
				 AND (@FormID='' OR EXISTS(SELECT 1 FROM getinstr(@FormID) WHERE list=intformid))
				 --删除明细表
				 PRINT '>>>>>>删除明细数据'
				 DELETE SOP_FACT_ItemActivityDetail
				 WHERE intActivityID IN(SELECT id FROM @table)
				 --删除大表数据
				 DELETE SOP_FACT_ItemInvoicing WHERE varReceiptNO IN(SELECT doccode FROM @table)
				 --删除临时表
				 DELETE @table
				--TRUNCATE TABLE SOP_FACT_ItemActivity
				--DBCC CHECKIDENT  ('SOP_FACT_ItemActivity',RESEED,0)
			END
------------------------------------------------------------------销售数据---------------------------------------------------------------
		IF @Datasource LIKE '%ItemActivity' OR @Datasource='' OR EXISTS(SELECT 1 FROM getinstr(@FormID) WHERE list IN(2401,2418,2419,2420,2424,4950,4951))
			begin
				PRINT '>>>>>>开始导入销售主表数据'  
				INSERT INTO SOP_FACT_ItemActivity(  dtmDate, intFormID, 
				       intUserFormID,varOrderActivity, varActivityTypeCode, varReceiptType, 
				       intYear, intPeriod, varReceiptNO, chvCustomerCode, 
				       chvCustomerTel, chvAreaCode, 
				       chvAreaRowID, chvDepartmentType, chvDepartmentCode, 
				       chvDepartmentRowID, chvStockCode, chvEmployeeCode, 
						varOperatorCode, dtmOperatorTime, 
				       varModifyUserCode, dtmModifyTime, varPostUserCode, 
				       dtmPostTime, varAuditingUserCode, dtmAuditingUserTime, 
				       intReturnCause, chvnNote,intDirection, 
				        mnyCashAmount, mnySlotCardAmount, 
				       mnyInstallmentAmount, chvnStoreAmount, varReservedCode, 
				       intRefrefFormid, varRefrefCode,intdatasource)
				 OUTPUT INSERTED.intActivityID,INSERTED.varReceiptNO,INSERTED.intformid INTO @table
				 SELECT docdate,formid,isnull(refformid,0) AS intUserFormID,
				 case formid 
					when 2420 then isnull(cleardoccode,'')
					WHEN 2424 THEN isnull(a.usertxt1,'')
					else isnull(refcode,'') 
				 END AS varOrderActivity,isnull(doctype,'') AS varActivityTypeCode,
				 case 
					when formid=2419 and refformid=9102 then '客户新入网'
					WHEN formid=2419 AND refformid=9146 THEN '套包业务'
					WHEN formid=2420 AND refrefformid=9102 THEN '客户新入网返销'
					WHEN formid=2420 AND refrefformid=9146 THEN '套包退货'
					WHEN formid=2419 AND ISNULL(refformid,0)=0 THEN '零售销售'
					WHEN formid=2420 AND ISNULL(refrefformid,0)=0 THEN '零售退货'
					WHEN formid=2424 THEN '调拔出库'
				ELSE '其他业务'
				END AS varReceiptType,
				YEAR(docdate) AS intYear,MONTH(docdate) AS intPeriod,doccode,isnull(cltcode,'888888') AS customercode,
				isnull(a.usertxt2,'') AS chvcustomertel  ,isnull(b.areaid,'') AS chvAreaCode,
				isnull(b.rowid,'') AS chvAreaRowID,isnull(c.dpttype,'') AS chvDepartmentType,isnull(c.sdorgid,'') AS chvDepartmentCode,
				isnull(c.rowid,'') AS chvDepartmentRowID,isnull(a.stcode,'') AS chvStockCode,isnull(a.sdgroup,'') AS chvEmployeeCode,
				isnull(a.entername,''),isnull(a.enterdate,getdate()),isnull(a.modifyname,''),isnull(a.modifydate,GETDATE()),isnull(a.postname,''),
				isnull(a.postdate,GETDATE()),isnull(a.auditingname,''),isnull(a.auditingdate,GETDATE()),
				(CASE a.prdno 
					WHEN '开错单冲红' then 1 
					WHEN '退货' THEN 2 
					WHEN '换货' THEN 3
					ELSE 0
				END )   AS intReturnCause,isnull(a.hdtext,''),
				CASE  
					WHEN formid in(2419,2401,2424,4950) THEN 1 
					WHEN formid IN(2420,2418,4951) THEN -1
					ELSE 0
				END  AS intDirection,
				case 
					WHEN a.formid IN(2419,2420) THEN  isnull(a.userdigit1,0)
					WHEN a.formid IN(4950,4951) THEN isnull(cavermoney,0)
					ELSE 0 
				end AS   mnyCashAmount ,												--现金收款
				CASE 
					WHEN a.formid IN(2419,2420) THEN  isnull(a.userdigit2,0) 
					else 0
				end as  mnySlotCardAmount,												--刷卡收款
				 isnull(a.summoney,0) AS mnyInstallmentAmount,							--分期收款
				 case 
					when formid in (2419,2420) then isnull(a.userdigit3,0) 
					else 0 
				end AS chvnStoreAmount,													--商场代收
				 isnull(a.reserveddoccode,'')  AS varReservedCode,						--预约编号
				 isnull(a.refrefformid,0) AS refrefformid,
				 isnull(a.refrefcode,'') AS refrefcode,
				 0 AS intdatasource
				 FROM ierptest..spickorderhd a,ierptest..garea b,ierptest..osdorg c,ierptest..ostorage d
				 WHERE a.formid IN(2419,2420,2401,2418,2424,4950,4951)
				 AND a.stcode=d.stcode
				 AND d.sdorgid=c.sdorgid
				 AND d.areaid=b.areaid
				 AND (@beginDay='' OR a.docdate >=@beginDay)
				 AND (@endday='' OR a.docdate<=@endday)
				 AND (@SDORGID='' OR c.sdorgid=@SDORGID)
				 AND (@Stcode='' OR d.stcode=@Stcode)
				 AND (@doccode='' OR a.doccode=@doccode)
				 AND a.docstatus = CASE 
										WHEN a.formid IN(2401,2418,2419,2420) THEN 200 
										when a.formid in (2424) then 150
										when a.formid IN(4950,4951) THEN 100
									ELSE 100 END
				AND (@formid='' or EXISTS(SELECT 1 FROM getinstr(@FormID) WHERE list=a.formid))
				PRINT '>>>>>>开始导入销售明细数据'
				  --TRUNCATE TABLE SOP_FACT_ItemActivityDetail
				 --DBCC CHECKIDENT  ('SOP_FACT_ItemActivityDetail',RESEED,0)
				INSERT INTO SOP_FACT_ItemActivityDetail(intActivityID, 
				       intDatasource, varReceiptNO,intRowID,
				       varItemCode, varItemGroupCode,varitemgrouprowid,
				       intQuantity, mnyAmount, mnyJoinLimit, mnyDiscountAmount, 
				       mnyRewards, mnyCostAmount, mnyPlanPrice, mnyCtrlPrice, 
				       mnyManageCostAmount, mnyCommitCostAmount, decScore, 
				       mnyGrossProfit, bitIsGifts, varVndCode, decLsScore, decAvgCostAmount,  
				       varCouponsBarCode, mnyCouponsBarAmount, dtmCollateTime, 
				       chvnIsSyned)
				SELECT b.id,
					0 AS intdatasource,a.doccode,
					ROW_NUMBER() OVER(PARTITION BY a.doccode ORDER BY a.docitem) AS intRowID,
					ISNULL(a.matcode,'') AS varitemcode,
					ISNULL(c.matgroup,'') AS varitemgroupcode,
					ISNULL(c.rowid,'') AS varitemgrouprowid,
					ISNULL(a.digit,0) AS intQuantity,
					ISNULL(totalmoney,0) AS mnyAmount,
					0 AS [mnyJoinLimit],
					CASE 
						WHEN b.formid IN(2419,2420) THEN  ISNULL(a.userdigit1,0) 
						else 0 
					end AS mnyDiscountAmount,												--优惠金额
					case
						when b.formid in(2419,2420) then ISNULL(a.userdigit2,0) 
						else 0
					end AS mnyRewards,														--现金奖励
					ISNULL(a.matcost*digit,0) AS mnyCostAmount,								--采购成本金额
					ISNULL(a.price,0) AS mnyPlanPrice,										--计划价
					ISNULL(a.selfprice,0) AS mnyCtrlPrice,									--控制价
					ISNULL(end4*digit,0) AS mnyManageCostAmount,							--经营成本金额
					ISNULL(a.selfprice1*digit,0) AS mnyCommitCostAmount,					--调拔成本金额
					case 
						when formid in(2419,2420) then ISNULL(a.totalmoney-a.digit*a.selfprice1,0)
						ELSE 0
					end AS decScore,														--积分
					ISNULL(totalmoney-a.digit*a.matcost,0) AS mnyGrossProfit,				--毛利
					ISNULL(gift,0) AS bitIsGifts,											--是否礼品
					ISNULL(a.vndcode,'') AS varvndcode,
					0 AS decLsScore,
					ISNULL(a.matcost,0) AS decAvgCostAmount,
					ISNULL(a.couponsbarcode,'') AS varCouponsBarCode,
					ISNULL(a.deductAmout,0) AS mnyCouponsBarAmount,
					GETDATE() AS dtmCollateTime,0 AS chvnIsSyned
				FROM   ierptest..spickorderitem a,@table b,ierptest..imatgeneral 
				       d,ierptest..imatgroup c
				WHERE  a.doccode = b.doccode
				       AND a.matcode = d.matcode
				       AND d.matgroup = c.matgroup
				PRINT '>>>>>>导入大表数据'
				INSERT SOP_FACT_ItemInvoicing( intDatasource, varReceiptNO, dtmDate, 
				       intFormID, intUserFormID, varOrderActivity, 
				       varActivityTypeCode, varReceiptType, intYear, intPeriod, 
				       chvCustomerCode, chvCustomerTel, chvSeriesNumber, 
				       chvAreaCode, chvAreaRowID, chvDepartmentType, 
				       chvDepartmentCode, chvDepartmentRowID, chvStockCode, 
				       chvEmployeeCode, intClassID1, intClassID2, 
				       chvnCustomerAddress, chvnCustomerBank, 
				       chvnBusinessAddress, chvnBusinessBank, intAccountID, 
				       chvnTerm, dtmReceiptDate, chvnIsInvoice, chvnInvoiceType, 
				       chvnInvoiceNumber, chvnCurrency, decRate, chvnContractNo, 
				       varOperatorCode, dtmOperatorTime, varModifyUserCode, 
				       dtmModifyTime, varPostUserCode, dtmPostTime, 
				       varAuditingUserCode, dtmAuditingUserTime, intReturnCause, 
				       varCheckerUserCode, varStockManager, varAccountant, 
				       varVoucher, varVoucherCode, chvnNote, varIsVoid, 
				       varSourceActivity, varInvoiceClose, chvnIsCash, 
				       varUseType, varOrganization, chvnPrepare1, chvnPrepare2, 
				       varSameGroup, intStatus, chvnErrorMsg, intDirection, 
				       varReservedCode, varIsReview, varReviewUserCode, 
				       dtmReviewTime, intRefrefFormid, varRefrefCode, intRowID, 
				       varPackageCode, varItemCode, varItemGroupCode, 
				       varItemGroupRowID, varBomCode, chvnUnit, varPositionCode, 
				       chvnUnitIDAux, intQuantity, intQuantityAux, decCurrPrice, 
				       chvnFactor, mnyCurrPriceTax, decDiscountRate, 
				       mnyCurrAmount, mnyAmount, mnyJoinLimit, mnyCtrlAmount, 
				       mnyDiscountAmount, decTax, mnyCurrTaxAmount, mnyTaxAmount, 
				       mnyCurrNewPrice, mnyRewards, mnyCostAmount, mnyPlanPrice, 
				       mnyCtrlPrice, mnyManageCostAmount, mnyCommitCostAmount, 
				       decScore, mnyGrossProfit, bitIsGifts, varVndCode, 
				       decLsScore, decCostDiff, decSaleTax, 
				       dblSettlementQuantity, intCurrSettlementAmount, 
				       intPaymentQuantity, mnyCurrPaymentAmount, 
				       chvnCloseInvoice, intInvoiceQuantity, 
				       mnyCurrInvoiceAmount, intPositionQuantity, chvnCustomID0, 
				       chvnCustomID1, chvnCustomID2, chvnCustomID3, 
				       chvnCustomID4, chvnCustomID5, chvnCostOrder, 
				       decAvgCostAmount, chvnReserve1, chvnCode, intReserve1, 
				       intReserve2, dtmDateReserve, varRejectNotifyDetailCode, 
				       varCouponsBarCode, mnyCouponsBarAmount, dtmCollateTime, 
				       chvnIsSyned)
				
				SELECT   a.intDatasource, a.varReceiptNO, dtmDate, 
				       intFormID, intUserFormID, varOrderActivity, 
				       varActivityTypeCode, varReceiptType, intYear, intPeriod, 
				       chvCustomerCode, chvCustomerTel, chvSeriesNumber, 
				       chvAreaCode, chvAreaRowID, chvDepartmentType, 
				       chvDepartmentCode, chvDepartmentRowID, chvStockCode, 
				       chvEmployeeCode, intClassID1, intClassID2, 
				       chvnCustomerAddress, chvnCustomerBank, 
				       chvnBusinessAddress, chvnBusinessBank, intAccountID, 
				       chvnTerm, dtmReceiptDate, chvnIsInvoice, chvnInvoiceType, 
				       chvnInvoiceNumber, chvnCurrency, decRate, chvnContractNo, 
				       varOperatorCode, dtmOperatorTime, varModifyUserCode, 
				       dtmModifyTime, varPostUserCode, dtmPostTime, 
				       varAuditingUserCode, dtmAuditingUserTime, intReturnCause, 
				       varCheckerUserCode, varStockManager, varAccountant, 
				       varVoucher, varVoucherCode, chvnNote, varIsVoid, 
				       varSourceActivity, varInvoiceClose, chvnIsCash, 
				       varUseType, varOrganization, chvnPrepare1, chvnPrepare2, 
				       varSameGroup, intStatus, chvnErrorMsg, intDirection, 
				       varReservedCode, varIsReview, varReviewUserCode, 
				       dtmReviewTime, intRefrefFormid, varRefrefCode, intRowID, 
				       varPackageCode, varItemCode, varItemGroupCode, 
				       varItemGroupRowID, varBomCode, chvnUnit, varPositionCode, 
				       chvnUnitIDAux, intQuantity, intQuantityAux, decCurrPrice, 
				       chvnFactor, mnyCurrPriceTax, decDiscountRate, 
				       mnyCurrAmount, mnyAmount, mnyJoinLimit, mnyCtrlAmount, 
				       mnyDiscountAmount, decTax, mnyCurrTaxAmount, mnyTaxAmount, 
				       mnyCurrNewPrice, mnyRewards, mnyCostAmount, mnyPlanPrice, 
				       mnyCtrlPrice, mnyManageCostAmount, mnyCommitCostAmount, 
				       decScore, mnyGrossProfit, bitIsGifts, varVndCode, 
				       decLsScore, decCostDiff, decSaleTax, 
				       dblSettlementQuantity, intCurrSettlementAmount, 
				       intPaymentQuantity, mnyCurrPaymentAmount, 
				       chvnCloseInvoice, intInvoiceQuantity, 
				       mnyCurrInvoiceAmount, intPositionQuantity, chvnCustomID0, 
				       chvnCustomID1, chvnCustomID2, chvnCustomID3, 
				       chvnCustomID4, chvnCustomID5, chvnCostOrder, 
				       decAvgCostAmount, chvnReserve1, chvnCode, intReserve1, 
				       intReserve2, dtmDateReserve, varRejectNotifyDetailCode, 
				       varCouponsBarCode, mnyCouponsBarAmount, dtmCollateTime, 
				       chvnIsSyned
				FROM SOP_FACT_ItemActivity a,SOP_FACT_ItemActivityDetail b,@table c
				WHERE a.intActivityID=b.intActivityID AND a.intDataSource=b.intDatasource
				AND a.intActivityID=c.id
				SELECT @RowCount=@@ROWCOUNT
				DELETE @table
				INSERT INTO _sysImportLog(DataSource,[Event],UserName,parameters,[RowCount],[Status]) VALUES(@Datasource,'导入销售数据','system',
				'beginday:'+convert(varchar(20),@beginday)+',EndDay:'+convert(varchar(20),@endday)+',SDORGID:'+@sdorgid+',stcode:'+@stcode+',Areaid:'+@areaid,@RowCount,1)
			END
--------------------------------------------------------------库存数据------------------------------------------------------------------------------------------
		IF @Datasource LIKE '%ItemActivity' OR @Datasource='' OR EXISTS(SELECT 1 FROM getinstr(@FormID) WHERE list IN(1507,1509,1504,1501,1520)) 
			BEGIN
				DELETE @table
				INSERT INTO SOP_FACT_ItemActivity(dtmDate, intFormID, 
				       intUserFormID,varOrderActivity, varActivityTypeCode, varReceiptType, 
				       intYear, intPeriod, varReceiptNO, chvCustomerCode, 
				       chvCustomerTel, chvAreaCode, 
				       chvAreaRowID, chvDepartmentType, chvDepartmentCode, 
				       chvDepartmentRowID, chvStockCode, chvEmployeeCode, 
						varOperatorCode, dtmOperatorTime, 
				       varModifyUserCode, dtmModifyTime, varPostUserCode, 
				       dtmPostTime, varAuditingUserCode, dtmAuditingUserTime, 
				       intReturnCause, chvnNote,intDirection, 
				        mnyCashAmount, mnySlotCardAmount, 
				       mnyInstallmentAmount, chvnStoreAmount, varReservedCode, 
				       intRefrefFormid, varRefrefCode,intdatasource)
				OUTPUT INSERTED.intActivityID,INSERTED.varReceiptNO,INSERTED.intformid INTO @table
				SELECT  a.docdate AS dtmdate, a.formid AS intFormID, 
					isnull(a.refformid,0) AS intUserFormID ,isnull(a.refcode,'') AS varOrderActivity,
					isnull(a.doctype,'') as varActivityTypeCode,ISNULL(a.doctype,'') AS  varReceiptType, 
					year(a.docdate) as intYear,MONTH(a.docdate) AS  intPeriod,a.doccode AS  varReceiptNO,
					case
						when a.formid in(1507) then ISNULL(a.cltcode,'')
						WHEN a.formid IN(1509,1520) THEN ISNULL(a.vndcode,'')
						ELSE ''
					end AS  chvCustomerCode,														--供应商及客户
					'' as chvCustomerTel, isnull(b.areaid,'') AS chvAreaCode,
					isnull(b.rowid,'') AS chvAreaRowID,isnull(c.dpttype,'') AS chvDepartmentType,isnull(c.sdorgid,'') AS chvDepartmentCode,
					isnull(c.rowid,'') AS chvDepartmentRowID,isnull(a.stcode,'') AS chvStockCode,'' AS chvEmployeeCode,
					isnull(a.entername,''),isnull(a.enterdate,getdate()),isnull(a.modifyname,''),isnull(a.modifydate,GETDATE()),isnull(a.postname,''),
					isnull(a.postdate,GETDATE()) AS dtmposttime ,
					CASE WHEN a.formid IN(1507) THEN ''
						ELSE ''
					end as varAuditingUserCode,
					CASE 
						WHEN a.formid IN(1507) THEN GETDATE()
						ELSE GETDATE()
					END AS  dtmAuditingUserTime,
					0 as intReturnCause, isnull(a.HDMemo,'') as chvnNote,
					case 
						when a.formid in(1507,1509,1520) then -1						--调拔入库/采购入库,其他入库
						WHEN a.formid IN(1504,1501) THEN 1								--采购退货,其他出库
						ELSE 0
					end as intDirection,												--方向
					case 
						when a.formid in(1507,1509,1504,1520,1501) then 0 
						ELSE 0
					end	as mnyCashAmount,												--现金
					CASE  
						when a.formid in(1507,1509,1504,1520,1501) then 0 
						else 0
					end as mnySlotCardAmount, 
					case 
						when a.formid in(1507,1509,1504,1520,1501) then 0
						else 0
					end as mnyInstallmentAmount,
					case 
						when a.formid in(1507,1509,1504,1520,1501) then 0
						else 0
					end as chvnStoreAmount, 
					case 
						when a.formid in(1507,1509,1504,1520,1501) then ''
						else ''
					end as varReservedCode, 
					case 
						when a.formid in(1507,1509,1504,1520,1501) then ''
						else ''
					end as intRefrefFormid,
					case 
						when a.formid in(1507,1509,1504,1520,1501) then ''
						else ''
					end as varRefrefCode,0 as intdatasource
				FROM ierptest..imatdoc_h a,ierptest..garea b,ierptest..osdorg c,ierptest..ostorage d
				WHERE a.formid IN(1507,1509,1504,1501,1520)
					AND a.stcode=d.stcode
					AND d.sdorgid=c.sdorgid
					AND d.areaid=b.areaid
					AND (@beginDay='' OR a.docdate >=@beginDay)
					AND (@endday='' OR a.docdate<=@endday)
					AND (@SDORGID='' OR c.sdorgid=@SDORGID)
					AND (@Stcode='' OR d.stcode=@Stcode)
					AND (@doccode='' OR a.doccode=@doccode)
				PRINT '>>>>>>开始导入库存明细数据'
				  --TRUNCATE TABLE SOP_FACT_ItemActivityDetail
				 --DBCC CHECKIDENT  ('SOP_FACT_ItemActivityDetail',RESEED,0)
				INSERT INTO SOP_FACT_ItemActivityDetail(intActivityID, 
				       intDatasource, varReceiptNO,intRowID,
				       varItemCode, varItemGroupCode,varitemgrouprowid,
				       intQuantity, mnyAmount, mnyDiscountAmount, 
				       mnyRewards, mnyCostAmount, mnyPlanPrice, mnyCtrlPrice, 
				       mnyManageCostAmount, mnyCommitCostAmount, decScore, 
				       mnyGrossProfit, bitIsGifts, decLsScore, decAvgCostAmount,  
				       varCouponsBarCode, mnyCouponsBarAmount, dtmCollateTime, 
				       chvnIsSyned)
				SELECT b.id,
					0 AS intdatasource,a.doccode,
					ROW_NUMBER() OVER(PARTITION BY a.doccode ORDER BY a.docitem) AS intRowID,
					ISNULL(a.matcode,'') AS varitemcode,
					ISNULL(c.matgroup,'') AS varitemgroupcode,
					ISNULL(c.rowid,'') AS varitemgrouprowid,
					ISNULL(a.digit,0) AS intQuantity,
					ISNULL(totalmoney,0) AS mnyAmount,
					0 AS mnyDiscountAmount,							--优惠金额
					case
						when b.formid in(1507,1509,1504,1501,1520) then 0
						else 0
					end AS mnyRewards,														--现金奖励
					ISNULL(a.matcost*digit,0) AS mnyCostAmount,								--成本金额
					ISNULL(a.price,0) AS mnyPlanPrice,										--计划价
					0 AS mnyCtrlPrice,														--控制价
					ISNULL(a.OperatingCost*digit,0) AS mnyManageCostAmount,					--经营成本金额
					0 AS mnyCommitCostAmount,												--调拨成本金额
					case 
						when formid in(1507,1509,1504,1501,1520) then 0
						ELSE 0
					end AS decScore,														--积分
					ISNULL(totalmoney-a.digit*a.matcost,0) AS mnyGrossProfit,				--毛利	
					0 AS bitIsGifts,														--是否礼品
					0 AS decLsScore,														--政策分析积分
					ISNULL(a.matcost,0) AS decAvgCostAmount,								--成本
					'' AS varCouponsBarCode,												--优惠券序号
					0 AS mnyCouponsBarAmount,												--抵扣金额
					GETDATE() AS dtmCollateTime,0 AS chvnIsSyned
				FROM   ierptest..imatdoc_d a,@table b,ierptest..imatgeneral 
				       d,ierptest..imatgroup c
				WHERE  a.doccode = b.doccode
				       AND a.matcode = d.matcode
				       AND d.matgroup = c.matgroup
				PRINT '>>>>>>导入大表数据'
				 --TRUNCATE TABLE SOP_FACT_ItemInvoicing
				 --DBCC CHECKIDENT  ('SOP_FACT_ItemInvoicing',RESEED,0)				
				INSERT SOP_FACT_ItemInvoicing( intDatasource, varReceiptNO, dtmDate, 
				       intFormID, intUserFormID, varOrderActivity, 
				       varActivityTypeCode, varReceiptType, intYear, intPeriod, 
				       chvCustomerCode, chvCustomerTel, chvSeriesNumber, 
				       chvAreaCode, chvAreaRowID, chvDepartmentType, 
				       chvDepartmentCode, chvDepartmentRowID, chvStockCode, 
				       chvEmployeeCode, intClassID1, intClassID2, 
				       chvnCustomerAddress, chvnCustomerBank, 
				       chvnBusinessAddress, chvnBusinessBank, intAccountID, 
				       chvnTerm, dtmReceiptDate, chvnIsInvoice, chvnInvoiceType, 
				       chvnInvoiceNumber, chvnCurrency, decRate, chvnContractNo, 
				       varOperatorCode, dtmOperatorTime, varModifyUserCode, 
				       dtmModifyTime, varPostUserCode, dtmPostTime, 
				       varAuditingUserCode, dtmAuditingUserTime, intReturnCause, 
				       varCheckerUserCode, varStockManager, varAccountant, 
				       varVoucher, varVoucherCode, chvnNote, varIsVoid, 
				       varSourceActivity, varInvoiceClose, chvnIsCash, 
				       varUseType, varOrganization, chvnPrepare1, chvnPrepare2, 
				       varSameGroup, intStatus, chvnErrorMsg, intDirection, 
				       varReservedCode, varIsReview, varReviewUserCode, 
				       dtmReviewTime, intRefrefFormid, varRefrefCode, intRowID, 
				       varPackageCode, varItemCode, varItemGroupCode, 
				       varItemGroupRowID, varBomCode, chvnUnit, varPositionCode, 
				       chvnUnitIDAux, intQuantity, intQuantityAux, decCurrPrice, 
				       chvnFactor, mnyCurrPriceTax, decDiscountRate, 
				       mnyCurrAmount, mnyAmount, mnyJoinLimit, mnyCtrlAmount, 
				       mnyDiscountAmount, decTax, mnyCurrTaxAmount, mnyTaxAmount, 
				       mnyCurrNewPrice, mnyRewards, mnyCostAmount, mnyPlanPrice, 
				       mnyCtrlPrice, mnyManageCostAmount, mnyCommitCostAmount, 
				       decScore, mnyGrossProfit, bitIsGifts, varVndCode, 
				       decLsScore, decCostDiff, decSaleTax, 
				       dblSettlementQuantity, intCurrSettlementAmount, 
				       intPaymentQuantity, mnyCurrPaymentAmount, 
				       chvnCloseInvoice, intInvoiceQuantity, 
				       mnyCurrInvoiceAmount, intPositionQuantity, chvnCustomID0, 
				       chvnCustomID1, chvnCustomID2, chvnCustomID3, 
				       chvnCustomID4, chvnCustomID5, chvnCostOrder, 
				       decAvgCostAmount, chvnReserve1, chvnCode, intReserve1, 
				       intReserve2, dtmDateReserve, varRejectNotifyDetailCode, 
				       varCouponsBarCode, mnyCouponsBarAmount, dtmCollateTime, 
				       chvnIsSyned)
				
				SELECT   a.intDatasource, a.varReceiptNO, dtmDate, 
				       intFormID, intUserFormID, varOrderActivity, 
				       varActivityTypeCode, varReceiptType, intYear, intPeriod, 
				       chvCustomerCode, chvCustomerTel, chvSeriesNumber, 
				       chvAreaCode, chvAreaRowID, chvDepartmentType, 
				       chvDepartmentCode, chvDepartmentRowID, chvStockCode, 
				       chvEmployeeCode, intClassID1, intClassID2, 
				       chvnCustomerAddress, chvnCustomerBank, 
				       chvnBusinessAddress, chvnBusinessBank, intAccountID, 
				       chvnTerm, dtmReceiptDate, chvnIsInvoice, chvnInvoiceType, 
				       chvnInvoiceNumber, chvnCurrency, decRate, chvnContractNo, 
				       varOperatorCode, dtmOperatorTime, varModifyUserCode, 
				       dtmModifyTime, varPostUserCode, dtmPostTime, 
				       varAuditingUserCode, dtmAuditingUserTime, intReturnCause, 
				       varCheckerUserCode, varStockManager, varAccountant, 
				       varVoucher, varVoucherCode, chvnNote, varIsVoid, 
				       varSourceActivity, varInvoiceClose, chvnIsCash, 
				       varUseType, varOrganization, chvnPrepare1, chvnPrepare2, 
				       varSameGroup, intStatus, chvnErrorMsg, intDirection, 
				       varReservedCode, varIsReview, varReviewUserCode, 
				       dtmReviewTime, intRefrefFormid, varRefrefCode, intRowID, 
				       varPackageCode, varItemCode, varItemGroupCode, 
				       varItemGroupRowID, varBomCode, chvnUnit, varPositionCode, 
				       chvnUnitIDAux, intQuantity, intQuantityAux, decCurrPrice, 
				       chvnFactor, mnyCurrPriceTax, decDiscountRate, 
				       mnyCurrAmount, mnyAmount, mnyJoinLimit, mnyCtrlAmount, 
				       mnyDiscountAmount, decTax, mnyCurrTaxAmount, mnyTaxAmount, 
				       mnyCurrNewPrice, mnyRewards, mnyCostAmount, mnyPlanPrice, 
				       mnyCtrlPrice, mnyManageCostAmount, mnyCommitCostAmount, 
				       decScore, mnyGrossProfit, bitIsGifts, varVndCode, 
				       decLsScore, decCostDiff, decSaleTax, 
				       dblSettlementQuantity, intCurrSettlementAmount, 
				       intPaymentQuantity, mnyCurrPaymentAmount, 
				       chvnCloseInvoice, intInvoiceQuantity, 
				       mnyCurrInvoiceAmount, intPositionQuantity, chvnCustomID0, 
				       chvnCustomID1, chvnCustomID2, chvnCustomID3, 
				       chvnCustomID4, chvnCustomID5, chvnCostOrder, 
				       decAvgCostAmount, chvnReserve1, chvnCode, intReserve1, 
				       intReserve2, dtmDateReserve, varRejectNotifyDetailCode, 
				       varCouponsBarCode, mnyCouponsBarAmount, dtmCollateTime, 
				       chvnIsSyned
				FROM SOP_FACT_ItemActivity a,SOP_FACT_ItemActivityDetail b,@table c
				WHERE a.intActivityID=b.intActivityID AND a.intDataSource=b.intDatasource
				AND a.intActivityID=c.id
				SELECT @RowCount=@@ROWCOUNT
				
				INSERT INTO _sysImportLog(DataSource,[Event],UserName,parameters,[RowCount],[Status]) VALUES(@Datasource,'导入销售数据','system',
				'beginday:'+convert(varchar(20),@beginday)+',EndDay:'+convert(varchar(20),@endday)+',SDORGID:'+@sdorgid+',stcode:'+@stcode+',Areaid:'+@areaid,@RowCount,1)	
			END
-----------------------------------------------------------------------------库存汇总数据刷新-----------------------------------------------------------------------------
		IF @Datasource LIKE '%ItemActivity' OR @Datasource='' OR EXISTS(SELECT 1 FROM getinstr(@FormID) WHERE list IN(2401,2418,2419,2420,2424,1507,1501,1520,4950,4951))
			BEGIN
				--删除货位发生额(货位商品出入库汇总)
				DELETE SOP_FACT_PositionDaily
				WHERE dtmDate BETWEEN @beginDay AND @endday
				AND (@Stcode='' OR  varPositionCode=@Stcode)
				AND (@SDORGID='' OR vardepartmentCode=@SDORGID)
				--插入新数据
				INSERT INTO SOP_FACT_PositionDaily( dtmDate, varItemCode, varPositionCode, 
				       vardepartmentCode,decPurchaseQuantity, mnyPurchaseAmount, 
				       mnyPurchaseExpense, decAdjInQuantity, mnyAdjInAmount, 
				       decInQuantity, mnyInAmount, mnyManageCostAmount, 
				       mnyCommitCostAmount, decCheckUpQuantity, mnyCheckUpAmount, 
				       mnyAdjPriceAdd, decSaleQuantity, mnySaleCtrlAmount, 
				       mnySaleCost, mnySaleCostDiff, mnySaleCostSaleTax, 
				       decLendQuantity, mnyLendAmount, mnyLendCost, 
				       mnyLendCostDiff, mnyLendCostSaleTax, decLendSaleQuantity, 
				       mnyLendSaleAmount, mnyLendSaleCost, decStageQuantity, 
				       mnyStageAmount, mnyStageCost, mnyStageCostDiff, 
				       mnyStageCostSaleTax, decStageSaleQuantity, 
				       mnyStageSaleAmount, mnyStageSaleCost, decAdjOutQuantity, 
				       mnyAdjOutAmount, decOutQuantity, mnyOutAmount, 
				       decCheckDownQuantity, mnyCheckDownAmount, mnyAdjPriceDec, 
				       mnyCostAdj, mnyCostCostAdj)
				SELECT a.dtmDate,a.varItemCode,a.varPostUserCode,a.vardepartmentcode,
				SUM(CASE WHEN a.intFormID in(1509,1504)  THEN a.intDirection* a.intQuantity ELSE 0 END) AS  decPurchaseQuantity,
				SUM(CASE WHEN a.intFormID in(1509,1504)  THEN a.intDirection* a.mnyAmount ELSE 0 END) AS  mnyAmount,
				SUM(CASE WHEN a.intFormID in(1509,1504)  THEN a.intDirection* a.mnyAmount ELSE 0 END) AS  mnyPurchaseExpense,
				SUM(CASE WHEN a.intFormID in(1507)  THEN a.intDirection* a.intQuantity ELSE 0 END) AS  decAdjInQuantity,
				SUM(CASE WHEN a.intFormID in(1507)  THEN a.intDirection* a.mnyAmount ELSE 0 END) AS  mnyAdjInAmount,
				SUM(CASE WHEN a.intFormID in(1520)  THEN a.intDirection* a.intQuantity ELSE 0 END) AS  decAdjInQuantity,
				SUM(CASE WHEN a.intFormID in(1520)  THEN a.intDirection* a.mnyAmount ELSE 0 END) AS  mnyAdjInAmount,
				FROM SOP_FACT_ItemInvoicing a
				WHERE a.dtmDate BETWEEN @beginDay AND @endday
				AND (@Stcode='' OR a.varPositionCode=@Stcode)
				AND (@SDORGID='' OR a.chvDepartmentCode=@SDORGID)
				GROUP BY a.dtmDate,a.varItemCode,a.varPostUserCode,a.vardepartmentcode, 
			END
-----------------------------------------------------------------------------运营商业务数据-------------------------------------------------------------------------------
		IF @Datasource LIKE '%NUMBERALLOCATION_LOG' OR @Datasource=''
			BEGIN
				--删除数据
				PRINT '>>>>>>删除运营商业务数据'
				DELETE SOP_FACT_NumberAllocation_Log --OUTPUT deleted.id,DELETED.strdoccode INTO @table
				FROM SOP_FACT_NumberAllocation_Log a
				WHERE  (@beginDay='' OR a.dtmdocdate >=@beginDay)
				 AND (@endday='' OR a.dtmdocdate<=@endday)
				 AND (@SDORGID='' OR a.strsdorgid=@SDORGID)
				 AND (@doccode='' OR a.strdoccode=@doccode)
				 AND (@stcode='' OR a.strstCode=@Stcode)
				 AND (@FormID='' OR EXISTS(SELECT 1 FROM getinstr(@FormID) WHERE list=a.intformid))
				 PRINT  '>>>>>>共计删除'+convert(VARCHAR,@@rowcount)+'行'
				DELETE @table
				PRINT '>>>>>>导入运营商业务数据'
				--导入开户和套包数据
				if (@FormID='' OR EXISTS(SELECT 1 FROM getinstr(@FormID) WHERE list IN(9102,9146)))
					begin
						INSERT INTO SOP_FACT_NumberAllocation_Log(strDoccode, 
							   dtmDocDate, strperiodid, intFormID, strDocType, 
							   strCompanyID, strAreaID, strAreaROWID, strdptType, strSdorgID, 
							   strSDORGROWID, strstCode, strSDGROUP, strCustomerCode, 
							   strSeriesNumber, intIntype, strPackageID, strNettype, 
							   strSIMCode, bitPreAllocation, intComboCode, 
							   strComboFeeType, dblPrice, dblPhoneRate, dblServiceFEE, 
							   dblOtherFEE, dblCardFEE, dblTotalMoney, 
							   dblCreditAmount, dblPackagePrice, strOperSdgroup, 
							   dtmOperDate, strMatCode, strseriescode, 
							   bitallocated, bitold, bitReturnd, strReservedDoccode, 
							   dtmEnterDate, strEnterName, dtmPostDate, strPostName)
						OUTPUT inserted.id,INSERTED.strdoccode,INSERTED.intformid INTO @table
						SELECT a.doccode,a.docdate,a.periodid,a.formid,a.doctype,a.companyid,b.areaid,b.rowid,c.dpttype,a.sdorgid,
						c.rowid AS sdorgrowid,a.stcode,a.sdgroup,a.cltcode AS customercode,
						a.seriesnumber,CASE   ISNULL(a.intype,'正常入库') 
										when '正常入库' then 0 
										WHEN '池外入库' THEN 1 
										WHEN '老客户号码' THEN 2 
										ELSE 0 
									   END as intIntype,
						ISNULL(a.packageid,'') AS strPackageID,ISNULL(nettype,'3G') AS nettype,'' AS SIMCODE,ISNULL(preallocation,0) AS preallocation,
						d.combocode,ISNULL(a.combofeetype,''),ISNULL(a.price,0) AS price,ISNULL(a.phonerate,0) AS phonerate, isnull(a.ServiceFEE,0), 
							   isnull(OtherFEE,0), isnull(CardFEE,0), isnull(a.UserDigit4,0) AS totalmoney, 
							   isnull(totalmoney2,0) AS CreditAmount, isnull(PackagePrice,0), isnull(a.Audits,'') AS OperSdgroup, 
							   isnull(a.Auditingdate,GETDATE()) AS OperDate, ''  as strmatcode , '' as strseriescode , 
							   case isnull(a.old,0) when 0 then 1 else 1 end as allocated , isnull(old,0) AS bitold, isnull(bitReturnd,0) AS bitReturnd, 
							   isnull(ReservedDoccode,'') AS strReservedDoccode,isnull(a.EnterDate,GETDATE()) AS EnterDate, 
							   isnull(a.EnterName,'') AS EnterName, isnull(PostDate,GETDATE()) AS PostDate, isnull(PostName,'') AS PostName
						FROM ierptest..unicom_orders a,ierptest..garea b ,ierptest..osdorg c,ierptest..combo_H d,ierptest..ostorage e
						WHERE a.sdorgid=c.sdorgid
						AND a.stcode=e.stcode
						AND b.areaid=e.areaid
						AND a.comboname=d.comboname
						AND (@beginDay='' OR a.docdate >=@beginDay)
						AND (@endday='' OR a.docdate<=@endday)
						AND (@SDORGID='' OR c.sdorgid=@SDORGID)
						AND (@Stcode='' OR e.stcode=@Stcode)
						AND (@doccode='' OR a.doccode=@doccode)
						AND (@FormID='' OR EXISTS(SELECT 1 FROM getinstr(@FormID) WHERE list=a.formid))
						AND docstatus<>0
						SELECT @RowCount=@@ROWCOUNT
						--取出手机串号的SIM卡号
						;WITH cte AS(
							SELECT doccode,max(case when b.matcode like '1.%' then b.matcode ELSE '' END) AS matcode,
							max(CASE WHEN b.matcode LIKE '1.%' THEN seriescode ELSE '' END) AS seriescode,
							max(CASE WHEN b.matcode LIKE '14.%' OR b.matcode LIKE '2.%' THEN seriescode ELSE '' END) AS SIMCODE,
							max(CASE WHEN b.matcode LIKE '1.%' THEN a.isSingleSale ELSE 0 END) AS isSingleSale
							FROM ierptest..unicom_orderdetails a,ierptest..imatgeneral b
							WHERE a.matcode=b.matcode
							AND b.matflag=1
							 AND a.doccode=@doccode
							GROUP BY a.doccode)
						--更新明细内容
						UPDATE  SOP_FACT_NumberAllocation_Log   
							SET strmatcode=c.matcode,strseriescode=c.seriescode,strsimcode=c.simcode, bitisSingleSale=c.isSingleSale  
							FROM SOP_FACT_NumberAllocation_Log a,@table b,cte c
							WHERE a.strDocCode=b.Doccode 
							AND a.strdoccode=c.doccode
						PRINT '>>>>>>共计导入'+convert(VARCHAR(10),@rowcount)+'行.'
						DELETE @table
					END
				--其他业务受理
				IF @FormID='' OR EXISTS(SELECT 1 FROM dbo.GetInStr(@FormID) WHERE list IN(9153,9159,9158,9167,9160,9165,9180))
					BEGIN
						INSERT INTO SOP_FACT_NumberAllocation_Log( strDoccode, 
						       dtmDocDate, strperiodid, intFormID, strDocType, 
						       strCompanyID, strAreaID, strAreaROWID, strdptType, 
						       strSdorgID, strSDORGROWID, strstCode, strSDGROUP, 
						       strCustomerCode, strSeriesNumber, strNettype, 
						       strmatcode, strSIMCode, dblprice, dblTotalMoney, 
						       strOperSdgroup, dtmOperDate, dtmEnterDate, 
						       strEnterName, dtmPostDate, strPostName)    
						SELECT a.doccode,a.docdate,a.periodid,a.formid,a.doctype,a.companyid,b.areaid,b.rowid,c.dpttype,a.sdorgid,
						c.rowid AS sdorgrowid,a.stcode,a.sdgroup,
						case when formid in(9153,9159) then ISNULL(customercode1,'') else isnull(customercode,'') end AS customercode,a.seriesnumber,
						ISNULL(nettype,'3G') AS nettype,isnull(a.matcode,''),ISNULL(a.simcode1,''),ISNULL(a.price,0), isnull(a.totalmoney,0) AS totalmoney, 
							   isnull(a.Audits,'') AS OperSdgroup, 
							   isnull(a.Auditingdate,GETDATE()) AS OperDate,isnull(a.EnterDate,GETDATE()) AS EnterDate, 
							   isnull(a.EnterName,'') AS EnterName, isnull(PostDate,GETDATE()) AS PostDate, isnull(PostName,'') AS PostName
						FROM ierptest..BusinessAcceptance_H a inner join ierptest..osdorg c ON a.sdorgid=c.sdorgid
						LEFT JOIN ierptest..garea b ON c.areaid=b.areaid
						LEFT JOIN  ierptest..combo_H f ON a.comboname=f.comboname 
						WHERE (formid in(9153,9159,9158,9167,9160,9165,9180 ))
							AND a.DocStatus<>0
							AND (@beginday='' OR docdate>=@beginday)      
							AND (@endday='' OR a.docdate<=@endday)      
							AND (@sdorgid='' OR a.sdorgid=@sdorgid)      
							AND (@areaid='' OR b.areaid=@areaid)      
							AND (@doccode='' OR  a.doccode = @doccode)      
							AND (@formid='' OR EXISTS(SELECT 1 FROM getinstr(@formid) WHERE list=a.formid))
						SELECT @RowCount=ISNULL(@RowCount,0)+@@ROWCOUNT
						PRINT '>>>>>>共计导入'+convert(VARCHAR(10),@rowcount)+'行.'
					END
			END
		IF @Datasource ='' or @Datasource LIKE '%STOCKLEDGERLOG'
			BEGIN
				DELETE @table
				/*INSERT INTO SOP_FACT_ItemActivity(dtmDate, intFormID, 
				       intUserFormID,varOrderActivity, varActivityTypeCode, varReceiptType, 
				       intYear, intPeriod, varReceiptNO, chvCustomerCode, 
				       chvCustomerTel, chvAreaCode, 
				       chvAreaRowID, chvDepartmentType, chvDepartmentCode, 
				       chvDepartmentRowID, chvStockCode, chvEmployeeCode, 
						varOperatorCode, dtmOperatorTime, 
				       varModifyUserCode, dtmModifyTime, varPostUserCode, 
				       dtmPostTime, varAuditingUserCode, dtmAuditingUserTime, 
				       intReturnCause, chvnNote,intDirection, 
				        mnyCashAmount, mnySlotCardAmount, 
				       mnyInstallmentAmount, chvnStoreAmount, varReservedCode, 
				       intRefrefFormid, varRefrefCode,intdatasource)
				 OUTPUT INSERTED.intActivityID,INSERTED.varReceiptNO INTO @table*/
				PRINT '>>>>>>共计导入'+convert(VARCHAR(10),@rowcount)+'行.'
			END
		IF @@ERROR=0
			BEGIN
				
				PRINT '>>>>>>导入数据完成'
				COMMIT
			END
		ELSE
			BEGIN
				INSERT INTO _sysImportLog(DataSource,[Event],UserName,parameters,[RowCount],[Status],Remark) VALUES(@Datasource,'导入销售数据','system',
				'beginday:'+convert(varchar(20),@beginday)+',EndDay:'+convert(varchar(20),@endday)+',SDORGID:'+@sdorgid+',stcode:'+@stcode+',Areaid:'+@areaid,@RowCount,0,ERROR_MESSAGE())	
				PRINT '>>>>>>导入数据失败'
				ROLLBACK
			END
		RETURN @RowCount
	END
	/*
DECLARE @sql VARCHAR(MAX)
SELECT @sql=''
SELECT @sql=@sql+NAME+',' FROM syscolumns s WHERE s.id=OBJECT_ID('SOP_FACT_PositionDaily')
PRINT @sql
NULL
池外入库
老客户号码
正常入库
*/