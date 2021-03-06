SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*                                                  
* 函数名称：sp_CheckNumberAllocationDoc                                      
* 功能描述：执行新入网审核操作                                
* 参数:见声名部分                                                  
* 编写：三断笛                                                  
* 时间：2010/06/22                                                 
* 备注：                                
* 示例：exec sp_CheckNumberAllocationDoc 9146,'PS20100901000082','18665123567','通过审核','SYSTEM','系统管理员','OK','18666855517','制单正确'                              
begin tran                               
exec sp_CheckNumberAllocationDoc 9158,'BK20120920000021','18602084677','通过审核','SYSTEM','管理员','客户号码已开通','18666855312'           
                              
rollback                              
UPDATE BusinessAcceptance_H SET CheckState ='待审核'                              
delete BusinessAcceptance_H                              
begin tran                              
exec sp_CheckNumberAllocationDoc 9102,'RW20111225000007','18680618661','通过审核','SYSTEM','管理员','客户号码已开通','18680618661'                                
rollback      
begin tran      
declare @p12 varchar(200)  
set @p12=''  
exec sp_CheckNumberAllocationDoc 9146,'BK20120921000001','18676980344','退回','SYSTEM','管理员','','通过asdfasdfasdfasdfasdfasdf审核','system','通过审核','开户审核','',@p12 output       
rollback               
update BusinessAcceptance_H set checkstate='待审核' where doccode='BK20120920000021'    
* --------------------------------------------------------------------                                                  
* 修改：如果用户提交的号码是14500000000,1560000000,18600000000则表示用户不知道号码,需要总部任选一个号码.                              
* 时间：                                                  
* 备注：      
---------------------------------------------------------      
修改:将9102,9146修改单据状态代码调整到所有项执行完之后.      
时间:2011-12-08      
编写:三断笛      
*                                                   
*/                                 
 
ALTER PROC [sp_CheckNumberAllocationDoc]                                
	@formid INT,      --单据功能号                                
	@doccode VARCHAR(20),    --单号                                
	@seriesnumber VARCHAR(20),   --号码                                
	@checkstate VARCHAR(20),   --审核状态                                
	@usercode VARCHAR(20) = '',    --审核人                               
	@userName VARCHAR(20) = '',  --审核人      
	@OpenSdorgId VARCHAR(50) = '', --开户门店                               
	@remark VARCHAR(2000) = '',    --备注                                
	@applyer VARCHAR(50) = '',                              
	@reason VARCHAR(100) = '',  --原因      
	@CheckType VARCHAR(20) = '开户审核',
	@TerminalID varchar(50)='',      
	@linkdocinfo VARCHAR(200) = '' OUTPUT                               
AS                                
BEGIN    
 /************************************************************初始化及变量定义***********************************************/                              
	SET NOCOUNT ON;  
	set xact_abort on
	DECLARE @audits          VARCHAR(20),    
	@auditsName      VARCHAR(50),    
	@tips            VARCHAR(200),    
	@newDoccode      VARCHAR(20),    
	@sdorgid         VARCHAR(20),    
	@sdorgName       VARCHAR(120),    
	@doctype         VARCHAR(30),    
	@formtype        INT,    
	@noNeedAllocate  BIT,    
	@old             BIT,    
	@MatName         VARCHAR(200),    
	@DocItem         INT,    
	@packageID       VARCHAR(20),    
	@TranCount       INT,    
	@sdgroup         VARCHAR(50),    
	@ICCID           VARCHAR(30),    
	@SeriesCode      VARCHAR(20),
	@MatCode Varchar(50), 
	@ForceCheckDoc BIT,    
	@CardMatcode VARCHAR(50),    
	@MustReadCard BIT,  
	@PreAllocation BIT,  
	@packageName VARCHAR(200),
	@dptType varchar(50),
	@BusiType Varchar(50),
	@bitOpenAccount Bit,
	@DocStatus Int,
	@preCheckstate Varchar(20),
	@SeriesNumberState Varchar(50),
	@SeriesNumberActived Varchar(50),
	@SeriesNumberRefcode Varchar(50),
	@PreSeriesNumber Varchar(50),
	@Intype Varchar(20),
	@CardSeriescode Varchar(30),
	@sql Nvarchar(Max),
	@bitHasphone Bit,
	@busiStockState Varchar(50),
	@ComboName Varchar(200),
	@ComboFeeType Varchar(50),
	@VoucherCode Varchar(50),
	@sdgroupname varchar(50)
 /************************************************************数据检查*******************************************************/     
  --若单据退回,则必须要求录入原因.  
	If @checkstate = '退回'
	Begin
		If Len(Isnull(@remark, '')) <= 10
		Begin
			Raiserror('单据退回请在[说明]处注明详细原因及解决办法,不得少于10个字.', 16, 1) 
			Return
		End
	    
		If Isnull(@reason, '') = ''
		Begin
			Raiserror('单据退回请选择退回原因.', 16, 1) 
			Return
		End
	End
 
 --检查单据状态,只有未确认且审核状态为空或待审核才允许进行本操作,防止人为调用此过程引起数据混乱                                
 IF @formid IN (9102, 9146, 9237,9244)    
 BEGIN  
	select * Into #Unicom_Orders From Unicom_Orders  with(nolock) where Doccode=@Doccode  
	Select * Into #unicom_OrderDetails From Unicom_OrderDetails with(nolock) Where Doccode=@Doccode  
	Select * Into #SeriesPool From SeriesPool where SeriesNumber=@SeriesNumber
     --取审核人信息                              
	SELECT @audits = audits,    
		@auditsName = uo.Auditingname,    
		@sdorgid = uo.sdorgid,    
		@sdorgName = uo.sdorgname,    
		@doctype = uo.DocType,    
		@formtype = 5,    
		@sdgroup = uo.sdgroup,      
		@packageID = uo.PackageID,    
		@ICCID = uo.ICCID,    
		@CardMatcode=uo.CardMatCode,  
		@packageID=packageid,  
		@packageName=packagename,  
		@PreAllocation=ISNULL(preallocation,0),
		@dptType=dpttype,
		@CardMatcode=cardmatcode,
		@DocStatus=uo.docStatus,
		@preCheckstate=checkstate,
		@PreSeriesNumber=seriesnumber,
		@Intype=uo.intype,
		@CardSeriescode=Left(@ICCID,19),
		@MatCode=uo.MatCode,
		@SeriesCode=uo.SeriesCode,
		@ComboName=uo.ComboName,
		@ComboFeeType=uo.comboFEEType,
		@sdgroupname=uo.sdgroupname
	FROM   Unicom_Orders uo   WITH(NOLOCK)  
	WHERE  uo.DocCode = @doccode    

	IF @OpenSdorgId = ''    SELECT @OpenSdorgId = @sdorgid  
     --取出政策信息    
	IF ISNULL(@packageID,'')!=''
		BEGIN
			SELECT @ForceCheckDoc=ForceCheckDoc,@BusiType=ph.PolicygroupID
			FROM policy_h ph WITH(NOLOCK) WHERE ph.DocCode=@packageID
		END
	Select @bitOpenAccount=pg.OpenAccount,@bitHasphone=pg.hasPhone,@busiStockState=pg.StockState
	From T_PolicyGroup pg Where pg.PolicyGroupID=@BusiType
	--取商品信息,判断是否必须读写卡
	SELECT @MustReadCard=mustreadcard FROM iMatGeneral img with(nolock) WHERE img.MatCode=@CardMatcode
	--取号码信息
	Select @SeriesNumberState=sp.[STATE],@SeriesNumberActived=sp.Actived,@SeriesNumberRefcode=sp.RefCode
	  From SeriesPool sp With(Nolock) Where sp.SeriesNumber=@seriesnumber    
 END   
	 
IF @formid IN (9153, 9158, 9159, 9160, 9165, 9167, 9180)    
	BEGIN    
	Select * Into #BusinessAcceptance_H From BusinessAcceptance_H Where Doccode=@Doccode  
     --取审核人信息                              
     SELECT @audits = audits,    
            @auditsName = uo.Auditingname,    
            @sdorgid = uo.sdorgid,    
            @sdorgName = uo.sdorgname,    
            @doctype = uo.DocType,    
            @formtype = 16,    
            @ICCID = uo.ICCID,    
            @seriesnumber = uo.SeriesNumber,    
            @CardMatcode=uo.MatCode,
            @dpttype=dpttype,
            @DocStatus=docstatus,
            @preCheckstate=checkstate
     FROM   #BusinessAcceptance_H uo   WITH(NOLOCK)  
     WHERE  uo.DocCode = @doccode    
         
     IF @OpenSdorgId = ''  SELECT @OpenSdorgId = @sdorgid    
     IF @formid IN(9158)
		BEGIN
			   SELECT @MustReadCard=mustreadcard FROM iMatGeneral img with(nolock)  WHERE img.MatCode=@CardMatcode   
		END
 
 END    
 IF @formid IN (9102, 9146, 9237, 9244)   AND @CheckType = '开户审核'
 BEGIN
     --开户审核不允许选择稽核错误选项      
     IF @checkstate = '稽核错误'
     BEGIN
         RAISERROR('开户审核不允许选择[稽核错误]状态!', 16, 1) 
         RETURN
     END 
     --如果审核人不是自己或未绑定审核人,则不允许审核                              
     IF @audits IS NULL
     BEGIN
         RAISERROR('单据尚未锁定审核人,不允许审核!', 16, 1) 
         RETURN
     END      
     
     IF @audits <> @usercode   AND @usercode != 'system'
     BEGIN
         SELECT @tips = @auditsName + '正在审核此单,您不需要再重复审核!' 
                RAISERROR(@tips, 16, 1) 
                RETURN
     END 
     --不是待审核状态的单据不允许审核                              
     IF @docstatus > 0 OR @precheckstate <> '待审核'
     BEGIN
         RAISERROR('单据正在审核中或已经审核完成,不允许重复审核!', 16, 1) 
         RETURN
     END 
     --检查号码是否合法 select dbo.fn_checkseriesnumber('18665131427')                               
     IF dbo.fn_checkseriesnumber(@seriesnumber) = 0   AND ISNULL(@noNeedAllocate, 0) = 0
     BEGIN
         RAISERROR('您输入的号码非法,请重新输入!', 16, 1) 
         RETURN
     END 
     --以下控制仅对开开户有效  
     IF @formid IN (9102, 9146, 9237)
     BEGIN
         --检查号码状态是否已被自动还原,这里只需要判断号码池中的那个号码的refcode是否为单号,也能兼容号码不在号码池的情况                              
         If @SeriesNumberRefcode<> @doccode  And @SeriesNumberState <> '已选'  And @bitOpenAccount=1
         BEGIN
             RAISERROR('审核超时,号码资源已被释放,单据作废,无需再审核.', 16, 1) 
             RETURN
         END    
         
         If @SeriesNumberActived  = '已激活' AND Isnull(@SeriesNumberRefcode, '') != @doccode --如果是本单开的,则不作限制.因为单据有可能开通后被撤回. 2012-04-30 三断笛
          And @bitOpenAccount=1   AND @checkstate = '通过审核'
         BEGIN
             RAISERROR('此号码已在激活状态,请核查此号码信息.若确认此号码在可用状态,请用[号码清理]功能将此号码删除.', 16,   1 ) 
             RETURN
         END 
         --检查号码是否14500000000,15600000000,18600000000                              
         IF @seriesnumber IN ('14500000000', '15600000000', '18600000000')   AND @checkstate = '通过审核'
         BEGIN
             RAISERROR('您需要将门店请求的新号码录入至[受理号码]框中再执行此操作.', 16, 1) 
             RETURN 
         END
         --只要写了卡就可以通过审核,先不严格限制必须激活      
         /*IF ISNULL(@ICCID, '') <> ''   AND @checkstate = '通过审核'    AND ISNULL(@MustReadCard, 0) = 1 --限制必须要求读卡的商品   
					   AND ISNULL(@PreAllocation, 0) <> 1 --预开户不作限制  
					   AND (dbo.fn_getSDOrgConfig(@sdorgid, 'rwCardBackground') = 1  OR ISNULL(@ForceCheckDoc, 0) = 1)
			BEGIN
					if NOT EXISTS(SELECT 1 FROM   URP11.JTURP.dbo.iSIMInfo is1 WITH(NOLOCK)				--多服务器版本要注意此处
											WHERE  is1.ICCID = @ICCID AND islocked = 1
					) --不需要后台审核的门店不限制
				 BEGIN
					 RAISERROR('SIM卡尚未激活,不允许通过审核!', 16, 1) 
					 RETURN
				 END
			END	*/
     END
    
 END
 IF @formid IN (9153, 9158, 9159, 9160, 9165, 9167, 9180)  AND @checktype = '开户审核'    
 BEGIN    
     --如果审核人不是自己或未绑定审核人,则不允许审核                              
     IF @audits IS NULL    
     BEGIN    
         RAISERROR('单据尚未锁定审核人,不允许审核!', 16, 1)     
         RETURN    
     END      
         
     IF @audits <> @usercode    
     BEGIN    
         SELECT @tips = @audits + '正在审核此单,您不需要再重复审核!'     
         RAISERROR(@tips, 16, 1)     
         RETURN    
     END      
         
     IF @docstatus > 0 Or @preCheckstate   <> '待审核'
     BEGIN    
         RAISERROR('单据正在审核中或已经审核完成,不允许重复审核!', 16, 1)     
         RETURN    
     END    
 END     
     
 /************************************************************更新数据*******************************************************/     

     
 --修改单据审核状态                               
 /**********************************************************新入网业务******************************************************/                              
 IF @formid IN (9102, 9146, 9237) AND @CheckType = '开户审核' --客户新入网    
 BEGIN    
     --将门店请求的号码更新至新入网单据                              
     If @preSeriesNumber IN ('14500000000', '15600000000', '18600000000')    
     BEGIN    
		--需要将done字段置1才允许修改单据                              
		Update Unicom_Orders
		Set    done = 1
		Where  DocCode = @doccode     
		--修改号码                              
		Update Unicom_Orders
		Set    SeriesNumber = @seriesnumber, done = Null
		Where DocCode=@doccode
	END
         
     IF @checkstate  In( '拒绝审核','退回')    
     BEGIN   
     	Begin try 
         --若开户的话,需要将号码释放
         If @bitOpenAccount=1
			BEGIN
				UPDATE SeriesPool    
				SET	ReleaseDate = DATEADD(n,60,GETDATE())  
				WHERE  seriesnumber = @seriesnumber
				--记录号码操作记录
				INSERT INTO SeriesNumber_Log (  SeriesNumber, [Event], RefFormid,     
				refCode, refFormType, SIMCode, ComboName, doctype,     
				ComboFeeType, UserName, UserCode, CustomerCode, Remark,     
				EnterDate  )    
				SELECT @seriesnumber, '开户'+@checkstate, @formid, @doccode, 5, '', @comboname, @doctype, @combofeetype, @username, @usercode,@vouchercode, @remark, GETDATE()    
			END                             
           
         --若开户,或业务类型包含手机,则解除对串号和卡号的锁定
         If @bitOpenAccount=1 Or (@bitHasphone=1 And Exists(Select 1 From commondb.dbo.[SPLIT](isnull(@busiStockState,'在库'),',') s Where s.list='在库'))
         and (isnull(@SeriesCode,'')!='' or Isnull(@CardSeriescode,'''')!='')
			BEGIN
				set xact_abort on
				SET @sql = 'Update Openquery(URP11,''Select isava,isbg,occupyed,OccupyedDoc From JTURP.dbo.iSeries Where Seriescode in('''''+Isnull(@SeriesCode,'')+''''','''''+Isnull(@CardSeriescode,'''')+''''')'')' + char(10)
						 + '         Set isava=0,isbg=0,occupyed=0,OccupyedDoc=Null'
				Exec sp_executesql @sql
				set xact_abort off
			End
		--若有ICCID,而且是开户,则需要取消ICCID的绑定
		IF @ICCID <> '' And @bitOpenAccount=1
 			   AND ISNULL(@MustReadCard,0) = 1
 			   AND ISNULL(@PreAllocation,0) <> 1 --预开户不作限制
 			   AND (dbo.fn_getSDOrgConfig(@sdorgid,'rwCardBackground') = 1
 					   OR ISNULL(@ForceCheckDoc,0) = 1)
 			BEGIN
 				EXEC sp_ChangeSIMStatus @ICCID,'',0,@doccode,@formid,5,@seriesnumber,  @usercode,@sdorgid,'单据退回审核'
 			End
 		--需要减少信用额度的冻结金额
 		If @dptType In('加盟店')
 			BEGIN
 				exec sp_UpdateCredit @formid,@doccode,@sdorgid,0,'2',@remark,@usercode,@TerminalId
 			END
		END TRY      
		BEGIN CATCH
			SELECT @tips = '退回单据发生异常.' + dbo.crlf() +
				   ISNULL(ERROR_MESSAGE(),'') + dbo.crlf() +
				   '异常发生在第' + convert(varchar(10),isnull(ERROR_LINE(),0)) + '行'

			RAISERROR(@tips,16,1) 
			return
		END CATCH                            
     END      
     --修改号码池号码状态,并记录不在号码池中的号码         select * from SeriesNumber_Log                       
	IF @checkstate = '通过审核'    
     BEGIN
         BEGIN TRY    
          /*If @bitOpenAccount=1
          BEGIN    
           UPDATE SeriesPool    
              SET    Actived = '已激活',    
                     STATE = '已选', --此行不可少.因为在请求审核时可能号码池中没有这个号码,而在通过审核时号码池中有了这个号码    
                                     --则要将新入库的这个号码状态改成已选状态                              
                     ReleaseDate = '2049-12-31',    
                     seriespool.ComboName = a.comboname,    
                     combofeetype = a.combofeetype,    
                     developsdorgid = a.sdorgid,    
                     developsdorgname = a.sdorgname,    
                     DevelopSdgroup = a.sdgroup,    
                     DevelopSdgroupname = a.sdgroupname,    
                     developdate = GETDATE(),    
                     customercode = a.cltcode,    
                     remark = a.hdtext,    
                     UsedTimes = ISNULL(UsedTimes, 0) + 1,    
                     opersdgroup = @usercode,    
                     OperSdgroupName = @userName,    
                     SeriesPool.ModifyName = @userName,    
                     SeriesPool.Modifydate = GETDATE(),    
                     SeriesPool.outFormid = a.formid,    
                     SeriesPool.outType = a.doctype,    
                     outdoccode = a.DocCode,
                     CardNumber = @ICCID,
                     CardMatCode = @CardMatcode
              FROM   #Unicom_Orders a  WITH(NOLOCK)--条件过滤掉了 老客户号码的套包销售情况？？    
              WHERE  a.DocCode = @doccode    
                     AND SeriesPool.SeriesNumber = @seriesnumber    
                     --AND SeriesPool.state <> '已售'     
                  
              --如果号码在号码池中不存在,则将号码插入号码池 select * from seriespool                           
              IF @@ROWCOUNT = 0    
              BEGIN    
                  -- print '将号码插入号码池'               
                  INSERT INTO seriespool (  SeriesNumber, NetType,     
                         ServiceFEE, PhoneRate, Price, MinComboFEE,     
                         OtherFEE, CardFEE, TotalMoney, STATE, Actived,     
                         remark, Condition_Code, Grade, developsdgroup,     
                         developsdgroupname, developsdorgid,     
                         developsdorgname, developdate, opersdgroup,     
                         opersdgroupname, AreaID, valid, UsedTimes,     
                         ModifyName, Modifydate, RefCode, preAllocation,     
                         Rewards, ComboCode, ComboName, ComboFEE,     
                         ValidDate, inType, inDoccode, inFormid, InTime,     
                         OutTime, Outdoccode, outFormid, outType, Inuse,     
                         Customercode, ReleaseDate )    
                  SELECT @seriesnumber, ISNULL(nettype, '3G'), servicefee, phonerate, price, mincombofee,     
                         otherfee, cardfee, totalmoney1, '已选', '已激活', hdtext, c.condition_code, c.grade,     
                         sdgroup, sdgroupname, sdorgid, sdorgname, GETDATE(), @usercode, @userName, areaid, 1, 1,    
                          postname, postdate, doccode, 0, 0, combocode, comboname, comboFEE, '2049-12-30',     
                         '池外入库', doccode, formid, postdate, postdate, doccode, formid, doctype, inuse, a.cltcode,     
                         '2049-12-31'    
                  FROM   #unicom_orders a   WITH(NOLOCK)  
                         OUTER APPLY fn_getConditionCode(a.seriesnumber) c    
                  WHERE  doccode = @doccode    
                         --and (select count(1) from SeriesPool where seriesnumber = @seriesnumber) <= 0    
              END     
          END*/     
          --修改号码操作记录                              
          INSERT INTO SeriesNumber_Log    
            ( SeriesNumber, [Event], RefFormid, refCode, refFormType, SIMCode, ComboName, DocType, ComboFeeType,     
              UserName, UserCode, CustomerCode, Remark, EnterDate  )
              
          SELECT @seriesnumber, '审核开户', formid, doccode, 5, '', comboname, doctype, combofeetype, @username, @usercode,     
                 cltcode, @remark, GETDATE()    
          FROM   #Unicom_Orders uo   WITH(NOLOCK)  
          WHERE  uo.DocCode = @doccode    
  
          --此处开启事务  
          SELECT @TranCount = @@TRANCOUNT      
          IF @TranCount = 0 BEGIN TRAN 
         --执行空白卡处理
          IF ISNULL(@ICCID, '') <> ''   AND ISNULL(@PreAllocation, 0) <> 1 --预开户不作限制  
                AND ISNULL(@MustReadCard, 0) = 1   AND (dbo.fn_getSDOrgConfig(@sdorgid, 'rwCardBackground') = 1
              OR ISNULL(@ForceCheckDoc, 0) = 1
                )
              --多服务器版本
              EXEC URP11.JTURP.dbo.sp_ChangeSIMStatus @ICCID, '', 3, @doccode, @formid, 5, @seriesnumber, @usercode, '', '开户激活'    
			  --单服务器版本
			  --EXEC URP11.URP01.dbo.sp_ChangeSIMStatus @ICCID, '', 3, @doccode, @formid, 5, @seriesnumber, @usercode, '', '开户激活'   
          IF @TranCount = 0 COMMIT
         END TRY      
         BEGIN CATCH
         	IF @TranCount = 0 ROLLBACK
         	    SELECT @tips = CHAR(10) + 'SIM卡绑定号码失败,请重试!' + CHAR(10)   + '异常描述:' + ERROR_MESSAGE() 
 	           RAISERROR(@tips, 16, 1) 
 	           RETURN
         END CATCH 
         SELECT @linkdocinfo = CAST(@formid AS VARCHAR) + ';' + CONVERT(VARCHAR(10), CASE WHEN @Formid IN (9237) THEN 16 ELSE 5 END)   + ';' + @doccode    
     END
 end  
 IF @formid IN(9244) and @checkstate='通过审核' and @CheckType='开户审核' and @bitOpenaccount=1
		BEGIN
	 
				BEGIN
					/*UPDATE SeriesPool
						SET [STATE] = '待选',
						actived='未激活',
						sdorgid=NULL,
						lockedusercode=NULL,
						OccupyTime = NULL,
						ReleaseDate = NULL,
						remark = '返销'
					WHERE SeriesNumber=@seriesNumber*/
					iNSERT INTO SeriesNumber_Log ( SeriesNumber, [Event], RefFormid, refCode, 
						   refFormType, DocType, SIMCode, ComboName, combofeetype, UserName, 
						   UserCode, sdorgid, sdorgname, Remark)
					SELECT @SeriesNumber, '号码返销', @formid, @doccode, 16, '开户返销单', 
						   @CardSeriescode, @comboname, @combofeetype, @sdgroupname, @sdgroup, 
						   @sdorgid, @sdorgname, @remark
				END
		END
--修改单据状态信息  
if @formid in(9102,9146,9237,9244) and @CheckType='开户审核'  
  begin  
     UPDATE Unicom_Orders    
     SET    checkState = @checkstate,    
            Unicom_Orders.Audits = '',--@usercode,    
            Unicom_Orders.Auditingname = '',--@userName,    
            Unicom_Orders.Auditingdate = GETDATE(),  
            opendate=GETDATE(),  
            unicom_orders.openSdgroup=@usercode,  
            unicom_orders.opensdgroupName=@userName,    
            ordernum = NULL,    
            OpenSdorgID = @OpenSdorgId,
            ReturnReasons=@remark,
            ReturnUsercode=@usercode
     WHERE  DocCode = @doccode    
            AND DocStatus = 0    
            AND checkState = '待审核'    
     IF @@ROWCOUNT = 0    
     BEGIN    
         RAISERROR('单据不在待审核状态,操作失败!', 16, 1)     
         RETURN    
     end  
end  
 /****************************************************************其他业务受理***************************************************************/
 
 IF @CheckType = '开户审核'    
 BEGIN    
       
     IF @formid IN (9158) --补卡    
     BEGIN    
         IF @ICCID <> ''    AND ISNULL(@MustReadCard,0)=1    AND dbo.fn_getSDOrgConfig(@sdorgid, 'rwCardBackground') = 1    
         BEGIN    
             IF @checkstate = '通过审核'    
                 EXEC sp_ChangeSIMStatus @ICCID, @SeriesCode, 3, @doccode, @formid, 16, @seriesnumber, @usercode, @sdorgid, '补换卡成功.'
                 
             ELSE  IF @checkstate = '退回'    
                 EXEC sp_ChangeSIMStatus @ICCID,@SeriesCode,0,@doccode,@formid,16,@seriesnumber,@usercode, @sdorgid, '补换卡审核退回.'    
         END     
            
         --更新已请求审核的串号，不允许再用
         --若开户,或业务类型包含手机,则解除对串号和卡号的锁定
         If isnull(@ICCID,'')<>''
			BEGIN
				set xact_abort on
				SET @sql = 'Update Openquery(URP11,''Select isava,isbg,occupyed,OccupyedDoc From JTURP.dbo.iSeries Where Seriescode in('''''+Isnull(@SeriesCode,'')+''''','''''+Isnull(@CardSeriescode,'''')+''''')'')' + char(10)
						 + '         Set isava=0,isbg=0,occupyed=0,OccupyedDoc=Null'
				Print @sql
				Exec sp_executesql @sql
				set xact_abort off
			End   
     END      
     --充值缴费控制信用额度
     if @formid in(9167) and @dpttype='加盟店'
		BEGIN
			--需要减少信用额度的冻结金额
         	exec sp_UpdateCredit @formid,@doccode,@sdorgid,0,'2',@remark,@usercode,@TerminalId
		END
     IF @formid IN (9153, 9158, 9159, 9160, 9163, 9165, 9167, 9180)    
     BEGIN    
         --修改审核状态                              
         UPDATE BusinessAcceptance_H    
         SET    checkState = @checkstate,    
                Audits        = @usercode,    
                Auditingname  = @userName,    
                Auditingdate  = GETDATE(),  
                opendate=GETDATE(),   
                openSdgroup=@usercode,  
				opensdgroupName=@userName,   
                OpenSdorgID = @OpenSdorgId,
                ReturnReasons=@remark,
				ReturnUsercode=@usercode   
         WHERE  DocCode = @doccode   
         SELECT @linkdocinfo = CAST(@formid AS VARCHAR) + ';16;' + @doccode     
                --end    
     END        
 END    
 --转移单据
 If @CheckType='开户审核' and @checkstate='通过审核'
	BEGIN
		 BEGIN TRY
 			Exec sp_TranseferDocToMainServer @formid,@doccode,'',@usercode,@TerminalID
 
		 END TRY
		 Begin catch
			Select @tips='单据审核失败,单据无法转移.'+dbo.crlf()+'异常原因:'+Isnull(Error_Message(),'')+dbo.crlf()+'请联系系统管理员.'
 			Raiserror(@tips,16,1)
 			return
		 END CATCH
	END
 BEGIN    
  -- select * from CheckNumberAllocationDoc_LOG                              
  /******************************************************************消息通知*************************************************************/     

  --记录审核操作                                
  INSERT INTO CheckNumberAllocationDoc_LOG (  checktype, doccode, formid,     
         seriesnumber, checkstate, entername, enterdate, remark, UserName,     
         doctype, formtype, sdorgid, sdorgname, reason,packageid,packagename  )    
  VALUES (   @CheckType,  @doccode,  @formid,  @seriesnumber,  @checkstate,      
         @usercode,  GETDATE(),  @remark,  @userName,  @doctype,  @formtype,  @sdorgid,  @sdorgName,  @reason,@packageID,@packageName  )     
  --发送电子邮件                              
  DECLARE @subject  VARCHAR(200),    
          @body     VARCHAR(2000)      
      
  SELECT @subject = '单据[' + @doccode + ']审核通知',    
         @body = '您所提交的单据[' + @doccode + ']已审核完毕.' + CHAR(10) +    
         '审核状态:' + @checkstate + CHAR(10) +    
         '审核人:' + @username + CHAR(10) +    
         '审核时间:' + CONVERT(VARCHAR(20), GETDATE(), 120) + CHAR(10) +    
         '审核说明:' + @remark + CHAR(10) +    
         '请尽快处理该单!'     
      
  --EXEC sp_sendemail @usercode,@applyer,@subject,@body       
  RETURN    
 END    
END
