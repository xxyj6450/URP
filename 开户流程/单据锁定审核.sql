/*                          
* 函数名称：sp_LockCheckingDoc      
* 功能描述：锁定待审核的单据      
* 参数:见声名部分                          
* 编写：三断笛                          
* 时间：2010/07/13                       
* 备注：将指定的单据锁定由谁审核,只有当前锁定人可以审核该单,其他人不能重复审核      
* 示例：      
* --------------------------------------------------------------------                          
* 修改：                          
* 时间：                          
* 备注：  
  
* begin tran  exec sp_LockCheckingDoc 9237,'RS20120406000546','013005','陈鹊燕',1  rollback      
 exec sp_LockCheckingDoc 9237,'RS20120406000546','system','管理员',1                          
*/        
CREATE PROC [dbo].[sp_LockCheckingDoc]      
 @formid INT,       --功能号      
 @doccode VARCHAR(20),     --单号      
 @usercode VARCHAR(30),     --审核人工号      
 @userName VARCHAR(50),     --审核人姓名      
 @Locked BIT = 1,       --是否锁定  
 @terminalID VARCHAR(50) = '',  
 @OptionID VARCHAR(100) = '',  
 @Remark VARCHAR(500) = '',
 @CheckType VARCHAR(20) = '开户审核'  
AS      
--SELECT * FROM _sysUser su WHERE su.Username='陈鹊燕'  
BEGIN  
 /************************************************公共变量定义**************************************************/      
 DECLARE @seriesnumber VARCHAR(20),  
         @Audits VARCHAR(500),  
         @AuditsName VARCHAR(500),  
         @tips VARCHAR(200),  
         @applyer VARCHAR(500),  
         @applyerName VARCHAR(500),
         @packageID VARCHAR(20),
         @PackageName VARCHAR(200)
   
 DECLARE @doctype VARCHAR(40),  
         @sdorgid VARCHAR(20),  
         @sdorgName VARCHAR(120),  
         @bitCanLockMultDocs int  
   
 DECLARE @formtype        INT,  
         @rowcount        INT,  
         @msg             VARCHAR(MAX),  
         @Auditingdate    DATETIME,  
         @LockDocNoOrder  BIT,  
         @AreaID          VARCHAR(100),  
         @tranCount       INT  ,
         @LockedCount int
   
 SET NOCOUNT ON;      
 IF @doccode = ''  
    OR @formid = ''  
    OR @usercode = ''  
    OR @userName = ''  
     RETURN  
   
 SELECT @msg = CHAR(10) +   
        '您可锁定的单据已超过上限,请及时释放单据,或联系管理员.'  
        + CHAR(10)  
 SELECT @AreaID = ISNULL(naa.AreaID, ''),  
        @LockDocNoOrder = ISNULL(naa.bitCanLockDocOutOfOrder, 0),  
        @bitCanLockMultDocs = ISNULL(bitCanLockMultDocs, 0)  
 FROM   NumberAllocationAudits naa  
 WHERE  naa.Usercode = @usercode
 
 /************************************************客户新入网及套包销售审核锁定*********************************/  
 IF @Locked = 1  
    --AND @usercode NOT IN ('system')  
    AND @bitCanLockMultDocs > 0  
 BEGIN  
 	--运营商一次稽核限制锁多单
	 /*IF @bitCanLockMultDocs>0 AND @CheckType IN('运营商一次稽核') 
		BEGIN
			SELECT @LockedCount=0
			 SELECT @LockedCount=COUNT(*)
			 FROM Unicom_Orders uo WITH(NOLOCK)
			 WHERE uo.Audits=@usercode
			 AND   EXISTS(SELECT 1 FROM CheckNumberAllocationDoc_LOG x WITH(NOLOCK)
							WHERE  x.doccode=uo.DocCode AND x.checkType='运营商一次稽核' and x.checkstate='锁定单据')
			 IF @LockedCount>@bitCanLockMultDocs
				BEGIN
					SELECT @msg='您已锁定'+convert(VARCHAR(5),@lockedcount-1)+'张单据,已超过上限,请及时释放单据,或联系管理员'
					RAISERROR(@msg,16,1)
					return
				END
			 SELECT @LockedCount=@LockedCount+COUNT(*)
			 FROM BusinessAcceptance_H  uo WITH(NOLOCK)
			 WHERE uo.Audits=@usercode
			 AND   EXISTS(SELECT 1 FROM CheckNumberAllocationDoc_LOG x WITH(NOLOCK)
							WHERE  x.doccode=uo.DocCode AND x.checkType='运营商一次稽核' and x.checkstate='锁定单据')
			 IF @rowcount>@bitCanLockMultDocs
				BEGIN
					SELECT @msg='您已锁定'+convert(VARCHAR(5),@lockedcount-1)+'张单据,已超过上限,请及时释放单据,或联系管理员'
					RAISERROR(@msg,16,1)
					return
				END
	 
		END */
	IF @CheckType IN('开户审核')
		begin
			 --锁定单据时,检查是否锁定多单  
			 SELECT @msg = @msg + doccode + CHAR(10)  
			 FROM   Unicom_Orders uo WITH(NOLOCK)  
			 WHERE  uo.checkState = '待审核'  
					AND audits = @usercode  
					AND DATEDIFF(DD, uo.DocDate, GETDATE()) <= 7  
					AND docstatus = 0  
		       
			 SELECT @msg = @msg + doccode + CHAR(10)  
			 FROM   BusinessAcceptance_H uo WITH(NOLOCK)  
			 WHERE  uo.checkState = '待审核'  
					AND audits = @usercode  
					AND DATEDIFF(DD, uo.DocDate, GETDATE()) <= 7  
					AND docstatus = 0  
		       
			 IF LEN(@msg) > 40  
			 BEGIN  
				 RAISERROR(@msg, 16, 1)  
				 RETURN  
			 END
		end
 END  
   
 IF @formid IN (9102, 9146, 9237,9244)  
 BEGIN  
     SELECT @seriesnumber = seriesnumber,  
            @Audits = isnull(audits,''),  
            @AuditsName = isnull(uo.Auditingname,''),  
            @applyer = uo.applyer,  
            @applyerName = uo.applyerName,  
            @Auditingdate = uo.Auditingdate,  
            @doctype = uo.DocType,  
            @sdorgid = uo.sdorgid,  
            @sdorgName = uo.sdorgname,
            @packageID=uo.PackageID,
            @PackageName=uo.PackageName,
            @formtype = 5 --取原审核人信息  
     FROM   Unicom_Orders uo  WITH(NOLOCK) 
     WHERE  uo.DocCode = @doccode  
		
 
     IF @Audits = @usercode  
        OR ISNULL(@Audits, '') = ''  
        OR @usercode IN ('system','012988','016497','016268','100225','100225') --如果未绑定或是被自己绑定或者是管理员身份才允许操作  
     BEGIN  
	 
         IF @Locked = 1 --锁定审核  
         BEGIN  
             --限制按序锁单  
             /*IF EXISTS(SELECT 1 FROM Unicom_Orders uo LEFT JOIN oSDOrg os ON uo.sdorgid=os.SDOrgID  
             WHERE uo.checkState='待审核'   
             and isnull(audits,'')=''   
             AND uo.Auditingdate<@Auditingdate   
             AND (@areaid='' or exists(select 1 from split(@areaid,',') d where  os.areaid LIKE d.list+'%' ))  
             --AND @usercode NOT in('system')  
             AND @LockDocNoOrder=0)  
             BEGIN  
             RAISERROR('请按提单顺序锁单!',16,1)  
             return  
             END*/  
  
               
             UPDATE Unicom_Orders  
             SET    Audits = @usercode,  
                    Auditingname = @userName,  
                    systemOption = @OptionID,  
                    HDText = ISNULL(HDText, '') + @Remark  
             WHERE  DocCode = @doccode  
                    --AND (ISNULL(Audits, '') <> @usercode OR @usercode = 'SYSTEM')    2012-05-01
               SELECT @rowcount = @@ROWCOUNT  
  
         END  
         ELSE  
             --解除锁定  
         BEGIN  
             IF EXISTS(  
                    SELECT 1  
                    FROM   NumberAllocationAudits naa  
                    WHERE  naa.Usercode = @usercode  
                           AND naa.unLockPerday > 0  
                           AND unlockTimes = naa.unLockPerday  
                )  
             BEGIN  
                 RAISERROR('您今天的解锁次数已达上限,请联系组长.', 16, 1)  
                 RETURN  
             END  
             ELSE  
             BEGIN  
                 --如果日期与当前日期相同则累加1,否则置1  
                 UPDATE NumberAllocationAudits  
                 SET    unlocktimes  = CASE   
                                           WHEN ISNULL(CONVERT(VARCHAR(10), today, 120), '')  
                                                = CONVERT(VARCHAR(10), GETDATE(), 120) THEN   
                                                ISNULL(unlocktimes, 0) + 1  
                                           ELSE 1  
                                      END,  
                        today        = CONVERT(VARCHAR(10), GETDATE(), 120)  
                 WHERE  Usercode     = @usercode  
             END  
             UPDATE Unicom_Orders  
             SET    Audits = NULL,  
                    Auditingname = NULL,  
                    systemOption = @OptionID,  
                    HDText = ISNULL(HDText, '') + @Remark  
             WHERE  DocCode = @doccode  
                    AND (ISNULL(Audits, '') = @usercode OR  @usercode IN ('system','012988','016497','016268','100225','100225'))  
               
             SELECT @rowcount = @@ROWCOUNT  
			print @rowcount
         END  
     END  
     ELSE  
         --如果审核人是其他人则报错  
     BEGIN  
         SELECT @tips = CHAR(10) + '单据已被' + @auditsname + '锁定!'   
         RAISERROR(@tips, 16, 1)   
         RETURN  
     END  
 END   
 /************************************************其他业务受理审核锁定****************************************/      
 IF @formid IN (9153, 9158, 9159, 9160, 9165, 9167, 9180,9752,9755)  
 BEGIN  
     SELECT @seriesnumber = uo.SeriesNumber,  
            @Audits = audits,  
            @AuditsName = uo.Auditingname,  
            @applyer = uo.applyer,  
            @applyerName = uo.applyerName,  
            @doctype = uo.DocType,  
            @sdorgid = uo.SdorgID,  
            @sdorgName = uo.sdorgname,  
            @formtype = 16 --取原审核人信息  
     FROM   BusinessAcceptance_H uo  
     WHERE  uo.DocCode = @doccode   
     --select Audits,Auditingname,* from update BusinessAcceptance_H set audits=null where doccode='GH20101101000004'  
     IF @Audits = @usercode  
        OR ISNULL(@Audits, '') = ''  
        OR  @usercode IN ('system','012988','016497','016268','100225','100225')  
     BEGIN  
         IF @Locked = 1 --锁定审核  
         BEGIN  
             --限制按序锁单  
             /*IF EXISTS(SELECT 1 FROM BusinessAcceptance_H  uo LEFT JOIN oSDOrg os ON uo.sdorgid=os.SDOrgID  
             WHERE uo.checkState='待审核'   
             and isnull(audits,'')=''   
             AND uo.Auditingdate<@Auditingdate   
             AND (@areaid='' or exists(select 1 from split(@areaid,',') d where os.areaid LIKE d.list+'%' ))  
             AND @usercode NOT in('system')  
             AND @LockDocNoOrder=0)  
             BEGIN  
             RAISERROR('请按提单顺序锁单!',16,1)  
             return  
             END  
             */  
             UPDATE BusinessAcceptance_H  
             SET    Audits = @usercode,  
                    Auditingname = @userName,  
                    systemOption = @OptionID,  
                    Remark = ISNULL(Remark, '') + @Remark  
             WHERE  DocCode = @doccode  
                    AND (ISNULL(Audits, '') <> @usercode OR @usercode IN ('system','012988','016497','016268','100225','100225'))  
               
             SELECT @rowcount = @@ROWCOUNT  
         END  
         ELSE  
             --解除锁定  
         BEGIN  
             UPDATE BusinessAcceptance_H  
             SET    Audits = NULL,  
                    Auditingname = NULL,  
                    systemOption = @OptionID,  
                    Remark = ISNULL(Remark, '') + @Remark  
             WHERE  DocCode = @doccode  
                    AND (ISNULL(Audits, '') = @usercode OR  @usercode IN ('system','012988','016497','016268','100225','100225'))  
              
             SELECT @rowcount = @@ROWCOUNT  
			print @rowcount
         END  
     END  
     ELSE  
         --如果审核人是其他人则报错  
     BEGIN  
         SELECT @tips = CHAR(10) + '单据已被' + @auditsname + '锁定!'   
         RAISERROR(@tips, 16, 1)   
         RETURN  
     END  
 END   
   
 /*****************************************************邮件通知************************************************************/      
print @rowcount 
IF  @rowcount > 0  
 BEGIN  
     --记录审核操作        
     INSERT INTO CheckNumberAllocationDoc_LOG (  CheckType,doccode, formid,   
            seriesnumber, checkstate, entername, enterdate, remark, UserName,   
            doctype, formtype, sdorgid, sdorgname, TerminalID,packageid,packagename  )  
     VALUES (  @CheckType, @doccode,  @formid,  @seriesnumber,  CASE @locked  
                                                          WHEN 1 THEN   
                                                               '锁定审核'  
                                                          ELSE '解除锁定'  
                                                     END,  @usercode,    
            GETDATE(),  NULL,  @userName,  @doctype,  @formtype,  @sdorgid,  @sdorgName,  @terminalid,@packageID,@PackageName  )
end  
-------------------------------------------
if @Locked = 1 and @rowcount>0 
   begin  
     DECLARE @subject  VARCHAR(400),  
             @body     VARCHAR(MAX)  
       
     SELECT @subject = '您提交的' + ISNULL(@doctype, '') + '单据[' + ISNULL(@doccode, '')   
            + '正在被' + ISNULL(@username, '') + '审核'  
       
     SELECT @body = '您提交的' + @doctype + '单据[' + @doccode + '正在被' + @userName   
            + '审核,请耐心等候审核完成.' + CHAR(10) + '审核时间:' + CONVERT(VARCHAR(30), GETDATE(), 120)  
       
     PRINT '审核人:' + @Audits   
     PRINT '申请人:' + @applyer   
     --IF @applyer IS NOT NULL EXEC sp_SendEmail  @usercode,@applyer,@subject,@body  
 END  
---------------------------------------------
END