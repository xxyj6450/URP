BEGIN TRAN
	UPDATE sPickorderHD
		SET sdgroup = b.sdgroup,
		sdgroupname = b.sdgroupname,
		sdgroup1 = b.sdgroup,
		sdgroupname1 = b.sdgroupname
	FROM spickorderhd a,oSDGroup b
	WHERE   b.SDGroupName='�ƽ���'
	AND a.DocCode IN('RE20110810000275')
																				ROLLBACK
																				COMMIT
																				SELECT * FROM oSDGroup os WHERE os.SDGroupName LIKE '%���%'
	UPDATE salelog
		SET sdgroup = b.sdgroup,
		sdgroupname = b.sdgroupname,
		sdgroup2 = b.sdgroup,
		sdgroupname2 = b.sdgroupname
	FROM salelog a,oSDGroup b
	WHERE   b.SDGroupName='�ƽ���'
	AND a.DocCode IN('RE20110810000275')
	
	UPDATE isaleledgerlog
		SET sdgroup = b.sdgroup,
		sdgroupname = b.sdgroupname 
	FROM isaleledgerlog a,oSDGroup b
	WHERE   b.SDGroupName='�ƽ���'
	AND a.DocCode IN('RE20110810000275')
 
	
	 