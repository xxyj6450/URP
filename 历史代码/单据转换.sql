
/*
��������:sp_ConvertDoc
����:����������
����:��һ�ֵ���ת�Ƴ���һ�ֵ���
��д:���ϵ�
ʱ��:2011-07-09
��ע:�˵���ת�ƹ���֧�ִӲ�ͬ�ط�������Դ����ת��,���Ҳ�Ӱ������Դ����������,
������Ϊ(���)Դ���ݱ�����д���������,�����֮��������һЩ���ӵĲ���,
Ҳ��Ӱ��ת��Ч��,������Ҫ������Դ��������ת�Ƶ������ݿ�,������Դ����ǰ��tmp_,ת�����������ɾ��.
����,����Դ�������ĸ�������,�ĸ����ݿ�,��������Դ,ֻ��Ҫ�����ݲ����м��,�Ϳ���ת������Ҫ�ĵ���.
����ֻʵ�ֵ�����ⵥ�����۵�,�ɹ���֮���ת��.
*/
alter PROC [dbo].[sp_ConvertDoc]
	@sDoccode VARCHAR(20),				--Դ����
	@sFormID INT,						--Դ���ܺ�
	@dFormID INT,						--�¹��ܺ�
	@dDocStatus int=0,					--�µ���״̬
	@dDoccodeBaseDigit INT=10000,		--�µ��ŵ��ݺ���ʼ����,Ĭ��ֵΪ10000.
	@optionID VARCHAR(20)='',			--ѡ��,����
	@dDoccode VARCHAR(20)='' OUTPUT		--�����ɵĵ���,���
AS
	BEGIN
		/*************************************************����������***********************************************************/
		DECLARE @CompanyID VARCHAR(20),@CompanyName VARCHAR(20),@sdORGID VARCHAR(50),@sdorgName varchar(200),@stcode VARCHAR(50),@stname VARCHAR(200),@doccode1 VARCHAR(20)
		DECLARE @stcode2 VARCHAR(20),@stname2 VARCHAR(200),@sdorgID2 VARCHAR(20),@sdorgName2 VARCHAR(200),@CompanyID2 VARCHAR(20),@companyName2 VARCHAR(50)
		DECLARE @vndCode VARCHAR(20),@vndName VARCHAR(200),@purStcode VARCHAR(20),@purStName VARCHAR(200)
		DECLARE @msg VARCHAR(2000)
		/**************************************************���ݳ�ʼ����******************************************************/
		set nocount on;
		SET XACT_ABORT ON;

		/*****************************************************����ִ����*******************************************************/
		--������ⵥ
		IF @sFormID IN(1507)-------------------------------------------------------------Begin @sFormID IN(1507)
			BEGIN
				/***********************************************************���ݳ�ʼ��*********************************************/
				--ȡ�����ŵ�����
				SELECT @stcode=b.stcode,@stname=b.name40,@sdorgid=c.sdorgid,@sdorgname=c.sdorgname,@companyID=d.plantid,@CompanyName=d.plantname
				  FROM tmp_imatdoc_h a,oStorage  b,oSDOrg c,oPlant d
				   WHERE DocCode=@dDoccode
				   AND a.stcode=b.stCode
				   AND b.sdorgid=c.SDOrgID
				   AND b.PlantID=d.plantid
				  --ȡ�����ŵ�����
				  SELECT @stcode2=b.stcode,@stname2=b.name40,@sdorgid2=c.sdorgid,@sdorgname2=c.sdorgname,@companyID2=d.plantid,@CompanyName2=d.plantname
				  FROM tmp_imatdoc_h a,oStorage  b,oSDOrg c,oPlant d
				   WHERE DocCode=@dDoccode
				   AND a.stcode2=b.stCode
				   AND b.sdorgid=c.SDOrgID
				   AND b.PlantID=d.plantid
/********************************************************************************************************************************************************/
	-----------------------------------------------------------ת���ɹ���------------------------------------------------------------------------
/*********************************************************************************************************************************************************/
				IF @dFormID=1509
					BEGIN
						/*******************************************************��������******************************************************/
						--������ʱ��
						SELECT * into #imatdoc_H FROM imatdoc_h WHERE 1=2
						SELECT * into #imatdoc_d FROM imatdoc_d WHERE 1=2
						SELECT * INTO #iSeriesLog_HD FROM iseriesLogHD WHERE 1=2
						SELECT * INTO #iSeriesLog_Item FROM iSeriesLogItem WHERE 1=2
						--���ɵ���
						EXEC sp_newdoccode @dFormID,'',@dDoccode out,@dDoccodeBaseDigit
						--�����ɲɹ���,������ͷ,�ֿ��òɹ��ֿ�
						INSERT INTO #imatdoc_H( doccode, formid, doctype, refcode, refformid, docdate, periodid, companyid, companyname, plantid, 
							   plantname, stcode, stname, companyid2, companyname2, plantid2, plantname2, vndcode, 
							   vndname, vatrate, usertxt2, usertxt3, docstatus, entername, enterdate, modifyname, 
							   modifydate, matstatus, companyidzb, sdorgid, sdorgname, rowid, ckcy)
						SELECT @dDoccode,@dFormID,'�ɹ����',@sdoccode,@sFormid,docdate,periodid,@companyid,@companyname,@companyid as plantid,@companyname as plantname,
						@purStcode,@purStName,@companyid as companyid2 ,@companyname AS companyname2,@companyid as plantid2,@companyname as plantname2,@vndcode AS vndcode,@vndname AS vndname,
						1 AS vatrate,NULL AS usertxt2,'��ԤԼ��' as usertxt3,@ddocstatus as docstatus,entername,enterdate,modifyname,modifydate,'����' as matstatus,'1' as companyidzb,
						sdorgid,sdorgname,NEWID() AS rowid,1 AS ckcy
						FROM tmp_imatdoc_h a
						WHERE DocCode=@sDoccode
						--������ϸ��
						INSERT INTO #imatdoc_d( doccode, docitem, rowid, itemtype, matcode, matname, matgroup, 
						       packagecode, batchcode, uom, price, digit, netprice, netmoney, totalmoney, ratetxt, 
						       uomrate, baseuomrate, baseuom, basedigit, baseprice, BaseNetprice, userdigit1, userdigit2,
						       userdigit3, poststock, postprice, sorowid, dcflag, inouttype, prematstatus,
						       newmatstatus)
						SELECT @dDocCode,0,NEWID(),'&����&',a.matcode,a.matname,a.matgroup,
						a.packagecode,a.batchcode,a.uom,a.price,a.digit-ISNULL(userdigit1,0) AS digit,
						netprice,netprice*(a.digit-ISNULL(userdigit1,0)) AS netmoney,price*(a.digit-ISNULL(userdigit1,0)) AS totalmoeny,ratetxt,
						uomrate,Baseuomrate,BaseUOM,a.digit-ISNULL(userdigit1,0) AS basedigit,baseprice,basenetprice,
						a.digit-ISNULL(userdigit1,0) AS userdigit1,a.digit-ISNULL(userdigit1,0) AS userdigit2,
						a.digit-ISNULL(userdigit1,0) AS userdigit3,price*(a.digit-ISNULL(userdigit1,0)) AS poststock,price AS postprice,
						NEWID() AS sorowid,'+' AS dcflag,'�ɹ����' AS inouttype,'����' AS prematstatus,'����' AS newmatstat
						FROM tmp_imatdoc_d a
						WHERE DocCode=@sDoccode
						AND a.Digit-ISNULL(a.userdigit2,0)>0

						
						--���봮����ϸ��ͷ
						INSERT INTO #iSeriesLogHD
						SELECT * FROM tmp_SeriesLogHD WHERE refcode=@sDoccode
						--ȡ�õ���
						SELECT @doccode1=doccode FROM #iSeriesLogHD
						--������ϸ��
						INSERT INTO #iSeriesLogItem
						SELECT a.* FROM ��tmp_SeriesLogItem a WHERE a.doccode=@doccode1
						AND ISNULL(a.usertxt1,0)=0 
						--���µ����ֶμ��ɹ��ֿ�
						UPDATE #iSeriesLogHD
							SET stcode=@purStcode,
							refcode=@dDoccode
						WHERE refcode=@sDoccode
						/**********************************************��������*************************************************/
						--��������
						BEGIN tran
						--�����ݲ���ɹ���
						BEGIN try
							INSERT INTO imatdoc_h SELECT * FROM #imatdoc_h
							INSERT INTO imatdoc_d SELECT * FROM #imatdoc_d
							--ִ��һ�ε��ݱ���,�ָ��ֳ�
							EXEC autoSeriesDigit @doccode1					--���ݱ���ִ�й���
							INSERT INTO iseriesloghd SELECT * FROM #iSeriesLogHD
							INSERT INTO iSeriesLogItem SELECT * FROM #iSeriesLogItem
							--ִ��һ�ε��ݱ���,�ָ��ֳ�
							exec update_money @dDoccode						--���ݱ���ִ��
							EXEC sp_CKCY @dFormID,@dDoccode					--�ֿ�ȷ��
							COMMIT
						END TRY
						/*********************************************�쳣����**************************************************/
						BEGIN CATCH
							SELECT @msg='ת�����ݷ�������,'+ERROR_message()+char(10)+
							'����Դ:'+ERROR_PROCEDURE()+CHAR(10)+
							'�������ڵ�'+convert(varchar(10),Error_Number())+'��'
							RAISERROR(@msg,16,1)
							IF @@TRANCOUNT>0 ROLLBACK
						END CATCH
						/*************************************************��������************************************************/
						--ɾ����ʱ��
						DROP TABLE #imatdoc_h
						DROP TABLE #imatdoc_d
						DROP TABLE #iSeriesLogHD
						DROP TABLE #iSeriesLogItem
					END--------------------------------------------------------------------------------------END @dFormID=1509
/********************************************************************************************************************************************************/
	-----------------------------------------------------------ת�������۵�------------------------------------------------------------------------
/*********************************************************************************************************************************************************/
				IF @dFormID=2419-----------------------------------------------------------------------------Begin @dFormID=2419
					BEGIN
						--���ɵ���
						EXEC sp_newdoccode @dFormID,'',@dDoccode out,@dDoccodeBaseDigit
						SELECT * INTO #spickOrderHD FROM sPickorderHD sph WHERE 1=2
						SELECT * INTO #spickOrderItem FROM spickOrderItem WHERE 1=2
						--���ɵ�ͷ,Ҫע��ֿ��ǵ����ֿ� stcode2,��Ϊ��ת���ĵ���,������Աȫ���ڹ���Ա��,����Ҳ���ڹ���Ա��.
						INSERT INTO #spickOrderHD( doccode, formid, doctype, docdate, periodid, refcode, companyid, 
						       companyname, docsubtype, plantid, plantname, sdorgid, sdorgname, cltcode, cltname, stcode, 
						       stname, instcode, instname, sdgroup, sdgroupname, pick_ref, userdigit1, userdigit2, 
						       userdigit3, userdigit4, docstatus, entername, enterdate, modifyname, modifydate, 
						       achievement, sdorgid2, sdorgname2, matstatus, refformid, sdgroup1, sdgroupname1, done, 
						       systemoption)
						SELECT @ddoccode,2419 AS formid,'���۳���' AS doctype,docdate,periodid,doccode,companyid2,
						       companyname2,'RX' AS docsubtype,companyid2 AS plantid,companyname2 AS plantname,stcode2 as sdorgid,
						       stname2 as sdorgname,'888888' AS cltcode,'���ۿͻ�' AS cltname,stcode2,stname2,stcode2,stname2,'system' AS 
						       sdgroup,'����Ա' AS sdgroupname,'system' AS pick_ref,0 AS userdigit1,0 AS userdigit2,0 AS 
						       userdigit3,0 AS userdigit4,@dDocstatus,'����Ա',EnterDate,'����Ա',ModifyDate,
						       'ҵ��Ա�ͻ�',stcode2,stname2,'����',FormID,'system' AS sdgroup1,'����Ա' AS sdgroupname1,1 AS 
						       done,1 AS systemoption
						FROM   tmp_imatdoc_h
						WHERE  DocCode = @sdoccode
						--������ͷ����
						/*
						1.��Ҫ������˾
						2.��Ҫ��������Ա����Ϣ����,��Ϊ���ε�����Щ��Ϣ
						*/
						--���²ֿ�,��˾,�����ű��
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
						--ȡ�õ���һЩ������Ϣ,���ں�������
						SELECT @sdORGID=sdorgid,@stcode=stcode,@stname=stname FROM #spickOrderHD WHERE doccode=@ddoccode
						
						--������ϸ��,�ȵ��޴��ŵ�
						INSERT INTO #spickorderitem( doccode, docitem, rowid, itemtype, matcode, 
						       matame, matgroup, packagecode, stcode, stname, uom, digit, pickdate, 
						       discountprice, price, pricememo, vatrate, netprice, netmoney, 
						        totalmoney, itemdiscount, uomrate, baseuomrate, ratetxt, 
						       baseuom, basedigit, baseprice, basenetprice, invoiced, price2, 
						       zcprice,transfeeRate, seriescode, selfprice, selfprice1, salesprice, 
						       vndcode, end4)
						SELECT @dDoccode,0,NEWID(),'&����&����&',a.matcode,b.matname,b.matgroup,b.packagecode,@stcode AS stocde,@stname AS stname,b.uom,a.digit,
						       GETDATE(),a.price AS discountprice,price,'����' AS priceMemo,a.vatrate,a.netprice,a.netprice*digit,a.totalmoney,1 AS 
						       itemdiscount,b.uomrate,b.baseuomrate,b.ratetxt,b.baseuom,basedigit,baseprice,
						       basenetprice,0 AS invoced, a.totalmoney-ISNULL(c.saleprice,0)*a.Digit AS price2,
						       a.totalmoney-c.selfprice1*digit AS zcprice,
						       1 as transfeeRate,NULL AS seriescode,
						       c.selfprice as selfprice,c.selfprice1 as selfprice1,c.saleprice as saleprice,NULL AS vndcode,c.end4
						FROM   tmp_imatdoc_d a cross apply uf_salesSDOrgpricecalcu3(a.MatCode,@sdorgid, '') c,imatgeneral b
						WHERE  a.DocCode = @sdoccode
						AND ISNULL(b.MatFlag,0)=0
						AND a.Digit-ISNULL(a.userdigit1,0)>0				--������-�����������������
						--�ٵ��д��ŵ�,��Ҫ��cross join,���ŵ�������Ϊ1,totalmoneyΪ�۸������,������.��Ϊ������ⵥ��,�۸��������,���Ϊ�����˵���,��˲�����ּ۸����ܽ��Բ��ϵ�����.
						--���ڼ۸�,�����ϵļ۸�ȡ�����׵ļ۸�,��ʵ�ս��ȡԴϵͳ���,��ֹ���׽�һ��.��Ŀ��������,�۸���Ե���.
						INSERT INTO #spickorderitem( doccode, docitem, rowid, itemtype, matcode, 
						       matname, matgroup, packagecode, stcode, stname, uom, digit, pickdate, 
						       discountprice, price, pricememo, vatrate, netprice, netmoney, 
						        totalmoney, itemdiscount, uomrate, baseuomrate, ratetxt, 
						       baseuom, basedigit, baseprice, basenetprice, invoiced, price2, 
						       zcprice,transfeeRate, seriescode, selfprice, selfprice1, salesprice1, 
						       vndcode, end4)
						SELECT @dDoccode,0,NEWID(),'&����&����&',a.matcode,b.matname,b.matgroup,b.packagecode,@stcode AS stocde,@stname AS stname,b.uom,1,
						       GETDATE(),a.price AS discountprice,price,'����' AS priceMemo,a.vatrate,a.netprice,a.price as netmoney,a.price as totalmoney,1 AS 
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
						AND ISNULL(b.MatFlag,0)=1							--�����������Ź����
						AND a.Digit-ISNULL(a.userdigit1,0)>0				--������-�����������������
						AND a.doccode=e.refCode
						AND f.matcode=a.matcode
						AND ISNULL(f.usertxt1,0)=0
						--����docitem
						;WITH cte as(SELECT rowid,ROW_NUMBER() OVER (ORDER BY f.doccode)  as docitem FROM #spickorderitem)
						UPDATE A
							SET docitem=b.docitem
						FROM #spickorderitem a,cte b
						WHERE a.rowid=b.rowid
						--�����ݲ������ݱ���
						INSERT INTO sPickorderHD SELECT * FROM #spickOrderHD
						INSERT INTO spickorderItem SELECT * FROM #spickOrderItem			
						--ִ��һ�ε��ݱ���,�ָ��ֳ�
						EXEC CashIntype @dDoccode
						--ɾ����ʱ��
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
 
 