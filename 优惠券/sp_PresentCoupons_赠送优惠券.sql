alter proc sp_PresentCoupons
	@FormID int,
	@Doccode varchar(50),
	@Refformid int=0,
	@Refcode varchar(50)='',
	@Stcode varchar(50)='',
	@Customercode varchar(50)='',
	@OptionID varchar(50)='',				--������#SkipCheck#�򲻼��
	@Usercode varchar(50)='',
	@TerminalID varchar(50)=''
as
	BEGIN
		set NOCOUNT ON
		DECLARE  @deductAmout money,@LinkDocInfo varchar(50),@linkDoc varchar(20),  @tips varchar(5000),	@msg VARCHAR(5000)
		DECLARE @TranCount INT,@DocStatus INT,@PackageId varchar(50),@ComboCode int
		DECLARE @SourceMode VARCHAR(20),				--��Դģʽ
				@CodeMode VARCHAR(20),						--����ģʽ
				@CodeLength INT,										--���볤��
				@PresentCount VARCHAR(20),						--�����������ʽ
				@PresentMode VARCHAR(500),					--��������ģʽ
				@PresentMoney VARCHAR(500),					--���ͽ����ʽ
				@ExchangeCount VARCHAR(20),					--�һ��������ʽ
				@ExchangeMode VARCHAR(500),				--�һ�����ģʽ
				@ExchangeMoney VARCHAR(500),				--�һ������ʽ
				@SdorgID VARCHAR(50),
				@sql VARCHAR(8000)
		if @Refformid in(9146,9237,9102)
		BEGIN
			select @PackageId=uo.PackageID,@ComboCode=uo.ComboCode
			from Unicom_Orders uo with(nolock)
			where uo.DocCode=@Refcode
		END
		if @OptionID<>'#SkipCheck#'
			BEGIN
				--У�����͹���
				BEGIN TRY
					exec sp_checkPresentCoupons   @formid,@doccode,@refFormid,@Refcode,@Stcode,@Customercode ,@PackageId ,@ComboCode ,@optionID,@userCode
				END TRY
				BEGIN CATCH
					select @tips=dbo.getLastError('�Ż�ȯ���͹���У��ʧ�ܡ�')
					raiserror(@tips,16,1)
					return
				END CATCH
			END
		
		--�޸��Ż�ȯ״̬
		UPDATE iCoupons
		SET	[State] = '����',
			OutDate = GETDATE(),
			OutDoccode = a.doccode,
			OutStcode = a.stcode,
			OutStName = a.stname,
			OutFormID = a.formid,
			PresentedMatcode = b.matcode,
			PresentedMatName = b.matname,
			PresentedSeriesCode = b.seriescode,
			PresentedMoney = b.Amount,
			presenteddigit=b.Digit,
			remark=b.Remark,
			iCoupons.PresentDoccode = @doccode,
			iCoupons.PresentFormid = @formid,
			iCoupons.PresentStcode = a.Stcode,
			iCoupons.PresentDate = GETDATE(),
			iCoupons.CouponsOWNER=CASE WHEN c.CouponsOWNER='�ֿ�' THEN a.stcode
																WHEN c.CouponsName='�ͻ�' THEN a.cltcode
																WHEN c.CouponsOWNER='ע���û�' then a.sdgroup
																ELSE a.Stcode
													end
		FROM Coupons_H a  with(nolock),Coupons_D b  with(nolock),iCoupons ic  with(nolock), iCouponsGeneral c WITH(NOLOCK)
		WHERE a.Doccode=b.Doccode
		AND b.CouponsBarCode=ic.CouponsBarcode
		AND a.Doccode=@doccode
		AND ic.[State]='�ڿ�'
		AND ic.CouponsCode=c.couponscode
		IF @@ROWCOUNT=0
			BEGIN
				select @tips='�޷����ʹ��Ż�ȯ,��Ϊ���Ż�ȯ�������򲻴���!'
				RAISERROR(@tips,16,1)
				return
			END
		return
	END