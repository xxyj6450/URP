select uo.Price,uo.Deposits,uo.BasicDeposits,uo.userdigit4+uo.Deposits, uo.userdigit4,sph.userdigit4, *
  from Unicom_Orders uo,sPickorderHD sph
where uo.DocCode=sph.refcode
and uo.FormID=9146
and uo.userdigit4<>sph.userdigit4
and uo.Deposits>0
and uo.DocDate>='2012-09-27'

begin tran
set NOCOUNT on;
declare @formid int,@doccode varchar(20),@newdoccode varchar(20),@sdorgid varchar(50),@stcode varchar(50),@stname varchar(200)
declare abc CURSOR FOR
select uo.formid,uo.DocCode,uo.stcode,uo.sdorgid,uo.stname,uo.refcode
  from Unicom_Orders uo,sPickorderHD sph
where uo.DocCode=sph.refcode
and uo.FormID=9146
and uo.userdigit4<>sph.userdigit4
and uo.Deposits>0
and uo.DocDate>='2012-09-27'
 
open abc
fetch next FROM abc into @formid,@doccode,@stcode,@sdorgid,@stname
while @@FETCH_STATUS=0
	BEGIN
		exec sp_newdoccode 2420,'',@newdoccode output
		INSERT INTO sPickorderHD(DocCode,DocStatus,DocType,FormID,refformid,refcode,refrefformid,refrefcode,docdate,                                  
						stcode,stname,sdorgid,sdorgname,Companyid,CompanyName,sdgroup,sdgroupname,instcode,instname,                                  
						sdorgid2,sdorgname2,Companyid2,CompanyName2,sdgroup1,sdgroupname1,                                  
						plantid,plantname,plantid2,plantname2,cltcode,cltname,usertxt3,usertxt1,UserTxt2,prdno,                                 
						UserDigit1,UserDigit2,UserDigit2Text,UserDigit3,UserDigit3Text,userdigit4,UserDigit4Text,UserDigit5,
						UserDigit5Text,summoney,HDText,matstatus,EnterName,EnterDate,done,        
						achievement,reftype,Rewards,dpttype,BusiType,DeductAmout,ReservedDoccode,PackageID,
						CustomerID,pick_ref,Score,Score1,TotalScore,cleardoccode)                                  
				 SELECT top 1 @newDoccode, 0, '销售退货', 2420, sph.formid, sph.doccode,sph.refformid,sph.refcode, convert(varchar(10),s.docdate,120),                                   
						s.stcode, s.stname, s.sdorgid,s.sdorgname,sph.plantid,sph.companyname, sph.sdgroup, sph.sdgroupname, sph.stcode,sph.stname,                                    
						s.sdorgid, s.sdorgname,sph.companyid2,sph.companyname2, sph.sdgroup,sph.sdgroupname,                                  
						sph.plantid, sph.plantname, sph.plantid2, sph.plantname2,s.cltcode,s.cltname,s.cltcode,s.cltname,s.SeriesNumber,'退货',                                 
						sph.UserDigit1,sph.UserDigit2,sph.UserDigit2Text,sph.UserDigit3,sph.UserDigit3Text,sph.userdigit4,
						sph.UserDigit4Text,sph.UserDigit5,sph.UserDigit5Text,s.summoney,'处理多收入的预存款','正常', s.entername,       
						s.EnterDate, 1,'业务员客户',s.doctype,s.Rewards,s.dpttype,s.doctype,s.DeductAmout,
						s.ReservedDoccode,s.packagecode,s.customerid,s.sdgroup,s.Score,s.Score1,s.TotalScore,sph.DocCode
				 FROM   Unicom_Orders s  WITH(NOLOCK) 	 inner JOIN sPickorderHD sph WITH(NOLOCK) ON s.doccode=sph.refcode
				 WHERE sph.FormID=2419
				 and s.DocCode=@doccode
				  INSERT INTO sPickorderitem
		   (  doccode,   docitem,   rowid,   itemtype,   seriesCode,   matcode,   
		      matname,   uom,   matgroup,   baseuom,   packagecode,   
		      baseuomrate,   selfprice1,   end4,   price2,   ScorePrice,   
		      uomrate,   ratetxt,   stcode,   stname,   price,   totalmoney,   
		      digit,   basedigit,   monvalue,   monadd,   userdigit2,   
		      isSingleSale,   DeductAmout,   CouponsBarCode )
		 --基本预存    <<<编号要跟金额一致>>>                            
		SELECT @newDoccode,  ROW_NUMBER() OVER(ORDER BY @newdoccode),  NEWID(),  '&自有&',  '',  l.matcode,  
		 l.matname,  l.salesuom,  l.matgroup,  l.salesuom,  l.packagecode,  
		 1,d.selfprice1, d.end4, CASE 
									WHEN ISNULL(l.deduct,0)=0 THEN 0
									ELSE CASE 
											WHEN ISNULL(l.MatState,0)=1 THEN ISNULL(s.Deposits,0)-1*isnull(d.ScorePrice,0)
											ELSE ISNULL(s.Deposits,0)*(1-isnull(d.ScorePrice,0))
									     END
								end,  d.ScorePrice,  1,  1,  @stcode,  @stname,  isnull(s.Deposits,0),  
		        isnull(s.Deposits,0),  1,  1,  0,  0,  NULL,  NULL,  NULL,  NULL
		 FROM   Unicom_Orders s WITH(NOLOCK)
		        INNER JOIN iMatGeneral l with(nolock)  ON  l.MatCode = (
		                 SELECT TOP 1 PropertyValue
		                 FROM   _sysNumberAllocationCfgValues
		                 WHERE  PropertyName = '基本预存款'
		             )--s.matcode_price
		              outer apply dbo.uf_salesSDOrgpricecalcu3(l.matcode, @sdorgid, '') d
		 WHERE  s.doccode = @doccode
		        AND ISNULL(s.price, 0) <> 0 
		        exec CashIntype @newdoccode,@formid
		        print @newdoccode
		        fetch next FROM abc into @formid,@doccode,@stcode,@sdorgid,@stname
	END
	close abc
	deallocate abc

rollback

rollback
commit



begin TRAN
delete from sPickorderitem
where DocCode in(
	select DocCode from sPickorderHD sph where sph.HDText='处理多收入的预存款' and formid=2420 and docstatus=0
)
delete from sPickorderHD  
where  HDText='处理多收入的预存款' and formid=2420  and docstatus=0

rollback

commit