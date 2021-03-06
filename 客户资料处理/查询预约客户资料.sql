/************************************************************
 * 对象名称:$OBJECT$
 * 功能描述:
 * 参数说明:
 * 返 回 值:
 * 备    注:
 * 编    辑:
 * 时    间:2011-1-15 11:22:24
 ************************************************************/


ALTER FUNCTION [dbo].[fn_QueryPotentialCustomer1]
(
	@CustomerSource        VARCHAR(20),
	@InputDoccode          VARCHAR(20),
	@inputsdgroup          VARCHAR(20),
	@InputsdGroupName      VARCHAR(50),
	@inputBeginDate        DATETIME,
	@inputEndDate          DATETIME,
	@queueid               VARCHAR(40),
	@ReservationBeginDate  DATETIME,
	@ReservationEndDate    DATETIME,
	@reservationCode       VARCHAR(20),
	@sdorgid               VARCHAR(50),
	@sdorgname             VARCHAR(120),
	@sdgroup               VARCHAR(20),
	@sdgroupname           VARCHAR(50),
	@customercode          VARCHAR(20),
	@customerName          VARCHAR(20),
	@customerPhone         VARCHAR(20),
	@NickName              VARCHAR(20),
	@sex                   VARCHAR(2),
	@VourcherCode          VARCHAR(30),
	@ReservedNumber        VARCHAR(50),
	@ReservedCombo         VARCHAR(50),
	@ReservedSdorgid       VARCHAR(50),
	@ReservedSdOrgName     VARCHAR(120),
	@ReservedBeginDate     DATETIME,
	@reservedEndDate       DATETIME,
	@ReservedResult        VARCHAR(50),
	@ReceiveBeginDate      DATETIME,
	@ReceiveEnddate        DATETIME,
	@BusinessType          VARCHAR(50),
	@phoneType             VARCHAR(50),
	@Runners               VARCHAR(20),
	@RunnersPhone          VARCHAR(20),
	@ReceivedSdorgid       VARCHAR(50),
	@ReceivedSdordidName   VARCHAR(120),
	@ReceivedSdgroup       VARCHAR(20),
	@ReceivedSdgroupname   VARCHAR(20),
	@ReceivedResult        VARCHAR(50),
	@ProcessDoccode        VARCHAR(20),
	@processDocType        VARCHAR(20),
	@Status                VARCHAR(20)
)
RETURNS @table TABLE(
            [InputDoccode] [varchar](20),
            [InputFormid] [int],
            [InputSdgroup] [varchar](50),
            [InputsdGroupName] [varchar](50),
            [InputDate] [datetime],
            [InputRemark] [varchar](255),
            [QUEUEID] [varchar](40),
            [InDate] [datetime],
            [ReservationCode] [varchar](20),
            [ReservationDate] [datetime],
            [SdorgID] [varchar](50),
            [SdorgName] [varchar](120),
            [Sdgroup] [varchar](50),
            [SdgroupName] [varchar](50),
            [ReserveFormid] [int],
            [CustomerCode] [varchar](50),
            [CustomerName] [varchar](50),
            [CustomerPhone] [varchar](20),
            [Sex] [varchar](50),
            [NickName] [varchar](50),
            [VoucherCode] [varchar](50),
            [ReservedNumber] [varchar](50),
            [ReservedSdorgID] [varchar](50),
            [ReservedSdOrgName] [varchar](120),
            [ReservedRemark] [varchar](255),
            [ReservedDate] [datetime],
            [ReservedResult] VARCHAR(50),
            [ReceivedDate] [datetime],
            [ReservedCombo] [varchar](50),
            [BusinessType] [varchar](50),
            [PhoneType] [varchar](50),
            [Runners] [varchar](50),
            [RunnersPhone] [varchar](50),
            [ReceivedSdorgid] [varchar](50),
            [ReceivedSdorgName] [varchar](120),
            [ReceivedNumber] [varchar](20),
            [ReceivedDoccode] [varchar](20),
            [ReceivedSdgroup] [varchar](50),
            [ReceivedSdgroupName] [varchar](50),
            [ReceivedRemark] [varchar](255),
            [ReceivedResult] [bit],
            [ReceivedFormID] [int],
            [ProcessDoccode] [varchar](20),
            [ProcessFormid] [int],
            [ProcessDocctype] [int],
            [Status] [varchar](500),
            [Totalmoney] [money],
            [ReservedTimes] [int],
            [CustomerSource] [varchar](20),
            cardmoney money
        )
AS
BEGIN
	IF @reservationCode='' AND @customerPhone =''  RETURN
 
	INSERT INTO @table
	  (InputDoccode, InputFormid, InputSdgroup, InputsdGroupName, InputDate, InputRemark, QUEUEID, InDate, 
	   ReservationCode, ReservationDate, SdorgID, SdorgName, Sdgroup, SdgroupName, ReserveFormid, CustomerCode, 
	   CustomerName, CustomerPhone, Sex, NickName, VoucherCode, ReservedNumber, ReservedSdorgID, ReservedSdOrgName, 
	   ReservedRemark, ReservedDate, ReservedResult, ReceivedDate, ReservedCombo, BusinessType, PhoneType, Runners, 
	   RunnersPhone, ReceivedSdorgid, ReceivedSdorgName, ReceivedNumber, ReceivedDoccode, ReceivedSdgroup, 
	   ReceivedSdgroupName, ReceivedRemark, ReceivedResult, ReceivedFormID, ProcessDoccode, ProcessFormid, 
	   ProcessDocctype, STATUS, Totalmoney, ReservedTimes, CustomerSource,cardmoney )
	SELECT InputDoccode, InputFormid, InputSdgroup, InputsdGroupName, InputDate, InputRemark, QUEUEID, InDate, 
	       ReservationCode, ReservationDate, SdorgID, SdorgName, Sdgroup, SdgroupName, ReserveFormid, CustomerCode, 
	       CustomerName, CustomerPhone, Sex, NickName, VoucherCode, ReservedNumber, ReservedSdorgID, ReservedSdOrgName, 
	       ReservedRemark, ReservedDate, ReservedResult, ReceivedDate, ReservedCombo, BusinessType, PhoneType, Runners, 
	       RunnersPhone, ReceivedSdorgid, ReceivedSdorgName, ReceivedNumber, ReceivedDoccode, ReceivedSdgroup, 
	       ReceivedSdgroupName, ReceivedRemark, ReceivedResult, ReceivedFormID, ProcessDoccode, ProcessFormid, 
	       ProcessDocctype, STATUS, Totalmoney, ReservedTimes, CustomerSource,a.cardmoney
	FROM   PotentialCustomer a
	WHERE (@CustomerSource='' OR a.CustomerSource=@CustomerSource)
	AND (@InputDoccode='' OR a.InputDoccode=@InputDoccode)
	AND (@inputsdgroup='' OR a.InputSdgroup=@inputsdgroup)
	AND (@inputBeginDate='' OR a.InputDate>=@inputBeginDate)
	AND (@inputEndDate='' OR a.InputDate<=@inputEndDate)
	AND (@queueid='' OR a.QUEUEID=@queueid)
	AND (@reservationCode='' OR a.ReservationCode=@reservationCode)
	AND (@ReservationBeginDate='' OR a.ReservationDate>=@ReservationBeginDate)
	AND (@ReservationEndDate='' OR a.ReservationDate<=@ReservationEndDate)
	AND (@sdorgid='' OR a.SdorgID=@sdorgid) AND (@sdgroup='' OR a.Sdgroup=@sdgroup) 	
	AND (@customercode='' OR a.CustomerCode=@customercode) 	
	AND (@customerName='' OR a.CustomerName=@customerName) 	
	AND (@customerphone='' OR a.customerphone=@customerPhone)
	AND (@sex='' OR a.Sex=@sex) 
	AND (@NickName='' OR a.NickName=@NickName) 
	AND (@VourcherCode='' OR a.VoucherCode=@VourcherCode) 
	AND (@ReservedNumber='' OR a.ReservedNumber=@ReservedNumber)
	AND (@ReservedSdorgid='' OR a.ReservedSdorgID=@ReservedSdorgid) 
	AND (@ReservationBeginDate='' OR a.ReservationDate>=@ReservationBeginDate)
	AND (@ReservationEndDate='' OR a.ReservationDate<=@ReservationEndDate) 
	AND (@ReservedResult='' OR a.ReservedResult=@ReservedResult)
	AND (@ReservedBeginDate='' OR a.ReservedDate>=@ReservedBeginDate) 
	AND (@reservedEndDate='' OR a.ReservedDate<=@reservedEndDate)
	AND (@ReservedCombo='' OR a.ReservedCombo LIKE '%' +@ReservedCombo+'%') 	
	AND (@ReservedNumber='' OR a.ReservedNumber LIKE '%'+@ReservedNumber+'%')
	AND (@BusinessType='' OR a.BusinessType=@BusinessType) 	
	AND (@phoneType='' OR a.PhoneType LIKE '%' +@phoneType+'%')
	AND (@Runners='' OR a.Runners=@Runners) 	
	AND (@RunnersPhone='' OR a.RunnersPhone=@RunnersPhone)
	AND (@ReceiveBeginDate='' OR a.ReceivedDate>=@ReceiveBeginDate) 
	AND (@ReceiveEnddate='' OR a.ReceivedDate<=@ReceiveEnddate)
	AND (@ReceivedSdorgid='' OR a.ReceivedSdorgid=@ReceivedSdorgid)
	AND (@ReceivedSdgroup='' OR a.ReceivedSdgroup=@ReceivedSdgroup)
	AND (@ReceivedResult='' OR a.receivedresult=@ReceivedResult)
	AND (@ProcessDoccode='' OR a.ProcessDoccode=@ProcessDoccode)
	AND (@processDocType='' OR a.ProcessDocctype=@processDocType)
	AND (@Status='' OR a.[Status]=@Status)
	RETURN
END


--select * from PotentialCustomer



--select name +',' from syscolumns where id=object_id('PotentialCustomer')


