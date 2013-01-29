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
	@RefFormID int,
	@OptionID varchar(200)='',
	@Usercode varchar(50)=''
as
	BEGIN
		set NOCOUNT on;
		declare @tips varchar(max)
		--ҵ������У��
		if object_id('tempdb.dbo.#Docdata') is NULL
			BEGIN
				raiserror('ҵ�����ݲ����ڣ��޷�У���Ż�ȯ.',16,1)
				return
			END
		--���Ż�ȯ������Ż�ȯ��Ϣ
		UPDATE a
			SET a.[STATE]=ic.[State],
			[OWNER] = ic.CouponsOWNER,
			CouponsAuthKey=ic.AuthKey
		FROM #DocData a,iCoupons ic WITH(NOLOCK)
		WHERE a.CouponsBarcode=ic.CouponsBarcode
		--��Դ��ʽΪ��1����3����5��Ҫ����,����Ż�ȯ״̬
		SELECT @tips='�����Ż�ȯ���ڿ�����״̬,�޷�ʹ��!'+dbo.crlf()
		SELECT @tips=@tips+a.CouponsName+'['+a.CouponsBarcode+']'+dbo.crlf()
		FROM #DocData a  with(nolock)
		WHERE a.SourceMode IN(1,2)
		AND a.[STATE]!='�ڿ�'
		IF @@ROWCOUNT>0
			BEGIN
				drop TABLE #DocData
				RAISERROR(@tips,16,1)
				return
			END
		--�����������
		SELECT @tips='�����Ż�ȯֻ����"һ��һȯ"��ʽ����,�Ż�ȯ������������.'+dbo.crlf()
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
	--���һ�����
	SELECT @tips='�����Ż�ȯ����Ҫ�����ҵ�񵥾ݷ���ʹ��.'+dbo.crlf()
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
		SELECT @tips='�����Ż�ȯֻ����"һ��Ʒһȯ"��ʽ����.'+dbo.crlf()
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
		--��������
		update #DocData
		set PresentCount= commondb.dbo.REGEXP_Replace(PresentCount, '(?:^|\b)(?<!&|''|#)((\d:)?[\u4e00-\u9fa5]+)(?!&|''|#)(?:$|\b)','#$1#'),
		PresentMoney=commondb.dbo.REGEXP_Replace(PresentMoney,  '(?:^|\b)(?<!&|''|#)((\d:)?[\u4e00-\u9fa5]+)(?!&|''|#)(?:$|\b)','#$1#')
		where ISNULL(PresentMoney,'')!='' OR ISNULL(PresentCount,'')!=''
		--ִ���ж�
		SELECT @tips ='�����Ż�ȯ���������������������,����ϸ�鿴�Ż�ȯʹ���ֲ�!'+dbo.crlf()
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