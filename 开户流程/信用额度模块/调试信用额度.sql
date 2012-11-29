 select totalmoney2, uo.commission, uo.doccode ,old,uo.NetType,uo.ComboCode,uo.ComboName, ch.Price,uo.PackageID
 from Unicom_Orders_2 uo inner join Combo_H ch on uo.ComboCode=ch.ComboCode
 where uo.doccode='RS20121027003662'
 

declare @ICCID varchar(20),@Seriescode varchar(50),@Doccode varchar(20),
@FormID int,@tips varchar(max),@Commission money,@sdorgid varchar(50),
@docdate datetime,@Totalmoney2 money


select @Doccode=uo.DocCode,@FormID=uo.FormID,@Seriescode=uo.SeriesCode,@ICCID=uo.ICCID
from Unicom_Orders uo
where uo.DocCode='RS20121027003662'

  Begin Tran  
  exec sp_ExecuteExpression @FormID,@Doccode,'',@Totalmoney2 out
  print @Totalmoney2
  
  rollback
  begin tran
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
 
 begin TRAN
 update Unicom_Orders
	set DocDate = '2012-09-30'
 where DocCode='PS20120929016501'
 
 commit