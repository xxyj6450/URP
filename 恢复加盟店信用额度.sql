
DECLARE @table TABLE(doccode VARCHAR(20))
DECLARE @doccode VARCHAR(20)
DECLARE abc CURSOR FOR 
SELECT 'PS20110601000577'union all
SELECT 'PS20110530000160'union all
SELECT 'PS20110524000249'union all
SELECT 'PS20110518000042'union all 
SELECT 'PS20110430000919'union all
SELECT 'PS20110426000238'union all
SELECT 'PS20110403000264'union all
SELECT 'PS20110324000099'union all
SELECT 'PS20110321000038'union all
SELECT 'PS20110318000054'union all
SELECT 'PS20110603000174'UNION ALL
SELECT 'PS20110627000162'
UNION ALL
SELECT a.DocCode
  FROM Unicom_Orders  a left join fsubledgerlog b ON  a.DocCode=b.doccode AND b.gltype='应收帐款-加盟商'
where a.PackageID='TBD2011080100002'
AND b.doccode IS NULL
AND a.DocStatus=100
AND a.DocCode NOT IN('PS20110802000286')
UNION ALL
SELECT doccode FROM Unicom_Orders uo WHERE uo.PackageID='TBD2011051700004'
AND ISNULL(uo.totalmoney2,0)=0
AND uo.DocStatus=100
UNION ALL
SELECT 'PS20110203000006'

OPEN abc
FETCH NEXT FROM abc INTO @doccode 
BEGIN tran
WHILE @@FETCH_STATUS=0
	BEGIN
		--删除运营业务明细
		DELETE FROM NumbeAllocation_Log WHERE Doccode=@doccode
		--取信用额度
		EXEC sp_getdoctotalmoney1 9146,@doccode
		--插入往来明细
		INSERT INTO fsubledgerlog( gltype, companyid, glcode,  CV1, 
       CV1name, subcode, 
       dcflag, currency, exchange_rate, amount_debit, natamount_debit, 
       formname, doctype, doccode, 
       docdate, formid,  periodid, memo, docword)
		SELECT '应收帐款-加盟商','101',113107, b.sdorgid,b.sdorgname,b.sdorgid,
			   '借','RMB',1.00,ISNULL(totalmoney2,0),ISNULL(totalmoney2,0),doctype,doctype,a.doccode,a.docdate,formid,a.periodid,'批量调整加盟店信用额度','记'
		FROM   Unicom_Orders a,oSDOrg b,osdorg c
		WHERE  a.DocCode =@doccode
		AND a.sdorgid=c.SDOrgID
		AND b.rowid=c.parentrowid
		
		INSERT INTO fsubledgerlog( gltype, companyid, glcode,   subcode, 
       dcflag, currency, exchange_rate, amount_credit, natamount_credit, 
       formname, doctype, doccode, 
       docdate, formid,  periodid, memo, docword)
		SELECT '临时调整科目','101',8888, b.sdorgid,
			   '贷','RMB',1.00,ISNULL(totalmoney2,0),ISNULL(totalmoney2,0),doctype,doctype,a.doccode,a.docdate,formid,a.periodid,'批量调整加盟店信用额度','记'
		FROM   Unicom_Orders a,oSDOrg b
		WHERE  a.DocCode =@doccode
		AND a.sdorgid=b.SDOrgID

		--更新信用额度
		exec sp_update_credit @doccode
		--更新即时帐
		exec sp_update_farbalance @doccode
		--播放运营商业务明细
		EXEC sp_ImportAllocationData 9146,@doccode
		FETCH NEXT FROM abc INTO @doccode 
	END
	CLOSE abc
	DEALLOCATE abc
	
	COMMIT
	ROLLBACK
SELECT * FROM sPickorderHD sph WHERE sph.refcode='PS20110802000286'
	
SELECT * FROM fsubledgerlog f WHERE f.memo='批量调整加盟店信用额度'