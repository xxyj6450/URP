--select * from imatsalelog
create proc sp_ImportMatSaleLogEX --'2010-01-25','2010-01-25'
	@user varchar(50)='SYSTEM',
	@remark varchar(255)=''
as
begin
	
	--插入imatsalelog不存在的数据
	insert into imatsalelog
	select a.doccode,a.formid,doctype,docdate,a.periodid,a.refcode,companyid,a.companyname,
	a.cltcode,a.cltname,a.sdorgid,a.sdorgname,a.stcode,a.stname,a.sdgroup,a.sdgroupname,
	a.sdgroup1,a.sdgroupname1,a.hdtext,a.userdigit1,a.userdigit2,a.userdigit3,a.userdigit4,
	a.entername,a.enterdate,a.postname,a.postdate,
	b.docitem,b.rowid,b.matcode,b.matname,b.seriescode,	b.uom,b.digit,b.price,
	b.userdigit1,b.totalmoney,b.selfprice,b.selfprice1,b.zcprice,b.gift,b.brush,'',
	b.matcost,b.userdigit5,b.usertxt6,c.mattype,c.brand,c.matlife,c.matgroup,d.matgroupname,
	d.matgroup1,d.matgroupname1,d.matgroup2,d.matgroupname2,d.matgroup3,d.matgroupname3,d.matgroup4,d.matgroupname4,
	d.matgroup5,d.matgroupname5,getdate(),@user,@remark
	from spickorderitem b left join spickorderhd a on a.doccode=b.doccode
	left join imatgeneral c on b.matcode=c.matcode
	left join imatgroup d on d.matgroup =c.matgroup 
	where a.formid in(2418,2419,2401,2420)
	and b.rowid not in(select rowid from imatsalelog)
end

/*
select * from syscolumns where id=object_id('imatsalelog') 
select * from syscolumns where id=object_id('spickorderitem') 
select * from syscolumns where id=object_id('spickorderhd') order by name
*/