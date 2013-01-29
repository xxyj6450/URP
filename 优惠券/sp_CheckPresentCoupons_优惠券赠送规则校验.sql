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
	@RefFormID int,
	@OptionID varchar(200)='',
	@Usercode varchar(50)=''
as
	BEGIN
		set NOCOUNT on;
		declare @tips varchar(max)
		--业务数据校验
		if object_id('tempdb.dbo.#Docdata') is NULL
			BEGIN
				raiserror('业务数据不存在，无法校验优惠券.',16,1)
				return
			END
		--从优惠券表更新优惠券信息
		UPDATE a
			SET a.[STATE]=ic.[State],
			[OWNER] = ic.CouponsOWNER,
			CouponsAuthKey=ic.AuthKey
		FROM #DocData a,iCoupons ic WITH(NOLOCK)
		WHERE a.CouponsBarcode=ic.CouponsBarcode
		--来源方式为○1，○3，○5需要赠送,检查优惠券状态
		SELECT @tips='以下优惠券不在可赠送状态,无法使用!'+dbo.crlf()
		SELECT @tips=@tips+a.CouponsName+'['+a.CouponsBarcode+']'+dbo.crlf()
		FROM #DocData a  with(nolock)
		WHERE a.SourceMode IN(1,2)
		AND a.[STATE]!='在库'
		IF @@ROWCOUNT>0
			BEGIN
				drop TABLE #DocData
				RAISERROR(@tips,16,1)
				return
			END
		--检查赠送条件
		SELECT @tips='以下优惠券只允许"一单一券"方式赠送,优惠券数量超过限制.'+dbo.crlf()
		;WITH cte AS(
			SELECT couponscode,CouponsName
				FROM #DocData   with(nolock)
			WHERE PresentMode='2'
			GROUP BY CouponsCode,CouponsName 
				HAVING COUNT(CouponsBarcode)>1)
			SELECT @tips=@tips+couponsName FROM cte
			IF @@ROWCOUNT>0
				BEGIN
					RAISERROR(@tips,16,1)
					return
				END
	--检查兑换条件
	SELECT @tips='以下优惠券必须要有相关业务单据方可使用.'+dbo.crlf()
	;WITH cte AS(
		SELECT couponscode,CouponsName
			FROM #DocData   with(nolock)
		WHERE ExchangeMode IN('2','3')
		AND ISNULL(Refcode,'')='')
		SELECT @tips=@tips+couponsName FROM cte
		IF @@ROWCOUNT>0
			BEGIN
				RAISERROR(@tips,16,1)
				return
			END
		SELECT @tips='以下优惠券只允许"一商品一券"方式赠送.'+dbo.crlf()
		;WITH cte AS(
			SELECT couponscode,CouponsName,Matcode
				FROM #DocData   with(nolock)
			WHERE PresentMode='3'
			GROUP BY CouponsCode,CouponsName,Matcode
				HAVING COUNT(CouponsBarcode)>1)
			SELECT @tips=@tips+couponsName+dbo.crlf() FROM cte
			IF @@ROWCOUNT>0
				BEGIN
					RAISERROR(@tips,16,1)
					return
				END
		--处理中文
		update #DocData
		set PresentCount= commondb.dbo.REGEXP_Replace(PresentCount, '(?:^|\b)(?<!&|''|#)((\d:)?[\u4e00-\u9fa5]+)(?!&|''|#)(?:$|\b)','#$1#'),
		PresentMoney=commondb.dbo.REGEXP_Replace(PresentMoney,  '(?:^|\b)(?<!&|''|#)((\d:)?[\u4e00-\u9fa5]+)(?!&|''|#)(?:$|\b)','#$1#')
		where ISNULL(PresentMoney,'')!='' OR ISNULL(PresentCount,'')!=''
		--执行判断
		SELECT @tips ='以下优惠券不符合赠送数量或金额规则,请仔细查看优惠券使用手册!'+dbo.crlf()
		SELECT  @tips=@tips+couponsName+'['+couponsbarcode+']'+dbo.crlf() 
		FROM #DocData a OUTER APPLY dbo.ExecuteTable(0, ISNULL(a.PresentCount,'1')+';'+ISNULL(a.PresentMoney,'1') ,
		'Select * From #DocData','CouponsBarcode='''+a.CouponsBarcode+'''',-1,
		'Select * From fn_getFormulaFields(''9146,'+CONVERT(VARCHAR(20),@formid)+CASE WHEN ISNULL(@refFormid,'')!='' THEN ','+CONVERT(VARCHAR(20),@refFormid) ELSE '' END +''')',0) b
					WHERE CONVERT(BIT,b.data1)=0 OR CONVERT(BIT,b.data2)=0
		IF @@ROWCOUNT>0
			BEGIN

				RAISERROR(@tips,16,1)
				return
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