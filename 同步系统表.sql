BEGIN TRAN
UPDATE a
	SET a.hdtable = g.hdtable,
	a.dttable = g.dttable,
	a.DealAfterDocSave = g.DealAfterDocSave,
	a.defaltformtype = g.defaltformtype,
	a.Maximized = g.Maximized 
FROM gform a,URPDB.dbo.gform g
WHERE a.formid=g.formid
	
BEGIN tran
DELETE FROM gField
INSERT INTO gField SELECT * FROM urpdb.dbo.gField g

ROLLBACK
 
BEGIN tran
INSERT INTO gform
SELECT * FROM urpdb.dbo.gform g WHERE g.formid NOT IN(SELECT  formid FROM gform g2)

COMMIT

BEGIN TRAN
DELETE FROM _sysFuncLink
INSERT INTO _sysFuncLink SELECT * FROM urpdb.dbo._sysFuncLink sfl

BEGIN TRAN
DELETE FROM _sysbusi2fi
INSERT INTO _sysbusi2fi SELECT * FROM urpdb.dbo._sysbusi2fi sfl

BEGIN TRAN
DELETE FROM gdoctype
INSERT INTO gdoctype  SELECT * FROM urpdb.dbo.gdoctype sfl


BEGIN TRAN
DELETE FROM _sysdatefilter
INSERT INTO _sysdatefilter  SELECT * FROM urpdb.dbo._sysdatefilter sfl


BEGIN TRAN
DELETE FROM _sysdicttype
INSERT INTO _sysdicttype  SELECT * FROM urpdb.dbo._sysdicttype sfl

BEGIN TRAN
DELETE FROM _sysdict
INSERT INTO _sysdict  SELECT * FROM urpdb.dbo._sysdict sfl

COMMIT
BEGIN TRAN
DELETE FROM _sysMenu
INSERT INTO _sysMenu  SELECT * FROM urpdb.dbo._sysMenu sfl

BEGIN TRAN
DELETE FROM gdocstate
INSERT INTO gdocstate  SELECT * FROM urpdb.dbo.gdocstate sfl

BEGIN TRAN
DELETE FROM _systransaction
INSERT INTO _systransaction  SELECT * FROM urpdb.dbo._systransaction sfl

BEGIN TRAN
DELETE FROM _systransgroup
INSERT INTO _systransgroup  SELECT * FROM urpdb.dbo._systransgroup sfl

s