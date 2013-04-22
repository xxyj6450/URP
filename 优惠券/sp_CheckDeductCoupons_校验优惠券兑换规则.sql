/*
�������ƣ�sp_CheckDeductCoupons
����������У���Ż�ȯ�һ�����
������������;�����̵Ĳ����⣬����Ҫ����һ��#CouponsDocData����ʱ���ڴ���ʱ���д洢ҵ�����ݺ��Ż�ȯ���ݣ������̽����ݴ�����Դ����У�顣
����ֵ��
��д�����ϵ�
��ע��
#CouponsDocData�ɰ�����ҵ�������ֵ��һ������������
*/
alter proc sp_CheckDeductCoupons
	@FormID int,
	@Doccode varchar(50),
	@RefFormID int=0,
	@Refcode varchar(20)='',
	@Stcode varchar(50)='',
	@CustomerCode varchar(50)='',
	@PackageID varchar(50)='',
	@ComboCode int=0,
	@OptionID varchar(200)='',					--������ֵΪ#PreCheck#����������Ż�ȯ״̬����Ϊ�ڿ��������
	@Usercode varchar(50)=''
as
	BEGIN
		set NOCOUNT on;
		declare @tips varchar(max)
		--��δ��������Դ�����Լ���֯
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
					BeginDate DATETIME,								--�Ż�ȯ���ϱ��е���ʼ��Ч��
					EndDate DATETIME,									--�Ż�ȯ���ϱ��е���ֹ��Ч��
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
					CouponsAuthKey	VARCHAR(50)	,				--�Ż�ȯ���е�У������
					Occupyed bit,
					OccupyedDoccode varchar(50)
				)
				--�����������ݷ�����ʱ��
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
						ig.ForceCheckStock,ig.BeginDate,ig.EndDate,ig.Valid,ig.price,	s.MatCode,s.MatName,ig2.MatGroup,ig2.mattype,ig3.[PATH],
						s.price,s.totalmoney,s.Digit,s.DeductAmout,ig.CouponsOwner,ig.canOverlay,s.RowID,
						newid() RefRowID,s.SeriesCode,i.beginValidDate,i.ValidDate,	i.CouponsOWNER,i.authKey,i.Occupyed,i.OccupyedDoccode
						FROM  sPickorderitem s with(nolock) INNER JOIN oStorage o  with(nolock) ON o.stCode=@Stcode
						INNER JOIN oSDOrg o2  with(nolock) ON o.sdorgid=o2.SDOrgID
						INNER JOIN gArea g  with(nolock) ON o2.AreaID=g.areaid
						left JOIN iCoupons i  with(nolock) ON s.CouponsBarCode=i.CouponsBarcode						--�Ż�ȯ��һ������,�˴�Ҫ��Left Join 
						left JOIN iCouponsGeneral ig  with(nolock) ON i.CouponsCode=ig.CouponsCode
						left JOIN iMatGeneral ig2  with(nolock) ON s.MatCode=ig2.MatCode
						left JOIN iMatGroup ig3  with(nolock) ON ig2.MatGroup=ig3.matgroup
						WHERE s.Doccode=@doccode
					end
				if @FormID in(9207)
					BEGIN
						--�����������ݷ�����ʱ��
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
								cd.Amount,cd.Amount,cd.DeductAmout,cd.DeductAmout,cd.RowID,cd.RefRowID,
								cd.SeriesCode,i.CouponsOWNER,i.authkey ,i.Occupyed,i.OccupyedDoccode
								FROM Coupons_H ch  with(nolock) INNER JOIN oStorage o  with(nolock) ON ch.Stcode=o.stCode
								INNER JOIN oSDOrg o2  with(nolock) ON o.sdorgid=o2.SDOrgID
								INNER JOIN gArea g  with(nolock) ON o2.AreaID=g.areaid
								INNER JOIN Coupons_D cd  with(nolock) ON ch.Doccode=cd.Doccode
								INNER JOIN iCouponsGeneral ig  with(nolock) ON cd.CouponsCode=ig.CouponsCode
								left JOIN iCoupons i  with(nolock) ON cd.CouponsBarCode=i.CouponsBarcode						--�Ż�ȯ��һ������,�˴�Ҫ��Left Join 
								LEFT JOIN iMatGeneral ig2  with(nolock) ON cd.MatCode=ig2.MatCode
								LEFT JOIN iMatGroup ig3  with(nolock) ON ig2.MatGroup=ig3.matgroup
								WHERE ch.Doccode=@doccode
					END
				
				if @FormID in(9146,9102,9237)
					BEGIN
						--������׼������ʱ��
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
								totalMoney,   digit,   deductAmount,CouponsOwner,canOverlay,RowID,RefRowID,Seriescode,
								beginValidDate,endValidDate,OWNER,CouponsAuthKey,Occupyed,OccupyedDoccode  )

						select @Doccode,getdate(),@FormID,NULL as DocType,NULL,NULL,@PackageID,@Combocode AS combocode,
						o2.SDOrgID,o2.dptType, o2.[PATH],g.areaid,g.[PATH],o.stCode,o.PlantID,@Customercode,
						s.CouponsBarCode,i.state [State],ig.CouponsCode,ig.CouponsName, ig.GroupCode,ig.CodeMode,ig.CodeLength,
						ig.SourceMode,ig.PresentMode,ig.PresentCount,ig.PresentMoney,PresentFormGroup,ig.ExchangeMode,ig.ExchangeCount,ig.ExchangeMoney,ig.FormGroup,
						ig.ForceCheckStock,ig.BeginDate,ig.EndDate,ig.Valid,ig.price,	s.MatCode,s.MatName,ig2.MatGroup,ig2.mattype,ig3.[PATH],
						s.price,s.totalmoney,s.Digit,s.DeductAmout,ig.CouponsOwner,ig.canOverlay,s.RowID,
						newid() RefRowID,s.SeriesCode,i.beginValidDate,i.ValidDate,i.CouponsOWNER,i.authKey,i.Occupyed,i.OccupyedDoccode
						FROM cte_unicom_orderdetails  s  with(nolock) INNER JOIN oStorage o  with(nolock) ON o.stCode=@Stcode
						INNER JOIN oSDOrg o2  with(nolock) ON o.sdorgid=o2.SDOrgID
						INNER JOIN gArea g  with(nolock) ON o2.AreaID=g.areaid
						left JOIN iCoupons i  with(nolock) ON s.CouponsBarCode=i.CouponsBarcode						--�Ż�ȯ��һ������,�˴�Ҫ��Left Join 
						left JOIN iCouponsGeneral ig  with(nolock) ON i.CouponsCode=ig.CouponsCode
						left JOIN iMatGeneral ig2  with(nolock) ON s.MatCode=ig2.MatCode
						left JOIN iMatGroup ig3  with(nolock) ON ig2.MatGroup=ig3.matgroup
						WHERE s.Doccode=@doccode
					END
 				--����ָ���Ĺ��ܺ�,����������Ϣ
				IF @refFormid IN(9102,9146,9237) or @FormID IN(9102,9146,9237)
					BEGIN
						update a
							set a.PackageType=isnull(b.DocType,'')
						From #CouponsDocData a left join policy_h b WITH(NOLOCK) on a.packageid=b.doccode
						update a
							set a.ComboPrice=ch.Price
						from #CouponsDocData a left join Combo_H ch with(nolock) on a.ComboCode=ch.ComboCode
					END
 
				--��������
				update #CouponsDocData
				set ExchangeCount= commondb.dbo.REGEXP_Replace(isnull(ExchangeCount,''), '(?:^|\b)(?<!&|''|#)((\d:)?[\u4e00-\u9fa5]+)(?!&|''|#)(?:$|\b)','#$1#'),
				ExchangeMoney=commondb.dbo.REGEXP_Replace(isnull(ExchangeMoney,''),  '(?:^|\b)(?<!&|''|#)((\d:)?[\u4e00-\u9fa5]+)(?!&|''|#)(?:$|\b)','#$1#'),
				Price=commondb.dbo.REGEXP_Replace(isnull(Price,''),  '(?:^|\b)(?<!&|''|#)((\d:)?[\u4e00-\u9fa5]+)(?!&|''|#)(?:$|\b)','#$1#')
				where ISNULL(ExchangeCount,'')!='' OR ISNULL(ExchangeMoney,'')!='' OR ISNULL(Price,'')!=''
 
				--���ݱ��ʽ����ɶһ������ͽ��.���ֿ������͵ֿ۶�ȱ����Ѿ�������,�Ͳ���ִ�и�����.���򰴱��ʽ����.
				IF not  EXISTS (SELECT 1 FROM #CouponsDocData a WHERE ISNUMERIC(ISNULL(a.ExchangeCount,'1'))=1 AND ISNUMERIC(ISNULL(a.ExchangeMoney,'0'))=1 )
					BEGIN
						--print 'Select * From fn_getFormulaFields('''+CONVERT(VARCHAR(20),@formid)+CASE WHEN ISNULL(@refFormid,'')!='' THEN ','+CONVERT(VARCHAR(20),@refFormid) ELSE '' END +''')'
						UPDATE  a
						SET a.ExchangeCount=convert(money,b.data1),
						a.ExchangeMoney=CONVERT(MONEY,b.data2)
						FROM #CouponsDocData a OUTER APPLY dbo.ExecuteTable(0,ISNULL(a.ExchangeCount,'1')+';'+ISNULL(a.ExchangeMoney,'0'),
						'Select * From #CouponsDocData','CouponsBarcode='''+a.CouponsBarcode+'''',-1,
						'Select * From fn_getFormulaFields('''+CONVERT(VARCHAR(20),@formid)+CASE WHEN ISNULL(@refFormid,'')!='' THEN ','+CONVERT(VARCHAR(20),@refFormid) ELSE '' END +''')',0) b
					END
				
			END
		--select * from #CouponsDocData a
		--ҵ������У��
		if object_id('tempdb.dbo.#CouponsDocData') is NULL
			BEGIN
				print 'ҵ�����ݲ����ڣ��޷�У���Ż�ȯ.'
				return -1
			END
		
		--��Դ��ʽΪ��1����3����5��Ҫ����,����Ż�ȯ״̬
		SELECT @tips='' 
		if @OptionID='#Precheck#'
			BEGIN
				SELECT @tips=@tips+isnull(a.CouponsName,'')+'['+a.CouponsBarcode+']'+'��ǰ״̬Ϊ['+ISNULL(a.state,'������')+'],�޷��һ���'+char(10)
				FROM #CouponsDocData a  with(nolock)
				WHERE isnull(a.SourceMode,1) IN(1,2)
				AND isnull(a.[STATE],'') not in('����','�ڿ�')
				IF @@ROWCOUNT>0
					BEGIN
						drop TABLE #CouponsDocData
						RAISERROR(@tips,16,1)
						return
					END
			END
		else
			BEGIN
				SELECT @tips=@tips+isnull(a.CouponsName,'')+'['+a.CouponsBarcode+']'+'��ǰ״̬Ϊ['+ISNULL(a.state,'������')+'],�޷��һ���'+char(10)
				FROM #CouponsDocData a  with(nolock)
				WHERE isnull(a.SourceMode,1) IN(1,2)
				AND isnull(a.[STATE],'')!='����'
				IF @@ROWCOUNT>0
					BEGIN
						drop TABLE #CouponsDocData
						RAISERROR(@tips,16,1)
						return
					END
			END
		select @tips=''
		select @tips=@tips+i.couponsname+'['+i.couponsbarcode+']�ѱ�����['+isnull(i.OccupyedDoccode,'')+']ռ�ã���ֹ�ظ�ʹ��.'
		from #CouponsDocData i
		where i.Occupyed=1
		if @@ROWCOUNT>0
			BEGIN
				raiserror(@tips,16,1)
				return
			END
		--����Ʒ�һ����Ż�ȯ,������Դ������Ʒ��Ϣ,��ֹ����һ��Ż�ȯ
		/*select @tips=''
		select @tips=@tips+'��Ʒ['+matname+']��Դ�������Ѳ�����,��������ʹ���Ż�ȯ['+couponsbarcode+'].'+dbo.crlf()
		From #CouponsDocData a
		where a.ExchangeMode='����Ʒ'
		and (isnull(a.RefRowID,'')='' or isnull(a.Matcode,'')='')
		if @@ROWCOUNT>0
			BEGIN
				raiserror(@tips,16,1)
				return
			END*/
	--����Ż�ȯ�Ƿ�������
	select @tips=''
	select @tips=@tips+a.CouponsName+'['+a.CouponsBarcode+']δ���ã���ֹʹ�á�'+char(10)
	from #CouponsDocData a
	where isnull(Valid,0)=0
	if @@ROWCOUNT>0
		BEGIN
			raiserror(@tips,16,1)
			return
		END
	--��Ч�ڿ���
	SELECT @tips='�����Ż�ȯ�ѹ���Ч��.'+dbo.crlf()
	SELECT @tips=@tips+a.CouponsBarcode+'['+a.CouponsName+']'+dbo.crlf()
	FROM #CouponsDocData a
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
	--�ж��Ż�ȯ�Ƿ������ָ������
		select @tips=''
		select @tips=@tips+a.couponsname+'['+a.couponsbarcode+']�������ڱ�ҵ��.'+char(10)
		from #CouponsDocData a where isnull(nullif(ltrim(rtrim(a.ExchangeFormGroup)),''),'9207')!='9207'												--��δ���ÿ����͹��ܺţ�������Ϊ9201���κ�ҵ�����
		and  a.formid not in( select list from commondb.dbo.SPLIT(isnull(a.ExchangeFormGroup,'9207'),',') )	
		and (isnull(a.RefFormID,0)=0 or a.refformid not in( select list from commondb.dbo.SPLIT(isnull(a.ExchangeFormGroup,'9207'),',')))
		if @@ROWCOUNT>0
			BEGIN
				raiserror(@tips,16,1)
				return
			END
	--�ж��Ƿ����һ���Ż�ȯ��ͬһ�ŵ���ʹ�ö��
	SELECT @tips='�����Ż�ȯֻ��ʹ��һ��.'+dbo.crlf()
	;WITH cte AS(
		SELECT a.CouponsBarcode,a.CouponsName,COUNT(a.CouponsBarcode) AS num
		FROM #CouponsDocData a
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
	--�ж��Ƿ��в��������ʹ�õ��Ż�ȯ
	SELECT @tips='�����Ż�ȯ�������������Ż�ȯ����ʹ��.'+dbo.crlf()
	--����ͳ���Ż�ȯ���༰�Ƿ����������Ϣ
	;WITH  cte1 AS(
		SELECT couponscode,CouponsName,canOverlay
		FROM #CouponsDocData
		GROUP BY couponscode,CouponsName,canOverlay
		)
	SELECT @tips=@tips+a.CouponsName+dbo.crlf()
	FROM cte1 a
	WHERE ISNULL(canOverlay,0)=1
	AND  (SELECT COUNT(couponscode) FROM cte1 )>1		--�ж��Ż�ȯ�����Ƿ����1
	IF @@ROWCOUNT>0
		BEGIN
			RAISERROR(@tips,16,1)
			RETURN
		END
	
	/******************************************************************�Ż�ȯ��������***********************************************************************/
	--�ж�һ���Ż�ȯ,��һ����Ʒ��,�Ƿ񳬹���������
	--ͳ��ÿ����Ʒ��ÿ���Ż�ȯ�ϵ�ʹ������.
	--���ڶ�"������"�һ����Ż�ȯ����������.
	IF EXISTS(SELECT 1 FROM #CouponsDocData WHERE ExchangeMode='������')
		BEGIN
 
			SELECT @tips='�����Ż�ȯ�����һ���������.'+dbo.crlf()
			;WITH cte AS(
				SELECT couponscode,COUNT(CouponsBarcode) AS num,convert(decimal,a.ExchangeCount,1) as ExchangeCount, a.CouponsName
				FROM #CouponsDocData a
				WHERE  a.ExchangeMode='������'
				GROUP BY couponscode,ExchangeCount,CouponsName
				)
			SELECT @tips=@tips+'['+isnull(a.CouponsName,'')+']ÿ������ʹ��'+convert(varchar(10),isnull(a.ExchangeCount,1))+'��,������ʹ��'+convert(varchar(10),isnull(a.num,0))+'��.'+dbo.crlf()
			FROM cte a
			WHERE a.num>a.ExchangeCount
			IF @@ROWCOUNT>0
				BEGIN
					RAISERROR(@tips,16,1)
					RETURN
				END
		END
	--����Ʒ���͵��Ż�ȯ��������Ʒ��Ϣ
	select @tips=''
	select @tips=@tips+a.CouponsName+'['+a.CouponsBarcode+']ֻ�ܰ���Ʒ�һ�,����ҵ�񵥾��в�������Ʒ��Ϣ���޷��һ���'+char(10)
	from #CouponsDocData a
	where a.ExchangeMode='����Ʒ' and isnull(a.matcode,'')=''
	if @@ROWCOUNT>0
		BEGIN
			raiserror(@tips,16,1)
			return
		END
	--����Ʒ�һ����Ż�ȯ,ÿ��ֻ������һ����Ʒ
	--��Ҫ���ÿ����Ʒʹ�õ��Ż�ȯ,�Ƿ񳬹��Ż����õ��������
	--���ڼ��"����Ʒ"�һ����Ż�ȯ��������
	IF EXISTS(SELECT 1 FROM #CouponsDocData WHERE ExchangeMode='����Ʒ')
		BEGIN
				--�жϰ���Ʒ�һ����Ż�ȯ,�Ƿ񳬹���������
				SELECT @tips='�����Żݳ����һ���������.'+dbo.crlf()
				;WITH cte AS(
					SELECT a.seriescode,a.RefRowID, Matcode,matname,couponscode,CouponsName,a.digit,convert(money ,a.ExchangeCount) as ExchangeCount, COUNT(a.CouponsBarcode) AS NUM
						FROM #CouponsDocData a with(nolock)
					WHERE ExchangeMode='����Ʒ'
					GROUP BY  a.seriescode,a.refrowid,Matcode,a.matname,CouponsCode,CouponsName,a.digit,a.ExchangeCount
					)
					SELECT @tips=@tips+'['+couponsName+']�ֿ���Ʒ['+a.matname+']ʱ����ʹ��'+convert(varchar(20),convert(decimal,a.ExchangeCount*a.digit,1))+'��,Ŀǰ��ʹ��'+convert(varchar(20),a.num)+'��,'+ dbo.crlf() 
					FROM cte a
					WHERE a.num>convert(decimal ,a.ExchangeCount*a.digit,1)
					IF @@ROWCOUNT>0
						BEGIN
							RAISERROR(@tips,16,1)
							return
						END
		END
		/***********************************************************************�Ż�ȯ������*****************************************************************/
		--������ֿ۽��ô������
		select @tips=''
		select @tips=@tips+a.CouponsName+'['+a.CouponsBarcode+']�ֿ۽������['+convert(varchar(10),a.couponsprice)+'Ԫ],���޸ĵֿ۽�'
		from #CouponsDocData a 
		where isnull(a.CouponsPrice,0)>0
		and isnull(a.deductAmount,0)>isnull(a.CouponsPrice,0)
		if @@ROWCOUNT>0
			BEGIN
				raiserror(@tips,16,1)
				return
			END
		--�ж�һ���Ż�ȯ,��һ����Ʒ��,�Ƿ񳬹��������
		--ͳ��ÿ����Ʒ��ÿ���Ż�ȯ�ϵĵֿ۽��
		--���ڶ�"������"�һ����Ż�ȯ�Ľ�����.
		IF EXISTS(SELECT 1 FROM #CouponsDocData a WHERE ExchangeMode='������' AND ISNULL(convert(money,a.ExchangeMoney),0)>0)
			BEGIN
				SELECT @tips='�����Ż�ȯ�����Żݽ������.'+dbo.clrlf()
				;WITH cte AS(
					SELECT couponcode,SUM(ISNULL(a.deductAmount,0)) AS num,convert(money,a.ExchangeMoney) as ExchangeMoney , a.CouponsName
					FROM #CouponsDocData a
					WHERE  a.ExchangeMode='2'
					GROUP BY couponcode,ExchangeCount,CouponsName
					)
				SELECT @tips+'['+a.CouponsName+']ÿ�������Ż�'+convert(varchar(10),a.ExchangeMoney)+'Ԫ,�������Ż�'+convert(varchar(10),a.num)+'Ԫ.'+dbo.crlf()
				FROM cte a
				WHERE isnull(a.num,0)>isnull(convert(money,a.ExchangeMoney),0)
				AND ISNULL(convert(money,a.ExchangeMoney),0)>0								--ֻ�����Ż�ȯ�ɵֿ۽�����0��
				IF @@ROWCOUNT>0
					BEGIN
						RAISERROR(@tips,16,1)
						RETURN
					END
			END
		--����Ʒ�һ����Ż�ȯ,ÿ��ֻ������һ����Ʒ
		--��Ҫ���ÿ����Ʒʹ�õ��Ż�ȯ,�Ƿ񳬹��Ż����õ�����Żݽ��
		--���ڼ��"����Ʒ"�һ����Ż�ȯ�Żݽ�����
		IF EXISTS(SELECT 1 FROM #CouponsDocData WHERE ExchangeMode='����Ʒ')
			BEGIN
					--�жϰ���Ʒ�һ����Ż�ȯ,�Ƿ񳬹��Żݽ������
					SELECT @tips='�����Żݳ����Żݽ������.'+dbo.crlf()
					/*;WITH cte AS(
						SELECT a.seriescode,a.Matcode,a.matname,couponscode,CouponsName,SUM(ISNULL(a.deductAmount,0)) AS num ,convert(money,a.ExchangeMoney) as ExchangeMoney ,a.digit
						FROM #CouponsDocData a  
						WHERE ExchangeMode='����Ʒ'
						GROUP BY a.seriescode,Matcode,a.matname,CouponsCode,CouponsName,a.ExchangeMoney,a.digit
					)
					select * from cte*/
					;WITH cte AS(
						SELECT a.seriescode,a.Matcode,a.matname,couponscode,CouponsName,SUM(ISNULL(a.deductAmount,0)) AS num ,convert(money,a.ExchangeMoney) as ExchangeMoney ,a.digit
						FROM #CouponsDocData a  
						WHERE ExchangeMode='����Ʒ'
						GROUP BY a.seriescode,Matcode,a.matname,CouponsCode,CouponsName,a.ExchangeMoney,a.digit
						)
						SELECT @tips=@tips+''+couponsName+'�ֿ���Ʒ['+a.matname+']ʱ�����Ż�'+convert(varchar(20),isnull(a.ExchangeMoney,0)*a.digit)+'Ԫ,Ŀǰ��ʹ��'+convert(varchar(20),a.num)+'Ԫ,'+ dbo.crlf() 
						FROM cte a
						WHERE   isnull(a.num,0)>isnull(convert(money,a.ExchangeMoney),0)*a.digit
						AND ISNULL(convert(money,a.ExchangeMoney),0)>0									--ֻ�����Ż�ȯ�ɵֿ۽�����0��
						IF @@ROWCOUNT>0
							BEGIN
								RAISERROR(@tips,16,1)
								return
							END
			END
		/**********************************************************�Ż�ȯ�һ��������*************************************************************/
		--ִ�����͹����ж�
		SELECT @tips ='�����Ż�ȯ�����϶һ�����,����ϸ�鿴�Ż�ȯʹ���ֲ�!'+dbo.crlf()
		SELECT @tips=@tips+a.couponsName+'['+a.couponsbarcode+']'+dbo.crlf()
		FROM #CouponsDocData a
		where NOT EXISTS(SELECT 1 FROM   Strategy_Coupons sc   
						WHERE a.CouponsCode=sc.CouponsCode 
						AND sc.Straytegygroup='02.01.02'
						AND (ISNULL(sc.Matcode,'')='' OR sc.Matcode=a.Matcode)
						AND (ISNULL(sc.Matgroup,'')='' OR a.MatgroupPath LIKE '%/'+sc.Matgroup+'/%')
						AND (ISNULL(sc.SdorgID,'')='' OR a.SdorgPath LIKE '%/'+sc.SdorgID+'/%')
						AND (ISNULL(sc.AreaID,'')='' OR EXISTS(SELECT 1 FROM commondb.dbo.[SPLIT](ISNULL(sc.AreaID,''),',') s WHERE a.AreaPath LIKE '%/'+s.List+'/%'))
						AND convert(bit,dbo.ExecuteScalar(0, commondb.dbo.REGEXP_Replace(ISNULL(NULLIF(sc.Filter,''),'1'),  '(?:^|\b)(?<!&|''|#)((\d:)?[\u4e00-\u9fa5]+)(?!&|''|#)(?:$|\b)','#$1#')
						,'Select * From #CouponsDocData','CouponsBarcode='''+a.CouponsBarcode+'''',-1,
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