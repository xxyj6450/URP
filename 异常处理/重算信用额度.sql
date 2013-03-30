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
and os.dptType='���˵�'
--and uo.DocCode='RS20130329000224'
order by uo.PostDate
open abc
fetch next FROM abc into @doccode,@SDOrgID,@ParentRowID,@SDOrgName,@Postdate
while @@FETCH_STATUS=0
	BEGIN
		--ȡ�������̱���
		select @AccountSDOrgID=os.SDOrgID
		from oSDOrg os with(nolock) where os.rowid=@ParentRowID
		--��ʼ��
		update Unicom_Orders	set commission = 0 where DocCode=@doccode
		Select * Into #iSeries From iSeries is1 where is1.SeriesCode in(isnull(@SeriesCode,''))
		Select * Into #DocData
		From   v_unicomOrders_HD With(Nolock)
		Where  DocCode = @doccode
		Begin Try
			--ִ�в���
			Exec sp_ExecuteStrategy 9237, @doccode, 1, '', '', ''
			 drop TABLE #iSeries
			drop TABLE #DocData
		End Try
		Begin Catch
			Select @tips = Error_message() + dbo.crlf() + '�쳣���̣�' + Error_procedure() + dbo.crlf() + '�쳣�����ڵڣ�' + Convert(Varchar(10), Error_line()) + '��'
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
				--�������ö��
				update oSDOrgCredit
					set Balance = isnull(Balance,0)+isnull(@Commission,0),
					modifydoccode=@doccode,ModifyDate = getdate(),ModifyUser = 'SYSTEM',
					remark = 'ϵͳ����δͬ��,ϵͳ����Ա��������Ӷ��.',
					@FrozenAmount=isnull(FrozenAmount,0),
					@CreditAmount=isnull(Balance,0),
					@OverRunLimit=isnull(OverrunLimit,0),@AvailabBalance=isnull(AvailableBalance,0)
				where SDOrgID=@AccountSDOrgID
				--������־
				insert into oSdorgCreditLog(Doccode,FormID,FormType,docdate,DocType,Account,Event,SDorgID,SDorgName,
				OverRunLimit,CreditAmount,FrozenAmount,ChangeCredit,Commission,Balance,AvailabBalance,
				Usercode,Remark)
				select @doccode,9237,16,getdate(),'�����̿���',113107,'����Ӷ��',@sdorgid,@SDOrgName ,
				@OverRunLimit,@CreditAmount,@FrozenAmount,-@Commission,@Commission,isnull(@CreditAmount,0)+isnull(@Commission,0),isnull(@AvailabBalance,0)+isnull(@Commission,0),
				'SYSTEM','ϵͳ����δͬ��,ϵͳ����Ա��������Ӷ��.'
				--�޸���ϸ��
				exec UN_fsubledgerlog @doccode
			END
		fetch next FROM abc into @doccode,@SDOrgID,@ParentRowID,@SDOrgName,@Postdate
	END
close abc
deallocate abc

rollback

commit