/*
��������:sp_UpdateCredit
����:�������ö��
����:������
����ֵ:��
��д:���ϵ�
ʱ��:2012-08-17
����˵��:
��ע: 1.�Թ��̶Խ���൱����. 2.Ҫע������������ʹ��.�����Ƿֲ�ʽ����. 3.�κ������ֶλ����,��Ҫ����ISNULL. 4.�ѻ�һ�п��ܷ������쳣,���������ܷ�����.
begin tran
exec [sp_UpdateCredit] 6090,'DD20120924000020','2.1.769.02.04',0,'2'
rollback
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
		        @Event               varchar(50),					--�¼�
		        @tips					varchar(500),				--��ʾ��Ϣ
		        --�޸�ǰ�Ķ����Ϣ
		        @OverRunLimit        money,							--�ɳ�֧���
		        @Credit              money,							--���ö��
		        @Balance             money,							--���ö�����(=���ö��-����Ӧ�۶��)
		        @FrozenAmount        money,							--�Ѷ�����
		        @AvailabBalance      money,							--��ǰ���ö��(=���ö��+�ɳ�֧���-�Ѷ�����-����������-����Ӧ�۶��)
		        --�޸ĵĶ����Ϣ
		        @ChangeCredit        money,							--����Ӧ�۶��
		        @ChangeFrozenAmount  money,							--����������
				@ChangeAmount	money,								--Ӧ�ս��.���ֶ����ύ���ʱ�Ƕ�����,��ȷ��ʱ�ǿ۶�Ƚ��.
				@Commission	money,									--Ӷ��
				@Rewards	money,									--�ֽ���
				@Refcode varchar(50),								--���õ���
				@AccountSdorgid varchar(50),						--���ö�ȿ����ŵ�
				@dptType varchar(50),								--�ŵ�����
				@minType varchar(50),								--��������
				@ParentRowID varchar(50),							--�����ϼ��ڵ�
				@SourceDoccode varchar(20),							--Դ����.ָȡ��������ʱ��ԭ�����ȵĵ���.
				@FrozenStatus varchar(20),							--���ö�ȶ���״̬,�ύ���ʱ"�Ѷ���",ȷ��ʱ"��ȡ��"
				@Doctype varchar(50),								--��������
				@FormType int,										--����ģ������
				@TranCount int,										--������
				@Rowcount int,
				@sql nvarchar(max),
				@osdtype varchar(50)	
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

if @Formid not in(9102,9146,9237,9167,9244,6090,4950,2401,4956,9267,2041,4951,6052) return
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
		
/*************************************************����ҵ��*****************************************************/
		--����
		if @Formid in(9102,9146,9237)
			begin
				--ȡ��������Ϣ,���洢����������ʱ��,�����ȴ���ʱ��ȡ������
				if object_id('tempdb.dbo.Unicom_Orders') is null
					BEGIN
						select @ChangeAmount=isnull(totalmoney2,0),@Commission=isnull(uo.commission,0),@Rewards=isnull(uo.rewards,0)
						from Unicom_Orders uo with(nolock)
						where uo.DocCode=@Doccode
						select @Rowcount=@@ROWCOUNT
					END
				else
					BEGIN
						select @ChangeAmount=isnull(totalmoney2,0),@Commission=isnull(uo.commission,0),@Rewards=isnull(uo.rewards,0)
						from #Unicom_Orders uo with(nolock)
						where uo.DocCode=@Doccode
						select @Rowcount=@@ROWCOUNT
						--���û��,��Ŭ������һ��,��Ҫ����.
						if @Rowcount=0
							BEGIN
								select @ChangeAmount=isnull(totalmoney2,0),@Commission=isnull(uo.commission,0),@Rewards=isnull(uo.rewards,0)
								from Unicom_Orders uo with(nolock)
								where uo.DocCode=@Doccode
								select @Rowcount=@@ROWCOUNT
							END
					END
					--ʵ��û�еĻ�,ֻ���׳��쳣��.
					if @ROWCOUNT=0
							BEGIN
								raiserror('���ݲ�����,�޷������ö�Ƚ��и���.',16,1)
								return
							END
				--�ύ���,���ö�Ȳ���,����Ԥռ���
				if @OptionID='1'
					BEGIN
						select @ChangeFrozenAmount=@ChangeAmount,@ChangeCredit=0,@Event='�����ύ��˶�����',@FrozenStatus='������'
					end
				--�˻����,ȡ��������
				else if @OptionID='2'
					BEGIN
						select @ChangeFrozenAmount= - @ChangeAmount,@ChangeCredit=0,@Event='����ȡ��,ȡ��������',@FrozenStatus='�Ѵ���',@SourceDoccode=@Doccode
					END

				--ȷ�ϵ���,�����ö��,����Ԥռ���
				else if @OptionID=''
					BEGIN
						select @ChangeCredit=@ChangeAmount-@Commission,@ChangeFrozenAmount=-@ChangeAmount,@Event='ȷ�ϵ��ݿۼ����,ȡ��������.',@SourceDoccode=@Doccode,@FrozenStatus='�Ѵ���'
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
						select @ChangeCredit=0,@ChangeFrozenAmount=  -@ChangeAmount,@ChangeCredit=0,@Event='��ֵʧ��,ȡ��������.',@FrozenStatus='�Ѵ���',@SourceDoccode=@Doccode
					end
				--ȷ�ϵ���,�����ö��,����Ԥռ���
				else if @OptionID=''
					BEGIN
						select @ChangeCredit=@ChangeAmount,@ChangeFrozenAmount=-@ChangeAmount,@Event='��ֵ�ɹ��ۼ����ö��,ȡ��������.',@SourceDoccode=@Doccode,@FrozenStatus='�Ѵ���' 
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
				if @OptionID in('','2')
					begin
						select @ChangeAmount=isnull(SumNetMoney,0)
						from ord_shopbestgoodsdoc with(nolock)
						where DocCode=@Doccode
						select @rowcount=@@rowcount
					end
				--�ֻ�ʱȡ���.
				if @OptionID in('3')
					begin
						select @ChangeAmount=isnull(SumNetMoney,0)-isnull(userdigit4,0)
						from ord_shopbestgoodsdoc with(nolock)
						where DocCode=@Doccode
						select @rowcount=@@rowcount
					end
				if @ROWCOUNT=0
					BEGIN
						raiserror('���ݲ�����,�޷������ö�Ƚ��и���.',16,1)
						return
					END
				--���϶���,ȡ����ȶ���
				if @OptionID='2'
					BEGIN
						select @ChangeFrozenAmount=-@ChangeAmount,@Event='��������,ȡ��������.',@SourceDoccode=@Doccode,@FrozenStatus='�Ѵ���'
					end
				--�ֻ�ȡ���
				else if @OptionID='3'
					BEGIN
						select @ChangeFrozenAmount=-@ChangeAmount,@Event='�ֻ�������.',@FrozenStatus='������'
					END
				--ȷ�϶���,������
				else if @OptionID=''
					BEGIN
						select @ChangeFrozenAmount=@ChangeAmount,@Event='����������.',@FrozenStatus='������'
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
		--����ָ���ֹ����
		if @Formid in(6052)
			BEGIN
				--����ƽ̨�˴�ȡ�ֻ����.
				select @ChangeAmount=isnull(b.userdigit4,0),@Refcode=b.DocCode
				from imatdoc_h a with(nolock) 
				inner join ord_shopbestgoodsdoc b with(nolock) on a.UserTxt1=b.DocCode 
				where a.FormID=6052 
				and a.DocCode=@doccode
				and b.FormID=6090
				and b.phflag='�Ѵ���'
				if @@ROWCOUNT=0
					BEGIN
						raiserror('��ָ�û�д�����Ķ�����,�޷������ö�Ƚ��в���',16,1)
						return
					END
				if @OptionID='2'
					BEGIN
						select @ChangeFrozenAmount=-@ChangeAmount,@Event='��ֹ����ȡ������������.',@SourceDoccode=@doccode,@FrozenStatus='�Ѵ���'
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
				if object_id('tempdb.dbo.sPickorderHD') is null
					BEGIN
						select @SDOrgID = os.sdorgid,@ChangeAmount = isnull(cavermoney,0),@ChangeCredit = isnull(cavermoney,0),
						@Refcode = UserTxt1,@ChangeFrozenAmount = 0,@Event = '�����ۼ����ö��.'
						from   sPickorderHD sph with(nolock)
							   inner join oStorage os with(nolock)on  sph.instcode = os.stCode
						where  DocCode = @Doccode
						select @Rowcount=@@ROWCOUNT
					END
				else
					BEGIN
						select @SDOrgID = os.sdorgid,@ChangeAmount = isnull(cavermoney,0),@ChangeCredit = isnull(cavermoney,0),
						@Refcode = UserTxt1,@ChangeFrozenAmount = 0,@Event = '�����ۼ����ö��.'
						from   #sPickorderHD sph with(nolock)
							   inner join oStorage os with(nolock)on  sph.instcode = os.stCode
						where  DocCode = @Doccode
						select @Rowcount=@@ROWCOUNT
						if @Rowcount=0
							BEGIN
								select @SDOrgID = os.sdorgid,@ChangeAmount = isnull(cavermoney,0),@ChangeCredit = isnull(cavermoney,0),
								@Refcode = UserTxt1,@ChangeFrozenAmount = 0,@Event = '�����ۼ����ö��.'
								from   sPickorderHD sph with(nolock)
									   inner join oStorage os with(nolock)on  sph.instcode = os.stCode
								where  DocCode = @Doccode
								select @Rowcount=@@ROWCOUNT
							END
					END
				if @ROWCOUNT=0
					BEGIN
						raiserror('���ݲ�����,�޷������ö�Ƚ��и���.',16,1)
						return
					END
				--ȡ���ϼ��ŵ�,��Ϊ���ö�ȿ���
				select @AccountSdorgid=sdorgid ,@SDorgName=sdorgname from oSDOrg os with(nolock) where os.rowid=@ParentRowID
				--���Ǹ��ݶ��������Ļ�,����Ҫ���ٶ�����,���ٵĶ�����Ϊ�������,���Ƿ���ʱ�Ķ��.
				if isnull(@Refcode,'')!=''
					begin
						--����ƽ̨�˴�ȡ�ֻ����.
						select @ChangeFrozenAmount=-isnull(b.userdigit4,0),@Event=@Event+'ȡ������������.',@SourceDoccode=b.doccode,@FrozenStatus='�Ѵ���'
						from imatdoc_h a with(nolock) 
						inner join ord_shopbestgoodsdoc b with(nolock) on a.UserTxt1=b.DocCode 
						where a.FormID=6052 
						and a.DocCode=@Refcode
						and b.FormID=6090
						and b.phflag='�Ѵ���'
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
		If @Formid In(9102,9146,9237,6090,9167,9244,9267)
			Begin
				SET @sql = 'select @AvailabBalance=ISNULL(AvailableBalance,0),@OverRunLimit=ISNULL(OverrunLimit,0),@FrozenAmount= ISNULL(FrozenAmount,0), ' + char(10)
				 + '				@Balance=isnull(Balance,0) ' + char(10)
				 + '				from OpenQuery(URP11,''Select AvailableBalance,OverrunLimit,FrozenAmount,Balance From JTURP.dbo.oSDOrgCredit  ' + char(10)
				 + '				where SDorgID='''''+@AccountSdorgid +'''''' + char(10)
				 + '				and Account=''''113107'''''')'
				--Print @sql
				Exec sp_executesql @sql,N'@AvailabBalance money output,@OverRunLimit money output,@FrozenAmount money output,@Balance money output',
				@AvailabBalance=@AvailabBalance Output,@OverRunLimit=@OverRunLimit Output,@FrozenAmount=@FrozenAmount Output,@Balance=@Balance output
				select @Rowcount=@@ROWCOUNT
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
				 
				if isnull(@AvailabBalance,0)+isnull(@Commission,0)+isnull(@Rewards,0)-isnull(@ChangeCredit,0)-isnull(@ChangeFrozenAmount,0)<0
					BEGIN
						SELECT @tips = 
						            '�������ö�Ȳ��㣬�뼰ʱ��ֵ��ȷ���Ѿ�ͨ����˵ĵ��ݣ�' + dbo.crlf() +
						            '����ǰ���:' + convert(varchar(50),isnull(@Balance,0)) + dbo.crlf() +
						            '�ɳ�֧���:'+convert(varchar(50),isnull(@OverRunLimit,0)) + dbo.crlf() +
						            '����Ӧ�۶��:' + convert(varchar(50),isnull(@ChangeCredit,0)) + dbo.crlf() +
						            '������:' + convert(varchar(50),isnull(@FrozenAmount,0))
						 RAISERROR(@tips,16,1) 
						 RETURN
					END
			END
/******************************************************ͳһ�������ö����Ϣ******************************************************/
			--��֤�ڷֲ�ʽ�������������.
			set xact_abort on
			--��¼��ǰ������.����ǰ�Ѿ�������������������,�����ⲿ������.���ⲿ������,������һ������.
			select @TranCount=@@TRANCOUNT	
			if @TranCount=0	begin tran
			begin try
				--�������ö��
				--�ֲ�ʽ������Ҫ���ö�̬SQL��ʽ����
				If @Formid In(9102,9146,9237,6090,9167,9244,9267)
					BEGIN
						SET @sql = '			update Openquery(URP11,''SELECT FrozenAmount,Balance,ModifyDate,ModifyUser,terminalID,ModifyDoccode From JTURP.dbo.oSDOrgCredit a Where SDOrgID='''''+@AccountSdorgid+''''' AND Account=''''113107'''''')' + char(10)
						 + '				set    FrozenAmount  = isnull(FrozenAmount,0) + isnull(@ChangeFrozenAmount,0), ' + char(10)
						 + '					   Balance       = isnull(Balance,0) -isnull(@ChangeCredit,0), ' + char(10)
						 + '					   ModifyDate = getdate(), ' + char(10)
						 + '					   ModifyUser = @Usercode, ' + char(10)
						 + '					   terminalID=@TerminalID, ' + char(10)
						 + '					   ModifyDoccode = @Doccode'
 
						Exec sp_executesql @sql,N'@ChangeFrozenAmount money,@ChangeCredit money, @Usercode varchar(50),@TerminalID varchar(50),@Doccode varchar(50),@AccountSdorgid varchar(50)',
						@ChangeFrozenAmount=@ChangeFrozenAmount,@ChangeCredit=@ChangeCredit,@Usercode=@Usercode,@TerminalID=@TerminalID,@Doccode=@Doccode,@AccountSdorgid=@AccountSdorgid
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
					END
				
			/*update Openquery(URP11,'SELECT FrozenAmount,Balance,ModifyDate,ModifyUser,terminalID,ModifyDoccode From oSDOrgCredit a Where SDOrgID=''' +@AccountSdorgid+''' ADN Account=''113107'''
				set    FrozenAmount  = isnull(FrozenAmount,0) + isnull(@ChangeFrozenAmount,0),
					   Balance       = isnull(a.Balance,0) -isnull(@ChangeCredit,0),
					   ModifyDate = getdate(),
					   ModifyUser = @Usercode,
					   terminalID=@TerminalID,
					   ModifyDoccode = @Doccode*/
			

				--��������,��Ҫ����
				if @@ROWCOUNT=0
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
								if @trancount=0 and @@TRANCOUNT>0 rollback
								raiserror('�����ڴ˲��ŵ����ö����Ϣ,���ʼ����Ⱥ��ٲ���!',16,1)
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
				If @Formid In(9102,9146,9237,6090,9167,9244,9267)
					BEGIN
						Insert into Openquery(URP11,'Select   Doccode, FormID, FormType, Docdate, DocType, 
						   Account, [Event], SDorgID, SDorgName, OverRunLimit, 
						   CreditAmount, FrozenAmount, ChangeFrozenAmount, ChangeCredit, 
						   Commission, Rewards, Balance, AvailabBalance, Usercode, 
						   Remark, TerminalID, FrozenStatus, refCode,AccountSdorgid from JTURP.dbo.oSdorgCreditLog')
						select @Doccode,@Formid,@FormType,getdate(),@Doctype,'113107',@Event,@SDOrgID,@SDorgName,@OverRunLimit,@Balance,@FrozenAmount,
							   @ChangeFrozenAmount,@ChangeCredit,@Commission,@Rewards,isnull(@Balance,0) -isnull(@ChangeCredit,0),
							   isnull(@AvailabBalance,0)-isnull(@ChangeFrozenAmount,0)-isnull(@ChangeCredit,0),@Usercode,@Remark,@TerminalID,@FrozenStatus,
							   @Refcode,@AccountSdorgid
					End
				Else
					BEGIN
						insert into oSdorgCreditLog( Doccode, FormID, FormType, Docdate, DocType, 
						   Account, [Event], SDorgID, SDorgName, OverRunLimit, 
						   CreditAmount, FrozenAmount, ChangeFrozenAmount, ChangeCredit, 
						   Commission, Rewards, Balance, AvailabBalance, Usercode, 
						   Remark, TerminalID, FrozenStatus, refCode,AccountSdorgid)
						select @Doccode,@Formid,@FormType,getdate(),@Doctype,'113107',@Event,@SDOrgID,@SDorgName,@OverRunLimit,@Balance,@FrozenAmount,
							   @ChangeFrozenAmount,@ChangeCredit,@Commission,@Rewards,isnull(@Balance,0) -isnull(@ChangeCredit,0),
							   isnull(@AvailabBalance,0)-isnull(@ChangeFrozenAmount,0)-isnull(@ChangeCredit,0),@Usercode,@Remark,@TerminalID,@FrozenStatus,
							   @Refcode,@AccountSdorgid
					END
				--����ԭʼ����,�Ҷ���״̬�������ʱ,����ԭ������״̬
				if isnull(@SourceDoccode,'') != ''
				   and @FrozenStatus = '�Ѵ���'
				Begin
					If  @Formid In(9102,9146,9237,6090,9167,9244,9267)
						BEGIN
							/*Update Openquery(URP11,'Select frozenstatus,Refcode From oSdorgCreditLog  where  Doccode  ='''+ @SourceDoccode+'''and frozenStatus  = ''������''')
							set    frozenstatus      = @FrozenStatus,
								   Refcode           = @SourceDoccode
							*/
							SET @sql = 'Update Openquery(URP11,''Select frozenstatus,Refcode From JTURP.dbo.oSdorgCreditLog  where  Doccode  ='''''+ @SourceDoccode+'''''and frozenStatus  = ''''������'''''') ' + char(10)
									 + '							set    frozenstatus      = @FrozenStatus, ' + char(10)
									 + '								   Refcode           = @SourceDoccode'
							Print @sql
							Exec sp_executesql @sql,N'@SourceDoccode varchar(30),@FrozenStatus varchar(20)',
							@SourceDoccode=@SourceDoccode,@FrozenStatus=@FrozenStatus
						End
					Else
						BEGIN
							update oSdorgCreditLog
							set    frozenstatus      = @FrozenStatus,
								   Refcode           = @SourceDoccode
							where  Doccode           = @SourceDoccode
								   and frozenStatus  = '������'
						END
					
				end
				--���ⲿ������ʱ,��ǰ��Ĵ�������������,��Ҫ�ύ֮.
				if @TranCount =0 commit
			end try
			begin catch
				if @TranCount=0 and @@TRANCOUNT>0 rollback
				select @tips='�������ö��ʧ��!'+dbo.crlf()+'�쳣��Ϣ:' +isnull(error_message(),'')+dbo.crlf()+'����ϵϵͳ����Ա.'
				raiserror(@tips,16,1)
				return
			end catch	
	end
/*
USE [URPDB]
GO

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_oSDOrgCredit_OverrunLimit]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[oSDOrgCredit] DROP CONSTRAINT [DF_oSDOrgCredit_OverrunLimit]
END

GO

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_oSDOrgCredit_FrozenAmount]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[oSDOrgCredit] DROP CONSTRAINT [DF_oSDOrgCredit_FrozenAmount]
END

GO

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_oSDOrgCredit_Balance]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[oSDOrgCredit] DROP CONSTRAINT [DF_oSDOrgCredit_Balance]
END

GO

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_oSDOrgCredit_CreateDate]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[oSDOrgCredit] DROP CONSTRAINT [DF_oSDOrgCredit_CreateDate]
END

GO

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_oSDOrgCredit_ModifyDate]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[oSDOrgCredit] DROP CONSTRAINT [DF_oSDOrgCredit_ModifyDate]
END

GO

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_oSDOrgCredit_APPName]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[oSDOrgCredit] DROP CONSTRAINT [DF_oSDOrgCredit_APPName]
END

GO

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_oSDOrgCredit_sUserName]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[oSDOrgCredit] DROP CONSTRAINT [DF_oSDOrgCredit_sUserName]
END

GO

USE [URPDB]
GO

 
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[oSDOrgCredit]') AND type in (N'U'))
DROP TABLE [dbo].[oSDOrgCredit]
GO

USE [URPDB]
GO

 
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[oSDOrgCredit](
	[SDOrgID] [varchar](30) NOT NULL,
	[Account] [varchar](10) NOT NULL,
	[OverrunLimit] [money] NULL,
	[FrozenAmount] [money] NULL,
	[Balance] [money] NULL,
	[AvailableBalance]  AS ((isnull([OverrunLimit],(0))+isnull([Balance],(0)))-isnull([FrozenAmount],(0))),
	[CreateDoccode] [varchar](50) NULL,
	[CreateDate] [datetime] NULL,
	[CreateUser] [varchar](50) NULL,
	[ModifyDoccode] [varchar](50) NULL,
	[ModifyDate] [datetime] NULL,
	[ModifyUser] [varchar](50) NULL,
	[APPName] [varchar](500) NULL,
	[sUserName] [varchar](50) NULL,
	[TerminalID] [varchar](50) NULL,
 CONSTRAINT [PK_oSDOrgCredit] PRIMARY KEY CLUSTERED 
(
	[SDOrgID] ASC,
	[Account] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[oSDOrgCredit] ADD  CONSTRAINT [DF_oSDOrgCredit_OverrunLimit]  DEFAULT ((0)) FOR [OverrunLimit]
GO

ALTER TABLE [dbo].[oSDOrgCredit] ADD  CONSTRAINT [DF_oSDOrgCredit_FrozenAmount]  DEFAULT ((0)) FOR [FrozenAmount]
GO

ALTER TABLE [dbo].[oSDOrgCredit] ADD  CONSTRAINT [DF_oSDOrgCredit_Balance]  DEFAULT ((0)) FOR [Balance]
GO

ALTER TABLE [dbo].[oSDOrgCredit] ADD  CONSTRAINT [DF_oSDOrgCredit_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
GO

ALTER TABLE [dbo].[oSDOrgCredit] ADD  CONSTRAINT [DF_oSDOrgCredit_ModifyDate]  DEFAULT (getdate()) FOR [ModifyDate]
GO

ALTER TABLE [dbo].[oSDOrgCredit] ADD  CONSTRAINT [DF_oSDOrgCredit_APPName]  DEFAULT (app_name()) FOR [APPName]
GO

ALTER TABLE [dbo].[oSDOrgCredit] ADD  CONSTRAINT [DF_oSDOrgCredit_sUserName]  DEFAULT (suser_name()) FOR [sUserName]
GO





USE [URPDB]
GO

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_oSdorgCreditLog_OverRunLimit]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[oSdorgCreditLog] DROP CONSTRAINT [DF_oSdorgCreditLog_OverRunLimit]
END

GO

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_oSdorgCreditLog_CreditAmount]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[oSdorgCreditLog] DROP CONSTRAINT [DF_oSdorgCreditLog_CreditAmount]
END

GO

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_Table_1_FrozenLimit]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[oSdorgCreditLog] DROP CONSTRAINT [DF_Table_1_FrozenLimit]
END

GO

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_oSdorgCreditLog_ChangeFrozenAmount]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[oSdorgCreditLog] DROP CONSTRAINT [DF_oSdorgCreditLog_ChangeFrozenAmount]
END

GO

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_oSdorgCreditLog_ChangeAmount]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[oSdorgCreditLog] DROP CONSTRAINT [DF_oSdorgCreditLog_ChangeAmount]
END

GO

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_oSdorgCreditLog_Commission]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[oSdorgCreditLog] DROP CONSTRAINT [DF_oSdorgCreditLog_Commission]
END

GO

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_oSdorgCreditLog_Rewards]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[oSdorgCreditLog] DROP CONSTRAINT [DF_oSdorgCreditLog_Rewards]
END

GO

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_oSdorgCreditLog_Balance]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[oSdorgCreditLog] DROP CONSTRAINT [DF_oSdorgCreditLog_Balance]
END

GO

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_oSdorgCreditLog_AvailabBalance]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[oSdorgCreditLog] DROP CONSTRAINT [DF_oSdorgCreditLog_AvailabBalance]
END

GO

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_oSdorgCreditLog_APPName]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[oSdorgCreditLog] DROP CONSTRAINT [DF_oSdorgCreditLog_APPName]
END

GO

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_oSdorgCreditLog_sUserName]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[oSdorgCreditLog] DROP CONSTRAINT [DF_oSdorgCreditLog_sUserName]
END

GO

USE [URPDB]
GO 
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[oSdorgCreditLog]') AND type in (N'U'))
DROP TABLE [dbo].[oSdorgCreditLog]
GO

USE [URPDB]
GO

 
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[oSdorgCreditLog](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Doccode] [varchar](50) NULL,
	[FormID] [int] NULL,
	[FormType] [int] NULL,
	[Docdate] [datetime] NULL,
	[DocType] [varchar](50) NULL,
	[Account] [varchar](50) NULL,
	[Event] [varchar](50) NULL,
	[SDorgID] [varchar](50) NULL,
	[SDorgName] [varchar](50) NULL,
	[OverRunLimit] [money] NULL,
	[CreditAmount] [money] NULL,
	[FrozenAmount] [money] NULL,
	[ChangeFrozenAmount] [money] NULL,
	[ChangeCredit] [money] NULL,
	[Commission] [money] NULL,
	[Rewards] [money] NULL,
	[Balance] [money] NULL,
	[AvailabBalance] [money] NULL,
	[Usercode] [varchar](50) NULL,
	[Remark] [varchar](500) NULL,
	[TerminalID] [varchar](50) NULL,
	[APPName] [varchar](500) NULL,
	[sUserName] [varchar](50) NULL,
	[Frozenstatus] [varchar](50) NULL,
	[refCode] [varchar](50) NULL,
 CONSTRAINT [PK_oSdorgCreditLog] PRIMARY KEY NONCLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[oSdorgCreditLog] ADD  CONSTRAINT [DF_oSdorgCreditLog_OverRunLimit]  DEFAULT ((0)) FOR [OverRunLimit]
GO

ALTER TABLE [dbo].[oSdorgCreditLog] ADD  CONSTRAINT [DF_oSdorgCreditLog_CreditAmount]  DEFAULT ((0)) FOR [CreditAmount]
GO

ALTER TABLE [dbo].[oSdorgCreditLog] ADD  CONSTRAINT [DF_Table_1_FrozenLimit]  DEFAULT ((0)) FOR [FrozenAmount]
GO

ALTER TABLE [dbo].[oSdorgCreditLog] ADD  CONSTRAINT [DF_oSdorgCreditLog_ChangeFrozenAmount]  DEFAULT ((0)) FOR [ChangeFrozenAmount]
GO

ALTER TABLE [dbo].[oSdorgCreditLog] ADD  CONSTRAINT [DF_oSdorgCreditLog_ChangeAmount]  DEFAULT ((0)) FOR [ChangeCredit]
GO

ALTER TABLE [dbo].[oSdorgCreditLog] ADD  CONSTRAINT [DF_oSdorgCreditLog_Commission]  DEFAULT ((0)) FOR [Commission]
GO

ALTER TABLE [dbo].[oSdorgCreditLog] ADD  CONSTRAINT [DF_oSdorgCreditLog_Rewards]  DEFAULT ((0)) FOR [Rewards]
GO

ALTER TABLE [dbo].[oSdorgCreditLog] ADD  CONSTRAINT [DF_oSdorgCreditLog_Balance]  DEFAULT ((0)) FOR [Balance]
GO

ALTER TABLE [dbo].[oSdorgCreditLog] ADD  CONSTRAINT [DF_oSdorgCreditLog_AvailabBalance]  DEFAULT ((0)) FOR [AvailabBalance]
GO

ALTER TABLE [dbo].[oSdorgCreditLog] ADD  CONSTRAINT [DF_oSdorgCreditLog_APPName]  DEFAULT (app_name()) FOR [APPName]
GO

ALTER TABLE [dbo].[oSdorgCreditLog] ADD  CONSTRAINT [DF_oSdorgCreditLog_sUserName]  DEFAULT (suser_name()) FOR [sUserName]
GO




*/