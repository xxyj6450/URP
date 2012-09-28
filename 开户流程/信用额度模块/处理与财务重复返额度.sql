--统计信用额度与往来明细表余额不一致的单据

--1.统计财务未返,且往来明细余额与信用额度不一致的.需要判断是清除明细,还是调整余额
--1.1 明细比余额多,需要补额度

select oscl.ID, oscl.Doccode, a.sdorgid,a.Balance as truecredit,c.osdorgcredit,c.balance as mxBalance,  oscl.ChangeCredit,oscl.Commission  -- into #t1 
  from oSdorgCreditLog oscl,osdorgcredit a,balance_test1 c
where oscl.Remark='管理员批量调整佣金'
and substring(oscl.Doccode,3,8)='20120922'
and oscl.accountsdorgid=a.sdorgid
and a.SDOrgID=c.cltcode
and c.osdorgcredit<c.balance
and not exists(select data1 from _sysImportData sid where oscl.Doccode=sid.Data1)

select * from oSDOrgCredit osc where osc.SDOrgID='2.791.068' 
 
--1.2 余额多 清除余额
select oscl.Doccode, a.sdorgid,a.Balance as truecredit,c.osdorgcredit,c.balance as mxBalance,  oscl.ChangeCredit,oscl.Commission  -- into #t1 
  from oSdorgCreditLog oscl,osdorgcredit a,balance_test1 c
where oscl.Remark='管理员批量调整佣金'
and substring(oscl.Doccode,3,8)='20120922'
and oscl.accountsdorgid=a.sdorgid
and a.SDOrgID=c.cltcode
and c.osdorgcredit>c.balance
and not exists(select data1 from _sysImportData sid where oscl.Doccode=sid.Data1)
 
--2.统计未返,但往明细来与余额一致的.这部分是正确的,不需要调整.
 select oscl.id,a.SDOrgID,oscl.doccode,a.Balance --into #t3
   from oSdorgCreditLog oscl,osdorgcredit a 
where oscl.Remark='管理员批量调整佣金'
and substring(oscl.Doccode,3,8)='20120922'
and oscl.accountsdorgid=a.sdorgid
and not  exists(select data1 from _sysImportData sid where oscl.Doccode=sid.Data1)
and not  exists(select 1 from balance_test1 where cltcode=a.sdorgid    )

--3.统计财务已返,且往来明细与余额不一致的,需要判断是明细多,还是余额多.

--3.1 明细多 需要清除明细
select * from oSdorgCreditLog oscl ,osdorgcredit a 
where oscl.Remark='管理员批量调整佣金'
and substring(oscl.Doccode,3,8)='20120922'
and oscl.accountsdorgid=a.sdorgid
and   exists(select data1 from _sysImportData sid where oscl.Doccode=sid.Data1)
and   exists(select 1 from balance_test1 where cltcode=a.SDOrgID and osdorgcredit>balance)
--3.2 余额多 需要调整余额
select oscl.ID, oscl.Doccode, a.sdorgid,a.Balance as truecredit,c.osdorgcredit,c.balance as mxBalance,  oscl.ChangeCredit,oscl.Commission    --into t5
  from oSdorgCreditLog oscl,osdorgcredit a,balance_test1 c
where oscl.Remark='管理员批量调整佣金'
and substring(oscl.Doccode,3,8)='20120922'
and oscl.accountsdorgid=a.sdorgid
and a.SDOrgID=c.cltcode
and c.osdorgcredit<c.balance
and   exists(select data1 from _sysImportData sid where oscl.Doccode=sid.Data1)
 
 


 select * from oSDOrgCredit osc where osc.SDOrgID='2.757.034'
 -------4.财务已返,且余额相当
 select oscl.id,a.SDOrgID,oscl.doccode,a.Balance --into #t6
   from oSdorgCreditLog oscl,osdorgcredit a 
where oscl.Remark='管理员批量调整佣金'
and substring(oscl.Doccode,3,8)='20120922'
and oscl.accountsdorgid=a.sdorgid
and   exists(select data1 from _sysImportData sid where oscl.Doccode=sid.Data1)
and not  exists(select 1 from balance_test1 where cltcode=a.sdorgid    )


select * from #t3 A,#t6 b where a.id=b.id 
select * from #t1 A,#t5 b where a.id=b.id 

select * from #t1
select * from #t5

-----------------------------------------------------------------------------------------
--1.1 财务款返,明细比余额多,需要补额度
declare @ICCID varchar(20),@Seriescode varchar(50),@Doccode varchar(20),
@FormID int,@tips varchar(max),@Commission money,@sdorgid varchar(50),
@docdate datetime,@Commission1 money,@AccountSdorgid varchar(50),@SdorgName varchar(200)
set NOCOUNT on;
set XACT_ABORT on;
 begin tran
declare curCommission cursor FAST_FORWARD READ_ONLY FOR
select doccode,case when doccode like 'RS%' then 9237 else 9146 end as formid,  commission,os.sdorgid,getdate(),os.sdorgname
from #t1 a,oSDOrg os
where  
  a.sdorgid=os.SDOrgID
--and DocDate>='2012-09-23'
 and a.truecredit+a.commission=a.mxbalance
open curCommission
fetch next FROM curCommission into @Doccode,@FormID,@Commission,@sdorgid,@docdate,@SdorgName
while @@FETCH_STATUS=0
	BEGIN
			Begin Try
				--更新信用额度
				--exec sp_updatecredit  @FormID,@Doccode,@sdorgid,1,'','管理员批量调整佣金','SYSTEM'
				select @commission1=@Commission
				--if isnull(@Commission,0)!=isnull(@Commission1,0)
					BEGIN
						select @AccountSdorgid=@sdorgid
							insert into oSDOrgCreditlog(Doccode,FormID,Docdate,Account,Event,SDorgID,SDorgName,OverRunLimit,
							 CreditAmount,FrozenAmount,ChangeFrozenAmount,ChangeCredit,Commission,balance,AvailabBalance,Usercode,
							 Remark,AccountSDorgID,Frozenstatus)
							 select @doccode,@formid,getdate(),'113107','补返额度',@sdorgid,@sdorgname,0,
							 osc.Balance,osc.FrozenAmount,0,-@Commission1,@Commission1,osc.Balance++isnull(@Commission1,0), osc.AvailableBalance+isnull(@Commission1,0),'SYSTEM',
							 '管理员补返未即返的佣金_20120926.本单财务未补,还需系统补.',@accountsdorgid,'已处理'
							 from oSDOrgCredit osc
							 where osc.SDOrgID=@AccountSdorgid
							 
						update oSDOrgCredit
							set Balance = isnull(@Commission1,0)+isnull(Balance,0)
						where SDOrgID=@AccountSdorgid
						
					END
				--重写子帐
				--exec SetFsubLedger @Doccode,@FormID,'1001',@docdate,'','201209'
				print @Doccode+'已执行完成'+'原佣金:'+convert(varchar(10),isnull(@Commission ,0))+'现佣金:'+convert(varchar(10),isnull(@Commission1 ,0))
 
			End Try
			Begin Catch
				Select @tips =isnull( Error_message(),'') + dbo.crlf() + '异常过程：' + isnull(Error_procedure(),'') + dbo.crlf() + '异常发生于第：' + Convert(Varchar(10), Error_line()) + '行'
 
				   print @tips
				     
			End Catch
			
			fetch next FROM curCommission into @Doccode,@FormID,@Commission,@sdorgid,@docdate,@SdorgName
	END
close curCommission
deallocate curCommission

commit
rollback
select oscl.ID, oscl.Doccode, a.sdorgid,a.Balance as truecredit,c.osdorgcredit,c.balance as mxBalance,  oscl.ChangeCredit,oscl.Commission   
  from oSdorgCreditLog oscl,osdorgcredit a,balance_test1 c
where oscl.Remark='管理员批量调整佣金'
and substring(oscl.Doccode,3,8)='20120922'
and oscl.accountsdorgid=a.sdorgid
and a.SDOrgID=c.cltcode
and c.osdorgcredit<c.balance
and not exists(select data1 from _sysImportData sid where oscl.Doccode=sid.Data1)
 and a.Balance=c.balance
 
 select * from oSDOrgCredit osc where osc.SDOrgID='2.791.073'
 -----------------------------------------------------------------------------------------------------------------------------------
 --3.2 财务已返,往来明细比实际多,需要清除往来明细
 declare @ICCID varchar(20),@Seriescode varchar(50),@Doccode varchar(20),
@FormID int,@tips varchar(max),@Commission money,@sdorgid varchar(50),
@docdate datetime,@Commission1 money,@AccountSdorgid varchar(50),@SdorgName varchar(200)
set NOCOUNT on;
set XACT_ABORT on;
 begin tran
declare curCommission cursor FAST_FORWARD READ_ONLY FOR
select doccode,case when doccode like 'RS%' then 9237 else 9146 end as formid,  commission,os.sdorgid,getdate(),os.sdorgname--,a.*
from #t5 a,oSDOrg os
where  
  a.sdorgid=os.SDOrgID
--and DocDate>='2012-09-23'
 and a.truecredit+a.commission=a.mxbalance
open curCommission
fetch next FROM curCommission into @Doccode,@FormID,@Commission,@sdorgid,@docdate,@SdorgName
while @@FETCH_STATUS=0
	BEGIN
			Begin Try
				--更新信用额度
				--exec sp_updatecredit  @FormID,@Doccode,@sdorgid,1,'','管理员批量调整佣金','SYSTEM'
				select @commission1=@Commission
				update Unicom_Orders
					set commission = 0 where DocCode=@Doccode
				--重写子帐
				exec SetFsubLedger @Doccode,@FormID,'1001',@docdate,'','201209'
				print @Doccode+'已执行完成'+'原佣金:'+convert(varchar(10),isnull(@Commission ,0))+'现佣金:'+convert(varchar(10),isnull(@Commission1 ,0))
 
			End Try
			Begin Catch
				Select @tips =isnull( Error_message(),'') + dbo.crlf() + '异常过程：' + isnull(Error_procedure(),'') + dbo.crlf() + '异常发生于第：' + Convert(Varchar(10), Error_line()) + '行'
 
				   print @tips
				     
			End Catch
			
			fetch next FROM curCommission into @Doccode,@FormID,@Commission,@sdorgid,@docdate,@SdorgName
	END
close curCommission
deallocate curCommission

commit

select* from _sysImportData sid1 where data1='RS20120922004564'

select * from fsubledgerlog f where f.doccode='RS20120922004564'
