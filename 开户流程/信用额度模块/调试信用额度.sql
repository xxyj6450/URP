 select uo.commission, uo.doccode ,old,uo.NetType,uo.ComboCode,uo.ComboName, ch.Price,uo.PackageID
 from Unicom_Orders uo inner join Combo_H ch on uo.ComboCode=ch.ComboCode
 where uo.PackageID='RS20120923003101'

select * from strategy_dt where doccode='CLS2012081100001' AND Filter like '%TBD2012092200040%'
select * from log_Strategy_HD where doccode='CLS2012081100001' order by EventTime desc

declare @ICCID varchar(20),@Seriescode varchar(50),@Doccode varchar(20),
@FormID int,@tips varchar(max),@Commission money,@sdorgid varchar(50),
@docdate datetime


select @Doccode=uo.DocCode,@FormID=uo.FormID,@Seriescode=uo.SeriesCode,@ICCID=uo.ICCID
from Unicom_Orders uo
where uo.DocCode='RS20120924008321'

  Begin Tran  
    Select * Into #iSeries From iSeries is1 where is1.SeriesCode in(isnull(@SeriesCode,''),left(isnull(@ICCID,''),19))
	Select * Into #DocData
	From   v_unicomOrders_HD With(Nolock)
	Where  DocCode = @doccode
	Begin Try
		--执行策略
		Exec sp_ExecuteStrategy @formid, @doccode, 1, '', '', ''
		 drop TABLE #iSeries
		drop TABLE #DocData
	End Try
	Begin Catch
		Select @tips = Error_message() + dbo.crlf() + '异常过程：' + Error_procedure() + dbo.crlf() + '异常发生于第：' + Convert(Varchar(10), Error_line()) + '行'
			Rollback
			 drop TABLE #iSeries
			drop TABLE #DocData
		   Raiserror(@tips, 16, 1) 
		   Return
	End Catch
	
 rollback