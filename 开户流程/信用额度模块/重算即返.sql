select * from dbo.fn_QueryDocWaitForAudit('2012-04-20','2012-04-24','','','','','','','SYSTEM','运营商一次稽核')

BEGIN TRAN
DELETE FROM Unicom_OrderDetails WHERE DocCode='PS20120422001011' AND MatCode IS NULL

COMMIT

BEGIN TRAN
EXEC sp_ExecAfterSaveDoc 9146,'PS20120422000109','',''

ROLLBACK


BEGIN TRAN
SET NOCOUNT ON;
DECLARE @Formid INT,@Doccode VARCHAR(20),@DocDate DATETIME,@Periodid VARCHAR(20),
@Commission MONEY,@Commission1 MONEY,@SDorgid VARCHAR(50),@ParentRowID VARCHAR(200) 
DECLARE abc CURSOR FAST_FORWARD READ_ONLY FOR 
SELECT uo.DocCode,Formid,Docdate,uo.periodid,Commission,uo.sdorgid,o.parentrowid--,uo.PostDate
FROM   Unicom_Orders uo WITH(NOLOCK),oSDOrg o WITH(NOLOCK)
WHERE  o.dptType = '加盟店'
       AND uo.sdorgid = o.sdorgid
       AND ISNULL(uo.commission, 0) = 0
       AND o.mintype IN ('专区','专柜')
       AND uo.docdate = '2012-04-22'
       AND uo.DocStatus!=0
       --AND o.SDOrgID='2.1.769.09.06'
ORDER BY uo.PostDate desc
       --AND uo.DocCode='RS20120422000022'
OPEN abc
FETCH NEXT FROM abc INTO @Doccode,@Formid,@DocDate,@Periodid,@Commission,@SDorgid,@ParentRowID
WHILE @@FETCH_STATUS=0
	BEGIN
		PRINT @Doccode
		--计算信用额度
		EXEC sp_ExecAfterSaveDoc @Formid,@Doccode,'','SYSTEM'
		--取出最新佣金
		SELECT @Commission1=commission FROM Unicom_Orders uo WITH(NOLOCK) WHERE uo.DocCode=@Doccode
		--标记
		UPDATE Unicom_Orders	SET HDText =ISNULL(HDText ,'')+ '|原佣金为'+convert(VARCHAR(20),isnull(@Commission,0)) where doccode=@doccode
		 --写总帐
		EXEC SetFsubLedger @doccode,@formid,'1001',@Docdate,'',@periodid
		--更新信用额度差额
		UPDATE oSDOrg	
			SET credit =ISNULL(credit,0)+ ISNULL(@Commission1,0)-ISNULL(@Commission,0)
		WHERE rowid=@ParentRowID 
		FETCH NEXT FROM abc INTO @Doccode,@Formid,@DocDate,@Periodid,@Commission,@SDorgid,@ParentRowID
	end
CLOSE abc
DEALLOCATE abc
 