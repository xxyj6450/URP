 
/*      
过程名称:sp_ChangeSIMStatus      
参数:见声名      
功能描述:修改SIM卡状态信息,统一过程修改,方便维护      
编写:三断笛      
时间:2011-12-22      
备注:      
-------      
修改:当SIM卡被锁定或被激活时,如果再被撤回或退回,不清空其单据信息及号码信息,因为此卡只能与此单此号码使用.允许此单再次提交      
select * from isiminfo      
exec [sp_ChangeSIMStatus] '89860112851004584272','8986011285100458427',1,'PS20120316001064',9146,5,18676044155,'','','ESS写卡成功!'      
SELECT @ICCID,@SeriesCode ,@ICCID ,@Status,@Doccode,@FormID,@SeriesNumber      
*/      
ALTER PROC [dbo].[sp_ChangeSIMStatus]      
 @ICCID VARCHAR(30),      
 @SeriesCode VARCHAR(30) = '',      
 @Status INT,      
 @Doccode VARCHAR(20) = '',      
 @FormID INT = '',      
 @Formtype INT = 1,      
 @SeriesNumber VARCHAR(20) = '',      
 @sdgroup VARCHAR(30) = '',      
 @Sdorgid VARCHAR(50) = '',      
 @remark VARCHAR(500) = '',      
 @OptionID VARCHAR(50) = ''      
AS      
BEGIN  
 SET NOCOUNT ON;  
   
 DECLARE @Tips       VARCHAR(4000),  
         @TranCount  INT   
 --将卡号信息存入临时表      
 SELECT * INTO #iSIMInfo  
 FROM   iSIMInfo is1  
 WHERE  is1.ICCID = @ICCID   
 --IF @@ROWCOUNT=0 return  
 --将串号改回未使用状态      
 IF @Status = 0  
 BEGIN  
     --已激活的不允许解锁      
     /*IF EXISTS(SELECT 1 FROM #iSIMInfo is1 WHERE is1.isActived=1)      
     BEGIN      
     RAISERROR('SIM卡已激活,不允许解锁SIM卡.',16,1)      
     return      
     END*/
     if isnull(@OptionID,'')=''
		BEGIN
			--如果卡尚未锁定,则将卡与单绑定的信息清空      
			 IF EXISTS(  
					SELECT 1  
					FROM   #iSIMInfo is1  
					WHERE  is1.ICCID = @ICCID  
						   AND isnull(doccode,@Doccode) = @Doccode  
						   AND isnull(is1.SeriesNumber,@SeriesNumber) = @SeriesNumber  
						   AND isnull(is1.isLocked,0) = 0  
				)  
			 BEGIN  
				 UPDATE iSIMInfo  
				 SET    [Status] = 0,  
						doccode = NULL,  
						SeriesNumber = NULL,  
						Formid = NULL, 
						IMSI = NULL  
				 WHERE  ICCID = @ICCID  
						AND isnull(Doccode,@Doccode) = @Doccode
			end
		END
     else if @OptionID='1'
		 BEGIN  
			 UPDATE iSIMInfo  
			 SET    [Status] = 0,  
					doccode = NULL,  
					SeriesNumber = NULL,  
					Formid = NULL, 
					IMSI = NULL,
					isLocked = 0,
					isActived = 0
			 WHERE  ICCID = @ICCID
		end
     INSERT INTO iSIMInfo_Log  
       ( SeriesCode,  ICCID,  USIM,  [Event],  Sdgroup,  sdorgID,    
         Doccode,  Formid,  FormType,  Remark )  
     SELECT LEFT(@ICCID,19), @ICCID, @ICCID, '解除锁定', @sdgroup, @sdorgid,   
            @doccode, @formid, @formtype, @remark  
      --如果卡已锁定,则只清空单据信息      
        /*IF EXISTS(SELECT 1 FROM #iSIMInfo is1 WHERE is1.ICCID=@ICCID AND @Doccode=@Doccode AND is1.SeriesNumber=@SeriesNumber AND is1.isLocked=1)      
        begin      
        UPDATE iSIMInfo      
        SET [Status] = 0,      
        doccode=NULL,      
        SeriesNumber = NULL,      
        FormID=null      
        WHERE ICCID=@ICCID      
        AND Doccode=@Doccode      
        end*/  
 END   
 --提交审核时,退回单据时,解除锁定时      
 IF @Status = 1  
 BEGIN  
     --如果是提交审核时      
     IF ISNULL(@OptionID, '') = ''  
     BEGIN  
         --如果串号不等于ICCID的前19位则报错      
         /*IF @SeriesCode <> LEFT(@ICCID, 19)  
         BEGIN  
             RAISERROR('手机串号与ICCID前19位不一致!', 16, 1)   
             RETURN  
         END   */
           
         --检查是待绑定的空白卡是否在可绑定状态,此卡不能绑定有其他单据和号码的信息      
         IF EXISTS(  
                SELECT 1  
                FROM   #iSIMInfo is1  
                WHERE  is1.ICCID = @ICCID  
                       AND (  
                               ISNULL(doccode, @Doccode) <> @Doccode  
                               OR ISNULL(is1.SeriesNumber, @SeriesNumber) <>  @SeriesNumber  
                           )  
            )  --select * from iSIMInfo where seriescode='8986011285101654742'
				--update iSIMInfo set doccode='' where seriescode='8986011285101654742'
         BEGIN  
             SELECT @Tips = 'SIM卡已使用,请换卡!'   
             RAISERROR(@Tips, 16, 1)   
             RETURN  
         END   
         --检查卡的状态,如果是同一个号码,同一张卡,则不管它是否已锁定      
         IF EXISTS(  
                SELECT 1  
                FROM   #iSIMInfo is1  
                WHERE  is1.ICCID = @ICCID  
                       AND is1.isLocked = 1  
                       AND (  
                               ISNULL(seriesnumber, '') <> @SeriesNumber  
                               OR ISNULL(doccode, '') <> @Doccode  
                           )  
            )  
         BEGIN  
             RAISERROR('此卡已被锁定,必须解锁才能使用!', 16, 1)   
             RETURN  
         END  
           
         IF EXISTS(  
                SELECT 1  
                FROM   #iSIMInfo is1  
                WHERE  is1.ICCID = @ICCID  
                       AND is1.isActived = 1  
                       AND (  
                               ISNULL(SeriesNumber, '') <> @SeriesNumber  
                               OR ISNULL(doccode, '') <> @doccode  
                           )  
            )  
         BEGIN  
             RAISERROR('此卡已激活,无法使用!', 16, 1)   
             RETURN  
         END   
         --如果是同一张卡,同一个号码,则不管它是否已写      
         IF EXISTS(  
                SELECT 1  
                FROM   #iSIMInfo is1  
                WHERE  is1.ICCID = @ICCID  
                       AND is1.isWriteen = 1  
                       AND (  
                               ISNULL(seriesnumber, '') <> @SeriesNumber  
                               OR ISNULL(doccode, '') <> @Doccode  
                           )  
            )  
         BEGIN  
             RAISERROR('此卡已写,请换卡!', 16, 1)   
             RETURN  
         END  
           
         IF EXISTS(  
                SELECT 1  
                FROM   #iSIMInfo is1  
                WHERE  is1.ICCID = @ICCID  
                       AND is1.isValid <> 1  
            )  
         BEGIN  
             RAISERROR('此卡已作废或被禁用!', 16, 1)   
             RETURN  
         END  
           
         IF dbo.isValidSeriesNumber(@SeriesNumber, 0) <> 1  
         BEGIN  
             RAISERROR('输入的号码无效,请重新输入!', 16, 1)   
             RETURN  
         END  
           
         BEGIN TRY  
          --先解除此单与其他卡的绑定,但是只取消未写卡锁定的卡,已写过卡的不修改,依然保持绑定.      
          UPDATE iSIMInfo  
          SET    [Status] = 0,  
                 doccode = NULL,  
                 SeriesNumber = NULL,  
                 City = NULL,  
                 Brand = NULL,  
                 BipCode = NULL,  
                 ProcID = NULL,  
                 CardType = NULL,  
                 IMSI = NULL,  
                 OptionID = NULL  
          WHERE  Doccode = @Doccode  
                 AND @FormID = @FormID  
                 AND ICCID <> @ICCID  
                 AND SeriesNumber = @SeriesNumber  
                 AND ISNULL(isLocked, 0) = 0  
            
          IF @@ROWCOUNT <> 0  
          BEGIN  
              INSERT INTO iSIMInfo_Log  
                ( SeriesCode,  ICCID,  USIM,  [Event],  Sdgroup,  sdorgID,    
                  Doccode,  Formid,  FormType,  Remark,  seriesnumber )  
              SELECT LEFT(@ICCID,19), @ICCID, @ICCID, '解除锁定', @sdgroup, @sdorgid,   
                     @doccode, @formid, @formtype,   
                     'SIM卡提交审核,解除原卡绑定', @seriesnumber  
          END   
          --再重新绑定      
          UPDATE iSIMInfo  
          SET    [Status] = 1,  
                 Formid = @FormID,  
                 doccode = @Doccode,  
                 SeriesCode = LEFT(@ICCID,19),  
                 USIM = @ICCID,  
                 SeriesNumber = @SeriesNumber  
          WHERE  iccid = @ICCID   
          --  SELECT * FROM iSIMInfo is1      
          IF @@ROWCOUNT = 0  
          BEGIN  
              INSERT INTO iSIMInfo  
                ( ICCID,  SeriesCode,  USIM,  [Status],  Doccode,  FormID,    
                  SeriesNumber )  
              SELECT @ICCID, LEFT(@ICCID,19), @ICCID, @Status, @Doccode, @FormID,   
                     @SeriesNumber  
          END   
          --记录绑定事件      
          INSERT INTO iSIMInfo_Log  
            ( SeriesCode,  ICCID,  USIM,  [Event],  Sdgroup,  sdorgID,    
              Doccode,  Formid,  FormType,  Remark,  SeriesNumber )  
          SELECT LEFT(@ICCID,19), @ICCID, @ICCID, '提交审核', @sdgroup, @sdorgid,   
                 @doccode, @formid, @formtype, @remark, @seriesnumber  
         END TRY      
         BEGIN CATCH  
          SELECT @Tips = '提交读卡失败!' + dbo.crlf() + ISNULL(ERROR_MESSAGE(), '')  
          INSERT INTO iSIMInfo_Log  
            ( SeriesCode,  ICCID,  USIM,  [Event],  Sdgroup,  sdorgID,    
              Doccode,  Formid,  FormType,  Remark,  SeriesNumber )  
          SELECT LEFT(@ICCID,19), @ICCID, @ICCID, '提交审核失败', @sdgroup, @sdorgid,   
                 @doccode, @formid, @formtype, @Tips, @SeriesNumber  
            
          RAISERROR(@Tips, 16, 1)   
          RETURN  
         END CATCH  
     END--撤回审核  
     ELSE   
     IF @OptionID = 'WithDraw'  
     BEGIN  
         UPDATE iSIMInfo  
         SET    [Status] = 1,  
                isActived = 1  
         FROM   iSIMInfo is1  
         WHERE  ICCID = @ICCID  
                AND Doccode = @Doccode  
           
         INSERT INTO iSIMInfo_Log  
           ( SeriesCode,  ICCID,  USIM,  [Event],  Sdgroup,  sdorgID,    
             Doccode,  Formid,  FormType,  Remark,  SeriesNumber )  
         SELECT LEFT(@ICCID,19), @ICCID, @ICCID, '开户撤回审核', @sdgroup, @sdorgid,   
                @doccode, @formid, @formtype, @Tips, @SeriesNumber  
     END  
 END   
 --锁定,在ESS写卡成功时      
 IF @Status = 2  
 BEGIN  
     --如果卡号不存在,则直接退出      
     IF NOT EXISTS(  
            SELECT 1  
            FROM   #iSIMInfo is1  
            WHERE  is1.ICCID = @ICCID  
        )  
         RETURN   
     --如果已经写卡成功,则直接退出      
     IF EXISTS(  
            SELECT 1  
            FROM   #iSIMInfo is1  
            WHERE  iccid = @ICCID  
                   AND STATUS = 2  
                   AND ISNULL(islocked, 0) = 1  
        )  
     BEGIN  
         RETURN  
     END  
       
     IF NOT EXISTS(  
            SELECT 1  
            FROM   #iSIMInfo is1  
            WHERE  is1.ICCID = @ICCID  
                   AND ISNULL(is1.isActived, 0) = 0  
                   AND ISNULL(is1.isLocked, 0) = 0  
        )  
     BEGIN  
         RAISERROR('SIM卡不在可写状态,请检查!', 16, 1)   
         RETURN  
     END  
       
     UPDATE iSIMInfo  
     SET    isLocked = 1,  
            [Status] = 2  
     WHERE  ICCID = @ICCID  
       
     INSERT INTO iSIMInfo_Log  
       ( SeriesCode,  ICCID,  USIM,  [Event],  Sdgroup,  sdorgID,  Doccode,    
         Formid,  FormType,  Remark,  SeriesNumber )  
     SELECT LEFT(@ICCID,19), @ICCID, @ICCID, '锁定SIM卡', @sdgroup, @sdorgid, @doccode,   
            @formid, @formtype, @remark, @seriesnumber  
       
     RETURN  
 END   
 --激活,在ESS确认单据时执行      
 IF @Status = 3  
 BEGIN  
  --处理尾数为00000000的专用号码  
  IF Exists(Select 1 From #iSIMInfo where right(SeriesNumber,8)='00000000')  
   begin  
    update iSIMInfo   
     set Seriesnumber=@Seriesnumber  
    where iccid=@iccid  
    update #iSIMInfo   
     set Seriesnumber=@Seriesnumber  
    where iccid=@iccid  
   end  
     IF NOT EXISTS(  
            SELECT 1  
            FROM   #iSIMInfo  
        )  
         RETURN   
     --必须在ESS写卡,激活成功才允许通过审核      
     IF NOT EXISTS(  
            SELECT 1  
            FROM   #iSIMInfo is1  
            WHERE  is1.ICCID = @ICCID  
                   AND is1.isLocked = 1  
        )  
     BEGIN  
         RAISERROR('SIM卡尚未在ESS写卡并确认成功,不允许通过审核', 16, 1)   
         RETURN  
     END   
     --SIM卡必须是与本单进行的绑定      
     IF NOT EXISTS(  
            SELECT 1  
            FROM   #iSIMInfo is1  
            WHERE  is1.ICCID = @ICCID  
                   AND ISNULL(is1.Doccode,@Doccode) = @Doccode  
                   AND isnull(SeriesNumber,@SeriesNumber) = @SeriesNumber  
                   AND isnull(is1.FormID,@FormID) = @FormID  
        )  
     BEGIN  
         RAISERROR('SIM卡尚未与本单据绑定,请联系系统管理员.', 16, 1)   
         RETURN  
     END   
     --      
     UPDATE iSIMInfo  
     SET    isActived = 1,  
            [Status] = 3  
     WHERE  ICCID = @ICCID  
       
     INSERT INTO iSIMInfo_Log  
       ( SeriesCode,  ICCID,  USIM,  [Event],  Sdgroup,  sdorgID,  Doccode,    
         Formid,  FormType,  Remark,  SeriesNumber )  
     SELECT LEFT(@ICCID,19), @ICCID, @ICCID, '激活SIM卡', @sdgroup, @sdorgid, @doccode,   
            @formid, @formtype, @remark, @seriesnumber  
       
     RETURN  
 END   
 --写卡,URP执行      
 IF @Status = 4  
 BEGIN  
     --必须在ESS写卡,激活成功才允许通过审核      
     IF NOT EXISTS(  
            SELECT 1  
  FROM   #iSIMInfo is1  
            WHERE  is1.ICCID = @ICCID  
                   AND is1.isLocked = 1  
                   AND is1.isActived = 1  
        )  
     BEGIN  
         RAISERROR('SIM卡尚未在ESS写卡并确认成功,不允许通过审核', 16, 1)   
         RETURN  
     END   
     --SIM卡必须是与本单进行的绑定      
     IF NOT EXISTS(  
            SELECT 1  
            FROM   #iSIMInfo is1  
            WHERE  is1.ICCID = @ICCID  
                   AND isnull(doccode,@Doccode) = @Doccode  
                   AND isnull(SeriesNumber,@SeriesNumber) = @SeriesNumber  
        )  
     BEGIN  
         RAISERROR('SIM卡尚未与本单据绑定,请联系系统管理员.', 16, 1)   
         RETURN  
     END  
       
     UPDATE iSIMInfo  
     SET    isWriteen = 1,  
            STATUS = 4,  
            WritenDate = GETDATE(),  
            WriteenCount = ISNULL(WriteenCount, 0) + 1  
     WHERE  ICCID = @ICCID  
       
     INSERT INTO iSIMInfo_Log  
       ( SeriesCode,  ICCID,  USIM,  [Event],  Sdgroup,  sdorgID,  Doccode,    
         Formid,  FormType,  Remark,  SeriesNumber )  
     SELECT LEFT(@ICCID,19), @ICCID, @ICCID, 'SIM卡写卡', @sdgroup, @sdorgid, @doccode,   
            @formid, @formtype, @remark, @SeriesNumber  
     --记录操作    
  INSERT INTO CheckNumberAllocationDoc_LOG(doccode,formid,checkstate,entername,UserName,remark,enterdate,seriesnumber)    
  VALUES(@doccode,@formid,'门店写卡',@sdgroup,NULL,NULL,getdate(),@seriesnumber)    
     RETURN  
 END  
END