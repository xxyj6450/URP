/*
过程名称:sp_CreateDataDictFromTemplate
参数:见声名
功能:从门店资料及权限模板复制信息 生成数据组
编写:三断笛
时间:2012-10-08
示例: 
BEGIN tran
exec sp_CreateDataDictFromTemplate '512.03','门店数据组模板',1,1

rollback
*/
alter PROC sp_CreateDataDictFromTemplate
	@sdOrgID varchar(50),
	@TemplateName varchar(50),
	@IncludeSubNodes bit=0,
	@OnlyDepartment bit =1
as
	BEGIN
		
		set NOCOUNT on;
		declare @table table(
			sdorgid varchar(50),
			companyid varchar(50)
		)
		--创建数据组
		if @IncludeSubNodes=1 
			BEGIN
				Insert Into _sysdataaccess(accessid,memo,companyid)
				output INSERTED.accessid,inserted.companyid into @table
				Select os.SDOrgID,os.SDOrgName,ops.PlantID
				from oSDOrg os with(nolock),oPlantSDOrg ops with(nolock)
				where os.SDOrgID=ops.SDOrgID
				and not exists(select 1 from _sysdataaccess s where s.accessid=os.SDOrgID)
				and os.PATH like '%/'+@sdOrgID+'/%'
				and (@OnlyDepartment=0 or (@OnlyDepartment=1 and os.mdf=1))
			END
		else
			BEGIN
				Insert Into _sysdataaccess(accessid,memo,companyid)
				output INSERTED.accessid,inserted.companyid into @table
				Select os.SDOrgID,os.SDOrgName,ops.PlantID
				from oSDOrg os with(nolock),oPlantSDOrg ops with(nolock)
				where os.SDOrgID=ops.SDOrgID
				and not exists(select 1 from _sysdataaccess s where s.accessid=os.SDOrgID)
				and os.SDOrgID=@sdOrgID
				and (@OnlyDepartment=0 or (@OnlyDepartment=1 and os.mdf=1))
			END
		--创建数据组内容
		insert into _sysdataaccessauthobj(accessid,authobj,modfvalues)
		select a.sdorgid,b.PropertyValue,replace(replace(b.lParams,'门店编码',a.sdorgid),'公司编码',a.companyid)
		from @table a,_sysNumberAllocationCfgValues b
		where b.PropertyName=@TemplateName
 
	END