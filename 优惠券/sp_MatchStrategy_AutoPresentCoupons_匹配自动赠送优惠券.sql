 /*
过程名称：[sp_MatchStrategy_AutoPresentCoupons]
功能：套包入网积分计算过程
参数：见声名
返回：
编写：三断笛
时间：2012-02-23
备注：该过程的依照sp_MatchStrategy标准过程而实现。
示例：
----------------------------------------------
*/
alter proc [sp_MatchStrategy_AutoPresentCoupons]
	@FormID varchar(50),												--功能号
	@Doccode VARCHAR(20),										--单号
	@FieldFormID varchar(50)='',									--字段映射功能号
	@StrategyGroup VARCHAR(20),								--策略组编码
	@MatchType VARCHAR(20)='1',								--匹配模式
	@RowFlag VARCHAR(500)='',									--行唯一标志
	@Optionid VARCHAR(100)='',									--选项
	@UserCode VARCHAR(50)='',									--执行人
	@TerminalID VARCHAR(50)='',								--终端编码
	@Result XML=''
AS
	BEGIN
 
		SET NOCOUNT ON;
		DECLARE @sql VARCHAR(MAX),@tips varchar(max)
		 Insert Into #Strategy
		SELECT newID(),a.rowid ,c.couponscode as StrategyCode,c.CouponsName,d.RowID,d.Priority,c.PresentFilter as StrategyFilter,d.Filter as DocFilter,
		c.PresentCount as StrategyValueExpression,Replicate('',500) as StrategyValue
		From #Datasource a  left join iCouponsGeneral    c WITH(NOLOCK) ON c.SourceMode='3'
		LEFT JOIN Strategy_Coupons d  WITH(NOLOCK) ON c.couponscode=d.CouponsCode AND d.Straytegygroup='02.01.01'							--此处注意用LEFT JOIN,因为没有设置规则时，默认为不限制。
		WHERE  ISNULL(c.Valid,0)=1
		AND ISNULL(c.PresentFormGroup,'')='' OR EXISTS(SELECT 1 FROM SPLIT(ISNULL(c.PresentFormGroup,''),',') x WHERE x.list=@FormID)
		AND (ISNULL(c.Begindate,'')='' OR c.Begindate<=a.docDate)
		AND (ISNULL(c.Enddate,'')='' OR c.Enddate>=a.docdate)
		AND (ISNULL(d.sdorgid,'')='' OR a.sdorgPath LIKE '%/'+d.sdorgid+'/%')
		AND (ISNULL(d.areaid,'')='' OR a.areaPath LIKE '%/'+d.areaid+'/%')
		AND (ISNULL(d.Matgroup,'')='' OR a.matgrouppath LIKE '%/'+d.Matgroup+'%/')
		AND (ISNULL(d.Matcode,'')='' OR a.matcode=d.Matcode)
 
		--SELECT * FROM iCouponsGeneral
	END
 
 