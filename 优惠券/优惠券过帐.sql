/*
begin tran
select * from icoupons where couponsbarcode='66911050004851'
select deductamout,CouponsBarcode from spickorderhd where doccode='RE20110502000001'
update icoupons set state='在库' where couponsbarcode='66911050004851'
update coupons_h set docstatus=0 where refcode='RE2王
begin tran
exec [sp_PostCouponsDoc] 'system','system',9146,'PS20120930006041'
 rollback
begin tran
EXEC sp_RequestCheckDoc 9146,'PS20121001001741','system','system','18681043288','',''

declare @linkdocinfo varchar(50)
exec sp_CreateCouponsDoc 9146,'PS20120930006041',9201,1,@linkdocinfo output
print @linkdocinfo
begin tran
exec [sp_postcouponsdoc ] 'system','system',2419,'RE20110711000066',1
select * from coupons_H where refcode='RW20110509000021'
commit
rollback

select couponsbarcode, * from unicom_orderdetails where doccode='PS20120930006041'
select * from icoupons where couponsbarcode='66912030027277'

begin tran
update icoupons
	set state='已赠'
where couponsbarcode='WS00024345'
*/

alter PROC [dbo].[sp_PostCouponsDoc]
	@userCode VARCHAR(20),
	@userName VARCHAR(40),
	@formid INT,
	@doccode VARCHAR(20),
	@optionID VARCHAR(500)='0'						--为0时表示正常执行,为Check时表示只执行判断,而不执行更新,所有的更新都被清除
AS
	BEGIN
		SET NOCOUNT ON;
		--SET XACT_ABORT ON;
		DECLARE @refFormid INT,@refcode VARCHAR(20),@deductAmout money,@LinkDocInfo varchar(50),@linkDoc varchar(20),  @tips varchar(5000),	@msg VARCHAR(500)
		DECLARE @TranCount INT,@DocStatus INT
		DECLARE @SourceMode VARCHAR(20),					--来源模式
				@CodeMode VARCHAR(20),						--编码模式
				@CodeLength INT,							--编码长度
				@PresentCount VARCHAR(20),					--赠送数量表达式
				@PresentMode VARCHAR(500),					--赠送数量模式
				@PresentMoney VARCHAR(500),					--赠送金额表达式
				@ExchangeCount VARCHAR(20),					--兑换数量表达式
				@ExchangeMode VARCHAR(500),					--兑换数量模式
				@ExchangeMoney VARCHAR(500),				--兑换金额表达式
				@Stcode VARCHAR(50),
				@SdorgID VARCHAR(50),
				@sql VARCHAR(8000)
		DECLARE @table TABLE(
			Doccode VARCHAR(20),
			FormID INT,
			UserCode VARCHAR(20),
			UserName VARCHAR(50),
			Remark VARCHAR(200))
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
					BeginDate DATETIME,
					EndDate DATETIME,
					Valid BIT,
					Price VARCHAR(500),
					Matcode VARCHAR(50),
					Matgroup VARCHAR(50),
					MatType VARCHAR(50),
					MatgroupPath VARCHAR(500),
					salePrice MONEY,
					totalMoney MONEY,
					digit INT,
					deductAmount MONEY)
		--优惠券入库
		IF @formid IN(9199)
			BEGIN
				INSERT INTO iCoupons ( CouponsBarcode, CouponsCode, stCode, 
				       [State], InDoccode, InDate, InStcode, InStName, Price, 
				       valid, Remark, ValidDate )
				SELECT b.CouponsBarCode, b.CouponsCode, a.Stcode, '在库', a.doccode, 
				       a.docdate, a.stcode, a.stname, price, 1, b.remark, b.validdate
				FROM   Coupons_H a  with(nolock), Coupons_D b with(nolock)
				WHERE  a.Doccode = b.Doccode
				       AND a.Doccode=@doccode
				return
			END
		--优惠券调配
		IF @formid IN(9200)
			BEGIN
				DECLARE  @stcode1 VARCHAR(50)
				SELECT @stcode=stcode,@stcode1=stcode1 FROM Coupons_H ch  with(nolock) WHERE ch.Doccode=@doccode
				UPDATE icoupons SET stCode = @stcode1 FROM iCoupons a  with(nolock),coupons_d b  with(nolock) WHERE a.CouponsBarcode=b.CouponsBarCode AND b.Doccode=@doccode
				return
			END
 
		--优惠券赠送
		IF @formid IN(9201)
			BEGIN
				SELECT @refFormid=refformid,@refcode=refcode,@Stcode=ch.Stcode
				  FROM Coupons_H ch  with(nolock) WHERE ch.Doccode=@doccode
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
						     BeginDate,   EndDate,   Valid,   Price,   Matcode,   
						     Matgroup,   MatType,   MatgroupPath,   salePrice,   
						     totalMoney,   digit,   deductAmount )
						      
						select ch.Doccode,ch.docdate,ch.FormID,vso.DocType,vso.FormID,vso.DocCode,vso.PackageID,NULL AS combocode,
						o2.SDOrgID,o2.dptType, o2.[PATH],g.areaid,g.[PATH],o.stCode,o.PlantID,ch.cltCode,
						cd.CouponsBarCode,i.[State],i.CouponsCode,cd.CouponsName, ig.GroupCode,ig.CodeMode,ig.CodeLength,
						ig.SourceMode,ig.PresentMode,ig.PresentCount,ig.PresentMoney,ig.ExchangeMode,ig.ExchangeCount,ig.ExchangeMoney,
						ig.ForceCheckStock,ig.BeginDate,ig.EndDate,ig.Valid,ig.price,
						s.MatCode,ig2.MatGroup,ig2.mattype,ig3.[PATH],s.price,s.totalmoney,s.Digit,cd.DeductAmout
						FROM Coupons_H ch  with(nolock) INNER JOIN oStorage o  with(nolock) ON ch.Stcode=o.stCode
						INNER JOIN oSDOrg o2  with(nolock) ON o.sdorgid=o2.SDOrgID
						INNER JOIN gArea g  with(nolock) ON o2.AreaID=g.areaid
						INNER JOIN Coupons_D cd  with(nolock) ON ch.Doccode=cd.Doccode
						inner JOIN iCouponsGeneral ig  with(nolock) ON cd.CouponsCode=ig.CouponsCode
						left JOIN iCoupons i  with(nolock) ON cd.CouponsBarCode=i.CouponsBarcode						--优惠券不一定存在,此处要用Left Join 
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
						     BeginDate,   EndDate,   Valid,   Price,   Matcode,   
						     Matgroup,   MatType,   MatgroupPath,   salePrice,   
						     totalMoney,   digit,   deductAmount )
						select ch.Doccode,ch.docdate,ch.FormID,vso.DocType,vso.FormID,vso.DocCode,vso.PackageID,vso.ComboCode AS combocode,
						o2.SDOrgID,o2.dptType, o2.[PATH],g.areaid,g.[PATH],o.stCode,o.PlantID,ch.cltCode,
						cd.CouponsBarCode,i.[State],i.CouponsCode,cd.CouponsName,ig.GroupCode,ig.CodeMode,ig.CodeLength,
						ig.SourceMode,ig.PresentMode,ig.PresentCount,ig.PresentMoney,ig.ExchangeMode,ig.ExchangeCount,ig.ExchangeMoney,
						ig.ForceCheckStock,ig.BeginDate,ig.EndDate,ig.Valid,ig.price,
						cd.MatCode,ig2.MatGroup,ig2.mattype,ig3.[PATH],cd.Amount,cd.Amount,cd.DeductAmout,cd.DeductAmout
						FROM Coupons_H ch  with(nolock) INNER JOIN oStorage o  with(nolock) ON ch.Stcode=o.stCode
						INNER JOIN oSDOrg o2  with(nolock) ON o.sdorgid=o2.SDOrgID
						INNER JOIN gArea g  with(nolock) ON o2.AreaID=g.areaid
						INNER JOIN Coupons_D cd  with(nolock) ON ch.Doccode=cd.Doccode
						INNER JOIN iCouponsGeneral ig  with(nolock) ON cd.CouponsCode=ig.CouponsCode
						left JOIN iCoupons i  with(nolock) ON cd.CouponsBarCode=i.CouponsBarcode						--优惠券不一定存在,此处要用Left Join 
						--不一定有关联单据,所以要用Left Join
						LEFT JOIN Unicom_Orders  vso  with(nolock) ON ch.RefCode=vso.DocCode 
						--LEFT JOIN Unicom_OrderDetails  s  with(nolock) ON vso.DocCode=s.DocCode AND  cd.RefRowID=s.rowid
						LEFT JOIN iMatGeneral ig2  with(nolock) ON cd.MatCode=ig2.MatCode
						LEFT JOIN iMatGroup ig3  with(nolock) ON ig2.MatGroup=ig3.matgroup
						WHERE ch.Doccode=@doccode
					END
				print '执行到了这里1'
				--来源方式为○1，○3，○5需要赠送,检查优惠券状态
				SELECT @tips='以下优惠券不在可赠送状态,无法使用!'+dbo.crlf()
				SELECT @tips=@tips+a.CouponsName+'['+a.CouponsBarcode+']'+dbo.crlf()
				FROM #DocData a  with(nolock)
				WHERE a.SourceMode IN(1,3,5)
				AND a.[STATE]!='在库'
				IF @@ROWCOUNT>0
					BEGIN
						drop TABLE #DocData
						RAISERROR(@tips,16,1)
						return
					END
				--检查赠送条件
				SELECT @tips='以下优惠券只允许"一单一券"方式兑换,优惠券数量超过限制.'+dbo.crlf()
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
				'Select * From fn_getFormulaFields('''+CONVERT(VARCHAR(20),@formid)+CASE WHEN ISNULL(@refFormid,'')!='' THEN ','+CONVERT(VARCHAR(20),@refFormid) ELSE '' END +''')',0) b
				          WHERE CONVERT(BIT,b.data1)=0 OR CONVERT(BIT,b.data2)=0
				IF @@ROWCOUNT>0
					BEGIN
						 
						RAISERROR(@tips,16,1)
						return
					END
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
				              AND (ISNULL(sc.AreaID,'')='' OR EXISTS(SELECT 1 FROM commondb.dbo.[SPLIT](ISNULL(sc.AreaID,''),'/') s WHERE a.AreaPath LIKE '%/'+s.List+'/%'))
				              AND convert(bit,dbo.ExecuteScalar(0,ISNULL(NULLIF(sc.Filter,''),'1'),'Select * From #DocData','CouponsBarcode='''+a.CouponsBarcode+'''',-1,
								'Select * From fn_getFormulaFields('''+CONVERT(VARCHAR(20),@formid)+CASE WHEN ISNULL(@refFormid,'')!='' THEN ','+CONVERT(VARCHAR(20),@refFormid) ELSE '' END +''')',0))=1
				)
				AND EXISTS(SELECT 1 FROM   Strategy_Coupons sc    with(nolock)
				              WHERE a.CouponsCode=sc.CouponsCode 
				              AND sc.Straytegygroup='02.01.01')
 
				IF @@ROWCOUNT>0
					BEGIN
						 select * 
						 FROM #DocData a
							where NOT EXISTS(SELECT 1 FROM   Strategy_Coupons sc  with(nolock)  
										  WHERE a.CouponsCode=sc.CouponsCode 
										  AND sc.Straytegygroup='02.01.01'
										  AND (ISNULL(sc.Matcode,'')='' OR sc.Matcode=a.Matcode)
										  AND (ISNULL(sc.Matgroup,'')='' OR a.MatgroupPath LIKE '%/'+sc.Matgroup+'/%')
										  AND (ISNULL(sc.SdorgID,'')='' OR a.SdorgPath LIKE '%/'+sc.SdorgID+'/%')
										  AND (ISNULL(sc.AreaID,'')='' OR EXISTS(SELECT 1 FROM commondb.dbo.[SPLIT](ISNULL(sc.AreaID,''),'/') s WHERE a.AreaPath LIKE '%/'+s.List+'/%'))
										  AND convert(bit,dbo.ExecuteScalar(0,ISNULL(NULLIF(sc.Filter,''),'1'),'Select * From #DocData','CouponsBarcode='''+a.CouponsBarcode+'''',-1,
											'Select * From fn_getFormulaFields('''+CONVERT(VARCHAR(20),@formid)+CASE WHEN ISNULL(@refFormid,'')!='' THEN ','+CONVERT(VARCHAR(20),@refFormid) ELSE '' END +''')',0))=1
							)
							AND EXISTS(SELECT 1 FROM   Strategy_Coupons sc    with(nolock)
										  WHERE a.CouponsCode=sc.CouponsCode 
										  AND sc.Straytegygroup='02.01.01')
						drop TABLE #DocData
						RAISERROR(@tips,16,1)
						return
					END
				--如果@optionID不为0,则不作更新
				IF ISNULL(@optionID,'') IN('check')  return
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
					iCoupons.PresentDate = GETDATE()
				FROM Coupons_H a  with(nolock),Coupons_D b  with(nolock),iCoupons ic  with(nolock)
				WHERE a.Doccode=b.Doccode
				AND b.CouponsBarCode=ic.CouponsBarcode
				AND a.Doccode=@doccode
				AND ic.[State]='在库'
				IF @@ROWCOUNT=0
					BEGIN
						drop TABLE #DocData
						select @tips='无法赠送此优惠券,因为此优惠券已赠出或不存在!'
						RAISERROR(@tips,16,1)
						return
					END
				return
			END
		--优惠券兑换
		IF @formid IN(9207)
			BEGIN
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
								 BeginDate,   EndDate,   Valid,   Price,   Matcode,   
								 Matgroup,   MatType,   MatgroupPath,   salePrice,   
								 totalMoney,   digit,   deductAmount )
								select ch.Doccode,ch.docdate,ch.FormID,vso.DocType,vso.FormID,vso.DocCode,vso.PackageID,NULL AS combocode,
								o2.SDOrgID,o2.dptType, o2.[PATH],g.areaid,g.[PATH],o.stCode,o.PlantID,ch.cltCode,
								cd.CouponsBarCode,i.[State],i.CouponsCode,cd.CouponsName, ig.GroupCode,ig.CodeMode,ig.CodeLength,
								ig.SourceMode,ig.PresentMode,ig.PresentCount,ig.PresentMoney,ig.ExchangeMode,ig.ExchangeCount,ig.ExchangeMoney,
								ig.ForceCheckStock,ig.BeginDate,ig.EndDate,ig.Valid,ig.price,
								s.MatCode,ig2.MatGroup,ig2.mattype,ig3.[PATH],s.price,s.totalmoney,s.Digit,cd.DeductAmout
								FROM Coupons_H ch   with(nolock) INNER JOIN oStorage o  with(nolock) ON ch.Stcode=o.stCode
								INNER JOIN oSDOrg o2  with(nolock) ON o.sdorgid=o2.SDOrgID
								INNER JOIN gArea g  with(nolock) ON o2.AreaID=g.areaid
								INNER JOIN Coupons_D cd  with(nolock) ON ch.Doccode=cd.Doccode
								inner JOIN iCouponsGeneral ig with(nolock)  ON cd.CouponsCode=ig.CouponsCode
								left JOIN iCoupons i  with(nolock) ON cd.CouponsBarCode=i.CouponsBarcode						--优惠券不一定存在,此处要用Left Join 
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
						     BeginDate,   EndDate,   Valid,   Price,   Matcode,   
						     Matgroup,   MatType,   MatgroupPath,   salePrice,   
						     totalMoney,   digit,   deductAmount )
						select ch.Doccode,ch.docdate,ch.FormID,vso.DocType,vso.FormID,vso.DocCode,vso.PackageID,vso.ComboCode AS combocode,
						o2.SDOrgID,o2.dptType, o2.[PATH],g.areaid,g.[PATH],o.stCode,o.PlantID,ch.cltCode,
						cd.CouponsBarCode,i.[State],i.CouponsCode,cd.CouponsName,ig.GroupCode,ig.CodeMode,ig.CodeLength,
						ig.SourceMode,ig.PresentMode,ig.PresentCount,ig.PresentMoney,ig.ExchangeMode,ig.ExchangeCount,ig.ExchangeMoney,
						ig.ForceCheckStock,ig.BeginDate,ig.EndDate,ig.Valid,ig.price,
						cd.MatCode,ig2.MatGroup,ig2.mattype,ig3.[PATH],cd.Amount,cd.Amount,cd.DeductAmout,cd.DeductAmout
						FROM Coupons_H ch  with(nolock) INNER JOIN oStorage o  with(nolock) ON ch.Stcode=o.stCode
						INNER JOIN oSDOrg o2  with(nolock) ON o.sdorgid=o2.SDOrgID
						INNER JOIN gArea g  with(nolock) ON o2.AreaID=g.areaid
						INNER JOIN Coupons_D cd  with(nolock) ON ch.Doccode=cd.Doccode
						INNER JOIN iCouponsGeneral ig  with(nolock) ON cd.CouponsCode=ig.CouponsCode
						left JOIN iCoupons i  with(nolock) ON cd.CouponsBarCode=i.CouponsBarcode						--优惠券不一定存在,此处要用Left Join 
						--不一定有关联单据,所以要用Left Join
						LEFT JOIN Unicom_Orders  vso  with(nolock) ON ch.RefCode=vso.DocCode 
						--LEFT JOIN Unicom_OrderDetails  s  with(nolock) ON vso.DocCode=s.DocCode AND  cd.RefRowID=s.rowid
						LEFT JOIN iMatGeneral ig2  with(nolock) ON cd.MatCode=ig2.MatCode
						LEFT JOIN iMatGroup ig3  with(nolock) ON ig2.MatGroup=ig3.matgroup
						WHERE ch.Doccode=@doccode
					END
				--来源方式为1时,需要为已赠送,而且在库
				SELECT @tips='以下优惠券未赠送,不允许兑换.'+dbo.crlf()
				SELECT @tips=@tips+a.CouponsName+'['+a.CouponsBarcode+']'+dbo.crlf()
				FROM #DocData a  with(nolock)
				WHERE a.SourceMode IN(1,2)
				AND isnull(a.[STATE],'')!='已赠'
				IF @@ROWCOUNT>0
					BEGIN
						RAISERROR(@tips,16,1)
						return
					END
				SELECT @tips='以下优惠券不在库,不允许使用'+dbo.crlf()
				SELECT @tips=@tips+a.CouponsName+'['+a.CouponsBarcode+']'+dbo.crlf()
				FROM #DocData a  with(nolock)
				WHERE a.SourceMode IN(1)
				AND isnull(a.stcode,'')!=@Stcode
				IF @@ROWCOUNT>0
					BEGIN
						RAISERROR(@tips,16,1)
						return
					END
				--优惠券类型为2,或为4且强制要求库存检查时,则要求优惠券必须在系统中有记录
				SELECT @tips='系统中不存在以下优惠券,不允许使用.'
				SELECT @tips=@tips+a.CouponsName+'['+a.CouponsBarcode+']'+dbo.crlf()
				FROM #DocData a  with(nolock)
				WHERE (a.SourceMode IN(2) OR (a.SourceMode=4 AND a.ForceCheckStock=1))
				AND a.stcode!=@Stcode
				IF @@ROWCOUNT>0
					BEGIN
						RAISERROR(@tips,16,1)
						return
					END
				--检查兑换条件
				SELECT @tips='以下优惠券只允许"一单一券"方式兑换,优惠券数量超过限制.'+dbo.crlf()
				;WITH cte AS(
					SELECT couponscode,CouponsName
					  FROM #DocData  with(nolock)
					WHERE ExchangeMode ='2'
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
					  FROM #DocData  with(nolock)
					WHERE ExchangeMode IN('2','3')
					AND ISNULL(Refcode,'')='')
					SELECT @tips=@tips+couponsName FROM cte
					IF @@ROWCOUNT>0
						BEGIN
							RAISERROR(@tips,16,1)
							return
						END
				SELECT @tips='以下优惠券只允许"一商品一券"方式兑换.'+dbo.crlf()
				;WITH cte AS(
					SELECT couponscode,CouponsName,Matcode
					  FROM #DocData  with(nolock)
					WHERE ExchangeMode='3'
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
				set PresentCount= commondb.dbo.REGEXP_Replace(isnull(PresentCount,''), '(?:^|\b)(?<!&|''|#)((\d:)?[\u4e00-\u9fa5]+)(?!&|''|#)(?:$|\b)','#$1#'),
				PresentMoney=commondb.dbo.REGEXP_Replace(isnull(PresentMoney,''),  '(?:^|\b)(?<!&|''|#)((\d:)?[\u4e00-\u9fa5]+)(?!&|''|#)(?:$|\b)','#$1#'),
				Price=commondb.dbo.REGEXP_Replace(isnull(Price,''),  '(?:^|\b)(?<!&|''|#)((\d:)?[\u4e00-\u9fa5]+)(?!&|''|#)(?:$|\b)','#$1#')
				where ISNULL(PresentMoney,'')!='' OR ISNULL(PresentCount,'')!='' OR ISNULL(Price,'')!=''
				--执行判断
				SELECT @tips ='以下优惠券不符合兑换规则,请仔细查看优惠券使用手册!'+dbo.crlf()
				SELECT  @tips=@tips+couponsName+'['+couponsbarcode+']'+dbo.crlf() 
				FROM #DocData a OUTER APPLY dbo.ExecuteTable(0,ISNULL(a.ExchangeCount,'1')+';'+ISNULL(a.ExchangeMoney,'1'),
				'Select * From #DocData','CouponsBarcode='''+a.CouponsBarcode+'''',-1,
				'Select * From fn_getFormulaFields('''+CONVERT(VARCHAR(20),@formid)+CASE WHEN ISNULL(@refFormid,'')!='' THEN ','+CONVERT(VARCHAR(20),@refFormid) ELSE '' END +''')',0) b
				          WHERE CONVERT(BIT,b.data1)=0 OR CONVERT(BIT,b.data2)=0
 
				IF @@ROWCOUNT>0
					BEGIN
						RAISERROR(@tips,16,1)
						return
					END
				SELECT @tips='以下优惠券抵扣金额超过其面额,不允许继续操作.'+dbo.crlf()
				SELECT @tips=@tips+a.CouponsName+'['+a.CouponsBarcode+']'+dbo.crlf()
				FROM #DocData a  with(nolock)
				WHERE ISNULL(a.deductAmount,0)>convert(money,dbo.ExecuteScalar(0,ISNULL(a.Price,'0'),'Select * From #DocData','CouponsBarcode='''+a.CouponsBarcode+'''',-1,
								'Select * From fn_getFormulaFields('''+CONVERT(VARCHAR(20),@formid)+CASE WHEN ISNULL(@refFormid,'')!='' THEN ','+CONVERT(VARCHAR(20),@refFormid) ELSE '' END +''')',0))
				IF @@ROWCOUNT>0
					BEGIN
						RAISERROR(@tips,16,1)
						return
					END
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
				              AND (ISNULL(sc.AreaID,'')='' OR EXISTS(SELECT 1 FROM commondb.dbo.[SPLIT](ISNULL(sc.AreaID,''),'/') s WHERE a.AreaPath LIKE '%/'+s.List+'/%'))
				              AND convert(bit,dbo.ExecuteScalar(0,ISNULL(sc.Filter,'1'),'Select * From #DocData','CouponsBarcode='''+a.CouponsBarcode+'''',-1,
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
				--如果@optionID不为0,则不作更新
				IF ISNULL(@optionID,'0')  IN('check') return
				UPDATE iCoupons
				SET
					[State] = '已兑换',
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
				AND c.[State]='已赠'
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
		--优惠券退货
		IF @formid IN(9211)
			BEGIN
				DECLARE @Result VARCHAR(20) 
				--取退货原因
				SELECT @Result=prdno,@stcode=b.Stcode
				  FROM sPickorderHD a WITH(NOLOCK),Coupons_H b   with(nolock) WHERE a.DocCode=b.RefCode AND  b.DocCode=@doccode
				--修改优惠券状态
				--更新配件券状态
				UPDATE a 
					SET STATE=CASE @Result when  '退货' then '作废' when  '开错单冲红' then '在库' else a.state end,
					a.ReturnDoccode = @doccode,
					returndate=GETDATE(),
					a.ReturnFormID = 9211,
					a.ReturnStcode =@stcode
				FROM  iCoupons a   with(nolock),Coupons_D b   with(nolock)
				WHERE b.Doccode=@doccode
				AND b.couponsbarcode=a.CouponsBarcode
				AND a.state IN('已赠','已兑换')
				IF @@ROWCOUNT=0
					BEGIN
						RAISERROR('此优惠券不存在或未赠送,或已作废!',16,1)
						return
					END
			END
		--优惠券赠送
		if @formid IN(9102,9146,2419)
			BEGIN
				
				if @formid in(2419) 
						BEGIN
							--如果有引用功能号,即是从套包单或开户单而来,则不做赠送
							 if  not exists(select 1 from spickorderitem a WITH(NOLOCK),sPickorderHD b with(nolock) where  a.doccode=b.doccode and 
							 a.doccode=@doccode 
							 and isnull(couponsbarcode,'')<>'' AND isnull(b.refformid,0)=0 ) 
								BEGIN
									return
								END
							--若单据中有只有抵扣金额却没有优惠券的项,则将抵扣金额清空
							IF EXISTS(SELECT 1 FROM sPickorderitem s WITH(NOLOCK) WHERE s.DeductAmout!=0 AND ISNULL(s.CouponsBarCode,'')='')
								begin
									UPDATE sPickorderitem
										SET DeductAmout = NULL
									WHERE DocCode=@doccode
									AND ISNULL(CouponsBarCode,'')=''
								END
							
							--如果不存在优惠券,就不用往下执行了
							IF NOT EXISTS(SELECT 1 FROM sPickorderitem s WITH(NOLOCK) WHERE s.DocCode=@doccode AND ISNULL(s.CouponsBarCode,'')!='' AND s.DocCode=@doccode)
								BEGIN
									return
								END
							--检查是否支持即时抵扣,即时抵扣是指赠送和抵扣在同一张单据上.也就是尚未赠送,处于在库状态.
							SELECT @msg='以下优惠券不支持即时抵扣，请检查！'+dbo.crlf()
							SELECT @msg=@msg+ig.CouponsName+'['+s.CouponsBarCode+']'+dbo.crlf()
							  FROM iCoupons i   with(nolock) INNER JOIN sPickorderitem s WITH(NOLOCK) ON i.CouponsBarcode=s.CouponsBarCode
								INNER JOIN iCouponsGeneral ig   with(nolock) ON ig.CouponsCode=i.CouponsCode
							          WHERE ISNULL(ig.Immediate_Deduction,0)=0
							          AND s.DocCode=@doccode
							          AND i.[State]='在库'
							          AND ISNULL(s.DeductAmout,0)!=0				--当抵扣金额大于0时,认为是抵扣.若抵扣金额为0,则支持在销售单据上直接赠送.
							IF @@ROWCOUNT>0
							BEGIN
								 
								RAISERROR(@msg,16,1)
								return
							END
							
						end
				if @formid in(9102,9146)
					begin
						print '开始执行了.'
						if NOT  exists(select 1 from unicom_orderdetails a   with(nolock),unicom_orders b   with(nolock) WHERE a.doccode=b.doccode 
						and a.doccode=@doccode and (isnull(couponsbarcode,'')<>'' or isnull(b.matCouponsbarcode,'')<>'' ) )
							BEGIN
								return
							END
						print '检查即时抵扣.'
						--检查是否支持即时抵扣,即时抵扣是指赠送和抵扣在同一张单据上.也就是尚未赠送,处于在库状态.
						SELECT @msg='以下优惠券不支持即时抵扣，请检查！'+dbo.crlf()
						;with cte(CouponsBarcode,DeductAmout) AS (
							select uo.matCouponsbarcode,uo.matDeductAmount 
							from Unicom_Orders uo with(nolock)
							where uo.DocCode=@doccode
							union all
							select uod.CouponsBarCode,uod.DeductAmout 
							from Unicom_OrderDetails uod
							where uod.DocCode=@doccode
							)
						SELECT @msg=@msg+ig.CouponsName+'['+s.CouponsBarCode+']'+dbo.crlf()
						  FROM iCoupons i INNER JOIN cte s WITH(NOLOCK) ON i.CouponsBarcode=s.CouponsBarCode
							INNER JOIN iCouponsGeneral ig  with(nolock) ON ig.CouponsCode=i.CouponsCode
						          WHERE ISNULL(ig.Immediate_Deduction,0)=0
						          AND i.[State]='在库'
						          AND ISNULL(s.DeductAmout,0)!=0						--当抵扣金额大于0时,认为是抵扣.若抵扣金额为0,则支持在销售单据上直接赠送.
						IF @@ROWCOUNT>0
						BEGIN
							RAISERROR(@msg,16,1)
							return
						END
					END
				
				
				BEGIN TRY
					SELECT @TranCount=@@TRANCOUNT,@LinkDocInfo=NULL,@DocStatus=NULL
					--在check模式下,不启用事务,仅在check模式下启用
					IF @TranCount =0 AND @optionID NOT IN('check') BEGIN TRAN
					--查找是否已经存在赠送单
					print '检查赠送单.'
					SELECT @linkdoc=doccode,@DocStatus=ch.DocStatus
					  FROM Coupons_H ch   with(nolock) WHERE ch.RefCode=@doccode AND ch.FormID=9201
 
					
					--如果没有,生成赠送单
					IF @linkdoc is NULL
						begin
							begin try
								print '生成赠送单'
								exec sp_CreateCouponsDoc @formid,@doccode,9201,1,@linkdocinfo OUTPUT
								select @linkdoc=right(@linkdocinfo,16)
							end try
							begin catch
								select @msg='创建优惠券赠送单据失败.'+isnull(error_message(),'')
								raiserror(@msg,16,1)
								return
							end catch
							--print @linkdoc
							--赠送单过账
							--SELECT '赠送前',ic.* FROM Coupons_D cd,iCoupons ic  WHERE cd.Doccode=@linkdoc and cd.couponsbarcode=ic.couponsbarcode
							begin try
								exec [sp_PostCouponsDoc] 'system','system',9201,@linkdoc,@optionID
							end try
							begin catch
								select @msg='优惠券赠送单据过帐失败.'+isnull(error_message(),'')
								raiserror(@msg,16,1)
								return
							end catch
						END
					--如果有,而且单据状态为0,则过帐之
					ELSE IF @DocStatus=0
						begin
							begin try
								EXEC sp_PostCouponsDoc @userCode,@username,9201,@linkdoc,@optionID
							end try
							begin catch
								
								select @msg='优惠券赠送单据过帐失败.'+isnull(error_message(),'')
								raiserror(@msg,16,1)
								return
							end catch
						end
					--如果是校验模式,则将生成的单据删除,并直接返回,不再执行兑换.  2012-04-29 暂时不执行兑换验证,待模块完整之后再执行.
					IF ISNULL(@optionID,'')   IN('check')
						BEGIN
							DELETE FROM Coupons_D WHERE Doccode=@linkDoc
							DELETE FROM Coupons_H WHERE doccode=@linkDoc
							return
						END
						
					--SELECT '赠送后',ic.* FROM Coupons_D cd,iCoupons ic  WHERE cd.Doccode=@linkdoc and cd.couponsbarcode=ic.couponsbarcode
					--修改单据状态
					IF ISNULL(@optionID,'') NOT IN('check')
						begin
							UPDATE Coupons_H
								SET DocStatus = 1
							WHERE Doccode=@linkDoc
							AND FormID=9201
						end
					--对兑换单的处理与赠送单相同
					SELECT @linkDoc=NULL,@DocStatus=NULL
										SELECT @linkdoc=doccode,@DocStatus=ch.DocStatus
					  FROM Coupons_H ch   with(nolock) WHERE ch.RefCode=@doccode AND ch.FormID=9207
					  
					--生成兑换单
					IF @linkDoc IS NULL
						begin
							begin try
								exec sp_CreateCouponsDoc @formid,@doccode,9207,1,@linkdocinfo output
							end try
							begin catch
								select @msg='优惠券兑换单据生成失败.'+isnull(error_message(),'')
								raiserror(@msg,16,1)
								return
							end catch
							select @linkdoc=right(@linkdocinfo,16)
							--PRINT @linkdoc
							--兑换单过账
							begin try
								exec [sp_PostCouponsDoc] 'system','system',9207,@linkdoc,@optionID
							end try
							begin catch
								select @msg='优惠券兑换单据过帐失败.'+isnull(error_message(),'')
								raiserror(@msg,16,1)
								return
							end catch
						END
					ELSE IF @DocStatus=0
						BEGIN
							begin try
								exec [sp_PostCouponsDoc] 'system','system',9207,@linkdoc,@optionID
							end try
							begin catch
								select @msg='优惠券兑换单据过帐失败.'+isnull(error_message(),'')
								raiserror(@msg,16,1)
								return
							end catch
						END
						UPDATE Coupons_H
							SET DocStatus = 1
						WHERE Doccode=@linkDoc
						AND FormID=9207
					IF @TranCount=0 AND @optionID NOT IN('check') COMMIT
				END TRY
				BEGIN CATCH
					IF @TranCount=0 AND @optionID NOT IN('check') ROLLBACK
					SELECT @msg='在过程'+ERROR_PROCEDURE()+'发生异常!'+char(10)+'错误原因:'+ERROR_MESSAGE()+char(10)+'错误发生在'+convert(varchar(10),error_line())+'行处.'+char(10)+'请与系统管理员联系!'
					RAISERROR(@msg,16,1)
					return
				END catch
 
			END
		--优惠券退还
		if @formid IN(2420)
			BEGIN

				 if  not exists(select 1 from spickorderitem a WITH(NOLOCK),sPickorderHD b WITH(NOLOCK) where  a.doccode=b.doccode and 
				 a.doccode=@doccode 
				and isnull(couponsbarcode,'')<>'') 
					BEGIN
						return
					END
				BEGIN TRAN tranCreateDOC
				BEGIN TRY

					--生成退还单
					exec sp_CreateCouponsDoc @formid,@doccode,9211,1,@linkdocinfo output
					select @linkdoc=right(@linkdocinfo,16)
					--print @linkdoc
					--退还单过账
					exec [sp_PostCouponsDoc] 'system','system',9211,@linkdoc  
				END TRY
				BEGIN CATCH
					RAISERROR(@msg,16,1)
					--ROLLBACK tran tranCreateDOC
					--PRINT ERROR_MESSAGE()
					SELECT @msg=ERROR_MESSAGE()
					
					return
				END catch
				if @@trancount>0 COMMIT tran tranCreateDOC
			END
		--优惠券批发
		IF @formid IN(9218)
			BEGIN
				UPDATE iCoupons
				SET	[State] = '已赠',
					OutDate = GETDATE(),
					OutDoccode = a.doccode,
					OutStcode = a.stcode,
					OutStName = a.stname,
					OutFormID = a.formid,
					--PresentedMatcode = b.matcode,
					--PresentedMatName = b.matname,
					--PresentedSeriesCode = b.seriescode,
					--PresentedMoney = b.Amount,
					--presenteddigit=b.Digit,
					iCoupons.PresentDoccode = @doccode,
					iCoupons.PresentFormid = @formid,
					iCoupons.PresentStcode = a.Stcode,
					iCoupons.PresentDate = GETDATE(),
					remark=b.Remark 
				FROM Coupons_H a   with(nolock),Coupons_D b   with(nolock),iCoupons ic   with(nolock)
				WHERE a.Doccode=b.Doccode
				AND b.CouponsBarCode=ic.CouponsBarcode
				AND a.Doccode=@doccode
				AND ic.[State]='在库'
			END
		return
	END

