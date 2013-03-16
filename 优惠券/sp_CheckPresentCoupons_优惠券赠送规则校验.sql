/*
过程名称：sp_CheckPresentCoupons
功能描述：校验优惠券赠送规则
参数：见声名;除过程的参数外，还需要传入一个#DocData的临时表，在此临时表中存储业务数据和优惠券数据，本过程仅根据此数据源进行校验。
返回值：
编写：三断笛
备注：
#DocData可按具体业务传入具体值，一般性声名如下：
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
示例：
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
		--业务数据校验
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
						inner JOIN iCoupons i  with(nolock) ON s.CouponsBarCode=i.CouponsBarcode						--优惠券不一定存在,此处要用Left Join 
						inner JOIN iCouponsGeneral ig  with(nolock) ON i.CouponsCode=ig.CouponsCode
						inner JOIN iMatGeneral ig2  with(nolock) ON s.MatCode=ig2.MatCode
						inner JOIN iMatGroup ig3  with(nolock) ON ig2.MatGroup=ig3.matgroup
						WHERE ch.Doccode=@doccode
					end
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
				if @FormID in(9146,9102)
					BEGIN
						--将数据准备至临时表
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
						inner JOIN iCoupons i  with(nolock) ON s.CouponsBarCode=i.CouponsBarcode						--优惠券不一定存在,此处要用Left Join 
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
			END
		--处理中文
		update #DocData
		set PresentCount= commondb.dbo.REGEXP_Replace(PresentCount, '(?:^|\b)(?<!&|''|#)((\d:)?[\u4e00-\u9fa5]+)(?!&|''|#)(?:$|\b)','#$1#'),
		PresentMoney=commondb.dbo.REGEXP_Replace(PresentMoney,  '(?:^|\b)(?<!&|''|#)((\d:)?[\u4e00-\u9fa5]+)(?!&|''|#)(?:$|\b)','#$1#')
		where ISNULL(PresentMoney,'')!='' OR ISNULL(PresentCount,'')!=''
		select * from #DocData
		--来源方式为○1，○3，○5需要赠送,检查优惠券状态
		--来源方式为○1，○3，○5需要赠送,检查优惠券状态
		SELECT @tips='' 
		SELECT @tips=@tips+'优惠券'+a.CouponsName+'['+a.CouponsBarcode+']'+'当前状态为['+ISNULL(a.state,'')+'],无法兑换。'+dbo.crlf()
		FROM #DocData a  with(nolock)
		WHERE a.SourceMode IN(1,2)
		AND a.[STATE]!='在库'
		IF @@ROWCOUNT>0
			BEGIN
				drop TABLE #DocData
				RAISERROR(@tips,16,1)
				return
			END
		--有效期控制
		SELECT @tips='以下优惠券已过有效期.'+dbo.crlf()
		SELECT @tips=@tips+a.CouponsBarcode+'['+a.CouponsName+']'+dbo.crlf()
		FROM #DocData a
		WHERE (
			--当前日期不能小于优惠券资料中的起始日期和优惠券表中的起始日期,若任何一项起始日期设置为空,则默认为getdate()
			(GETDATE()<ISNULL(a.BeginDate,GETDATE()) OR GETDATE()<ISNULL(a.beginValidDate,GETDATE())
			--当前日期不能大于任何一项结束日期,若任何一项终止日期设置为空,则默认为'2099-01-01'
			OR(GETDATE()>ISNULL(a.EndDate,'2099-01-01') OR GETDATE()>ISNULL(a.endValidDate,'2099-01-01')
			))					)
		IF @@ROWCOUNT>0
			BEGIN
				RAISERROR(@tips,16,1)
				RETURN
			END
		--判断是否存在一张优惠券中同一张单中使用多次
		SELECT @tips='以下优惠券只能使用一次.'+dbo.crlf()
		;WITH cte AS(
			SELECT a.CouponsBarcode,a.CouponsName,COUNT(a.CouponsBarcode) AS num
			FROM #DocData a
			GROUP BY a.CouponsBarcode,a.CouponsName
			)
		SELECT @tips=@tips+a.CouponsBarcode+'['+a.CouponsName+']已使用'+convert(VARCHAR(5),a.num)+'次.'+dbo.crlf()
		FROM cte a
		WHERE a.num>1
		IF @@rowcount>0
			BEGIN
				RAISERROR(@tips,16,1)
				RETURN
			END
	/******************************************************************优惠券数量控制***********************************************************************/
	--判断一种优惠券,在一个商品上,是否超过数量限制
	--统计每个商品在每个优惠券上的使用数量.
	--用于对"按单据"兑换类优惠券的数量控制.
	IF EXISTS(SELECT 1 FROM #DocData WHERE PresentMode='按单据')
		BEGIN
 
			SELECT @tips='以下优惠券超过赠送数量限制.'+dbo.crlf()
			;WITH cte AS(
				SELECT couponscode,COUNT(CouponsBarcode) AS num,a.PresentCount, a.CouponsName
				FROM #DocData a
				WHERE  a.PresentMode='按单据'
				GROUP BY couponscode,a.PresentCount,CouponsName
				)
			SELECT @tips=@tips+'['+isnull(a.CouponsName,'')+']每单仅能使用'+convert(varchar(10),isnull(a.PresentCount,1))+'张,本单已使用'+convert(varchar(10),isnull(a.num,0))+'张.'+dbo.crlf()
			FROM cte a
			WHERE a.num>a.PresentCount
			IF @@ROWCOUNT>0
				BEGIN
					RAISERROR(@tips,16,1)
					RETURN
				END
		END
	--按商品兑换的优惠券,每张只能用于一个商品
	--需要检查每个商品使用的优惠券,是否超过优惠设置的最大张数
	--用于检查"按商品"兑换的优惠券数量控制
	IF EXISTS(SELECT 1 FROM #DocData WHERE PresentMode='按商品')
		BEGIN
				--判断按商品兑换的优惠券,是否超过数量限制
				SELECT @tips='以下优惠超过兑换数量限制.'+dbo.crlf()
				;WITH cte AS(
					SELECT a.seriescode,a.RefRowID, Matcode,matname,couponscode,CouponsName,a.digit,a.PresentCount, COUNT(a.CouponsBarcode) AS NUM
						FROM #DocData a with(nolock)
					WHERE ExchangeMode='按商品'
					GROUP BY  a.seriescode,a.refrowid,Matcode,a.matname,CouponsCode,CouponsName,a.digit,a.PresentCount
					)
					SELECT @tips=@tips+'['+couponsName+']抵扣商品['+a.matname+']时仅能使用'+convert(varchar(20),a.PresentCount*a.digit)+'张,目前已使用'+convert(varchar(20),a.num)+'张,'+ dbo.crlf() 
					FROM cte a
					WHERE a.num>a.PresentCount*a.digit
					IF @@ROWCOUNT>0
						BEGIN
							RAISERROR(@tips,16,1)
							return
						END
		END
		--select * from #DocData
		--执行赠送规则判断
		SELECT @tips ='以下优惠券不符合赠送规则,请仔细查看优惠券使用手册!'+dbo.crlf()
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