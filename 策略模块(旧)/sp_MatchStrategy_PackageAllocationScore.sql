SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
	
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
ALTER proc [sp_MatchStrategy_PackageAllocationScore]
	@FormID varchar(50),			--功能号
	@Doccode VARCHAR(20),			--单号
	@FieldFormID varchar(50)='',	--字段映射功能号
	@StrategyGroup VARCHAR(20),		--策略组编码
	@MatchType VARCHAR(20)='1',		--匹配模式
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
		AND ISNULL(c.Valid,0)=1
		AND (ISNULL(c.Begindate,'')='' OR c.Begindate<=a.docDate)
		AND (ISNULL(c.Enddate,'')='' OR c.Enddate>=a.docdate)
		AND (ISNULL(c.sdorgid,'')='' OR a.sdorgPath LIKE '%/'+c.sdorgid+'/%')
		AND (ISNULL(c.areaid,'')='' OR a.areaPath LIKE '%/'+c.areaid+'/%')
		AND (ISNULL(c.ComboCode,'')='' OR a.combocode=c.ComboCode)
	END
