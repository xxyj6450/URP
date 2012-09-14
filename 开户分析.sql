--�Ƶ�����һ���ύ����,���ŵ��Ƶ�ʱ��
WITH ctea as(
	--��һ���ύ��˼����һ���ύ���
	SELECT doccode,a.checktype,MIN(enterdate) AS min_enterdate,max(enterdate) AS MAX_enterdate,'�������' as checkstate 
	FROM CheckNumberAllocationDoc_LOG a  WITH(NOLOCK)
	WHERE a.checkstate='�������'
	AND a.checkType='�������'
	AND a.UserName<>'system'
	GROUP BY a.doccode,checktype
)
,cteb AS(
	--��һ��ͨ����˺����һ��ͨ�����
	SELECT doccode,'�������' as checktype,MIN(enterdate) AS min_enterdate,max(enterdate) AS MAX_enterdate,'ͨ�����' as checkstate 
	FROM CheckNumberAllocationDoc_LOG a  WITH(NOLOCK)
	WHERE a.checkstate='ͨ�����'
	AND a.checkType='�������'
	AND a.UserName<>'system'
	GROUP BY a.doccode
)
,ctec AS(
	--�˵�����
	SELECT   doccode,COUNT(*) AS returnCount
	FROM CheckNumberAllocationDoc_LOG a  WITH(NOLOCK)
	WHERE a.checkType='�������'
	AND a.checkstate='�˻�'
	AND a.UserName<>'system'
	GROUP BY doccode
)
,cted AS(
	--��һ������ʱ��
	SELECT doccode,MIN(enterdate) AS min_enterdate
	FROM CheckNumberAllocationDoc_LOG x  WITH(NOLOCK)
	WHERE x.checkstate='�������'
	AND x.UserName<>'system'
	GROUP BY doccode
)
,ctee AS(
	--�Ƶ�ʱ��
	SELECT doccode,MIN(enterdate) AS min_enterdate
	FROM CheckNumberAllocationDoc_LOG x WITH(NOLOCK)
	WHERE x.checkstate='��������'
	AND x.UserName<>'system'
	GROUP BY doccode
)
,ctef AS(
	SELECT 0 as id,'3��������' as name,0 AS min_Num,3 AS max_num
	UNION ALL
	SELECT 1 as id,'5��������' as name,3 AS min_Num,5 AS max_num
	UNION ALL
	SELECT 2,'10��������',5,10
	UNION ALL
	SELECT 3,'15��������',10,15
	UNION ALL
	SELECT 4,'20��������',15,20
	UNION ALL
	SELECT 5,'30��������',20,30
	UNION ALL
	SELECT 6,'40��������',30,40
	UNION ALL
	SELECT 7,'50��������',40,50
	UNION ALL
	SELECT 8,'60��������',50,60
	UNION ALL
	SELECT 9,'60����',60,10000
)
,cteg AS(
	SELECT 0 as id,'3��������' as name,0 AS min_Num,2 AS max_num
	UNION ALL
	SELECT 1 as id,'5��������' as name,2 AS min_Num,4 AS max_num
	UNION ALL
	SELECT 2,'10��������',4,8
	UNION ALL
	SELECT 3,'15��������',8,10
	UNION ALL
	SELECT 4,'20��������',10,12
	UNION ALL
	SELECT 5,'30��������',12,14
	UNION ALL
	SELECT 6,'40��������',14,16
	UNION ALL
	SELECT 7,'50��������',16,18
	UNION ALL
	SELECT 8,'60��������',18,20
	UNION ALL
	SELECT 9,'60����',20,10000
)
,cte as (
	--�Ƶ�����
	SELECT a.doccode,a.enterdate AS begindate,b.min_enterdate AS enddate,os.AreaID,datediff(day,os.signeddate,GETDATE()) AS signeddate
	FROM CheckNumberAllocationDoc_LOG a  WITH(NOLOCK)
	LEFT JOIN ctea b ON a.doccode=b.doccode AND a.checkType=b.checkType AND a.checkstate='��������' and b.checkstate='�������'
	LEFT JOIN oSDOrg os ON a.sdorgid=os.SDOrgID
	WHERE a.checkType='�������'
	AND EXISTS(SELECT 1 FROM CheckNumberAllocationDoc_LOG x  WITH(NOLOCK) WHERE x.doccode=a.doccode AND x.checkstate='ͨ�����')
	--AND DATEDIFF(minute,a.enterdate,b.min_enterdate)<=3		--С��59����
	AND a.enterdate IS NOT NULL
	AND b.min_enterdate IS NOT NULL
	--and DATEDIFF(minute,a.enterdate,b.min_enterdate)=59
	AND a.doccode LIKE 'RS%'
	)
,cte1 as (
	--������
	SELECT a.doccode,a.min_enterdate AS begindate,b.max_enterdate AS enddate,c.returncount
	FROM ctea a
	LEFT JOIN cteb b ON a.doccode=b.doccode
	LEFT JOIN ctec c ON a.doccode=c.doccode
	where   a.doccode LIKE 'RS%'
	and DATEDIFF(minute,a.min_enterdate,b.max_enterdate)<=30		--С��59����
	AND a.min_enterdate IS NOT NULL
	AND b.max_enterdate IS NOT NULL
	--and DATEDIFF(minute,a.enterdate,b.min_enterdate)=59
	AND DAY(a.min_enterdate)=DAY(b.max_enterdate)				--�ᵥʱ������ʱ����յĲ�ͳ��
	)
,cte2 as (
	--��������
	SELECT a.doccode,a.min_enterdate AS begindate,b.min_enterdate AS enddate
	FROM ctea a
	LEFT JOIN cted b ON a.doccode=b.doccode
	where   a.doccode LIKE 'RS%'
	and DATEDIFF(second,a.min_enterdate,b.min_enterdate)>1200		--С��59����
	AND a.min_enterdate IS NOT NULL
	AND b.min_enterdate IS NOT NULL
	--and DATEDIFF(minute,a.enterdate,b.min_enterdate)=59
	AND DAY(a.min_enterdate)=DAY(b.min_enterdate)				--�ᵥʱ������ʱ����յĲ�ͳ��
)
,cte3 as (
	--���忪��ʱ��
	SELECT a.doccode,a.min_enterdate AS begindate,b.max_enterdate AS enddate,c.returncount
	FROM ctee a					--�Ƶ�ʱ��
	LEFT JOIN cteb b ON a.doccode=b.doccode			--��ʱ��
	LEFT JOIN ctec c ON a.doccode=c.doccode			--�˵���Ϣ
	where   a.doccode LIKE 'RS%'
	and DATEDIFF(minute,a.min_enterdate,b.max_enterdate)>100		--С��59����
	AND a.min_enterdate IS NOT NULL
	AND b.max_enterdate IS NOT NULL
	--and DATEDIFF(minute,a.enterdate,b.min_enterdate)=59
	AND DAY(a.min_enterdate)=DAY(b.max_enterdate)				--�ᵥʱ������ʱ����յĲ�ͳ��
)
,cte4 as(--���������Ƶ���
	SELECT LEFT(a.areaid,3) AS areaid,COUNT(*) AS salescount
	FROM cte a
	GROUP BY LEFT(a.areaid,3)
	
 )
,cte_�Ƶ�ʱ�� as(SELECT f.id,f.name, avg(DATEDIFF(minute,begindate,enddate)) as 'ƽ���Ƶ�ʱ��' ,
				--var(DATEDIFF(minute,begindate,enddate)) as '�Ƶ�ʱ�䷽��' ,
				--varp(DATEDIFF(minute,begindate,enddate)) as '�Ƶ�ʱ�����巽��' ,
				stdev(DATEDIFF(minute,begindate,enddate)) as '�Ƶ�ʱ���׼��' ,
				--STDEVP(DATEDIFF(minute,begindate,enddate)) as '�Ƶ�ʱ�������׼��' ,
				count(*) as '����' 
					FROM cte a right join ctef f on (DATEDIFF(minute,begindate,enddate)) BETWEEN f.min_num and f.max_num 
					--where f.id<=8
                 group by f.id,f.name)
 ,cte_�Ƶ�ʱ�����15���� as(SELECT left(a.areaid,3) as '����', avg(DATEDIFF(minute,begindate,enddate)) as 'ƽ���Ƶ�ʱ��' ,
 
				stdev(DATEDIFF(minute,begindate,enddate)) as '�Ƶ�ʱ���׼��' ,
				var(DATEDIFF(minute,begindate,enddate)) as '�Ƶ�ʱ�䷽��',
				count(*) as '����',max(b.salescount)
				FROM cte a
				LEFT JOIN cte4 b ON  left(a.areaid,3)=b.areaid
                            WHERE  DATEDIFF(minute,begindate,enddate) between 15 AND 60
                 group by left(a.areaid,3)
 )
      
,cte_��ʱ�� as(SELECT avg(DATEDIFF(minute,begindate,enddate)) as 'ƽ����ʱ��',sum(returncount) as '�˵�����',count(*) as '����' FROM cte1 a
	where NOT EXISTS(SELECT 1 FROM CheckNumberAllocationDoc_LOG x WITH(NOLOCK) WHERE x.doccode=a.doccode AND x.checkstate='�˻�')			--�����˵�
	--AND doccode<'RS20120726'
)
,cte_����ʱ�� as(SELECT avg(DATEDIFF(second,begindate,enddate)) as 'ƽ������ʱ��' ,count(*) as '����' FROM cte2)
,cte_����ʱ�� as(SELECT avg(DATEDIFF(minute,begindate,enddate)) as 'ƽ������ʱ��' ,sum(returncount) as '�˵�����',count(*) as '����' FROM cte3)
--SELECT * FROM cte_�Ƶ�ʱ�� a order by id
SELECT * FROM cte_�Ƶ�ʱ�����15����
--SELECT * FROM cte_����ʱ��
--SELECT * FROM cte_����ʱ��
--SELECT * FROM cte_����ʱ��

 

SELECT a.reason,COUNT(*) FROM CheckNumberAllocationDoc_LOG a
WHERE a.doccode LIKE 'RS%'
AND a.checkstate='�˻�'
GROUP BY a.reason
ORDER BY 2 DESC

PRINT 22613-18135

--�˵�����
SELECT  COUNT(*),
SUM(CASE WHEN a.remark LIKE '%֤%' THEN 1 ELSE 0 END) as '֤��������', 
SUM(CASE WHEN a.remark LIKE '%��%' THEN 1 ELSE 0 END) as 'SIM��������' ,
SUM(CASE WHEN a.remark LIKE '%�ն�%' THEN 1 ELSE 0 END) as '�ն˴�����',
SUM(CASE WHEN a.remark LIKE '%����%' THEN 1 ELSE 0 END) as '���������',
SUM(CASE WHEN a.remark LIKE '%Э��%' THEN 1 ELSE 0 END) as 'Э�������',
SUM(CASE 
		WHEN a.remark LIKE '%������%' THEN 1
		WHEN a.remark LIKE '%Ƿ��%' THEN 1
		WHEN a.remark LIKE '%��%' then 1
		WHEN a.remark LIKE '%һ��%' THEN 1
		WHEN a.remark LIKE '%����%' THEN 1
		WHEN a.remark LIKE '%����%' THEN 1
		WHEN a.remark LIKE '%�Ļ�%' THEN 1
		WHEN a.remark LIKE '%�廧%' then 1
		ELSE 0 END) as '�û��쳣',
SUM(CASE 
	WHEN a.remark LIKE '%�װ�%' THEN 1 
	WHEN a.remark LIKE '%Ԥ��%' THEN 1 
	WHEN a.remark LIKE '%���%' THEN 1
	ELSE 0 END) as '�Ƶ�������'
FROM CheckNumberAllocationDoc_LOG a
WHERE a.doccode LIKE 'RS%'
AND a.checkstate='�˻�'
ORDER BY 2 DESC
