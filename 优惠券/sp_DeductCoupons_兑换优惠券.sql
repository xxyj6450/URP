create proc sp_DeductCoupons
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
		SELECT @refFormid=refformid,@refcode=refcode,@Stcode=ch.Stcode
				  FROM Coupons_H ch  with(nolock) WHERE ch.Doccode=@doccode
				IF @refformid IN(2419)
					begin
						INSERT 	INTO #DocData (  Doccode,   DocDate,   FormID,   Doctype,   
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
								 totalMoney,   digit,   deductAmount,CouponsOwner,AuthKey,canOverlay ,RowID,RefRowID,Seriescode )
								select ch.Doccode,ch.docdate,ch.FormID,vso.DocType,vso.FormID,vso.DocCode,vso.PackageID,NULL AS combocode,
								o2.SDOrgID,o2.dptType, o2.[PATH],g.areaid,g.[PATH],o.stCode,o.PlantID,ch.cltCode,
								cd.CouponsBarCode,NULL [State],ig.CouponsCode,cd.CouponsName, ig.GroupCode,ig.CodeMode,ig.CodeLength,
								ig.SourceMode,ig.PresentMode,ig.PresentCount,ig.PresentMoney,ig.ExchangeMode,ig.ExchangeCount,ig.ExchangeMoney,
								ig.ForceCheckStock,ig.BeginDate,ig.EndDate,ig.Valid,ig.price,
								cd.MatCode,cd.MatName,ig2.MatGroup,ig2.mattype,ig3.[PATH],s.price,s.totalmoney,s.Digit,cd.DeductAmout,
								ig.CouponsOwner,cd.authKey,ig.canOverlay ,cd.RowID,cd.RefRowID,cd.SeriesCode
								FROM Coupons_H ch   with(nolock) INNER JOIN oStorage o  with(nolock) ON ch.Stcode=o.stCode
								INNER JOIN oSDOrg o2  with(nolock) ON o.sdorgid=o2.SDOrgID
								INNER JOIN gArea g  with(nolock) ON o2.AreaID=g.areaid
								INNER JOIN Coupons_D cd  with(nolock) ON ch.Doccode=cd.Doccode
								inner JOIN iCouponsGeneral ig with(nolock)  ON cd.CouponsCode=ig.CouponsCode
								--left JOIN iCoupons i  with(nolock) ON cd.CouponsBarCode=i.CouponsBarcode						--优惠券不一定存在,此处要用Left Join 
								--不一定有关联单据,所以要用Left Join
								LEFT JOIN spickorderhd vso WITH(NOLOCK) ON ch.RefCode=vso.DocCode 
								LEFT JOIN sPickorderitem s WITH(NOLOCK) ON vso.DocCode=s.DocCode AND  cd.RefRowID=s.rowid
								LEFT JOIN iMatGeneral ig2  with(nolock) ON s.MatCode=ig2.MatCode
								LEFT JOIN iMatGroup ig3 with(nolock) ON ig2.MatGroup=ig3.matgroup
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
						     totalMoney,   digit,   deductAmount,CouponsOwner,AuthKey,canOverlay,RowID,RefRowID,Seriescode)
						select ch.Doccode,ch.docdate,ch.FormID,vso.DocType,vso.FormID,vso.DocCode,vso.PackageID,vso.ComboCode AS combocode,
						o2.SDOrgID,o2.dptType, o2.[PATH],g.areaid,g.[PATH],o.stCode,o.PlantID,ch.cltCode,
						cd.CouponsBarCode,NULL [State],ig.CouponsCode,cd.CouponsName,ig.GroupCode,ig.CodeMode,ig.CodeLength,
						ig.SourceMode,ig.PresentMode,ig.PresentCount,ig.PresentMoney,ig.ExchangeMode,ig.ExchangeCount,ig.ExchangeMoney,
						ig.ForceCheckStock,ig.BeginDate,ig.EndDate,ig.Valid,ig.price,
						cd.MatCode,cd.matname,ig2.MatGroup,ig2.mattype,ig3.[PATH],cd.Amount,cd.Amount,cd.DeductAmout,cd.DeductAmout,
						ig.CouponsOwner,cd.authKey,ig.canOverlay ,cd.RowID,cd.RefRowID,cd.Seriescode
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
				/*IF @refFormid IN(6090)
					BEGIN
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
						     totalMoney,   digit,amount,  deductAmount,CouponsOwner,AuthKey,canOverlay,RowID,RefRowID,Seriescode )
						select ch.Doccode,ch.docdate,ch.FormID,NULL DocType,@refFormid  ,@refcode  ,NULL PackageID,NULL AS combocode,
						o2.SDOrgID,o2.dptType, o2.[PATH],g.areaid,g.[PATH],o.stCode,o.PlantID,ch.cltCode,
						cd.CouponsBarCode,NULL [State],ig.CouponsCode,cd.CouponsName,ig.GroupCode,ig.CodeMode,ig.CodeLength,
						ig.SourceMode,ig.PresentMode,ig.PresentCount,ig.PresentMoney,ig.ExchangeMode,ig.ExchangeCount,ig.ExchangeMoney,
						ig.ForceCheckStock,ig.BeginDate,ig.EndDate,ig.Valid,ig.price,	cd.MatCode,cd.MatName,ig2.MatGroup,ig2.mattype,ig3.[PATH],
						cd.Price,ch.,cd.Digit,cd.DeductAmout,ig.CouponsOWNER,cd.authKey,ig.canOverlay ,cd.RowID,cd.RefRowID,cd.SeriesCode
						FROM Coupons_H ch  with(nolock) 
						INNER JOIN oStorage o  with(nolock) ON ch.Stcode=o.stCode
						INNER JOIN oSDOrg o2  with(nolock) ON o.sdorgid=o2.SDOrgID
						INNER JOIN gArea g  with(nolock) ON o2.AreaID=g.areaid
						INNER JOIN Coupons_D cd  with(nolock) ON ch.Doccode=cd.Doccode
						INNER JOIN iCouponsGeneral ig  with(nolock) ON cd.CouponsCode=ig.CouponsCode
						--left JOIN iCoupons i  with(nolock) ON cd.CouponsBarCode=i.CouponsBarcode						--优惠券不一定存在,此处要用Left Join 
						--不一定有关联单据,所以要用Left Join
						--LEFT JOIN ord_shopbestgoodsdoc  vso  with(nolock) ON ch.RefCode=vso.DocCode 
						--LEFT JOIN ord_shopbestgoodsdtl    s  with(nolock) ON vso.DocCode=s.DocCode AND  cd.matcode=s.matcode
						LEFT JOIN iMatGeneral ig2  with(nolock) ON cd.MatCode=ig2.MatCode
						LEFT JOIN iMatGroup ig3  with(nolock) ON ig2.MatGroup=ig3.matgroup
						WHERE ch.Doccode=@doccode
						--从源单据更新信息
						update a
							set a.digit=b.ask_digit,
							a.Price=b.salesprice,
							a.amount=b.totalmoney,
							a.RefRowID=b.rowid
						--下面用LEFT JOIN的一个好处时,当源单据商品已经不存在时,也能将数量和金额改成NULL.
						from #DocData a Left join ord_shopbestgoodsdtl b with(nolock) on b.doccode=@refcode  and a.refrowid=b.rowid
						where a.ExchangeMode='按商品'
						update a
							set  a.totalMoney=b.SumNetMoney,
						from #DocData a Left join ord_shopbestgoodsdoc b with(nolock) on b.doccode=@refcode
					END*/
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
				--校验兑换规则
				BEGIN TRY
					exec sp_checkDeductCoupons @formid,@doccode,@optionID,@userCode
				END TRY
				BEGIN CATCH
					select @tips=dbo.getLastError('优惠券兑换规则校验失败。')
					raiserror(@tips,16,1)
					return
				END CATCH
				/************************************************************************更新优惠券状态******************************************************/
				--如果@optionID不为0,则不作更新
				IF ISNULL(@optionID,'0')  IN('check') RETURN
				--若本机为URP主服务器,则更新自己,否则更新URP主服务器
				
				UPDATE iCoupons
				SET
					[State] =ISNULL(NULLIF(@CouponsStatus,''), '已兑换'),						--更新优惠券状态,若传入的状态不为空,则使用传入的状态,否则使用默认的状态.
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
						set a.DeductAmout=b.DeductAmout,
						done=0
						from spickorderitem a WITH(NOLOCK),coupons_d b
						where a.doccode=@refcode
							and b.doccode=@doccode
							and a.matcode=b.matcode
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
						set a.DeductAmout=b.DeductAmout
						from unicom_orderdetails a   with(nolock),coupons_d b   with(nolock)
						where a.doccode=@refcode
							and b.doccode=@doccode
							and a.matcode=b.matcode
					END
				return
	END