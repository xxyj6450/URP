/*
��������:sp_UpdateCredit
����:�������ö��
����:������
����ֵ:��
��д:���ϵ�
ʱ��:2012-08-17
����˵��:
��ע: 1.�Թ��̶Խ���൱����. 2.Ҫע������������ʹ��.�����Ƿֲ�ʽ����. 3.�κ������ֶλ����,��Ҫ����ISNULL. 4.�ѻ�һ�п��ܷ������쳣,���������ܷ�����.
--------------------------------------------------------------------------
����ʱ��:2012-12-24
�޸���:���ϵ�
��������:
�޸����ö�ȴ����߼�.�����̵���ʽ������,��Ҫ�����ڽ����ȴ��������̵�����.
����������Ҫ����������������ж����ȵļ�¼����.
��������ʱ���ܶ�����.��ʱ����״̬Ϊ������.
�ں��������̴��������,�᲻�ϼ��ٶ�����(�������̲�Ӧ���Ӷ�����,�����ȵ�����ֻ�������̷�����Ա����,����Ӧ�����̴�����Ա����.).
�����̽���ǰ,��Щ���������ٵĶ����ȶ��ʴ�����״̬,�Թ���ѯ���̵Ķ�����.�����̳��׽���ʱ,�����к������̱�־���Ѵ���.ȡ�������־�����ж�����.
����Щ���������̿�����ĳ���ڵ��ɢ�γɶ������������,������֧���̲���֪���Լ��Ƿ����������̵��յ�,Ҳ����˵��֪���������̺�ʱ���׽���,����ʱȡ�����ж�����.
������������,���������:
1.���Ӷ�����̱�,��¼���̱���(����),���������ѽⶳ��ȱ�־.�κ�ҵ�����ʹ�ô����̱���и����ӵĿ���.
2.��������ʱ,���������̱�־(@StartFlow)�����̱�־,������,д�������̱�.
3.�����ö�ȵĴ����봦��״̬�޹�.�����������Ƿ����,�����Ƿ����,�Զ�ȵĴ������ı�.�������̽�Ӱ������ϸ��־.
4.�����̴���,
	4.1һ�����̽ڵ�,��������ֹ����,�һ�ı䶳����,���"������"��־,����ID��־,Դ���ݱ�־.
		4.1.1 �����̶�����<=�Ѵ�����+���ζ�����,���׳��쳣
		4.1.2 �����̶�����>=�Ѵ�����+���ζ�����,��������������һ�ʽⶳ���,��ͬʱ����һ�д�����Ķ�����.
	4.2һ�����̽ڵ�,�����ܽ���ֹ����,���"�Ѵ���"��־,����ID��־,Դ���ݱ�־.
		4.2.1 ����ʱ���̶�����<=�Ѵ�����+���ζ�����,��������������һ�ʶ�����,��ͬʱ����һ�д���������.
	4.3 ����ʱ���̶�����>=�Ѵ�����+���ζ�����,���Զ����������̵����нڵ��־"�Ѵ���"
5.�����̲�����
	5.1 ����"�Ѵ���"��־,��ֱ����ֹ��������,�������̽ڵ��־"�Ѵ���".
	5.2 ����"������"��־,������һ�ж����ϸ,״̬Ϊ"������"

�����߼����������������̵ķ�֧,��˳������ʽ����,���������ô���.��������:
1.ȡ�����ö��,������Ϣ��������Ϣ.
2.����ҵ�������Ƿ���������,�Ƿ��������.
3.�������ö��.
4.�����̴���,�����̶�����<=�Ѵ�����+���ζ�����,���׳��쳣,���˳�.
5.�޸����ö��.
6.����"��������"��־,�����һ��������.
7.���Ӷ����־.
8.�����̴���,�����̼�¼������һ�ʴ�����.
9.����"�Ѵ���"��־
	9.1 �����̴���,�Ҵ�ʱ���̶�����>=�Ѵ�����+���ζ�����,���Զ����������̵����нڵ��־"�Ѵ���"
	9.2 �����̲�����,��Դ�������̸ĳ�"�Ѵ���"

begin tran
exec [sp_UpdateCredit] 6093,'GFH2013030402006','2.1.576.01.91',1,'1','�ֻ���������������δ������ֻ��������޷��ֻ�������Ա����֮��2013-03-06 ���ϵ�','SYSTEM',''
rollback
commit
begin tran
exec [sp_UpdateCredit] 9237,'JDC2012113000000','2.1.769.09.29',1,'1'

 
BEGIN tran
	EXEC  sp_UpdateCredit 6052,'DTZ2012121700006','2.1.769.02.23',0,'2','������ֹ,ȡ����ȶ���.'
	
select * from oSDOrgCreditlog osc where osc.Doccode='DD20120924000020' order by osc.Docdate desc
select * from osdorgcredit where sdorgid='2.020.426'
*/
 ALTER proc [dbo].[sp_UpdateCredit]
	@Formid int,							--���ܺ�
	@Doccode varchar(20),					--����
	@SDOrgID	varchar(50),				--�ŵ����
	@ControlBalance bit=1,					--�Ƿ�������ö��,Ĭ��Ϊ1
	@OptionID varchar(100)='',				--@OptionIDΪ�����ʾȷ��,ΪĬ��ֵ.1��ʾ�ύ��� 2��ʾ���ϻ��˻�
	@Remark varchar(500)='',				--��ע
	@Usercode varchar(50)='',				--�޸���
	@TerminalID varchar(50)=''				--�ն˱���
as
	BEGIN
		set nocount On
		Set Xact_abort On;
/*************************************************��������*****************************************************/

		declare @SDorgName           varchar(200),					--��������
		        @Event               varchar(50),								--�¼�
		        @tips					varchar(5000),							--��ʾ��Ϣ
		        --�޸�ǰ�Ķ����Ϣ
		        @OverRunLimit        money,								--�ɳ�֧���
		        @Credit              money,									--���ö��
		        @Balance             money,									--���ö�����(=���ö��-����Ӧ�۶��)
		        @FrozenAmount        money,								--�Ѷ�����
		        @AvailabBalance      money,								--��ǰ���ö��(=���ö��+�ɳ�֧���-�Ѷ�����-����������-����Ӧ�۶��)
		        --�޸ĵĶ����Ϣ
		        @ChangeCredit        money,								--����Ӧ�۶��
		        @ChangeFrozenAmount  money,							--����������
				@ChangeAmount	money,									--Ӧ�ս��.���ֶ����ύ���ʱ�Ƕ�����,��ȷ��ʱ�ǿ۶�Ƚ��.
				@Commission	money,										--Ӷ��
				@DeductAmount money,									--�ֽ𽱵ֿ۽��
				@Rewards	money,												--�ֽ���
				@Refcode varchar(50),										--���õ���
				@AccountSdorgid varchar(50),							--���ö�ȿ����ŵ�
				@dptType varchar(50),										--�ŵ�����
				@minType varchar(50),										--��������
				@ParentRowID varchar(50),									--�����ϼ��ڵ�
				@SourceDoccode varchar(20),							--Դ����.ָȡ��������ʱ��ԭ�����ȵĵ���.
				@FrozenStatus varchar(20),									--���ö�ȶ���״̬,�ύ���ʱ"�Ѷ���",ȷ��ʱ"��ȡ��"
				@Doctype varchar(50),										--��������
				@FormType int,													--����ģ������
				@TranCount int,													--������
				@Rowcount int,
				@sql nvarchar(max),
				@osdtype varchar(50),
				@StartFlow bit,													--��������
				@FlowStatus VARCHAR(50),									--����״̬
				@FlowExists BIT,												--�����Ƿ����
				@FlowUnFrozenAmount money,							--������Ѿ��ⶳ���
				@FlowInstanceID varchar(50),								--����ʵ��ID.���ڼ�¼һ����ҵ�����̵ı�־,�綩������,�����Զ�������Ϊ���̱��.
				@FlowFrozenAmount money								--�������Ѿ�����Ľ��
		--���������Դ洢�޸�ǰ�����ö����Ϣ
		declare @table table(
			Sdorgid varchar(50),
			Account varchar(50),
			OverRunLimit money,
			FrozenAmount money,
			Balance money,
			AvailableBalance money,
			curBalance money,
			curAvailableBalance money
		)
/*************************************************����������**************************************************/

if @Formid not in(9102,9146,9237,9167,9244,6090,4950,2401,4956,9267,2041,4951,6052,6093) return
/*************************************************��ʼ������*****************************************************/
		--��δ���벿����Ϣ,���׳��쳣
		if ISNULL(@SDOrgID,'')=''
			BEGIN
				raiserror('�޲�����Ϣ,�ܾ�������Ϣ���,����ϵϵͳ����Ա',16,1)
				return
			END
		--ȡ��������Ϣ
		select @dptType=dpttype,@ParentRowID=parentrowid,@SDorgName=SDOrgName,@minType =mintype,@osdtype=osdtype
		from osdorg with(nolock)
		where sdorgid=@SDOrgID
		if @@ROWCOUNT=0
			BEGIN
				
				raiserror('������Ϣ������,�ܾ�������Ϣ���,����ϵϵͳ����Ա',16,1)
				return
			END
		--���Ǽ��˵�,��ֱ���˳�,���ټ���.Ҫע���ʱ�Ĳ��ű�������Ǽ��˵�,Ҳ�����Ǽ�����,��Ҫ��������������Ĳ���.
		if isnull(@dptType,'') not in('���˵�') and isnull(@osdtype,'') not in('����') return
		SELECT @Rowcount=0
/*************************************************����ҵ��*****************************************************/
		--����
		if @Formid in(9102,9146,9237)
			begin
				--ȡ��������Ϣ,���洢����������ʱ��,�����ȴ���ʱ��ȡ������
				if object_id('tempdb.dbo.Unicom_Orders') IS not null
					BEGIN
						select @ChangeAmount=isnull(totalmoney2,0),@Commission=isnull(uo.commission,0),@Rewards=isnull(uo.rewards,0),@DeductAmount=isnull(uo.deductamount,0)
						from #Unicom_Orders uo with(nolock)
						where uo.DocCode=@Doccode
						select @Rowcount=@@ROWCOUNT
					END
					--���û��,��Ŭ������һ��,��Ҫ����.
					if isnull(@Rowcount,0)=0
						BEGIN
							select @ChangeAmount=isnull(totalmoney2,0),@Commission=isnull(uo.commission,0),@Rewards=isnull(uo.rewards,0),@DeductAmount=isnull(uo.DeductAmout,0)
							from Unicom_Orders uo with(nolock)
							where uo.DocCode=@Doccode
							select @Rowcount=@@ROWCOUNT
						END
					--ʵ��û�еĻ�,ֻ���׳��쳣��.
					if isnull(@ROWCOUNT,0) =0
							BEGIN
								raiserror('���ݲ�����,�޷������ö�Ƚ��и���.',16,1)
								return
							END
				--�ύ���,���ö�Ȳ���,����Ԥռ���
				if @OptionID='1'
					BEGIN
						select @ChangeFrozenAmount=@ChangeAmount,@ChangeCredit=0,@Event='�����ύ��˶�����',
						@FrozenStatus='������'
					end
				--�˻����,ȡ��������
				else if @OptionID='2'
					BEGIN
						select @ChangeFrozenAmount= - @ChangeAmount,@ChangeCredit=0,@Event='����ȡ��,ȡ��������',
						@FrozenStatus='�Ѵ���',@SourceDoccode=@Doccode
					END
				--ȷ�ϵ���,�����ö��,����Ԥռ���
				else if @OptionID=''
					BEGIN
						select @ChangeCredit=@ChangeAmount-@Commission-isnull(@DeductAmount,0),@ChangeFrozenAmount=-@ChangeAmount,
						@Event='ȷ�ϵ��ݿۼ����,ȡ��������.',@SourceDoccode=@Doccode,@FrozenStatus='�Ѵ���'
					end
				--���������Ͳ�����,���׳��쳣,��ֹ�Ƿ�����
				else
					BEGIN
						raiserror('�������ö�Ȳ�������δ��ʶ��,ִ��ʧ��,����ϵϵͳ����Ա',16,1)
						return
					END
				--ȡ���ϼ��ŵ�,��Ϊ���ö�ȿ���
				select @AccountSdorgid=sdorgid ,@SDorgName=sdorgname from oSDOrg os  with(nolock) where os.rowid=@ParentRowID
				--ȡ�������Ϣ
			end
/*************************************************��������ҵ��*****************************************************/
		--����,�ύ���ʱ,���ı��κζ��
		if @Formid in(9244)
			begin
				--ȡ��������Ϣ,���洢����������ʱ��,�����ȴ���ʱ��ȡ������
				if object_id('tempdb.dbo.Unicom_Orders') is null
					BEGIN
						select  @ChangeAmount=isnull(-uo.totalmoney2,0)+isnull(uo.commission,0)+isnull(@Rewards,0),@Commission=isnull(uo.commission,0),
						@Rewards=isnull(uo.rewards,0), @ChangeFrozenAmount=0,@Event='���������������ö��.'
						from Unicom_Orders uo with(nolock)
						where uo.DocCode=@Doccode
						select @Rowcount=@@ROWCOUNT
					END
				else
					BEGIN
						select  @ChangeAmount=isnull(-uo.totalmoney2,0)+isnull(uo.commission,0)+isnull(@Rewards,0),@Commission=isnull(uo.commission,0),
						@Rewards=isnull(uo.rewards,0), @ChangeFrozenAmount=0,@Event='���������������ö��.'
						from #Unicom_Orders uo with(nolock)
						where uo.DocCode=@Doccode
						select @Rowcount=@@ROWCOUNT
						if @ROWCOUNT=0
							BEGIN
								select  @ChangeAmount=isnull(-uo.totalmoney2,0)+isnull(uo.commission,0)+isnull(@Rewards,0),@Commission=isnull(uo.commission,0),
								@Rewards=isnull(uo.rewards,0), @ChangeFrozenAmount=0,@Event='���������������ö��.'
								from Unicom_Orders uo with(nolock)
								where uo.DocCode=@Doccode
								select @Rowcount=@@ROWCOUNT
							END
					END
					if @ROWCOUNT=0
						BEGIN
							raiserror('���ݲ�����,�޷������ö�Ƚ��и���.',16,1)
							return
						END
				select @ChangeCredit=@ChangeAmount,@ChangeFrozenAmount=0
				--ȡ���ϼ��ŵ�,��Ϊ���ö�ȿ���
				select @AccountSdorgid=sdorgid  from oSDOrg os with(nolock) where os.rowid=@ParentRowID
			end
/*************************************************��ֵ�ɷ�ҵ��*****************************************************/
		--��ֵ�ɷ�
		if @Formid in(9167,9267)
			begin
				declare @intype varchar(20)
				--ȡ��������Ϣ,���洢����������ʱ��,�����ȴ���ʱ��ȡ������
				if object_id('tempdb.dbo.Unicom_Orders') is null
					BEGIN
						select @SDOrgID=uo.sdorgid,@SDorgName=uo.sdorgname,@ChangeAmount=isnull(TotalMoney,0),@intype=uo.intype
						from BusinessAcceptance_H  uo with(nolock)
						where uo.DocCode=@Doccode
						select @Rowcount=@@ROWCOUNT
					END
				else
					BEGIN
						select @SDOrgID=uo.sdorgid,@SDorgName=uo.sdorgname,@ChangeAmount=isnull(TotalMoney,0),@intype=uo.intype
						from #BusinessAcceptance_H  uo with(nolock)
						where uo.DocCode=@Doccode
						select @Rowcount=@@ROWCOUNT
						if @Rowcount=0
							BEGIN
								select @SDOrgID=uo.sdorgid,@SDorgName=uo.sdorgname,@ChangeAmount=isnull(TotalMoney,0),@intype=uo.intype
								from BusinessAcceptance_H  uo with(nolock)
								where uo.DocCode=@Doccode
								select @Rowcount=@@ROWCOUNT
							END
					END
				if @ROWCOUNT=0
					BEGIN
						raiserror('���ݲ�����,�޷������ö�Ƚ��и���.',16,1)
						return
					END
				--�ύ���,���ö�Ȳ���,����Ԥռ���
				if @OptionID='1'
					BEGIN
						select @ChangeFrozenAmount=  @ChangeAmount,@ChangeCredit=0,@Event='��ֵ�ύ��˶�����.',@FrozenStatus='������'
					end
				--�˻����,���ö�Ȳ���,ȡ��Ԥռ���
				else if @OptionID='2'
					BEGIN
						select @ChangeCredit=0,@ChangeFrozenAmount=  -@ChangeAmount,@ChangeCredit=0,@Event='��ֵʧ��,ȡ��������.',
						@FrozenStatus='�Ѵ���',@SourceDoccode=@Doccode
					end
				--ȷ�ϵ���,�����ö��,����Ԥռ���
				else if @OptionID=''
					BEGIN
						select @ChangeCredit=@ChangeAmount,@ChangeFrozenAmount=-@ChangeAmount,
						@Event='��ֵ�ɹ��ۼ����ö��,ȡ��������.',@SourceDoccode=@Doccode,@FrozenStatus='�Ѵ���' 
					end
				--���������Ͳ�����,���׳��쳣,��ֹ�Ƿ�����
				else
					BEGIN
						raiserror('�������ö�Ȳ�������δ��ʶ��,ִ��ʧ��,����ϵϵͳ����Ա',16,1)
						return
					END
				--ȡ���ϼ��ŵ�,��Ϊ���ö�ȿ���
				select @AccountSdorgid=sdorgid ,@SDorgName=sdorgname from oSDOrg os with(nolock) where os.rowid=@ParentRowID
			end
/*************************************************�ܲ��������뵥*****************************************************/
		--�ܲ��������뵥,���Ӷ�����
		if @Formid in(6090)
			BEGIN
				--��������
				select @ChangeAmount=isnull(SumNetMoney,0),@FlowInstanceID=@Doccode
				from ord_shopbestgoodsdoc with(nolock)
				where DocCode=@Doccode
				if @@ROWCOUNT=0
					BEGIN
						raiserror('���ݲ�����,�޷������ö�Ƚ��и���.',16,1)
						return
					END
				--���϶���,ȡ����ȶ���
				if @OptionID='2'
					BEGIN
						select @ChangeFrozenAmount=-@ChangeAmount,@Event='��������,ȡ��������.',
						@SourceDoccode=@Doccode,@FrozenStatus='�Ѵ���',@FlowInstanceID=@Doccode
					end

				--ȷ�϶���,������
				else if @OptionID=''
					BEGIN
						select @ChangeFrozenAmount=@ChangeAmount,@Event='����������.',@FrozenStatus='������',@FlowInstanceID=@Doccode,@StartFlow=1
					end
				--���������Ͳ�����,���׳��쳣,��ֹ�Ƿ�����
				else
					BEGIN
						raiserror('�������ö�Ȳ�������δ��ʶ��,ִ��ʧ��,����ϵϵͳ����Ա',16,1)
						return
					END
				--ȡ���ϼ��ŵ�,��Ϊ���ö�ȿ���
				select @AccountSdorgid=sdorgid ,@SDorgName=sdorgname from oSDOrg os with(nolock) where os.rowid=@ParentRowID
			END
		--�����ֻ���,�ֻ�ʱ��Ҫ�������ȵĲ���
		if @Formid in(6093)
			BEGIN
				--ALTER TABLE ord_shopbestgoodsdoc ADD  REFDOC VARCHAR(50)
				--�ֻ�ʱȡ���.
				select @ChangeAmount=isnull(SumNetMoney,0)-isnull(userdigit,0),@FlowInstanceID=ISNULL(RefDoc,'')
				from ord_shopbestgoodsdoc with(nolock)
				where DocCode=@Doccode
				select @rowcount=@@rowcount
				IF @rowcount=0
					BEGIN
						raiserror('���ݲ�����,�޷������ö�Ƚ��и���.',16,1)
						return
					end
				--�ֻ�ȡ���
				 if @OptionID IN('','1')
					BEGIN
						select @ChangeFrozenAmount=-@ChangeAmount,@Event='�ֻ�������.',@FrozenStatus='�Ѵ���'
					END
				--���������Ͳ�����,���׳��쳣,��ֹ�Ƿ�����
				else
				BEGIN
					select @tips='�������ö�Ȳ�������δ��ʶ��,ִ��ʧ��,����ϵϵͳ����Ա'+convert(varchar(20),@optionid)
					raiserror(@tips,16,1)
					return
				END
				--ȡ���ϼ��ŵ�,��Ϊ���ö�ȿ���
				select @AccountSdorgid=sdorgid ,@SDorgName=sdorgname from oSDOrg os with(nolock) where os.rowid=@ParentRowID
			END
		--����ָ���ֹ����
		if @Formid in(6052)
			BEGIN
				--����ƽ̨�˴�ȡ�ֻ����.
				select @Refcode=a.UserTxt1,@FlowInstanceID=ISNULL(a.UserTxt1,'')
				from imatdoc_h a with(nolock) 
				where a.FormID=6052
				and a.DocCode=@doccode
				if @@ROWCOUNT=0
					BEGIN
						raiserror('ָ�������,���������.',16,1)
						return
					END
				--ȡ���������Ľ��
				select @ChangeAmount=sum(isnull(totalmoney,0))
				from imatdoc_d with(nolock)
				where DocCode=@Doccode
				if @OptionID='2'
					BEGIN
						if left(@FlowInstanceID,2)='DD'
							BEGIN
								select @ChangeFrozenAmount=-@ChangeAmount,@Event='��ֹ����ȡ������������.',
								@SourceDoccode=@doccode,@FrozenStatus='�Ѵ���'
							END
					END
				else
					BEGIN
						raiserror('�������ö�Ȳ�������δ��ʶ��,ִ��ʧ��,����ϵϵͳ����Ա',16,1)
						return
					END
				--ȡ���ϼ��ŵ�,��Ϊ���ö�ȿ���
				select @AccountSdorgid=sdorgid ,@SDorgName=sdorgname from oSDOrg os with(nolock) where os.rowid=@ParentRowID
			END
 /*************************************************�ͻ���*****************************************************/
		--�ͻ���,�������ö��,����Ԥռ���(�ж�����ʱ)
		if @Formid in(4950)
			BEGIN
				--ȡ��������Ϣ,���洢����������ʱ��,�����ȴ���ʱ��ȡ������
				if object_id('tempdb.dbo.sPickorderHD') IS not null
					BEGIN
						select @SDOrgID = os.sdorgid,@ChangeAmount = isnull(cavermoney,0),@ChangeCredit = isnull(cavermoney,0),
						@Refcode = UserTxt1,@ChangeFrozenAmount = 0,@Event = '�����ۼ����ö��.'
						from   #sPickorderHD sph with(nolock)
							   inner join oStorage os with(nolock)on  sph.instcode = os.stCode
						where  DocCode = @Doccode
						select @Rowcount=@@ROWCOUNT
					end
					if isnull(@Rowcount,0)=0
						BEGIN
							select @SDOrgID = os.sdorgid,@ChangeAmount = isnull(cavermoney,0),@ChangeCredit = isnull(cavermoney,0),
							@Refcode = UserTxt1,@ChangeFrozenAmount = 0,@Event = '�����ۼ����ö��.'
							from   sPickorderHD sph with(nolock)
								   inner join oStorage os with(nolock)on  sph.instcode = os.stCode
							where  DocCode = @Doccode
							select @Rowcount=@@ROWCOUNT
						END
				if isnull(@ROWCOUNT,0)=0
					BEGIN
						raiserror('���ݲ�����,�޷������ö�Ƚ��и���.',16,1)
						return
					END
				--ȡ���ϼ��ŵ�,��Ϊ���ö�ȿ���
				select @AccountSdorgid=sdorgid ,@SDorgName=sdorgname from oSDOrg os with(nolock) where os.rowid=@ParentRowID
				--���Ǹ��ݶ��������Ļ�,����Ҫ���ٶ�����,���ٵĶ�����Ϊ�������,���Ƿ���ʱ�Ķ��.
				if isnull(@Refcode,'')!=''
					begin
						--ȡ������
						select @Event=@Event+'���ٶ���������.',@SourceDoccode=a.UserTxt1,@FlowInstanceID=isnull(a.usertxt1,'')
						from imatdoc_h a with(nolock)
						where a.doccode=@Refcode
						if @@rowcount=0
							begin
								raiserror('����ָ�������,�޷�������������Ϣ,�޷��������ö��.',16,1)
								return
							end
						--ֻ�е�������������DD��ͷ�Ķ�����ʱ,�Ŵ������ö��.
						if @SourceDoccode like 'DD%'
							begin
								--ȡָ��ϵķֻ����,���ڼ��ٶ�����.
								select @ChangeFrozenAmount=-sum(isnull(b.totalmoney,0)),@FrozenStatus='�Ѵ���'
								from  imatdoc_d   b with(nolock) 
								where  b.DocCode=@Refcode
								group by b.doccode
							end
					END
			end
/*************************************************�˻���*****************************************************/
		--�˻���,�������ö��
		if @Formid in(4951)
			BEGIN
				select @SDOrgID =os.sdorgid,@ChangeAmount = isnull(-cavermoney, 0),@AccountSdorgid=sph.cltCode2,
				       @ChangeCredit = isnull(-cavermoney,0),@ChangeFrozenAmount = 0,@Event = '�˻����˻����ö��.'
				from   sPickorderHD sph with(nolock)
				       inner join oStorage os with(nolock)on  sph.instcode = os.stCode
				where  DocCode = @Doccode
				if @@ROWCOUNT=0
					BEGIN
						raiserror('���ݲ�����,�޷������ö�Ƚ��и���.',16,1)
						return
					END
 
			    --ȡ���ϼ��ŵ�,��Ϊ���ö�ȿ���
				--select @AccountSdorgid=sdorgid ,@SDorgName=sdorgname from oSDOrg os with(nolock) where os.rowid=@ParentRowID
			end
/*************************************************���ֵ�*****************************************************/
		--���ֵ�,���Ӷ�����,���ö�Ȳ���
		if @Formid in(4956)
			begin
				select  @ChangeAmount=isnull(amount,0),@ChangeCredit=0,@AccountSdorgid=@Sdorgid
				from farcashindoc with(nolock)
				where DocCode=@Doccode
				if @@ROWCOUNT=0
					BEGIN
						raiserror('���ݲ�����,�޷������ö�Ƚ��и���.',16,1)
						return
					END
				if isnull(@OptionID,'')=''
					BEGIN
						select @ChangeFrozenAmount=isnull(@ChangeAmount,0),@Event='���ö�ȷ��ֶ�����.',@FrozenStatus='������'
					end
				--���ֵ�����
				else if @OptionID='2'
					BEGIN
						select @ChangeFrozenAmount=isnull(-@ChangeAmount,0),@Event='���ö������,ȡ��������.',@FrozenStatus='�Ѵ���',@SourceDoccode=@Doccode
					end
				--���������Ͳ�����,���׳��쳣,��ֹ�Ƿ�����
				else
					BEGIN
						raiserror('δ֪��������,ִ��ʧ��!',16,1)
						return
					END
			end
 /*************************************************�����տ*****************************************************/
		--�����տ
		if @Formid in(2041)
			BEGIN
				select  @ChangeAmount=isnull(amount,0),@ChangeCredit=-isnull(amount,0),@refcode=refcode,@Event='�������.',@AccountSdorgid=cltcode
				from farcashindoc with(nolock)
				where DocCode=@Doccode
				if @@ROWCOUNT=0
					BEGIN
						raiserror('���ݲ�����,�޷������ö�Ƚ��и���.',16,1)
						return
					END
				--�ж��Ƿ��Ƿ��ֵ�,���Ƿ��ֵ�����Ҫ���ٷ��ֵ���������
				if isnull(@Refcode,'')!=''
					begin
						--ȡ�������뵥�Ľ����Ϊȡ�������ȵĽ��.������ֱ��ʹ�õ������Ľ����Ϊȡ������Ľ��.
						select @ChangeFrozenAmount=-isnull(amount,0),@Event='���ö�ȷ��ֳɹ�,ȡ��������.',@SourceDoccode=@Refcode,@FrozenStatus='�Ѵ���'
							from farcashindoc with(nolock)
						where DocCode=@refcode
						and @Formid in(4956)
					end
			end
/******************************************************ͳһ������ö��******************************************************/
		--�����ö�Ȳ�����ϢΪ��,���׳��쳣
		if ISNULL(@AccountSdorgid,'')=''
			BEGIN
				raiserror('�����ö�Ȳ�����Ϣ,�ܾ�������Ϣ���,����ϵϵͳ����Ա',16,1)
				return
			END
		---------------------------------------------------------------ȡ�����ö����Ϣ---------------------------------------------------------
 
		--�ֲ�ʽ��ѯ���ö�̬SQL��ʽ
		If @Formid In(9102,9146,9237,6090,9167,9244,9267,6052)
			Begin
				SET @sql = 'select @AvailabBalance=ISNULL(AvailableBalance,0),@OverRunLimit=ISNULL(OverrunLimit,0),@FrozenAmount= ISNULL(FrozenAmount,0), ' + char(10)
				 + '				@Balance=isnull(Balance,0) ' + char(10)
				 + '				from OpenQuery(URP11,''Select AvailableBalance,OverrunLimit,FrozenAmount,Balance From JTURP.dbo.oSDOrgCredit  ' + char(10)
				 + '				where SDorgID='''''+isnull(@AccountSdorgid,'') +'''''' + char(10)
				 + '				and Account=''''113107'''''')'
				--Print @sql
				Exec sp_executesql @sql,N'@AvailabBalance money output,@OverRunLimit money output,@FrozenAmount money output,@Balance money output',
				@AvailabBalance=@AvailabBalance Output,@OverRunLimit=@OverRunLimit Output,@FrozenAmount=@FrozenAmount Output,@Balance=@Balance output
				select @Rowcount=@@ROWCOUNT
 
				--������������,��ȡ���������̵���Ϣ,����־�����Ƿ����.
				if isnull(@StartFlow,0)=0 AND isnull(@FlowInstanceID,'')<>''
					BEGIN
						SET @sql = 'select @FlowFrozenAmount=ISNULL(FrozenAmount,0),@FlowUnFrozenAmount=ISNULL(ProcessedAmount,0),@FlowStatus=ISNULL(FlowStatus,''δ���'')'
						 + '				from OpenQuery(URP11,''Select FrozenAmount,ProcessedAmount ,FlowStatus From JTURP.dbo.oSDOrgCreditFlow  ' + char(10)
						 + '				where FlowInstanceID='''''+isnull(@FlowInstanceID,'') +''''''')' + char(10)
						--Print @sql
						Exec sp_executesql @sql,N'@FlowFrozenAmount money output,@FlowUnFrozenAmount money output,@FlowStatus varchar(50) output',
						@FlowFrozenAmount=@FlowFrozenAmount Output,@FlowUnFrozenAmount=@FlowUnFrozenAmount OUTPUT,@FlowStatus=@FlowStatus output
						SELECT @FlowExists=CASE WHEN @@ROWCOUNT=0 THEN 0 ELSE 1 end
					END
 
			End
		Else
			--�Ƿֲ�ʽ��������ֱ����ɼ���.
			BEGIN
				select @AvailabBalance=ISNULL(osc.AvailableBalance,0),@OverRunLimit=ISNULL(osc.OverrunLimit,0),@FrozenAmount= ISNULL(osc.FrozenAmount,0),
				@Balance=isnull(Balance,0)
				from oSDOrgCredit   osc
				where osc.SDorgID=@AccountSdorgid
				and osc.Account='113107'
				select @Rowcount=@@ROWCOUNT
				--������������,��ȡ���������̵���Ϣ,����־�����Ƿ����.
				if isnull(@StartFlow,0)=0 AND ISNULL(@FlowInstanceID,'')<>''
					BEGIN
						select @FlowFrozenAmount=ISNULL(FrozenAmount,0),@FlowUnFrozenAmount=ISNULL(ProcessedAmount,0),@FlowStatus=ISNULL(FlowStatus,'δ���')
						from dbo.oSDOrgCreditFlow WITH(NOLOCK)
						where FlowInstanceID= @FlowInstanceID
						SELECT @FlowExists=CASE WHEN @@ROWCOUNT=0 THEN 0 ELSE 1 END
					end
			END
		if @ROWCOUNT=0 and @Formid not in (2041)
			BEGIN
				raiserror('�����ڴ˲��ŵ����ö����Ϣ,���ʼ����Ⱥ��ٲ���!',16,1)
				return
			END
		
	---------------------------------------------------------------������ö��------------------------------------------------------------------
		--���ύ��˻�ȷ��ʱ,�����ö�Ƚ��м��
		if isnull(@OptionID,'') in('','1') and @ControlBalance=1
			Begin
				 
				if isnull(@AvailabBalance,0)+isnull(@Commission,0)+isnull(@Rewards,0)-isnull(@ChangeCredit,0)-isnull(@ChangeFrozenAmount,0)+ISNULL(@OverRunLimit,0)+isnull(@DeductAmount,0)<0
					BEGIN
						SELECT @tips = 
						            '�������ö�Ȳ��㣬�뼰ʱ��ֵ��ȷ���Ѿ�ͨ����˵ĵ��ݣ�' + dbo.crlf() +
						            '���ɳ�֧���:'+convert(varchar(50),isnull(@OverRunLimit,0)) + dbo.crlf() +
						            '���Ѷ�����:' + convert(varchar(50),isnull(@FrozenAmount,0))+dbo.crlf()+
						            '����ǰ���:' + convert(varchar(50),isnull(@Balance,0)) + dbo.crlf() +
						            '����ǰ�������:' + convert(varchar(50),ISNULL(@AvailabBalance,0)) + dbo.crlf() +
						            '����Ӧ�۶��:' + convert(varchar(50),isnull(@ChangeCredit,0)) + dbo.crlf() +
						            '����������'+convert(varchar(50),isnull(@ChangeFrozenAmount,0)) + dbo.crlf() +
						            '����Ӷ��'+convert(varchar(50),isnull(@Commission,0)) + dbo.crlf() +
						            '�����Żݽ��'+convert(varchar(50),isnull(@DeductAmount,0)) + dbo.crlf() 
						 RAISERROR(@tips,16,1) 
						 RETURN
					END
			END
		--����״̬����
		IF @FlowExists=1 AND ISNULL(@FlowStatus,'δ���')='�����'
			BEGIN
				RAISERROR('����[%s]�ѽⶳ�Ķ�ȴﵽ������,���̽���,��ֹ��������.',16,1,@flowinstanceid)
				return
			END
			
/******************************************************ͳһ�������ö����Ϣ******************************************************/
			--��֤�ڷֲ�ʽ�������������.
			set xact_abort on
			--��¼��ǰ������.����ǰ�Ѿ�������������������,�����ⲿ������.���ⲿ������,������һ������.
			select @TranCount=@@TRANCOUNT,@Rowcount=0
			if @TranCount=0	begin tran
			begin try
				--�������ö��
				print 606
				--�ֲ�ʽ������Ҫ���ö�̬SQL��ʽ����
				If @Formid In(9102,9146,6090,9167,9244,9267,6052,4950)
					BEGIN
						begin try
							SET @sql = '	update Openquery(URP11,''SELECT FrozenAmount,Balance,ModifyDate,ModifyUser,terminalID,ModifyDoccode '+CHAR(10)
							 + '				From JTURP.dbo.oSDOrgCredit a Where SDOrgID='''''+isnull(@AccountSdorgid,'')+''''' AND Account=''''113107'''''')' + char(10)
							 + '				set    FrozenAmount  = isnull(FrozenAmount,0) + isnull(@ChangeFrozenAmount,0), ' + char(10)
							 + '					   Balance       = isnull(Balance,0) -isnull(@ChangeCredit,0), ' + char(10)
							 + '					   ModifyDate = getdate(), ' + char(10)
							 + '					   ModifyUser = @Usercode, ' + char(10)
							 + '					   terminalID=@TerminalID, ' + char(10)
							 + '					   ModifyDoccode = @Doccode'
							Exec sp_executesql @sql,N'@ChangeFrozenAmount money,@ChangeCredit money, @Usercode varchar(50),@TerminalID varchar(50),@Doccode varchar(50),@AccountSdorgid varchar(50)',
							@ChangeFrozenAmount=@ChangeFrozenAmount,@ChangeCredit=@ChangeCredit,@Usercode=@Usercode,
							@TerminalID=@TerminalID,@Doccode=@Doccode,@AccountSdorgid=@AccountSdorgid
							SELECT @Rowcount=@@ROWCOUNT
						end try
						begin catch
							select @tips=dbo.getLastError('�������ö��ʧ�ܡ�')
							raiserror(@tips,16,1)
							return
						end catch
						--����ʼ����,�����һ����¼.
						if @StartFlow=1
							BEGIN
								Insert into Openquery(URP11,'Select  FlowInstanceID,Formid,FrozenAmount from JTURP.dbo.oSdorgCreditFlow')
								select @FlowInstanceID,@Formid,@ChangeFrozenAmount
							END
					End
				Else
				--���ظ�����ֱ��update
					BEGIN
						update a
						set    FrozenAmount  = isnull(FrozenAmount,0) + isnull(@ChangeFrozenAmount,0),
							   Balance       = isnull(a.Balance,0) -isnull(@ChangeCredit,0),
							   ModifyDate = getdate(),
							   ModifyUser = @Usercode,
							   terminalID=@TerminalID,
							   ModifyDoccode = @Doccode
							  /* output inserted.sdorgid,
							   inserted.account,
							   deleted.overrunlimit,
							   deleted.frozenamount,
							   deleted.balance,
							   deleted.AvailableBalance,
							   inserted.balance,
							   inserted.availableBalance into @table*/
						from   oSDOrgCredit a ---->ע��˴���Ҫ����with(nolock)
						where  a.SDOrgID = @AccountSdorgid
							   and a.Account = '113107'
						SELECT @Rowcount=@@ROWCOUNT
						--����ʼ����,�����һ�������¼.
						if @StartFlow=1
							BEGIN
								Insert into  dbo.oSdorgCreditFlow(FlowInstanceID,Formid,FrozenAmount )
								select @FlowInstanceID,@Formid,@ChangeFrozenAmount
							END
					END
			/*update Openquery(URP11,'SELECT FrozenAmount,Balance,ModifyDate,ModifyUser,terminalID,ModifyDoccode From oSDOrgCredit a Where SDOrgID=''' +@AccountSdorgid+''' ADN Account=''113107'''
				set    FrozenAmount  = isnull(FrozenAmount,0) + isnull(@ChangeFrozenAmount,0),
					   Balance       = isnull(a.Balance,0) -isnull(@ChangeCredit,0),
					   ModifyDate = getdate(),
					   ModifyUser = @Usercode,
					   terminalID=@TerminalID,
					   ModifyDoccode = @Doccode*/

				--��������,��Ҫ����
				if @ROWCOUNT=0
					BEGIN
						--�������ö�ȳ�ʼ��,�����һ����¼.
						if @Formid in(2041)
							BEGIN
								INSERT into oSDOrgCredit( SDOrgID, Account, OverrunLimit, FrozenAmount, Balance, 
								       CreateDate, CreateUser, TerminalID, 
								       CreateDoccode)
								SELECT @AccountSdorgid,'11307',isnull(@OverRunLimit, 0),
								       isnull(@ChangeFrozenAmount,0),isnull(@ChangeCredit,0),getdate(),@Usercode,@TerminalID,@Doccode
							END
						--�������������
						else
							BEGIN
								--���ⲿ������ʱ,�������������������,��Ҫ�ع�ǰ�������.
								--PRINT @AccountSdorgid
								if @trancount=0 and @@TRANCOUNT>0 rollback
								raiserror('δ�������ö����Ϣ,��Ϊ�����ڴ˲��ŵ����ö����Ϣ,���ʼ����Ⱥ��ٲ���!',16,1)
							END
						
					END
				--������¼�¼
				 
				/*
				insert into oSdorgCreditLog( Doccode, FormID, FormType, Docdate, DocType, 
					   Account, [Event], SDorgID, SDorgName, OverRunLimit, 
					   CreditAmount, FrozenAmount, ChangeFrozenAmount, ChangeCredit, 
					   Commission, Rewards, Balance, AvailabBalance, Usercode, 
					   Remark, TerminalID, FrozenStatus, refCode)
				select @Doccode,@Formid,@FormType,getdate(),@Doctype,'113107',@Event,@SDOrgID,@SDorgName,a.OverRunLimit,a.Balance,a.FrozenAmount,
					   @ChangeFrozenAmount,@ChangeCredit,@Commission,@Rewards,a.curBalance,
					   a.curAvailableBalance,@Usercode,@Remark,@TerminalID,@FrozenStatus,
					   @Refcode
				from   @table a
				*/
 
				If @Formid In(9102,9146,9237,6090,9167,9244,9267,6052)
					BEGIN
						Insert into Openquery(URP11,'Select   Doccode, FormID, FormType, Docdate, DocType, 
						   Account, [Event], SDorgID, SDorgName, OverRunLimit, 
						   CreditAmount, FrozenAmount, ChangeFrozenAmount, ChangeCredit, 
						   Commission, Rewards,DeductAmount, Balance, AvailabBalance, Usercode, 
						   Remark, TerminalID, FrozenStatus, refCode,AccountSdorgid,FlowInstanceID from JTURP.dbo.oSdorgCreditLog')
						select @Doccode,@Formid,@FormType,getdate(),@Doctype,'113107',@Event,@SDOrgID,@SDorgName,@OverRunLimit,@Balance,@FrozenAmount,
							   @ChangeFrozenAmount,@ChangeCredit,@Commission,@Rewards,@DeductAmount,isnull(@Balance,0) -isnull(@ChangeCredit,0),
							   isnull(@AvailabBalance,0)-isnull(@ChangeFrozenAmount,0)-isnull(@ChangeCredit,0),@Usercode,@Remark,@TerminalID,
							   CASE  
										WHEN @FrozenStatus='�Ѵ���' and @FlowExists=1 and isnull(@FlowStatus,'')='δ���' then '������'
										else @FrozenStatus
								end, 
							   @Refcode,@AccountSdorgid,@FlowInstanceID
 
						--������ʼ�ڵ�Ĵ�����,���޸��Ѵ�����.
						 if isnull(@StartFlow,0)=0 AND ISNULL(@FlowExists,0)=1
							BEGIN
								SET @sql = '			update Openquery(URP11,''SELECT ProcessedAmount,ModifyDate,ModifyUser,terminalID,ModifyDoccode,FlowStatus,FrozenAmount From JTURP.dbo.oSDOrgCreditFlow a Where FlowInstanceID='''''+isnull(@FlowInstanceID,'')+'''''''   )' + char(10)
									 + '				set    ProcessedAmount  = isnull(ProcessedAmount,0) - isnull(@ChangeFrozenAmount,0), ' + char(10)
									 +'				FlowStatus=CASE WHEN isnull(ProcessedAmount,0) - isnull(@ChangeFrozenAmount,0)>=ISNULL(FrozenAmount,0) THEN ''�����'' else isnull(FlowStatus,''δ���'') end,' +char(10)
									 + '					   ModifyDate = getdate(), ' + char(10)
									 + '					   ModifyUser = @Usercode, ' + char(10)
									 + '					   terminalID=@TerminalID, ' + char(10)
									 + '					   ModifyDoccode= @Doccode'
									Exec sp_executesql @sql,N'@ChangeFrozenAmount money,@ChangeCredit money, @Usercode varchar(50),@TerminalID varchar(50),@Doccode varchar(50),@AccountSdorgid varchar(50)',
									@ChangeFrozenAmount=@ChangeFrozenAmount,@ChangeCredit=@ChangeCredit,@Usercode=@Usercode,
									@TerminalID=@TerminalID,@Doccode=@Doccode,@AccountSdorgid=@AccountSdorgid 
							END
					End
				Else
					BEGIN
						insert into oSdorgCreditLog( Doccode, FormID, FormType, Docdate, DocType, 
						   Account, [Event], SDorgID, SDorgName, OverRunLimit, 
						   CreditAmount, FrozenAmount, ChangeFrozenAmount, ChangeCredit, 
						   Commission, Rewards,DeductAmount, Balance, AvailabBalance, Usercode, 
						   Remark, TerminalID, FrozenStatus, refCode,AccountSdorgid,FlowInstanceID)
						select @Doccode,@Formid,@FormType,getdate(),@Doctype,'113107',@Event,@SDOrgID,@SDorgName,@OverRunLimit,@Balance,@FrozenAmount,
							   @ChangeFrozenAmount,@ChangeCredit,@Commission,@Rewards,@DeductAmount,isnull(@Balance,0) -isnull(@ChangeCredit,0),
							   isnull(@AvailabBalance,0)-isnull(@ChangeFrozenAmount,0)-isnull(@ChangeCredit,0),@Usercode,@Remark,@TerminalID,
							   CASE  
										WHEN @FrozenStatus='�Ѵ���' and isnull(@FlowExists,0)=1 and isnull(@FlowStatus,'')='δ���' then '������'
										else @FrozenStatus
								end,
							   @Refcode,@AccountSdorgid,@FlowInstanceID
						--������ʼ�ڵ�Ĵ�����,���޸��Ѵ�����.
						 if   isnull(@StartFlow,0)=0 AND ISNULL(@FlowExists,0)=1
							BEGIN
								update a
								set ProcessedAmount  = isnull(ProcessedAmount,0) - isnull(@ChangeFrozenAmount,0),
									   ModifyDate = getdate(),
									   ModifyUser = @Usercode,
									   terminalID=@TerminalID,
									   ModifyDoccode = @Doccode 
									   ,FlowStatus=CASE WHEN isnull(ProcessedAmount,0) - isnull(@ChangeFrozenAmount,0)>=ISNULL(a.FrozenAmount,0) THEN '�����' else isnull(a.FlowStatus,'δ���') end
								from   oSDOrgCreditFlow a
								where a.flowInstanceID=@FlowInstanceID
							end
					END
 
				--����ԭʼ����,�Ҷ���״̬�������ʱ,����ԭ������״̬
				if  isnull(@SourceDoccode,'')!='' and @FrozenStatus = '�Ѵ���'
				Begin
					If  @Formid In(9102,9146,9237,6090,9167,9244,9267,4950,6093,6052)
						BEGIN
							/*Update Openquery(URP11,'Select frozenstatus,Refcode From oSdorgCreditLog  where  Doccode  ='''+ @SourceDoccode+'''and frozenStatus  = ''������''')
							set    frozenstatus      = @FrozenStatus,
								   Refcode           = @SourceDoccode
							*/
							--�����̴���,���Ѵ����ȴ��ڵ��ڶ�����,����ֹ����.
							IF @FlowExists=1 AND ISNULL(@FlowFrozenAmount,0)<=ISNULL(@FlowUnFrozenAmount,0)-ISNULL(@ChangeFrozenAmount,0)  AND ISNULL(@FlowInstanceID,'')<>''
								BEGIN
									SET @sql = 'Update Openquery(URP11,''Select frozenstatus,Refcode From JTURP.dbo.oSdorgCreditLog  where  FlowInstanceID  ='''''+ isnull(@FlowInstanceID,'')+''''''+char(10)+
									 ' and frozenStatus  = ''''������'''''')' + char(10)
											 + '							set    frozenstatus      = ''�Ѵ���'', ' + char(10)
											 + '								   Refcode           = @Doccode'
									--Print @sql
									Exec sp_executesql @sql,N'@SourceDoccode varchar(30),@FrozenStatus varchar(20),@Doccode varchar(50)',
									@SourceDoccode=@SourceDoccode,@FrozenStatus=@FrozenStatus,@Doccode=@Doccode
									--�������ѽ���,���Խ�δʹ�õ��Ż�ȯ��ԭ.
									--exec URP11.JTURP.dbo.sp_UpdateCouponsFlow @Formid,@Doccode,@FlowInstanceID,'�����','',@Usercode,@terminalid
								END
							IF ISNULL(@FlowExists,0)=0
								BEGIN
									SET @sql = 'Update Openquery(URP11,''Select frozenstatus,Refcode From JTURP.dbo.oSdorgCreditLog  where  Doccode  ='''''+ isnull(@SourceDoccode,'')+''''''+char(10)+
									 '  and frozenStatus  = ''''������'''''')  ' + char(10)
											 + '							set    frozenstatus      = @FrozenStatus, ' + char(10)
											 + '								   Refcode           = @Doccode'
									--Print @sql
									Exec sp_executesql @sql,N'@SourceDoccode varchar(30),@FrozenStatus varchar(20),@Doccode varchar(50)',
									@SourceDoccode=@SourceDoccode,@FrozenStatus=@FrozenStatus,@Doccode=@Doccode
									
								END
						End
					Else
						BEGIN
							IF @FlowExists=1 AND ISNULL(@FlowFrozenAmount,0)<=ISNULL(@FlowUnFrozenAmount,0)-ISNULL(@ChangeFrozenAmount,0) AND ISNULL(@FlowInstanceID,'')<>''
								BEGIN
									update oSdorgCreditLog
									set    frozenstatus      = @FrozenStatus,
										   Refcode           = @SourceDoccode
									WHERE FlowInstanceID=@FlowInstanceID
										   and frozenStatus  = '������'
									--�������ѽ���,���Խ�δʹ�õ��Ż�ȯ��ԭ.
									--exec sp_UpdateCouponsFlow @Formid,@Doccode,@FlowInstanceID,'�����','',@Usercode,@terminalid
								END
							IF ISNULL(@FlowExists,0)=0
								BEGIN
									update oSdorgCreditLog
									set    frozenstatus      = @FrozenStatus,
										   Refcode           = @SourceDoccode
									where  Doccode           = @SourceDoccode
										   and frozenStatus  = '������'
								END
						END
				END
				 
				--���ⲿ������ʱ,��ǰ��Ĵ�������������,��Ҫ�ύ֮.
				if @TranCount =0 commit
			end try
			begin catch

				if @TranCount=0 and @@TRANCOUNT>0  rollback
				
				select @tips=dbo.getLastError('�������ö��ʧ��!' )
				raiserror(@tips,16,1)
				return
			end catch	
	end
 