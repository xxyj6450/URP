alter proc sp_AddSaleledger
	@FormID int,
	@Doccode int,
	@OptionId varchar(50)='',
	@UserCode varchar(50)='',
	@TerminalID varchar(50)=''
as
BEGIN
		set NOCOUNT ON
		declare @refcode varchar(50),@PeriodID varchar(50)
		--内部采购入库时,写内部销售单的销售明细帐
		if @FormID in(4061)
			BEGIN
				select @refcode=refCode,@PeriodID=PeriodID
				from imatdoc_h with(nolock) 
				where DocCode=@Doccode
				exec sp_AddSaleledger 4031,@refcode,'',@UserCode,@TerminalID
			END
		if @FormID in(2398,2399,2400,2401,2413,2414,2416,2417,2419,2425,2433,2434,2448,2449,2450,4031,4950,9955)
			BEGIN
				INSERT into isaleledgerlog( inserttime, doccode, formid, doctype, docdate, 
				       periodid, companyid, docsubtype, plantid, sdorgid, 
				       cltcode, cltcode2, sdgroup, docitem, rowid, itemtype, 
				       matcode, batchcode, stcode, basedigit, price, grossprice, 
				       discountprice, discountmoney, pricememo, netmoney, 
				       totalmoney, salesbasedigit, salestotalmoney, 
				       salesnetmoney, sdgroupname, zcprice, lsprice, memo, 
				       seriescode, mobilecode, userdigit1, matlife, selfprice, 
				       selfprice1, usertxt3, usertxt1, gift, weave,matcost,ratemoney)
				SELECT getdate(),doccode,formid,doctype,docdate,periodid,companyid,docsubtype,plantid,sdorgid,
				       cltcode,cltcode2,sdgroup,docitem,rowid,itemtype,a.matcode,
				       batchcode,stcode,basedigit,price,grossprice,discountprice,
				       discountmoney,pricememo,netmoney,totalmoney,basedigit,
				       totalmoney,netmoney,sdgroupname,zcprice,a.lsprice,hdtext,
				       seriescode,usertxt3,userdigit1,b.matlife,selfprice,
				       selfprice1,usertxt3,usertxt1,gift,weave,a.MatCost,ratemoney
				FROM   vspickorder1 a,iMatGeneral b
				WHERE  doccode = @Doccode
				       AND a.matcode = b.matcode
			END
		if @FormID in(2424)
			BEGIN
				INSERT into isaleledgerlog( inserttime, DocCode, FormID, DocType, DocDate, 
				       docstatus, periodid, refcode, Companyid, docsubtype, 
				       plantid, plantid2, sdorgid, cltCode, cltcode2, drivername, 
				       sdgroup, sdgroupname, DocItem, rowid, itemtype, MatCode, 
				       batchcode, stcode, baseDigit, pricememo, memo, 
				       moveoutdigit, instcode, salesbasedigit, totalmoney, 
				       matlife)
				SELECT getdate(),doccode,formid,DocType,DocDate,docstatus,periodid,refcode,Companyid,docsubtype,
				       plantid,plantid2,sdorgid,'','',drivername,sdgroup,
				       sdgroupname,DocItem,rowid,itemtype,a.MatCode,batchcode,
				       stcode,baseDigit,pricememo,HDText,basedigit,instcode,
				       basedigit,totalmoney,l.matlife
				FROM   vspickorder a
				       left JOIN imatgeneral l ON  a.matcode = l.matcode
				WHERE  doccode = @doccode
			END
		if @FormID in(2418,2420,4032,4062,4951)
			BEGIN
				INSERT into isaleledgerlog( inserttime, doccode, formid, doctype, docdate, 
				       periodid, companyid, docsubtype, plantid, sdorgid, 
				       cltcode, cltcode2, sdgroup, docitem, rowid, itemtype, 
				       matcode, batchcode, stcode, drivername, basedigit, price, 
				       grossprice, discountprice, discountmoney, pricememo, 
				       netmoney, totalmoney, salesbasedigit, salestotalmoney, 
				       salesnetmoney, cspbasedigit, csptotalmoney, cspnetmoney, 
				       vspbasedigit, vsptotalmoney, vspnetmoney, sdgroupname, 
				       zcprice, lsprice, memo, cubage, seriescode, mobilecode, 
				       userdigit1, matlife, gift,matcost,ratemoney)
				SELECT getdate(),doccode,formid,doctype,docdate,periodid,companyid,docsubtype,plantid,sdorgid,
				       cltcode,cltcode2,sdgroup,docitem,rowid,itemtype,a.matcode,
				       batchcode,stcode,drivername,-basedigit,price,grossprice,
				       discountprice,-discountmoney,pricememo,-netmoney,-
				       totalmoney,-basedigit,-totalmoney,-netmoney,0,0,0,0,0,0,
				       sdgroupname,zcprice,b.lsprice,hdtext,a.cubage,seriescode,
				       usertxt3,-userdigit1,b.matlife,gift,a.MatCost,ratemoney
				FROM   vspickorder1 a,iMatGeneral b
				WHERE  doccode = @Doccode
				       AND a.matcode = b.matcode
			END
END