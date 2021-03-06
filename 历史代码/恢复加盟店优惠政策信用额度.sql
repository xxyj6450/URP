BEGIN tran
DECLARE @doccode VARCHAR(20),@sdorgid VARCHAR(20),@Credit MONEY,@period VARCHAR(10)
	DECLARE abc CURSOR FOR 
	SELECT os.mintype,   uo.doccode ,uo.periodid,
	(ISNULL(uo.commission,0)+ISNULL(uo.rewards,0)) AS totalmoney3,f.cv1 

	--UPDATE uo 		SET uo.totalmoney2 = f.amount_debit 
	  FROM Unicom_Orders uo LEFT JOIN fsubledgerlog f ON uo.DocCode=f.doccode
	  LEFT JOIN oSDOrg os ON uo.sdorgid=os.SDOrgID
	WHERE uo.DocDate>='2011-09-06'
	AND uo.DocStatus=100
	AND uo.dptType='加盟店'
	-- AND uo.totalmoney2 NOT IN(100,200)
	 AND uo.commission>0
	 AND f.glcode='113107'
	 AND f.gltype IN('加盟商即返','加盟商佣金/奖励即返')
	 AND uo.DocCode='PS20110907000003'
	 AND   os.mintype not  IN('专区','专柜')
	 OPEN abc
	 FETCH NEXT FROM abc INTO @doccode,@period,@Credit,@sdorgid
	 WHILE @@FETCH_STATUS=0
		BEGIN
			PRINT @doccode
			--更新即时帐
			UPDATE Fsubinstbalance
				SET balance =ISNULL(balance,0)+@Credit
			WHERE cv1=@sdorgid
			AND account='113107'
			--更新期间帐
			UPDATE FsubBalance
				SET credit = credit-@Credit,
				natcredit = natcredit-@Credit
			WHERE account='113107'
			AND periodid='2011-09'
			AND cv1=@sdorgid
			--更新应收即时帐
			UPDATE farinstbalance
				SET balance = balance+@Credit
			WHERE account='113107'
			AND cltcode=@sdorgid
			--更新应收期间帐
			UPDATE fARbalance
				SET debit = balance+@Credit
			WHERE account='113107'
			and cltcode=@sdorgid
			AND periodid=@period
			PRINT '删除往来明细'
			DELETE FROM fsubledgerlog
			WHERE doccode=@doccode
			AND glcode IN('113107','540115')
			AND gltype IN('加盟商即返','加盟商佣金/奖励即返','佣金及奖励支出','佣金及奖励支出')
			PRINT @@ROWCOUNT
			print '恢复信用额度'
			UPDATE oSDOrg
				SET credit = credit-@Credit
			WHERE SDOrgID=@sdorgid
			PRINT @@ROWCOUNT
			print '清空单据佣金与奖励'
			UPDATE Unicom_Orders
				SET commission = 0,
				rewards = 0
			WHERE DocCode=@doccode
			PRINT @@ROWCOUNT
			 FETCH NEXT FROM abc INTO @doccode,@period,@Credit,@sdorgid
		END
		CLOSE abc
		DEALLOCATE abc

ROLLBACK

COMMIT

SELECT DISTINCT cv1 FROM Fsubinstbalance WHERE account='113107' AND cv1='2.1.755.001'

SELECT * FROM FsubBalance WHERE account='113107' AND periodid='2011-09'

	SELECT f.cv1,f.cv1name,sum(uo.commission),sum(uo.rewards),
	sum(ISNULL(uo.commission,0)+ISNULL(uo.rewards,0)) AS totalmoney3

	--UPDATE uo 		SET uo.totalmoney2 = f.amount_debit 
	  FROM Unicom_Orders uo LEFT JOIN fsubledgerlog f ON uo.DocCode=f.doccode
	WHERE uo.DocDate='2011-09-06'
	AND uo.DocStatus=100
	AND uo.dptType='加盟店'
	-- AND uo.totalmoney2 NOT IN(100,200)
	 AND uo.commission>0
	 AND f.glcode='113107'
	GROUP BY f.cv1,f.cv1name
	 


	SELECT f.cv1,f.cv1name, uo.commission , uo.rewards ,
	 (ISNULL(uo.commission,0)+ISNULL(uo.rewards,0)) AS totalmoney3

	--UPDATE uo 		SET uo.totalmoney2 = f.amount_debit 
	  FROM Unicom_Orders uo LEFT JOIN fsubledgerlog f ON uo.DocCode=f.doccode
	WHERE uo.DocDate='2011-09-06'
	AND uo.DocStatus=100
	AND uo.dptType='加盟店'
	-- AND uo.totalmoney2 NOT IN(100,200)
	 --AND uo.commission>0
	 AND f.glcode='113107'
	and uo.DocCode='PS20110906000227'
	 
	 
 