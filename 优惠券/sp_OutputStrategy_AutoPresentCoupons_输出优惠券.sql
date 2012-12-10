 /*
过程名称：sp_OutputStrategy_AutoPresentCoupons
功能：策略处理接口
参数：见声名
返回：
编写：三断笛
时间：2012-02-18
备注：
示例：
----------------------------------------------
*/
alter PROC [sp_OutputStrategy_AutoPresentCoupons]
	@FormID varchar(50),
	@Doccode VARCHAR(20),
	@FieldFormID varchar(10)='',					--字段映射功能号
	@StrategyGroup VARCHAR(20),				--策略组
	@ComputeType VARCHAR(50)='',			--计算类型：累加，覆盖
	@OutputType VARCHAR(50)='',				--输出类型：提示，写数据表
	@OutputTable VARCHAR(50)='',				--输出表
	@OutputFields VARCHAR(500)='',			--输出的字段
	@RowFlag VARCHAR(100)='',					--输出数据的行标志，与输入数据源相匹配
	@StrategyCode VARCHAR(20)='',			--策略编码
	@Optionid VARCHAR(100)='',					--扩展选项
	@UserCode VARCHAR(50)='',					--执行人
	@TerminalID VARCHAR(50)='',				--执行终端
	@Result XML='' output							--返回值
AS
	BEGIN
		SET NOCOUNT ON;
		DECLARE @sql VARCHAR(8000),@tips varchar(max)
		 DECLARE @Newdoccode VARCHAR(50),@cltcode VARCHAR(50),@cltname VARCHAR(50),@stcode VARCHAR(50),@stname VARCHAR(200),
		 @sdgroup VARCHAR(50),@sdgroupname VARCHAR(200)
		 declare @CouponsCode VARCHAR(50),@CouponsCount INT,@CouponsPrice MONEY
		 CREATE TABLE #Couponsbarcode(CouponsBarCode VARCHAR(50),CouponsCode varchar(50),CouponsName VARCHAR(50))
		 IF @FormID IN(9012,9146,9237)
			BEGIN
				SELECT @stcode=uo.stcode,@stname=uo.stname,@cltcode=uo.cltCode,@cltname=uo.cltName,
				@sdgroup=uo.sdgroup,@sdgroupname=uo.sdgroupname
				  FROM Unicom_Orders uo WITH(NOLOCK) WHERE uo.DocCode=@Doccode
				 IF @@ROWCOUNT=0
					BEGIN
						RAISERROR('单据不存在,无法自动赠送优惠券.',16,1)
						RETURN
					END
			END
		IF @formid IN(2419)
			BEGIN
				SELECT @stcode=uo.stcode,@stname=uo.stname,@cltcode=uo.cltCode,@cltname=uo.cltName,
				@sdgroup=uo.sdgroup,@sdgroupname=uo.sdgroupname
				FROM sPickorderHD  uo WITH(NOLOCK) WHERE uo.DocCode=@Doccode
				 IF @@ROWCOUNT=0
					BEGIN
						RAISERROR('单据不存在,无法自动赠送优惠券.',16,1)
						RETURN
					END
			END
		--生成优惠券赠送单据
		 EXEC sp_newdoccode 9201,'',@Newdoccode OUTPUT
		 INSERT INTO Coupons_H(Doccode,FormID,docdate,RefFormid,RefCode,Stcode,cltCode,DocStatus,DocType,
		 EnterName,EnterDate,PostName,PostDate,sdgroup,sdgroupname,Remark)
		 SELECT @Newdoccode,9201,convert(varchar(10),getdate(),120),@formid,@Doccode,@stcode,@cltcode,1,'优惠券赠送',@usercode,
		 convert(varchar(20),getdate(),120), @UserCode ,convert(varchar(20),getdate(),120),@sdgroup,@sdgroupname,'系统自动赠送优惠券.'
		--生成优惠券数据
		DECLARE cur_coupons CURSOR READ_ONLY FORWARD_ONLY  FOR
		SELECT strategycode,convert(int,StratetyValue)
		FROM #Strategy
		OPEN cur_coupons
		FETCH NEXT FROM cur_coupons INTO @CouponsCode,@CouponsCount
		WHILE @@FETCH_STATUS=0
			BEGIN
				EXEC sp_GenerateCouponsbarcode @CouponsCode,'',@CouponsCount,0,1
				FETCH NEXT FROM cur_coupons INTO @CouponsCode,@CouponsCount
			END
		CLOSE cur_coupons
		DEALLOCATE cur_coupons
		--将数据插入优惠券赠送明细
		IF NOT EXISTS(SELECT 1 FROM #Couponsbarcode)
			BEGIN
				RAISERROR('未生成任何优惠券',16,1)
				return
			END
		--插入明细
		INSERT INTO Coupons_D(Doccode,Docitem,RowID,CouponsBarCode,CouponsCode,CouponsName,CouponsGroup,couponsGroupName,Price)
		SELECT @Newdoccode,ROW_NUMBER() OVER (ORDER BY (SELECT 1)),NEWID(),
		a.CouponsBarCode,b.CouponsCode,b.CouponsName,b.GroupCode,b.GroupName,b.Price
		FROM #Couponsbarcode a,iCouponsGeneral b WITH(NOLOCK)
		WHERE a.CouponsCode=b.CouponsCode
		--再插入优惠券表
		INSERT INTO iCoupons(CouponsBarcode,CouponsCode,stCode,[State],InDoccode,InDate,InStcode,InStName,
		Price,Valid,Remark,ValidDate,PresentDate,PresentDoccode,PresentFormid,PresentStcode,CouponsOWNER,
		OutDate,OutDoccode,OutStcode,OutStName,OutFormID)
		SELECT a.CouponsBarCode,b.CouponsCode,@stcode,'已赠',@newdoccode,getdate(),@stcode,@stname,
		b.Price,1,'系统自动赠送',dateadd(DAY,1,GETDATE()),getdate(),@doccode,@formid,@stcode,
		CASE   b.CouponsOWNER WHEN '客户' then @cltcode when '仓库' then @stcode when '注册用户' then @sdgroup end,
		getdate(),@Newdoccode,@stcode,@stname,9201
		FROM #Couponsbarcode a,iCouponsGeneral b WITH(NOLOCK)
		WHERE a.CouponsCode=b.CouponsCode
 
		return
	END
	 