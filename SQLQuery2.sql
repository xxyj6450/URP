    
/*    
��������:plan_sellweekmanage    
����:Ӫ���ܴ����ͳ�Ʊ�      
����:����������    
��д:δ֪    
ʱ��:δ֪    
��ע:     
�޸�:���ϵ�    
�޸�ʱ��:2010/1/12    
��ע:    
 1.ԭ������д������,��д֮.�������Ƚϴ�,��ʱδд�������ͳ��,�����ŵ�͵����Ĳ�ѯҲδ���.    
 2.ϵͳ��ÿ��Ԥ���ܶ�Ӧ�ľ���ʱ������Ԥ��������(gBudgetWeek)�в�ѯ    
 3.��Ҫʹ��spickorderhd��spickorderitem��ͳ������,��Ϊ�˶���̫��,���Ӳ������ĺܴ�.ʹ��isaleledgerlog��Ͽ�    
 4.��ͳ��Ԥ����,�õ�����(��������),������isaleledgerlog��,�����ֿ������ٶȻ�ȽϿ�,��ΪisaleledgerlogҲ��С    
 5.ϵͳ����������Ѹ������,���Ӳ���������ϵͳ��Դ����Ҫ����,�����ֲ�����,������ʹ����ʱ������Table����(Ҳ����ʱ��)    
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
		--CTE����Ԥ����ͳ��
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

		--������Ԥ������
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

		--���������
		UPDATE @table
		SET weekmanage=100*weekfactsell/(CASE ISNULL(weekplansell,1) WHEN 0 THEN 1 ELSE weekplansell end),
		monthmanage=100*monthfactsell/(CASE ISNULL(monthplansell,1) WHEN 0 THEN 1 ELSE monthplansell end)
	RETURN      
END    
