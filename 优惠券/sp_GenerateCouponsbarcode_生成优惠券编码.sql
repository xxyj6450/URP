/*
过程名称:sp_GenerateCouponsbarcode
返回值:无
功能:生成优惠券序号,并将序号回写至入库单
编写:三断笛
时间:2012-05-07
示例:exec [sp_GenerateCouponsbarcode] '1001','QCK2012050800002',100,-1
备注:生成时会自动删除单据上原有优惠券数据.只有当单据确认时才更新当前优惠券最大编码.
以下是编码模式
1.前缀+日期+序号+校验位
2.前缀+日期+序号
3.前缀+序号+校验位
4.前缀+序号
5.无规则
校验位采用LUHN算法
*/
 
alter PROC [dbo].[sp_GenerateCouponsbarcode]
	@CouponsCode VARCHAR(50),				--待生成编码的优惠券
	@Doccode VARCHAR(20),					--数据将插入的单号
	@GenerateCount INT=100,					--生成的数量
	@Basedigit INT=0,						--起始序号,若为0,则从当前的最大值开始,否则从此序号开始
	@ReserverDoc BIT=1							--是否保持单据原有内容
AS
	BEGIN
		SET NOCOUNT ON;
		--变量定义
		DECLARE @Prefix VARCHAR(20),@CodeMode AS VARCHAR(6),@Length INT,@StartNum INT,@Rowcount INT,
		@MaxDate DATETIME,@Now DATETIME,@CouponsName VARCHAR(200),@tips VARCHAR(200),@bitHasMaxcode bit
		--初始化
		SELECT @StartNum=0,@MaxDate='1900-01-01',@Now=CONVERT(VARCHAR(10),GETDATE(),120),@bitHasMaxcode=1
		IF @Basedigit<0
			BEGIN
				RAISERROR('基数BaseDigit不能小于0,请联系系统管理员.',16,1)
				RETURN 0
			END
		--取出优惠券基本信息
		SELECT @Prefix=isnull(ig.prefix,''),@CodeMode=ig.CodeMode,@Length=ig.CodeLength,@CouponsName=ig.CouponsName
		  FROM iCouponsGeneral ig WITH(NOLOCK) WHERE ig.CouponsCode=@CouponsCode
		 IF @@ROWCOUNT=0
			BEGIN
				RAISERROR('优惠券不存在,无法生成编码.',16,1)
				RETURN 0
			END
		--检查参数
		IF isnull(@GenerateCount,0)<=0 OR isnull(@GenerateCount,0)>10000
			BEGIN
				RAISERROR('生成编码的数量必须在1至10000之间!',16,1)
				RETURN 0
			END
 		/*
			取出最大长度,可能有以下情况
			1.对于编码模式为1或2时,取出最近日期的最大序号.若最近日期为空(有可能是首次使用),或小于当前日期,则当最大日期修改为本日,最大序号为0
			2.对于编码模式为3或4时,取出最大序号,若最大序号为空(首次使用),则最大序号为0
			3.当
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
		 
		--若最大日期小于当前日期,则将最大日期置为当前日期,并将起始数值重置0
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
		--若基数不为0,且基数小于最大数,则会出现编码重复,抛出异常
		IF @Basedigit!=0 AND @Basedigit<@StartNum
			BEGIN
				RAISERROR('起始序号比当前最大序号小,可能出现重复,请重新输入起始序号,或输入0',16,1)
				return
			END
		IF @Basedigit!=0 AND @Basedigit>=@StartNum
			BEGIN
				SELECT @StartNum=@Basedigit+@StartNum
			END
		 PRINT @StartNum
		--清除原有数据
		IF ISNULL(@ReserverDoc,0)=0 AND @Doccode!='' 		DELETE FROM Coupons_D WHERE Doccode=@Doccode
		--下面开始生成数据
		IF @CodeMode IN('1')
			BEGIN
				IF @Length<LEN(@Prefix)+9+4
					BEGIN
						SELECT @tips='优惠券长度设置过短,不得少于'+CONVERT(VARCHAR(200),len(@Prefix)+13)+'位.'
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
						SELECT @tips='优惠券长度设置过短,不得少于'+CONVERT(VARCHAR(200),len(@Prefix)+12)+'位.'
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
						SELECT @tips='优惠券长度设置过短,不得少于'+CONVERT(VARCHAR(200),len(@Prefix)+5)+'位.'
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
						SELECT @tips='优惠券长度设置太短,不得少于'+CONVERT(VARCHAR(200),len(@Prefix)+4)+'位.'
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
				RAISERROR('该优惠券不能自动生成编码!',16,1)
				return
			END
		--更新最大值
		IF @Doccode!='' 	UPDATE Coupons_H	SET Max_Code = @StartNum+@GenerateCount WHERE Doccode=@Doccode
	END