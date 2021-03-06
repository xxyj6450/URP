/*
过程名称：sp_MatchStrategy_PackageMatScore
功能：套包商品积分计算过程
参数：见声名
返回：
编写：三断笛
时间：2012-02-23
备注：该过程的依照sp_MatchStrategy标准过程而实现。
示例：
----------------------------------------------
*/
alter proc sp_MatchStrategy_PackageMatScore
	@FormID varchar(50),			--功能号
	@Doccode VARCHAR(20),			--单号
	@FieldFormID varchar(50)='',	--字段映射功能号
	@StrategyGroup VARCHAR(20),		--策略组编码
	@RowFlag VARCHAR(500)='',		--行唯一标志
	@Optionid VARCHAR(100)='',		--选项
	@UserCode VARCHAR(50)='',		--执行人
	@TerminalID VARCHAR(50)='',		--终端编码
	@Result XML=''
AS
	BEGIN
		SET NOCOUNT ON;
		DECLARE @sql VARCHAR(MAX),@tips varchar(max)
		
		Insert Into #Strategy
		SELECT newID(), a.RowID,c.Doccode as StrategyCode,a.PackageName,c.RowID,c.Priority,NULL as StrategyFilter,c.Filter as DocFilter,
		c.Expression as StratetyValueExpression,Replicate('',500) as StratetyValue
		From #DataSource a, Strategy_DT c
		Where  c.Strategygroup=@StrategyGroup
		AND a.PackageID=c.Doccode
		AND (ISNULL(c.sdorgid,'')='' OR a.sdorgPath LIKE '%/'+c.sdorgid+'/%')
		AND (ISNULL(c.areaid,'')='' OR a.areaPath LIKE '%/'+c.areaid+'/%')
		and (isnull(c.Matcode,'')='' or a.matcode=c.matcode)
		and (isnull(c.matgroup,'')='' or exists(select 1 from split(c.matgroup,',') x where a.matgroupPath like '%/'+x.list+'/%'))
		and (isnull(c.seriescode,'')='' or a.seriescode=c.seriescode)
		update #Strategy
			set strategyfilter= commondb.dbo.REGEXP_Replace(strategyfilter, '(?<!&|'')((\d:)?[\u4e00-\u9fa5]+)(?!&|'')','&$1&'),
			StratetyValueExpression=commondb.dbo.REGEXP_Replace(StratetyValueExpression, '(?<!&|'')((\d:)?[\u4e00-\u9fa5]+)(?!&|'')','&$1&'),
			DocFilter=commondb.dbo.REGEXP_Replace(DocFilter, '(?<!&|'')((\d:)?[\u4e00-\u9fa5]+)(?!&|'')','&$1&')
		--过滤单据数据,注意此处活动行的使用.
		begin try
			DELETE from #Strategy
			WHERE convert(bit,dbo.ExecuteScalar(0,DocFilter, 'Select * From #DataSource','RowID='''+DocRowFlag+'''',-1,
			'Select * from fn_getFormulaFields('''+convert(varchar(50),COALESCE(@FieldFormID,@FormID,''))+''')',0))=0
			And Isnull(DocFilter,'')<>''
			 EXEC(@sql)
		end try
		begin catch
			select @tips='策略组'+@StrategyGroup+'执行失败。'+dbo.crlf()+
			'错误发生于'+error_procedure()+'第'+convert(varchar(10),error_line())+'行'+dbo.crlf()+
			error_message()
			raiserror(@tips,16,1)
			return
		end catch
		 --删除重复数据，只留下优先级值小的。
		  ;WITH cte AS( 
		  			SELECT  DocRowFlag,max(ISNULL(a.Strategypriority,0)) AS Strategypriority FROM  #Strategy a 
		  			GROUP BY DocRowFlag 
		 			) 
		 DELETE #Strategy FROM #Strategy a,cte b  
		 WHERE a.DocRowFlag=b.DocRowFlag  
		  AND ISNULL(a.Strategypriority,0)<b.Strategypriority

		 
	END
	go
	
 /*
过程名称：sp_MatchStrategy_PackageAllocationScore
功能：套包入网积分计算过程
参数：见声名
返回：
编写：三断笛
时间：2012-02-23
备注：该过程的依照sp_MatchStrategy标准过程而实现。
示例：
----------------------------------------------
*/
alter proc sp_MatchStrategy_PackageAllocationScore
	@FormID varchar(50),			--功能号
	@Doccode VARCHAR(20),			--单号
	@FieldFormID varchar(50)='',	--字段映射功能号
	@StrategyGroup VARCHAR(20),		--策略组编码
	@RowFlag VARCHAR(500)='',		--行唯一标志
	@Optionid VARCHAR(100)='',		--选项
	@UserCode VARCHAR(50)='',		--执行人
	@TerminalID VARCHAR(50)='',		--终端编码
	@Result XML=''
AS
	BEGIN
 
		SET NOCOUNT ON;
		DECLARE @sql VARCHAR(MAX),@tips varchar(max)
		 --select * From #datasource
		 Insert Into #Strategy
		SELECT newID(),a.doccode ,c.Doccode as StrategyCode,a.PackageName,c.RowID,c.Priority,NULL as StrategyFilter,c.Filter as DocFilter,
		c.Expression as StratetyValueExpression,Replicate('',500) as StratetyValue
		From #Datasource a,Strategy_Combo  c
		Where c.Strategygroup=@StrategyGroup
		AND a.PackageID=c.Doccode
		AND (ISNULL(c.sdorgid,'')='' OR a.sdorgPath LIKE '%/'+c.sdorgid+'/%')
		AND (ISNULL(c.areaid,'')='' OR a.areaPath LIKE '%/'+c.areaid+'/%')
		AND (ISNULL(c.ComboCode,'')='' OR a.combocode=c.ComboCode)
		--过滤单据数据,要注意使用活动行.
		DELETE from #Strategy
		WHERE  dbo.ExecuteScalar(0,DocFilter, 'Select * From #DocData','Doccode='''+DocRowFlag+'''',-1,
		'Select * from fn_getFormulaFields('''+convert(varchar(50),COALESCE(@FieldFormID,@FormID,''))+''')',0) =0
		And Isnull(DocFilter,'')<>'' 
		 --删除重复数据，只留下优先级值小的。本段亦可不使用动态SQL而直接写Delete。动态SQL只是为了保持与sp_MatchStrategy写法一致。
		 begin try
			 SET @sql =  '		;WITH cte AS( ' + char(10)
					 + '			SELECT DocRowFlag  ,max(ISNULL(a.Strategypriority,0)) AS Strategypriority FROM  #Strategy a ' + char(10)
					 + '			GROUP BY DocRowFlag'  + char(10)
					 + '			) ' + char(10)
					 + '		DELETE #Strategy FROM #Strategy a,cte b  ' + char(10)
					 + '		WHERE a.DocRowFlag=b.DocRowFlag ' + char(10)
					 + '		AND ISNULL(a.Strategypriority,0)<b.Strategypriority'
	 
			EXEC(@sql)  
		end try
		begin catch
			select @tips='策略组'+@StrategyGroup+'执行失败。'+dbo.crlf()+
			'错误发生于'+error_procedure()+'第'+convert(varchar(10),error_line())+'行'+dbo.crlf()+
			error_message()
			raiserror(@tips,16,1)
			return
		end catch
		UPDATE #Strategy	
			SET StratetyValueExpression= commondb.dbo.REGEXP_Replace(StratetyValueExpression, '(?<!&)((\d:)?[\u4e00-\u9fa5]+)(?!&)','&$1&')
 
	END
	GO
 /*
函数名称：fn_getAllocationScore
功能：获取普通入网积分
参数：见声名
返回：
编写：三断笛
时间：2012-02-24
备注：
示例：Select dbo.fn_getAllocationScore(9146,'PS20120224000002','1.1.769.02.02',10)
----------------------------------------------
*/
 alter FUNCTION fn_getAllocationScore(
	@FormID varchar(20),
	@Doccode VARCHAR(20),
	@sdorgid VARCHAR(50),
	@ComboCode VARCHAR(10)
 )
 RETURNS MONEY
 AS
	BEGIN
		DECLARE @ret MONEY
		--先匹配区域套餐设置
		SELECT TOP 1 @ret=a.score
		FROM  oSDOrg b  
		OUTER APPLY SPLIT(b.path,'/') c
		LEFT JOIN osdorg d ON c.list=d.SDOrgID
		inner join Combo_cfg a ON d.SDOrgID=a.SDOrgID
		WHERE   b.SDOrgID=@sdorgid
		AND a.ComboCode=@ComboCode
		AND a.score IS NOT NULL
		ORDER BY c.[LEVEL] desc
		IF @@ROWCOUNT<>0 RETURN @ret
		SELECT @ret=score FROM Combo_H ch WHERE ch.ComboCode=@ComboCode
		RETURN @ret
	END
	
 

	
 
	