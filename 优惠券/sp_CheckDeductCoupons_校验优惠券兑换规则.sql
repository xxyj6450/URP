/*
�������ƣ�sp_CheckDeductCoupons
����������У���Ż�ȯ�һ�����
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
		--ҵ������У��
		if object_id('tempdb.dbo.#Docdata') is NULL
			BEGIN
				raiserror('ҵ�����ݲ����ڣ��޷�У���Ż�ȯ.',16,1)
				return
			END
		
		--��Դ��ʽΪ��1����3����5��Ҫ����,����Ż�ȯ״̬
		SELECT @tips='' 
		SELECT @tips=@tips+'�Ż�ȯ'+a.CouponsName+'['+a.CouponsBarcode+']'+'��ǰ״̬Ϊ['+ISNULL(a.state,'')+'],�޷��һ���'+dbo.crlf()
		FROM #DocData a  with(nolock)
		WHERE a.SourceMode IN(1,2)
		AND a.[STATE]!='����'
		IF @@ROWCOUNT>0
			BEGIN
				drop TABLE #DocData
				RAISERROR(@tips,16,1)
				return
			END
		--����Ʒ�һ����Ż�ȯ,������Դ������Ʒ��Ϣ,��ֹ����һ��Ż�ȯ
		select @tips=''
		select @tips=@tips+'��Ʒ['+matname+']��Դ�������Ѳ�����,��������ʹ���Ż�ȯ['+couponsbarcode+'].'+dbo.crlf()
		From #DocData a
		where a.ExchangeMode='����Ʒ'
		and (isnull(a.RefRowID,'')='' or isnull(a.Matcode,'')='')
		if @@ROWCOUNT>0
			BEGIN
				raiserror(@tips,16,1)
				return
			END
		--���Ż�ȯ������Ż�ȯ��Ϣ
		UPDATE a
			SET a.[STATE]=ic.[State],
			[OWNER] = ic.CouponsOWNER,
			CouponsAuthKey=ic.AuthKey,
			beginValidDate = ic.beginValidDate,
			endValidDate = ic.ValidDate
		FROM #DocData a,iCoupons ic WITH(NOLOCK)
		WHERE a.CouponsBarcode=ic.CouponsBarcode
	--��������
	update #DocData
	set PresentCount= commondb.dbo.REGEXP_Replace(isnull(ExchangeCount,''), '(?:^|\b)(?<!&|''|#)((\d:)?[\u4e00-\u9fa5]+)(?!&|''|#)(?:$|\b)','#$1#'),
	PresentMoney=commondb.dbo.REGEXP_Replace(isnull(ExchangeMoney,''),  '(?:^|\b)(?<!&|''|#)((\d:)?[\u4e00-\u9fa5]+)(?!&|''|#)(?:$|\b)','#$1#'),
	Price=commondb.dbo.REGEXP_Replace(isnull(Price,''),  '(?:^|\b)(?<!&|''|#)((\d:)?[\u4e00-\u9fa5]+)(?!&|''|#)(?:$|\b)','#$1#')
	where ISNULL(ExchangeCount,'')!='' OR ISNULL(ExchangeMoney,'')!='' OR ISNULL(Price,'')!=''
	--�ɱ���˾��ϵͳ���е��Ż�ȯ,��ҪΪ�����ͻ�ʹ����,������һ�
	SELECT @tips='�����Ż�ȯδ����,������һ�.'+dbo.crlf()
	SELECT @tips=@tips+a.CouponsName+'['+a.CouponsBarcode+']'+dbo.crlf()
	FROM #DocData a  with(nolock)
	WHERE a.SourceMode IN(1,2)
	AND isnull(a.[STATE],'') NOT IN('����','ʹ����')
	IF @@ROWCOUNT>0
		BEGIN
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
	--�ж��Ƿ��в��������ʹ�õ��Ż�ȯ
	SELECT @tips='�����Ż�ȯ�������������Ż�ȯ����ʹ��.'+dbo.crlf()
	--����ͳ���Ż�ȯ���༰�Ƿ����������Ϣ
	;WITH  cte1 AS(
		SELECT couponscode,CouponsName,canOverlay
		FROM #DocData
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
	--���ݱ��ʽ����ɶһ������ͽ��.���ֿ������͵ֿ۶�ȱ����Ѿ�������,�Ͳ���ִ�и�����.���򰴱��ʽ����.
	IF not  EXISTS (SELECT 1 FROM #DocData a WHERE ISNUMERIC(ISNULL(a.ExchangeCount,'1'))=1 AND ISNUMERIC(ISNULL(a.ExchangeMoney,'0'))=1 )
		BEGIN
			UPDATE  a
			SET a.ExchangeCount=convert(int,b.data1),
			a.ExchangeMoney=CONVERT(MONEY,b.data2)
			FROM #DocData a OUTER APPLY dbo.ExecuteTable(0,ISNULL(a.ExchangeCount,'1')+';'+ISNULL(a.ExchangeMoney,'0'),
			'Select * From #DocData','CouponsBarcode='''+a.CouponsBarcode+'''',-1,
			'Select * From fn_getFormulaFields('''+CONVERT(VARCHAR(20),@formid)+CASE WHEN ISNULL(@refFormid,'')!='' THEN ','+CONVERT(VARCHAR(20),@refFormid) ELSE '' END +''')',0) b
		END
	/******************************************************************�Ż�ȯ��������***********************************************************************/
	--�ж�һ���Ż�ȯ,��һ����Ʒ��,�Ƿ񳬹���������
	--ͳ��ÿ����Ʒ��ÿ���Ż�ȯ�ϵ�ʹ������.
	--���ڶ�"������"�һ����Ż�ȯ����������.
	IF EXISTS(SELECT 1 FROM #DocData WHERE ExchangeMode='������')
		BEGIN
 
			SELECT @tips='�����Ż�ȯ�����һ���������.'+dbo.crlf()
			;WITH cte AS(
				SELECT couponscode,COUNT(CouponsBarcode) AS num,a.ExchangeCount, a.CouponsName
				FROM #DocData a
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
	--����Ʒ�һ����Ż�ȯ,ÿ��ֻ������һ����Ʒ
	--��Ҫ���ÿ����Ʒʹ�õ��Ż�ȯ,�Ƿ񳬹��Ż����õ��������
	--���ڼ��"����Ʒ"�һ����Ż�ȯ��������
	IF EXISTS(SELECT 1 FROM #DocData WHERE ExchangeMode='����Ʒ')
		BEGIN
				--�жϰ���Ʒ�һ����Ż�ȯ,�Ƿ񳬹���������
				SELECT @tips='�����Żݳ����һ���������.'+dbo.crlf()
				;WITH cte AS(
					SELECT a.seriescode,a.RefRowID, Matcode,matname,couponscode,CouponsName,a.digit,a.ExchangeCount, COUNT(a.CouponsBarcode) AS NUM
						FROM #DocData a with(nolock)
					WHERE ExchangeMode='����Ʒ'
					GROUP BY  a.seriescode,a.refrowid,Matcode,a.matname,CouponsCode,CouponsName,a.digit,a.ExchangeCount
					)
					SELECT @tips=@tips+'['+couponsName+']�ֿ���Ʒ['+a.matname+']ʱ����ʹ��'+convert(varchar(20),a.ExchangeCount*a.digit)+'��,Ŀǰ��ʹ��'+convert(varchar(20),a.num)+'��,'+ dbo.crlf() 
					FROM cte a
					WHERE a.num>a.ExchangeCount*a.digit
					IF @@ROWCOUNT>0
						BEGIN
							RAISERROR(@tips,16,1)
							return
						END
		END
		/***********************************************************************�Ż�ȯ������*****************************************************************/
		--�ж�һ���Ż�ȯ,��һ����Ʒ��,�Ƿ񳬹��������
		--ͳ��ÿ����Ʒ��ÿ���Ż�ȯ�ϵĵֿ۽��
		--���ڶ�"������"�һ����Ż�ȯ�Ľ�����.
		IF EXISTS(SELECT 1 FROM #DocData a WHERE ExchangeMode='������' AND ISNULL(a.ExchangeMoney,0)>0)
			BEGIN
				SELECT @tips='�����Ż�ȯ�����Żݽ������.'+dbo.clrlf()
				;WITH cte AS(
					SELECT couponcode,SUM(ISNULL(a.deductAmount,0)) AS num,a.ExchangeMoney, a.CouponsName
					FROM #DocData a
					WHERE  a.ExchangeMode='2'
					GROUP BY couponcode,ExchangeCount,CouponsName
					)
				SELECT @tips+'['+a.CouponsName+']ÿ�������Ż�'+convert(varchar(10),a.ExchangeMoney)+'Ԫ,�������Ż�'+convert(varchar(10),a.num)+'Ԫ.'+dbo.crlf()
				FROM cte a
				WHERE isnull(a.num,0)>isnull(a.ExchangeMoney,0)
				AND ISNULL(a.ExchangeMoney,0)>0								--ֻ�����Ż�ȯ�ɵֿ۽�����0��
				IF @@ROWCOUNT>0
					BEGIN
						RAISERROR(@tips,16,1)
						RETURN
					END
			END
		--����Ʒ�һ����Ż�ȯ,ÿ��ֻ������һ����Ʒ
		--��Ҫ���ÿ����Ʒʹ�õ��Ż�ȯ,�Ƿ񳬹��Ż����õ�����Żݽ��
		--���ڼ��"����Ʒ"�һ����Ż�ȯ�Żݽ�����
		IF EXISTS(SELECT 1 FROM #DocData WHERE ExchangeMode='����Ʒ')
			BEGIN
					--�жϰ���Ʒ�һ����Ż�ȯ,�Ƿ񳬹��Żݽ������
					SELECT @tips='�����Żݳ����Żݽ������.'+dbo.crlf()
					;WITH cte AS(
						SELECT a.seriescode,a.Matcode,a.matname,couponscode,CouponsName,SUM(ISNULL(a.deductAmount,0)) AS num ,a.ExchangeMoney ,a.digit
						FROM #DocData a  
						WHERE ExchangeMode='����Ʒ'
						GROUP BY a.seriescode,Matcode,a.matname,CouponsCode,CouponsName,a.ExchangeMoney,a.digit
						)
						SELECT @tips=@tips+'['+couponsName+']�ֿ���Ʒ['+a.matname+']ʱ�����Ż�'+convert(varchar(20),isnull(a.ExchangeMoney,0))+'Ԫ,Ŀǰ��ʹ��'+convert(varchar(20),a.num)+'Ԫ,'+ dbo.crlf() 
						FROM cte a
						WHERE   isnull(a.num,0)>isnull(a.ExchangeMoney,0)*a.digit
						AND ISNULL(a.ExchangeMoney,0)>0									--ֻ�����Ż�ȯ�ɵֿ۽�����0��
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