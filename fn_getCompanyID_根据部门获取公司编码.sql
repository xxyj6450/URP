/*
��������:fn_getCompanyID 
����:���ݲ��ű���,���ϵݹ�,���ҹ�˾����.���ڸ������ŵ��Զ����ù�˾.
����:���ű���
����ֵ:��˾����
��д:���ϵ�
ʱ��:2012-12-26
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