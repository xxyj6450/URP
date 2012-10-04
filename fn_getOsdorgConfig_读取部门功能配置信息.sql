 
 
/*  
* ��������:[fn_getSDOrgConfig]  
* ��������:��ȡ�ŵ����ò���.�����ŵ�δ���ò���,���Զ��̳���һ�㲿�ŵ�����,�����δ����,�򷵻�Ĭ��ֵ  
* ����:������  
* ����ֵ:�������ò���  
* ��д:���ϵ�  
* ʱ��:2011-04-08  
* ��ע:sp_getSDOrgconfig�洢����Ҳ�д˹���,����Ĭ��ֵ��������  
* select dbo.fn_getsdorgconfig('1.1.769.13.02','dptOpenAcccountLimit')  
*/  
ALTER FUNCTION [fn_getSDOrgConfig]
(
	@sdorgid    VARCHAR(40),
	@Parameter  VARCHAR(50)
)
RETURNS VARCHAR(500)
AS
  
BEGIN
	DECLARE @value  VARCHAR(500),@Value1 VARCHAR(500)
	DECLARE @path   VARCHAR(200)  
	DECLARE @TABLE  TABLE(
	            sdorgid VARCHAR(50),
	            LEVEL INT PRIMARY KEY,	--�˴�����������������  
	            autocheck BIT,
	            uploadvoucher BIT,
	            ShareSeriesPool BIT,
	            AllowOuterNumber BIT,
	            LockCheckOut BIT,
	            rwCardBackground BIT DEFAULT 1,
	            ContactAddressFormat VARCHAR(200),
	            BlackListCheck BIT DEFAULT 1,
	            ContactAddressErrorInfo VARCHAR(500),
	            MinAge int,
	            LimitOpenAccount int,
	            dptOpenAcccountLimit int
	        ) 
	--DECLARE @sdorgid VARCHAR(50),@path VARCHAR(200)  
	SELECT @path = PATH
	FROM   oSDOrg os with(nolock)
	WHERE  os.SDOrgID = @sdorgid 
	;WITH /*cte_sdorgid(sdorgid,rowid,parentrowid,LEVEL,autocheck,uploadvoucher,ShareSeriesPool,AllowOuterNumber,LockCheckOut,rwCardBackground) AS(  
	SELECT sdorgid,rowid,parentrowid,0,autocheck,uploadvoucher,ShareSeriesPool,AllowOuterNumber,LockCheckOut,rwCardBackground
	FROM view_SDorgConfig a  
	WHERE a.sdorgid='1.1.769.07.04'  
	UNION ALL  
	SELECT a.sdorgid,a.rowid,a.parentrowid,b.level+1,a.autocheck,a.uploadvoucher,a.ShareSeriesPool,a.AllowOuterNumber,a.LockCheckOut,a.rwCardBackground
	FROM view_SDorgConfig a,cte_sdorgid b   
	WHERE a.rowid=b.parentrowid  
	),*/cte_sdorgid(
	    sdorgid,
	    LEVEL,
	    autocheck,
	    uploadvoucher,
	    ShareSeriesPool,
	    AllowOuterNumber,
	    LockCheckOut,
	    rwCardBackground,
	    ContactAddressFormat,
	    BlackListCheck,
	    ContactAddressErrorInfo,
	    MinAge,LimitOpenAccount,dptOpenAcccountLimit
	) AS(
	    SELECT sdorgid,  b.level AS LEVEL,  autocheck,  uploadvoucher,  
	           ShareSeriesPool,  AllowOuterNumber,  LockCheckOut,  
	           rwCardBackground,ContactAddressFormat,BlackListCheck,ContactAddressErrorInfo,MinAge,LimitOpenAccount,dptOpenAcccountLimit
	    FROM    SPLIT(@path, '/') b,   view_SDorgConfig a  with(nolock)
	    WHERE  a.SDOrgID = b.list
	) 
	
	INSERT INTO @table
	SELECT sdorgid,  LEVEL,  autocheck,  uploadvoucher,  ShareSeriesPool,  
	       AllowOuterNumber,  LockCheckOut,  rwCardBackground,ContactAddressFormat,BlackListCheck,ContactAddressErrorInfo,MinAge,LimitOpenAccount,dptOpenAcccountLimit
	FROM   cte_sdorgid  with(nolock)
	
	IF @parameter = 'autocheck'
	BEGIN
	    SELECT TOP 1 @value = autocheck
	    FROM   @table
	    WHERE  autocheck IS NOT NULL
	    ORDER BY   LEVEL DESC
	    
	    IF @value IS NULL
	        SET @value = 1
	END 
	--select * from cte_sdorgid  
	IF @parameter = 'uploadvoucher'
	BEGIN
	    SELECT TOP 1 @value = uploadvoucher
	    FROM   @table
	    WHERE  uploadvoucher IS NOT NULL
	    ORDER BY   LEVEL DESC
	    
	    IF @value IS NULL
	        SET @value = 1
	END
	
	IF @Parameter = 'ShareSeriesPool'
	BEGIN
	    SELECT TOP 1 @value = ShareSeriesPool
	    FROM   @table
	    WHERE  ShareSeriesPool IS NOT NULL
	    ORDER BY   LEVEL DESC
	    
	    IF @value IS NULL
	        SET @value = 0
	END
	
	IF @Parameter = 'AllowOuterNumber'
	BEGIN
	    SELECT TOP 1 @value = AllowOuterNumber
	    FROM   @table
	    WHERE  AllowOuterNumber IS NOT NULL
	    ORDER BY   LEVEL DESC
	    
	    IF @value IS NULL
	        SET @value = 0
	END
	
	IF @Parameter = 'LockCheckOut'
	BEGIN
	    SELECT TOP 1 @value = LockCheckOut
	    FROM   @table
	    WHERE  LockCheckOut IS NOT NULL
	    ORDER BY   LEVEL DESC
	    
	    IF @value IS NULL
	        SET @value = 0
	END
	
	IF @Parameter = 'rwCardBackground'
	BEGIN
	    SELECT TOP 1 @value = rwCardBackground
	    FROM   @table
	    WHERE  rwCardBackground IS NOT NULL
	    ORDER BY   LEVEL DESC
	    
	    IF @value IS NULL
	        SET @value = 1
	END
	--��ϵ�˵�ַ��ʽ
	IF @Parameter='ContactAddressFormat'
	BEGIN
	    SELECT TOP 1 @value = isnull(ContactAddressFormat,'')+'|'+isnull(ContactAddressErrorInfo,'')
	    FROM   @table
	    WHERE  isnull(ContactAddressFormat,'')!=''
	    ORDER BY   LEVEL DESC
	    
	    IF @value IS NULL  
			SET @value = ''
 
	END
	--���������
	IF @Parameter='BlackListCheck'
	BEGIN
	    SELECT TOP 1 @value = BlackListCheck 
	    FROM   @table
	    WHERE  isnull(BlackListCheck,'')!=''
	    ORDER BY   LEVEL DESC
	    
	    IF @value IS NULL  SET @value = 1
	END
	--���������
	IF @Parameter='MinAge'
	BEGIN
	    SELECT TOP 1 @value = MinAge 
	    FROM   @table
	    WHERE  isnull(MinAge,'')!=''
	    ORDER BY   LEVEL DESC
	    IF @value IS NULL SET @value=18
	END
	--����������
	IF @Parameter='LimitOpenAccount'
	BEGIN
	    SELECT TOP 1 @value = LimitOpenAccount 
	    FROM   @table
	    WHERE  isnull(LimitOpenAccount,'')!=''
	    ORDER BY   LEVEL DESC
	    IF @value IS NULL SET @value=0
	END
	--dptOpenAcccountLimit
	IF @Parameter='dptOpenAcccountLimit'
	BEGIN
	    SELECT TOP 1 @value = dptOpenAcccountLimit 
	    FROM   @table
	    WHERE  isnull(dptOpenAcccountLimit,'')!=''
	    ORDER BY   LEVEL DESC
	    IF @value IS NULL SET @value=0
	END
	RETURN @value
END


