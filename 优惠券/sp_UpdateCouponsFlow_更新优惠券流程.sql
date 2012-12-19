/*
��������:sp_FinishCouponsFlow
����:������
����ֵ:
��������:�����Ż�ȯ����,��δʹ�õ��Ż�ȯ�˻ظ��û�����ʹ��.
��ע:������ֻ��URP��������.Ŀ�������������������������,ֻ��Ҫ���ù���,����Ҫ����ȡ���ݵ�����.����������ʹ�����ӷ�������ʽ���ʸù���.
��д:���ϵ�
ʱ��:2012-12-19
ʾ��:
*/
create proc sp_UpdateCouponsFlow
	@FormID int,
	@Doccode varchar(50),
	@FlowInstanceID varchar(50),					--���̱���
	@FlowStatus varchar(50)='δ���',
	@Couponsbarcode varchar(2000),
	@OptionId varchar(50)='',
	@Usercode varchar(50)='',
	@TerminalID varchar(50)=''
as
	BEGIN
		set NOCOUNT on;
		declare @sql varchar(max)
		--�����������,��δʹ�õ��Ż�ȯ���˻ظ��û�ʹ��.
		if @FlowStatus='�����'
			BEGIN
				if exists(select 1 from oSDOrgCouponsFlow a with(nolock) where a.FlowInstanceID=@FlowInstanceID and a.FlowStatus='δ����') 
					begin
						--�Ȼ�ԭ�Ż�ȯ״̬
							update a
								set a.State='����',
								a.Remark='�Ż�ȯδʹ��,�Զ���ԭΪ����״̬.'
							from iCoupons a with(nolock),oSDOrgCouponsFlow b with(nolock)
							where a.CouponsBarcode=b.Couponsbarcode
							and b.FlowStatus='δ����'
							and a.State='ʹ����'
							and b.FlowInstanceId=@FlowInstanceID
							--���޸����̱�־
							update a
								set a.FlowStatus='�Ѵ���',remark='�Ż�ȯδʹ��,�Զ���ԭΪ����״̬.'
							from oSDOrgCouponsFlow  a with(nolock)
							where a.FlowInstanceID=@FlowStatus
					end
			END
		--������δ����,��ʽ�һ��Ż�ȯʱ,���Ż�ȯ��־��ʹ��
		if @FlowStatus='δ���' and @couponsbarcode<>''
			BEGIN
				update a
								set a.State='�Ѷһ�',
								a.Remark='�Ż�ȯ�һ����'
							from iCoupons a with(nolock),oSDOrgCouponsFlow b with(nolock)
							where a.CouponsBarcode=b.Couponsbarcode
							and b.FlowStatus='δ����'
							and a.State='ʹ����'
							and b.FlowInstanceId=@FlowInstanceID
							--���޸����̱�־
							update a
								set a.FlowStatus='�Ѵ���',remark='�Ż�ȯδʹ��,�Զ���ԭΪ����״̬.'
							from oSDOrgCouponsFlow  a with(nolock)
							where a.FlowInstanceID=@FlowStatus
			END
 
	END