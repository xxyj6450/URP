--һ��һ�µ����

--(1)ָ�����ͼ��,���е�ָ�����ͱ�����CDMA��������
SELECT * FROM CltMonthTotalBudget a,Cltmonthbudgetitem b
WHERE a.doccode=b.doccode
AND a.YearBudget=2010
AND a.MonthBudget=4
AND a.formid=6206
AND (b.targetgroup NOT LIKE '%������_%CDMA%' and  b.targetgroup NOT LIKE '%������_%������%')
-------
BEGIN tran
UPDATE CltMonthTotalBudget
SET docstatus=0 
WHERE doccode='KYS2010032200013'
--(2)����Ƿ����ظ�ָ��
SELECT cltcode,targetgroup,COUNT(targetgroup)
FROM CltMonthTotalBudget a,Cltmonthbudgetitem b
WHERE a.doccode=b.doccode
AND a.YearBudget=2010
AND a.MonthBudget=4
AND a.formid=6206
--AND (b.targetgroup NOT LIKE '%������_%CDMA%' and  b.targetgroup NOT LIKE '%������_%������%')
GROUP BY cltcode,targetgroup
HAVING COUNT(targetgroup)>1
ORDER BY 3 DESC
--(3)����Ƿ����ŵ�û�б��
SELECT *
FROM CltMonthTotalBudget a LEFT JOIN oSDOrg c ON  a.cltcode=c.sdorgid
where a.YearBudget=2010
AND a.MonthBudget=4
AND a.formid=6206
AND c.p_no IS NULL
--(4)ͳ��ÿ������վ(����)�ĵ���
SELECT c.ps_stname,COUNT(a.doccode)
FROM CltMonthTotalBudget a left JOIN oSDOrg c ON  a.cltcode=c.sdorgid
where a.YearBudget=2010
AND a.MonthBudget=4
AND a.formid=6206
GROUP BY ps_stname
ORDER BY 2 desc
COMPUTE SUM(COUNT(a.doccode))
-----������3�·ݵ������
SELECT c.ps_stname,COUNT(a.doccode)
FROM CltMonthTotalBudget a left JOIN oSDOrg c ON  a.cltcode=c.sdorgid
where a.YearBudget=2010
AND a.MonthBudget=3
AND a.formid=6206
GROUP BY ps_stname
ORDER BY 2 desc
COMPUTE SUM(COUNT(a.doccode))
--(5)ͳ��û�б�ŵ��ŵ�
SELECT *
FROM CltMonthTotalBudget a left JOIN oSDOrg c ON  a.cltcode=c.sdorgid
where a.YearBudget=2010
AND a.MonthBudget=4
AND a.formid=6206
AND c.ps_st IS NULL
--
SELECT *
FROM CltMonthTotalBudget a,Cltmonthbudgetitem b
WHERE a.doccode=b.doccode
AND a.YearBudget=2010
AND a.MonthBudget=4
AND a.formid=6206
AND a.cltcode='GZ0180'

