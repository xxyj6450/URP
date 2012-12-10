/*
��������:sp_GenerateCouponsbarcode
����ֵ:��
����:�����Ż�ȯ���,������Ż�д����ⵥ
��д:���ϵ�
ʱ��:2012-05-07
ʾ��:exec [sp_GenerateCouponsbarcode] '1001','QCK2012050800002',100,-1
��ע:����ʱ���Զ�ɾ��������ԭ���Ż�ȯ����.ֻ�е�����ȷ��ʱ�Ÿ��µ�ǰ�Ż�ȯ������.
�����Ǳ���ģʽ
1.ǰ׺+����+���+У��λ
2.ǰ׺+����+���
3.ǰ׺+���+У��λ
4.ǰ׺+���
5.�޹���
У��λ����LUHN�㷨
*/
 
alter PROC [dbo].[sp_GenerateCouponsbarcode]
	@CouponsCode VARCHAR(50),				--�����ɱ�����Ż�ȯ
	@Doccode VARCHAR(20),					--���ݽ�����ĵ���
	@GenerateCount INT=100,					--���ɵ�����
	@Basedigit INT=0,						--��ʼ���,��Ϊ0,��ӵ�ǰ�����ֵ��ʼ,����Ӵ���ſ�ʼ
	@ReserverDoc BIT=1							--�Ƿ񱣳ֵ���ԭ������
AS
	BEGIN
		SET NOCOUNT ON;
		--��������
		DECLARE @Prefix VARCHAR(20),@CodeMode AS VARCHAR(6),@Length INT,@StartNum INT,@Rowcount INT,
		@MaxDate DATETIME,@Now DATETIME,@CouponsName VARCHAR(200),@tips VARCHAR(200),@bitHasMaxcode bit
		--��ʼ��
		SELECT @StartNum=0,@MaxDate='1900-01-01',@Now=CONVERT(VARCHAR(10),GETDATE(),120),@bitHasMaxcode=1
		IF @Basedigit<0
			BEGIN
				RAISERROR('����BaseDigit����С��0,����ϵϵͳ����Ա.',16,1)
				RETURN 0
			END
		--ȡ���Ż�ȯ������Ϣ
		SELECT @Prefix=isnull(ig.prefix,''),@CodeMode=ig.CodeMode,@Length=ig.CodeLength,@CouponsName=ig.CouponsName
		  FROM iCouponsGeneral ig WITH(NOLOCK) WHERE ig.CouponsCode=@CouponsCode
		 IF @@ROWCOUNT=0
			BEGIN
				RAISERROR('�Ż�ȯ������,�޷����ɱ���.',16,1)
				RETURN 0
			END
		--������
		IF isnull(@GenerateCount,0)<=0 OR isnull(@GenerateCount,0)>10000
			BEGIN
				RAISERROR('���ɱ��������������1��10000֮��!',16,1)
				RETURN 0
			END
 		/*
			ȡ����󳤶�,�������������
			1.���ڱ���ģʽΪ1��2ʱ,ȡ��������ڵ�������.���������Ϊ��(�п������״�ʹ��),��С�ڵ�ǰ����,����������޸�Ϊ����,������Ϊ0
			2.���ڱ���ģʽΪ3��4ʱ,ȡ��������,��������Ϊ��(�״�ʹ��),��������Ϊ0
			3.��
		*/
		IF @CodeMode IN('1','2')
			BEGIN
				SELECT @StartNum=MAX(cmc.MaxNumber),@MaxDate=MAX(isnull(cmc.[Datetime],@Now)) FROM Coupons_MaxCode cmc 
				WHERE cmc.CouponsCode=@CouponsCode
				AND cmc.[Datetime]=CONVERT(VARCHAR(10),GETDATE(),120)
				GROUP BY CouponsCode
				SELECT @Rowcount=@@ROWCOUNT
			END
		ELSE
			BEGIN
				SELECT @StartNum=MAX(cmc.MaxNumber),@MaxDate=MAX(isnull(cmc.[Datetime],@Now)) FROM Coupons_MaxCode cmc 
				WHERE cmc.CouponsCode=@CouponsCode
				GROUP BY cmc.CouponsCode
				SELECT @Rowcount=@@ROWCOUNT
			END
		IF @ROWCOUNT=0
			BEGIN
				SELECT @StartNum=1,@MaxDate=convert(varchar(10),GETDATE(),120),@bitHasMaxcode=0
			END
		ELSE
			BEGIN
				SELECT @StartNum=@StartNum+1,@MaxDate=convert(varchar(10),GETDATE(),120)
			END
		 
		--���������С�ڵ�ǰ����,�����������Ϊ��ǰ����,������ʼ��ֵ����0
		IF ISNULL(@MaxDate,'1900-01-01')<@Now AND @CodeMode IN('1','2')
			BEGIN
				select @MaxDate=convert(varchar(10),GETDATE(),120),@StartNum=1 
			END
		IF @bitHasMaxcode=0
			BEGIN
				INSERT INTO Coupons_MaxCode(CouponsCode,MaxNumber,[Datetime])
				SELECT @CouponsCode,@GenerateCount,convert(varchar(10),@MaxDate,120)
			END
		ELSE IF @bitHasMaxcode=1
			BEGIN
				UPDATE Coupons_MaxCode	
					SET MaxNumber = MaxNumber+@GenerateCount,
					[Datetime]=CONVERT(VARCHAR(10),@MaxDate,120)
				WHERE CouponsCode=@CouponsCode
			END
		--��������Ϊ0,�һ���С�������,�����ֱ����ظ�,�׳��쳣
		IF @Basedigit!=0 AND @Basedigit<@StartNum
			BEGIN
				RAISERROR('��ʼ��űȵ�ǰ������С,���ܳ����ظ�,������������ʼ���,������0',16,1)
				return
			END
		IF @Basedigit!=0 AND @Basedigit>=@StartNum
			BEGIN
				SELECT @StartNum=@Basedigit+@StartNum
			END
		 PRINT @StartNum
		--���ԭ������
		IF ISNULL(@ReserverDoc,0)=0 AND @Doccode!='' 		DELETE FROM Coupons_D WHERE Doccode=@Doccode
		--���濪ʼ��������
		IF @CodeMode IN('1')
			BEGIN
				IF @Length<LEN(@Prefix)+9+4
					BEGIN
						SELECT @tips='�Ż�ȯ�������ù���,��������'+CONVERT(VARCHAR(200),len(@Prefix)+13)+'λ.'
						RAISERROR(@tips,16,1)
						return
					END
				IF @Doccode='' AND OBJECT_ID('tempdb.dbo.#Couponsbarcode') IS NOT NULL
					BEGIN
						INSERT INTO #Couponsbarcode(CouponsBarCode,CouponsCode,CouponsName)
						SELECT  upper(@Prefix)+CONVERT(VARCHAR(8),@MaxDate,112)+right('00000000000000000000'+ CONVERT(VARCHAR(50),n.digit),@Length-LEN(@Prefix)-9)+
						dbo.fn_getcheckcode(CONVERT(VARCHAR(8),@MaxDate,112)+right('00000000000000000000'+ CONVERT(VARCHAR(50),n.digit),@Length-LEN(@Prefix)-9),'LUHN'),
						@CouponsCode,@CouponsName
						FROM Numbers n WITH(NOLOCK)
						WHERE digit BETWEEN @StartNum AND @StartNum+  @GenerateCount-1
					END
				IF @Doccode!=''
					BEGIN
						INSERT INTO Coupons_D(Doccode,Docitem,RowID,CouponsBarCode,CouponsCode,CouponsName)
						SELECT @Doccode,ROW_NUMBER() OVER(ORDER BY (SELECT 1)),NEWID(),
						upper(@Prefix)+CONVERT(VARCHAR(8),@MaxDate,112)+right('00000000000000000000'+ CONVERT(VARCHAR(50),n.digit),@Length-LEN(@Prefix)-9)+
						dbo.fn_getcheckcode(CONVERT(VARCHAR(8),@MaxDate,112)+right('00000000000000000000'+ CONVERT(VARCHAR(50),n.digit),@Length-LEN(@Prefix)-9),'LUHN'),
						@CouponsCode,@CouponsName
						FROM Numbers n WITH(NOLOCK)
						WHERE digit BETWEEN @StartNum AND @StartNum+  @GenerateCount-1
					END
				
			END
		IF @CodeMode IN('2')
			BEGIN
				IF @Length<LEN(@Prefix)+8+4
					BEGIN
						SELECT @tips='�Ż�ȯ�������ù���,��������'+CONVERT(VARCHAR(200),len(@Prefix)+12)+'λ.'
						RAISERROR(@tips,16,1)
						return
					END
				IF @Doccode='' AND OBJECT_ID('tempdb.dbo.#Couponsbarcode') IS NOT NULL
					BEGIN
						INSERT INTO #Couponsbarcode(CouponsBarCode,CouponsCode,CouponsName)
						SELECT  upper(@Prefix)+CONVERT(VARCHAR(8),@MaxDate,112)+right('00000000000000000000'+ CONVERT(VARCHAR(50),n.digit),@Length-LEN(@Prefix)-8),
						@CouponsCode,@CouponsName
						FROM Numbers n
						WHERE digit BETWEEN @StartNum AND @StartNum+  @GenerateCount-1
					END
				IF @Doccode!=''
					BEGIN
						INSERT INTO Coupons_D(Doccode,Docitem,RowID,CouponsBarCode,CouponsCode,CouponsName)
						SELECT @Doccode,ROW_NUMBER() OVER(ORDER BY (SELECT 1)),NEWID(),
						upper(@Prefix)+CONVERT(VARCHAR(8),@MaxDate,112)+right('00000000000000000000'+ CONVERT(VARCHAR(50),n.digit),@Length-LEN(@Prefix)-8),
						@CouponsCode,@CouponsName
						FROM Numbers n
						WHERE digit BETWEEN @StartNum AND @StartNum+  @GenerateCount-1
					END
				
			END		 
		IF @CodeMode IN('3')
			BEGIN
				IF @Length<LEN(@Prefix)+1+4
					BEGIN
						SELECT @tips='�Ż�ȯ�������ù���,��������'+CONVERT(VARCHAR(200),len(@Prefix)+5)+'λ.'
						RAISERROR(@tips,16,1)
						return
					END
				IF @Doccode='' AND OBJECT_ID('tempdb.dbo.#Couponsbarcode') IS NOT NULL
					BEGIN
						INSERT INTO #Couponsbarcode(CouponsBarCode,CouponsCode,CouponsName)
						SELECT  upper(@Prefix)+right('00000000000000000000'+ CONVERT(VARCHAR(50),n.digit),@Length-LEN(@Prefix)-1)+
						dbo.fn_getcheckcode(right('00000000000000000000'+ CONVERT(VARCHAR(50),n.digit),@Length-LEN(@Prefix)-1),'LUHN'),
						@CouponsCode,@CouponsName
						FROM Numbers n
						WHERE digit BETWEEN @StartNum AND @StartNum+  @GenerateCount-1
					END
				IF @Doccode!=''
					BEGIN
						INSERT INTO Coupons_D(Doccode,Docitem,RowID,CouponsBarCode,CouponsCode,CouponsName)
						SELECT @Doccode,ROW_NUMBER() OVER(ORDER BY (SELECT 1)),NEWID(),
						upper(@Prefix)+right('00000000000000000000'+ CONVERT(VARCHAR(50),n.digit),@Length-LEN(@Prefix)-1)+
						dbo.fn_getcheckcode(right('00000000000000000000'+ CONVERT(VARCHAR(50),n.digit),@Length-LEN(@Prefix)-1),'LUHN'),
						@CouponsCode,@CouponsName
						FROM Numbers n
						WHERE digit BETWEEN @StartNum AND @StartNum+  @GenerateCount-1
					END
			END			 
 		IF @CodeMode IN('4')
			BEGIN
				IF @Length<LEN(@Prefix)+4
					BEGIN
						SELECT @tips='�Ż�ȯ��������̫��,��������'+CONVERT(VARCHAR(200),len(@Prefix)+4)+'λ.'
						RAISERROR(@tips,16,1)
						return
					END
				IF @Doccode='' AND OBJECT_ID('tempdb.dbo.#Couponsbarcode') IS NOT NULL
					BEGIN
						INSERT INTO #Couponsbarcode(CouponsBarCode,CouponsCode,CouponsName)
						SELECT upper(@Prefix)+right('00000000000000000000'+ CONVERT(VARCHAR(50),n.digit),@Length-LEN(@Prefix)),
						@CouponsCode,@CouponsName
						FROM Numbers n
						WHERE digit BETWEEN @StartNum AND @StartNum+  @GenerateCount-1
					END
				IF @Doccode!=''
					BEGIN
						INSERT INTO Coupons_D(Doccode,Docitem,RowID,CouponsBarCode,CouponsCode,CouponsName)
						SELECT @Doccode,ROW_NUMBER() OVER(ORDER BY (SELECT 1)),NEWID(),
						upper(@Prefix)+right('00000000000000000000'+ CONVERT(VARCHAR(50),n.digit),@Length-LEN(@Prefix)),
						@CouponsCode,@CouponsName
						FROM Numbers n
						WHERE digit BETWEEN @StartNum AND @StartNum+  @GenerateCount-1
					END
			END
		IF @CodeMode IN('5')
			BEGIN
				RAISERROR('���Ż�ȯ�����Զ����ɱ���!',16,1)
				return
			END
		--�������ֵ
		IF @Doccode!='' 	UPDATE Coupons_H	SET Max_Code = @StartNum+@GenerateCount WHERE Doccode=@Doccode
	END