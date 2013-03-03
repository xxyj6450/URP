alter proc sp_PostOSDorgDoc
	@FormID INT,
	@Doccode varchar(20),
	@OptionID varchar(200)=''
as
	BEGIN
		if @FormID in(1211)
			BEGIN
				update a
					set 
					SDOrgName=b.SDOrgName,
					deputy=b.deputy,
					PostCode=b.PostCode,
					Province=b.Province,
					City=b.City,
					Street=b.Street,
					Tel1=b.Tel1,
					Tel2=b.Tel2,
					Fax1=b.Fax1,
					Email=b.Email,
					Internat=b.Internat,
					Memo40=b.Memo40,
					curCode=b.curCode,
					rowid=b.rowid,
					TreeControl=b.TreeControl,
					parentrowid=b.parentrowid,
					HJCC=b.HJCC,
					newcode=b.newcode,
					mdf=b.mdf,
					cycle=b.cycle,
					sdorggroup=b.sdorggroup,
					train=b.train,
					reckoning=b.reckoning,
					AreaID=b.AreaID,
					AreaName=b.AreaName,
					osdtype=b.osdtype,
					resman=b.resman,
					instrdate=b.instrdate,
					osdscope=b.osdscope,
					Agent=b.Agent,
					ExternalDptID=b.ExternalDptID,
					ExternalDptName=b.ExternalDptName,
					ExternalStaffID=b.ExternalStaffID,
					ExternalAdminID=b.ExternalAdminID,
					ExternalAdminName=b.ExternalAdminName,
					ExternalManager=b.ExternalManager,
					Phone=b.Phone,
					dptType=b.dptType,
					credit=b.credit,
					mintype=b.mintype,
					LimitCredit=b.LimitCredit,
					signeddate=b.signeddate,
					signeduser=b.signeduser,
					company_b=b.company_b,
					area_b=b.area_b,
					builddate=b.builddate,
					tradate=b.tradate,
					BBSID=b.BBSID,
					OAID=b.OAID,
					memo=b.memo,
					SOPID=b.SOPID,
					star=b.star,
					cashno=b.cashno,
					HTID=b.HTID,
					place=b.place,
					usertxt1=b.usertxt1,
					usertxt2=b.usertxt2,
					ESSID=b.ESSID,
					agentid=b.agentid,
					branchid=b.branchid,
					isSaled=b.isSaled,
					SubSystemID=b.SubSystemID,
					SubSystemPWD=b.SubSystemPWD,
					PATH=b.PATH,
					opendate=b.opendate,
					companyid=b.companyid,
					company_bname=b.company_bname,
					area_bname=b.area_bname,
					Devusercode=b.Devusercode,
					Devusername=b.Devusername,
					Devtel=b.Devtel,
					Ckmoney=b.Ckmoney,
					descri=b.descri,
					back=b.back,
					backtype=b.backtype,
					aid=b.aid,
					black=b.black,
					blacklist=b.blacklist,
					director=b.director,
					directorname=b.directorname,
					address=b.address,
					ESSIDT=b.ESSIDT,
					usertxt3=b.usertxt3,
					Fisttransdate=b.Fisttransdate,
					netgroupid=b.netgroupid,
					netgroupname=b.netgroupname,
					ContractExpirationDate=b.ContractExpirationDate,
					closed=b.closed,
					unname=b.unname,
					color=b.color
				from oSDOrg a,oSDOrgHD b
				where b.doccode=@Doccode
				and a.SDOrgID=b.sdorgid
			END
	END
	
	/*
declare @sql varchar(max)
select @sql=''
select @sql=@sql+s.name+'=b.'+s.name+','+char(10)
from syscolumns s
where s.id=object_id('osdorg')
print @sql
*/