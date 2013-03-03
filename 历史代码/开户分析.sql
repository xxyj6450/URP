--制单到第一次提交单据,即门店制单时间
WITH ctea as(
	--第一次提交审核及最后一次提交审核
	SELECT doccode,a.checktype,MIN(enterdate) AS min_enterdate,max(enterdate) AS MAX_enterdate,'请求审核' as checkstate 
	FROM CheckNumberAllocationDoc_LOG a  WITH(NOLOCK)
	WHERE a.checkstate='请求审核'
	AND a.checkType='开户审核'
	AND a.UserName<>'system'
	GROUP BY a.doccode,checktype
)
,cteb AS(
	--第一次通过审核和最后一次通过审核
	SELECT doccode,'开户审核' as checktype,MIN(enterdate) AS min_enterdate,max(enterdate) AS MAX_enterdate,'通过审核' as checkstate 
	FROM CheckNumberAllocationDoc_LOG a  WITH(NOLOCK)
	WHERE a.checkstate='通过审核'
	AND a.checkType='开户审核'
	AND a.UserName<>'system'
	GROUP BY a.doccode
)
,ctec AS(
	--退单次数
	SELECT   doccode,COUNT(*) AS returnCount
	FROM CheckNumberAllocationDoc_LOG a  WITH(NOLOCK)
	WHERE a.checkType='开户审核'
	AND a.checkstate='退回'
	AND a.UserName<>'system'
	GROUP BY doccode
)
,cted AS(
	--第一次锁单时间
	SELECT doccode,MIN(enterdate) AS min_enterdate
	FROM CheckNumberAllocationDoc_LOG x  WITH(NOLOCK)
	WHERE x.checkstate='锁定审核'
	AND x.UserName<>'system'
	GROUP BY doccode
)
,ctee AS(
	--制单时间
	SELECT doccode,MIN(enterdate) AS min_enterdate
	FROM CheckNumberAllocationDoc_LOG x WITH(NOLOCK)
	WHERE x.checkstate='创建单据'
	AND x.UserName<>'system'
	GROUP BY doccode
)
,ctef AS(
	SELECT 0 as id,'3分钟以内' as name,0 AS min_Num,3 AS max_num
	UNION ALL
	SELECT 1 as id,'5分钟以内' as name,3 AS min_Num,5 AS max_num
	UNION ALL
	SELECT 2,'10分钟以内',5,10
	UNION ALL
	SELECT 3,'15分钟以内',10,15
	UNION ALL
	SELECT 4,'20分钟以内',15,20
	UNION ALL
	SELECT 5,'30分钟以内',20,30
	UNION ALL
	SELECT 6,'40分钟以内',30,40
	UNION ALL
	SELECT 7,'50分钟以内',40,50
	UNION ALL
	SELECT 8,'60分钟以内',50,60
	UNION ALL
	SELECT 9,'60以上',60,10000
)
,cteg AS(
	SELECT 0 as id,'3分钟以内' as name,0 AS min_Num,2 AS max_num
	UNION ALL
	SELECT 1 as id,'5分钟以内' as name,2 AS min_Num,4 AS max_num
	UNION ALL
	SELECT 2,'10分钟以内',4,8
	UNION ALL
	SELECT 3,'15分钟以内',8,10
	UNION ALL
	SELECT 4,'20分钟以内',10,12
	UNION ALL
	SELECT 5,'30分钟以内',12,14
	UNION ALL
	SELECT 6,'40分钟以内',14,16
	UNION ALL
	SELECT 7,'50分钟以内',16,18
	UNION ALL
	SELECT 8,'60分钟以内',18,20
	UNION ALL
	SELECT 9,'60以上',20,10000
)
,cte as (
	--制单数据
	SELECT a.doccode,a.enterdate AS begindate,b.min_enterdate AS enddate,os.AreaID,datediff(day,os.signeddate,GETDATE()) AS signeddate
	FROM CheckNumberAllocationDoc_LOG a  WITH(NOLOCK)
	LEFT JOIN ctea b ON a.doccode=b.doccode AND a.checkType=b.checkType AND a.checkstate='创建单据' and b.checkstate='请求审核'
	LEFT JOIN oSDOrg os ON a.sdorgid=os.SDOrgID
	WHERE a.checkType='开户审核'
	AND EXISTS(SELECT 1 FROM CheckNumberAllocationDoc_LOG x  WITH(NOLOCK) WHERE x.doccode=a.doccode AND x.checkstate='通过审核')
	--AND DATEDIFF(minute,a.enterdate,b.min_enterdate)<=3		--小于59分钟
	AND a.enterdate IS NOT NULL
	AND b.min_enterdate IS NOT NULL
	--and DATEDIFF(minute,a.enterdate,b.min_enterdate)=59
	AND a.doccode LIKE 'RS%'
	)
,cte1 as (
	--审单数据
	SELECT a.doccode,a.min_enterdate AS begindate,b.max_enterdate AS enddate,c.returncount
	FROM ctea a
	LEFT JOIN cteb b ON a.doccode=b.doccode
	LEFT JOIN ctec c ON a.doccode=c.doccode
	where   a.doccode LIKE 'RS%'
	and DATEDIFF(minute,a.min_enterdate,b.max_enterdate)<=30		--小于59分钟
	AND a.min_enterdate IS NOT NULL
	AND b.max_enterdate IS NOT NULL
	--and DATEDIFF(minute,a.enterdate,b.min_enterdate)=59
	AND DAY(a.min_enterdate)=DAY(b.max_enterdate)				--提单时间与审单时间跨日的不统计
	)
,cte2 as (
	--锁单数据
	SELECT a.doccode,a.min_enterdate AS begindate,b.min_enterdate AS enddate
	FROM ctea a
	LEFT JOIN cted b ON a.doccode=b.doccode
	where   a.doccode LIKE 'RS%'
	and DATEDIFF(second,a.min_enterdate,b.min_enterdate)>1200		--小于59分钟
	AND a.min_enterdate IS NOT NULL
	AND b.min_enterdate IS NOT NULL
	--and DATEDIFF(minute,a.enterdate,b.min_enterdate)=59
	AND DAY(a.min_enterdate)=DAY(b.min_enterdate)				--提单时间与审单时间跨日的不统计
)
,cte3 as (
	--整体开户时间
	SELECT a.doccode,a.min_enterdate AS begindate,b.max_enterdate AS enddate,c.returncount
	FROM ctee a					--制单时间
	LEFT JOIN cteb b ON a.doccode=b.doccode			--审单时间
	LEFT JOIN ctec c ON a.doccode=c.doccode			--退单信息
	where   a.doccode LIKE 'RS%'
	and DATEDIFF(minute,a.min_enterdate,b.max_enterdate)>100		--小于59分钟
	AND a.min_enterdate IS NOT NULL
	AND b.max_enterdate IS NOT NULL
	--and DATEDIFF(minute,a.enterdate,b.min_enterdate)=59
	AND DAY(a.min_enterdate)=DAY(b.max_enterdate)				--提单时间与审单时间跨日的不统计
)
,cte4 as(--各区域总制单量
	SELECT LEFT(a.areaid,3) AS areaid,COUNT(*) AS salescount
	FROM cte a
	GROUP BY LEFT(a.areaid,3)
	
 )
,cte_制单时间 as(SELECT f.id,f.name, avg(DATEDIFF(minute,begindate,enddate)) as '平均制单时间' ,
				--var(DATEDIFF(minute,begindate,enddate)) as '制单时间方差' ,
				--varp(DATEDIFF(minute,begindate,enddate)) as '制单时间总体方差' ,
				stdev(DATEDIFF(minute,begindate,enddate)) as '制单时间标准差' ,
				--STDEVP(DATEDIFF(minute,begindate,enddate)) as '制单时间总体标准差' ,
				count(*) as '数量' 
					FROM cte a right join ctef f on (DATEDIFF(minute,begindate,enddate)) BETWEEN f.min_num and f.max_num 
					--where f.id<=8
                 group by f.id,f.name)
 ,cte_制单时间大于15分钟 as(SELECT left(a.areaid,3) as '区域', avg(DATEDIFF(minute,begindate,enddate)) as '平均制单时间' ,
 
				stdev(DATEDIFF(minute,begindate,enddate)) as '制单时间标准差' ,
				var(DATEDIFF(minute,begindate,enddate)) as '制单时间方差',
				count(*) as '数量',max(b.salescount)
				FROM cte a
				LEFT JOIN cte4 b ON  left(a.areaid,3)=b.areaid
                            WHERE  DATEDIFF(minute,begindate,enddate) between 15 AND 60
                 group by left(a.areaid,3)
 )
      
,cte_审单时间 as(SELECT avg(DATEDIFF(minute,begindate,enddate)) as '平均审单时间',sum(returncount) as '退单次数',count(*) as '总数' FROM cte1 a
	where NOT EXISTS(SELECT 1 FROM CheckNumberAllocationDoc_LOG x WITH(NOLOCK) WHERE x.doccode=a.doccode AND x.checkstate='退回')			--不含退单
	--AND doccode<'RS20120726'
)
,cte_锁单时间 as(SELECT avg(DATEDIFF(second,begindate,enddate)) as '平均锁单时间' ,count(*) as '数量' FROM cte2)
,cte_开单时间 as(SELECT avg(DATEDIFF(minute,begindate,enddate)) as '平均开单时间' ,sum(returncount) as '退单次数',count(*) as '总数' FROM cte3)
--SELECT * FROM cte_制单时间 a order by id
SELECT * FROM cte_制单时间大于15分钟
--SELECT * FROM cte_开单时间
--SELECT * FROM cte_锁单时间
--SELECT * FROM cte_开单时间

 

SELECT a.reason,COUNT(*) FROM CheckNumberAllocationDoc_LOG a
WHERE a.doccode LIKE 'RS%'
AND a.checkstate='退回'
GROUP BY a.reason
ORDER BY 2 DESC

PRINT 22613-18135

--退单分析
SELECT  COUNT(*),
SUM(CASE WHEN a.remark LIKE '%证%' THEN 1 ELSE 0 END) as '证件错误数', 
SUM(CASE WHEN a.remark LIKE '%卡%' THEN 1 ELSE 0 END) as 'SIM卡错误数' ,
SUM(CASE WHEN a.remark LIKE '%终端%' THEN 1 ELSE 0 END) as '终端错误数',
SUM(CASE WHEN a.remark LIKE '%号码%' THEN 1 ELSE 0 END) as '号码错误数',
SUM(CASE WHEN a.remark LIKE '%协议%' THEN 1 ELSE 0 END) as '协议错误数',
SUM(CASE 
		WHEN a.remark LIKE '%黑名单%' THEN 1
		WHEN a.remark LIKE '%欠费%' THEN 1
		WHEN a.remark LIKE '%虚%' then 1
		WHEN a.remark LIKE '%一户%' THEN 1
		WHEN a.remark LIKE '%二户%' THEN 1
		WHEN a.remark LIKE '%三户%' THEN 1
		WHEN a.remark LIKE '%四户%' THEN 1
		WHEN a.remark LIKE '%五户%' then 1
		ELSE 0 END) as '用户异常',
SUM(CASE 
	WHEN a.remark LIKE '%套包%' THEN 1 
	WHEN a.remark LIKE '%预存%' THEN 1 
	WHEN a.remark LIKE '%金额%' THEN 1
	ELSE 0 END) as '制单错误数'
FROM CheckNumberAllocationDoc_LOG a
WHERE a.doccode LIKE 'RS%'
AND a.checkstate='退回'
ORDER BY 2 DESC
