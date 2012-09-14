with cte as(SELECT cltcode FROM Unicom_Orders uo  
WHERE formid IN(9102,9146) AND ISNULL(old,0)=0
AND uo.DocStatus<>0
GROUP BY uo.cltCode
)
--SELECT * FROM cte WHERE cltcode NOT IN(SELECT customercode FROM Customers c)

SELECT a.* FROM Customers a,cte b
WHERE a.CustomerCode=b.cltcode


SELECT cltcode,usertxt3,* FROM sPickorderHD sph WHERE sph.FormID=2419 AND sph.cltCode IS NOT NULL

SELECT cltcode,cltname,usertxt1,usertxt3,sph.APPNAME
  FROM sPickorderHD sph WHERE formid=2419 AND sph.cltCode IS null
  
 BEGIN TRAN
	UPDATE spickorderhd set usertxt1='������',
	usertxt2='18688750229'
	WHERE doccode='RT20100821000007'
	
	COMMIT
  
  BEGIN tran
  UPDATE a
  SET --cltcode=usertxt3,
  cltname=usertxt1
  --SELECT doccode,cltcode,cltname,a.usertxt3,a.usertxt1 ,usertxt2
  FROM sPickorderHD a
  WHERE (isnull(cltname,'')='' or cltname='���')
  AND isnull(usertxt1,'')<>''
  AND a.FormID IN(2419,2420)
  
  ORDER BY docdate desc
  COMMIT
  
  ROLLBACK
  BEGIN tran
    SELECT formid,doccode,refcode,cltcode,cltname,sph.usertxt3,sph.usertxt1--,sph.usertxt2
    
   /*UPDATE sph
		SET cltname=usertxt1,
		sph.cltCode = usertxt3 */
      FROM sPickorderHD sph 
    WHERE (cltname IS NULL OR cltname ='���')
    AND (isnull(sph.cltCode,'')   IN('','8888','9999','88888','888888','9999','00','000'))
	 --AND (sph.usertxt3 IS NOT NULL OR usertxt1 IS NOT NULL)
    AND formid =2419
    AND usertxt1<>cltname
    AND isnull(sph.refformid,0)<>9167
    ORDER BY sph.DocDate desc
  
  SELECT   * FROM sPickorderHD   uo WHERE uo.refcode='PS20110609000203'
  
  SELECT * FROM isaleledgerlog i WHERE i.DocCode='RE20110609000210'
  BEGIN tran
  UPDATE a
	SET a.usertxt2=b.seriesnumber
	--SELECT a.doccode,a.refcode,a.cltcode,a.cltname,a.usertxt3,a.usertxt1,a.usertxt2,b.seriesnumber,b.cltcode,b.cltname
  FROM Unicom_Orders    b,sPickorderHD a
  WHERE a.refcode=b.DocCode
  AND a.FormID=2419
  AND a.usertxt2 IS null
  
  commit
  BEGIN tran
  UPDATE sp
	SET sp.cltname=a.Name
	SELECT doccode,refcode,sdorgname,sp.cltcode,a.Name,sp.cltName
  FROM customers a,sPickorderHD sp
  WHERE a.customercode=sp.cltCode
  AND sp.FormID=2419
  AND sp.cltName<>NAME
   
	ORDER BY sp.DocDate desc
  ROLLBACK
 SELECT * FROM Unicom_Orders uo WHERE uo.DocCode='RW20100727000017'
 
 
 SELECT formid,doccode,refcode,cltcode,cltname,sph.usertxt3,sph.usertxt1,sph.usertxt3
  FROM sPickorderHD sph
 WHERE (sph.cltcode IS NULL OR cltcode IN ('8888')
 AND sph.FormID=2419
 AND isnull(sph.refformid,0)<>9167
 ORDER BY sph.DocDate DESC
 
 BEGIN tran
 UPDATE sPickorderHD
	SET cltName = a.NAME
--SELECT *
 FROM customers a,sPickorderHD b
 WHERE a.CustomerCode=b.cltcode
and ISNULL(cltname,'���')='���'

 
 
 SELECT  formid,doccode,refcode,cltcode,cltname,sph.usertxt3,sph.usertxt1,sph.usertxt2
 FROM sPickorderHD sph
 WHERE sph.FormID=2419
 AND LEFT(cltcode,2)<>'JT'
 AND sph.cltCode IS NOT NULL
 AND sph.cltCode NOT IN('9999','888888','88888')
 
 SELECT formid,doccode,refcode,cltcode,cltname,sph.usertxt3,sph.usertxt1,sph.usertxt2
  FROM sPickorderHD sph WHERE sph.cltname='���ۿͻ�'
  
  BEGIN tran
 UPDATE sPickorderHD
	SET cltname=cltcode
 WHERE cltname='���ۿͻ�'
 and cltcode NOT IN('888888')
 
 COMMIT
 
 ROLLBACK
 

 
 SELECT formid,doccode,refcode,cltcode,cltname,sph.usertxt3,sph.usertxt1,sph.usertxt2
  FROM sPickorderHD sph WHERE sph.cltName=usertxt2
 AND sph.FormID=2419
 AND ISNULL(sph.refformid,'') <>9167
 AND LEFT(cltcode,2)<>'JT'
 ORDER BY sph.DocDate DESC
 --------------------------------------
 BEGIN tran
 UPDATE spickorderhd
	SET cltname=cltCode 
 WHERE cltName=usertxt2
  AND  FormID=2419
 AND ISNULL( refformid,'') <>9167
 AND cltCode NOT IN('888888','9999','JT041837','JT052502')
 
 COMMIT
 
 SELECT formid,doccode,refcode,cltcode,cltname,sph.usertxt3,sph.usertxt1,sph.usertxt2,LEN(usertxt2)
  FROM sPickorderHD sph
 WHERE sph.FormID=2419
 AND (LEN(sph.usertxt2) not in(11,7,8,12)  )
 AND LEFT(isnull(cltcode,''),2) <>'JT'
 ORDER BY sph.DocDate desc
 
 SELECT LEN('186769020910')
 
 
 SELECT formid,doccode,refcode,cltcode,cltname,sph.usertxt3,sph.usertxt1,sph.usertxt2,LEN(usertxt2)
 
   FROM sPickorderHD sph WHERE left(sph.usertxt2,4) IN( '0755','0769')
   
   UPDATE sPickorderHD SET 
	usertxt2=REPLACE(usertxt2,'-','')
	
	
	SELECT formid,doccode,refcode,cltcode,cltname,sph.usertxt3,sph.usertxt1,sph.usertxt2,LEN(usertxt2)
	 FROM sPickorderHD sph
	WHERE sph.usertxt2 LIKE '%-%'
	
	BEGIN tran
	UPDATE sPickorderHD
		SET usertxt2=REPLACE(usertxt2,'886-','0886')
	WHERE  usertxt2 LIKE '%-%'
	
	COMMIT
	
	ROLLBACK

------------------------------------------------------------------------------�����������,��������------------------------------------------------------------
--����ͻ�����
delete   bidb..sop_dim_customers
--��������ֵ
DBCC CHECKIDENT ('customers',RESEED,1)

------------------------------------------------------��Ӫ�̿ͻ�---------------------------------------------
--�Ȱ���Ӫ��ҵ���еĿͻ�����ȥ,cltcode like 'JT%'
DECLARE @table TABLE(
	CustomerID INT,
	cltcode VARCHAR(20),
	seriesnumber VARCHAR(50))
--�Ȳ����пͻ������ 
DELETE bidb..sop_dim_customers
INSERT INTO bidb..sop_dim_customers(strcustomercode,intordercount,strremark,dtmindate)
SELECT customercode,COUNT(doccode),max(doccode),min(docdate)  FROM NumbeAllocation_Log  a
WHERE docdate<='2011-08-03'
and isnull(customercode,'')  like 'JT%'
and isnull(seriesnumber,'')<>''
GROUP BY customercode
ORDER BY 2 DESC
--ȡ���һ�η���ҵ�����ϵ�绰
update a
	set strtel=b.seriesnumber,
	strCustomerName=b.customername,
	strcustomertype=doctype
from bidb..sop_dim_customers a,NumbeAllocation_Log b
where a.strremark=b.doccode
--���¿ͻ�����
update a
	set strgrade=b.grade
from bidb..sop_dim_customers a,customers b
where a.strcustomercode=b.customercode
--��������
select * from bidb..sop_dim_customers
where isnull(strcustomercode,'')=''
or len(isnull(strtel,''))<8
or isnull(strCustomerName,'')=''

select strtel,count(strtel)
	from bidb..sop_dim_customers
	group by strtel
	having(count(strtel)>1)
---
select * from bidb..customers where tel='18665424598'
--��������
/*update a
	set strcustomername=name
from bidb..sop_dim_customers a,customers b where a.strcustomercode=b.customercode
and a.customerid='200A8D77-7D2B-4165-8721-CE6D78B47B8C'
select * from customers where customercode='JT021907'*/
--�ٴβ�ѯ����
select top 1000 * from bidb..sop_dim_customers
--�ٴ����޿ͻ������ select seriesnumber, * from NumbeAllocation_Log 	where isnull(customercode,'')=''
insert into bidb..sop_dim_customers(strtel,strremark,intordercount,dtmindate,strcustomertype)
	select seriesnumber,max(doccode),count(seriesnumber),min(docdate),'��Ӫ�̿ͻ�'
from NumbeAllocation_Log a
	where isnull(customercode,'')=''
	and docdate<'2011-08-04'
	and  not  exists(select 1 from bidb..sop_dim_customers b where a.seriesnumber=b.strtel)		---�Ѿ����ڵĵ绰����Ͳ�Ҫ��
	group by seriesnumber
	order by 2 desc
--���¿ͻ�����
begin tran
update a
	set strcustomername=b.customername,
	strcustomertype=doctype 
	from  bidb..sop_dim_customers a,NumbeAllocation_Log b
	where a.strremark=b.doccode
	and isnull(a.strcustomercode,'')=''
	commit
--��������
select top 1000 * from bidb..sop_dim_customers where isnull(strcustomercode,'')='' order by customerid desc
--�������ظ����� ������й�
select strtel,count(strtel) AS num
	from bidb..sop_dim_customers
WHERE ISNULL(strcustomercode,'')=''
	group by strtel
	having(count(strtel)>1)
----------------------------------------------------------���ۿͻ�--------------------------------------------
insert into bidb..customers(tel,ordercount,remark,indate,customertype)
	select usertxt2,count(doccode),max(doccode),min(docdate),'���ۿͻ�'
	from spickorderhd a
	where formid in(2419,2420)
	and isnull(refformid,'')='' 
	and isnull(refcode,'')=''
	and len(isnull(usertxt2,''))>7
	and  not exists(select 1 from bidb..sop_dim_customers b where a.usertxt2=b.strtel)
	and docdate<'2011-08-04'
	group by usertxt2
	order by 2 desc
--���¿ͻ�����
begin tran
update a
	set customername=cltname
	from bidb..customers a,spickorderhd b
where a.remark=b.doccode

commit

---У������
select top 1000 * from bidb..customers where customertype='���ۿͻ�' 
ROLLBACK

-----------------------------------------------------�û���������
--����ͻ�����
delete   bidb..[Profile]
--��������ֵ
DBCC CHECKIDENT ('Profile',RESEED,1)
--
INSERT INTO [Profile](CustomerID,CustomerCode,SeriesNumber,Doccode )
SELECT b.customerid,a.cltcode,a.seriesnumber,MAX(a.doccode) 
FROM ierptest..unicom_orders a,customers b
WHERE a.docdate<'2011-06-13'
AND a.cltcode=b.CustomerCode
AND ISNULL(a.old,0)=0
AND a.docstatus=100
GROUP BY b.customerid,a.cltcode,a.seriesnumber
ORDER BY 5 DESC
--����������Ϣ
UPDATE [Profile]
	SET NAME=a.NAMe,
	sex=a.sex,
	vouchertype=a.vouchertype,
	vouchercode=a.vouchercode,
	phonenumber=a.phonenumber,
	phonenumber1=a.phonenumber1,
	curAddress = a.curaddress,
	VoucherAddress = a.voucheraddress,
	Post = a.post,
	ValidDate = a.validdate,
	Fax = a.fax,
	EMail = a.email,
	Company = a.company,
	ZipCode = a.zipcode,
	CompanyLicense = a.companylicense,
	CompanyAddress = a.companyaddress,
	DevelopStaffID = a.developstaffid,
	DevelopStaffName = a.DevelopStaffName,
	DevelopSdorgID = a.developsdorgid,
	DevelopSdorgName = a.developsdorgname
 
FROM ierptest..customers a
WHERE a.customercode=PROFILE.CustomerCode
---��������
INSERT INTO [Profile]( CustomerID,doccode, CustomerCode, SeriesNumber, SIMCode, NAME, 
       Sex, VoucherType, VoucherCode, ValidDate, PhoneNumber, PhoneNumber1, Fax, 
       Industry, Company, Department, Post, ZipCode, BirthDay, BirthdayString, 
       LunarDate, LunarDateString, VoucherAddress, curAddress, EMail, 
       TotalConsumption, ConsumptionCount, Grade, DevelopStaffID, 
       DevelopStaffName, DevelopSdorgID, DevelopSdorgName, EnterName, EnterDate, 
       ModifyName, ModifyDate, Photo, Remark, BlackList, QQ, CompanyLicense, 
       CompanyAddress, [URL])
SELECT b.customerid,a.doccode,c.*
FROM Customers b,ierptest..customers c,ierptest..unicom_orders a
WHERE b.CustomerCode=c.customercode
AND c.customercode=a.cltcode
AND ISNULL(a.old,0)=0
AND a.docdate<'2011-06-13'
--���������绰]
UPDATE a
	SET seriesnumber=b.seriesnumber
FROM ierptest..unicom_orders b,[Profile] a
WHERE a.Doccode=b.doccode

--�������
SELECT TOP 6000 * FROM [Profile] p WHERE ISNULL(p.SeriesNumber,'')=''
begin tran
--����ظ����룬ȡ����󿪻����ں���С�������ڣ���ɾ����С�������ڵġ����ҿ������С��9����
;with cte as(SELECT  strseriesnumber,COUNT(strSeriesNumber) as num,MAX(a.Doccode) as maxdoccode,MIN(a.Doccode) as mindoccode FROM bidb..sop_dim_profile a
--where a.strseriesnumber=b.seriesnumber
GROUP BY strseriesnumber
HAVING(COUNT(strSeriesNumber)>1))
, cteb as(select c.*,a.docdate as maxdocdate,b.docdate as mindocdate from cte c,unicom_orders a,unicom_orders b
where c.maxdoccode=a.doccode
and c.mindoccode=b.doccode
and datediff(mm,a.docdate,b.docdate)<9)
delete from bidb..sop_dim_profile where doccode in(select mindoccode from cteb)
commit
--ɾ���ظ���¼(���˻���)
begin tran
;WITH cte AS(SELECT  strseriesnumber  FROM bidb..sop_dim_profile
GROUP BY strseriesnumber
HAVING(COUNT(strSeriesNumber)>1)),
cteb as (SELECT a.doccode,a.SeriesNumber
           FROM ierptest..unicom_orders a,cte b,ierptest..spickorderhd c WHERE a.seriesnumber=b.strseriesnumber AND a.docstatus=100 AND c.refrefcode=a.doccode )

delete bidb..sop_dim_profile where doccode in(select doccode from cteb)
commit

---
SELECT docstatus,cltcode, * FROM ierptest..unicom_orders WHERE seriesnumber='18620350218'

SELECT * FROM ierptest..spickorderhd WHERE refrefcode='RW20110411000084'

SELECT * FROM ierptest..seriespool_d WHERE seriesnumber='18676709052'

--ȡ���һ����ϵ�绰
with cte as(
	select customercode,max(doccode) as doccode,count(doccode) as count
	from NumbeAllocation_Log 
	where customercode   like 'JT%'
	--and isnull(seriesnumber,'')=''
	group by  customercode,doc
	--order by 3 desc
)
select cltcode,max(doccode) as doccode,count(doccode) as count
	from spickorderhd 
	where cltcode like 'JT%'
	--and isnull(seriesnumber,'')=''
	group by  cltcode

update bidb..customers
	set tel=a.seriesnumber
from numberallocation_log
where 

SELECT uo.cltCode, * FROM Unicom_Orders uo WHERE uo.SeriesNumber='18602099168'

SELECT usertxt2,COUNT(usertxt2)
FROM sPickorderHD sph
WHERE sph.FormID IN(2419,2420)
AND LEFT(cltcode,2)<>'JT'
AND LEN(ISNULL(usertxt2,''))>=7
AND usertxt2 not IN(SELECT seriesnumber FROM unicom_orders)
--AND usertxt2 NOT IN (SELECT phonenumber FROM customers)
--AND usertxt2 NOT IN(SELECT phonenumber1 FROM customers)
GROUP BY usertxt2
ORDER BY 2 desc
COMMIT
SELECT usertxt1,usertxt3, cltcode,cltname,usertxt2 FROM sPickorderHD sph WHERE sph.usertxt2='18666855601'

INSERT INTO bidb..customers(customercode,customername,remark,tel)
SELECT cltcode,NULL,NULL,NULL,NULL,

SELECT * FROM Unicom_Orders uo WHERE uo.cltCode='JT000736'
SELECT formid,doccode,refcode,cltcode,cltname,sph.usertxt3,sph.usertxt1,sph.usertxt2
  FROM sPickorderHD sph WHERE 
  --sph.cltCode='JT000175'
  doccode='RE20110604000596'
ORDER BY sph.DocDate DESC

SELECT usertxt1,usertxt3, cltcode,cltname,usertxt2
 FROM Unicom_Orders uo WHERE uo.SeriesNumber='18602099168'
 
 SELECT doccode,sdorgname,usertxt1,usertxt3, cltcode,cltname,usertxt2,refformid,refcode
 FROM spickorderhd uo WHERE uo.usertxt2='18666855627'
order by docdate desc
 
	
 