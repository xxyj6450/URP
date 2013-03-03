    
/*    
函数名称:plan_sellweekmanage    
描述:营销周达成率统计表      
参数:见声明部分    
编写:未知    
时间:未知    
备注:     
修改:三断笛    
修改时间:2010/1/12    
备注:    
 1.原函数编写不完整,重写之.数据量比较大,暂时未写月完成量统计,基于门店和地区的查询也未完成.    
 2.系统中每个预算周对应的具体时间在周预算年历表(gBudgetWeek)中查询    
 3.不要使用spickorderhd和spickorderitem来统计销量,因为此二表太大,连接操作消耗很大.使用isaleledgerlog会较快    
 4.先统计预算量,得到数据(数量较少),再连接isaleledgerlog表,这样分开连接速度会比较快,因为isaleledgerlog也不小    
 5.系统数据量正在迅速增长,连接操作是消耗系统资源的重要因素,尽量分步连接,尽量少使用临时表及定义Table变量(也是临时表)    
 select * from osdorg    
select * from dbo.plan_sellweekmanage1('2010','2','1','','','4401','')    
*/    
alter  FUNCTION [dbo].[plan_sellweekmanage1] (
	@pyear VARCHAR(4) ,
	@pmonth VARCHAR(2) ,
	@pweek VARCHAR(1) ,
	@matgroup VARCHAR(50) ,
	@matcode VARCHAR(50) ,
	@areaid VARCHAR(20) ,
	@sdorgid VARCHAR(20) )
RETURNS @table TABLE (
			sdorgid VARCHAR(20),
			sdorgname VARCHAR(60),
			matgroup VARCHAR(50) ,
			matcode VARCHAR(50) ,
			matname VARCHAR(50) ,
			weekplansell MONEY ,
			weekfactsell MONEY ,
			weekmanage MONEY ,
			monthplansell MONEY ,
			monthfactsell MONEY ,
			monthmanage MONEY,
			areaid VARCHAR(20))
	BEGIN      
		--CTE定义预算周统计
		WITH sta_bugetPerWeek(budgetyear,budgetmonth,cltcode,matcode,matname,fmdigit,ftdigit,fwdigit,fthdigit,ffdigit)
			AS(
				SELECT budgety,budgetm,cltcode,matcode,matname,
				CASE budgetw1 	WHEN 1 THEN ISNULL(bqdigit,0) ELSE 0 END,
				CASE budgetw1 	WHEN 2 THEN ISNULL(bqdigit,0) ELSE 0 END,
				CASE budgetw1 	WHEN 3 THEN ISNULL(bqdigit,0) ELSE 0 END,
				CASE budgetw1 	WHEN 4 THEN ISNULL(bqdigit,0) ELSE 0 END,
				CASE budgetw1 	WHEN 5 THEN ISNULL(bqdigit,0) ELSE 0 END
				FROM BU_weeksellbudgethd a ,dbo.BU_weeksellbudgetitem b
				WHERE a.doccode=b.doccode
				AND budgety>=2010
				AND formid=6300
				--AND cltcode='LYYF0004'
		)

		INSERT INTO @table( matcode,matname,matgroup,sdorgid,
			sdorgname,weekplansell,weekfactsell,monthplansell, monthfactsell,areaid)
		SELECT a.matcode,b.matname,a.matgroup,a.sdorgid,a.sdorgname,
		(CASE @pweek
			WHEN 1 THEN fmdigit
			WHEN 2 THEN ftdigit
			WHEN 3 THEN fwdigit
			WHEN 4 THEN fthdigit
			WHEN 5 THEN ffdigit
		END) AS weekplansell,
		(CASE @pweek
			WHEN 1 THEN salesCount1
			WHEN 2 THEN salesCount2
			WHEN 3 THEN salesCount3
			WHEN 4 THEN salesCount4
			WHEN 5 THEN salesCount5
		END) AS weekfactsell,
		fmdigit+ftdigit+fwdigit+fthdigit+ffdigit,
		salesCount1+salesCount2+salesCount3+salesCount4+salesCount5 AS monthfactsell,areaid
		FROM sta_MatSalesPerWeek a
/*
		LEFT JOIN sta_bugetPerWeek b  ON b.cltcode=a.SDOrgid AND b.budgety=a.budgetyear AND b.budgetm=a.budgetmonth
		INNER JOIN BU_weeksellbudgetitem c ON b.doccode=c.doccode AND a.matcode=c.matcode
		WHERE a.budgetyear=@pyear
		AND a.budgetmonth=@pmonth
		AND b.budgetW1=@pweek
		AND b.formid=6300
*/
		LEFT JOIN sta_bugetPerWeek b ON a.matcode=b.matcode AND a.SDOrgid=b.cltcode AND a.budgetyear=b.budgetyear AND a.budgetmonth=b.budgetmonth
		WHERE a.budgetyear=@pyear
		AND a.budgetmonth=@pmonth
		AND (@matcode='' or EXISTS(SELECT 1 FROM getinstr(@matcode) WHERE a.matcode LIKE '%'+list +'%'))
		AND (@matgroup='' or EXISTS(SELECT 1 FROM getinstr(@matgroup) WHERE a.matgroup LIKE '%'+list +'%'))
		AND (@sdorgid='' or EXISTS(SELECT 1 FROM getinstr(@sdorgid) WHERE a.sdorgid =list ))
		AND (@areaid='' or EXISTS(SELECT 1 FROM getinstr(@areaid) WHERE a.areaid =list))

		--更新周预算数据
/*
  UPDATE @table
    SET matname = c.matname, weekplansell = c.bqdigit

    FROM @table a
-- select * from sta_MatSalesPerWeek a
    LEFT JOIN BU_weeksellbudgethd b ON ( a.budgetyear = b.budgety
                                         AND a.budgetmonth = b.budgetm
                                         AND  b.budgetw1=1
                                         AND a.sdorgid = b.cltcode ) 
    INNER JOIN BU_weeksellbudgetitem c ON b.doccode = c.doccode
    WHERE a.matcode = c.matcode
        AND b.formid = 6300

return
*/

		--更新完成率
		UPDATE @table
		SET weekmanage=100*weekfactsell/(CASE ISNULL(weekplansell,1) WHEN 0 THEN 1 ELSE weekplansell end),
		monthmanage=100*monthfactsell/(CASE ISNULL(monthplansell,1) WHEN 0 THEN 1 ELSE monthplansell end)
	RETURN      
END    
