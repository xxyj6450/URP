--Ʒ�Ƶ���ƽ�ⵥ������ϼ�
SELECT SUM(afsumdigit),SUM(busumdigit)
 FROM 
CltmonthgroupHD a,Cltmonthgroupitem b
WHERE a.doccode=b.doccode
AND a.formid=6311
AND a.YearBudget=2010
AND a.MonthBudget=4
--Ʒ�Ƶ���ƽ�ⵥ�������ϼ�
SELECT a.usertxt2, SUM(userdigit1)
 FROM 
CltmonthgroupHD a
WHERE  a.formid=6311
AND a.YearBudget=2010
AND a.MonthBudget=4
--AND a.targetgroup='������_����-CDMA'
GROUP BY a.usertxt2
COMPUTE SUM(SUM(userdigit1))
--ͳ��ÿ������վָ����ͳ��(ͬ����ƽ�ⵥ)
SELECT a.usertxt2,a.targetgroup, SUM(userdigit1)
 FROM 
CltmonthgroupHD a
WHERE  a.formid=6311
AND a.YearBudget=2010
AND a.MonthBudget=4
--AND a.targetgroup='������_����-CDMA'
GROUP BY a.usertxt2,a.targetgroup
ORDER BY usertxt2,targetgroup
COMPUTE SUM(SUM(userdigit1))
-------
UPDATE 
CltMonthTotalBudget
SET docstatus=0
WHERE doccode='BPA2010032300001'
