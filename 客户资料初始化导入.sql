--��������
BEGIN TRAN
--����ͻ����ϵǼ�
insert INTO customers_h
SELECT * FROM ierp.dbo.customers_h
WHERE doccode NOT IN(SELECT doccode FROM customers_h)
AND customercode IS NOT null
--���·�չ����
UPDATE Customers_H
	SET DevelopSdorgID=a.SDOrgID   
FROM sop10.ierp.dbo.sdorg_bak a
WHERE Customers_H.DevelopSdorgID=a.oldSDOrgID
--����ͻ���������
INSERT INTO customers
SELECT * FROM ierp.dbo.customers a
WHERE   NOT exists(SELECT 1 FROM customers  b WHERE a.customercode=b.CustomerCode AND a.vouchercode=b.VoucherCode)
delete Customers
ROLLBACK
COMMIT
 SELECT a.customercode,a.vouchercode,b.CustomerCode,b.VoucherCode
   FROM ierp.dbo.customers a LEFT JOIN customers b ON a.customercode=b.CustomerCode where a.vouchercode<>b.VoucherCode
   TRUNCATE TABLE Customers_H
 delete   Customers
 DELETE FROM CustomerOrders
 SELECT * FROM ierp.dbo.customers WHERE CustomerCode='JT115954'
  SELECT * FROM ierp.dbo.customers WHERE CustomerCode='JT115957'
  SELECT * FROM customers WHERE VoucherCode='430406198801010001'
  
  DELETE FROM customers WHERE VoucherCode='440582197901193635'
  SELECT usertxt2, * FROM  ierp.dbo.unicom_orders WHERE cltcode='JT115952'
 ROLLBACK
 


--���·�չ����
UPDATE Customers
	SET DevelopSdorgID=a.SDOrgID    
FROM sop10.ierp.dbo.sdorg_bak a
WHERE Customers.DevelopSdorgID=a.oldSDOrgID
--����ͻ����Ѽ�¼
 INSERT INTO CustomerOrders
SELECT * FROM ierp.dbo.CustomerOrders
WHERE customercode NOT IN(SELECT customercode FROM CustomerOrders)
--���·�չ����
UPDATE CustomerOrders
	SET sdorgid=a.SDOrgID   
FROM sop10.ierp.dbo.sdorg_bak a
WHERE CustomerOrders.sdorgid=a.oldSDOrgID

TRUNCATE TABLE SOP_dim_Profile
delete SOP_dim_Customers
--��customers�����ͻ���
INSERT INTO SOP_dim_Customers( CustomerID, strCustomerCode, strCustomerName, 
       strCustomerType, strGrade, intConsumptionCount, dblTotalConsumption, 
       bitBlackList, strQQ, strEMail, strZIPCODE, strPost, strDepartment, strURL, 
       strCompanyAddress, strCompanyLicense, strCompany, strIndustry, strFax, 
       strPhoneNumber1, strPhoneNumber, strcurAddress, strVoucherAddress, 
       strLunarDateString, dtmLunarDate, strBirthdayString, dtmBirthDay, 
       dtmValidDate, strVoucherCode, strVoucherType, strSex, strRemark, 
       dtmIndate, intOrderCount, IMPORTDATE, dtmModifyDate, strModifyName, 
       dtmEnterDate, strEnterName, strDevelopSdorgID, strDevelopStaffID, 
       dtmdocDate, strDoccode, strGrade2, intCustomerSource )
SELECT NEWID(),c.customercode,c.name,'��Ӫ�̿ͻ�',grade,0,0,0,c.qq,c.email,c.zipcode,c.post,c.department,c.url,
c.companyaddress,c.CompanyLicense,c.Company,c.Industry,c.fax,c.PhoneNumber1,c.PhoneNumber,c.curaddress,c.voucheraddress,
c.LunarDateString,  c.LunarDate, c.BirthdayString, c.BirthDay, 
       c.ValidDate, c.VoucherCode, c.VoucherType, c.Sex, c.Remark, 
       GETDATE(), 0, GETDATE(), c.ModifyDate, c.ModifyName, 
       c.EnterDate, c.EnterName, c.DevelopSdorgID, c.DevelopStaffID, 
       NULL, NULL, NULL, c.CustomerSource 
FROM Customers c
--�û�����
BEGIN TRAN
INSERT INTO SOP_dim_Profile( UserID, CustomerID, CustomerCode, strSeriesNumber, 
       strSIMCode, strSeriesCode, strMatCode, STATUS, strName, strGrade, 
       intComboCode, intComboFeeType, strDoccode, dtmdocDate, strDevelopStaffID, 
       strDevelopSdorgID, strEnterName, dtmEnterDate, strModifyName, 
       dtmModifyDate, ReservedDoccode, IMPORTDATE,packageid )
SELECT NEWID(),b.CustomerID,b.strCustomerCode,a.SeriesNumber,c.SIMCode,c.seriescode,c.matCode,1,
b.strCustomerName,b.strGrade,a.ComboCode,case a.comboFEEType WHEN 'ȫ���ײ�' then 0 when '�����ײ�' then 1 WHEN '�����ʷ�' then 2 else 3 end,
a.doccode,a.DocDate,a.sdgroup,a.sdorgid,a.EnterName,a.EnterDate,
a.ModifyName,a.ModifyDate,a.ReservedDoccode,GETDATE(),a.PackageID

  FROM ierp.dbo.Unicom_Orders a LEFT JOIN SOP_dim_Customers b ON a.cltCode=b.strCustomerCode
INNER JOIN ierp.dbo.NumberAllocation_Log c ON a.DocCode=c.Doccode
WHERE
a.FormID IN(9102,9146)
AND a.checkState='ͨ�����'
AND ISNULL(a.old,0)=0 AND ISNULL(a.NONeedAllocate,0)=0

ROLLBACK

 
--������ҵ�������еĺϷ��û�����
COMMIT
BEGIN tran
;WITH cte AS(
SELECT strSeriesNumber,MIN(strdoccode) AS doccode,COUNT(*) AS num FROM SOP_dim_Profile sdp
GROUP BY sdp.strSeriesNumber
HAVING COUNT(*)>1)
UPDATE a
	SET [Status]=-1
FROM SOP_dim_Profile a,cte b 
WHERE a.strseriesnumber=b.strSeriesNumber
AND a.strdoccode=b.doccode

--���²���
BEGIN tran
UPDATE SOP_dim_Profile
	SET strDevelopSdorgID = b.sdorgid
FROM SOP_dim_Profile a,sop10.ierp.dbo.sdorg_bak b 
WHERE a.strDevelopSdorgID=b.oldsdorgid

DECLARE @sql VARCHAR(2000)
SELECT @sql=''
SELECT @sql=@sql+NAME+','  FROM syscolumns s WHERE id=OBJECT_ID('SOP_dim_Profile')
PRINT @sql
CREATE FUNCTION getTableColumns

DELETE FROM customers WHERE VoucherCode='430381198605013615'
DELETE FROM customers_h WHERE VoucherCode='430381198605013615'
DELETE FROM SOP_dim_Customers WHERE strVoucherCode='430381198605013615'

SELECT * FROM unicom_orders