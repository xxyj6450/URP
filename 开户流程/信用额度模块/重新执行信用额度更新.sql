
select top 10 * from Unicom_Orders uo where uo.commission=0  and uo.dptType='���˵�' order by docdate desc

declare @ICCID varchar(20),@Seriescode varchar(50),@Doccode varchar(20),
@FormID int,@tips varchar(max),@Commission money,@sdorgid varchar(50),
@docdate datetime,@Commission1 money,@AccountSdorgid varchar(50),@SdorgName varchar(200)
set NOCOUNT on;
 begin tran
declare curCommission cursor FAST_FORWARD READ_ONLY FOR
select doccode,formid,commission,os.sdorgid,DocDate,os.sdorgname
from unicom_orders,oSDOrg os
where os.dptType='���˵�'
and isnull(commission,0)=0
and DocStatus<>0
and unicom_orders.sdorgid=os.SDOrgID
and DocDate>='2012-09-23'
and FormID in(9102,9237,9146)
and os.mintype in('ר��','ר��')
--and unicom_orders.DocCode='RS20120922011482'
open curCommission
fetch next FROM curCommission into @Doccode,@FormID,@Commission,@sdorgid,@docdate,@SdorgName
while @@FETCH_STATUS=0
	BEGIN
			Select * Into #iSeries From iSeries is1 where is1.SeriesCode in(isnull(@SeriesCode,''),left(isnull(@ICCID,''),19))
			Select * Into #DocData
			From   v_unicomOrders_HD With(Nolock)
			Where  DocCode = @doccode
			Begin Try
				--ִ�в���
				Exec sp_ExecuteStrategy @formid, @doccode, 1, '', '', ''
				--�������ö��
				--exec sp_updatecredit  @FormID,@Doccode,@sdorgid,1,'','����Ա��������Ӷ��','SYSTEM'
				select @commission1=uo.commission
				  from Unicom_Orders uo where uo.DocCode=@doccode
				if isnull(@Commission,0)!=isnull(@Commission1,0)
					BEGIN
						select @AccountSdorgid=b.sdorgid
						from oSDOrg a,oSDOrg b
						where a.parentrowid=b.rowid
						and a.sdorgid=@sdorgid
							print @AccountSdorgid
							insert into oSDOrgCreditlog(Doccode,FormID,Docdate,Account,Event,SDorgID,SDorgName,OverRunLimit,
							 CreditAmount,FrozenAmount,ChangeFrozenAmount,ChangeCredit,Commission,balance,AvailabBalance,Usercode,
							 Remark,AccountSDorgID,Frozenstatus)
							 select @doccode,@formid,getdate(),'113107','�������',@sdorgid,@sdorgname,0,
							 osc.Balance,osc.FrozenAmount,0,-@Commission1,@Commission1,osc.Balance++isnull(@Commission1,0), osc.AvailableBalance+isnull(@Commission1,0),'SYSTEM',
							 '����Ա����δ������Ӷ��.',@accountsdorgid,'�Ѵ���'
							 from oSDOrgCredit osc
							 where osc.SDOrgID=@AccountSdorgid
							 
						update oSDOrgCredit
							set Balance = isnull(@Commission1,0)+isnull(Balance,0)
						where SDOrgID=@AccountSdorgid
						
					END
				--��д����
				exec SetFsubLedger @Doccode,@FormID,'1001',@docdate,'','201209'
				print @Doccode+'��ִ�����'+'ԭӶ��:'+convert(varchar(10),isnull(@Commission ,0))+'��Ӷ��:'+convert(varchar(10),isnull(@Commission1 ,0))
				 drop TABLE #iSeries
				drop TABLE #DocData
			End Try
			Begin Catch
				Select @tips =isnull( Error_message(),'') + dbo.crlf() + '�쳣���̣�' + isnull(Error_procedure(),'') + dbo.crlf() + '�쳣�����ڵڣ�' + Convert(Varchar(10), Error_line()) + '��'
					
					 drop TABLE #iSeries
					drop TABLE #DocData
					
				   print @tips
				     
			End Catch
			
			fetch next FROM curCommission into @Doccode,@FormID,@Commission,@sdorgid,@docdate,@SdorgName
	END
close curCommission
deallocate curCommission

select * from oSDOrgCredit osc where osc.SDOrgID='2.752.112'
select * from oSDOrgCreditlog osc where osc.accountSDOrgID='2.752.112' and osc.Doccode='RS20120922005044'

rollback

commit
select uo.commission, *
  from Unicom_Orders uo where uo.DocCode='RS20120922000522'

select * from fsubledgerlog f where f.doccode='RS20120922005044'