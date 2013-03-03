--Åä¼þ¿â´æ
SELECT b.matcode,b.matname,c.stcode,c.name40,a.unlimitstock,d.MAP,e.crprice
  FROM iMatStorage a left join iMatGeneral b on a.matcode=b.matcode
  left join oStorage  c ON a.stCode=c.stCode
LEFT JOIN iMatLedger d ON a.MatCode=d.MatCode
LEFT JOIN sMatSDOrgPrice e ON a.MatCode=e.matcode 
WHERE a.unlimitStock>0
AND e.SDOrgID='1.2'
AND b.MatFlag=0
ORDER BY c.name40,b.matname

--´®ºÅ¿â´æ
SELECT * FROM iSeries is1 WHERE is1.vndcode IS NOT null
AND STATE='ÔÚ¿â'
SELECT b.stcode,b.name40,a.matcode,a.matname,seriescode,c.vndcode,c.vndname,d.purprice,e.MAP
FROM iSeries d left join iMatGeneral a ON d.MatCode=a.MatCode
left join oStorage b ON d.stcode=b.stCode
LEFT JOIN pVndGeneral c ON d.vndcode=c.vndCode
LEFT JOIN iMatLedger e ON d.MatCode=e.MatCode
WHERE d.[state]='ÔÚÍ¾'
ORDER BY d.stcode,d.MatCode

SELECT * FROM iMatLedger



SELECT * FROM #tt
WHERE ISNULL(purprice,0)=0 OR ISNULL(vndcode,'')=''
BEGIN tran
;WITH ctea AS(
	SELECT MAX(doccode) AS doccode,v.MatCode
	FROM vmatdoc v
	WHERE v.DocStatus<>0
	AND v.FormID=1509
	AND v.price>0
	GROUP BY v.MatCode)
,cteb AS (
	SELECT v.doccode,v.matcode,v.vndcode,v.vndname,Price
	FROM vmatdoc v,ctea b
	WHERE v.MatCode=b.matcode
	AND v.DocCode=b.doccode)


SELECT a.stcode,a.name40,b.matcode,b.matname,d.unlimitstock,
CASE when ISNULL(e.price,0)=0 THEN b.inprice ELSE e.price end AS purprice, 
CASE when ISNULL(e.vndcode,'')='' THEN b.vndcode ELSE e.vndcode END,
CASE when ISNULL(e.vndname,'')='' THEN b.vndname ELSE e.vndname END,
e.doccode
--INTO #tt
FROM iMatStorage d
LEFT JOIN cteb e ON  d.MatCode=e.matcode
,oStorage a,iMatGeneral b 
WHERE d.stCode=a.stCode
AND d.MatCode=b.MatCode
AND b.MatState=1
AND b.MatFlag=0
AND d.unlimitStock>0
ORDER BY d.stCode,d.MatCode


DROP TABLE #tt

ROLLBACK

	--SELECT * FROM cteb
UPDATE b
	SET vndcode=a.vndcode,
	vndname=a.vndname,
	purprice=a.price,
	doccode=a.doccode
FROM #tt b left join cteb a
on a.matcode=b.matcode
AND a.stcode=b.stcode


SELECT a.doccode,a.stcode,a.stname,a.instcode,a.instname,b.MatCode,b.MatName,e.SeriesCode,e.purprice,e.vndcode,f.MAP,b.price
  FROM sPickorderHD a INNER JOIN sPickorderitem b on a.doccode=b.doccode
LEFT JOIN iseriesloghd c ON c.refcode=a.DocCode
left join iserieslogitem d ON c.DocCode=d.doccode AND b.MatCode=d.matcode
 INNER JOIN iseries e ON d.seriescode=e.SeriesCode
 LEFT JOIN iMatLedger f ON b.matcode=f.MatCode
WHERE a.FormID=2424
AND a.DocStatus=150
AND a.done=0
AND e.[state]='ÔÚÍ¾'
ORDER BY a.stcode,a.instcode,b.MatCode

CREATE VIEW view_MatOnTranse
as
SELECT a.doccode,a.stcode,a.stname,a.instcode,a.instname,b.MatCode,b.MatName,b.price,e.crprice, f.MAP,b.BaseDigit,b.grdigit
  FROM sPickorderHD a INNER JOIN sPickorderitem b on a.doccode=b.doccode
 LEFT JOIN iMatLedger f ON b.matcode=f.MatCode
 LEFT JOIN sMatSDOrgPrice e ON b.MatCode=e.matcode
 INNER JOIN iMatGeneral c ON b.MatCode=c.MatCode
WHERE a.FormID=2424
AND a.DocStatus=150
AND a.done=0
AND e.SDOrgID='1.2'
AND c.MatFlag=0
AND b.BaseDigit-b.grdigit>0
 

 