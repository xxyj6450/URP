BEGIN TRAN

--运营商业务
TRUNCATE TABLE Unicom_OrderDetails
delete Unicom_Orders
TRUNCATE TABLE BusinessAcceptance_H
TRUNCATE TABLE SeriesPool
TRUNCATE TABLE CheckNumberAllocationDoc_LOG
TRUNCATE TABLE NumberAllocation_Log
TRUNCATE TABLE NumberAllocationAudits
DROP FUNCTION fn_getPackage1
drop TABLE policy_d1
TRUNCATE TABLE SeriesNumber_Log
TRUNCATE TABLE SeriesNumberMAP
TRUNCATE TABLE SeriesNumberInfo
TRUNCATE TABLE hdPotentialCustomer
/*TRUNCATE TABLE policy_d
TRUNCATE TABLE policy_h*/
TRUNCATE TABLE log_Unicom_Orders
TRUNCATE TABLE log_sPickorderHD
TRUNCATE TABLE log_Customers_H
TRUNCATE TABLE PackageSelect_HD
TRUNCATE TABLE log_PackageSelect_HD
TRUNCATE TABLE log_BusinessAcceptance_H
TRUNCATE TABLE Seriespool_D
TRUNCATE TABLE log_SeriesPool_H
TRUNCATE TABLE iCoupons
TRUNCATE TABLE log_hdReserveCustomers
TRUNCATE TABLE Coupons_H
TRUNCATE TABLE SeriesPool_H
TRUNCATE TABLE SeriesCode_HD
TRUNCATE TABLE PackageSeriesLog_D
TRUNCATE TABLE hdReserveCustomers
TRUNCATE TABLE PotentialCustomer
TRUNCATE TABLE hdBatchReserveCustomers
TRUNCATE TABLE dtBatchReseredCustomers
TRUNCATE TABLE log_SeriesCode_HD
TRUNCATE TABLE log_commision_H
TRUNCATE TABLE log_policy_h
TRUNCATE TABLE log_Coupons_H
TRUNCATE TABLE PackageSeriesLog_H
TRUNCATE TABLE ServiceConfiguration
TRUNCATE TABLE ServiceConfiguration_DT
TRUNCATE TABLE ServiceConfiguration_HD
drop function dbo.Base64Decode
drop function dbo.Base64Encode
drop function  dbo.HashAlgorithmd
drop function bo.SymmetricDecrypt
drop function dbo.SymmetricEncrypt
DROP function  dbo.SymmetricDecrypt
DROP PROC sp_writecard
DROP FUNCTION [getSIMInfo]
DROP FUNCTION dbo.ExecuteScalar
DROP FUNCTION dbo.ExecuteTable
 
TRUNCATE TABLE log_osdorg
--进销存
TRUNCATE TABLE spickorderitem
TRUNCATE TABLE spickorderhd
TRUNCATE TABLE imatdoc_d
delete   imatdoc_h
 
DELETE FROM iSeries
TRUNCATE TABLE isaleledgerlog
TRUNCATE TABLE iserieslog
TRUNCATE TABLE iseriesloghd
TRUNCATE TABLE iserieslogitem
TRUNCATE TABLE istockledgerlog
TRUNCATE TABLE SaleLog
TRUNCATE TABLE checkquenchseries
TRUNCATE TABLE RJimatstoragelog
TRUNCATE TABLE iSeries
TRUNCATE TABLE iMatLedger
TRUNCATE TABLE sMatSDOrgPrice
TRUNCATE TABLE sMatSDOrgPricelog
TRUNCATE TABLE sMatSDPriclog
TRUNCATE TABLE imatStockLog
TRUNCATE TABLE iMatStorage
TRUNCATE TABLE iMatStorageLog
TRUNCATE TABLE imatstbalance
TRUNCATE TABLE imatstbalance2
TRUNCATE TABLE iMatLedger
TRUNCATE TABLE iSeriesPriceCalcu
TRUNCATE TABLE RJsalelog
TRUNCATE TABLE checkquenchamount
TRUNCATE TABLE fh_deliverydtl
TRUNCATE TABLE ord_shopbestgoodsdtl
TRUNCATE TABLE RJmovelog
TRUNCATE TABLE commission
TRUNCATE TABLE log_imatdoc_h
TRUNCATE TABLE log_iseriesloghd
TRUNCATE TABLE log_ord_shopbestgoodsdoc
TRUNCATE TABLE Coupons_D
TRUNCATE TABLE ord_bestgoodsinit
TRUNCATE TABLE log_fh_deliverydoc
TRUNCATE TABLE fh_stcodedtl
TRUNCATE TABLE checkquenchcard
TRUNCATE TABLE imatbalance
TRUNCATE TABLE rj_baltag
TRUNCATE TABLE Loss_price
TRUNCATE TABLE saleed
TRUNCATE TABLE ord_shopbestgoodsdoc
TRUNCATE TABLE log_farcashindoc
TRUNCATE TABLE log_ppohd
TRUNCATE TABLE ppohd
TRUNCATE TABLE ppoitem
TRUNCATE TABLE checkseriescodeitem
TRUNCATE TABLE log_fh_stcodedoc
TRUNCATE TABLE Fendperiodbusitem
TRUNCATE TABLE iMatPlant
TRUNCATE TABLE AdjustPrice_DT
TRUNCATE TABLE CommonDoc_HD
TRUNCATE TABLE Newcost
--往来,总帐,资金
TRUNCATE TABLE fsubledgerlog
TRUNCATE TABLE FsubBalance
TRUNCATE TABLE Fsubinstbalance
TRUNCATE TABLE fARbalance
TRUNCATE TABLE Fapbalance
TRUNCATE TABLE Fapinstbalance
TRUNCATE TABLE imatstbalance
TRUNCATE TABLE FchargedocD
TRUNCATE TABLE FchargedocM
TRUNCATE TABLE log_Fchargedocm
TRUNCATE TABLE fainstaccount
TRUNCATE TABLE Fcashdoc
TRUNCATE TABLE fastbalance
 TRUNCATE TABLE onstranmat
 TRUNCATE TABLE FARcashindoc
 TRUNCATE TABLE Unionlog
TRUNCATE TABLE DBYSperbalance
TRUNCATE TABLE DBYFperbalance
TRUNCATE TABLE sARSalesBalance
TRUNCATE TABLE sARSalesinstBalance
--售后
TRUNCATE TABLE  nceptpoint
TRUNCATE TABLE log_Service_hd
TRUNCATE TABLE Service_list
TRUNCATE TABLE Mobilerepairlog
TRUNCATE TABLE Service_hd
TRUNCATE TABLE Service_hd_files
TRUNCATE TABLE Service_hd_fileParts
TRUNCATE TABLE Service_hdlink
TRUNCATE TABLE log_Mobilerepairdoc
TRUNCATE TABLE Bowelmaintain
TRUNCATE TABLE Mobilerepairdoc
TRUNCATE TABLE Mobmatgeneral
--资产
/*TRUNCATE TABLE fh_deliverydoc
TRUNCATE TABLE log_Fcashdoc
TRUNCATE TABLE fCapdocPd_d
TRUNCATE TABLE fCapdocPd_h
TRUNCATE TABLE fCapdocPd_hlink
TRUNCATE TABLE fCapdoc_d
TRUNCATE TABLE fCapdoc_h
TRUNCATE TABLE fCapdoc_hlink
TRUNCATE TABLE fCapdoc_h_fileParts
TRUNCATE TABLE fCapdoc_h_files
TRUNCATE TABLE fCapSubdoc
TRUNCATE TABLE fCapSubdocPd
TRUNCATE TABLE fCapVnd
TRUNCATE TABLE Fcashdoc
TRUNCATE TABLE Fcashdocitem
TRUNCATE TABLE Fcashdoclink
TRUNCATE TABLE Fcashdoc_fileParts
TRUNCATE TABLE Fcashdoc_files
TRUNCATE TABLE FCashFlux*/
 
--基础资料
TRUNCATE TABLE oSDGroup
TRUNCATE TABLE osdorggroup
TRUNCATE TABLE oStaff
TRUNCATE TABLE osdgroup_hd
TRUNCATE TABLE osdgroup_hdlink
TRUNCATE TABLE osdgroup_item
TRUNCATE TABLE oStaffLevel
 TRUNCATE TABLE log_osdgroup_hd
TRUNCATE TABLE oPlantPurOrg
TRUNCATE TABLE oPlantShipPnt
TRUNCATE TABLE matModifyHistory
TRUNCATE TABLE matbarcode_d
TRUNCATE TABLE iMatBarCode
TRUNCATE TABLE imatbatchprice
TRUNCATE TABLE imatbatchpricelog
TRUNCATE TABLE log_osdorg
--预算
TRUNCATE TABLE org_monthbudgetItem
--系统表
TRUNCATE TABLE gLoginLog

TRUNCATE TABLE cdosysmail_failures
TRUNCATE TABLE gErrorMessage
 TRUNCATE TABLE gTerminal
TRUNCATE TABLE gDocPostQueue

TRUNCATE TABLE gAutoSendMessage
 
--其他表
TRUNCATE TABLE ord_sporgcommitdoc
TRUNCATE TABLE FglSetbalance
drop TABLE salesbbc
TRUNCATE TABLE fh_stcodedoc
TRUNCATE TABLE fChargeplanitem
TRUNCATE TABLE Tiaojia
TRUNCATE TABLE Tb_Duanxin_BL
TRUNCATE TABLE iSeriesPriceCalculog
TRUNCATE TABLE iMatsalary

 
TRUNCATE TABLE FcheckoutDelail
TRUNCATE TABLE salesbbd
TRUNCATE TABLE  CltMonthlistitem
TRUNCATE TABLE imatstJB
TRUNCATE TABLE shiftpolicydoc
TRUNCATE TABLE SolarData
TRUNCATE TABLE log_ord_deliverydoc
TRUNCATE TABLE log_Commsales_h

DROP TABLE checkquenchseries_bak
DROP TABLE oSDOrg0818
DROP TABLE osdorg1
DROP TABLE oSDOrg20050818
DROP TABLE osdorggroup_20080724
drop TABLE osdorgbak
DROP TABLE TableLog
DROP TABLE Table_1
DROP TABLE table_a
DROP TABLE log_hdBatchReserveCustomers
DROP TABLE tempCHDetail
DROP TABLE gQuantOP_bak
DROP TABLE tempCH
DROP TABLE PackageSelect_HD_fileParts
TRUNCATE TABLE log_PackageSeriesLog_H
TRUNCATE TABLE log_Fendperiodbusihd
DROP TABLE customers_h_1010
DROP TABLE fgldoc_0830
DROP TABLE fsubledgerlog05
DROP TABLE fsubledgerlog_20080830
DROP TABLE iserieslogitem007
DROP TABLE iserieslogitem0070
DROP TABLE iserieslogitem1
DROP TABLE iseriesloghd_files
DROP TABLE iseriesloghd_fileParts
DROP TABLE farbalance0930
drop TABLE imatstorage_0902
drop TABLE MZ_MobileNum
DROP TABLE moiblelist
DROP TABLE saleed_bak
DROP table up_series_arealog
DROP table up_series_arealog
drop TABLE checkquenchseries0819
DROP TABLE gstaffprofilebak
DROP TABLE test0001
DROP TABLE seriespool_20101201
DROP TABLE guserprofile1
DROP TABLE nums
DROP  TABLE dddk
drop TABLE aaba
drop TABLE salesabc
DROP TABLE ddl_log
DROP TABLE tmpOsdorg
DROP TABLE tmpx1
DROP TABLE tmp_imatdoc_d
DROP TABLE tmp_imatdoc_h
DROP TABLE tmp_iSeriesLogHD
DROP TABLE tmp_iSeriesLogItem
DROP TABLE tmp_spickOrderHD
DROP TABLE tmp_spickOrderItem
DROP TABLE oSDGroup_bak
DROP TABLE SDOrg_bak
TRUNCATE TABLE Newpur
DROP TABLE oStorage_bak

SELECT OBJECT_NAME(id),rowcnt  FROM sysindexes WHERE rowcnt>0 ORDER BY rowcnt DESC

 SELECT * FROM PackageSelect_HD
 
 SELECT * FROM ord_shopbestgoodsdoc_files os
 
 SELECT * FROM DBYFbalance
 
 
 TRUNCATE TABLE ord_shopbestgoodsdoc_files
 TRUNCATE TABLE DBYFbalance
 TRUNCATE TABLE commision_H
TRUNCATE TABLE  forcredit
 TRUNCATE TABLE Incmonthstockitem
 TRUNCATE TABLE Cltmonthsellsumitem
TRUNCATE TABLE  log_BusinessAcceptance_H
TRUNCATE TABLE  DM_integralbudgethd
TRUNCATE TABLE  log_Commsales_h
TRUNCATE TABLE  JMD_Qcyue
 TRUNCATE TABLE log_Unicom_PreAcceptance
TRUNCATE TABLE  Cltmonthbudgetitem
 TRUNCATE TABLE ibomdocitem
 TRUNCATE TABLE log_CommonDoc_HD
 TRUNCATE TABLE iSIMInfo_Log
 
 TRUNCATE TABLE iSIMInfo
TRUNCATE TABLE tempts