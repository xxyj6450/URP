alter proc sp_PresentCoupons
	@FormID int,
	@Doccode varchar(50),
	@Refformid int=0,
	@Refcode varchar(50)='',
	@Stcode varchar(50)='',
	@Customercode varchar(50)='',
	@OptionID varchar(50)='',				--若传入#SkipCheck#则不检查
	@Usercode varchar(50)='',
	@TerminalID varchar(50)=''
as
	BEGIN
		set NOCOUNT ON
		DECLARE  @deductAmout money,@LinkDocInfo varchar(50),@linkDoc varchar(20),  @tips varchar(5000),	@msg VARCHAR(5000)
		DECLARE @TranCount INT,@DocStatus INT,@PackageId varchar(50),@ComboCode int
		DECLARE @SourceMode VARCHAR(20),				--来源模式
				@CodeMode VARCHAR(20),						--编码模式
				@CodeLength INT,										--编码长度
				@PresentCount VARCHAR(20),						--赠送数量表达式
				@PresentMode VARCHAR(500),					--赠送数量模式
				@PresentMoney VARCHAR(500),					--赠送金额表达式
				@ExchangeCount VARCHAR(20),					--兑换数量表达式
				@ExchangeMode VARCHAR(500),				--兑换数量模式
				@ExchangeMoney VARCHAR(500),				--兑换金额表达式
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
				--校验赠送规则
				BEGIN TRY
					exec sp_checkPresentCoupons   @formid,@doccode,@refFormid,@Refcode,@Stcode,@Customercode ,@PackageId ,@ComboCode ,@optionID,@userCode
				END TRY
				BEGIN CATCH
					select @tips=dbo.getLastError('优惠券赠送规则校验失败。')
					raiserror(@tips,16,1)
					return
				END CATCH
			END
		
		--修改优惠券状态
		UPDATE iCoupons
		SET	[State] = '已赠',
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
			iCoupons.CouponsOWNER=CASE WHEN c.CouponsOWNER='仓库' THEN a.stcode
																WHEN c.CouponsName='客户' THEN a.cltcode
																WHEN c.CouponsOWNER='注册用户' then a.sdgroup
																ELSE a.Stcode
													end
		FROM Coupons_H a  with(nolock),Coupons_D b  with(nolock),iCoupons ic  with(nolock), iCouponsGeneral c WITH(NOLOCK)
		WHERE a.Doccode=b.Doccode
		AND b.CouponsBarCode=ic.CouponsBarcode
		AND a.Doccode=@doccode
		AND ic.[State]='在库'
		AND ic.CouponsCode=c.couponscode
		IF @@ROWCOUNT=0
			BEGIN
				select @tips='无法赠送此优惠券,因为此优惠券已赠出或不存在!'
				RAISERROR(@tips,16,1)
				return
			END
		return
	END