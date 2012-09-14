--品牌店面平衡单审核量合计
SELECT SUM(afsumdigit),SUM(busumdigit)
 FROM 
CltmonthgroupHD a,Cltmonthgroupitem b
WHERE a.doccode=b.doccode
AND a.formid=6311
AND a.YearBudget=2010
AND a.MonthBudget=4
--品牌店面平衡单任务量合计
SELECT a.usertxt2, SUM(userdigit1)
 FROM 
CltmonthgroupHD a
WHERE  a.formid=6311
AND a.YearBudget=2010
AND a.MonthBudget=4
--AND a.targetgroup='零售量_海尔-CDMA'
GROUP BY a.usertxt2
COMPUTE SUM(SUM(userdigit1))
--统计每个配送站指标量统计(同区域平衡单)
SELECT a.usertxt2,a.targetgroup, SUM(userdigit1)
 FROM 
CltmonthgroupHD a
WHERE  a.formid=6311
AND a.YearBudget=2010
AND a.MonthBudget=4
--AND a.targetgroup='零售量_海尔-CDMA'
GROUP BY a.usertxt2,a.targetgroup
ORDER BY usertxt2,targetgroup
COMPUTE SUM(SUM(userdigit1))
-------
UPDATE 
CltMonthTotalBudget
SET docstatus=0
WHERE doccode='BPA2010032300001'
