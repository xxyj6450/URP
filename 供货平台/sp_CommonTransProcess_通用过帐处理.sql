/*
��������:sp_CommonTransProcess
��������:Ϊͨ�õ��ݱ� CommonDoc_HD�ṩͨ�ù���
����:������
����ֵ:
��д:���ϵ�
ʱ��:2012-12-24
��ע:
*/
create proc sp_CommonTransProcess
	@FormID int,
	@Doccode varchar(50),
	@RefFormID int=0,
	@RefCode varchar(50)='',
	@SDorgID varchar(50)='',
	@stcode varchar(50)='',
	@OptionID varchar(200)='',
	@Usercode varchar(50)='',
	@TerminalID varchar(50)='',
	@InstanceID varchar(50)=''
as
	BEGIN
		set NOCOUNT ON
		declare @RowID varchar(50),@areaID varchar(50),@VndCode varchar(50)
		declare @table table(matcode varchar(50))
		--��Ӧ�̱��۵�
		if @FormID in(2226)
			BEGIN
				select @areaID=cdh.areaid,@VndCode=cdh.Vndcode
				from CommonDoc_HD cdh with(nolock)
				where cdh.Doccode=@Doccode
				--�ȸ������е�����
				update a
				set a.price=isnull(b.curSalePrice,0),
				a.stock=isnull(b.Expression,0),
				a.areaid=@areaID,
				a.modifydate=getdate(),
				a.modifyname=@Usercode,
				a.modifydoccode=@Doccode
				output deleted.matcode into @table
				from AdjustPrice_DT b with(nolock),sMatStorage_VND a with(nolock)
				where a.Matcode=b.MatCode
				and a.vndCode=@VndCode
				and b.Doccode=@Doccode
				--�ٲ���δ�е�����
				insert into sMatStorage_VND(Matcode,vndCode,AreaID,Stock,price,EnterName,EnterDate,EnterDoccode)
				select a.MatCode,@VndCode,@areaID,a.Expression,a.curSalePrice,@Usercode,getdate(),@Doccode
				from AdjustPrice_DT a with(nolock)
				where a.Doccode=@Doccode
				and not exists(select 1 from @table x where a.MatCode=x.matcode)
			END
		return
	END
 