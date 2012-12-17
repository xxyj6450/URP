/*
��������:fn_getDepositsInfo
����:��ȡ���մ���Ԥ�����Ϣ
����:������
����ֵ:
��д:���ϵ�
ʱ��:2012-10-26
��ע:
ʾ��:
select * from combo_h where comboname='B�ƻ�96Ԫ3G�ײ�'
SELECT * from dbo.fn_getDepositsInfo('TBD2012121300060','755',19)  
*/
alter FUNCTION fn_getDepositsInfo(
	@PackageID varchar(50),
	@AreaId varchar(50),
	@ComboCode varchar(50)
)
returns   table
return
	select psld.DepositsMatcode,psld.DepositsMatName ,isnull(psld.Deposits,0) as Deposits,isnull(psld.minPrice,0) as minPrice
	from PackageSeriesLog_H  psh with(nolock)   
        inner join PackageSeriesLog_D psld  with(nolock) on psh.DocCode=psld.Doccode 
        outer apply commondb.dbo.SPLIT(coalesce(nullif(psld.AreaID,''),@areaid,''),',') s
        where psh.refcode=@packageid
        and psh.FormID=9108
        and  psld.combocode=@combocode
        and exists(select 1 from gArea ga with(nolock) where ga.areaid=@AreaId and  ga.PATH like '/%'+s.List+'/%')
        
 