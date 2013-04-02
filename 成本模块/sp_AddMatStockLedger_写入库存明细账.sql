alter proc sp_AddMatStockLedger
	@FormID int,
	@Doccode varchar(50),
	@OptionId varchar(50)='',
	@UserCode varchar(50)='',
	@TerminalID varchar(50)=''
as
	BEGIN
		set NOCOUNT ON
		declare @Docdate DATETIME, @stcode varchar(50),@PeriodID varchar(7),@CompanyID varchar(50),@Doctype varchar(50),@SDorgid varchar(50)
		declare @RefFormID int,@Refcode varchar(50)
		--采购入库单,从sp_istldlog_nmin传入
		if @FormID in(1502,1503,1508,1509,1520,1599,2439,4061)
			BEGIN
				--内部采购入库时,必须先写内部销售的库存明细,即原来4031的库存明细账
				if @FormID in(4061)
					BEGIN
						select @RefFormID=a.refformid,@Refcode=a.refCode,@PeriodID=a.PeriodID
						from imatdoc_h a with(nolock) 
						where a.DocCode=@Doccode
						insert into istockledgerlog 
					   (companyid,sdorgid,periodid,matvalue,plantid,matcode,stcode,batchcode,formid,formname,doccode,docdate,doctype,
						cltcode,vndcode,docitem,docrowid,digit,uom,baseuomrate,uomrate,baseuom,
						indigit,outdigit,inledgerdigit,inledgeramount,outledgerdigit,outledgeramount,
						incspdigit,outcspdigit,invspdigit,outvspdigit,salesflag,cspflag,vspflag,inouttype,end4,matcost,outrateamount)
					   select  
						companyid,sdorgid,@periodid,matvalue,plantid,matcode,stcode,batchcode,formid,formname,doccode,docdate,doctype,
						cltcode,vndcode,docitem,rowid,digit,uom,baseuomrate,uomrate,baseuom,
						0,basedigit,0,0,basedigit,matcost,0,0,0,0,1,0,0,pricememo,end4,MatCost,ratemoney
					   from VSPKOITEM with(nolock)
					   where doccode=@Refcode
					END
				INSERT INTO istockledgerlog( companyid,sdorgid, periodid, matvalue, plantid, matcode, 
			   stcode, batchcode, formid, formname, doccode, docdate, doctype, 
			   workshopid, cltcode, vndcode, docitem, docrowid, digit, uom, 
			   baseuomrate, uomrate, baseuom, indigit, outdigit, inledgerdigit, 
			   inledgeramount, outledgerdigit, outledgeramount, incspdigit, outcspdigit, invspdigit, outvspdigit, 
			   salesflag, cspflag, vspflag, inouttype,end4,inrateamount,matcost)
				SELECT companyid,sdorgid,periodid,matvalue,plantid,matcode,stcode,batchcode,formid,
					   formname,doccode,docdate,doctype,workshopid,cltcode,vndcode,docitem,
					   rowid,digit,uom,baseuomrate,uomrate,baseuom,basedigit,0,basedigit,
					   netmoney,0,0,0,0,0,0,0,0,0,inouttype,operatingcost,ratemoney,matcost
				FROm vmatdoc with(nolock)
				WHERE  doccode = @doccode
			END
		--采购退货单
		if @FormID in(1504,4062)
			BEGIN
				 INSERT into istockledgerlog( companyid,sdorgid, periodid, matvalue, plantid, matcode, 
				        stcode, batchcode, formid, formname, doccode, docdate, 
				        doctype, workshopid, cltcode, vndcode, docitem, docrowid, 
				        digit, uom, baseuomrate, uomrate, baseuom, indigit, 
				        outdigit, inledgerdigit, inledgeramount, outledgerdigit, 
				        outledgeramount, incspdigit, outcspdigit, invspdigit, 
				        outvspdigit, salesflag, cspflag, vspflag, inouttype,matcost,outrateamount)
				 SELECT companyid,sdorgid,periodid,matvalue,plantid,matcode,stcode,
				        batchcode,formid,formname,doccode,docdate,doctype,
				        workshopid,cltcode,companyid2,docitem,rowid,-digit,uom,
				        baseuomrate,uomrate,baseuom,-basedigit,0,-basedigit,-
				        matcost,0,0,0,0,0,0,0,0,0,inouttype,matcost,ratemoney
				 FROM   vmatdoc  with(nolock)
				 WHERE  doccode = @doccode
			END
		--调拔入库单,同时写调拔出库明细与调拔入库明细.
		if @FormID in(1507)
			BEGIN
				--注意取调拔入库的期间
				select @RefFormID=refformid,@Refcode=refCode,@PeriodID=PeriodID
				from imatdoc_h with(nolock)
				where DocCode=@Doccode
				--写出库明细,来源于sp_istldlog_quickmove
				 INSERT INTO istockledgerlog( companyid,sdorgid, periodid, matvalue, plantid, matcode, 
				   stcode, batchcode, formid, formname, doccode, docdate, doctype, 
				   cltcode, vndcode, docitem, docrowid, digit, uom, baseuomrate, uomrate, 
				   baseuom, indigit, outdigit, inledgerdigit, inledgeramount, 
				   outledgerdigit, outledgeramount, incspdigit, outcspdigit, invspdigit, 
				   outvspdigit, salesflag, cspflag, vspflag, inouttype, instcode,end4,matcost,outrateamount)
			SELECT companyid,sdorgid,@periodid,matvalue,plantid,matcode,stcode,batchcode,formid,
				   formname,doccode,docdate,doctype,cltcode,'',docitem,rowid,digit,uom,
				   baseuomrate,uomrate,baseuom,0,basedigit,0,0,basedigit,matcost,0,0,0,0,
				   1,0,0,pricememo,instcode,end4,MatCost,ratemoney
			FROM   VSPKOITEM
			WHERE  doccode = @refcode
				--写入库明细,来源于sp_moveistldgerlog_in
				 INSERT INTO istockledgerlog( companyid,sdorgid, periodid, matvalue, plantid, matcode, 
			   stcode, batchcode, formid, formname, doccode, docdate, doctype, 
			   cltcode, vndcode, docitem, docrowid, digit, uom, baseuomrate, uomrate, 
			   baseuom, indigit, outdigit, inledgerdigit, inledgeramount, 
			   outledgerdigit, outledgeramount, incspdigit, outcspdigit, invspdigit, 
			   outvspdigit, salesflag, cspflag, vspflag, inouttype,end4,matcost,inrateamount)
				SELECT companyid,sdorgid,periodid,matvalue,plantid,matcode,stcode,batchcode,formid,
					   formname,doccode,docdate,doctype,cltcode,'',docitem,rowid,digit,uom,
					   baseuomrate,uomrate,baseuom,basedigit,0,basedigit,netmoney,0,0,0,0,0,
					   0,0,0,0,inouttype,OperatingCost,matcost,ratemoney
				FROM   vmatdoc
				WHERE  doccode = @doccode
			END
		--领料出库单，从原sp_istldlog_out转入
		if @FormID in(1501,1521,1523,1532,1598,2465)
			BEGIN
				 insert into istockledgerlog   
				(companyid,sdorgid,periodid,matvalue,plantid,matcode,stcode,batchcode,formid,formname,doccode,docdate,doctype,inouttype,workshopid,  
				cltcode,vndcode,docitem,docrowid,digit,uom,baseuomrate,uomrate,baseuom,  
				indigit,outdigit,inledgerdigit,inledgeramount,outledgerdigit,outledgeramount,  
				incspdigit,outcspdigit,invspdigit,outvspdigit,salesflag,cspflag,vspflag,end4,matcost,outrateamount)  
				select companyid,sdorgid,periodid,matvalue,plantid,matcode,stcode,batchcode,formid,formname,doccode,docdate,doctype,  
				inouttype,workshopid,cltcode,'',docitem,rowid,digit,uom,baseuomrate,uomrate,baseuom,0,basedigit,0,0,basedigit,netmoney,  
				0,0,0,0,0,0,0,operatingcost,matcost,ratemoney
				from vmatdoc
				where doccode=@doccode  
			END
		--供应商代销退货单,
		if @formid in (4621,4611,4631)    
			  begin      
					insert into istockledgerlog       
					(companyid,sdorgid,periodid,matvalue,plantid,matcode,stcode,batchcode,formid,formname,doccode,docdate,doctype,      
					cltcode,vndcode,docitem,docrowid,digit,uom,baseuomrate,uomrate,baseuom,      
					indigit,outdigit,inledgerdigit,inledgeramount,outledgerdigit,outledgeramount,      
					incspdigit,outcspdigit,invspdigit,outvspdigit,salesflag,cspflag,vspflag,inouttype,instcode,end4,matcost,outrateamount)      
					select  companyid,sdorgid,periodid,matvalue,plantid,matcode,stcode,batchcode,formid,formname,doccode,docdate,doctype,      
					cltcode,'' as vndcode,docitem,rowid,digit,uom,baseuomrate,uomrate,baseuom,      
					0 as indigit,basedigit as outdigit,0 as inledgerdigit,0 as inledgeramount,basedigit as outledgerdigit,matcost as outledgeramount,      
					0 incspdigit,0 outcspdigit,0 invspdigit,0 outvspdigit,1 salesflag,0 cspflag,0 vspflag,'',stcode2,end4,matcost,ratemoney
					from vCommsales with(nolock)
					where doccode=@doccode      
			  end
			--供应商代销单
			if @formid in (4622,4610,4630)   
			begin    
				insert into istockledgerlog       
				(companyid,sdorgid,periodid,matvalue,plantid,matcode,stcode,batchcode,formid,formname,doccode,docdate,doctype,      
				cltcode,vndcode,docitem,docrowid,digit,uom,baseuomrate,uomrate,baseuom,      
				indigit,outdigit,inledgerdigit,inledgeramount,outledgerdigit,outledgeramount,      
				incspdigit,outcspdigit,invspdigit,outvspdigit,salesflag,cspflag,vspflag,inouttype,instcode,end4,matcost,inrateamount)      
				select   companyid,sdorgid,periodid,matvalue,plantid,matcode,stcode,batchcode,formid,formname,doccode,docdate,doctype,      
				cltcode,'',docitem,rowid,digit,uom,baseuomrate,uomrate,baseuom,      
				basedigit   indigit,0 outdigit,basedigit inledgerdigit ,netmoney inledgeramount,0 outledgerdigit,0 outledgeramount,    
				basedigit incspdigit,netmoney outcspdigit,0 invspdigit,0 outvspdigit,1 salesflag,0 cspflag,0 vspflag,'',stcode2,end4 ,matcost     ,ratemoney
				from vCommsales with(nolock)
				where doccode=@doccode   
			end
		--调拔出库单,从sp_istldlog_quickmove转移来
		if @FormID in(2424)
			BEGIN
				 INSERT INTO istockledgerlog( companyid,sdorgid, periodid, matvalue, plantid, matcode, 
				   stcode, batchcode, formid, formname, doccode, docdate, doctype, 
				   cltcode, vndcode, docitem, docrowid, digit, uom, baseuomrate, uomrate, 
				   baseuom, indigit, outdigit, inledgerdigit, inledgeramount, 
				   outledgerdigit, outledgeramount, incspdigit, outcspdigit, invspdigit, 
				   outvspdigit, salesflag, cspflag, vspflag, inouttype, instcode,end4,matcost,outrateamount)
			SELECT companyid,sdorgid,periodid,matvalue,plantid,matcode,stcode,batchcode,formid,
				   formname,doccode,docdate,doctype,cltcode,'',docitem,rowid,digit,uom,
				   baseuomrate,uomrate,baseuom,0,basedigit,0,0,basedigit,matcost,0,0,0,0,
				   1,0,0,pricememo,instcode,end4,MatCost,ratemoney
			FROM   VSPKOITEM
			WHERE  doccode = @doccode
			END
		--批发销售出库单,4031功能号移出,不在再此处处理,而改在4061中集中处理.
		if @FormID in(2399,2401,2414,2417,2419,2434,2450,4950,9955)
			BEGIN
				 insert into istockledgerlog 
				   (companyid,sdorgid,periodid,matvalue,plantid,matcode,stcode,batchcode,formid,formname,doccode,docdate,doctype,
					cltcode,vndcode,docitem,docrowid,digit,uom,baseuomrate,uomrate,baseuom,
					indigit,outdigit,inledgerdigit,inledgeramount,outledgerdigit,outledgeramount,
					incspdigit,outcspdigit,invspdigit,outvspdigit,salesflag,cspflag,vspflag,inouttype,end4,matcost,outrateamount)
				   select  
					companyid,sdorgid,periodid,matvalue,plantid,matcode,stcode,batchcode,formid,formname,doccode,docdate,doctype,
					cltcode,vndcode,docitem,rowid,digit,uom,baseuomrate,uomrate,baseuom,
					0 indigit,basedigit outdigit,0 inledgerdigit,0 inledgeramount,basedigit outledgerdigit,matcost outledgeramount,
					0,0,0,0,1,0,0,pricememo,end4,MatCost,ratemoney
				   from VSPKOITEM with(nolock)
				   where doccode=@doccode
			END
		--批发销售退货
		if @FormID in(2418,2420,4032,4951)
			BEGIN
				--内部销售退货还需要写内部采购退货4062的库存明细账
				if @FormID in(4032)
					BEGIN
						select @Refcode=refCode,@PeriodID=PeriodID
						from spickorderhd with(nolock)
						where DocCode=@Doccode
						exec sp_AddMatStockLedger 4062,@Refcode,'',@UserCode,@TerminalID
					END
				INSERT INTO istockledgerlog( companyid,sdorgid, periodid, matvalue, plantid, matcode, 
			   stcode, batchcode, formid, formname, doccode, docdate, doctype, 
			   cltcode, vndcode, docitem, docrowid, digit, uom, baseuomrate, uomrate, 
			   baseuom, indigit, outdigit, inledgerdigit, inledgeramount, 
			   outledgerdigit, outledgeramount, incspdigit, outcspdigit, invspdigit, 
			   outvspdigit, salesflag, cspflag, vspflag, inouttype,end4,matcost,inrateamount)
				SELECT companyid,sdorgid,periodid,matvalue,plantid,matcode,stcode,batchcode,formid,
					   formname,doccode,docdate,doctype,cltcode,vndcode,docitem,rowid,digit,
					   uom,baseuomrate,uomrate,baseuom,0,-basedigit,0,0,-basedigit,-matcost,0,
					   0,0,0,1,0,0,pricememo,end4,-MatCost,ratemoney
				FROM   VSPKOITEM with(nolock)
				WHERE  doccode = @doccode
			END
		--从原有sp_DJMwritestocklog 转入
		if @FormID in(2137)
			BEGIN
				insert into istockledgerlog     
				  (companyid,periodid,matvalue,plantid,matcode,stcode,batchcode,formid,formname,
				  doccode,docdate,doctype,workshopid,cltcode,vndcode,docitem,docrowid,
				  digit,uom,baseuomrate,uomrate,baseuom,indigit,outdigit,inledgerdigit,inledgeramount,outledgerdigit,  
				  outledgeramount,incspdigit,outcspdigit,invspdigit,outvspdigit,salesflag,cspflag,vspflag,inouttype)    

				SELECT ma.usertxt1,mo.PeriodID,'',ma.usertxt1,ma.MatCode,ma.stcode,ma.BatchCode,mo.FormID,g.formname,
				mo.DocCode,mo.DocDate,mo.DocType,mo.workshopid,mo.cltCode,mo.vndCode,ma.DocItem,ma.rowid,
				ma.Digit,ma.UOM,1,1,ma.UOM,0,0,0,ma.userprice2,0,
				0,0,0,0,0,0,0,0,ma.inouttype
				FROM MObileAssurehd mo with(nolock) JOIN MObileAssureitem ma with(nolock) ON mo.DocCode=ma.DocCode AND mo.DocCode=@doccode
				JOIN gform g ON g.formid=mo.FormID
			END
		--从 sp_writestocklog 转入
		if @FormID in(1512)
			BEGIN
				  INSERT into istockledgerlog( companyid, periodid, plantid, matcode, 
						 stcode,sdorgid, formid, doccode, docdate, doctype, docitem, docrowid, digit,  
						    indigit, outdigit, inledgerdigit, 
						 inledgeramount, outledgerdigit, outledgeramount, incspdigit, 
						 outcspdigit, invspdigit, outvspdigit, salesflag, cspflag, vspflag, 
						 inouttype, matcost, inrateamount)
				  SELECT  c.companyid,c.periodid,c.plantid,b.matcode,b.stcode,b.sdorgid,
						 c.formid,c.doccode,c.docdate,c.doctype,b.DocItem,b.rowid,0,0,
						 0,0,b.totalmoney,0,0,0,0,0,0,0,0,0,1,b.totalmoney,b.ratemoney
				  FROM   imatdoc_h  c with(nolock) inner join imatdoc_d b with(nolock) on b.doccode=c.doccode	  
				  WHERE  c.doccode = @doccode
			END
		--原100042过账逻辑转入
		if @FormID in(1506,1510,1511)	
			BEGIN
				INSERT into istockledgerlog( companyid,sdorgid, periodid, matvalue, plantid, matcode, 
				       stcode, batchcode, formid, formname, doccode, docdate, 
				       doctype, workshopid, cltcode, vndcode, docitem, docrowid, 
				       digit, uom, baseuomrate, uomrate, baseuom, indigit, 
				       outdigit, inledgerdigit, inledgeramount, outledgerdigit, 
				       outledgeramount, incspdigit, outcspdigit, invspdigit, 
				       outvspdigit, salesflag, cspflag, vspflag, inouttype,matcost,inrateamount)
				Select companyid ,sdorgid,periodid ,matvalue ,plantid ,matcode ,
				      stcode ,batchcode ,formid ,formname ,doccode ,
				      docdate ,doctype ,workshopid ,cltcode ,vndcode ,
				      docitem ,rowid ,digit ,uom ,baseuomrate ,uomrate
				      ,baseuom ,0,0,0,netmoney ,0,0,0,0,0,0,0,0,0,
				      inouttype,v.matcost,v.ratemoney
				From vmatdoc v with(nolock)
				where v.DocCode=@Doccode
			END
		--返厂返回与串号调整
		if @FormID in(1553,1557)
			BEGIN
				--取出单据基本信息
				select @stcode=i.stcode,@Docdate=i.DocDate,@Doctype=i.DocType,@PeriodID=i.PeriodID
				from iseriesloghd i with(nolock)
				where i.DocCode=@Doccode
				if @@ROWCOUNT=0
					BEGIN
						raiserror('单据不存在，无法写入库存明细帐.',16,1)
						return
					END
				--取仓库信息
				select @CompanyID=os.PlantID,@PeriodID =coalesce(nullif(@PeriodID,''),nullif(dbo.getperiod(os.PlantID,'库存事务',@docdate),''),convert(varchar(7),@docdate,120)),@sdorgid=os.sdorgid
				from oStorage os with(nolock) 
				where os.stCode=@stcode
				if @@ROWCOUNT=0
					BEGIN
						raiserror('仓库不存在，无法写入库存明细帐.',16,1)
						return
					END
				--先写出库串号
				INSERT into istockledgerlog( companyid,sdorgid, periodid,  plantid, matcode, 
				       stcode, formid, doccode, docdate, 
				       doctype, docitem, docrowid, 
				       digit, uom, baseuomrate, uomrate, baseuom, indigit, 
				       outdigit, inledgerdigit, inledgeramount, outledgerdigit, 
				       outledgeramount, incspdigit, outcspdigit, invspdigit, 
				       outvspdigit, salesflag, cspflag, vspflag, inouttype,matcost,outrateamount)
				Select @companyid,@sdorgid,@PeriodID,@companyid ,img.matcode , @stcode  ,@formid  ,@doccode,@docdate ,@doctype,
				      v.docitem ,v.rowid ,1 as digit ,img.uom ,img.baseuomrate ,img.uomrate
				      ,img.baseuom ,-1 as indigit,0 as outdigit,-1 as inledgerdigit,-netmoney as inledgeramount,0 as outledgerdigit,
				      0 as outledgeramount,0 incspdigit,0 outcspdigit,0 invspdigit,0 outvspdigit,0 salesflag,0 cspflag,0 vspflag,inouttype,v.netmoney,v.ratemoney
				From  iserieslogitem  v with(nolock)   
				inner join iMatGeneral img with(nolock) on v.matcode1=img.MatCode
				where v.DocCode=@Doccode
				--再写入库串号
				INSERT into istockledgerlog( companyid, sdorgid,periodid, plantid, matcode, 
				       stcode, formid, doccode, docdate, 
				       doctype, docitem, docrowid, 
				       digit, uom, baseuomrate, uomrate, baseuom, indigit, 
				       outdigit, inledgerdigit, inledgeramount, outledgerdigit, 
				       outledgeramount, incspdigit, outcspdigit, invspdigit, 
				       outvspdigit, salesflag, cspflag, vspflag, inouttype,matcost,outrateamount)
				Select @companyid,@SDorgid ,@PeriodID ,	@companyid ,img.matcode ,@stcode  ,@formid  ,@doccode,@docdate ,@doctype,
				      v.docitem ,v.rowid ,1 as digit ,img.uom ,img.baseuomrate ,img.uomrate
				      ,img.baseuom ,1 as indigit,0 as outdigit,1 as inledgerdigit,v.netmoney1 as inledgeramount,0 as outledgerdigit,
				      0 as outledgeramount,0 incspdigit,0 outcspdigit,0 invspdigit,0 outvspdigit,0 salesflag,0 cspflag,0 vspflag,inouttype,v.netmoney1,v.ratemoney1
				From  iserieslogitem  v with(nolock)   
				inner join iMatGeneral img with(nolock) on v.matcode=img.MatCode
				where v.DocCode=@Doccode

			END
	END
	 