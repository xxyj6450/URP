/*
过程名称：sp_DistributedExecuteStrategy
功能描述：分布式执行策略。将数据源传输到指定服务器进行计算，计算后返回结果。
参数：见声名
编写：三断笛
时间：2013-01-15
备注:将传入的XML分别转换到两个临时表。在策略组中设置数据源时，可以直接使用此临时表。
示例：
*/
create proc sp_DistributedExecuteStrategy
	@FormID int,																--功能号
	@Doccode int,															--单号
	@DocDataXML XML,													--单据数据源，以XML传入,必须是For XML RAW格式,以<root>为根节点
	@DocDataDefinition nvarchar(max),								--单据数据源定义
	@DataSourceXML XML,												--策略数据源，以XML传入，必须是For XML RAW格式,以<root>为根节点
	@DataSourceDefinition nvarchar(max),							--策略数据源定义
	@OptionID varchar(200)='',											--预留选项值，可选
	@Usercode varchar(50)='',											--用户编码
	@TermianlID varchar(50)='',										--终端编码
	@InstanceID varchar(50)='',										--服务器实例ID
	@ResultXML xml=NULL output									--输出结果，以For XML RAW格式输出,以<root>为根节点
as
	BEGIN
		set NOCOUNT on;
		declare @hDocData int,@hDataSource int
		exec sp_xml_preparedocument @hDocData output,@DocDataXML
		select * Into #Docdata From OpenXML(@hDocData,'Root'
	END
	