alter proc sp_DeductCoupons
	@FormID int,
	@Doccode varchar(50),
	@Refformid int=0,
	@Refcode varchar(50)='',
	@Stcode varchar(50)='',
	@Customercode varchar(50)='',
	@OptionID varchar(50)='',						--若传入#Skipcheck#则不检查
	@Usercode varchar(50)='',
	@TerminalID varchar(50)=''
as
	BEGIN
		set NOCOUNT ON
		DECLARE @deductAmout money,@LinkDocInfo varchar(50),@linkDoc varchar(20),  @tips varchar(5000),	@msg VARCHAR(5000)
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
						--校验兑换规则
						BEGIN TRY
							exec sp_checkDeductCoupons @formid,@doccode,@Refformid,@Refcode,@Stcode,@Customercode,@PackageId,@ComboCode,@optionID,@userCode
						END TRY
						BEGIN CATCH
							select @tips=dbo.getLastError('优惠券兑换规则校验失败。')
							raiserror(@tips,16,1)
							return
						END CATCH
					END
				
				/************************************************************************更新优惠券状态******************************************************/
				--若本机为URP主服务器,则更新自己,否则更新URP主服务器
				
				UPDATE iCoupons
				SET
					[State] = '已兑换',						--更新优惠券状态,若传入的状态不为空,则使用传入的状态,否则使用默认的状态.
					DeductAmout =b.DeductAmout ,
					Remark = b.Remark ,
					DeducedDoccode = a.Doccode ,
					DeducedDate = GETDATE(),
					DeducedFormID = a.FormID ,
					DeducedStcode = a.Stcode ,
					DeducedStName = a.stName ,
					DeducedMatcode = b.Matcode ,
					DeducedMatName = b.MatName ,
					DeducedSeriescode = b.SeriesCode,
					DeducedMoney = b.Amount ,
					DeducedDigit =b.Digit
				FROM Coupons_H a  with(nolock),Coupons_D b  with(nolock),iCoupons c  with(nolock)
				WHERE a.Doccode=b.Doccode
				AND b.CouponsBarCode=c.CouponsBarcode
				AND a.Doccode= @doccode
				AND c.[State] IN('已赠','使用中')
				IF @@ROWCOUNT=0
					BEGIN
						select @tips='无法兑换此优惠券,因为此优惠券尚未赠送或不存在'
						RAISERROR(@tips,16,1)
						return
					END
				;WITH ctea AS(SELECT SUM(isnull(deductamout,0)) AS totalmoney FROM Coupons_D cd WHERE cd.Doccode=@doccode)
				UPDATE coupons_h 
					SET TotalDeductAmout = a.totalmoney 
				FROM ctea a 
				WHERE coupons_h.Doccode=@doccode
				SELECT @refFormid=refformid,@refcode=refcode,@deductAmout=ch.TotalDeductAmout
				  FROM Coupons_H ch   with(nolock) WHERE ch.Doccode=@doccode
				  /**********************************************************回填业务单据********************************************************************/
				--优惠金额回填业务单据
				IF @refFormid IN(2419)
					BEGIN
						UPDATE sPickorderHD
						SET DeductAmout = @deductAmout
						WHERE DocCode=@refcode
						AND FormID=@refFormid              

						UPDATE spickorderitem SET done=1 WHERE doccode=@doccode
						--修改明细表
						update a
						set a.DeductAmout=b.DeductAmout,a.CouponsBarCode=b.CouponsBarCode,
						done=0
						from spickorderitem a WITH(NOLOCK) LEFT JOIN coupons_d b
						on a.doccode=@refcode
							and b.doccode=@doccode
							and a.matcode=b.matcode
							and a.rowid=b.RefRowID
					END
				IF @refFormid IN(9102,9146)
					BEGIN
						UPDATE Unicom_Orders
						SET DeductAmout = @deductAmout
						WHERE DocCode=@doccode
						AND FormID=@formid
						AND FormID=@refFormid
						--修改明细表
						update a
						set a.DeductAmout=b.DeductAmout,a.CouponsBarCode=b.CouponsBarCode
						from unicom_orderdetails a   with(nolock) LEFT join coupons_d b   with(nolock)			--用LEFT JOIN性能降低，但可清除优惠券兑换单中没有，但在单据中还有的优惠券,保持数据一致。
						on a.doccode=@refcode
							and b.doccode=@doccode
							and a.matcode=b.matcode
							and a.rowid=b.RefRowID
					END
				return
	END