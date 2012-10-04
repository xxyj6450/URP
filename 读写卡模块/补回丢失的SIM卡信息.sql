begin tran
declare @option varchar(5000),@IMSI varchar(50)
select @option='!A0A40000023F00,S,,9FXX!A0A40000027F10,S,,9FXX!A0A40000026F42,S,,9FXX!A0DC010428FFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFFFFFFFFFFFF0891683110200005F0FFFFFFFFFFFF,S,,9000'
;with cte as(
	select data1,data2 from _sysImportData sid
	 
group by data1,data2
)
 insert into isiminfo(iccid,seriescode,seriesnumber,Doccode,FormID,IMSI,OptionID,isLocked,isActived,Remark,USIM)
select uo.iccid,left(uo.iccid,19),seriesnumber,doccode,formid,b.data2,@option,1,1,'管理员恢复SIM卡数据',uo.iccid
--select uo.DocCode,uo.SeriesNumber,b.data2
from Unicom_Orders uo with(nolock), cte b 
where uo.SeriesNumber=b.Data1
and uo.DocDate>='2012-09-28'
and not exists(select 1 from iSIMInfo is1 with(nolock) where is1.ICCID=uo.ICCID)
 
--and   exists(select 1 from iSIMInfo is1 with(nolock) where is1.ICCID=uo.ICCID)
rollback

commit

select data1,data2 from _sysImportData sid
group by data1,data2
select * from iSIMInfo is1 where is1.ICCID='89860112851081922041'
select * from iSIMInfo where SeriesNumber='18620604262'
select * from _sysImportData sid where data1 not in(select seriesnumber from Unicom_Orders uo with(nolock) where uo.DocDate>='2012-09-28')
 
select * from _sysImportData sid where data1   in(select seriesnumber from isiminfo uo with(nolock))

!A0A40000023F00,S,,9FXX!A0A40000027F10,S,,9FXX!A0A40000026F42,S,,9FXX!A0DC010428FFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFFFFFFFFFFFF0891683110200005F0FFFFFFFFFFFF,S,,9000

select * from iSIMInfo is1 where is1.SeriesNumber='18620624133'

select uo.bitReturnd,uo.OpenDate, *
  from Unicom_Orders uo where uo.SeriesNumber='18620683975'
  
  select * from iSIMInfo is1 where is1.Doccode='RS20121001019223'