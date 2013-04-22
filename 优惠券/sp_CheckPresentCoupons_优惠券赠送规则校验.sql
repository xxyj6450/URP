/*
过程名称：sp_CheckPresentCoupons
功能描述：校验优惠券赠送规则
参数：见声名;除过程的参数外，还需要传入一个#CouponsDocData的临时表，在此临时表中存储业务数据和优惠券数据，本过程仅根据此数据源进行校验。
返回值：
编写：三断笛
备注：
#CouponsDocData可按具体业务传入具体值
*/
alter proc sp_CheckPresentCoupons
	@FormID int,
	@Doccode varchar(50),
	@RefFormID int=0,
	@Refcode varchar(20)='',
	@Stcode varchar(50)='',
	@CustomerCode varchar(50)='',
	@PackageID varchar(50)='',
	@ComboCode int=0,
	@OptionID varchar(200)='',					--若传入值为#PreCheck#，则仅限制优惠券状态必须为在库或已赠。
	@Usercode varchar(50)=''
as
	BEGIN
		set NOCOUNT on;
		declare @tips varchar(max)
		--若未传入数据源，则自己组织
		if object_id('tempdb.dbo.#CouponsDocData') is NULL
			BEGIN
				CREATE TABLE #CouponsDocData(
					Doccode VARCHAR(20),
					DocDate DATETIME,
					FormID INT,
					Doctype VARCHAR(50),
					RefFormID INT,
					Refcode VARCHAR(20),
					packageID VARCHAR(20),
					ComboCode VARCHAR(50),
					ComboPrice money,
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
					PresentFormGroup varchar(500),
					ExchangeMode VARCHAR(50),
					ExchangeCount VARCHAR(500),
					ExchangeMoney VARCHAR(500),
					ExchangeFormGroup varchar(500),
					ForceCheckStock BIT,
					BeginDate DATETIME,								--优惠券资料表中的起始有效期
					EndDate DATETIME,									--优惠券资料表中的终止有效期
					Valid BIT,
					CouponsPrice VARCHAR(500),
					RowID varchar(50),
					Seriescode varchar(50),
					RefRowID varchar(50),
					Matcode VARCHAR(50),
					MatName varchar(200),
					Matgroup VARCHAR(50),
					MatType VARCHAR(50),
					MatgroupPath VARCHAR(500),
					Price MONEY,
					totalmoney MONEY,
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
					CouponsAuthKey	VARCHAR(50)	,				--优惠券表中的校验密码
					Occupyed bit,
					OccupyedDoccode varchar(50)
				)
				--将待处理数据放至临时表
				IF @Formid IN(2419)
					begin
						INSERT INTO #CouponsDocData
							(  Doccode,   DocDate,   FormID,   Doctype,   
								RefFormID,   Refcode,   packageID,   ComboCode,   
								SdorgID,   dptType,   SdorgPath,   
								AreaID,   AreaPath,   stcode,   companyID,   
								cltCode,   CouponsBarcode,   STATE,   CouponsCode,   
								CouponsName,   CouponsgroupCode,   CodeMode,   
								CodeLength,   SourceMode,   PresentMode,   
								PresentCount,   PresentMoney,  PresentFormGroup, ExchangeMode,   
								ExchangeCount,   ExchangeMoney,ExchangeFormGroup,   ForceCheckStock,   
								BeginDate,   EndDate,   Valid,   CouponsPrice,   Matcode, matname,  
								Matgroup,   MatType,   MatgroupPath,   Price,   
								totalMoney,   digit,   deductAmount,CouponsOwner,canOverlay,RowID,RefRowID,
								Seriescode,beginValidDate,endValidDate,OWNER,CouponsAuthKey,Occupyed,OccupyedDoccode )

						select @Doccode,getdate(),@FormID,NULL as DocType,NULL,NULL,@PackageID as packageid,@combocode AS combocode,
						o2.SDOrgID,o2.dptType, o2.[PATH],g.areaid,g.[PATH],o.stCode,o.PlantID,@Customercode,
						s.CouponsBarCode,i.State [State],ig.CouponsCode,ig.CouponsName, ig.GroupCode,ig.CodeMode,ig.CodeLength,
						ig.SourceMode,ig.PresentMode,ig.PresentCount,ig.PresentMoney,ig.PresentFormGroup,ig.ExchangeMode,ig.ExchangeCount,ig.ExchangeMoney,ig.FormGroup,
						ig.ForceCheckStock,ig.BeginDate,ig.EndDate,ig.Valid,ig.Price,	s.MatCode,s.MatName,ig2.MatGroup,ig2.mattype,ig3.[PATH],
						s.price,s.totalmoney,s.Digit,s.DeductAmout,ig.CouponsOwner,ig.canOverlay,s.RowID,newid() RefRowID,s.SeriesCode,i.beginValidDate,i.ValidDate,
						i.CouponsOWNER,i.authKey,i.Occupyed,i.OccupyedDoccode
						FROM  sPickorderitem s with(nolock) INNER JOIN oStorage o  with(nolock) ON o.stCode=@Stcode
						INNER JOIN oSDOrg o2  with(nolock) ON o.sdorgid=o2.SDOrgID
						INNER JOIN gArea g  with(nolock) ON o2.AreaID=g.areaid
						left JOIN iCoupons i  with(nolock) ON s.CouponsBarCode=i.CouponsBarcode						--优惠券不一定存在,此处要用Left Join 
						left JOIN iCouponsGeneral ig  with(nolock) ON i.CouponsCode=ig.CouponsCode
						left JOIN iMatGeneral ig2  with(nolock) ON s.MatCode=ig2.MatCode
						left JOIN iMatGroup ig3  with(nolock) ON ig2.MatGroup=ig3.matgroup
						WHERE s.Doccode=@doccode
					end
				if @FormID in(9201)
					BEGIN
						--将待处理数据放至临时表
								INSERT INTO #CouponsDocData
									(  Doccode,   DocDate,   FormID,   Doctype,   
										RefFormID,   Refcode,   packageID,   ComboCode,   
										SdorgID,   dptType,   SdorgPath,   
										AreaID,   AreaPath,   stcode,   companyID,   
										cltCode,   CouponsBarcode,   STATE,   CouponsCode,   
										CouponsName,   CouponsgroupCode,   CodeMode,   
										CodeLength,   SourceMode,   PresentMode,   
										PresentCount,   PresentMoney, PresentFormGroup,  ExchangeMode,   
										ExchangeCount,   ExchangeMoney, ExchangeFormGroup,  ForceCheckStock,   
										BeginDate,   EndDate,   Valid,   CouponsPrice,   Matcode, matname,
										Matgroup,   MatType,   MatgroupPath,   Price,   
										totalMoney,   digit,   deductAmount ,RowID,RefRowID,Seriescode,OWNER,CouponsAuthKey,Occupyed,OccupyedDoccode )
								select ch.Doccode,ch.docdate,ch.FormID,NULL DocType,@refFormID,@Refcode DocCode,@PackageID,@ComboCode AS combocode,
								o2.SDOrgID,o2.dptType, o2.[PATH],g.areaid,g.[PATH],o.stCode,o.PlantID,ch.cltCode,
								cd.CouponsBarCode,i.[State],ig.CouponsCode,cd.CouponsName,ig.GroupCode,ig.CodeMode,ig.CodeLength,
								ig.SourceMode,ig.PresentMode,ig.PresentCount,ig.PresentMoney,ig.PresentFormGroup,ig.ExchangeMode,ig.ExchangeCount,ig.ExchangeMoney,ig.FormGroup,
								ig.ForceCheckStock,ig.BeginDate,ig.EndDate,ig.Valid,ig.price,cd.MatCode,cd.matname,ig2.MatGroup,ig2.mattype,ig3.[PATH],
								cd.Amount,cd.Amount,cd.DeductAmout,cd.DeductAmout,cd.RowID,cd.RefRowID,cd.SeriesCode,i.CouponsOWNER,i.authkey ,i.Occupyed,i.OccupyedDoccode
								FROM Coupons_H ch  with(nolock) INNER JOIN oStorage o  with(nolock) ON ch.Stcode=o.stCode
								INNER JOIN oSDOrg o2  with(nolock) ON o.sdorgid=o2.SDOrgID
								INNER JOIN gArea g  with(nolock) ON o2.AreaID=g.areaid
								INNER JOIN Coupons_D cd  with(nolock) ON ch.Doccode=cd.Doccode
								INNER JOIN iCouponsGeneral ig  with(nolock) ON cd.CouponsCode=ig.CouponsCode
								left JOIN iCoupons i  with(nolock) ON cd.CouponsBarCode=i.CouponsBarcode						--优惠券不一定存在,此处要用Left Join 
								LEFT JOIN iMatGeneral ig2  with(nolock) ON cd.MatCode=ig2.MatCode
								LEFT JOIN iMatGroup ig3  with(nolock) ON ig2.MatGroup=ig3.matgroup
								WHERE ch.Doccode=@doccode
					END
				
				if @FormID in(9146,9102,9237)
					BEGIN
						--将数据准备至临时表
						if object_id('tempdb.dbo.#Unicom_OrderDetails') is null select * Into #Unicom_OrderDetails From Unicom_OrderDetails with(nolock) where DocCode=@Doccode
						;with   cte_unicom_orderdetails(doccode,seriescode,matcode,MatName,rowid,digit,price,totalmoney,couponsbarcode,DeductAmout) as(
							select doccode,seriescode,matcode,matname,rowid,digit,price,totalmoney,couponsbarcode,uod.DeductAmout
							from #Unicom_OrderDetails uod with(nolock)
							where uod.DocCode=@Doccode
							and isnull(uod.couponsbarcode,'')<>''
							union all
							select @Doccode,uo.SeriesCode,uo.matcode,uo.MatName,newid(),1,uo.MatPrice,uo.MatMoney,uo.matCouponsbarcode,uo.matDeductAmount
							from Unicom_Orders uo with(nolock) where uo.DocCode=@Doccode
							and isnull(uo.matCouponsbarcode,'')<>''
						)
						INSERT INTO #CouponsDocData
							(  Doccode,   DocDate,   FormID,   Doctype,   
								RefFormID,   Refcode,   packageID,   ComboCode,   
								SdorgID,   dptType,   SdorgPath,   
								AreaID,   AreaPath,   stcode,   companyID,   
								cltCode,   CouponsBarcode,   STATE,   CouponsCode,   
								CouponsName,   CouponsgroupCode,   CodeMode,   
								CodeLength,   SourceMode,   PresentMode,   
								PresentCount,   PresentMoney, PresentFormGroup,  ExchangeMode,   
								ExchangeCount,   ExchangeMoney,ExchangeFormGroup,   ForceCheckStock,   
								BeginDate,   EndDate,   Valid,   CouponsPrice,   Matcode, matname,  
								Matgroup,   MatType,   MatgroupPath,   Price,   
								totalMoney,   digit,   deductAmount,CouponsOwner,canOverlay,RowID,RefRowID,
								Seriescode,beginValidDate,endValidDate,OWNER,CouponsAuthKey,Occupyed,OccupyedDoccode  )

						select @Doccode,getdate(),@FormID,NULL as DocType,NULL,NULL,@PackageID,@Combocode AS combocode,
						o2.SDOrgID,o2.dptType, o2.[PATH],g.areaid,g.[PATH],o.stCode,o.PlantID,@Customercode,
						s.CouponsBarCode,i.state [State],ig.CouponsCode,ig.CouponsName, ig.GroupCode,ig.CodeMode,ig.CodeLength,
						ig.SourceMode,ig.PresentMode,ig.PresentCount,ig.PresentMoney,PresentFormGroup,ig.ExchangeMode,ig.ExchangeCount,ig.ExchangeMoney,ig.FormGroup,
						ig.ForceCheckStock,ig.BeginDate,ig.EndDate,ig.Valid,ig.price,	s.MatCode,s.MatName,ig2.MatGroup,ig2.mattype,ig3.[PATH],
						s.price,s.totalmoney,s.Digit,s.DeductAmout,ig.CouponsOwner,ig.canOverlay,s.RowID,newid() RefRowID,
						s.SeriesCode,i.beginValidDate,i.ValidDate,i.CouponsOWNER,i.authKey,i.Occupyed,i.OccupyedDoccode
						FROM cte_unicom_orderdetails  s  with(nolock) INNER JOIN oStorage o  with(nolock) ON o.stCode=@Stcode
						INNER JOIN oSDOrg o2  with(nolock) ON o.sdorgid=o2.SDOrgID
						INNER JOIN gArea g  with(nolock) ON o2.AreaID=g.areaid
						left JOIN iCoupons i  with(nolock) ON s.CouponsBarCode=i.CouponsBarcode						--优惠券不一定存在,此处要用Left Join 
						left JOIN iCouponsGeneral ig  with(nolock) ON i.CouponsCode=ig.CouponsCode
						left JOIN iMatGeneral ig2  with(nolock) ON s.MatCode=ig2.MatCode
						left JOIN iMatGroup ig3  with(nolock) ON ig2.MatGroup=ig3.matgroup
						WHERE s.Doccode=@doccode
						
					END
 				--对于指定的功能号,更新政策信息
				IF @refFormid IN(9102,9146,9237) or @FormID IN(9102,9146,9237)
					BEGIN
						update a
							set a.PackageType=isnull(b.DocType,'')
						From #CouponsDocData a left join policy_h b WITH(NOLOCK) on a.packageid=b.doccode
						update a
							set a.ComboPrice=ch.Price
						from #CouponsDocData a left join Combo_H ch with(nolock) on a.ComboCode=ch.ComboCode
					END
				--处理中文
				update #CouponsDocData
				set PresentCount= commondb.dbo.REGEXP_Replace(PresentCount, '(?:^|\b)(?<!&|''|#)((\d:)?[\u4e00-\u9fa5]+)(?!&|''|#)(?:$|\b)','#$1#'),
				PresentMoney=commondb.dbo.REGEXP_Replace(PresentMoney,  '(?:^|\b)(?<!&|''|#)((\d:)?[\u4e00-\u9fa5]+)(?!&|''|#)(?:$|\b)','#$1#')
				where ISNULL(PresentMoney,'')!='' OR ISNULL(PresentCount,'')!=''
				--select * from #CouponsDocData a
				--根据表达式计算可兑换数量和金额.若抵扣数量和抵扣额度本身已经是数字,就不再执行更新了.否则按表达式处理.
				IF    EXISTS (SELECT 1 FROM #CouponsDocData a WHERE ISNUMERIC(ISNULL(a.PresentCount,'1'))=0  )
					BEGIN
							print 'Select * From fn_getFormulaFields('''+CONVERT(VARCHAR(20),@formid)+CASE WHEN ISNULL(@refFormid,'')!='' THEN ','+CONVERT(VARCHAR(20),@refFormid) ELSE '' END +''')'
						UPDATE  a
						SET a.PresentCount=convert(float,b.data1) 
						FROM #CouponsDocData a OUTER APPLY dbo.ExecuteTable(0,ISNULL(a.PresentCount,'1'),
						'Select * From #CouponsDocData','CouponsBarcode='''+a.CouponsBarcode+'''',-1,
						'Select * From fn_getFormulaFields('''+CONVERT(VARCHAR(20),@formid)+CASE WHEN ISNULL(@refFormid,'')!='' THEN ','+CONVERT(VARCHAR(20),@refFormid) ELSE '' END +''')',0) b
					
					END
			END
		--select * from #CouponsDocData
		--若不存在优惠券，则直接退出了
		if not exists(select 1 from #CouponsDocData where isnull(CouponsBarcode,'')<>'')
			BEGIN
				print '优惠券赠送规则检查-->没有优惠券业务数据,操作中止.'
				return -1
			END
		
		--来源方式为○1，○3，○5需要赠送,检查优惠券状态
		--来源方式为○1，○3，○5需要赠送,检查优惠券状态
		SELECT @tips='' 
		if @OptionID='#Precheck#'
			BEGIN
				SELECT @tips=@tips+'优惠券'+isnull(a.CouponsName,'')+'['+a.CouponsBarcode+']'+'当前状态为['+ISNULL(a.state,'不存在')+'],无法赠送。'+dbo.crlf()
				FROM #CouponsDocData a  with(nolock)
				WHERE isnull(a.SourceMode,1) IN(1,2)
				AND isnull(a.[STATE],'') not in('已赠','在库')
				IF @@ROWCOUNT>0
					BEGIN
						drop TABLE #CouponsDocData
						RAISERROR(@tips,16,1)
						return
					END
			END
		else
			BEGIN
				SELECT @tips=@tips+'优惠券'+isnull(a.CouponsName,'')+'['+a.CouponsBarcode+']'+'当前状态为['+ISNULL(a.state,'不存在')+'],无法赠送。'+dbo.crlf()
				FROM #CouponsDocData a  with(nolock)
				WHERE isnull(a.SourceMode,1) IN(1,2)
				AND isnull(a.[STATE],'')!='在库'
				IF @@ROWCOUNT>0
					BEGIN
						drop TABLE #CouponsDocData
						RAISERROR(@tips,16,1)
						return
					END
			END
		select @tips=''
		select @tips=@tips+i.couponsname+'['+i.couponsbarcode+']已被单据['+isnull(i.OccupyedDoccode,'')+']占用，禁止重复使用.'
		from #CouponsDocData i
		where i.Occupyed=1
		if @@ROWCOUNT>0
			BEGIN
				raiserror(@tips,16,1)
				return
			END
		--若没有待赠送的优惠券,则退出检查
		if not exists(select 1 from #CouponsDocData where STATE='在库') return
		--检查优惠券是否已启用
		select @tips=''
		select @tips=@tips+a.CouponsName+'['+a.CouponsBarcode+']未启用，禁止使用。'+char(10)
		from #CouponsDocData a
		where isnull(Valid,0)=0
		if @@ROWCOUNT>0
			BEGIN
				raiserror(@tips,16,1)
				return
			END
		--有效期控制
		SELECT @tips='以下优惠券已过有效期.'+dbo.crlf()
		SELECT @tips=@tips+a.CouponsBarcode+'['+a.CouponsName+']'+dbo.crlf()
		FROM #CouponsDocData a
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
		--判断优惠券是否可用于指定功能
		select @tips=''
		select @tips=@tips+a.couponsname+'['+a.couponsbarcode+']不可用于本业务.'+char(10)
		from #CouponsDocData a where isnull(nullif(ltrim(rtrim(a.PresentFormGroup)),''),'9201')!='9201'												--若未设置可赠送功能号，或设置为9201则任何业务可用
		and  a.formid not in( select list from commondb.dbo.SPLIT(isnull(a.PresentFormGroup,'9201'),',') )	
		and (isnull(a.RefFormID,0)=0 or a.refformid not in( select list from commondb.dbo.SPLIT(isnull(a.PresentFormGroup,'9201'),',')))
		if @@ROWCOUNT>0
			BEGIN
				raiserror(@tips,16,1)
				return
			END
		--判断是否存在一张优惠券中同一张单中使用多次
		SELECT @tips='以下优惠券只能使用一次.'+dbo.crlf()
		;WITH cte AS(
			SELECT a.CouponsBarcode,a.CouponsName,COUNT(a.CouponsBarcode) AS num
			FROM #CouponsDocData a
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
	IF EXISTS(SELECT 1 FROM #CouponsDocData WHERE PresentMode='按单据')
		BEGIN
 
			SELECT @tips='以下优惠券超过赠送数量限制.'+dbo.crlf()
			;WITH cte AS(
				SELECT couponscode,COUNT(CouponsBarcode) AS num,a.PresentCount, a.CouponsName
				FROM #CouponsDocData a
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
	--按商品赠送的优惠券必须有商品信息
	select @tips=''
	select @tips=@tips+a.CouponsName+'['+a.CouponsBarcode+']只能按商品赠送,但是业务单据中不包含商品信息，无法赠送。'+char(10)
	from #CouponsDocData a
	where a.PresentMode='按商品' and isnull(a.matcode,'')=''
	if @@ROWCOUNT>0
		BEGIN
			raiserror(@tips,16,1)
			return
		END
	--按商品兑换的优惠券,每张只能用于一个商品
	--需要检查每个商品使用的优惠券,是否超过优惠设置的最大张数
	--用于检查"按商品"兑换的优惠券数量控制
	
	IF EXISTS(SELECT 1 FROM #CouponsDocData WHERE PresentMode='按商品')
		BEGIN
				/*;WITH cte AS(
					SELECT a.seriescode,a.RefRowID, Matcode,matname,couponscode,CouponsName,a.digit,convert(money,a.PresentCount) as PresentCount, COUNT(a.CouponsBarcode) AS NUM
						FROM #CouponsDocData a with(nolock)
					WHERE ExchangeMode='按商品'
					GROUP BY  a.seriescode,a.refrowid,Matcode,a.matname,CouponsCode,CouponsName,a.digit,a.PresentCount
				)
				select * from cte*/
				--判断按商品兑换的优惠券,是否超过数量限制
				SELECT @tips='以下优惠超过兑换数量限制.'+dbo.crlf()
				;WITH cte AS(
					SELECT a.seriescode,a.RefRowID, Matcode,matname,couponscode,CouponsName,a.digit,convert(float,a.PresentCount) as PresentCount, COUNT(a.CouponsBarcode) AS NUM
						FROM #CouponsDocData a with(nolock)
					WHERE ExchangeMode='按商品'
					GROUP BY  a.seriescode,a.refrowid,Matcode,a.matname,CouponsCode,CouponsName,a.digit,a.PresentCount
					)
					SELECT @tips=@tips+'['+couponsName+']抵扣商品['+a.matname+']时仅能使用'+convert(varchar(20),convert(decimal,a.PresentCount*a.digit,2))+'张,目前已使用'+convert(varchar(20),a.num)+'张,'+ dbo.crlf() 
					FROM cte a
					WHERE isnull(a.num,0)>isnull(convert(decimal,a.PresentCount*a.digit,1),0)
					IF @@ROWCOUNT>0
						BEGIN
							RAISERROR(@tips,16,1)
							return
						END
		END
		--select * from #CouponsDocData
		--执行赠送规则判断
		SELECT @tips ='以下优惠券不符合赠送规则,请仔细查看优惠券使用手册!'+dbo.crlf()
		SELECT @tips=@tips+a.couponsName+'['+a.couponsbarcode+']'+dbo.crlf()
		FROM #CouponsDocData a
		where NOT EXISTS(SELECT 1 FROM   Strategy_Coupons sc  with(nolock)  
						WHERE a.CouponsCode=sc.CouponsCode 
						AND sc.Straytegygroup='02.01.01'
						AND (ISNULL(sc.Matcode,'')='' OR sc.Matcode=a.Matcode)
						AND (ISNULL(sc.Matgroup,'')='' OR a.MatgroupPath LIKE '%/'+sc.Matgroup+'/%')
						AND (ISNULL(sc.SdorgID,'')='' OR a.SdorgPath LIKE '%/'+sc.SdorgID+'/%')
						AND (ISNULL(sc.AreaID,'')='' OR EXISTS(SELECT 1 FROM commondb.dbo.[SPLIT](ISNULL(sc.AreaID,''),',') s WHERE a.AreaPath LIKE '%/'+s.List+'/%'))
						AND convert(bit,dbo.ExecuteScalar(0, commondb.dbo.REGEXP_Replace(ISNULL(NULLIF(sc.Filter,''),'1'),  '(?:^|\b)(?<!&|''|#)((\d:)?[\u4e00-\u9fa5]+)(?!&|''|#)(?:$|\b)','#$1#')
						,'Select * From #CouponsDocData','CouponsBarcode='''+a.CouponsBarcode+'''',-1,
						'Select * From fn_getFormulaFields(''9146,'+CONVERT(VARCHAR(20),@formid)+CASE WHEN ISNULL(@refFormid,'')!='' THEN ','+CONVERT(VARCHAR(20),@refFormid) ELSE '' END +''')',0))=1
		)
		AND EXISTS(SELECT 1 FROM   Strategy_Coupons sc    with(nolock)
						WHERE a.CouponsCode=sc.CouponsCode 
						AND sc.Straytegygroup='02.01.01')
 
		IF @@ROWCOUNT>0
			BEGIN
				drop TABLE #CouponsDocData
				RAISERROR(@tips,16,1)
				return
			END
	END