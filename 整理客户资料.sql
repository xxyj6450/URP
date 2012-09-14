--零售业务客户资料中联系电话不能超过20次
INSERT INTO  t_seriesnumberblacklist(seriesnumber)
SELECT usertxt2  FROM sPickorderHD sph
WHERE sph.FormID IN(2419,2420)
AND isnull(usertxt2,'')<>''
AND usertxt2 NOT IN(SELECT seriesnumber FROM t_seriesnumberblacklist)
and isnull(refformid,0)=0
GROUP BY usertxt2
HAVING(COUNT(*)>=20)
--客户资料表中的联系电话不能出现超过10次
INSERT INTO  t_seriesnumberblacklist(seriesnumber)
SELECT phonenumber1  FROM customers 
WHERE PhoneNumber1 NOT IN(SELECT seriesnumber FROM t_seriesnumberblacklist)
and isnull(PhoneNumber1,'')<>''
GROUP BY PhoneNumber1
HAVING COUNT(*)>=10
--客户资料表中的联系电话不能出现超过10次
INSERT INTO  t_seriesnumberblacklist(seriesnumber)
SELECT phonenumber  FROM customers 
WHERE PhoneNumber NOT IN(SELECT seriesnumber FROM t_seriesnumberblacklist)
and isnull(PhoneNumber,'')<>''
GROUP BY PhoneNumber
HAVING COUNT(*)>=10
--入网及裸机套包次数不得超过8次
INSERT INTO  t_seriesnumberblacklist(seriesnumber)
SELECT seriesnumber-- ,COUNT(*)
FROM Unicom_Orders uo
WHERE uo.SeriesNumber NOT IN(SELECT  SeriesNumber FROM t_seriesnumberblacklist)
GROUP BY uo.SeriesNumber
HAVING COUNT(*)>=8
--门店冲值总次数超过50次的限制之
INSERT INTO  t_seriesnumberblacklist(seriesnumber)
SELECT seriesnumber-- ,COUNT(*)
FROM BusinessAcceptance_H  uo
WHERE uo.SeriesNumber NOT IN(SELECT  SeriesNumber FROM t_seriesnumberblacklist)
and uo.FormID =9167
--AND uo.DocDate>=DATEADD(MONTH,-1,GETDATE())
AND intype='门店充值'
GROUP BY uo.SeriesNumber
HAVING COUNT(*)>=30

 