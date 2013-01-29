/*
过程名称：sp_CheckDeductCoupons
功能描述：校验优惠券兑换规则
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
alter proc sp_CheckDeductCoupons
	@FormID int,
	@Doccode varchar(50),
	@RefFormID int,
	@OptionID varchar(200)='',
	@Usercode varchar(50)=''
as
	BEGIN
		set NOCOUNT on;
		declare @tips varchar(max)
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
		--业务数据校验
		if object_id('tempdb.dbo.#Docdata') is NULL
			BEGIN
				raiserror('业务数据不存在，无法校验优惠券.',16,1)
				return
			END
		
		--来源方式为○1，○3，○5需要赠送,检查优惠券状态
		SELECT @tips='' 
		SELECT @tips=@tips+'优惠券'+a.CouponsName+'['+a.CouponsBarcode+']'+'当前状态为['+ISNULL(a.state,'')+'],无法兑换。'+dbo.crlf()
		FROM #DocData a  with(nolock)
		WHERE a.SourceMode IN(1,2)
		AND a.[STATE]!='已赠'
		IF @@ROWCOUNT>0
			BEGIN
				drop TABLE #DocData
				RAISERROR(@tips,16,1)
				return
			END
		--按商品兑换的优惠券,必须有源单据商品信息,防止错误兑换优惠券
		select @tips=''
		select @tips=@tips+'商品['+matname+']在源单据中已不存在,不允许再使用优惠券['+couponsbarcode+'].'+dbo.crlf()
		From #DocData a
		where a.ExchangeMode='按商品'
		and (isnull(a.RefRowID,'')='' or isnull(a.Matcode,'')='')
		if @@ROWCOUNT>0
			BEGIN
				raiserror(@tips,16,1)
				return
			END
		--从优惠券表更新优惠券信息
		UPDATE a
			SET a.[STATE]=ic.[State],
			[OWNER] = ic.CouponsOWNER,
			CouponsAuthKey=ic.AuthKey,
			beginValidDate = ic.beginValidDate,
			endValidDate = ic.ValidDate
		FROM #DocData a,iCoupons ic WITH(NOLOCK)
		WHERE a.CouponsBarcode=ic.CouponsBarcode
	--处理中文
	update #DocData
	set PresentCount= commondb.dbo.REGEXP_Replace(isnull(ExchangeCount,''), '(?:^|\b)(?<!&|''|#)((\d:)?[\u4e00-\u9fa5]+)(?!&|''|#)(?:$|\b)','#$1#'),
	PresentMoney=commondb.dbo.REGEXP_Replace(isnull(ExchangeMoney,''),  '(?:^|\b)(?<!&|''|#)((\d:)?[\u4e00-\u9fa5]+)(?!&|''|#)(?:$|\b)','#$1#'),
	Price=commondb.dbo.REGEXP_Replace(isnull(Price,''),  '(?:^|\b)(?<!&|''|#)((\d:)?[\u4e00-\u9fa5]+)(?!&|''|#)(?:$|\b)','#$1#')
	where ISNULL(ExchangeCount,'')!='' OR ISNULL(ExchangeMoney,'')!='' OR ISNULL(Price,'')!=''
	--由本公司或系统发行的优惠券,需要为已赠送或使用中,才允许兑换
	SELECT @tips='以下优惠券未赠送,不允许兑换.'+dbo.crlf()
	SELECT @tips=@tips+a.CouponsName+'['+a.CouponsBarcode+']'+dbo.crlf()
	FROM #DocData a  with(nolock)
	WHERE a.SourceMode IN(1,2)
	AND isnull(a.[STATE],'') NOT IN('已赠','使用中')
	IF @@ROWCOUNT>0
		BEGIN
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
	--判断是否有不允许叠加使用的优惠券
	SELECT @tips='以下优惠券不允许与其他优惠券叠加使用.'+dbo.crlf()
	--归类统计优惠券种类及是否允许叠加信息
	;WITH  cte1 AS(
		SELECT couponscode,CouponsName,canOverlay
		FROM #DocData
		GROUP BY couponscode,CouponsName,canOverlay
		)
	SELECT @tips=@tips+a.CouponsName+dbo.crlf()
	FROM cte1 a
	WHERE ISNULL(canOverlay,0)=1
	AND  (SELECT COUNT(couponscode) FROM cte1 )>1		--判断优惠券数量是否大于1
	IF @@ROWCOUNT>0
		BEGIN
			RAISERROR(@tips,16,1)
			RETURN
		END
	--根据表达式计算可兑换数量和金额.若抵扣数量和抵扣额度本身已经是数字,就不再执行更新了.否则按表达式处理.
	IF not  EXISTS (SELECT 1 FROM #DocData a WHERE ISNUMERIC(ISNULL(a.ExchangeCount,'1'))=1 AND ISNUMERIC(ISNULL(a.ExchangeMoney,'0'))=1 )
		BEGIN
			UPDATE  a
			SET a.ExchangeCount=convert(int,b.data1),
			a.ExchangeMoney=CONVERT(MONEY,b.data2)
			FROM #DocData a OUTER APPLY dbo.ExecuteTable(0,ISNULL(a.ExchangeCount,'1')+';'+ISNULL(a.ExchangeMoney,'0'),
			'Select * From #DocData','CouponsBarcode='''+a.CouponsBarcode+'''',-1,
			'Select * From fn_getFormulaFields('''+CONVERT(VARCHAR(20),@formid)+CASE WHEN ISNULL(@refFormid,'')!='' THEN ','+CONVERT(VARCHAR(20),@refFormid) ELSE '' END +''')',0) b
		END
	/******************************************************************优惠券数量控制***********************************************************************/
	--判断一种优惠券,在一个商品上,是否超过数量限制
	--统计每个商品在每个优惠券上的使用数量.
	--用于对"按单据"兑换类优惠券的数量控制.
	IF EXISTS(SELECT 1 FROM #DocData WHERE ExchangeMode='按单据')
		BEGIN
 
			SELECT @tips='以下优惠券超过兑换数量限制.'+dbo.crlf()
			;WITH cte AS(
				SELECT couponscode,COUNT(CouponsBarcode) AS num,a.ExchangeCount, a.CouponsName
				FROM #DocData a
				WHERE  a.ExchangeMode='按单据'
				GROUP BY couponscode,ExchangeCount,CouponsName
				)
			SELECT @tips=@tips+'['+isnull(a.CouponsName,'')+']每单仅能使用'+convert(varchar(10),isnull(a.ExchangeCount,1))+'张,本单已使用'+convert(varchar(10),isnull(a.num,0))+'张.'+dbo.crlf()
			FROM cte a
			WHERE a.num>a.ExchangeCount
			IF @@ROWCOUNT>0
				BEGIN
					RAISERROR(@tips,16,1)
					RETURN
				END
		END
	--按商品兑换的优惠券,每张只能用于一个商品
	--需要检查每个商品使用的优惠券,是否超过优惠设置的最大张数
	--用于检查"按商品"兑换的优惠券数量控制
	IF EXISTS(SELECT 1 FROM #DocData WHERE ExchangeMode='按商品')
		BEGIN
				--判断按商品兑换的优惠券,是否超过数量限制
				SELECT @tips='以下优惠超过兑换数量限制.'+dbo.crlf()
				;WITH cte AS(
					SELECT a.seriescode,a.RefRowID, Matcode,matname,couponscode,CouponsName,a.digit,a.ExchangeCount, COUNT(a.CouponsBarcode) AS NUM
						FROM #DocData a with(nolock)
					WHERE ExchangeMode='按商品'
					GROUP BY  a.seriescode,a.refrowid,Matcode,a.matname,CouponsCode,CouponsName,a.digit,a.ExchangeCount
					)
					SELECT @tips=@tips+'['+couponsName+']抵扣商品['+a.matname+']时仅能使用'+convert(varchar(20),a.ExchangeCount*a.digit)+'张,目前已使用'+convert(varchar(20),a.num)+'张,'+ dbo.crlf() 
					FROM cte a
					WHERE a.num>a.ExchangeCount*a.digit
					IF @@ROWCOUNT>0
						BEGIN
							RAISERROR(@tips,16,1)
							return
						END
		END
		/***********************************************************************优惠券金额控制*****************************************************************/
		--判断一种优惠券,在一个商品上,是否超过金额限制
		--统计每个商品在每个优惠券上的抵扣金额
		--用于对"按单据"兑换类优惠券的金额控制.
		IF EXISTS(SELECT 1 FROM #DocData a WHERE ExchangeMode='按单据' AND ISNULL(a.ExchangeMoney,0)>0)
			BEGIN
				SELECT @tips='以下优惠券超过优惠金额限制.'+dbo.clrlf()
				;WITH cte AS(
					SELECT couponcode,SUM(ISNULL(a.deductAmount,0)) AS num,a.ExchangeMoney, a.CouponsName
					FROM #DocData a
					WHERE  a.ExchangeMode='2'
					GROUP BY couponcode,ExchangeCount,CouponsName
					)
				SELECT @tips+'['+a.CouponsName+']每单仅能优惠'+convert(varchar(10),a.ExchangeMoney)+'元,本单已优惠'+convert(varchar(10),a.num)+'元.'+dbo.crlf()
				FROM cte a
				WHERE isnull(a.num,0)>isnull(a.ExchangeMoney,0)
				AND ISNULL(a.ExchangeMoney,0)>0								--只处理优惠券可抵扣金额大于0的
				IF @@ROWCOUNT>0
					BEGIN
						RAISERROR(@tips,16,1)
						RETURN
					END
			END
		--按商品兑换的优惠券,每张只能用于一个商品
		--需要检查每个商品使用的优惠券,是否超过优惠设置的最大优惠金额
		--用于检查"按商品"兑换的优惠券优惠金额控制
		IF EXISTS(SELECT 1 FROM #DocData WHERE ExchangeMode='按商品')
			BEGIN
					--判断按商品兑换的优惠券,是否超过优惠金额限制
					SELECT @tips='以下优惠超过优惠金额限制.'+dbo.crlf()
					;WITH cte AS(
						SELECT a.seriescode,a.Matcode,a.matname,couponscode,CouponsName,SUM(ISNULL(a.deductAmount,0)) AS num ,a.ExchangeMoney ,a.digit
						FROM #DocData a  
						WHERE ExchangeMode='按商品'
						GROUP BY a.seriescode,Matcode,a.matname,CouponsCode,CouponsName,a.ExchangeMoney,a.digit
						)
						SELECT @tips=@tips+'['+couponsName+']抵扣商品['+a.matname+']时仅能优惠'+convert(varchar(20),isnull(a.ExchangeMoney,0))+'元,目前已使用'+convert(varchar(20),a.num)+'元,'+ dbo.crlf() 
						FROM cte a
						WHERE   isnull(a.num,0)>isnull(a.ExchangeMoney,0)*a.digit
						AND ISNULL(a.ExchangeMoney,0)>0									--只处理优惠券可抵扣金额大于0的
						IF @@ROWCOUNT>0
							BEGIN
								RAISERROR(@tips,16,1)
								return
							END
			END
		/**********************************************************优惠券兑换规则控制*************************************************************/
		--执行赠送规则判断
		SELECT @tips ='以下优惠券不符合兑换规则,请仔细查看优惠券使用手册!'+dbo.crlf()
		SELECT @tips=@tips+a.couponsName+'['+a.couponsbarcode+']'+dbo.crlf()
		FROM #DocData a
		where NOT EXISTS(SELECT 1 FROM   Strategy_Coupons sc   
						WHERE a.CouponsCode=sc.CouponsCode 
						AND sc.Straytegygroup='02.01.02'
						AND (ISNULL(sc.Matcode,'')='' OR sc.Matcode=a.Matcode)
						AND (ISNULL(sc.Matgroup,'')='' OR a.MatgroupPath LIKE '%/'+sc.Matgroup+'/%')
						AND (ISNULL(sc.SdorgID,'')='' OR a.SdorgPath LIKE '%/'+sc.SdorgID+'/%')
						AND (ISNULL(sc.AreaID,'')='' OR EXISTS(SELECT 1 FROM commondb.dbo.[SPLIT](ISNULL(sc.AreaID,''),',') s WHERE a.AreaPath LIKE '%/'+s.List+'/%'))
						AND convert(bit,dbo.ExecuteScalar(0, commondb.dbo.REGEXP_Replace(ISNULL(NULLIF(sc.Filter,''),'1'),  '(?:^|\b)(?<!&|''|#)((\d:)?[\u4e00-\u9fa5]+)(?!&|''|#)(?:$|\b)','#$1#')
						,'Select * From #DocData','CouponsBarcode='''+a.CouponsBarcode+'''',-1,
						'Select * From fn_getFormulaFields('''+CONVERT(VARCHAR(20),@formid)+CASE WHEN ISNULL(@refFormid,'')!='' THEN ','+CONVERT(VARCHAR(20),@refFormid) ELSE '' END +''')',0))=1
			)
		AND EXISTS(SELECT 1 FROM   Strategy_Coupons sc   
						WHERE a.CouponsCode=sc.CouponsCode 
						AND sc.Straytegygroup='02.01.02')
		IF @@ROWCOUNT>0
			BEGIN
				RAISERROR(@tips,16,1)
				return
			END
	END