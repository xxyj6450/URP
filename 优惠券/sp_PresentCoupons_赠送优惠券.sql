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
		DECLARE @SourceMode VARCHAR(20),				--��Դģʽ
				@CodeMode VARCHAR(20),						--����ģʽ
				@CodeLength INT,										--���볤��
				@PresentCount VARCHAR(20),						--�����������ʽ
				@PresentMode VARCHAR(500),					--��������ģʽ
				@PresentMoney VARCHAR(500),					--���ͽ����ʽ
				@ExchangeCount VARCHAR(20),					--�һ��������ʽ
				@ExchangeMode VARCHAR(500),				--�һ�����ģʽ
				@ExchangeMoney VARCHAR(500),				--�һ������ʽ
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
					BeginDate DATETIME,								--�Ż�ȯ���ϱ��е���ʼ��Ч��
					EndDate DATETIME,									--�Ż�ȯ���ϱ��е���ֹ��Ч��
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
					--�һ���Ʒ����.ÿ����Ʒ��������������.
					--��Ϊ��Ʒ��������ʹ�ö���,�����Ż�ȯ
					--�������Ż�ȯ�һ�����,��Ʒ��ʵ������,�Դ�����Ϊ׼
					--���Ҫ����Դ������,ͬ������Ʒֻ����һ��
					--�����Ż�ȯ�һ����е���Ʒ�����������ԭ���ݶ�Ӧ
					--��ÿ�������Ż�ȯ�һ���ʱ,����ɾ��ԭ�һ����е���ϸ,�����²���.
					--������ȷ��Դ����ʱ,��Ҫ�˶����Ż�ȯ�һ����е���Ʒ�����Ƿ�һ��.
					digit INT,													
					deductAmount MONEY,
					PackageType varchar(50),
					beginValidDate DATETIME,							--�Ż�ȯ���е���ʼ��Ч��
					endValidDate DATETIME,							--�Ż�ȯ���е���ֹ��Ч��
					canOverlay BIT,											--�����Ż�ȯ�Ƿ��������
					CouponsOwner VARCHAR(50),					--�Ż�ȯ���������еĳ�����
					[OWNER] VARCHAR(50),								--ʵ���Ż�ȯ�ĳ�����
					AuthKey	 VARCHAR(50),								--�Ż�ȯ�һ������û������У������
					CouponsAuthKey	VARCHAR(50)					--�Ż�ȯ���е�У������
		)
		--�����������ݷ�����ʱ��
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
				--left JOIN iCoupons i  with(nolock) ON cd.CouponsBarCode=i.CouponsBarcode						--�Ż�ȯ��һ������,�˴�Ҫ��Left Join 
				--��һ���й�������,����Ҫ��Left Join
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
				--left JOIN iCoupons i  with(nolock) ON cd.CouponsBarCode=i.CouponsBarcode						--�Ż�ȯ��һ������,�˴�Ҫ��Left Join 
				--��һ���й�������,����Ҫ��Left Join
				LEFT JOIN Unicom_Orders  vso  with(nolock) ON ch.RefCode=vso.DocCode 
				--LEFT JOIN Unicom_OrderDetails  s  with(nolock) ON vso.DocCode=s.DocCode AND  cd.RefRowID=s.rowid
				LEFT JOIN iMatGeneral ig2  with(nolock) ON cd.MatCode=ig2.MatCode
				LEFT JOIN iMatGroup ig3  with(nolock) ON ig2.MatGroup=ig3.matgroup
				WHERE ch.Doccode=@doccode
			END
		--����ָ���Ĺ��ܺ�,����������Ϣ
		IF @refFormid IN(9102,9146,9237)
			BEGIN
				update a
					set a.PackageType=isnull(b.DocType,'')
				From #DocData a left join policy_h b WITH(NOLOCK) on a.packageid=b.doccode
			END
		--���Ż�ȯ������Ż�ȯ��Ϣ
		UPDATE a
			SET a.[STATE]=ic.[State],
			[OWNER] = ic.CouponsOWNER,
			CouponsAuthKey=ic.AuthKey
		FROM #DocData a,iCoupons ic WITH(NOLOCK)
		WHERE a.CouponsBarcode=ic.CouponsBarcode
		--У�����͹���
		BEGIN TRY
			exec sp_checkPresentCoupons @formid,@doccode,@refFormid,@optionID,@userCode
		END TRY
		BEGIN CATCH
			select @tips=dbo.getLastError('�Ż�ȯ���͹���У��ʧ�ܡ�')
			raiserror(@tips,16,1)
			return
		END CATCH
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
				drop TABLE #DocData
				select @tips='�޷����ʹ��Ż�ȯ,��Ϊ���Ż�ȯ�������򲻴���!'
				RAISERROR(@tips,16,1)
				return
			END
		return
	END