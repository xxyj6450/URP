/*
�������ƣ�sp_CheckPresentCoupons
����������У���Ż�ȯ���͹���
������������;�����̵Ĳ����⣬����Ҫ����һ��#DocData����ʱ���ڴ���ʱ���д洢ҵ�����ݺ��Ż�ȯ���ݣ������̽����ݴ�����Դ����У�顣
����ֵ��
��д�����ϵ�
��ע��
#DocData�ɰ�����ҵ�������ֵ��һ�����������£�
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
ʾ����
*/
alter proc sp_CheckPresentCoupons
	@FormID int,
	@Doccode varchar(50),
	@RefFormID int=0,
	@OptionID varchar(200)='',
	@Usercode varchar(50)=''
as
	BEGIN
		set NOCOUNT on;
		declare @tips varchar(max)
		--ҵ������У��
		if object_id('tempdb.dbo.#Docdata') is NULL
			BEGIN
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
				IF @Formid IN(2419)
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
								totalMoney,   digit,   deductAmount,CouponsOwner,canOverlay,RowID,RefRowID,Seriescode,beginValidDate,endValidDate )

						select ch.Doccode,ch.docdate,ch.FormID,ch.DocType,NULL,NULL,ch.PackageID,NULL AS combocode,
						o2.SDOrgID,o2.dptType, o2.[PATH],g.areaid,g.[PATH],o.stCode,o.PlantID,ch.cltCode,
						s.CouponsBarCode,NULL [State],ig.CouponsCode,ig.CouponsName, ig.GroupCode,ig.CodeMode,ig.CodeLength,
						ig.SourceMode,ig.PresentMode,ig.PresentCount,ig.PresentMoney,ig.ExchangeMode,ig.ExchangeCount,ig.ExchangeMoney,
						ig.ForceCheckStock,ig.BeginDate,ig.EndDate,ig.Valid,ig.price,	s.MatCode,s.MatName,ig2.MatGroup,ig2.mattype,ig3.[PATH],
						s.price,s.totalmoney,s.Digit,s.DeductAmout,ig.CouponsOwner,ig.canOverlay,s.RowID,newid() RefRowID,s.SeriesCode,i.beginValidDate,i.ValidDate 
						FROM spickorderhd ch  with(nolock) INNER JOIN oStorage o  with(nolock) ON ch.Stcode=o.stCode
						INNER JOIN oSDOrg o2  with(nolock) ON o.sdorgid=o2.SDOrgID
						INNER JOIN gArea g  with(nolock) ON o2.AreaID=g.areaid
						inner JOIN sPickorderitem s with(nolock) ON ch.DocCode=s.DocCode 
						inner JOIN iCoupons i  with(nolock) ON s.CouponsBarCode=i.CouponsBarcode						--�Ż�ȯ��һ������,�˴�Ҫ��Left Join 
						inner JOIN iCouponsGeneral ig  with(nolock) ON i.CouponsCode=ig.CouponsCode
						inner JOIN iMatGeneral ig2  with(nolock) ON s.MatCode=ig2.MatCode
						inner JOIN iMatGroup ig3  with(nolock) ON ig2.MatGroup=ig3.matgroup
						WHERE ch.Doccode=@doccode
					end
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
				if @FormID in(9146,9102)
					BEGIN
						--������׼������ʱ��
						if object_id('tempdb.dbo.#Unicom_OrderDetails') is null select * Into #Unicom_OrderDetails From Unicom_OrderDetails with(nolock) where DocCode=@Doccode
						;with   cte_unicom_orderdetails(doccode,seriescode,matcode,MatName,rowid,digit,price,totalmoney,couponsbarcode,DeductAmout) as(
							select doccode,seriescode,matcode,matname,rowid,digit,price,totalmoney,couponsbarcode,uod.DeductAmout
							from #Unicom_OrderDetails uod with(nolock)
							where uod.DocCode=@Doccode
						)
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
								totalMoney,   digit,   deductAmount,CouponsOwner,canOverlay,RowID,RefRowID,Seriescode,beginValidDate,endValidDate )

						select ch.Doccode,ch.docdate,ch.FormID,ch.DocType,NULL,NULL,ch.PackageID,NULL AS combocode,
						o2.SDOrgID,o2.dptType, o2.[PATH],g.areaid,g.[PATH],o.stCode,o.PlantID,ch.cltCode,
						s.CouponsBarCode,NULL [State],ig.CouponsCode,ig.CouponsName, ig.GroupCode,ig.CodeMode,ig.CodeLength,
						ig.SourceMode,ig.PresentMode,ig.PresentCount,ig.PresentMoney,ig.ExchangeMode,ig.ExchangeCount,ig.ExchangeMoney,
						ig.ForceCheckStock,ig.BeginDate,ig.EndDate,ig.Valid,ig.price,	s.MatCode,s.MatName,ig2.MatGroup,ig2.mattype,ig3.[PATH],
						s.price,s.totalmoney,s.Digit,s.DeductAmout,ig.CouponsOwner,ig.canOverlay,s.RowID,newid() RefRowID,s.SeriesCode,i.beginValidDate,i.ValidDate 
						FROM Unicom_Orders  ch  with(nolock) INNER JOIN oStorage o  with(nolock) ON ch.Stcode=o.stCode
						INNER JOIN oSDOrg o2  with(nolock) ON o.sdorgid=o2.SDOrgID
						INNER JOIN gArea g  with(nolock) ON o2.AreaID=g.areaid
						inner JOIN cte_unicom_orderdetails s with(nolock) ON ch.DocCode=s.DocCode 
						inner JOIN iCoupons i  with(nolock) ON s.CouponsBarCode=i.CouponsBarcode						--�Ż�ȯ��һ������,�˴�Ҫ��Left Join 
						inner JOIN iCouponsGeneral ig  with(nolock) ON i.CouponsCode=ig.CouponsCode
						inner JOIN iMatGeneral ig2  with(nolock) ON s.MatCode=ig2.MatCode
						inner JOIN iMatGroup ig3  with(nolock) ON ig2.MatGroup=ig3.matgroup
						WHERE ch.Doccode=@doccode
					END
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
			END
		--��������
		update #DocData
		set PresentCount= commondb.dbo.REGEXP_Replace(PresentCount, '(?:^|\b)(?<!&|''|#)((\d:)?[\u4e00-\u9fa5]+)(?!&|''|#)(?:$|\b)','#$1#'),
		PresentMoney=commondb.dbo.REGEXP_Replace(PresentMoney,  '(?:^|\b)(?<!&|''|#)((\d:)?[\u4e00-\u9fa5]+)(?!&|''|#)(?:$|\b)','#$1#')
		where ISNULL(PresentMoney,'')!='' OR ISNULL(PresentCount,'')!=''
		select * from #DocData
		--��Դ��ʽΪ��1����3����5��Ҫ����,����Ż�ȯ״̬
		--��Դ��ʽΪ��1����3����5��Ҫ����,����Ż�ȯ״̬
		SELECT @tips='' 
		SELECT @tips=@tips+'�Ż�ȯ'+a.CouponsName+'['+a.CouponsBarcode+']'+'��ǰ״̬Ϊ['+ISNULL(a.state,'')+'],�޷��һ���'+dbo.crlf()
		FROM #DocData a  with(nolock)
		WHERE a.SourceMode IN(1,2)
		AND a.[STATE]!='�ڿ�'
		IF @@ROWCOUNT>0
			BEGIN
				drop TABLE #DocData
				RAISERROR(@tips,16,1)
				return
			END
		--��Ч�ڿ���
		SELECT @tips='�����Ż�ȯ�ѹ���Ч��.'+dbo.crlf()
		SELECT @tips=@tips+a.CouponsBarcode+'['+a.CouponsName+']'+dbo.crlf()
		FROM #DocData a
		WHERE (
			--��ǰ���ڲ���С���Ż�ȯ�����е���ʼ���ں��Ż�ȯ���е���ʼ����,���κ�һ����ʼ��������Ϊ��,��Ĭ��Ϊgetdate()
			(GETDATE()<ISNULL(a.BeginDate,GETDATE()) OR GETDATE()<ISNULL(a.beginValidDate,GETDATE())
			--��ǰ���ڲ��ܴ����κ�һ���������,���κ�һ����ֹ��������Ϊ��,��Ĭ��Ϊ'2099-01-01'
			OR(GETDATE()>ISNULL(a.EndDate,'2099-01-01') OR GETDATE()>ISNULL(a.endValidDate,'2099-01-01')
			))					)
		IF @@ROWCOUNT>0
			BEGIN
				RAISERROR(@tips,16,1)
				RETURN
			END
		--�ж��Ƿ����һ���Ż�ȯ��ͬһ�ŵ���ʹ�ö��
		SELECT @tips='�����Ż�ȯֻ��ʹ��һ��.'+dbo.crlf()
		;WITH cte AS(
			SELECT a.CouponsBarcode,a.CouponsName,COUNT(a.CouponsBarcode) AS num
			FROM #DocData a
			GROUP BY a.CouponsBarcode,a.CouponsName
			)
		SELECT @tips=@tips+a.CouponsBarcode+'['+a.CouponsName+']��ʹ��'+convert(VARCHAR(5),a.num)+'��.'+dbo.crlf()
		FROM cte a
		WHERE a.num>1
		IF @@rowcount>0
			BEGIN
				RAISERROR(@tips,16,1)
				RETURN
			END
	/******************************************************************�Ż�ȯ��������***********************************************************************/
	--�ж�һ���Ż�ȯ,��һ����Ʒ��,�Ƿ񳬹���������
	--ͳ��ÿ����Ʒ��ÿ���Ż�ȯ�ϵ�ʹ������.
	--���ڶ�"������"�һ����Ż�ȯ����������.
	IF EXISTS(SELECT 1 FROM #DocData WHERE PresentMode='������')
		BEGIN
 
			SELECT @tips='�����Ż�ȯ����������������.'+dbo.crlf()
			;WITH cte AS(
				SELECT couponscode,COUNT(CouponsBarcode) AS num,a.PresentCount, a.CouponsName
				FROM #DocData a
				WHERE  a.PresentMode='������'
				GROUP BY couponscode,a.PresentCount,CouponsName
				)
			SELECT @tips=@tips+'['+isnull(a.CouponsName,'')+']ÿ������ʹ��'+convert(varchar(10),isnull(a.PresentCount,1))+'��,������ʹ��'+convert(varchar(10),isnull(a.num,0))+'��.'+dbo.crlf()
			FROM cte a
			WHERE a.num>a.PresentCount
			IF @@ROWCOUNT>0
				BEGIN
					RAISERROR(@tips,16,1)
					RETURN
				END
		END
	--����Ʒ�һ����Ż�ȯ,ÿ��ֻ������һ����Ʒ
	--��Ҫ���ÿ����Ʒʹ�õ��Ż�ȯ,�Ƿ񳬹��Ż����õ��������
	--���ڼ��"����Ʒ"�һ����Ż�ȯ��������
	IF EXISTS(SELECT 1 FROM #DocData WHERE PresentMode='����Ʒ')
		BEGIN
				--�жϰ���Ʒ�һ����Ż�ȯ,�Ƿ񳬹���������
				SELECT @tips='�����Żݳ����һ���������.'+dbo.crlf()
				;WITH cte AS(
					SELECT a.seriescode,a.RefRowID, Matcode,matname,couponscode,CouponsName,a.digit,a.PresentCount, COUNT(a.CouponsBarcode) AS NUM
						FROM #DocData a with(nolock)
					WHERE ExchangeMode='����Ʒ'
					GROUP BY  a.seriescode,a.refrowid,Matcode,a.matname,CouponsCode,CouponsName,a.digit,a.PresentCount
					)
					SELECT @tips=@tips+'['+couponsName+']�ֿ���Ʒ['+a.matname+']ʱ����ʹ��'+convert(varchar(20),a.PresentCount*a.digit)+'��,Ŀǰ��ʹ��'+convert(varchar(20),a.num)+'��,'+ dbo.crlf() 
					FROM cte a
					WHERE a.num>a.PresentCount*a.digit
					IF @@ROWCOUNT>0
						BEGIN
							RAISERROR(@tips,16,1)
							return
						END
		END
		--select * from #DocData
		--ִ�����͹����ж�
		SELECT @tips ='�����Ż�ȯ���������͹���,����ϸ�鿴�Ż�ȯʹ���ֲ�!'+dbo.crlf()
		SELECT @tips=@tips+a.couponsName+'['+a.couponsbarcode+']'+dbo.crlf()
		FROM #DocData a
		where NOT EXISTS(SELECT 1 FROM   Strategy_Coupons sc  with(nolock)  
						WHERE a.CouponsCode=sc.CouponsCode 
						AND sc.Straytegygroup='02.01.01'
						AND (ISNULL(sc.Matcode,'')='' OR sc.Matcode=a.Matcode)
						AND (ISNULL(sc.Matgroup,'')='' OR a.MatgroupPath LIKE '%/'+sc.Matgroup+'/%')
						AND (ISNULL(sc.SdorgID,'')='' OR a.SdorgPath LIKE '%/'+sc.SdorgID+'/%')
						AND (ISNULL(sc.AreaID,'')='' OR EXISTS(SELECT 1 FROM commondb.dbo.[SPLIT](ISNULL(sc.AreaID,''),',') s WHERE a.AreaPath LIKE '%/'+s.List+'/%'))
						AND convert(bit,dbo.ExecuteScalar(0, commondb.dbo.REGEXP_Replace(ISNULL(NULLIF(sc.Filter,''),'1'),  '(?:^|\b)(?<!&|''|#)((\d:)?[\u4e00-\u9fa5]+)(?!&|''|#)(?:$|\b)','#$1#')
						,'Select * From #DocData','CouponsBarcode='''+a.CouponsBarcode+'''',-1,
						'Select * From fn_getFormulaFields(''9146,'+CONVERT(VARCHAR(20),@formid)+CASE WHEN ISNULL(@refFormid,'')!='' THEN ','+CONVERT(VARCHAR(20),@refFormid) ELSE '' END +''')',0))=1
		)
		AND EXISTS(SELECT 1 FROM   Strategy_Coupons sc    with(nolock)
						WHERE a.CouponsCode=sc.CouponsCode 
						AND sc.Straytegygroup='02.01.01')
 
		IF @@ROWCOUNT>0
			BEGIN
				drop TABLE #DocData
				RAISERROR(@tips,16,1)
				return
			END
	END