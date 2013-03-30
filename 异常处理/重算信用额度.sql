begin TRAN
set NOCOUNT on
declare @doccode varchar(50),@SDOrgID varchar(50),@SDOrgName varchar(200),@AccountSDOrgID varchar(50),@ParentRowID varchar(50),@tips varchar(max),@Postdate datetime
declare @OverRunLimit money,@CreditAmount money,@FrozenAmount money,@ChangeCredit money,@Commission money,@Seriescode varchar(50),@AvailabBalance money
declare abc CURSOR READ_ONLY fast_forward for
select 
	uo.DocCode,uo.sdorgid,os.parentrowid,uo.sdorgname,Postdate
from  Unicom_Orders uo with(nolock) inner join oSDOrg os with(nolock) on uo.sdorgid=os.SDOrgID
where uo.DocDate='2013-03-29'
and isnull(uo.commission,0)=0
and os.dptType='加盟店'
--and uo.DocCode='RS20130329000224'
order by uo.PostDate
open abc
fetch next FROM abc into @doccode,@SDOrgID,@ParentRowID,@SDOrgName,@Postdate
while @@FETCH_STATUS=0
	BEGIN
		--取出加盟商编码
		select @AccountSDOrgID=os.SDOrgID
		from oSDOrg os with(nolock) where os.rowid=@ParentRowID
		--初始化
		update Unicom_Orders	set commission = 0 where DocCode=@doccode
		Select * Into #iSeries From iSeries is1 where is1.SeriesCode in(isnull(@SeriesCode,''))
		Select * Into #DocData
		From   v_unicomOrders_HD With(Nolock)
		Where  DocCode = @doccode
		Begin Try
			--执行策略
			Exec sp_ExecuteStrategy 9237, @doccode, 1, '', '', ''
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
		select @Commission=isnull(commission,0) from Unicom_Orders uo with(nolock) where uo.DocCode=@doccode
		print @doccode+','+@SDOrgID+','+convert(varchar(50),isnull(@Commission,0))+'--->'+convert(varchar(30),isnull(@Postdate,getdate()),120)
		if isnull(@Commission,0)<>0
			BEGIN
				--更新信用额度
				update oSDOrgCredit
					set Balance = isnull(Balance,0)+isnull(@Commission,0),
					modifydoccode=@doccode,ModifyDate = getdate(),ModifyUser = 'SYSTEM',
					remark = '系统数据未同步,系统管理员批量处理佣金.',
					@FrozenAmount=isnull(FrozenAmount,0),
					@CreditAmount=isnull(Balance,0),
					@OverRunLimit=isnull(OverrunLimit,0),@AvailabBalance=isnull(AvailableBalance,0)
				where SDOrgID=@AccountSDOrgID
				--插入日志
				insert into oSdorgCreditLog(Doccode,FormID,FormType,docdate,DocType,Account,Event,SDorgID,SDorgName,
				OverRunLimit,CreditAmount,FrozenAmount,ChangeCredit,Commission,Balance,AvailabBalance,
				Usercode,Remark)
				select @doccode,9237,16,getdate(),'加盟商开户',113107,'开户佣金',@sdorgid,@SDOrgName ,
				@OverRunLimit,@CreditAmount,@FrozenAmount,-@Commission,@Commission,isnull(@CreditAmount,0)+isnull(@Commission,0),isnull(@AvailabBalance,0)+isnull(@Commission,0),
				'SYSTEM','系统数据未同步,系统管理员批量处理佣金.'
				--修改明细账
				exec UN_fsubledgerlog @doccode
			END
		fetch next FROM abc into @doccode,@SDOrgID,@ParentRowID,@SDOrgName,@Postdate
	END
close abc
deallocate abc

rollback

commit