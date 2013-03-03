
/*
过程名称:sp_ConvertDoc
参数:见声名部分
功能:将一种单据转移成另一种单据
编写:三断笛
时间:2011-07-09
备注:此单据转移过程支持从不同地方的数据源进行转换,并且不影响数据源的正常工作,
而且因为(如果)源数据表可能有大量的数量,如果与之关联进行一些复杂的操作,
也将影响转换效率,所以需要将数据源的数据先转移到本数据库,表名在源表名前加tmp_,转换完毕再予以删除.
这样,不管源数据在哪个服务器,哪个数据库,哪种数据源,只需要将数据插入中间表,就可以转换成需要的单据.
本次只实现调拔入库单与零售单,采购单之间的转换.
*/
alter PROC [dbo].[sp_ConvertDoc]
	@sDoccode VARCHAR(20),				--源单号
	@sFormID INT,						--源功能号
	@dFormID INT,						--新功能号
	@dDocStatus int=0,					--新单据状态
	@dDoccodeBaseDigit INT=10000,		--新单号单据号起始基数,默认值为10000.
	@optionID VARCHAR(20)='',			--选项,备用
	@dDoccode VARCHAR(20)='' OUTPUT		--新生成的单号,输出
AS
	BEGIN
		/*************************************************变量定义区***********************************************************/
		DECLARE @CompanyID VARCHAR(20),@CompanyName VARCHAR(20),@sdORGID VARCHAR(50),@sdorgName varchar(200),@stcode VARCHAR(50),@stname VARCHAR(200),@doccode1 VARCHAR(20)
		DECLARE @stcode2 VARCHAR(20),@stname2 VARCHAR(200),@sdorgID2 VARCHAR(20),@sdorgName2 VARCHAR(200),@CompanyID2 VARCHAR(20),@companyName2 VARCHAR(50)
		DECLARE @vndCode VARCHAR(20),@vndName VARCHAR(200),@purStcode VARCHAR(20),@purStName VARCHAR(200)
		DECLARE @msg VARCHAR(2000)
		/**************************************************数据初始化区******************************************************/
		set nocount on;
		SET XACT_ABORT ON;

		/*****************************************************功能执行区*******************************************************/
		--调拔入库单
		IF @sFormID IN(1507)-------------------------------------------------------------Begin @sFormID IN(1507)
			BEGIN
				/***********************************************************数据初始化*********************************************/
				--取调入门店资料
				SELECT @stcode=b.stcode,@stname=b.name40,@sdorgid=c.sdorgid,@sdorgname=c.sdorgname,@companyID=d.plantid,@CompanyName=d.plantname
				  FROM tmp_imatdoc_h a,oStorage  b,oSDOrg c,oPlant d
				   WHERE DocCode=@dDoccode
				   AND a.stcode=b.stCode
				   AND b.sdorgid=c.SDOrgID
				   AND b.PlantID=d.plantid
				  --取调出门店资料
				  SELECT @stcode2=b.stcode,@stname2=b.name40,@sdorgid2=c.sdorgid,@sdorgname2=c.sdorgname,@companyID2=d.plantid,@CompanyName2=d.plantname
				  FROM tmp_imatdoc_h a,oStorage  b,oSDOrg c,oPlant d
				   WHERE DocCode=@dDoccode
				   AND a.stcode2=b.stCode
				   AND b.sdorgid=c.SDOrgID
				   AND b.PlantID=d.plantid
/********************************************************************************************************************************************************/
	-----------------------------------------------------------转换采购单------------------------------------------------------------------------
/*********************************************************************************************************************************************************/
				IF @dFormID=1509
					BEGIN
						/*******************************************************创建数据******************************************************/
						--创建临时表
						SELECT * into #imatdoc_H FROM imatdoc_h WHERE 1=2
						SELECT * into #imatdoc_d FROM imatdoc_d WHERE 1=2
						SELECT * INTO #iSeriesLog_HD FROM iseriesLogHD WHERE 1=2
						SELECT * INTO #iSeriesLog_Item FROM iSeriesLogItem WHERE 1=2
						--生成单号
						EXEC sp_newdoccode @dFormID,'',@dDoccode out,@dDoccodeBaseDigit
						--先生成采购单,创建表头,仓库用采购仓库
						INSERT INTO #imatdoc_H( doccode, formid, doctype, refcode, refformid, docdate, periodid, companyid, companyname, plantid, 
							   plantname, stcode, stname, companyid2, companyname2, plantid2, plantname2, vndcode, 
							   vndname, vatrate, usertxt2, usertxt3, docstatus, entername, enterdate, modifyname, 
							   modifydate, matstatus, companyidzb, sdorgid, sdorgname, rowid, ckcy)
						SELECT @dDoccode,@dFormID,'采购入库',@sdoccode,@sFormid,docdate,periodid,@companyid,@companyname,@companyid as plantid,@companyname as plantname,
						@purStcode,@purStName,@companyid as companyid2 ,@companyname AS companyname2,@companyid as plantid2,@companyname as plantname2,@vndcode AS vndcode,@vndname AS vndname,
						1 AS vatrate,NULL AS usertxt2,'非预约款' as usertxt3,@ddocstatus as docstatus,entername,enterdate,modifyname,modifydate,'正常' as matstatus,'1' as companyidzb,
						sdorgid,sdorgname,NEWID() AS rowid,1 AS ckcy
						FROM tmp_imatdoc_h a
						WHERE DocCode=@sDoccode
						--创建明细表
						INSERT INTO #imatdoc_d( doccode, docitem, rowid, itemtype, matcode, matname, matgroup, 
						       packagecode, batchcode, uom, price, digit, netprice, netmoney, totalmoney, ratetxt, 
						       uomrate, baseuomrate, baseuom, basedigit, baseprice, BaseNetprice, userdigit1, userdigit2,
						       userdigit3, poststock, postprice, sorowid, dcflag, inouttype, prematstatus,
						       newmatstatus)
						SELECT @dDocCode,0,NEWID(),'&自有&',a.matcode,a.matname,a.matgroup,
						a.packagecode,a.batchcode,a.uom,a.price,a.digit-ISNULL(userdigit1,0) AS digit,
						netprice,netprice*(a.digit-ISNULL(userdigit1,0)) AS netmoney,price*(a.digit-ISNULL(userdigit1,0)) AS totalmoeny,ratetxt,
						uomrate,Baseuomrate,BaseUOM,a.digit-ISNULL(userdigit1,0) AS basedigit,baseprice,basenetprice,
						a.digit-ISNULL(userdigit1,0) AS userdigit1,a.digit-ISNULL(userdigit1,0) AS userdigit2,
						a.digit-ISNULL(userdigit1,0) AS userdigit3,price*(a.digit-ISNULL(userdigit1,0)) AS poststock,price AS postprice,
						NEWID() AS sorowid,'+' AS dcflag,'采购入库' AS inouttype,'正常' AS prematstatus,'正常' AS newmatstat
						FROM tmp_imatdoc_d a
						WHERE DocCode=@sDoccode
						AND a.Digit-ISNULL(a.userdigit2,0)>0

						
						--插入串号明细表单头
						INSERT INTO #iSeriesLogHD
						SELECT * FROM tmp_SeriesLogHD WHERE refcode=@sDoccode
						--取得单号
						SELECT @doccode1=doccode FROM #iSeriesLogHD
						--插入明细表
						INSERT INTO #iSeriesLogItem
						SELECT a.* FROM 码tmp_SeriesLogItem a WHERE a.doccode=@doccode1
						AND ISNULL(a.usertxt1,0)=0 
						--更新单号字段及采购仓库
						UPDATE #iSeriesLogHD
							SET stcode=@purStcode,
							refcode=@dDoccode
						WHERE refcode=@sDoccode
						/**********************************************整理数据*************************************************/
						--开启事务
						BEGIN tran
						--将数据插入采购单
						BEGIN try
							INSERT INTO imatdoc_h SELECT * FROM #imatdoc_h
							INSERT INTO imatdoc_d SELECT * FROM #imatdoc_d
							--执行一次单据保存,恢复现场
							EXEC autoSeriesDigit @doccode1					--单据保存执行过程
							INSERT INTO iseriesloghd SELECT * FROM #iSeriesLogHD
							INSERT INTO iSeriesLogItem SELECT * FROM #iSeriesLogItem
							--执行一次单据保存,恢复现场
							exec update_money @dDoccode						--单据保存执行
							EXEC sp_CKCY @dFormID,@dDoccode					--仓库确认
							COMMIT
						END TRY
						/*********************************************异常处理**************************************************/
						BEGIN CATCH
							SELECT @msg='转换单据发生错误,'+ERROR_message()+char(10)+
							'错误源:'+ERROR_PROCEDURE()+CHAR(10)+
							'错误发生在第'+convert(varchar(10),Error_Number())+'处'
							RAISERROR(@msg,16,1)
							IF @@TRANCOUNT>0 ROLLBACK
						END CATCH
						/*************************************************后期清理************************************************/
						--删除临时表
						DROP TABLE #imatdoc_h
						DROP TABLE #imatdoc_d
						DROP TABLE #iSeriesLogHD
						DROP TABLE #iSeriesLogItem
					END--------------------------------------------------------------------------------------END @dFormID=1509
/********************************************************************************************************************************************************/
	-----------------------------------------------------------转换成零售单------------------------------------------------------------------------
/*********************************************************************************************************************************************************/
				IF @dFormID=2419-----------------------------------------------------------------------------Begin @dFormID=2419
					BEGIN
						--生成单号
						EXEC sp_newdoccode @dFormID,'',@dDoccode out,@dDoccodeBaseDigit
						SELECT * INTO #spickOrderHD FROM sPickorderHD sph WHERE 1=2
						SELECT * INTO #spickOrderItem FROM spickOrderItem WHERE 1=2
						--生成单头,要注意仓库是调出仓库 stcode2,因为是转换的单据,操作人员全计在管理员上,积分也算在管理员上.
						INSERT INTO #spickOrderHD( doccode, formid, doctype, docdate, periodid, refcode, companyid, 
						       companyname, docsubtype, plantid, plantname, sdorgid, sdorgname, cltcode, cltname, stcode, 
						       stname, instcode, instname, sdgroup, sdgroupname, pick_ref, userdigit1, userdigit2, 
						       userdigit3, userdigit4, docstatus, entername, enterdate, modifyname, modifydate, 
						       achievement, sdorgid2, sdorgname2, matstatus, refformid, sdgroup1, sdgroupname1, done, 
						       systemoption)
						SELECT @ddoccode,2419 AS formid,'销售出库' AS doctype,docdate,periodid,doccode,companyid2,
						       companyname2,'RX' AS docsubtype,companyid2 AS plantid,companyname2 AS plantname,stcode2 as sdorgid,
						       stname2 as sdorgname,'888888' AS cltcode,'零售客户' AS cltname,stcode2,stname2,stcode2,stname2,'system' AS 
						       sdgroup,'管理员' AS sdgroupname,'system' AS pick_ref,0 AS userdigit1,0 AS userdigit2,0 AS 
						       userdigit3,0 AS userdigit4,@dDocstatus,'管理员',EnterDate,'管理员',ModifyDate,
						       '业务员客户',stcode2,stname2,'正常',FormID,'system' AS sdgroup1,'管理员' AS sdgroupname1,1 AS 
						       done,1 AS systemoption
						FROM   tmp_imatdoc_h
						WHERE  DocCode = @sdoccode
						--调整单头数据
						/*
						1.需要调整公司
						2.需要将积分人员等信息补上,因为调拔单无这些信息
						*/
						--更新仓库,公司,及部门编号
						UPDATE b
							SET companyid=a.plantid,
							companyname=a.plantname,
							plantid=a.plantid,
							plantname=a.plantname,
							sdorgid = d.sdorgid,
							sdorgname=d.SDOrgName,
							stcode=c.stCode,
							stname=c.name40,
							instcode=c.stCode,
							instname=c.stname
						FROM #spickOrderHD b,oPlant a,oStorage c,oSDOrg d
						WHERE b.stcode2=c.stCode
						AND c.PlantID=c.PlantID
						AND b.doccode=@dDoccode
						AND c.sdorgid=d.SDOrgID
						--取得单据一些基本信息,用于后续处理
						SELECT @sdORGID=sdorgid,@stcode=stcode,@stname=stname FROM #spickOrderHD WHERE doccode=@ddoccode
						
						--生成明细表,先导无串号的
						INSERT INTO #spickorderitem( doccode, docitem, rowid, itemtype, matcode, 
						       matame, matgroup, packagecode, stcode, stname, uom, digit, pickdate, 
						       discountprice, price, pricememo, vatrate, netprice, netmoney, 
						        totalmoney, itemdiscount, uomrate, baseuomrate, ratetxt, 
						       baseuom, basedigit, baseprice, basenetprice, invoiced, price2, 
						       zcprice,transfeeRate, seriescode, selfprice, selfprice1, salesprice, 
						       vndcode, end4)
						SELECT @dDoccode,0,NEWID(),'&销售&自有&',a.matcode,b.matname,b.matgroup,b.packagecode,@stcode AS stocde,@stname AS stname,b.uom,a.digit,
						       GETDATE(),a.price AS discountprice,price,'正常' AS priceMemo,a.vatrate,a.netprice,a.netprice*digit,a.totalmoney,1 AS 
						       itemdiscount,b.uomrate,b.baseuomrate,b.ratetxt,b.baseuom,basedigit,baseprice,
						       basenetprice,0 AS invoced, a.totalmoney-ISNULL(c.saleprice,0)*a.Digit AS price2,
						       a.totalmoney-c.selfprice1*digit AS zcprice,
						       1 as transfeeRate,NULL AS seriescode,
						       c.selfprice as selfprice,c.selfprice1 as selfprice1,c.saleprice as saleprice,NULL AS vndcode,c.end4
						FROM   tmp_imatdoc_d a cross apply uf_salesSDOrgpricecalcu3(a.MatCode,@sdorgid, '') c,imatgeneral b
						WHERE  a.DocCode = @sdoccode
						AND ISNULL(b.MatFlag,0)=0
						AND a.Digit-ISNULL(a.userdigit1,0)>0				--总数量-拒收数量必须大于零
						--再导有串号的,需要做cross join,串号的数量均为1,totalmoney为价格乘数量,即单价.因为调拔入库单中,价格不允许调整,金额为数量乘单价,因此不会出现价格与总金额对不上的事情.
						--对于价格,单据上的价格都取本帐套的价格,但实收金额取源系统金额,防止帐套金额不一致.在目标帐套中,价格可以调整.
						INSERT INTO #spickorderitem( doccode, docitem, rowid, itemtype, matcode, 
						       matname, matgroup, packagecode, stcode, stname, uom, digit, pickdate, 
						       discountprice, price, pricememo, vatrate, netprice, netmoney, 
						        totalmoney, itemdiscount, uomrate, baseuomrate, ratetxt, 
						       baseuom, basedigit, baseprice, basenetprice, invoiced, price2, 
						       zcprice,transfeeRate, seriescode, selfprice, selfprice1, salesprice1, 
						       vndcode, end4)
						SELECT @dDoccode,0,NEWID(),'&销售&自有&',a.matcode,b.matname,b.matgroup,b.packagecode,@stcode AS stocde,@stname AS stname,b.uom,1,
						       GETDATE(),a.price AS discountprice,price,'正常' AS priceMemo,a.vatrate,a.netprice,a.price as netmoney,a.price as totalmoney,1 AS 
						       itemdiscount,b.uomrate,b.baseuomrate,b.ratetxt,b.baseuom,basedigit,baseprice,
						       basenetprice,0 AS invoced, a.totalmoney-ISNULL(c.saleprice,0)*a.Digit AS price2,
						       a.totalmoney-c.selfprice1 AS zcprice,
						       1 as transfeeRate,f.seriescode,
						       c.selfprice as selfprice,c.selfprice1 as selfprice1,c.saleprice as saleprice,NULL AS vndcode,c.end4
						FROM   tmp_imatdoc_d a cross apply uf_salesSDOrgpricecalcu3(a.MatCode,@sdorgid, '') c,imatgeneral b
						CROSS JOIN tmp_iSeriesLogItem f
						INNER JOIN tmp_iSeriesLogHD e ON f.doccode=e.doccode 
						WHERE  a.DocCode = @sdoccode
						AND a.matcode=b.matcode
						AND ISNULL(b.MatFlag,0)=1							--必须是做串号管理的
						AND a.Digit-ISNULL(a.userdigit1,0)>0				--总数量-拒收数量必须大于零
						AND a.doccode=e.refCode
						AND f.matcode=a.matcode
						AND ISNULL(f.usertxt1,0)=0
						--更新docitem
						;WITH cte as(SELECT rowid,ROW_NUMBER() OVER (ORDER BY f.doccode)  as docitem FROM #spickorderitem)
						UPDATE A
							SET docitem=b.docitem
						FROM #spickorderitem a,cte b
						WHERE a.rowid=b.rowid
						--将数据插入数据表中
						INSERT INTO sPickorderHD SELECT * FROM #spickOrderHD
						INSERT INTO spickorderItem SELECT * FROM #spickOrderItem			
						--执行一次单据保存,恢复现场
						EXEC CashIntype @dDoccode
						--删除临时表
						DROP TABLE #spickOrderHD
						DROP TABLE #spickOrderItem
					END----------------------------------------------------------------------------END @dFormID=2419
			END------------------------------------------------------------------------------------END @sFormID IN(1507)
		return
	END
	/*
	!uf_salesSDOrgpricecalcu3('&matcode&','&sdorgid&','&seriescode&')|price;salesprice1;selfprice;selfprice1;end4
SELECT TOP 1 * FROM sPickorderHD sph where formid=2419 and docstatus=200 ORDER BY sph.DocDate
SELECT TOP 1 * FROM imatdoc_h WHERE formid=1507 AND DocStatus=100  ORDER BY docdate DESC

SELECT TOP 5 * FROM spickorderitem sph WHERE sph.DocCode='RE20110704000001'
SELECT TOP 5 * FROM imatdoc_d WHERE doccode='DR20110629000260'*/
 
 