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
		@CustomerID VARCHAR(50),@Rowcount INT,@DocDate DATETIME,@Remark VARCHAR(500),@totalmoney money,
		@Sdgroup varchar(50),@sdgroupname VARCHAR(200),@CustomerName VARCHAR(200),@msg varchar(500),
		@FlowInstanceID varchar(50)
		declare @table table(
 
			couponsbarcode varchar(50)
			)
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
						IF @FormID IN(9102,9146,9237)
							BEGIN
								--IF EXISTS(SELECT 1 FROM Unicom_Orders  sph WHERE sph.DocCode='PS20110509000037' AND sph.DocStatus=0) return
								--如果单据已经确认,则不再生成兑换单
								IF EXISTS(SELECT 1 FROM Unicom_Orders sph WHERE sph.DocCode=@doccode AND sph.DocStatus=100 AND @DocStatus=0)
									BEGIN
										RAISERROR('业务单据已确认,无法再赠送优惠券!',16,1)
										return
									END
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
										and b.State='在库'
								if @@ROWCOUNT=0 return
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
						IF @FormID IN(9102,9146,9237)
							BEGIN
								--IF EXISTS(SELECT 1 FROM Unicom_Orders  sph WHERE sph.DocCode=@doccode AND sph.DocStatus=0) return
								--如果单据已经确认,则不再生成兑换单
								IF EXISTS(SELECT 1 FROM Unicom_Orders sph WITH (NOLOCK) WHERE sph.DocCode=@doccode AND sph.DocStatus=100 AND @DocStatus=0 )
									BEGIN
										RAISERROR('业务单据已确认,无法再兑换优惠券!',16,1)
										return
									END
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
										and b.State='已赠'
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
						--送货单自动处理优惠券
						if @FormID in(4950)
							BEGIN
								--取出单据信息
								select @Refcode=usertxt1,@stcode=sph.stcode,@stname =sph.stname,@DocDate=sph.DocDate,@Remark=sph.HDText
								  from sPickorderHD sph with(nolock) 
								where sph.DocCode=@doccode
								--若指令单不存在,则退出
								if isnull(@Refcode,'')=''	return
								select @FlowInstanceID=usertxt1
								from imatdoc_h ih with(nolock) where ih.DocCode=@Refcode
								and ih.FormID=6052
								--若不是加盟商订货单,则退出
								if  isnull(@FlowInstanceID,'') not  like 'DD%' return
								--若没有未使用的优惠券,则退出
								if not exists(select 1 from oSDOrgCouponsFlow oscf with(nolock) where oscf.FlowInstanceID=@FlowInstanceID and oscf.FlowStatus='未完成')
									BEGIN
										return
									END
								--将处理串号中的串号展开
								;with cteSeries as(
									select row_number() OVER (partition by b.MatCode order by b.docitem  ) as id,
									b.seriescode,b.matcode,a.refCode as doccode
									from iseriesloghd a with(nolock) inner join iserieslogitem b on a.DocCode=b.doccode
									where a.refCode=@doccode
									)
								--将送货单商品信息按数量展开,得到的结果是每种商品,每个数量一行记录,每行有一个序号.
								,cteDoc(id,matcode,matname,digit,price,rowid,doccode) as(
									select row_number() OVER (partition by sp.MatCode order by sp.docitem  ) as id,
									sp.MatCode,sp.MatName,sp.digit,sp.price,sp.rowid,sp.DocCode
									from sPickorderitem sp with(nolock) inner join Numbers n with(nolock) on sp.Digit>=n.digit
									where sp.DocCode=@doccode
									)
								--再将上述两个CTE进行整合.并不是所有的商品都有串号,所以要用LEFT JOIN,并且可以确定的是,有串号的商品,商品数量和串号数量必然相等.
								,cteDoc_Series(ID,Seriescode,matcode,matname,digit,price,rowid) as(
									select a.id,b.seriescode,a.matcode,a.matname,a.digit,a.price,a.rowid
									from ctedoc a left join cteSeries b on a.doccode=b.doccode and a.id=b.id and a.matcode=b.matcode 
									)
								--将优惠券编号,得到的结果是,每个商品所对应的优惠券,都有一个序号.
								,cteCoupons(id,FlowInstanceID,matcode,couponsbarcode,couponscode,deductamount)as(
									select row_number() OVER ( partition by a.Matcode  order by a.Couponsbarcode) as id,
									a.FlowInstanceID, a.Matcode,
									a.Couponsbarcode,a.CouponsCode,a.DeductAmount
									from oSDOrgCouponsFlow a with(nolock)
									where a.FlowInstanceID=@FlowInstanceID
									and a.FlowStatus='未完成'
								)
								--将上面两步得到的结果,用ID和商品编码关联,即可得每个商品所使用的优惠券.
								INSERT INTO Coupons_D ( Doccode, Docitem, RowID, CouponsBarCode, CouponsCode, 
							   CouponsName, Remark, Price, UseImmediate, 
							   DeductAmout, Matcode, MatName, Digit, 
							   SeriesCode, Amount, RefRowID, RefDocItem, 
							   ValidDate, CouponsGroup, couponsGroupName )
							   SELECT @newDoccode,ROW_NUMBER() OVER (ORDER BY @newdoccode),NEWID(),sp.CouponsBarCode, b.CouponsCode,c.CouponsName,
							   NULL,sp1.Price,NULL,sp.DeductAmount,sp1.MatCode,NULL,sp1.Digit,
							   sp1.seriescode,sp.DeductAmount,sp1.rowid,NULL,b.ValidDate,c.GroupCode,c.GroupName
							   FROM  cteCoupons sp WITH(NOLOCK) ,iCoupons  b  WITH(NOLOCK),
							   iCouponsGeneral c  WITH(NOLOCK),cteDoc_Series sp1 with(nolock)
							   WHERE sp.FlowInstanceID=@FlowInstanceID
							   and sp.Couponsbarcode=b.CouponsBarcode
							   and b.CouponsCode=c.CouponsCode
							   and b.State='使用中'
							   and sp1.MatCode=sp.Matcode
							   and sp.id=sp1.id
								if @@ROWCOUNT>0
									BEGIN
										insert into	coupons_h ( Doccode, DocDate, DocStatus, 
									   DocType, FormID, RefFormid, RefCode, Remark, 
									   Stcode, stName,  EnterDate )
										SELECT @newDoccode,  @DocDate,@DocStatus,
									   '优惠券兑换', @optionid, @formid, @doccode, 
									   @remark,@stcode, @stname, @DocDate
									   begin try
											--优惠券兑换单过帐
											update ic
												set ic.State='已兑换',
												ic.DeductAmout=cd.DeductAmout,
												ic.DeducedMatcode=cd.Matcode,
												ic.DeducedMatName=cd.MatName,
												ic.DeducedDigit=cd.Digit,
												ic.DeducedDate=getdate(),
												ic.DeducedDoccode=cd.Doccode,
												ic.DeducedSeriescode=cd.SeriesCode						--将优惠券与串号绑定
											--output deleted.CouponsBarcode into @table
											from iCoupons ic with(nolock),Coupons_D cd with(nolock)
											where ic.CouponsBarcode=cd.CouponsBarCode
											and cd.Doccode=@doccode
											and ic.State='使用中'
											--更新优惠券流程信息
											if @@ROWCOUNT>0
												BEGIN
													update a
														set a.FlowStatus='已完成',
														a.ModifyName=@sdgroupname,
														a.ModifyDoccode=@doccode,
														a.ModifyDate=getdate()
													from  oSDOrgCouponsFlow a with(nolock),Coupons_D cd with(nolock)
													where cd.Doccode=@doccode
													and a.Couponsbarcode=a.Couponsbarcode
													and a.FlowInstanceID=@FlowInstanceID
													and a.FlowStatus='使用中'
													--最终将数据回填入业务单据
													;with cte as(
														select sum(isnull(cd.DeductAmout,0)) DeductAmout
														from Coupons_D cd with(nolock)
														where cd.Doccode=@newDoccode
														)
													update sPickorderHD
														set DeductAmout= cd.deductamout
													from  cte cd
													where  sPickorderHD.DocCode=@doccode
													--再将串号与优惠券绑定
													update a
														set a.CouponsBarcode=b.CouponsBarCode,
														a.CouponsCode=b.CouponsCode,
														a.DeductAmount=b.DeductAmout
													from iSeries a,Coupons_D b
													where a.SeriesCode=b.SeriesCode
													and b.Doccode=@newDoccode 
												END
										end try
										begin catch
											select @msg=dbo.getLastError('优惠券兑换单据过帐失败.')
											raiserror(@msg,16,1)
											return
										end catch
									END
								else
									--若未生成优惠券兑换单明细,则直接退出.
									BEGIN
										return
									END
						end
					END
			end
			--优惠券退还
			IF @optionID=9211
				BEGIN
 
					--检索赠送单的退货单
					SELECT @newDoccode=doccode FROM Coupons_H ch  WITH(NOLOCK) WHERE ch.RefFormid=@formid AND ch.RefCode=@doccode AND formid=9211
					IF @@Rowcount=0
						BEGIN
							EXEC sp_newdoccode @formid = 9211, @opid = '', @doccode = @newdoccode OUTPUT
							--对于零售退货单，只要单据中有优惠券就将优惠券退掉
							IF @FormID IN(2420)
								BEGIN
									if exists(select 1 from sPickorderitem sp with(nolock) where sp.DocCode=@doccode and ltrim(rtrim(isnull(sp.CouponsBarCode,'')))<>'')
										BEGIN
											SELECT @RefFormid=2419,@Refcode=sph.ClearDocCode,@stcode=sph.stcode,
											@stname=sph.stname,@CustomerID=sph.CustomerID,@DocDate=sph.DocDate,@remark=sph.prdno,
											@CustomerName=sph.cltName,@Sdgroup=sph.sdgroup,@sdgroupname=sph.sdgroupname
											FROM sPickorderHD sph WITH(NOLOCK)
											WHERE sph.DocCode=@doccode
											 --插入明细表
											INSERT INTO Coupons_D ( Doccode, Docitem, RowID, CouponsBarCode, CouponsCode, 
												   CouponsName, Remark, Price, 
												   ic.DeductAmout, Matcode, MatName, Digit, 
												   SeriesCode, Amount, RefRowID, RefDocItem,UseImmediate)
											SELECT @newDoccode,ROW_NUMBER() OVER(ORDER BY @newDoccode),NEWID(),ic.CouponsBarCode,ic.CouponsCode,
											cd.CouponsName,sp.usertxt2,ic.Price,
											sp.DeductAmout,sp.Matcode,sp.MatName,sp.Digit,
											sp.SeriesCode,sp.totalmoney,sp.rowid,sp.DocItem,
											CASE ic.[State] WHEN '已兑换' then 1 else 0 end
											FROM sPickorderitem sp   WITH(NOLOCK) ,iCoupons ic  WITH(NOLOCK),iCouponsGeneral cd  WITH(NOLOCK)
											WHERE sp.CouponsBarCode=ic.CouponsBarcode
											AND ic.CouponsCode=cd.CouponsCode
											AND sp.doccode=@doccode
											if @@ROWCOUNT=0
												BEGIN
													raiserror('优惠券不存在，生成优惠券退还单异常，请检查优惠券序号是否正确。',16,1)
													return
												END
										END
									
								END
							--对于反销单，将原单中的优惠券全部退掉
							IF @FormID IN(9244)
								BEGIN
									SELECT @RefFormid=sph.refformid,@Refcode=sph.refcode,@stcode=sph.stcode,
									@stname=sph.stname,@CustomerID=sph.CustomerID,@DocDate=sph.DocDate,@remark=HDText,
									@CustomerName=sph.cltName,@Sdgroup=sph.sdgroup,@sdgroupname=sph.sdgroupname
									FROM Unicom_Orders   sph WITH(NOLOCK)
									WHERE sph.DocCode=@doccode
									--将按单赠送的优惠券全部退掉
									--判断是否有赠送优惠券
									IF EXISTS(SELECT 1 FROM Coupons_H ch WITH(NOLOCK) WHERE ch.FormID=9207 AND  ch.RefCode=@Refcode)
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
												AND sp.FormID=9207
												AND sp.Doccode=cd.Doccode
												if @@ROWCOUNT=0
												BEGIN
													raiserror('优惠券不存在，生成优惠券退还单异常，请检查优惠券序号是否正确。',16,1)
													return
												END
										END
								end
							--加盟商订货退货单.
							if @FormID in(4951)
								BEGIN
									SELECT  @stcode=sph.instcode,@stname=sph.instname, @DocDate=sph.DocDate
									FROM sPickorderHD sph WITH(NOLOCK)
									WHERE sph.DocCode=@doccode
									--判断是否有串号
									select @Refcode=doccode from iseriesloghd i with(nolock) where i.refCode=@doccode
									if @@ROWCOUNT<=0 return
									create TABLE #iSeries (
										ID int,
										RowID varchar(50),
										Seriescode varchar(50),
										State varchar(50),
										Matcode varchar(50),
										MatName varchar(50),
										Couponsbarcode varchar(50),
										Couponscode varchar(50),
										CouponsState varchar(50)
									)
									--先将有赠送优惠券的串号记入临时表
									insert into #iSeries(ID,state,RowID,Seriescode,i.matcode,i.matname,Couponscode)
									--按Couponscode分组排序好
									select row_number() over(partition by is2.CouponsCode order by (select 1)),is2.state,i.rowid,i.seriescode,i.matcode,i.matname,is2.CouponsCode
									from iserieslogitem i with(nolock) inner join iSeries is2 with(nolock)					--用LEFT JOIN 防止串号不存在
									on i.doccode=@Refcode
									and i.seriescode=is2.SeriesCode
									and isnull(is2.CouponsBarcode,'')<>'' 
									
									if @@ROWCOUNT=0 return
									--将优惠券信息更新到临时表
									--先将本仓库中的优惠券按优惠券编码排序,准备好
									;with cte as(
										--按Couponscode分组排序好
										select row_number() OVER (partition by ic.couponscode order by (select 1)) as ID , ic.couponsbarcode,ic.couponscode,ic.State
										From iCoupons ic with(nolock)
										where ic.stCode=@stcode
										and ic.State in('在库','已赠')
									)
									--按ID将优惠券序号填入#iSeries对应的ID中
									update a
										set a.CouponsState=ic.State,
										a.Couponsbarcode=ic.couponsbarcode
									from #iSeries a,cte ic with(nolock)
									where a.Couponscode=ic.couponscode
									and a.ID=ic.id
									
									select @newDoccode, * from #iSeries
									--对数据进行校验
									--1.检查串号状态是否正确
									
									 --取出串号的优惠券
									INSERT INTO Coupons_D (Doccode, Docitem, RowID, CouponsBarCode, CouponsCode, 
											CouponsName, Price,DeductAmout,	 Matcode, MatName, Digit, 
											SeriesCode, Amount, RefRowID, RefDocItem,UseImmediate,Remark)
									--若没有优惠券则以newID临时生成一个
									SELECT @newDoccode,ROW_NUMBER() OVER(ORDER BY @newDoccode),NEWID(),isnull(i.CouponsBarCode,newid()) as CouponsBarCode,i.CouponsCode,
									icg.CouponsName as CouponsName,NULL Price,
									case when isnull(i.Couponsbarcode,'')!='' then 0 else 30 end as DeductAmout,				---若有在库的优惠券可退,则退优惠券,否则直接退30元.
									 i.Matcode,i.MatName,NULL as Digit,
									i.SeriesCode,NULL as Amount,newid() as rowid,0 as DocItem,1,
									case when isnull(i.Couponsbarcode,'')!='' then NULL else '加盟商退货无可用券,直接扣除30信用额度.' end as Remark
									FROM #iSeries i ,iCouponsGeneral icg with(nolock)
									where i.Couponscode=icg.CouponsCode
									if @@ROWCOUNT>0
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
											
										END
									else
										BEGIN
											raiserror('优惠券不存在，生成优惠券退还单异常，请检查优惠券序号是否正确。',16,1)
											return
										END
								END
						end
				END
		set @LinkDocInfo=CONVERT(VARCHAR(10),@optionID)+';5;'+@newDoccode
		return
	END