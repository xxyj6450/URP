select a.data1,a.data2,i.IMSI_SAFE,i.isActived,i.isLocked,i.isWriteen,isl.Remark
,case
	when (isnull(islocked,0)=1 or isnull(isactived,0)=1 or isnull(iswriteen,0)=1)  and isnull(i.isWriteen,0)=0 and isnull(i.IMSI_SAFE,'')='' then 'SOP�ѽ���'
	when (isnull(islocked,0)=1 or isnull(isactived,0)=1 or isnull(iswriteen,0)=1 )  and isnull(i.isWriteen,0)=0 and isnull(i.IMSI_SAFE,'')<>'' then '���̨ESS����'
	when isnull(i.isWriteen,0)=1 then '�ŵ�д�ѿ�,��Ҫʵ�￨���ܽ���'
	else '������'
end as State
  from _sysImportData a left join iSIMInfo i with(nolock) on i.ICCID like a.Data2+'%'
  left join iSIMInfo_Log isl with(nolock) on i.ICCID=isl.ICCID and isl.remark in('ESSд���ɹ�!','ESS����ɹ�!')
 
 
 
 select top 100 *from iSIMInfo_Log isl where isl.Remark ='ESSд���ɹ�!'
 
 select *from iSIMInfo_Log isl where isl.SeriesCode='8986011285105098938'