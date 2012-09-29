BEGIN tran
;WITH cte AS(
	SELECT companyid,periodid,f.glcode, cv1 AS cltcode,SUM(f.amount_debit) AS debit,SUM(amount_credit) AS credit
	FROM fsubledgerlog f
	WHERE f.glcode='113107'
	AND f.periodid IN('2010-10','2010-11','2010-12','2011-01','2011-02','2011-03','2011-04','2011-05','2011-06','2011-07''2011-08','2011-09''2011-10', '2011-11')
	GROUP BY companyid,periodid,f.glcode, cv1
)
UPDATE b
	SET prebalance = dbo.getfarprebalance1(a.companyid,a.cltcode,'113107',a.periodid+'-01'),
	debit = a.debit,
	credit = a.credit
FROM cte a,fARbalance b
WHERE a.companyid=b.companyid
AND a.cltcode=b.cltcode
AND a.glcode=b.account
AND a.periodid=b.periodid

ROLLBACK

COMMIT


SELECT os.credit, * FROM oSDOrg os WHERE os.SDOrgID='2.1.769.266'



SELECT *,dbo.getfarprebalance1(companyid,cltcode,'113107',periodid+'-01') prebalance FROM cte
WHERE cltcode='2.1.769.266'

SELECT * FROM fARbalance fa WHERE fa.cltcode='2.1.769.266' AND account='113107' AND periodid IN('2011-03','2011-04','2011-05')


select * from farbalance e left join (select companyid,periodid,cv1,glcode,sum(amount_debit)debit,sum(amount_credit)creditfrom fsubledgerlog group by companyid,periodid,cv1,glcode) b on e.companyid=b.companyid and e.periodid=b.periodidand e.cltcode=b.cv1 and e.account=b.glcode where isnull(e.debit,0)<>isnull(b.debit,0) or isnull(e.credit,0)<>isnull(b.credit,0)and e.cltcode in (select sdorgid from osdorg where osdtype='º”√À')2.1.769.583