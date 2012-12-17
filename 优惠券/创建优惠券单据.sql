/*
* 过程名称:[sp_CreateCouponsDoc]
* 功能描述:创建优惠券单据
* 参数:见声明
* 编写:三断笛
* 时间:2011-03-28
* 备注:无
* begin tran exec sp_createcouponsdoc 2419,'RE20110725000736',9201,0 rollback
* select * from coupons_d where doccode='QTH2011051000002'
*/
ALTER PROC [dbo].[sp_CreateCouponsDoc]
	@FormID	INT,
	@doccode VARCHAR(20),
	@optionID	INT=9201,
	@DocStatus INT=0,
	@LinkDocInfo VARCHAR(200)='' output
AS
	BEGIN
		SET NOCOUNT ON
		DECLARE @newDoccode VARCHAR(20)
		DECLARE @RefFormid INT,@Refcode VARCHAR(50),@stcode VARCHAR(50),@stname VARCHAR(200),
		@CustomerID VARCHAR(50),@Rowcount INT,@DocDate DATETIME,@Remark VARCHAR(500),
		@Sdgroup varchar(50),@sdgroupname VARCHAR(200),@CustomerName VARCHAR(200)
		SET NOCOUNT ON
		--优惠券赠送
		IF @optionID=9201
			BEGIN
				SELECT @newDoccode=doccode FROM Coupons_H ch  WITH(NOLOCK) WHERE ch.RefFormid=@FormID AND ch.RefCode=@doccode AND ch.FormID=@optionID
				IF @newDoccode IS NULL 	
					begin
						EXEC sp_newdoccode @formid = 9201, @opid = '', @doccode = @newdoccode OUTPUT
						--select * from coupons_h
						
						IF @FormID in(2419,2420)
							BEGIN
								--如果单据已经确认,则不再生成兑换单,需要注意的是,此处还要判断传入的@docstatus值,当为0时说明是从功能链接中操作的,当为1时,说明是单据确认时操作
								--因为在过帐时,先修改单据状态,再过帐,也就是说,在过帐时,此时的单据状态值必为200.
								--倘若是在功能链接中执行此操作,如果单据已确认,再传入@docstatus值为0则必然无法创建新单据,这样处理才正确.
								--后面同样有几处这样的判断,请注意.
								IF EXISTS(SELECT 1 FROM sPickorderHD sph WHERE sph.DocCode=@doccode AND sph.DocStatus=200 AND @DocStatus=0)
									BEGIN
										RAISERROR('业务单据已确认,无法再赠送优惠券!',16,1)
										return
									END
								INSERT INTO coupons_h ( Doccode, DocDate,  DocStatus, 
									   DocType, FormID, RefFormid, RefCode, Remark, 
									   Stcode, stName, sdgroup, sdgroupname, EnterName, 
									   EnterDate,cltCode,cltName )
								SELECT @newDoccode, sph.DocDate, @DocStatus,
									   '优惠券赠送', @optionid, @formid, @doccode, 
									   hdtext, stcode, stname, sdgroup, sdgroupname, 
									   sdgroupname, sph.DocDate,sph.cltCode,sph.cltName
								FROM   sPickorderHD sph WITH(NOLOCK)
								WHERE  sph.DocCode=@doccode
								
								INSERT INTO Coupons_D ( Doccode, Docitem, RowID, CouponsBarCode, CouponsCode, 
								       CouponsName, Remark, Price, UseImmediate, 
								       DeductAmout, Matcode, MatName, Digit, 
								       SeriesCode, Amount, RefRowID, RefDocItem, 
								       ValidDate, CouponsGroup, couponsGroupName )
								       SELECT @newDoccode,ROW_NUMBER() OVER (ORDER BY @newdoccode),NEWID(),sp.CouponsBarCode, b.CouponsCode,c.CouponsName,
								       sp.usertxt2,b.Price,NULL,sp.DeductAmout,sp.MatCode,sp.MatName,sp.Digit,
								       sp.seriesCode,sp.totalmoney,sp.rowid,sp.DocItem,b.ValidDate,c.GroupCode,c.GroupName
								       FROM sPickorderitem sp  WITH(NOLOCK),iCoupons  b  WITH(NOLOCK),iCouponsGeneral c  WITH(NOLOCK)
								       WHERE isnull(sp.CouponsBarCode,'')<>''
								       AND sp.CouponsBarCode=b.CouponsBarcode
										AND b.CouponsCode=c.CouponsCode
										AND sp.DocCode=@doccode
							END
						IF @FormID IN(9102,9146)
							BEGIN
								--IF EXISTS(SELECT 1 FROM Unicom_Orders  sph WHERE sph.DocCode='PS20110509000037' AND sph.DocStatus=0) return
								--如果单据已经确认,则不再生成兑换单
								IF EXISTS(SELECT 1 FROM Unicom_Orders sph WHERE sph.DocCode=@doccode AND sph.DocStatus=100 AND @DocStatus=0)
									BEGIN
										RAISERROR('业务单据已确认,无法再赠送优惠券!',16,1)
										return
									END
								INSERT INTO coupons_h ( Doccode, DocDate,  DocStatus, 
									   DocType, FormID, RefFormid, RefCode, Remark, 
									   Stcode, stName, sdgroup, sdgroupname, EnterName, 
									   EnterDate,cltCode,cltName )
								SELECT @newDoccode, sph.DocDate, @DocStatus,
									   '优惠券赠送', @optionid, @formid, @doccode, 
									   hdtext, stcode, stname, sdgroup, sdgroupname, 
									   sdgroupname,   sph.DocDate,sph.cltCode,sph.cltName
								FROM Unicom_Orders   sph  WITH(NOLOCK)
								WHERE  sph.DocCode=@doccode
								;with cte(seriescode,couponsbarcode,couponscode,deductamout,matcode,matname,digit,remark,totalmoney,rowid,docitem) AS (
									select uo.SeriesCode, uo.matCouponsbarcode,uo.matCouponsCode,uo.matDeductAmount,
									matcode,uo.MatName,1,uo.HDText,uo.MatMoney,uo.DocCode,0
									from Unicom_Orders uo with(nolock)
									where uo.DocCode=@doccode
									union all
									select uod.seriesCode, uod.CouponsBarCode,null,uod.DeductAmout,uod.MatCode,uod.MatName,
									uod.Digit,usertxt2,uod.totalmoney,uod.rowid,uod.DocItem
									from Unicom_OrderDetails uod with(nolock)
									where uod.DocCode=@doccode
								)
								INSERT INTO Coupons_D ( Doccode, Docitem, RowID, CouponsBarCode, CouponsCode, 
								       CouponsName, Remark, Price, UseImmediate, 
								       DeductAmout, Matcode, MatName, Digit, 
								       SeriesCode, Amount, RefRowID, RefDocItem, 
								       ValidDate, CouponsGroup, couponsGroupName )
								SELECT @newDoccode,ROW_NUMBER() OVER (ORDER BY @newdoccode),NEWID(),sp.CouponsBarCode, b.CouponsCode,c.CouponsName,
								       sp.remark,b.Price,NULL,sp.DeductAmout,sp.MatCode,sp.MatName,sp.Digit,
								       sp.seriesCode,sp.totalmoney,sp.rowid,sp.DocItem,b.ValidDate,c.GroupCode,c.GroupName
								       FROM cte  sp  WITH(NOLOCK),iCoupons  b  WITH(NOLOCK),iCouponsGeneral c  WITH(NOLOCK)
								       WHERE isnull(sp.CouponsBarCode,'')<>''
								       AND sp.CouponsBarCode=b.CouponsBarcode
										AND b.CouponsCode=c.CouponsCode
							END
					end
			END
		--优惠券兑换
		IF @optionID=9207
			BEGIN
				SELECT @newDoccode=doccode FROM Coupons_H ch  WITH(NOLOCK) WHERE ch.RefFormid=@FormID AND ch.RefCode=@doccode AND formid=@optionID
				IF @@ROWCOUNT=0 	
					begin
						EXEC sp_newdoccode @formid = 9207, @opid = '', @doccode = @newdoccode OUTPUT
						--select * from coupons_h
						--零售业务生成兑换单
						IF @FormID in(2419,2420)
							BEGIN
								--IF EXISTS(SELECT 1 FROM sPickorderHD sph WHERE sph.DocCode=@doccode AND sph.DocStatus=0) return
								--如果单据已经确认,则不再生成兑换单
								IF EXISTS(SELECT 1 FROM sPickorderHD sph  WITH(NOLOCK) WHERE sph.DocCode=@doccode AND sph.DocStatus=200 AND @DocStatus=0)
									BEGIN
										RAISERROR('业务单据已确认,无法再兑换优惠券!',16,1)
										return
									END
								INSERT INTO coupons_h ( Doccode, DocDate, DocStatus, 
									   DocType, FormID, RefFormid, RefCode, Remark, 
									   Stcode, stName, sdgroup, sdgroupname, EnterName, 
									   EnterDate,cltCode,cltName )
								SELECT @newDoccode,  sph.DocDate,@DocStatus,
									   '优惠券兑换', @optionid, @formid, @doccode, 
									   hdtext, stcode, stname, sdgroup, sdgroupname, 
									   sdgroupname, sph.DocDate,sph.cltCode,sph.cltName
								FROM   sPickorderHD sph  WITH(NOLOCK)
								WHERE  sph.DocCode=@doccode
								INSERT INTO Coupons_D ( Doccode, Docitem, RowID, CouponsBarCode, CouponsCode, 
								       CouponsName, Remark, Price, UseImmediate, 
								       DeductAmout, Matcode, MatName, Digit, 
								       SeriesCode, Amount, RefRowID, RefDocItem, 
								       ValidDate, CouponsGroup, couponsGroupName )
								       SELECT @newDoccode,ROW_NUMBER() OVER (ORDER BY @newdoccode),NEWID(),sp.CouponsBarCode, b.CouponsCode,c.CouponsName,
								       sp.usertxt2,b.Price,NULL,sp.DeductAmout,sp.MatCode,sp.MatName,sp.Digit,
								       sp.seriesCode,sp.totalmoney,sp.rowid,sp.DocItem,b.ValidDate,c.GroupCode,c.GroupName
								       FROM sPickorderitem sp  WITH(NOLOCK),iCoupons  b  WITH(NOLOCK),iCouponsGeneral c  WITH(NOLOCK)
								       WHERE isnull(sp.CouponsBarCode,'')<>''
								       AND sp.CouponsBarCode=b.CouponsBarcode
										AND b.CouponsCode=c.CouponsCode
										AND sp.DocCode=@doccode
							END
						--从运营商业务生成兑换单
						IF @FormID IN(9102,9146)
							BEGIN
								--IF EXISTS(SELECT 1 FROM Unicom_Orders  sph WHERE sph.DocCode=@doccode AND sph.DocStatus=0) return
								--如果单据已经确认,则不再生成兑换单
								IF EXISTS(SELECT 1 FROM Unicom_Orders sph WITH (NOLOCK) WHERE sph.DocCode=@doccode AND sph.DocStatus=100 AND @DocStatus=0 )
									BEGIN
										RAISERROR('业务单据已确认,无法再兑换优惠券!',16,1)
										return
									END
								INSERT INTO coupons_h ( Doccode, DocDate, DocStatus, 
									   DocType, FormID, RefFormid, RefCode, Remark, 
									   Stcode, stName, sdgroup, sdgroupname, EnterName, 
									   EnterDate,cltCode,cltName )
								SELECT @newDoccode, sph.DocDate, @DocStatus,
									   '优惠券兑换', @optionid, @formid, @doccode, 
									   hdtext, stcode, stname, sdgroup, sdgroupname, 
									   sdgroupname, sph.DocDate,sph.cltCode,sph.cltName
								FROM Unicom_Orders   sph  WITH(NOLOCK)
								WHERE  sph.DocCode=@doccode
								;with cte(seriescode,couponsbarcode,couponscode,deductamout,matcode,matname,digit,remark,totalmoney,rowid,docitem) AS (
									select uo.SeriesCode, uo.matCouponsbarcode,uo.matCouponsCode,uo.matDeductAmount,
									matcode,uo.MatName,1,uo.HDText,uo.MatMoney,uo.DocCode,0
									from Unicom_Orders uo with(nolock)
									where uo.DocCode=@doccode
									union all
									select uod.seriesCode, uod.CouponsBarCode,null,uod.DeductAmout,uod.MatCode,uod.MatName,
									uod.Digit,usertxt2,uod.totalmoney,uod.rowid,uod.DocItem
									from Unicom_OrderDetails uod with(nolock)
									where uod.DocCode=@doccode
								)
								INSERT INTO Coupons_D ( Doccode, Docitem, RowID, CouponsBarCode, CouponsCode, 
								       CouponsName, Remark, Price, UseImmediate, 
								       DeductAmout, Matcode, MatName, Digit, 
								       SeriesCode, Amount, RefRowID, RefDocItem, 
								       ValidDate, CouponsGroup, couponsGroupName )
								SELECT @newDoccode,ROW_NUMBER() OVER (ORDER BY @newdoccode),NEWID(),sp.CouponsBarCode, b.CouponsCode,c.CouponsName,
								       sp.remark,b.Price,NULL,sp.DeductAmout,sp.MatCode,sp.MatName,sp.Digit,
								       sp.seriesCode,sp.totalmoney,sp.rowid,sp.DocItem,b.ValidDate,c.GroupCode,c.GroupName
								       FROM cte  sp  WITH(NOLOCK),iCoupons  b  WITH(NOLOCK),iCouponsGeneral c  WITH(NOLOCK)
								       WHERE isnull(sp.CouponsBarCode,'')<>''
								       AND sp.CouponsBarCode=b.CouponsBarcode
										AND b.CouponsCode=c.CouponsCode
							END
						--从优惠券赠送单生成兑换单
						IF @FormID IN(9201)
							BEGIN
								--如果单据已经确认,则不再生成兑换单
								IF EXISTS(SELECT 1 FROM coupons_h sph WHERE sph.DocCode=@doccode AND sph.DocStatus=100  AND @DocStatus=0)
									BEGIN
										RAISERROR('业务单据已确认,无法再兑换优惠券!',16,1)
										return
									END
								INSERT INTO coupons_h ( Doccode, DocDate, DocStatus, 
									   DocType, FormID, RefFormid, RefCode, Remark, 
									   Stcode, stName, sdgroup, sdgroupname, EnterName, 
									   EnterDate,TotalDeductAmout,cltCode,cltName )
								SELECT @newDoccode,  sph.DocDate, @DocStatus,
									   '优惠券兑换', @optionid, refformid, refcode, 
									   remark, stcode, stname, sdgroup, sdgroupname, 
									   sdgroupname,  sph.DocDate,sph.TotalDeductAmout,cltCode,cltName
								FROM coupons_h   sph  WITH(NOLOCK)
								WHERE  sph.DocCode=@doccode
								INSERT INTO Coupons_D ( Doccode, Docitem, RowID, CouponsBarCode, CouponsCode, 
								       CouponsName, Remark, Price, 
								       DeductAmout, Matcode, MatName, Digit, 
								       SeriesCode, Amount, RefRowID, RefDocItem)
								SELECT @newDoccode,ROW_NUMBER() OVER(ORDER BY @newDoccode),NEWID(),cd.CouponsBarCode,cd.CouponsCode,
								cd.CouponsName,cd.Remark,cd.Price,
								cd.DeductAmout,cd.Matcode,cd.MatName,cd.Digit,
								cd.SeriesCode,cd.Amount,cd.RefRowID,cd.RefDocItem
								FROM Coupons_D cd  WITH(NOLOCK) WHERE cd.Doccode=@doccode
								AND cd.UseImmediate=1
							END
						--订货使用优惠券
						IF @FormID IN(6090)
							BEGIN
								--如果单据已经确认,则不再生成兑换单
								IF EXISTS(SELECT 1 FROM ord_shopbestgoodsdoc sph  WITH(NOLOCK) WHERE sph.DocCode=@doccode AND sph.DocStatus=100  AND @DocStatus=0)
									BEGIN
										RAISERROR('业务单据已确认,无法再兑换优惠券!',16,1)
										return
									END
								INSERT INTO coupons_h ( Doccode, DocDate, DocStatus, 
									   DocType, FormID, RefFormid, RefCode, Remark, 
									   Stcode, stName,  EnterDate )
								SELECT @newDoccode,  sph.DocDate,@DocStatus,
									   '优惠券兑换', @optionid, @formid, @doccode, 
									   hdtext, stcode, stname, sph.DocDate 
								FROM   ord_shopbestgoodsdoc sph  WITH(NOLOCK)
								WHERE  sph.DocCode=@doccode
								 
							END
					end
			END
			--优惠券退还
			IF @optionID=9211
				BEGIN
					
					--检索赠送单的退货单
					SELECT @newDoccode=doccode FROM Coupons_H ch  WITH(NOLOCK) WHERE ch.RefFormid=@formid AND ch.RefCode=@doccode AND formid=9211
					IF @@Rowcount=0
						BEGIN
							EXEC sp_newdoccode @formid = 9211, @opid = '', @doccode = @newdoccode OUTPUT
							IF @FormID IN(2420)
								BEGIN
									SELECT @RefFormid=2419,@Refcode=sph.ClearDocCode,@stcode=sph.stcode,
									@stname=sph.stname,@CustomerID=sph.CustomerID,@DocDate=sph.DocDate,@remark=sph.prdno,
									@CustomerName=sph.cltName,@Sdgroup=sph.sdgroup,@sdgroupname=sph.sdgroupname
									FROM sPickorderHD sph WITH(NOLOCK)
									WHERE sph.DocCode=@doccode
								END
							IF @FormID IN(9244)
								BEGIN
									SELECT @RefFormid=sph.refformid,@Refcode=sph.refcode,@stcode=sph.stcode,
									@stname=sph.stname,@CustomerID=sph.CustomerID,@DocDate=sph.DocDate,@remark=HDText,
									@CustomerName=sph.cltName,@Sdgroup=sph.sdgroup,@sdgroupname=sph.sdgroupname
									FROM Unicom_Orders   sph WITH(NOLOCK)
									WHERE sph.DocCode=@doccode
								END
							--判断是否有赠送优惠券
							IF EXISTS(SELECT 1 FROM Coupons_H ch WITH(NOLOCK) WHERE ch.FormID=9201 AND  ch.RefCode=@Refcode)
								BEGIN
									--插入表头
									INSERT INTO coupons_h ( Doccode, DocDate,  DocStatus, 
										   DocType, FormID, RefFormid, RefCode, Remark, 
										   Stcode, stName, sdgroup, sdgroupname, EnterName, 
										   EnterDate,Reason,cltCode,cltName )
									SELECT @newDoccode,  @DocDate,@DocStatus,
										   '优惠券退还', @optionid, @formid, @doccode, 
										   @Remark, @stcode, @stname, @sdgroup, @sdgroupname, 
										   @sdgroupname, convert(varchar(20), GETDATE()),@REMARK,@Customerid,@CustomerName
										 --插入明细表,直接
										INSERT INTO Coupons_D ( Doccode, Docitem, RowID, CouponsBarCode, CouponsCode, 
											   CouponsName, Price, 
											   ic.DeductAmout, Matcode, MatName, Digit, 
											   SeriesCode, Amount, RefRowID, RefDocItem,UseImmediate)
										SELECT @newDoccode,ROW_NUMBER() OVER(ORDER BY @newDoccode),NEWID(),cd.CouponsBarCode,cd.CouponsCode,
										cd.CouponsName,cd.Price,
										cd.DeductAmout,cd.Matcode,cd.MatName,cd.Digit,
										cd.SeriesCode,cd.Amount,cd.rowid,cd.DocItem,1
										FROM Coupons_H  sp   WITH(NOLOCK),Coupons_D cd WITH(NOLOCK)
										WHERE sp.RefCode=@RefCode
										AND sp.FormID=9201
										AND sp.Doccode=cd.Doccode
								END
							ELSE
								BEGIN
									set @LinkDocInfo=''
									return
								END
						end
				END
		set @LinkDocInfo=CONVERT(VARCHAR(10),@optionID)+';5;'+@newDoccode
		return
	END
	 







