SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
过程名称：sp_MatchStrategy
功能：策略处理接口
参数：见声名
返回：
编写：三断笛
时间：2012-02-18
备注：在此过程中，可以引用#DataSource数据源和#StrategyGroup策略数据。
	其中#Strategygroup策略数据已经包含数据源。将计算后的结果输出至#Strategy临时表
示例：
----------------------------------------------
*/
ALTER PROC [sp_MatchStrategy]
	@FormID INT,											--功能号
	@Doccode VARCHAR(20),									--单号
	@FieldFormID varchar(10)='',							--字段映射功能号
	@StrategyGroup VARCHAR(20),								--策略组编码
	@RowFlag VARCHAR(500)='',								--行唯一标志
	@Optionid VARCHAR(100)='',								--选项
	@UserCode VARCHAR(50)='',								--执行人
	@TerminalID VARCHAR(50)='',								--终端编码
	@Result XML=''
AS
	BEGIN
		set nocount on;
		Declare  @sql VARCHAR(MAX),@tips varchar(max)
		--接下来匹配策略
		SET @sql = 'Insert Into #Strategy ' + char(10)
         + '		SELECT  NewID(),a.'+@rowFlag+',b.Doccode as StrategyCode,b.StrategyName,c.RowID,c.Priority,b.Filter as StrategyFilter,c.Filter as DocFilter,'+char(10)
         +'			c.Expression as StratetyValueExpression,Replicate('''',500) as StratetyValue ' + char(10)
         + '		From #Datasource a,Strategy_HD b,Strategy_DT c ' + char(10)
         + '		Where b.Strategygroup='''+@StrategyGroup +'''' + char(10)
         + '		and b.Doccode=c.Doccode ' + char(10)
         + '		And (ISNULL(b.beginday,'''')='''' OR b.beginday<=a.docdate) ' + char(10)
         + '		AND (ISNULL(b.endday,'''')='''' OR b.endday>=a.docdate) ' + char(10)
         + '		AND b.[enable]=1 ' + char(10)
         + '		AND (ISNULL(b.sdorgid,'''')='''' OR exists(select 1 from split(b.sdorgid,'','') x where a.sdorgPath LIKE ''%/''+x.list+''/%'')) ' + char(10)
         + '		AND (ISNULL(b.areaid,'''')='''' OR exists(select 1 from split(b.areaid,'','') x where a.areaPath LIKE ''%/''+x.list+''/%'')) ' + char(10)
         + '		and (Isnull(b.CompanyID,'''')='''' or exists(select 1 From split(b.companyid,'','') x where x.list=a.CompanyID)) ' + char(10)
         + '		and (isnull(c.Matcode,'''')='''' or a.matcode=c.matcode) ' + char(10)
         + '		and (isnull(c.matgroup,'''')='''' or exists(select 1 from split(c.matgroup,'','') x where a.matgroupPath like ''%/''+x.list+''/%'')) ' + char(10)
         + '		and (isnull(c.seriescode,'''')='''' or a.seriescode=c.seriescode) ' + char(10)
         + '		AND (ISNULL(c.sdorgid,'''')='''' OR a.sdorgPath LIKE ''%/''+c.sdorgid+''/%'') ' + char(10)
         + '		AND (ISNULL(c.areaid,'''')='''' OR exists(select 1 from split(c.areaid,'','') x where a.areaPath LIKE ''%/''+x.list+''/%'')) ' + char(10)
         + '		AND (ISNULL(c.ComboCode,'''')='''' OR a.combocode=c.ComboCode) ' + char(10)
         + '		AND (ISNULL(b.PackageID,'''')='''' OR EXISTS(SELECT 1 FROM SPLIT(ISNULL(b.PackageID,''''),'','') x WHERE x.list=a.packageid))' +CHAR(10)
 
           EXEC(@sql)	  
 
	END
