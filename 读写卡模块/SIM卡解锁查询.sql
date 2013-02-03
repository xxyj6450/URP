select a.data1,a.data2,i.IMSI_SAFE,i.isActived,i.isLocked,i.isWriteen,isl.Remark
,case
	when (isnull(islocked,0)=1 or isnull(isactived,0)=1 or isnull(iswriteen,0)=1)  and isnull(i.isWriteen,0)=0 and isnull(i.IMSI_SAFE,'')='' then 'SOP已解锁'
	when (isnull(islocked,0)=1 or isnull(isactived,0)=1 or isnull(iswriteen,0)=1 )  and isnull(i.isWriteen,0)=0 and isnull(i.IMSI_SAFE,'')<>'' then '请后台ESS解锁'
	when isnull(i.isWriteen,0)=1 then '门店写已卡,需要实物卡才能解锁'
	else '正常卡'
end as State
  from _sysImportData a left join iSIMInfo i with(nolock) on i.ICCID like a.Data2+'%'
  left join iSIMInfo_Log isl with(nolock) on i.ICCID=isl.ICCID and isl.remark in('ESS写卡成功!','ESS激活成功!')
 
 
 
 select top 100 *from iSIMInfo_Log isl where isl.Remark ='ESS写卡成功!'
 
 select *from iSIMInfo_Log isl where isl.SeriesCode='8986011285105098938'