/*
begin tran
select * from icoupons where couponsbarcode='66911050004851'
select deductamout,CouponsBarcode from spickorderhd where doccode='RE20110502000001'
update icoupons set state='在库' where couponsbarcode='66911050004851'
update coupons_h set docstatus=0 where refcode='RE2王
begin tran
exec [sp_PostCouponsDoc] 'system','system',9146,'PS20121211000482','check'
 rollback
begin tran
*/

ALTER PROC [sp_PostCouponsDoc]
	@formid INT,
	@doccode VARCHAR(20),
	@RefFormid int=0,
	@RefCode varchar(50)='',
	@Stcode varchar(50)='',
	@optionID VARCHAR(500)='0'	,					--为0时表示正常执行,为Check时表示只执行判断,而不执行更新,所有的更新都被清除
	@CouponsStatus VARCHAR(50)='',
	@userCode VARCHAR(20)='',
	@userName VARCHAR(40)=''
AS
	BEGIN
		SET NOCOUNT ON;
		--SET XACT_ABORT ON;
/**************************************************************************************变量定义与初始化*****************************************************************************/
		DECLARE  @deductAmout money,@LinkDocInfo varchar(50),@linkDoc varchar(20),  @tips varchar(5000),	@msg VARCHAR(5000)
		DECLARE @TranCount INT,@DocStatus INT
		declare @refFormid1 int,@DocStatus1 int
		DECLARE @SourceMode VARCHAR(20),				--来源模式
				@CodeMode VARCHAR(20),						--编码模式
				@CodeLength INT,										--编码长度
				@PresentCount VARCHAR(20),						--赠送数量表达式
				@PresentMode VARCHAR(500),					--赠送数量模式
				@PresentMoney VARCHAR(500),					--赠送金额表达式
				@ExchangeCount VARCHAR(20),					--兑换数量表达式
				@ExchangeMode VARCHAR(500),				--兑换数量模式
				@ExchangeMoney VARCHAR(500),				--兑换金额表达式
 
				@SdorgID VARCHAR(50),
				@sql VARCHAR(8000)
 
		/*if object_id('tempdb.dbo.#CouponsDocData') is NULL
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
					BeginDate DATETIME,								--优惠券资料表中的起始有效期
					EndDate DATETIME,									--优惠券资料表中的终止有效期
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
		end*/
/********************************************************************************开始优惠券业务**************************************************************************/
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
/************************************************************************************优惠券退还开始**************************************************************************/
		--优惠券退货
		IF @formid IN(9211)
			BEGIN
				 SELECT @deductAmout=SUM(isnull(deductamout,0))     FROM Coupons_D cd WHERE cd.Doccode=@doccode
				UPDATE coupons_h 
					SET TotalDeductAmout = @deductAmout,
					@refFormid=coupons_h.RefFormid,@RefCode=coupons_h.RefCode,@Stcode=Stcode
				WHERE coupons_h.Doccode=@doccode
				print @doccode 
				--更新配件券状态
				UPDATE a 
					SET STATE=CASE 
										WHEN a.[State]='已赠' then    isnull(icg.PresentReturnState,'作废')
										WHEN a.[State]='已兑换' then isnull(icg.ReturnState,'作废')
									end,
					a.ReturnStcode=@Stcode,
					a.ReturnDoccode = @doccode,
					returndate=GETDATE(),
					a.ReturnFormID = 9211,
					Occupyed = 0,OccupyedDoccode = NULL
				FROM  iCoupons a   with(nolock),Coupons_D b   with(nolock),iCouponsGeneral icg WITH(NOLOCK)
				WHERE b.Doccode=@doccode
				AND b.couponsbarcode=a.CouponsBarcode
				AND icg.CouponsCode=a.CouponsCode
				--AND a.state IN('已赠','已兑换')
				/*IF @@ROWCOUNT=0
					BEGIN
						RAISERROR('此优惠券不存在或未赠送,或已作废!',16,1)
						return
					END*/
				--回填业务单据
				
				
				/*SELECT @refFormid=refformid,@refcode=refcode,@deductAmout=ch.TotalDeductAmout
				  FROM Coupons_H ch   with(nolock) WHERE ch.Doccode=@doccode*/
				  /**********************************************************回填业务单据********************************************************************/
				--优惠金额回填业务单据
				IF @refFormid IN(2420)
					BEGIN
						UPDATE sPickorderHD
						SET DeductAmout = @deductAmout
						WHERE DocCode=@refcode
						AND FormID=@refFormid              

						/*UPDATE spickorderitem SET done=1 WHERE doccode=@doccode
						--修改明细表
						update a
						set a.DeductAmout=b.DeductAmout,a.CouponsBarCode=b.CouponsBarCode,
						done=0
						from spickorderitem a WITH(NOLOCK) LEFT JOIN coupons_d b
						on a.doccode=@refcode
							and b.doccode=@doccode
							and a.matcode=b.matcode
							and a.rowid=b.RefRowID*/
					END
				IF @refFormid IN(9244)
					BEGIN
						UPDATE Unicom_Orders
						SET DeductAmout = @deductAmout
						WHERE DocCode=@refcode
						--AND FormID=@formid
					END
					if @refFormid in(4951)
					BEGIN
						
						update sPickorderHD
							set DeductAmout =@deductAmout
						 
						where sPickorderHD.DocCode=@refcode
						--更新串号
						update isa
							set isa.CouponsBarcode=NULL,isa.CouponsCode=NULL,Occupyed = 0,OccupyedDoc = NULL
						from iSeries isa with(nolock) inner join Coupons_D cd with(nolock)
						on isa.SeriesCode=cd.SeriesCode
						and cd.Doccode=@doccode
						
					END
				return
			END
/************************************************************************************优惠券退还结束**************************************************************************/
/************************************************************************************优惠券批发开始**************************************************************************/
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
/************************************************************************************优惠券批发结束**************************************************************************/
/************************************************************************************优惠券关联业务开始**************************************************************************/
 
		if @formid IN(9102,9146,2419,9237)
			BEGIN
				if @formid in(2419) 
						BEGIN
							select @refFormid1=sph.refformid,@DocStatus1=sph.DocStatus,@Stcode=sph.stcode
							from sPickorderHD sph with(nolock) where sph.DocCode=@doccode
							--如果有引用功能号,即是从套包单或开户单而来,则不做赠送
							 if  not exists(select 1 from spickorderitem a WITH(NOLOCK),sPickorderHD b with(nolock) where  a.doccode=b.doccode and 
							 a.doccode=@doccode 
							 and isnull(couponsbarcode,'')<>'' AND isnull(b.refformid,0)=0 ) 
								BEGIN
									return
								END
			 

							--如果不存在优惠券,就不用往下执行了
							IF NOT EXISTS(SELECT 1 FROM sPickorderitem s WITH(NOLOCK) WHERE s.DocCode=@doccode AND ISNULL(s.CouponsBarCode,'')!='' AND s.DocCode=@doccode)
								BEGIN
									return
								END
							--检查是否支持即时抵扣,即时抵扣是指赠送和抵扣在同一张单据上.也就是尚未赠送,处于在库状态.
							SELECT @msg='以下优惠券不支持即时抵扣，请检查！'+dbo.crlf()
						

						end
				if @formid in(9102,9146,9237)
					begin
						if NOT  exists(select 1 from unicom_orders b  with(nolock) left join unicom_orderdetails a   with(nolock) on a.doccode=b.doccode 
						where b.doccode=@doccode and (isnull(a.couponsbarcode,'')<>'' or isnull(b.matCouponsbarcode,'')<>'' ) )
							BEGIN
								return
							END

						--检查是否支持即时抵扣,即时抵扣是指赠送和抵扣在同一张单据上.也就是尚未赠送,处于在库状态.
						SELECT @msg='以下优惠券不支持即时抵扣，请检查！'+dbo.crlf()
						 
					END
				BEGIN TRY
					SELECT @TranCount=@@TRANCOUNT,@LinkDocInfo=NULL,@DocStatus=NULL
 
					--查找是否已经存在赠送单

					SELECT @linkdoc=doccode,@DocStatus=ch.DocStatus
					  FROM Coupons_H ch   with(nolock) WHERE ch.RefCode=@doccode AND ch.FormID=9201
					--如果没有,生成赠送单
					IF @@ROWCOUNT=0
						begin
							begin try

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
							if isnull(@linkDoc,'')!=''
								BEGIN
									begin try
										exec sp_PresentCoupons 9201,@linkdoc,@formid,@doccode,@Stcode,null,@optionID
									end try
									begin catch
										select @msg='优惠券赠送单据过帐失败.'+isnull(error_message(),'') +'错误发生于第'+convert(varchar(10),isnull(error_line(),0))+'行'
										raiserror(@msg,16,1)
										return
									end catch
								END
						END
					--如果有,而且单据状态为0,则过帐之
					ELSE IF @DocStatus=0
						begin
							begin try
								exec sp_PresentCoupons 9201,@linkdoc,@formid,@doccode,@Stcode,null,@optionID
							end try
							begin catch

								select @msg='优惠券赠送单据过帐失败.'+isnull(error_message(),'')+'错误发生于第'+convert(varchar(10),isnull(error_line(),0))+'行'
								raiserror(@msg,16,1)
								return
							end catch
						end
					--SELECT '赠送后',ic.* FROM Coupons_D cd,iCoupons ic  WHERE cd.Doccode=@linkdoc and cd.couponsbarcode=ic.couponsbarcode
					--修改单据状态
						UPDATE Coupons_H
							SET DocStatus = 1
						WHERE Doccode=@linkDoc
						AND FormID=9201
 
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
								exec sp_DeductCoupons  9207,@linkdoc,@formid,@doccode,@Stcode,null,@optionID
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
								exec sp_DeductCoupons 9207,@linkdoc,@formid,@doccode,@Stcode,null,@optionID
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
 
				END TRY
				BEGIN CATCH
 
					SELECT @msg='在过程'+ERROR_PROCEDURE()+'发生异常!'+char(10)+'错误原因:'+ERROR_MESSAGE()+char(10)+'错误发生在'+convert(varchar(10),error_line())+'行处.'+char(10)+'请与系统管理员联系!'
					RAISERROR(@msg,16,1)
					return
				END catch
 
			END
		---订货赠送优惠券
		IF @formid IN(6090)
			BEGIN
				set XACT_ABORT on;
				SELECT @linkDoc=doccode FROM Coupons_H ch WHERE ch.RefCode=@doccode AND ch.Formid=9207
				IF @@ROWCOUNT>0
					BEGIN
						--将优惠券单据过帐
						BEGIN TRY
							EXEC sp_PostCouponsDoc @userCode,@userName,9207,@linkDoc,'','使用中'
						END TRY
						BEGIN CATCH
							select @tips=dbo.getLastError('')
							raiserror(@tips,16,1)
							return
						END CATCH
						
						--更新优惠券兑换单状态
						UPDATE Coupons_H
							SET DocStatus = 1
						WHERE Doccode=@linkDoc
						--更新主服务器优惠券状态
 
						UPDATE c
						SET  
							[State] =ISNULL(NULLIF(@CouponsStatus,''), '已兑换'),						--更新优惠券状态,若传入的状态不为空,则使用传入的状态,否则使用默认的状态.
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
							DeducedMoney = b.DeductAmout ,
							DeducedDigit =b.Digit
						FROM Coupons_H a  with(nolock),Coupons_D b  with(nolock),dbo.iCoupons c  with(nolock)
						WHERE a.Doccode=b.Doccode
						AND b.CouponsBarCode=c.CouponsBarcode
						AND a.Doccode= @linkDoc
						AND c.[State] IN('已赠')
						IF @@ROWCOUNT=0
							BEGIN
								select @tips='无法兑换此优惠券,因为此优惠券尚未赠送或不存在'
								RAISERROR(@tips,16,1)
								return
							END
						--将数据插入优惠券流程表
						/*INSERT INTO URP11.JTURP.dbo.oSDOrgCouponsFlow
						  (
						    FlowInstanceID, SDorgID,stcode,refcode,refrowid, Matcode, Digit, Price, Couponsbarcode, CouponsCode, DeductAmount, 
						    FlowStatus, ModifyName, ModifyDoccode, ModifyDate,seriescode,remark
						  )
						SELECT @doccode, a.Stcode,a.Stcode,a.RefCode,cd.RefRowID, cd.Matcode, cd.Digit, cd.Price, cd.CouponsBarCode, cd.CouponsCode, cd.DeductAmout, 
						       '未完成',  @username, a.doccode, getdate(),cd.seriescode,a.remark
						FROM   Coupons_H a WITH(NOLOCK), Coupons_D cd WITH(NOLOCK)
						where a.Doccode=cd.Doccode
						and a.doccode=@linkDoc*/
					END
			END
		--送货单正式使用优惠券
		if @formid in(4950)
			BEGIN
 
				begin try
					--创建优惠券兑换单据
					exec sp_CreateCouponsDoc @formid,@doccode,9207,1,@linkdocinfo OUTPUT
					select @linkdoc=right(@linkdocinfo,16)
				end try
				begin catch
					select @msg='创建优惠券兑换单据失败.'+isnull(error_message(),'')
					raiserror(@msg,16,1)
					return
				end catch
			END
		--优惠券退还
		if @formid IN(2420,9244,4951)
			BEGIN
				BEGIN TRY
					--下面这句是因为在供货平台需要用到
					set XACT_ABORT on
					--生成退还单
					exec sp_CreateCouponsDoc @formid,@doccode,9211,1,@linkdocinfo output
					select @linkdoc=right(@linkdocinfo,16)
					--若未生成单据,则直接返回了.
					IF ISNULL(@linkdoc,'')='' return
 
					--退还单过账
					exec [sp_PostCouponsDoc]  9211,@linkDoc,@formid,@doccode,@Stcode,'',0,@userCode,@userName 
					/*UPDATE Coupons_H
						SET DocStatus = 1
					WHERE Doccode=@linkDoc*/
				END TRY
				BEGIN CATCH
					SELECT @msg= dbo.getLastError('优惠券退还失败.')
					 RAISERROR(@msg,16,1)
					return
				END catch
 
			END
/************************************************************************************优惠券关联业务结束**************************************************************************/
		
		return
	END