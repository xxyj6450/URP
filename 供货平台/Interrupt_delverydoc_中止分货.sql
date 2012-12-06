alter PROC [dbo].[Interrupt_deliverydoc]    
(@doccode VARCHAR(50),@source VARCHAR(50),@user VARCHAR(50),@refcode VARCHAR(50),@zldcode VARCHAR(50)    
)    
AS    
SET NOCOUNT ON    
SET XACT_ABORT ON    
BEGIN    
 DECLARE @gooddoccode VARCHAR(50),@sdorgid VARCHAR(50),@Source1 VARCHAR(50),@companyid VARCHAR(50)    
 DECLARE @sql VARCHAR(2000) ,@Status VARCHAR(500)
 DECLARE @formid VARCHAR(50),@DocStatus int
 
	SELECT @sdorgid=cltcode ,@Status=Usetxt5,@Docstatus=DocStatus
	FROM imatdoc_h WITH(NOLOCK)
	WHERE DocCode=@doccode
	IF ISNULL(@DocStatus,0)=0
		BEGIN
			RAISERROR('单据尚未确认,不允许中止发货.',16,1)
			return
		END
	IF ISNULL(@Status,'')<>''
		BEGIN
			RAISERROR('当前指令单已处理,不允许中止发货.',16,1)
			return
		END
	UPDATE imatdoc_h SET Usetxt5='中止发货' WHERE DocCode=@doccode;

	EXEC  sp_UpdateCredit 6052,@doccode,@sdorgid,0,'2','发货中止,取消额度冻结.'

	----结束
	/*BEGIN tran
   EXEC  sp_UpdateCredit 6052,'DTZ2012112800146','2.1.769.09.29',0,'2','发货中止,取消额度冻结.'
   SELECT * FROM oSDOrgCreditFlow oscf WHERE oscf.FlowInstanceID='DD20121128000200'
   SELECT * FROM oSdorgCreditLog oscl WHERE oscl.FlowInstanceID='DD20121128000200'
   commit
   */
END