declare @sdorgid varchar(50),@AccountSdorgid varchar(200),@formid int,
@Balance money,@FrozenBalance money,@ChangeFrozenAmount money,
@ChangeCredit money,@Commission money,@SdorgName varchar(200),@doccode varchar(50)
begin tran
declare abc cursor READ_ONLY forward_only for
select oscl.AccountSDorgID,oscl.SDorgID,oscl.SDorgName,oscl.ChangeFrozenAmount,oscl.ChangeFrozenAmount,-oscl.Commission,oscl.Doccode,formid
  from oSdorgCreditLog oscl where oscl.Remark='管理员批量调整佣金'

 open abc
 fetch next FROM abc into @AccountSdorgid,@sdorgid,@SdorgName,@ChangeFrozenAmount,@ChangeCredit,@Commission,@doccode,@formid
 while @@FETCH_STATUS=0
	BEGIN
		--取出当前信用额度信息
		select @Balance=isnull(a.Balance,0),@FrozenBalance=isnull(a.FrozenAmount,0)
		from oSDOrgCredit a
		where a.SDOrgID=@AccountSdorgid
		--更新额度
		update oSDOrgCredit
			set Balance =isnull(Balance,0)-isnull(@ChangeCredit,0)+isnull(@Commission,0),
			FrozenAmount =isnull(FrozenAmount,0)-@ChangeFrozenAmount 
		where SDOrgID=@AccountSdorgid
		 --记录额度
		 insert into oSDOrgCreditlog(Doccode,FormID,Docdate,Account,Event,SDorgID,SDorgName,OverRunLimit,
		 CreditAmount,FrozenAmount,ChangeFrozenAmount,ChangeCredit,Commission,AvailabBalance,Usercode,
		 Remark,AccountSDorgID,Frozenstatus)
		 select @doccode,@formid,getdate(),'113107','调整额度',@sdorgid,@sdorgname,0,
		 @Balance,@FrozenBalance,@ChangeFrozenAmount,@ChangeCredit-@Commission,@Commission,null,'SYSTEM',
		 '管理员调整错误额度信息.',@accountsdorgid,'已处理'
		 fetch next FROM abc into @AccountSdorgid,@sdorgid,@SdorgName,@ChangeFrozenAmount,@ChangeCredit,@Commission,@doccode,@formid
	END
close abc
deallocate abc

select * from oSDOrgcredit where sdorgid='2.760.009'
select * from oSdorgCreditLog oscl where oscl.AccountSDorgID='2.760.009' and oscl.Event='调整额度'
select * from oSdorgCreditLog oscl where   oscl.Event='调整额度'

rollback

commit

2.756.027	2.1.756.02.06	香洲众人诚	-120.00	0.00	120.00

select * into osdorgcredit_2312
from oSDOrgCredit osc