/* 
过程名称:[sp_CreateSalesDoc]
功能描述:将运营商业务单据转换成正常的零售/退货单据
参数:见声名
编写:三断笛
时间:
-------------------------------------------------------------
修改:2012-06-10 三断笛 新增对运营商返销的支持;将业务数据先缓存至临时表再进行操作,并调整代码结构,提升性能

示例:        
select * from update osdorg set credit=6489.64 where sdorgid='2.769.128'        
[sp_CreateSalesDoc] 9146,'PS20120101003948','system','管理员'                            
begin tran        
exec sp_createsalesdoc 9158,'BK20120611000001','system','system',0,''        
rollback        
SELECT docstatus,* FROM sPickorderHD sph WHERE sph.refcode='PS20120101000416'   
select * from spickorderitem where doccode='RE20120102000017'       
              commit      
begin tran
declare @doccode varchar(20)
exec sp_CreateSalesDoc 9244,'KHFX201210060061','system','system',9244,@doccode output
print @doccode

commit
rollback              
*/                                      
ALTER PROC [dbo].[sp_CreateSalesDoc]                                      
	@formid INT,                                
	@doccode VARCHAR(20),                                
	@usercode VARCHAR(20),                                
	@userName VARCHAR(50),                                
	@optionId INT = 0,                                
	@newDoccode VARCHAR(20) = '' OUTPUT        
--WITH ENCRYPTION                                
AS                                
set nocount on            
BEGIN
-------------------------------------------------------------------变量定义--------------------------------------------------------------------                 
	 DECLARE @stcode      VARCHAR(50),                                  
			@stname      VARCHAR(200),                                  
			@seriescode  VARCHAR(50),                                  
			@sdorgid     VARCHAR(100),                                  
			@matcode     VARCHAR(100),                 
			@TBmatcode   varchar(50),                               
			@tips VARCHAR(MAX)
	  DECLARE @doctype VARCHAR(30),@old int,@ComboCode varchar(50),@PackageID varchar(50),
	  @refcode VARCHAR(50),@refformID int,@refrefcode varchar(50),@dpttype varchar(50),@ICCID VARCHAR(50),@CardMatcode VARCHAR(50),@BusiStockState varchar(100)
	  declare @Score money,@Score1 money,@TotalScore money,@BusiType varchar(50)
  ----------------------------------------------------------------初始化数据-----------------------------------------------------------------------------------------------
--取出数据
 if @formid in(9102,9146,9237,9244)
	BEGIN
		--取出表头信息
		select * into #Unicom_Orders from Unicom_Orders uo with(nolock) where uo.DocCode=@doccode
		SELECT @stcode = stcode, @stname = stname,@sdorgid = s.sdorgid,@doctype=s.DocType,@refcode=refcode,@refformID=refformid,
		@old=isnull(s.old,0),  @ComboCode=ComboCode,@PackageID=PackageID,@dpttype=o.dpttype,@ICCID=iccid,@seriescode=seriescode,
		@Score=isnull(s.Score,0),@Score1=isnull(s.Score1,0),@TotalScore=isnull(s.totalscore,0)
			  FROM   #Unicom_Orders s left join osdorg o on s.sdorgid=o.sdorgid
			  WHERE  s.docCode = @doccode
		--取出明细表信息.返销单直接使用原业务单据表体信息
		select * into #Unicom_Orderdetails from Unicom_OrderDetails uod with(nolock) where uod.DocCode=case when @formid in(9244) then @refcode  else @doccode END
		select top 1 @TBmatcode=matcode from #Unicom_OrderDetails where doccode=@doccode and isnull(monvalue,0)<>0
		--返销时,取出政策的库存状态字段,防止将已售后机参与自备机政策后又退回仓库.
		select @BusiStockState=pg.StockState,@BusiType=pg.PolicyGroupID
		  from T_PolicyGroup pg inner join policy_h ph with(nolock) on pg.PolicyGroupID=ph.PolicygroupID and ph.DocCode=@PackageID
	end
if @formid in(9153,9157,9158,9159,9160,9165,9167,9180,9267,9752,9755)
	BEGIN
		--取出表头信息
		select * into #BusinessAcceptance_H from BusinessAcceptance_H bah with(nolock) where bah.docCode=@doccode
		SELECT @stcode = stcode, @stname = stname, @seriescode = SimCode1, @sdorgid = bah.sdorgid, @matcode = matcode ,
		@Score=isnull(bah.totalScore,0),@TotalScore=isnull(bah.totalscore,0),@BusiType=BUSITYPE,
		 @doctype=o.dpttype,@ICCID=iccid--select stcode,stname,simcode1,sdorgid,matcode,*                                
		 FROM   #BusinessAcceptance_H bah   WITH(NOLOCK)  left join osdorg o on bah.sdorgid=o.sdorgid                                
		 WHERE  bah.docCode = @doccode--  'BK20100717000002'  
		 --是加盟店则直接跳出
		IF EXISTS(SELECT 1
	          FROM   #BusinessAcceptance_H h WITH(NOLOCK)
	                 LEFT JOIN vstorage e ON  h.stcode = e.stcode
	          WHERE  doccode = @doccode
	                 AND h.dpttype = '加盟店'
	   )
		BEGIN
			RETURN
		END
	END
--------------------------------------------------------------------加盟店业务受理------------------------------------------------------------------------------
--加盟店不生成销售单                      
 if @formID in(9102,9146,9237,9244)	and @dpttype='加盟店'	--补上功能号 2012-06-06 三断笛                      
	begin
		if not exists(select 1 from #unicom_orders where doccode=@doccode  and dpttype='加盟店' and (isnull(FWcost,0)<>0 or isnull(TBcost,0)<>0))
			begin
				return
			end
		
			IF NOT EXISTS(SELECT 1 FROM oPlantSDOrg ops WHERE ops.SDOrgID= @sdorgid)
			BEGIN
				RAISERROR('该部门尚未指定到任何公司,请联系系统管理员.',16,1)
				RETURN
			END  
		if @FormID in(9102,9146,9237)
				begin            
					EXEC sp_newdoccode 2419,  '',  @newDoccode OUTPUT              
					  
					  --更新入网和套包销售回填零售销售单信息                                
					  UPDATE Unicom_Orders                                
					  SET    refformid = 2419,                                
							 Refcode = @newDoccode                                
					  WHERE  doccode = @doccode                    
                          
					  --生成单头       select top 1 * from sPickorderHD where doccode='RE20100724000019'                              
					  INSERT INTO sPickorderHD(DocCode,DocStatus,DocType,FormID,refformid,refcode,docdate,         
							 stcode,stname,sdorgid,sdorgname,Companyid,CompanyName,sdgroup,sdgroupname,instcode,instname,                                  
							 sdorgid2,sdorgname2,Companyid2,CompanyName2,sdgroup1,sdgroupname1,pick_ref,                                 
							 plantid,plantname,plantid2,plantname2,cltcode,cltname,UserTxt2,                                  
							 UserDigit1,UserDigit2,UserDigit3,userdigit4,HDText,matstatus,EnterName,EnterDate,done,achievement,        
					reftype,Rewards,dpttype,YFKdoccode,YFKmoney,FKdoccode,FKmoney,BusiType,
					DeductAmout,ReservedDoccode,PackageID,CustomerID,Score,Score1,TotalScore)                                  
					  SELECT top 1 @newDoccode, 50, '销售出库', 2419, @formid, @doccode, convert(varchar(10),docdate,120),                                   
							 stcode, stname, s.sdorgid,s.sdorgname,s.companyid,companyname, sdgroup, sdgroupname, stcode,stname,                                    
							 s.sdorgid, s.sdorgname,companyid2,companyname2, sdgroup,sdgroupname,sdgroup,                                
							 s.companyid, s.plantname, s.plantid2, s.plantname2,cltcode,cltname,SeriesNumber,                                  
							 isnull(tbcost,0)+isnull(fwcost,0),0,0,isnull(tbcost,0)+isnull(fwcost,0),'加盟商'+@doctype,'正常', s.entername, s.EnterDate, 1,'业务员客户',        
					@doctype,Rewards,dpttype,YFKdoccode,YFKmoney,FKdoccode,FKmoney,@BusiType  ,
					s.DeductAmout,s.ReservedDoccode,s.PackageCode,s.CustomerID,isnull(@Score,0),isnull(@Score1,0),isnull(@TotalScore,0)                    
					  FROM   #Unicom_Orders s  WITH(NOLOCK) --left JOIN voPlantSDOrg b ON  s.SdorgID =b.SDOrgID                                  
					  WHERE  s.docCode = @doccode             
				end
			 --返销
			IF @formid IN(9244)
				BEGIN
					EXEC sp_newdoccode 2420,  '',  @newDoccode OUTPUT                                
 
					  --生成单头       select top 1 * from sPickorderHD where doccode='RE20100724000019'                              
					  INSERT INTO sPickorderHD(DocCode,DocStatus,DocType,FormID,refformid,refcode,refrefformid,refrefcode,docdate,         
							 stcode,stname,sdorgid,sdorgname,Companyid,CompanyName,sdgroup,sdgroupname,instcode,instname,                                  
							 sdorgid2,sdorgname2,Companyid2,CompanyName2,sdgroup1,sdgroupname1,pick_ref,  
							 plantid,plantname,plantid2,plantname2,cltcode,cltname,UserTxt2,usertxt1,usertxt3,prdno,  
							 UserDigit1,UserDigit2,UserDigit3,userdigit4,HDText,matstatus,EnterName,EnterDate,done,achievement,        
					reftype,Rewards,dpttype,YFKdoccode,YFKmoney,FKdoccode,FKmoney,BusiType,DeductAmout,
					ReservedDoccode,PackageID,CustomerID,ClearDocCode,Score,Score1,TotalScore,Rewards)                                  
					  SELECT top 1 @newDoccode, 0, '销售出库', 2420, 2419, sph.doccode,s.refformid,s.refcode, convert(varchar(10),s.docdate,120),                                   
							 sph.stcode, sph.stname, s.sdorgid,s.sdorgname,s.companyid,sph.companyname, sph.sdgroup, sph.sdgroupname, sph.stcode,sph.stname,                                    
							 s.sdorgid, s.sdorgname,sph.companyid2,sph.companyname2, s.sdgroup,s.sdgroupname,s.sdgroup,
							 s.companyid, s.plantname, s.plantid2, s.plantname2,s.cltcode,s.cltname,s.cltname,s.cltcode,s.SeriesNumber,'运营商返销',
							 isnull(s.tbcost,0)+isnull(s.fwcost,0),0,0,isnull(s.tbcost,0)+isnull(s.fwcost,0),'加盟商'+s.doctype,'正常', s.entername, s.EnterDate, 1,'业务员客户',        
					s.doctype,s.Rewards,s.dpttype,s.YFKdoccode,s.YFKmoney,s.FKdoccode,s.FKmoney,@BusiType  ,s.DeductAmout,
					s.ReservedDoccode,s.PackageCode,s.CustomerID,sph.DocCode,sph.score,sph.score1,sph.totalscore,sph.Rewards  
					  FROM   #Unicom_Orders s  WITH(NOLOCK),sPickorderHD sph WITH(NOLOCK) --left JOIN voPlantSDOrg b ON  s.SdorgID =b.SDOrgID                                  
					  WHERE  s.docCode = @doccode 
					  AND sph.refcode=s.refcode
					  AND sph.FormID=2419
 
				END
				--插入统一的明细表
				     
				  --由明细列表生成销售明细 select * from voPlantSDOrg                
				  INSERT INTO sPickorderitem(doccode,docitem,rowid,itemtype,seriesCode,                                  
						 matcode,matname,uom,matgroup,baseuom,packagecode,baseuomrate,                                  
						 uomrate,ratetxt,stcode,stname,price,totalmoney,digit,basedigit,monvalue,monadd,userdigit2)                  
				 --服务成本                              
				 select @newDoccode,row_number() over(order by @newdoccode),NEWID(), '&自有&','',                                
				  (select top 1 PropertyValue from _sysNumberAllocationCfgValues where PropertyName='靓号服务费'),l.matname,l.salesuom,l.matgroup,l.salesuom,null,1,                                  
						  1,1,@stcode,@stname, s.FWcost, s.FWcost, 1, 1 ,0,0,NULL                  
				 from #Unicom_Orders s  WITH(NOLOCK) INNER JOIN iMatGeneral l on l.MatCode=(select top 1 PropertyValue from _sysNumberAllocationCfgValues where PropertyName='靓号服务费') where s.doccode=@doccode and isnull(s.FWcost,0)<>0                                
				 UNION all--手机                                
			   select @newDoccode,row_number() over(order by @newdoccode),NEWID(), '&自有&','',                                
				  @TBmatcode,l.matname,l.salesuom,l.matgroup,l.salesuom,null,1,                                  
						   1,1,@stcode,@stname, s.TBcost, s.TBcost, 1, 1 ,0,0,NULL                               
				 from #Unicom_Orders s  WITH(NOLOCK) INNER JOIN iMatGeneral l ON @TBmatcode=l.MatCode where s.doccode=@doccode and isnull(s.TBcost,0)<>0
				  
				IF @formid IN(9102,9237,9146)
					BEGIN
						EXEC CashIntype @newDoccode,@FormID
					END
				ELSE IF @formid IN(9244)
					BEGIN
						EXEC CashIntype1 @newDoccode
					END
		return                      
	END
	--------------------------------------------------------------------非加盟店业务受理------------------------------------------------------------------------------
	 ----------------------------------------------------------------------------生成新单号----------------------------------------------------------------
	 IF @formid IN(9102,9146,9237,9158,9167,9267)
		BEGIN
			 EXEC sp_newdoccode 2419,  '',  @newDoccode OUTPUT  
		END
	--返销
	ELSE IF @formid IN(9244)
		BEGIN
			EXEC sp_newdoccode 2420,  '',  @newDoccode OUTPUT   
		END

	SET TRANSACTION ISOLATION LEVEL READ COMMITTED      
	--开启事务
	BEGIN TRAN
-----------------------------------------------------------------------其他业务受理生成零售单-------------------------------------------------------------------                         
 --正面开始生成单据
 BEGIN try                         
	 IF @formid IN (9158,9167,9267) --补卡时自动生成一张白卡零售单                                  
	 BEGIN                                  
	     BEGIN TRAN
		IF NOT EXISTS(SELECT 1 FROM oPlantSDOrg ops WHERE ops.SDOrgID= @sdorgid)
		BEGIN
			RAISERROR('该部门尚未指定到任何公司,请联系系统管理员.',16,1)
			RETURN
		END
		 --更新补卡单生成的零售销售单                                    
		 UPDATE BusinessAcceptance_H                                  
		 SET    refformid = 2419,                                  
				RefDoccode = @newDoccode                
		 WHERE  doccode = @doccode                                   
		 --生成单头                                     
		 INSERT INTO sPickorderHD(DocCode,DocStatus,DocType,FormID,refformid,                                  
				refcode,docdate,periodid,stcode,stname,sdorgid,sdorgname,                                  
				Companyid,CompanyName,sdgroup,sdgroupname,instcode,instname,                                  
				sdorgid2,sdorgname2,Companyid2,CompanyName2,sdgroup1,sdgroupname1,                       
				plantid,plantname,plantid2,plantname2,cltcode,cltname,UserTxt2,prdno,                                 
				UserDigit1,UserDigit2,userdigit4,HDText,matstatus,EnterName,EnterDate,done,achievement,
				Reftype,dpttype,BusiType,CustomerID,pick_ref,Score,Score1,TotalScore)                                  
		 SELECT top 1 @newDoccode, 50, '销售出库', 2419, @formid, @doccode, convert(varchar(10),docdate,120),                                   
				dbo.getperiodid(2419, companyid, docdate), stcode, stname, bah.sdorgid,                                   
				bah.sdorgname, b.plantid, NULL, sdgroup, sdgroupname, stcode,                                   
				stname, bah.sdorgid, bah.sdorgname, bah.companyid, NULL, sdgroup,                                   
				sdgroupname, b.plantid, NULL, bah.companyid, NULL, customercode,                                   
				customername, SeriesNumber,'运营商返销', totalmoney1,totalmoney2, totalmoney, @doctype,                                   
				'正常', entername, bah.EnterDate, 1,'业务员客户',
				@doctype,dpttype,bah.busitype,bah.customerid,bah.sdgroup,isnull(@Score,0),isnull(@Score1,0),isnull(@TotalScore,0)
		FROM   #BusinessAcceptance_H bah  WITH(NOLOCK) left JOIN voPlantSDOrg b ON  bah.SdorgID = b.SDOrgID                                  
		WHERE  bah.docCode = @doccode          
		 --生成明细表   并更新商品资料和价格                                
		 INSERT INTO sPickorderitem(doccode,docitem,rowid,itemtype,seriesCode,                                  
				matcode,matname,uom,matgroup,baseuom,packagecode,baseuomrate,                                  
				uomrate,ratetxt,stcode,stname,price,totalmoney,digit,basedigit)                                  
		 SELECT @newDoccode, 1, NEWID(), '&自有&', b.simcode1, ig.matcode, ig.matname,ig.salesuom,ig.matgroup,ig.salesuom,ig.packagecode,1,                                  
				1,1,@stcode,@stname, b.price, b.TotalMoney, 1, 1                                 
		 FROM   #BusinessAcceptance_H b  WITH(NOLOCK) INNER JOIN iMatGeneral ig ON b.MatCode=ig.MatCode                                  
		 WHERE  b.docCode = @doccode                                   
		 --SELECT refformid,refcode,* FROM sPickorderHD sh WHERE sh.FormID=2419 AND sh.refformid=9158 and refcode=''                                  
		 --select ig.matcode, ig.matname,ig.salesuom,ig.matgroup,ig.packagecode,* from imatgeneral ig where matcode=(select matcode from BusinessAcceptance_H where doccode='BK20100717000002')                                
		IF ISNULL(@seriescode,'')<>''                                 
		begin                                 
			UPDATE sPickorderitem SET vndcode = i.vndcode FROM sPickorderitem s  WITH(NOLOCK)                                  
			INNER JOIN  iSeries  i  WITH(NOLOCK) ON s.seriesCode=i.SeriesCode                           
			WHERE s.doccode=@newDoccode                                
			and i.seriesCode=@seriescode                                  
		end
		 --更新收款人                                  
		 UPDATE spickorderhd
		 SET    cashname = (
		            SELECT TOP 1 username
		            FROM   CheckNumberAllocationDoc_LOG WITH(NOLOCK)
		            WHERE  doccode = @doccode
		                   AND checkstate = '请求审核'
		            ORDER BY   enterdate DESC
		        )
		WHERE  doccode = @newDoccode         
		IF @formid IN(9158,9167,9267)
			BEGIN
				EXEC CashIntype @newDoccode,@FormID
			END
	 END
	 -------------------------------------------------------------其他业务受理写入积分明细表--------------------------------------------------------------------------
	 if @formid in(9153,9159,9160,9165,9180,9752,9755)
		BEGIN
			INSERT INTO Salelog
			  ( doccode, formid, doctype, docdate, periodid, refcode, companyid, plantid, sdorgid, sdorgname,   cltcode, cltname,  stcode, 
				stname, sdgroup, sdgroupname,  HDText,totalmoney, entername, enterdate, modifyname, modifydate, postname, postdate, auditing, 
				auditingname, auditingdate,   dpttype, BusiType,docitem,rowid,matcode,matname,Score, Score1, TotalScore  )
			--增加memo2字段，对应b.usertxt3,手机号码 memo3套餐
			--调整RefCode,如果为退货单,则取ClearCode,否则取Refcode      
			SELECT a.doccode, a.formid, a.doctype, a.docdate, a.periodid, null as refcode, a.companyid, a.companyid ,
				 a.sdorgid, a.sdorgname,a.CustomerCode,a.CustomerName,  a.stcode, a.stname,  a.sdgroup, a.sdgroupname , 
				   a.Remark,a.TotalMoney,  a.entername, a.enterdate, a.modifyname, 
				   a.modifydate, a.postname, a.postdate, a.Audits, a.auditingname, a.auditingdate, 
				    a.dpttype, a.BusiType,1,newid(),c.MatCode,c.matname,  isnull(@Score,0),isnull( @Score1,0), isnull(@TotalScore,0)
				   --into #tableXXX
			FROM #BusinessAcceptance_H a(NOLOCK)
				   LEFT JOIN _sysNumberAllocationCfgValues     b 
				   ON b.PropertyName=case when a.FormID in(9153) then '代办-过户'
															when a.formid in(9159) then '代办-客户资料变更'
															when a.formid in(9160) then '代办-套餐变更'
															when a.formid in(9165) then '代办-报开报停'
															when a.formid in(9180) then '代办-银行托收'
															when a.formid in(9752) then '代办-SP业务'
															when a.formid in(9755) then '代办-亲情业务'
														end
				   LEFT JOIN imatgeneral c ON  b.PropertyValue = c.matcode
			WHERE  a.doccode = @doccode --and c.matgroup <> 'P10'
				   AND a.formid IN (9153,9159,9160,9165,9180,9752,9755) --限制在销售业务

		END
	
	--------------------------------------------------------------------套包单处理--------------------------------------------------------------------------                       
	 IF @formid IN (9102,9146,9237) --客户新入网单,套包销售单自动生成一张零售单                    
	 BEGIN                                  
		IF NOT EXISTS(SELECT 1 FROM oPlantSDOrg ops with(nolock) WHERE ops.SDOrgID= @sdorgid)
			BEGIN
				RAISERROR('该部门尚未指定到任何公司,请联系系统管理员.',16,1)
				RETURN
			END
		 --更新入网和套包销售回填零售销售单信息                        
				 UPDATE Unicom_Orders                                
				 SET    refformid = 2419,                                
						Refcode = @newDoccode                                
				 WHERE  doccode = @doccode                                
				 --生成单头       select refformid,refcode,* from sPickorderHD where doccode='RE20100724000019'                              
				 INSERT INTO sPickorderHD(DocCode,DocStatus,DocType,FormID,refformid,refcode,docdate,                                  
						stcode,stname,sdorgid,sdorgname,Companyid,CompanyName,sdgroup,sdgroupname,instcode,instname,                                  
						sdorgid2,sdorgname2,Companyid2,CompanyName2,sdgroup1,sdgroupname1,                                  
						plantid,plantname,plantid2,plantname2,cltcode,cltname,UserTxt2,
						UserDigit1,UserDigit2,UserDigit2Text,UserDigit3,UserDigit3Text,userdigit4,UserDigit4Text,
						UserDigit5,UserDigit5Text,summoney,HDText,matstatus,EnterName,EnterDate,done,
						achievement,reftype,Rewards,dpttype,BusiType,DeductAmout,ReservedDoccode,PackageID,CustomerID,pick_ref,Score,Score1,TotalScore)                                  
				 SELECT top 1 @newDoccode, 50, '销售出库', 2419, @formid, @doccode, convert(varchar(10),docdate,120),                                   
						stcode, stname, s.sdorgid,s.sdorgname,b.plantid,companyname, sdgroup, sdgroupname, stcode,stname,                                    
						s.sdorgid, s.sdorgname,companyid2,companyname2, sdgroup,sdgroupname,                                  
						b.plantid, s.plantname, s.plantid2, s.plantname2,cltcode,cltname,SeriesNumber,                                
						UserDigit1,UserDigit2,UserDigit2Text,UserDigit3,UserDigit3Text,userdigit4,UserDigit4Text,
						UserDigit5,UserDigit5Text,summoney,@doctype,'正常', s.entername,         
						s.EnterDate, 1,'业务员客户',@doctype,Rewards,dpttype,@busitype,s.DeductAmout,
						s.ReservedDoccode,s.packagecode,s.customerid,sdgroup,s.Score,s.Score1,s.TotalScore
				 FROM   #Unicom_Orders s  WITH(NOLOCK) left JOIN voPlantSDOrg b ON  s.SdorgID =b.SDOrgID                                  
				 WHERE  s.docCode = @doccode
				 --print @newDoccode
				 --由明细列表生成销售明细       Unicom_OrderDetails                            
				 INSERT INTO sPickorderitem
				   (  doccode,   docitem,   rowid,   itemtype,   seriesCode,   matcode,   
					  matname,   uom,   matgroup,   baseuom,   packagecode,   
					  baseuomrate,   selfprice1,   end4,   price2,   ScorePrice,   
					  uomrate,   ratetxt,   stcode,   stname,   price,   totalmoney,   
					  digit,   basedigit,   monvalue,   monadd,   userdigit2,   
					  isSingleSale,   DeductAmout,   CouponsBarCode )
				 SELECT @newDoccode,  docitem,  NEWID(),  '&自有&',  seriesCode,  matcode,  matname,  uom,  matgroup,  baseuom,  NULL,  
						baseuomrate,  d.selfprice1,  d.end4,  price2,  d.ScorePrice,  
						uomrate,  NULL,  @stcode,  @stname,  price,  b.totalmoney,  
						digit,  digit,  monvalue,  monadd,  userdigit2,  b.isSingleSale,  
						b.DeductAmout,  b.CouponsBarCode
				 FROM   #Unicom_OrderDetails b WITH(NOLOCK)
						OUTER APPLY dbo.uf_salesSDOrgpricecalcu3(b.matcode, @sdorgid, b.Seriescode)  d
		 
				 UNION all
				 --基本预存    <<<编号要跟金额一致>>>                            
				 SELECT @newDoccode,  ROW_NUMBER() OVER(ORDER BY @newdoccode),  NEWID(),  '&自有&',  '',  l.matcode,  
				 l.matname,  l.salesuom,  l.matgroup,  l.salesuom,  l.packagecode,  
				 1,d.selfprice1, d.end4, 0 as price2,  0 as ScorePrice,  1,  1,  @stcode,  @stname,  isnull(s.BasicDeposits,0),  
						isnull(s.BasicDeposits,0),  1,  1,  0,  0,  NULL,  NULL,  NULL,  NULL
				 FROM   #Unicom_Orders s WITH(NOLOCK)
						INNER JOIN iMatGeneral l with(nolock)  ON  l.MatCode = (
								 SELECT TOP 1 PropertyValue
								 FROM   _sysNumberAllocationCfgValues
								 WHERE  PropertyName = '基本预存款'
							 )--s.matcode_price
							  outer apply dbo.uf_salesSDOrgpricecalcu3(l.matcode, @sdorgid, '') d
				 WHERE  s.doccode = @doccode
						AND ISNULL(s.price, 0) <> 0 
				 UNION all
				 --靓号预存      
				 SELECT @newDoccode,  ROW_NUMBER() OVER(ORDER BY @newdoccode),  NEWID(),  '&自有&',  '', l.matcode, 
				 l.matname,  l.salesuom,  l.matgroup,  l.salesuom,  l.packagecode,  
				  1,d.selfprice1, d.end4, 0 as price2,  0 as ScorePrice,  1,  1, @stcode,  @stname,  
						s.PhoneRate,  s.PhoneRate,  1,  1,  0,  0,  NULL,  NULL,  NULL,  
						NULL
				 FROM   #Unicom_Orders s WITH(NOLOCK)
						INNER JOIN iMatGeneral l with(nolock)  ON  l.MatCode = (
								 SELECT TOP 1 PropertyValue
								 FROM   _sysNumberAllocationCfgValues
								 WHERE  PropertyName = '靓号预存款'
							 ) --s.matcode_server
							   outer apply dbo.uf_salesSDOrgpricecalcu3(l.matcode, @sdorgid, '') d
				 WHERE  s.doccode = @doccode
						AND ISNULL(s.PhoneRate, 0) <> 0 
				 UNION all
				 --服务费用      
				 SELECT @newDoccode,  ROW_NUMBER() OVER(ORDER BY @newdoccode),  NEWID(),  '&自有&',  '',  l.matcode,  
				 l.matname,  l.salesuom,  l.matgroup,  l.salesuom,  l.packagecode,  
				 1,d.selfprice1, d.end4,0 as price2 ,  0 as ScorePrice,  1,  1, @stcode,  @stname,  s.ServiceFEE,  
						s.ServiceFEE,  1,  1,  0,  0,  NULL,  NULL,  NULL,  NULL
				 FROM   #Unicom_Orders s WITH(NOLOCK)
						INNER JOIN iMatGeneral l  ON  l.MatCode = (
								 SELECT TOP 1 PropertyValue
								 FROM   _sysNumberAllocationCfgValues
								 WHERE  PropertyName = '靓号服务费'
							 )-- s.matcode_phone
							  outer apply dbo.uf_salesSDOrgpricecalcu3(l.matcode, @sdorgid, '') d
				 WHERE  s.doccode = @doccode
						AND ISNULL(s.ServiceFEE, 0) <> 0 
				 UNION all
				 --其它预存      
				 SELECT @newDoccode,  ROW_NUMBER() OVER(ORDER BY @newdoccode),  NEWID(),  '&自有&',  '', l.matcode,
				 l.matname,  l.salesuom,  l.matgroup,  l.salesuom,l.packagecode,  
				 1,d.selfprice1, d.end4,0 as price2,  0 as ScorePrice,  1,  1, @stcode,  @stname,  s.OtherFEE,  s.OtherFEE,  
						1,  1,  0,  0,  NULL,  NULL,  NULL,  NULL
				 FROM   #Unicom_Orders s WITH(NOLOCK)
						INNER JOIN iMatGeneral l  ON  l.MatCode = (
								 SELECT TOP 1 PropertyValue
								 FROM   _sysNumberAllocationCfgValues
								 WHERE  PropertyName = '其它费用'
							 )-- s.matcode_other
							  outer apply dbo.uf_salesSDOrgpricecalcu3(l.matcode, @sdorgid, '') d
				 WHERE  s.doccode = @doccode
						AND ISNULL(s.OtherFEE, 0) <> 0
				union all
				--代收代付
				SELECT @newDoccode,  ROW_NUMBER() OVER(ORDER BY @newdoccode),  NEWID(),  '&自有&',  '', l.matcode,
				 l.matname,  l.salesuom,  l.matgroup,  l.salesuom,l.packagecode,  
				 1,d.selfprice1, d.end4, 0 as price2,  0 as ScorePrice,  1,  1, @stcode,  @stname,  s.Deposits,s.Deposits,  
						1,  1,  0,  0,  NULL,  NULL,  NULL,  NULL
				 FROM   #Unicom_Orders s WITH(NOLOCK)
						INNER JOIN iMatGeneral l  ON  l.MatCode =s.DepositsMatcode
						outer apply dbo.uf_salesSDOrgpricecalcu3(l.matcode, @sdorgid, '') d
				 WHERE  s.doccode = @doccode
						AND ISNULL(s.Deposits, 0) <> 0
				--空白卡
				UNION ALL
				SELECT @newDoccode,  ROW_NUMBER() OVER(ORDER BY @newdoccode),  NEWID(),  '&自有&',
				--若空白卡未做串号管理,则不写串号到销售单.
				case when isnull(l.matflag,0)=1 then  NULLIF(s.CardNumber,'') else NULL end, l.matcode,
				 l.matname,  l.salesuom,  l.matgroup,  l.salesuom,l.packagecode,  
				 1,d.selfprice1, d.end4,0 as price2,  0 as ScorePrice,  1,  1, @stcode,  @stname,  s.CardFEE1,  s.CardFEE1,  
						1,  1,  0,  0,  isnull(cardrewards,0),  NULL,  NULL,  NULL
				 FROM   #Unicom_Orders s WITH(NOLOCK)
						INNER JOIN iMatGeneral l WITH(NOLOCK)  ON  l.MatCode=s.CardMatCode
							  outer apply dbo.uf_salesSDOrgpricecalcu3(l.matcode, @sdorgid, '') d
				 WHERE  s.doccode = @doccode
				 AND isnull(s.CardMatCode,'')!=''
				 --将套餐写入明细表,供销售分析,并记录开户积分.
				 union all
				 SELECT @newDoccode,  ROW_NUMBER() OVER(ORDER BY @newdoccode),  NEWID(),  '&自有&',
				 NULL as Seriescode, l.matcode,
				 l.matname,  l.salesuom,  l.matgroup,  l.salesuom,l.packagecode,  
				 1,0 as selfprice1, 0 as end4, isnull(s.score,0),  0 as ScorePrice,  1,  1, @stcode,  @stname,  d.Price,  0 as totalmoney,  
						1,  1,  0,  0, 0 as userdigit2,  NULL,  NULL,  NULL
				 FROM   #Unicom_Orders s WITH(NOLOCK)
				  inner join combo_h d with(nolock) on s.combocode=d.ComboCode
						INNER JOIN iMatGeneral l WITH(NOLOCK)  ON  l.MatCode=d.matcode
				 WHERE  s.doccode = @doccode
 
				 --当销售时,若有串号,且政策要求用在库的机,则可以出串号.先判断前提条件再处理串号,减少对串号表的访问.
				if  isnull(@seriescode,'')<>'' and exists(select 1 from commondb.dbo.SPLIT(isnull(@BusiStockState,'在库'),',') s where s.list='在库')
					BEGIN
						--手机
						 INSERT INTO sPickorderitem
				   (  doccode,   docitem,   rowid,   itemtype,   seriesCode,   matcode,   
					  matname,   uom,   matgroup,   baseuom,   packagecode,   
					  baseuomrate,   selfprice1,   end4,   price2,   ScorePrice,   
					  uomrate,   ratetxt,   stcode,   stname,   price,   totalmoney,   
					  digit,   basedigit,   monvalue,   monadd,   userdigit2,   
					  isSingleSale,   DeductAmout,   CouponsBarCode )
						SELECT @newDoccode,  ROW_NUMBER() OVER(ORDER BY @newdoccode),  NEWID(),  '&自有&', NULLIF(s.seriescode ,''), l.matcode,
						 l.matname,  l.salesuom,  l.matgroup,  l.salesuom,l.packagecode,  
						 1,d.selfprice1, d.end4, 0 as price2,  d.ScorePrice,  1,  1, @stcode,  @stname,  s.MatMoney,  s.MatMoney,  
								1,  1,  0,  0,  isnull(matrewards,0),  NULL,  isnull(matdeductamount,0),  matcouponsbarcode
						 FROM   #Unicom_Orders s WITH(NOLOCK)
								inner join iSeries is1 with(nolock) on s.SeriesCode=is1.SeriesCode
							   INNER JOIN iMatGeneral l WITH(NOLOCK)  ON  is1.MatCode=l.MatCode 
									  outer apply dbo.uf_salesSDOrgpricecalcu3(l.matcode, @sdorgid, '') d
						 WHERE  s.doccode = @doccode
						 and is1.state=   '在库'	 --必须是在库的机器
					END
					--从积分明细表更新积分
					update a
						set a.price2=sll.Score
					from sPickorderitem a with(nolock),ScoreLedgerLog sll with(nolock)
					where a.DocCode=@newDoccode
					and sll.Doccode=@doccode
					and a.MatCode=sll.Matcode
				--更新供应商
				  UPDATE m
				  SET    vndcode = s.vndcode --select m.vndcode,s.vndcode,*
				  FROM   spickorderitem m WITH(NOLOCK)
						 LEFT JOIN iseries s  WITH(NOLOCK)
							  ON  m.seriescode = s.seriescode
				  WHERE  m.doccode = @newDoccode
						 AND ISNULL(m.seriescode, '') <> ''
						 AND ISNULL(m.vndcode, '') = ''
						 AND ISNULL(s.vndcode, '') <> ''        
				 --更新收款人  select top 1 username from CheckNumberAllocationDoc_LOG where checkstate='请求审核' order by enterdate desc        
					UPDATE spickorderhd
					SET    cashname = (
							SELECT TOP 1 username
							FROM   CheckNumberAllocationDoc_LOG  WITH(NOLOCK)
							WHERE  doccode = @doccode
								   AND checkstate = '请求审核'
							ORDER BY   enterdate DESC
						)
					WHERE  doccode = @newDoccode
			end
		-------------------------------------------------------------------------返销单---------------------------------------------------------------------------
		IF @formid IN(9244)
			BEGIN
				--取出对应的销售单号
				select @refrefcode=sph.refcode 
				from sPickorderHD sph with(nolock) 
				where sph.refcode=@refcode
				and sph.FormID=2419
				if @@ROWCOUNT=0
					BEGIN
						raiserror('返销的套包单尚未生成零售单,无法返销.',16,1)
						return
					END
				--生成返销单单头,从零售单直接复制       select refformid,refcode,* from sPickorderHD where doccode='RE20100724000019'                              
				 INSERT INTO sPickorderHD(DocCode,DocStatus,DocType,FormID,refformid,refcode,refrefformid,refrefcode,docdate,                                  
						stcode,stname,sdorgid,sdorgname,Companyid,CompanyName,sdgroup,sdgroupname,instcode,instname,                                  
						sdorgid2,sdorgname2,Companyid2,CompanyName2,sdgroup1,sdgroupname1,                                  
						plantid,plantname,plantid2,plantname2,cltcode,cltname,usertxt3,usertxt1,UserTxt2,prdno,                                 
						UserDigit1,UserDigit2,UserDigit2Text,UserDigit3,UserDigit3Text,userdigit4,UserDigit4Text,UserDigit5,
						UserDigit5Text,summoney,HDText,matstatus,EnterName,EnterDate,done,        
						achievement,reftype,Rewards,dpttype,BusiType,DeductAmout,ReservedDoccode,PackageID,
						CustomerID,pick_ref,Score,Score1,TotalScore,cleardoccode,DeductAmout,Rewards)                                  
				 SELECT top 1 @newDoccode, 0, '销售退货', 2420, sph.formid, sph.doccode,sph.refformid,sph.refcode, convert(varchar(10),s.docdate,120),                                   
						s.stcode, s.stname, s.sdorgid,s.sdorgname,sph.plantid,sph.companyname, sph.sdgroup, sph.sdgroupname, sph.stcode,sph.stname,                                    
						s.sdorgid, s.sdorgname,sph.companyid2,sph.companyname2, sph.sdgroup,sph.sdgroupname,                                  
						sph.plantid, sph.plantname, sph.plantid2, sph.plantname2,s.cltcode,s.cltname,s.cltcode,s.cltname,s.SeriesNumber,'运营商返销',                                 
						sph.UserDigit1,sph.UserDigit2,sph.UserDigit2Text,sph.UserDigit3,sph.UserDigit3Text,sph.userdigit4,sph.UserDigit4Text,sph.UserDigit5,sph.UserDigit5Text,s.summoney,s.doctype,'正常', s.entername,       
						s.EnterDate, 1,'业务员客户',s.doctype,s.Rewards,s.dpttype,s.doctype,s.DeductAmout,
						s.ReservedDoccode,s.packagecode,s.customerid,s.sdgroup,s.Score,s.Score1,s.TotalScore,sph.DocCode,sph.DeductAmout,sph.Rewards
				 FROM   #Unicom_Orders s  WITH(NOLOCK) 	 inner JOIN sPickorderHD sph WITH(NOLOCK) ON s.doccode=@refrefcode
				 WHERE sph.FormID=2419
				 --从零售单复制清单数据
				  INSERT INTO sPickorderitem
					   (  doccode,   docitem,   rowid,   itemtype,   seriesCode,   matcode,   
						  matname,   uom,   matgroup,   baseuom,   packagecode,   
						  baseuomrate,   selfprice1,   end4,   price2,   ScorePrice,   
						  uomrate,   ratetxt,   stcode,   stname,   price,   totalmoney,   
						  digit,   basedigit,   monvalue,   monadd,   userdigit2,   
						  isSingleSale,   DeductAmout,   CouponsBarCode )
				 select @newDoccode,   docitem,   rowid,   itemtype,   seriesCode,   matcode,   
					  matname,   uom,   matgroup,   baseuom,   packagecode,   
					  baseuomrate,   selfprice1,   end4,   price2,   ScorePrice,   
					  uomrate,   ratetxt,   stcode,   stname,   price,   totalmoney,   
					  digit,   basedigit,   monvalue,   monadd,   userdigit2,   
					  isSingleSale,   DeductAmout,   CouponsBarCode 
				 from sPickorderitem sp with(nolock)
				 where sp.DocCode=@refrefcode
			END
		   
		-----------------------------------------------------------生成完单据后，执行一次单据保存------------------------------------------------------------------
		IF @formid IN(9102,9237,9146)
			BEGIN
				EXEC CashIntype @newDoccode,@FormID
			END
		ELSE IF @formid IN(9244)
			BEGIN
				EXEC CashIntype1 @newDoccode
			END
	
		--提交事务
		COMMIT 
		--select * from sPickorderitem sp where sp.DocCode=@newDoccode
            
 END TRY
 BEGIN CATCH                          
	SELECT @tips='创建零售单失败. '+dbo.crlf()+'错误过程:'+ISNULL(ERROR_PROCEDURE(),'') +char(10)+'错误信息:'+ ISNULL(ERROR_MESSAGE(),'')              
	IF @@TRANCOUNT>0 ROLLBACK                                  
	RAISERROR(@tips,16,1)                                                                
 END CATCH    
 RETURN                                  
END