/*
函数名称:fn_getDepositsInfo
功能:获取代收代付预存款信息
参数:见声名
返回值:
编写:三断笛
时间:2012-10-26
备注:
示例:
select * from combo_h where comboname='B计划96元3G套餐'
SELECT * from dbo.fn_getDepositsInfo('TBD2011051700003','769',13)  
*/
create FUNCTION fn_getDepositsInfo(
	@PackageID varchar(50),
	@AreaId varchar(50),
	@ComboCode varchar(50)
)
returns   table
return
	select psld.DepositsMatcode,psld.DepositsMatName ,isnull(psld.Deposits,0) as Deposits,isnull(psld.minPrice,0) as minPrice
	from PackageSeriesLog_H  psh with(nolock)   
        inner join PackageSeriesLog_D psld  with(nolock) on psh.DocCode=psld.Doccode 
        outer apply commondb.dbo.SPLIT(coalesce(psld.AreaID,@areaid,''),',') s
        where psh.refcode=@packageid
        and psh.FormID=9108
        and  psld.combocode=@combocode
        and s.List=@areaid
        
 