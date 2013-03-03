--一上一下单检查

--(1)指标类型检查,所有的指标类型必须是CDMA的零售量
SELECT * FROM CltMonthTotalBudget a,Cltmonthbudgetitem b
WHERE a.doccode=b.doccode
AND a.YearBudget=2010
AND a.MonthBudget=4
AND a.formid=6206
AND (b.targetgroup NOT LIKE '%零售量_%CDMA%' and  b.targetgroup NOT LIKE '%零售量_%上网卡%')
-------
BEGIN tran
UPDATE CltMonthTotalBudget
SET docstatus=0 
WHERE doccode='KYS2010032200013'
--(2)检查是否有重复指标
SELECT cltcode,targetgroup,COUNT(targetgroup)
FROM CltMonthTotalBudget a,Cltmonthbudgetitem b
WHERE a.doccode=b.doccode
AND a.YearBudget=2010
AND a.MonthBudget=4
AND a.formid=6206
--AND (b.targetgroup NOT LIKE '%零售量_%CDMA%' and  b.targetgroup NOT LIKE '%零售量_%上网卡%')
GROUP BY cltcode,targetgroup
HAVING COUNT(targetgroup)>1
ORDER BY 3 DESC
--(3)检查是否有门店没有编号
SELECT *
FROM CltMonthTotalBudget a LEFT JOIN oSDOrg c ON  a.cltcode=c.sdorgid
where a.YearBudget=2010
AND a.MonthBudget=4
AND a.formid=6206
AND c.p_no IS NULL
--(4)统计每个配送站(地区)的单数
SELECT c.ps_stname,COUNT(a.doccode)
FROM CltMonthTotalBudget a left JOIN oSDOrg c ON  a.cltcode=c.sdorgid
where a.YearBudget=2010
AND a.MonthBudget=4
AND a.formid=6206
GROUP BY ps_stname
ORDER BY 2 desc
COMPUTE SUM(COUNT(a.doccode))
-----各地区3月份单据情况
SELECT c.ps_stname,COUNT(a.doccode)
FROM CltMonthTotalBudget a left JOIN oSDOrg c ON  a.cltcode=c.sdorgid
where a.YearBudget=2010
AND a.MonthBudget=3
AND a.formid=6206
GROUP BY ps_stname
ORDER BY 2 desc
COMPUTE SUM(COUNT(a.doccode))
--(5)统计没有编号的门店
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

