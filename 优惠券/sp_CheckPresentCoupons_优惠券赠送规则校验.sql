/*
�������ƣ�sp_CheckPresentCoupons
����������У���Ż�ȯ���͹���
������������;�����̵Ĳ����⣬����Ҫ����һ��#CouponsDocData����ʱ���ڴ���ʱ���д洢ҵ�����ݺ��Ż�ȯ���ݣ������̽����ݴ�����Դ����У�顣
����ֵ��
��д�����ϵ�
��ע��
#CouponsDocData�ɰ�����ҵ�������ֵ
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
						ig.ForceCheckStock,ig.BeginDate,ig.EndDate,ig.Valid,ig.Price,	s.MatCode,s.MatName,ig2.MatGroup,ig2.mattype,ig3.[PATH],
						s.price,s.totalmoney,s.Digit,s.DeductAmout,ig.CouponsOwner,ig.canOverlay,s.RowID,newid() RefRowID,s.SeriesCode,i.beginValidDate,i.ValidDate,
						i.CouponsOWNER,i.authKey,i.Occupyed,i.OccupyedDoccode
						FROM  sPickorderitem s with(nolock) INNER JOIN oStorage o  with(nolock) ON o.stCode=@Stcode
						INNER JOIN oSDOrg o2  with(nolock) ON o.sdorgid=o2.SDOrgID
						INNER JOIN gArea g  with(nolock) ON o2.AreaID=g.areaid
						left JOIN iCoupons i  with(nolock) ON s.CouponsBarCode=i.CouponsBarcode						--�Ż�ȯ��һ������,�˴�Ҫ��Left Join 
						left JOIN iCouponsGeneral ig  with(nolock) ON i.CouponsCode=ig.CouponsCode
						left JOIN iMatGeneral ig2  with(nolock) ON s.MatCode=ig2.MatCode
						left JOIN iMatGroup ig3  with(nolock) ON ig2.MatGroup=ig3.matgroup
						WHERE s.Doccode=@doccode
					end
				if @FormID in(9201)
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
								cd.Amount,cd.Amount,cd.DeductAmout,cd.DeductAmout,cd.RowID,cd.RefRowID,cd.SeriesCode,i.CouponsOWNER,i.authkey ,i.Occupyed,i.OccupyedDoccode
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
				set PresentCount= commondb.dbo.REGEXP_Replace(PresentCount, '(?:^|\b)(?<!&|''|#)((\d:)?[\u4e00-\u9fa5]+)(?!&|''|#)(?:$|\b)','#$1#'),
				PresentMoney=commondb.dbo.REGEXP_Replace(PresentMoney,  '(?:^|\b)(?<!&|''|#)((\d:)?[\u4e00-\u9fa5]+)(?!&|''|#)(?:$|\b)','#$1#')
				where ISNULL(PresentMoney,'')!='' OR ISNULL(PresentCount,'')!=''
				--select * from #CouponsDocData a
				--���ݱ��ʽ����ɶһ������ͽ��.���ֿ������͵ֿ۶�ȱ����Ѿ�������,�Ͳ���ִ�и�����.���򰴱��ʽ����.
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
		--���������Ż�ȯ����ֱ���˳���
		if not exists(select 1 from #CouponsDocData where isnull(CouponsBarcode,'')<>'')
			BEGIN
				print '�Ż�ȯ���͹�����-->û���Ż�ȯҵ������,������ֹ.'
				return -1
			END
		
		--��Դ��ʽΪ��1����3����5��Ҫ����,����Ż�ȯ״̬
		--��Դ��ʽΪ��1����3����5��Ҫ����,����Ż�ȯ״̬
		SELECT @tips='' 
		if @OptionID='#Precheck#'
			BEGIN
				SELECT @tips=@tips+'�Ż�ȯ'+isnull(a.CouponsName,'')+'['+a.CouponsBarcode+']'+'��ǰ״̬Ϊ['+ISNULL(a.state,'������')+'],�޷����͡�'+dbo.crlf()
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
				SELECT @tips=@tips+'�Ż�ȯ'+isnull(a.CouponsName,'')+'['+a.CouponsBarcode+']'+'��ǰ״̬Ϊ['+ISNULL(a.state,'������')+'],�޷����͡�'+dbo.crlf()
				FROM #CouponsDocData a  with(nolock)
				WHERE isnull(a.SourceMode,1) IN(1,2)
				AND isnull(a.[STATE],'')!='�ڿ�'
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
		--��û�д����͵��Ż�ȯ,���˳����
		if not exists(select 1 from #CouponsDocData where STATE='�ڿ�') return
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
		from #CouponsDocData a where isnull(nullif(ltrim(rtrim(a.PresentFormGroup)),''),'9201')!='9201'												--��δ���ÿ����͹��ܺţ�������Ϊ9201���κ�ҵ�����
		and  a.formid not in( select list from commondb.dbo.SPLIT(isnull(a.PresentFormGroup,'9201'),',') )	
		and (isnull(a.RefFormID,0)=0 or a.refformid not in( select list from commondb.dbo.SPLIT(isnull(a.PresentFormGroup,'9201'),',')))
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
	/******************************************************************�Ż�ȯ��������***********************************************************************/
	--�ж�һ���Ż�ȯ,��һ����Ʒ��,�Ƿ񳬹���������
	--ͳ��ÿ����Ʒ��ÿ���Ż�ȯ�ϵ�ʹ������.
	--���ڶ�"������"�һ����Ż�ȯ����������.
	IF EXISTS(SELECT 1 FROM #CouponsDocData WHERE PresentMode='������')
		BEGIN
 
			SELECT @tips='�����Ż�ȯ����������������.'+dbo.crlf()
			;WITH cte AS(
				SELECT couponscode,COUNT(CouponsBarcode) AS num,a.PresentCount, a.CouponsName
				FROM #CouponsDocData a
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
	--����Ʒ���͵��Ż�ȯ��������Ʒ��Ϣ
	select @tips=''
	select @tips=@tips+a.CouponsName+'['+a.CouponsBarcode+']ֻ�ܰ���Ʒ����,����ҵ�񵥾��в�������Ʒ��Ϣ���޷����͡�'+char(10)
	from #CouponsDocData a
	where a.PresentMode='����Ʒ' and isnull(a.matcode,'')=''
	if @@ROWCOUNT>0
		BEGIN
			raiserror(@tips,16,1)
			return
		END
	--����Ʒ�һ����Ż�ȯ,ÿ��ֻ������һ����Ʒ
	--��Ҫ���ÿ����Ʒʹ�õ��Ż�ȯ,�Ƿ񳬹��Ż����õ��������
	--���ڼ��"����Ʒ"�һ����Ż�ȯ��������
	
	IF EXISTS(SELECT 1 FROM #CouponsDocData WHERE PresentMode='����Ʒ')
		BEGIN
				/*;WITH cte AS(
					SELECT a.seriescode,a.RefRowID, Matcode,matname,couponscode,CouponsName,a.digit,convert(money,a.PresentCount) as PresentCount, COUNT(a.CouponsBarcode) AS NUM
						FROM #CouponsDocData a with(nolock)
					WHERE ExchangeMode='����Ʒ'
					GROUP BY  a.seriescode,a.refrowid,Matcode,a.matname,CouponsCode,CouponsName,a.digit,a.PresentCount
				)
				select * from cte*/
				--�жϰ���Ʒ�һ����Ż�ȯ,�Ƿ񳬹���������
				SELECT @tips='�����Żݳ����һ���������.'+dbo.crlf()
				;WITH cte AS(
					SELECT a.seriescode,a.RefRowID, Matcode,matname,couponscode,CouponsName,a.digit,convert(float,a.PresentCount) as PresentCount, COUNT(a.CouponsBarcode) AS NUM
						FROM #CouponsDocData a with(nolock)
					WHERE ExchangeMode='����Ʒ'
					GROUP BY  a.seriescode,a.refrowid,Matcode,a.matname,CouponsCode,CouponsName,a.digit,a.PresentCount
					)
					SELECT @tips=@tips+'['+couponsName+']�ֿ���Ʒ['+a.matname+']ʱ����ʹ��'+convert(varchar(20),convert(decimal,a.PresentCount*a.digit,2))+'��,Ŀǰ��ʹ��'+convert(varchar(20),a.num)+'��,'+ dbo.crlf() 
					FROM cte a
					WHERE isnull(a.num,0)>isnull(convert(decimal,a.PresentCount*a.digit,1),0)
					IF @@ROWCOUNT>0
						BEGIN
							RAISERROR(@tips,16,1)
							return
						END
		END
		--select * from #CouponsDocData
		--ִ�����͹����ж�
		SELECT @tips ='�����Ż�ȯ���������͹���,����ϸ�鿴�Ż�ȯʹ���ֲ�!'+dbo.crlf()
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