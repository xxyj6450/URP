create proc sp_PresentCoupons
	@FormID int,
	@Doccode varchar(50),
	@OptionID varchar(50)='',
	@Usercode varchar(50)='',
	@TerminalID varchar(50)=''
as
	BEGIN
		set NOCOUNT ON
		DECLARE @refFormid INT,@refcode VARCHAR(20),@deductAmout money,@LinkDocInfo varchar(50),@linkDoc varchar(20),  @tips varchar(5000),	@msg VARCHAR(5000)
		DECLARE @TranCount INT,@DocStatus INT
		DECLARE @SourceMode VARCHAR(20),				--来源模式
				@CodeMode VARCHAR(20),						--编码模式
				@CodeLength INT,										--编码长度
				@PresentCount VARCHAR(20),						--赠送数量表达式
				@PresentMode VARCHAR(500),					--赠送数量模式
				@PresentMoney VARCHAR(500),					--赠送金额表达式
				@ExchangeCount VARCHAR(20),					--兑换数量表达式
				@ExchangeMode VARCHAR(500),				--兑换数量模式
				@ExchangeMoney VARCHAR(500),				--兑换金额表达式
				@Stcode VARCHAR(50),
				@SdorgID VARCHAR(50),
				@sql VARCHAR(8000)
 
		CREATE TABLE #DocData(
					Doccode VARCHAR(20),
					DocDate DATETIME,
					FormID INT,
					Doctype VARCHAR(50),
					RefFormID INT,
					Refcode VARCHAR(20),
					packageID VARCHAR(20),
					ComboCode VARCHAR(50),
					SdorgID VARCHAR(50),
					dptType VARCHAR(50),
					SdorgPath VARCHAR(500),
					AreaID VARCHAR(50),
					AreaPath VARCHAR(500),
					stcode VARCHAR(50),
					companyID VARCHAR(50),
					cltCode VARCHAR(50),
					CouponsBarcode VARCHAR(50),
					[STATE]  VARCHAR(20),
					CouponsCode VARCHAR(50),
					CouponsName VARCHAR(200),
					CouponsgroupCode VARCHAR(50),
					CodeMode VARCHAR(50),
					CodeLength INT,
					SourceMode VARCHAR(20),
					PresentMode VARCHAR(50),
					PresentCount VARCHAR(500),
					PresentMoney VARCHAR(500),
					ExchangeMode VARCHAR(50),
					ExchangeCount VARCHAR(500),
					ExchangeMoney VARCHAR(500),
					ForceCheckStock BIT,
					BeginDate DATETIME,								--优惠券资料表中的起始有效期
					EndDate DATETIME,									--优惠券资料表中的终止有效期
					Valid BIT,
					Price VARCHAR(500),
					RowID varchar(50),
					Seriescode varchar(50),
					RefRowID varchar(50),
					Matcode VARCHAR(50),
					MatName varchar(200),
					Matgroup VARCHAR(50),
					MatType VARCHAR(50),
					MatgroupPath VARCHAR(500),
					salePrice MONEY,
					totalMoney MONEY,
					--兑换商品数量.每个商品编码有若干数量.
					--因为商品允许设置使用多张,多种优惠券
					--所以在优惠券兑换单中,商品的实物总数,以此数量为准
					--这就要求在源单据中,同样的商品只能有一行
					--并且优惠券兑换单中的商品及数量必须和原单据对应
					--在每次生成优惠券兑换单时,都先删除原兑换单中的明细,再重新插入.
					--并且在确认源单据时,需要核对与优惠券兑换单中的商品数量是否一致.
					digit INT,													
					deductAmount MONEY,
					PackageType varchar(50),
					beginValidDate DATETIME,							--优惠券表中的起始有效期
					endValidDate DATETIME,							--优惠券表中的终止有效期
					canOverlay BIT,											--多种优惠券是否允许叠加
					CouponsOwner VARCHAR(50),					--优惠券资料设置中的持有者
					[OWNER] VARCHAR(50),								--实际优惠券的持有者
					AuthKey	 VARCHAR(50),								--优惠券兑换单中用户输入的校验密码
					CouponsAuthKey	VARCHAR(50)					--优惠券表中的校验密码
		)
		--将待处理数据放至临时表
		IF @refFormid IN(2419)
			begin

				INSERT INTO #DocData
					(  Doccode,   DocDate,   FormID,   Doctype,   
						RefFormID,   Refcode,   packageID,   ComboCode,   
						SdorgID,   dptType,   SdorgPath,   
						AreaID,   AreaPath,   stcode,   companyID,   
						cltCode,   CouponsBarcode,   STATE,   CouponsCode,   
						CouponsName,   CouponsgroupCode,   CodeMode,   
						CodeLength,   SourceMode,   PresentMode,   
						PresentCount,   PresentMoney,   ExchangeMode,   
						ExchangeCount,   ExchangeMoney,   ForceCheckStock,   
						BeginDate,   EndDate,   Valid,   Price,   Matcode, matname,  
						Matgroup,   MatType,   MatgroupPath,   salePrice,   
						totalMoney,   digit,   deductAmount,CouponsOwner,canOverlay,RowID,RefRowID,Seriescode )

				select ch.Doccode,ch.docdate,ch.FormID,vso.DocType,vso.FormID,vso.DocCode,vso.PackageID,NULL AS combocode,
				o2.SDOrgID,o2.dptType, o2.[PATH],g.areaid,g.[PATH],o.stCode,o.PlantID,ch.cltCode,
				cd.CouponsBarCode,NULL [State],ig.CouponsCode,cd.CouponsName, ig.GroupCode,ig.CodeMode,ig.CodeLength,
				ig.SourceMode,ig.PresentMode,ig.PresentCount,ig.PresentMoney,ig.ExchangeMode,ig.ExchangeCount,ig.ExchangeMoney,
				ig.ForceCheckStock,ig.BeginDate,ig.EndDate,ig.Valid,ig.price,	cd.MatCode,cd.MatName,ig2.MatGroup,ig2.mattype,ig3.[PATH],
				s.price,s.totalmoney,s.Digit,cd.DeductAmout,ig.CouponsOwner,ig.canOverlay,cd.RowID,cd.RefRowID,cd.SeriesCode 
				FROM Coupons_H ch  with(nolock) INNER JOIN oStorage o  with(nolock) ON ch.Stcode=o.stCode
				INNER JOIN oSDOrg o2  with(nolock) ON o.sdorgid=o2.SDOrgID
				INNER JOIN gArea g  with(nolock) ON o2.AreaID=g.areaid
				INNER JOIN Coupons_D cd  with(nolock) ON ch.Doccode=cd.Doccode
				inner JOIN iCouponsGeneral ig  with(nolock) ON cd.CouponsCode=ig.CouponsCode
				--left JOIN iCoupons i  with(nolock) ON cd.CouponsBarCode=i.CouponsBarcode						--优惠券不一定存在,此处要用Left Join 
				--不一定有关联单据,所以要用Left Join
				LEFT JOIN spickorderhd vso WITH(NOLOCK) ON ch.RefCode=vso.DocCode 
				LEFT JOIN sPickorderitem s with(nolock) ON vso.DocCode=s.DocCode AND  cd.RefRowID=s.rowid
				LEFT JOIN iMatGeneral ig2  with(nolock) ON s.MatCode=ig2.MatCode
				LEFT JOIN iMatGroup ig3  with(nolock) ON ig2.MatGroup=ig3.matgroup
				WHERE ch.Doccode=@doccode
			end
 		IF @refFormid IN(9102,9146)
			begin
				INSERT INTO #DocData
					(  Doccode,   DocDate,   FormID,   Doctype,   
						RefFormID,   Refcode,   packageID,   ComboCode,   
						SdorgID,   dptType,   SdorgPath,   
						AreaID,   AreaPath,   stcode,   companyID,   
						cltCode,   CouponsBarcode,   STATE,   CouponsCode,   
						CouponsName,   CouponsgroupCode,   CodeMode,   
						CodeLength,   SourceMode,   PresentMode,   
						PresentCount,   PresentMoney,   ExchangeMode,   
						ExchangeCount,   ExchangeMoney,   ForceCheckStock,   
						BeginDate,   EndDate,   Valid,   Price,   Matcode, matname,
						Matgroup,   MatType,   MatgroupPath,   salePrice,   
						totalMoney,   digit,   deductAmount ,RowID,RefRowID,Seriescode)
				select ch.Doccode,ch.docdate,ch.FormID,vso.DocType,vso.FormID,vso.DocCode,vso.PackageID,vso.ComboCode AS combocode,
				o2.SDOrgID,o2.dptType, o2.[PATH],g.areaid,g.[PATH],o.stCode,o.PlantID,ch.cltCode,
				cd.CouponsBarCode,NULL [State],ig.CouponsCode,cd.CouponsName,ig.GroupCode,ig.CodeMode,ig.CodeLength,
				ig.SourceMode,ig.PresentMode,ig.PresentCount,ig.PresentMoney,ig.ExchangeMode,ig.ExchangeCount,ig.ExchangeMoney,
				ig.ForceCheckStock,ig.BeginDate,ig.EndDate,ig.Valid,ig.price,cd.MatCode,cd.matname,ig2.MatGroup,ig2.mattype,ig3.[PATH],
				cd.Amount,cd.Amount,cd.DeductAmout,cd.DeductAmout,cd.RowID,cd.RefRowID,cd.SeriesCode 
				FROM Coupons_H ch  with(nolock) INNER JOIN oStorage o  with(nolock) ON ch.Stcode=o.stCode
				INNER JOIN oSDOrg o2  with(nolock) ON o.sdorgid=o2.SDOrgID
				INNER JOIN gArea g  with(nolock) ON o2.AreaID=g.areaid
				INNER JOIN Coupons_D cd  with(nolock) ON ch.Doccode=cd.Doccode
				INNER JOIN iCouponsGeneral ig  with(nolock) ON cd.CouponsCode=ig.CouponsCode
				--left JOIN iCoupons i  with(nolock) ON cd.CouponsBarCode=i.CouponsBarcode						--优惠券不一定存在,此处要用Left Join 
				--不一定有关联单据,所以要用Left Join
				LEFT JOIN Unicom_Orders  vso  with(nolock) ON ch.RefCode=vso.DocCode 
				--LEFT JOIN Unicom_OrderDetails  s  with(nolock) ON vso.DocCode=s.DocCode AND  cd.RefRowID=s.rowid
				LEFT JOIN iMatGeneral ig2  with(nolock) ON cd.MatCode=ig2.MatCode
				LEFT JOIN iMatGroup ig3  with(nolock) ON ig2.MatGroup=ig3.matgroup
				WHERE ch.Doccode=@doccode
			END
		--对于指定的功能号,更新政策信息
		IF @refFormid IN(9102,9146,9237)
			BEGIN
				update a
					set a.PackageType=isnull(b.DocType,'')
				From #DocData a left join policy_h b WITH(NOLOCK) on a.packageid=b.doccode
			END
		--从优惠券表更新优惠券信息
		UPDATE a
			SET a.[STATE]=ic.[State],
			[OWNER] = ic.CouponsOWNER,
			CouponsAuthKey=ic.AuthKey
		FROM #DocData a,iCoupons ic WITH(NOLOCK)
		WHERE a.CouponsBarcode=ic.CouponsBarcode
		--校验赠送规则
		BEGIN TRY
			exec sp_checkPresentCoupons @formid,@doccode,@refFormid,@optionID,@userCode
		END TRY
		BEGIN CATCH
			select @tips=dbo.getLastError('优惠券赠送规则校验失败。')
			raiserror(@tips,16,1)
			return
		END CATCH
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
				drop TABLE #DocData
				select @tips='无法赠送此优惠券,因为此优惠券已赠出或不存在!'
				RAISERROR(@tips,16,1)
				return
			END
		return
	END