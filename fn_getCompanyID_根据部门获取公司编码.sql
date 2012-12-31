/*
函数名称:fn_getCompanyID 
功能:根据部门编码,往上递归,查找公司编码.用于给新增门店自动设置公司.
参数:部门编码
返回值:公司编码
编写:三断笛
时间:2012-12-26
*/
create FUNCTION fn_getCompanyID(
	@SDOrgID varchar(50)
)
returns varchar(50)
as
	BEGIN
		declare @CompanyID varchar(50)
		;with cte(sdorgid,rowid,parentrowid,level) as(
		select os.sdorgid,os.rowid,parentrowid,0 as level
		from oSDOrg os with(nolock)
		where os.SDOrgID=@SDOrgID
		union  all
		select os.sdorgid,os.rowid,os.parentrowid,b.level+1 as level
		from oSDOrg os with(nolock) join cte b on os.rowid=b.parentrowid
		   
		)
		select top 1 @CompanyID=plantid
		from cte a,oPlantSDOrg ops with(nolock)
		where a.sdorgid=ops.SDOrgID
		order by a.level
		return @CompanyID
	END