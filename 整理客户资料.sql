--����ҵ��ͻ���������ϵ�绰���ܳ���20��
INSERT INTO  t_seriesnumberblacklist(seriesnumber)
SELECT usertxt2  FROM sPickorderHD sph
WHERE sph.FormID IN(2419,2420)
AND isnull(usertxt2,'')<>''
AND usertxt2 NOT IN(SELECT seriesnumber FROM t_seriesnumberblacklist)
and isnull(refformid,0)=0
GROUP BY usertxt2
HAVING(COUNT(*)>=20)
--�ͻ����ϱ��е���ϵ�绰���ܳ��ֳ���10��
INSERT INTO  t_seriesnumberblacklist(seriesnumber)
SELECT phonenumber1  FROM customers 
WHERE PhoneNumber1 NOT IN(SELECT seriesnumber FROM t_seriesnumberblacklist)
and isnull(PhoneNumber1,'')<>''
GROUP BY PhoneNumber1
HAVING COUNT(*)>=10
--�ͻ����ϱ��е���ϵ�绰���ܳ��ֳ���10��
INSERT INTO  t_seriesnumberblacklist(seriesnumber)
SELECT phonenumber  FROM customers 
WHERE PhoneNumber NOT IN(SELECT seriesnumber FROM t_seriesnumberblacklist)
and isnull(PhoneNumber,'')<>''
GROUP BY PhoneNumber
HAVING COUNT(*)>=10
--����������װ��������ó���8��
INSERT INTO  t_seriesnumberblacklist(seriesnumber)
SELECT seriesnumber-- ,COUNT(*)
FROM Unicom_Orders uo
WHERE uo.SeriesNumber NOT IN(SELECT  SeriesNumber FROM t_seriesnumberblacklist)
GROUP BY uo.SeriesNumber
HAVING COUNT(*)>=8
--�ŵ��ֵ�ܴ�������50�ε�����֮
INSERT INTO  t_seriesnumberblacklist(seriesnumber)
SELECT seriesnumber-- ,COUNT(*)
FROM BusinessAcceptance_H  uo
WHERE uo.SeriesNumber NOT IN(SELECT  SeriesNumber FROM t_seriesnumberblacklist)
and uo.FormID =9167
--AND uo.DocDate>=DATEADD(MONTH,-1,GETDATE())
AND intype='�ŵ��ֵ'
GROUP BY uo.SeriesNumber
HAVING COUNT(*)>=30

 