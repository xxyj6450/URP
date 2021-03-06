ALTER FUNCTION [fn_querySDorgInfo](
	@SdorgID varchar(50),
	@SdorgName varchar(50),
	@AreaID varchar(50),
	@AreaName varchar(50),
	@CompanyID varchar(50),
	@CompanyName varchar(50),
	@dptType varchar(50),
	@minType varchar(50),
	@mdf varchar(2),
	@area_b VARCHAR(20),
	@area_bname varchar(50),
	@cashno varchar(20),
	@HTID varchar(50)
)
returns table
return
select top 5000 Replicate(' ',2*(len(a.PATH)-len(replace(a.PATH,'/',''))-2))+a.SDOrgID as DisplayID , a.*
from oSDOrg a with(nolock) left join gArea b with(nolock) on a.AreaID=b.areaid
where (@SdorgID='' or a.PATH like '%/'+@SdorgID+'/%')
and (@SdorgName='' or a.SDOrgName like '%'+@SdorgName+'%')
and (@AreaID='' or b.areaid like '%/'+@AreaID+'/%')
and (@AreaName='' or b.areaname like '%'+@AreaName+'%')
and (@CompanyID='' or a.company_b=@CompanyID)
and (@CompanyName='' or a.company_bname like '%'+@CompanyName+'%')
and (@dptType='' or a.dptType=@dptType)
and (@minType='' or a.mintype=@minType)
and (@mdf='' or a.mdf=case @mdf when  '是' then 1 when '否' then 0 end)
and (@area_b='' or a.area_b=@area_b)
and (@area_bname='' or a.area_bname=@area_bname)
order by path
