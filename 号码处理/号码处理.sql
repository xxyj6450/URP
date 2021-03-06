/*            
函数名称：sp_PostSeriesNumber                      
功能描述：处理手机号码                      
参数说明：见声名部分                      
编写:三断笛                      
时间：2010 / 06                      
备注：                      
示例：                      
-------------------------------------------------------------                      
修改： 三断笛 
时间： 2012-09-29                  
备注： 预开户增加绑定套餐功能            
select packageid from seriespool
*/            
-- begin tran exec sp_postseriesnumber 9138,'HT20120921000081'   rollback                   
ALTER PROC [dbo].[sp_PostSeriesNumber]                        
@formid INT,                        
@doccode VARCHAR(20)                        
AS                        
BEGIN
	--如果存储过程中包含的一些语句并不返回许多实际数据，则该设置由于大量减少了网络流量，因此可显著提高性能。 摘自MSDN。            
	SET NOCOUNT ON 
	set XACT_ABORT on;
	--修改事务隔离级别,锁住这条记录              
	--SET TRANSACTION ISOLATION LEVEL READ COMMITTED 
	--BEGIN TRAN --开启事务，锁定记录             
	DECLARE @user     VARCHAR(20),
	        @docdate  DATETIME
	DECLARE @SIMSeriescode VARCHAR(50)
	DECLARE @seriesNumber VARCHAR(20),@Seriescode varchar(50)
	declare @blnNoNeedSIM bit,@old bit,@packageid varchar(200),@NONeedAllocate BIT,@refcode VARCHAR(20)
	IF @formid IN (9118) --号码录入单
	BEGIN
	    SELECT @user = entername, @docdate = docdate
	    FROM   SeriesPool_H sph with(nolock)
	    WHERE  sph.Doccode = @doccode 
	   
	    --修改旧的号码，将重入网的旧号码标志为可用状态，并将使用次数加1             
	    
	    UPDATE SeriesPool
	    SET    [STATE] = '待选',
	           actived = '未激活',
	           usedtimes = CASE b.STATE
	                            WHEN '已售' THEN ISNULL(UsedTimes, 0) + 1
	                            ELSE 0
	                       END,	--使用次数加1                      
	           modifyname = @user,
	           NetTYpe = a.NetType,
	           ServiceFEE = a.ServiceFEE,
	           PhoneRate = a.PhoneRate,
	           Price = a.Price,
	           ComboFEE = CASE a.ComboFEE
	                           WHEN 1 THEN a.ComboFEE
	                           ELSE 0
	                      END,
	           OtherFEE = a.OtherFEE,
	           CardFEE = a.CardFEE,
	           TotalMoney = ISNULL(a.price, 0) + ISNULL(a.OtherFEE, 0) + ISNULL(a.CardFEE, 0) 
	           + ISNULL(a.phonerate, 0) + ISNULL(a.servicefee, 0),
	           sdorgid = NULL,	--清空部门属性                      
 
	           freecalls=a.Freecalss,
	           cardnumber = CASE a.preallocation
	                             WHEN 1 THEN a.cardnumber
	                             ELSE NULL
	                        END,
	           CardMatCode = CASE a.preallocation
	                              WHEN 1 THEN a.cardmatcode
	                              ELSE NULL
	                         END,
	           cardmatname = CASE a.cardmatname
	                              WHEN 1 THEN a.cardmatname
	                              ELSE NULL
	                         END,
	           Areaid = a.areaid,
	           valid = 1,
	           comboCode = CASE a.preallocation
	                            WHEN 1 THEN a.comboCode
	                            ELSE NULL
	                       END,
	           comboName = CASE a.preallocation
	                            WHEN 1 THEN a.comboName
	                            ELSE NULL
	                       END,
	           packageid=a.packageid,
	           preallocation = a.preallocation,
	           rewards = a.Rewards,
	           mincomboFEE = a.mincombofee,
	           validdate = a.validdate,
	           intype = '正常入库',
	           intime = GETDATE(),
	           SeriesPool.inDoccode = a.DocCode,
	           inuse = a.Inuse,
	           SeriesPool.bPackageSale = a.bPackageSale,
	           privatesdorgid = a.privatesdorgid,
	           remark = a.remark,
	           dpttype = a.dpttype,
	           oldcode = a.oldcode,
	           mintype = a.mintype, --新政策加入建设形态
				Seriescode=a.Seriescode,
				ControlPrice = isnull(a.ControlPrice,0)
	
	    FROM   Seriespool_D a  with(nolock),
	           SeriesPool b with(nolock)
	    WHERE  a.SeriesNumber = b.SeriesNumber
	           AND (
	                   (b.[STATE] = '已售' AND b.actived = '已激活')
	                   --OR (B.state = '待选' AND b.actived = '未激活')
	               )
	           AND a.DocCode = @doccode 
	    --插入新的号码                        
	    INSERT INTO SeriesPool ( SeriesNumber, NetType, ServiceFEE, PhoneRate, 
	           Price, ComboFEE, OtherFEE, CardFEE, TotalMoney, [STATE], Actived, 
	           remark, condition_code, grade, MODIFYname, CardNumber, 
	           CardMatcode, CardMatName, areaid, valid, comboCode, comboName, 
	           preallocation, rewards, mincombofee, validdate, intype, intime, 
	           inDoccode, inuse, bPackageSale, PrivateSdorgid, dpttype, indate, 
	           purcode, oldcode, mintype,Seriescode,packageid,ControlPrice )
	    --新政策加入建设形态          
	    SELECT a.seriesnumber, Nettype, ServiceFEE, PhoneRate, Price, CASE a.preallocation
	                                                                       WHEN 
	                                                                            1 THEN 
	                                                                            a.combofee
	                                                                       ELSE 
	                                                                            0
	                                                                  END, 
	           OtherFEE, CardFEE, totalmoney, '待选', '未激活', remark, b.Condition_Code, 
	           b.grade, @user, CASE a.preallocation
	                                WHEN 1 THEN CardNumber
	                                ELSE NULL
	                           END, CASE a.preallocation
	                                     WHEN 1 THEN CardMatcode
	                                     ELSE NULL
	                                END, CASE a.preallocation
	                                          WHEN 1 THEN CardmatName
	                                          ELSE NULL
	                                     END, areaid, 1, comboCode, 
	           comboName, preallocation, rewards, mincombofee, validdate, 
	           '正常入库', GETDATE(), doccode, inuse, bPackageSale, privatesdorgid, dpttype, @docdate, a.doccode, a.oldcode, 
	           a.mintype, --新政策加入建设形态
				a.Seriescode,a.packageid,isnull(a.ControlPrice,0)
	    FROM   SeriesPool_d a  with(nolock)
	           OUTER APPLY fn_getconditioncode(a.seriesnumber) b
	    WHERE  DocCode = @doccode
	           AND NOT EXISTS(
	                   SELECT 1
	                   FROM   SeriesPool sp  with(nolock)
	                   WHERE  sp.SeriesNumber = a.seriesnumber
	               ) 
	    --将预开户的卡打上预开户标记 alter table iSeries add SeriesNumber varchar(20) 
	   /* if exists(select 1 from Seriespool_D sd where sd.DocCode=@doccode and isnull(sd.preAllocation,0)=1)
			BEGIN
				UPDATE b
				SET    preAllocation = a.preallocation,
					   b.SeriesNumber = a.SeriesNumber
				FROM   Seriespool_D a  with(nolock),
					   Openquery(URP11,'Select SeriesCode, preAllocation,SeriesNumber From JTURP.dbo.iSeries b with(nolock)') b
				WHERE   b.SeriesCode in(isnull(a.CardNumber,''),isnull(a.Seriescode,''))
					   AND a.DocCode = @doccode 
			END           
	    */
 
	    --给录入成功的号码加上已录入的标记            
	    UPDATE SeriesPool_d
	    SET    imported = 1
	    FROM   SeriesPool sp with(nolock)
	           INNER JOIN SeriesPool_d a with(nolock)
	                ON  (
	                        sp.SeriesNumber = a.seriesnumber
	                        AND a.doccode = sp.indoccode
	                    )
	    WHERE  a.doccode = @doccode 
	    --插入号码事件 select * from SeriesNumber_Log            
	    INSERT INTO SeriesNumber_Log ( SeriesNumber, [Event], RefFormid, refCode, 
	           refFormType, DocType, SIMCode, ComboName, UserName, UserCode, 
	           Remark )
	    SELECT SeriesNumber, '号码入库', formid, sd.doccode, 5, doctype, 
	           cardnumber, comboname, postname, NULL, sd.remark
	    FROM   Seriespool_D sd with(nolock)
	           INNER JOIN SeriesPool_H sph  with(nolock) ON  sd.DocCode = sph.Doccode
	    WHERE  sd.DocCode = @doccode
	END          
	--号码预留   
	IF @formid IN(9214)
		BEGIN
			UPDATE seriespool
			SET PrivateSdorgid = a.PrivateSdorgid,
			seriespool.privateDate = a.Privatedate,
			seriespool.oldPrivateSdorgid = 'Shared'
			FROM seriespool b  with(nolock),seriespool_d a  with(nolock)
			WHERE a.SeriesNumber=b.SeriesNumber
			AND a.DocCode=@doccode
			INSERT INTO SeriesNumber_Log ( SeriesNumber, [Event], RefFormid, refCode, 
			       refFormType, DocType, SIMCode, ComboName, ComboFeeType, 
			       UserName, UserCode, SdorgID, SdOrgName, CustomerCode, Remark, 
			       EnterDate )
			 SELECT seriesnumber,'号码预留',b.formid,b.doccode,5,b.doctype,null,null,null,b.postname,null,null,null,null,'号码预留',getdate()
			 FROM Seriespool_D a  with(nolock),SeriesPool_H b  with(nolock)
			 WHERE a.DocCode=@doccode
			 AND a.DocCode=b.doccode
		
		end
	IF @formid IN (9122) --号码设置
	BEGIN
	    UPDATE SeriesPool
	    SET    NetTYpe = a.NetType,
	           ServiceFEE = a.ServiceFEE,
	           PhoneRate = a.PhoneRate,
	           Price = a.Price,
	           ComboFEE = a.ComboFEE,
	           OtherFEE = a.OtherFEE,
	           CardFEE = a.CardFEE,
	           TotalMoney = ISNULL(a.price, 0) + ISNULL(a.OtherFEE, 0) + ISNULL(a.CardFEE, 0) 
	           + ISNULL(a.phonerate, 0) + ISNULL(a.servicefee, 0),
	           STATE = a.STATE,
	           Actived = a.Actived,
	           remark = a.remark,
 
	           cardnumber = a.cardnumber,
	           CardMatCode = a.cardmatcode,
	           cardmatname = a.CardMatName,
	           areaid = a.areaid,
	           valid = a.valid,
	           comboCode = a.combocode,
	           comboName = a.ComboName,
	           preallocation = a.preallocation,
	           rewards = a.Rewards,
	           mincomboFEE = a.mincombofee,
	           validdate = a.validdate,
	           intype = '正常入库',
	           intime = GETDATE(),
	           SeriesPool.inDoccode = a.DocCode,
	           inuse = a.inuse,
	           bPackageSale = a.bPackageSale,
	           SeriesPool.PrivateSdorgid = a.PrivateSdorgid
	    FROM   seriesmodify_H a  with(nolock)
	    WHERE  doccode = @doccode
	           AND SeriesPool.SeriesNumber = a.seriesnumber --插入号码事件            
	    INSERT INTO SeriesNumber_Log ( SeriesNumber, [Event], RefFormid, refCode, 
	           refFormType, DocType, SIMCode, ComboName, UserName, UserCode, 
	           Remark )
	    SELECT SeriesNumber, '号码设置', formid, sd.doccode, 5, doctype, 
	           cardnumber, comboname, postname, NULL, sd.remark
	    FROM   seriesmodify_H sd  with(nolock)
	    WHERE  sd.DocCode = @doccode
	END
	
	IF @formid IN (9138) --号码调整
	BEGIN
		set XACT_ABORT on;
	    UPDATE SeriesPool
	    SET    modifyname = @user,
	           ServiceFEE = a.ServiceFEE,
	           PhoneRate = a.PhoneRate,
	           Price = a.Price,
	           ComboFEE = CASE a.ComboFEE
	                           WHEN 1 THEN a.ComboFEE
	                           ELSE 0
	                      END,
	           OtherFEE = a.OtherFEE,
	           CardFEE = a.CardFEE,
	           freecalls=a.Freecalss,
	           TotalMoney = ISNULL(a.price, 0) + ISNULL(a.OtherFEE, 0) + ISNULL(a.CardFEE, 0) 
	           + ISNULL(a.phonerate, 0) + ISNULL(a.servicefee, 0),
	           cardnumber = CASE a.preallocation
	                             WHEN 1 THEN a.cardnumber
	                             ELSE NULL
	                        END,
	           CardMatCode = CASE a.preallocation
	                              WHEN 1 THEN a.cardmatcode
	                              ELSE NULL
	                         END,
	           cardmatname = CASE a.preallocation
	                              WHEN 1 THEN a.cardmatname
	                              ELSE NULL
	                         END,
	           Areaid = a.areaid,
	           packageid=a.packageid,
	           comboCode = a.comboCode,	--CASE a.comboCode WHEN 1 THEN a.comboCode ELSE NULL END,            
	           comboName = a.comboName,	--CASE a.comboName WHEN 1 THEN a.comboName  ELSE NULL END,            
	           preallocation = a.preallocation,
	           rewards = a.Rewards,
	           mincomboFEE = a.mincombofee,
	           validdate = a.validdate,
	           inuse = a.Inuse,
	           bPackageSale = a.bPackageSale,
	           SeriesPool.PrivateSdorgid = a.privatesdorgid,
	           remark = a.remark,
	           SeriesPool.dpttype = a.dpttype,
	           oldcode = a.oldcode,
	           mintype = a.mintype, --新政策加入建设形态
				Seriescode=a.Seriescode,
				ControlPrice = isnull(a.ControlPrice,0)
	    FROM   Seriespool_D a with(Nolock),
	           SeriesPool b with(nolock)
	    WHERE  a.SeriesNumber = b.SeriesNumber
	           AND (B.state <> '已选')
	           AND a.DocCode = @doccode 
	    --将预开户的卡打上预开户标记            
	    /* if exists(select 1 from Seriespool_D sd where sd.DocCode=@doccode and isnull(sd.preAllocation,0)=1)
			BEGIN
				 UPDATE b
				SET    preAllocation = 1
				FROM   Seriespool_D a with(nolock),
					   Openquery(URP11,'Select SeriesCode, preAllocation,SeriesNumber From JTURP.dbo.iSeries b with(nolock)') b
				WHERE   --b.SeriesCode in(isnull(a.CardNumber,''),isnull(b.Seriescode,''))  --2012-05-01
						a.CardNumber=b.SeriesCode
					   AND a.DocCode = @doccode 
						and isnull(a.preallocation,0)=1   --2012-05-01
			END
	   */
	    --插入号码事件            
	    INSERT INTO SeriesNumber_Log ( SeriesNumber, [Event], RefFormid, refCode, 
	           refFormType, DocType, SIMCode, ComboName, UserName, UserCode, 
	           Remark )
	    SELECT SeriesNumber, '号码修改', formid, sd.doccode, 5, doctype, 
	           cardnumber, comboname, postname, NULL, sd.remark
	    FROM   Seriespool_D sd  with(nolock)
	           INNER JOIN SeriesPool_H sph  with(nolock) ON  sd.DocCode = sph.Doccode
	    WHERE  sd.DocCode = @doccode
	END
	
	IF @formid IN (9102, 9146,9237) --客户新入网单
	BEGIN
		
		--取出单据基本信息
		select @SIMSeriescode=LEFT(iccid,19),@Seriesnumber=seriesnumber,@Seriescode=Seriescode,@packageid=PackageID
		  from unicom_orders  with(nolock) where doccode=@doccode
		if @FormID in(9102,9146,9237)
			begin
				--取出SIM卡号
				/*select @SIMSeriescode=  seriescode 
				from unicom_orderdetails a with(nolock)
				left join imatgroup b  with(nolock) on a.matgroup=b.matgroup
				where a.doccode=@doccode
				and exists(select 1 from dbo.fn_sysGetNumberAllocationConfig('SIM卡大类') x where b.path like '%/'+x.propertyvalue +'/%')*/
				--SELECT @SIMSeriescode=LEFT(iccid,19) FROM unicom_orders uo WITH(NOLOCK) WHERE uo.DocCode=@doccode
				--取出串号
				SELECT @Seriescode=  seriescode 
				from unicom_orderdetails a with(nolock)
				left join imatgroup b  with(nolock) on a.matgroup=b.matgroup
				where a.doccode=@doccode
				and exists(select 1 from dbo.fn_sysGetNumberAllocationConfig('手机大类') x where b.path like '%/'+x.propertyvalue +'/%')
			end
 
		if @formid in(9146,9237) 
			BEGIN
 
				IF   EXISTS(
				       SELECT 1
				       FROM   policy_h a  WHERE a.DocCode=@packageid AND (ISNULL(a.old,0)=1 OR ISNULL(a.NONeedAllocate,0)=1)
				       )
				       begin
							SELECT @blnNoNeedSIM = 1
						end
				--检查是否需要开户
				SELECT @NONeedAllocate=NONeedAllocate FROM policy_h ph  with(nolock) WHERE ph.DocCode=@packageid
			END
	    --插入号码事件 select * from SeriesNumber_Log            
	    INSERT INTO SeriesNumber_Log ( SeriesNumber, [Event], RefFormid, refCode, 
	           refFormType, DocType, SIMCode, ComboName, combofeetype, UserName, 
	           UserCode, sdorgid, sdorgname, Remark, customercode )
	    SELECT SeriesNumber, '号码销售', formid, uo.doccode, 5, doctype, 
	           @SIMSeriesCode, comboname, combofeetype, sdgroupname, sdgroup, 
	           sdorgid, sdorgname, uo.hdtext, cltcode
	    FROM   Unicom_Orders uo with(nolock)
	    WHERE  uo.DocCode = @doccode
	    --如果需要开户,则修改号码状态
		--IF ISNULL(@NONeedAllocate,0)=0
			begin
				--修改号码状态为已售,并记录号码出库信息            
				UPDATE SeriesPool
				SET    STATE = '已售',
					   outtype = a.doctype,
					   OutTime = a.postdate,
					   Outdoccode = a.doccode,
					   customercode = a.cltCode,
					   salecombocode = a.ComboCode,
					   salecomboname = a.ComboName
				FROM   Unicom_Orders a with(nolock)
				WHERE  a.DocCode = @doccode
					   AND a.SeriesNumber = seriespool.SeriesNumber 
	    --IF isnull(@blnNoNeedSIM,0)=0 --or ISNULL(@NONeedAllocate,0)=0
				--如果需要白卡,则将白卡与号码绑定
				IF ISNULL(@blnNoNeedSIM,0)=0
					 BEGIN
						--将销售卡号绑定至号码池 select seriesnumber from unicom_orderdetails select seriesnumber from seriespool            
						UPDATE seriespool
						SET    salecardnumber = @SIMSeriesCode 
						WHERE  seriesnumber=@seriesnumber
 						IF  @@ROWCOUNT = 0 --如果绑定失败
						BEGIN
							--IF @@TRANCOUNT > 0 ROLLBACK
					        
							RAISERROR('SIM卡绑定号码失败,请重试!', 16, 1)
						END
						--检查SIM卡与手机的绑定
						IF EXISTS(SELECT 1 FROM SeriesPool sp WITH(NOLOCK) 
						          WHERE sp.SeriesNumber=@seriesNumber
						          AND ISNULL(sp.preAllocation,0)=1
							AND (ISNULL(sp.CardNumber,@SIMSeriescode)!=@SIMSeriescode OR ISNULL(sp.SeriesCode,@Seriescode)!=@Seriescode)
						)  
						BEGIN
							RAISERROR('该预开号码已绑定SIM卡或手机，录入正确的SIM卡或手机',16,1)
							return
						END
					 END
					 
			 end
	END
	--返销,还原号码状态
	IF @formid IN(9244)
		BEGIN
			SELECT @old=old,@NONeedAllocate=uo.NONeedAllocate,@seriesNumber=uo.SeriesNumber,@refcode=uo.refcode
			  FROM Unicom_Orders uo WITH(NOLOCK) WHERE uo.DocCode=@doccode
			--将号码还原,只有在原单是开户业务时才还原
			IF not(ISNULL(@old,0)=1 OR ISNULL(@NONeedAllocate,0)=1)
				BEGIN
					UPDATE SeriesPool
						SET [STATE] = '待选',
						actived='未激活',
						sdorgid=NULL,
						lockedusercode=NULL,
						OccupyTime = NULL,
						ReleaseDate = NULL,
						remark = '返销'
					WHERE SeriesNumber=@seriesNumber
					iNSERT INTO SeriesNumber_Log ( SeriesNumber, [Event], RefFormid, refCode, 
						   refFormType, DocType, SIMCode, ComboName, combofeetype, UserName, 
						   UserCode, sdorgid, sdorgname, Remark, customercode )
					SELECT SeriesNumber, '号码返销', formid, uo.doccode, 16, doctype, 
						   @SIMSeriesCode, comboname, combofeetype, sdgroupname, sdgroup, 
						   sdorgid, sdorgname, uo.hdtext, cltcode
					FROM   Unicom_Orders uo with(nolock)
					WHERE  uo.DocCode = @doccode
				END
			UPDATE Unicom_Orders SET bitReturnd = 1 WHERE DocCode=@refcode
			UPDATE NumberAllocation_Log SET bitreturnd=1 WHERE doccode=@refcode
			
		END
	IF @formid IN (9166) --号码清理
	BEGIN
	    --标记号码            
	    UPDATE Seriespool_D
	    SET    Imported = 1
	    FROM   Seriespool_D sd  with(nolock)
	           INNER JOIN SeriesPool sp  with(nolock)
	                ON  sd.SeriesNumber = sp.SeriesNumber
	    WHERE (sp.STATE='待选' or sp.actived='已激活')
	           AND sd.DocCode = @doccode 
	    --删除号码            
	    DELETE 
	    FROM   SeriesPool   
	    WHERE  SeriesNumber IN (SELECT SeriesNumber
	                            FROM   Seriespool_D sd  with(nolock)
	                            WHERE  sd.DocCode = @doccode
	                                   AND sd.Imported = 1)
		--清理清除号码与卡，手机的绑定
	 /*if exists(select 1 from Seriespool_D sd where sd.DocCode=@doccode and isnull(sd.preAllocation,0)=1)
		BEGIN
			Update a
				set SeriesNumber=NULL
			From Openquery(URP11,'Select SeriesCode, preAllocation,SeriesNumber From JTURP.dbo.iSeries b with(nolock)') a,
			Seriespool_d b with(nolock)
			where a.Seriescode in(isnull(b.cardnumber,''),isnull(b.seriescode,''))
			and b.DocCode=@doccode
		END
		*/
		
	    --插入号码事件            
	    INSERT INTO SeriesNumber_Log ( SeriesNumber, [Event], RefFormid, refCode, 
	           refFormType, DocType, SIMCode, ComboName, UserName, UserCode, 
	           Remark )
	    SELECT SeriesNumber, '号码清理', formid, sd.doccode, 5, doctype, 
	           cardnumber, comboname, postname, NULL, sd.remark
	    FROM   Seriespool_D sd  with(nolock)
	           INNER JOIN SeriesPool_H sph   with(nolock) ON  sd.DocCode = sph.Doccode
	    WHERE  sd.DocCode = @doccode
	           AND sd.Imported = 1
	END
	
	IF @formid IN (9168) --号码状态修改
	BEGIN
	    --标记号码            
	    UPDATE Seriespool_D
	    SET    Imported = 1
	    FROM   Seriespool_D sd  with(nolock)
	           INNER JOIN SeriesPool sp  with(nolock)
	                ON  sd.SeriesNumber = sp.SeriesNumber
	    WHERE  sp.[STATE]IN ('待选', '已售')
	           AND sd.DocCode = @doccode 
	    --调整号码            
	    UPDATE l
	    SET    Valid = d.Valid,
	           remark = d.remark
	    FROM   Seriespool_D d  with(nolock)
	           LEFT JOIN SeriesPool l  with(nolock)
	                ON  d.seriesnumber = l.seriesnumber
	    WHERE  d.doccode = @doccode
	           AND ISNULL(d.Imported, 0) = 1
	    /*update SeriesPool
	    SET Valid =sd.Valid ,      
	    remark=sd.remark  --select *     
	    FROM Seriespool_D sd      
	    WHERE sd.DocCode=@doccode     
	    AND sd.Imported=1 */ 
	    --插入号码事件            
	    INSERT INTO SeriesNumber_Log ( SeriesNumber, [Event], RefFormid, refCode, 
	           refFormType, DocType, SIMCode, ComboName, UserName, UserCode, 
	           Remark )
	    SELECT SeriesNumber, '号码状态修改', formid, sd.doccode, 5, doctype, 
	           cardnumber, comboname, postname, NULL, sd.remark
	    FROM   Seriespool_D sd  with(nolock)
	           INNER JOIN SeriesPool_H sph   with(nolock) ON  sd.DocCode = sph.Doccode
	    WHERE  sd.DocCode = @doccode
	           AND sd.Imported = 1
	END
	
	/*IF @@ERROR <> 0 --错误处理
	BEGIN
	    IF @@TRANCOUNT > 0
	    BEGIN
	        ROLLBACK 
	        PRINT '操作失败,事务已回滚'
	    END
	    
	    RAISERROR('操作失败,请重试!', 16, 1) 
	    RETURN
	END
	ELSE
	BEGIN
	    IF @@TRANCOUNT > 0
	    BEGIN
	        COMMIT 
	        PRINT '操作成功,事务已提交'
	    END
	END*/
END