/*                                    
* 函数名称：sp_CreateSeriesDoc                                 
* 功能描述：生成和更新客户新入网单,并返回单号                                    
* 参数:见声名部分                                    
* 编写：三断笛                                    
* 时间：2010/06/17                                  
* 备注： 此过程用于生成和更新客户新入网单,如果不存在相应的新入网单,则创建新单,如果存在,则更新.但是本过程只更新与号码相关的部分数据.                              
* 示例：Begin tran
exec sp_createseriesdoc '01.01.01.01.01',9146,'18682372645','1.1.755.08.01','广东省深圳市横岗志健时代广场综合店',
		             '300169','林少佩',0,'','客户新入网',''
		             
		             rollback
* --------------------------------------------------------------------                                    
* 修改：     不再用dbo.fn_getNetType来判断网段.池外号码直接标记NULL,在提交审核时再根据套餐进行处理.                        
* 时间：     2012-11-02                                
* 备注：                                 
*                   
*/                     
ALTER  PROC [dbo].[sp_CreateSeriesDoc]
	@busiType VARCHAR(50),
	@packageID VARCHAR(50),                
	@formid INT,                  
	@seriesnumber VARCHAR(20),                    
	@sdorgid VARCHAR(20),                    
	@sdorgname VARCHAR(150),                    
	@sdgroup VARCHAR(20),                    
	@sdgroupname VARCHAR(20),                    
	@refformid INT = 0,                    
	@refcode VARCHAR(20) = '',                    
	@doctype VARCHAR(20) = '客户新入网',   
	@ReservationDoccode VARCHAR(20),                   
	@doccode VARCHAR(20) = '' OUTPUT                 
AS                    
BEGIN  
	SET NOCOUNT ON --如果您看到了此句,那建议您在所有的存储过程中都使用该选项,将有效地提高程序的性能.   
	SET XACT_ABORT ON  
    
	DECLARE @PreAllocation BIT, @propertyValue VARCHAR(100), @OpenAccount     BIT 
	DECLARE @olddoccode VARCHAR(20), @matgroup1 VARCHAR(40), @matcode         VARCHAR(50), 
	@old INT, @Tel1 VARCHAR(50), @tel2 VARCHAR(50),@reservedCardmoney money
	 IF ISNULL(@busiType,'')=''
		BEGIN
			RAISERROR('业务类型信息缺失,无法继续操作,请联系系统管理员.',16,1)
			return
		End

	 --读取业务类型信息
	 SELECT @old=ISNULL(pg.oldCustomerBusi,0),@OpenAccount=ISNULL(pg.OpenAccount,0) FROM T_PolicyGroup pg WITH(NOLOCK) WHERE pg.PolicyGroupID=@busiType
	 IF @@ROWCOUNT=0
		BEGIN
			RAISERROR('业务类型信息无效,请联系系统管理员.',16,1)
			return
		END
	--如果@formid与@refformid相等,则说明是重新选号,此时不需要创建单据,只需要更新@refcode单据中的号码信息                  
	 IF @formid = @refformid  AND @refcode =@doccode 
		 BEGIN  
			 SELECT @olddoccode = @refcode  
		 END  
	IF @formid = 9102 OR (@formid=9237 AND ISNULL(@packageID,'')='')  SELECT @doctype = '客户新入网'  

	IF @formid = 9224    SELECT @doctype = '3G融合入网'  

	IF @formid = 9146   OR (@formid=9237 AND ISNULL(@packageID,'')!='')   SELECT @doctype = '套包销售' 
    if @ReservationDoccode<>''
		BEGIN
			select @reservedCardmoney=pc.cardmoney
			  from PotentialCustomer pc where pc.ReservationCode=@ReservationDoccode
		END
 --如果没有找到当天未提交审核的单据的话 再创建新单据               
	IF ISNULL(@olddoccode,'') = ''  
		BEGIN
			--读取员工信息
			SELECT @Tel1=o.Tel,@tel2=o.Fax FROM oSDGroup o WITH(NOLOCK) WHERE o.SDGroup=@sdgroup
			 --创建新单号  select convert(varchar(20),GETDATE(),120  )                  
			 EXEC sp_newdoccode @formid,'',@oldDoccode OUTPUT    
			 IF EXISTS(SELECT 1  
					   FROM   SeriesPool sp  WITH(NOLOCK)
					   WHERE  sp.SeriesNumber = @seriesnumber  
				)  
				AND ISNULL(@OpenAccount,0) = 1 --只有当号码池存在该号码,并且是开户时,才从号码表引入信息
			 BEGIN  
				 INSERT INTO Unicom_Orders( doccode, docdate, formid, refformid,   
						refcode, docstatus, doctype, SeriesNumber, sdorgid, sdorgname,
						pick_ref, preallocation, mincombofee, combocode, comboname,   
						rewards, validdate, sdgroup, sdgroupname, sdgroup1,   
						sdgroupname1, indoccode, intype, ServiceFEE, PhoneRate, Price,   
						TotalMoney1, OtherFEE, ComboFEE, CardFEE,CardFee1, CardNumber,   
						cardmatcode, CardMatName, nettype, EnterName, EnterDate,   
						inuse, ModifyName, ModifyDate,matstatus, comboFEEType,   
						old, done, ReservedDoccode,userdigit1,userdigit4,Seriescode,
						Companyid,stcode,stname,areaid,dptType,ContactAddress,usertxt5,usertxt6,busiType,cardmoney
				 )  
				 SELECT @oldDoccode,CONVERT(VARCHAR(10),GETDATE(),120),@formid,@refformid,@refcode,0,@doctype,@seriesnumber,@sdorgid,os.SDOrgName,
						@sdgroup, preallocation,mincombofee,combocode,comboname,rewards,  
						validdate,@sdgroup,@sdgroupname,@sdgroup,@sdgroupname,  
						indoccode,intype,b.servicefee,b.PhoneRate,b.Price,b.TotalMoney,  
						OtherFEE,ComboFEE,b.CardFEE,b.CardFee,b.CardNumber,b.cardmatcode,b.CardMatName,  
						b.nettype,@sdgroupname,CONVERT(VARCHAR(20),GETDATE(),120),inuse,@sdgroupname,  
						CONVERT(VARCHAR(20),GETDATE(),120),'正常',  
						dbo.fn_getComboFeeType(),0,b.oldcode,@ReservationDoccode,b.totalmoney,b.totalmoney,
						CASE WHEN ISNULL(b.preAllocation,0)=1 THEN b.SeriesCode ELSE NULL END,
						os2.PlantID,os2.stCode,os2.name40,os.AreaID,os.dptType,os.[address],@Tel1,@tel2,@busiType,@reservedCardmoney
				 FROM   SeriesPool b WITH(NOLOCK),oSDOrg os WITH(NOLOCK),oStorage os2 WITH(NOLOCK)
				 WHERE  b.SeriesNumber = @SeriesNumber
				 AND os.SDOrgID=@sdorgid
				 AND os2.sdorgid=os.SDOrgID

			 END  
			 ELSE  
			--如果不存在该号码 或是老客户业务时,则不使用号码池中的信息  
			 BEGIN 
				 INSERT INTO Unicom_Orders( doccode, docdate, formid, refformid,   
						refcode, docstatus, doctype, SeriesNumber, sdorgid, sdorgname,   
						pick_ref, preallocation, mincombofee, combocode, comboname,   
						rewards, validdate, sdgroup, sdgroupname, sdgroup1,   
						sdgroupname1, indoccode, intype, ServiceFEE, PhoneRate, Price,   
						TotalMoney1, OtherFEE, ComboFEE, CardFEE, CardNumber,   
						cardmatcode, CardMatName, nettype, EnterName, EnterDate,   
						inuse, ModifyName, ModifyDate, matstatus, comboFEEType,   
						old, done, ReservedDoccode,
						Companyid,stcode,stname,areaid,dptType,ContactAddress,usertxt5,usertxt6,
						busitype,cardmoney)  
				 SELECT @oldDoccode,CONVERT(VARCHAR(10),GETDATE(),120),@formid,@refformid,@refcode,0,@doctype,@seriesnumber,@sdorgid,os.SDOrgName,@sdgroup,  
						0,0,NULL,NULL,0,'2050-12-31',@sdgroup,@sdgroupname,@sdgroup,@sdgroupname,  
						NULL,'池外入库',0,0,200,0,0,0,0,NULL,NULL,NULL,NULL,  
						@sdgroupname,CONVERT(VARCHAR(20),GETDATE(),120),1,@sdgroupname,CONVERT(VARCHAR(20),GETDATE(),120),  
						'正常',dbo.fn_getComboFeeType(),0,NULL,@ReservationDoccode,
						os2.PlantID,os2.stCode,os2.name40,os.AreaID,os.dptType,os.[address],@Tel1,@tel2,
						@busiType,@reservedCardmoney
				 FROM oSDOrg os WITH(NOLOCK),oStorage os2 WITH(NOLOCK)
				 WHERE os.SDOrgID=@sdorgid
				 AND os2.sdorgid=os.SDOrgID
				 If @@ROWCOUNT=0
					BEGIN
						Raiserror('门店信息与仓库信息不匹配,生成业务单据失败,请联系系统管理员.',16,1)
						return
					END
			 END
		END  
 /*ELSE  
	BEGIN  
		 --当号码更换时,需要将号码信息重新写入单据       
		 UPDATE A  
		 SET    SeriesNumber = b.seriesnumber,  
				nettype = b.NetType,  
				ServiceFEE = ISNULL(b.servicefee,0),  
				PhoneRate = ISNULL(b.phonerate,0),  
				--Price =CASE ISNULL(price,0)<isull(b.price,0) THEN   b.price,                    
				OtherFEE = ISNULL(b.otherfee,0),  
				totalmoney1 = ISNULL(b.TotalMoney,0),  
				ComboFEE = ISNULL(b.combofee,0),  
				--combocode=b.ComboCode,  
				--当套餐最低消费不变,且未绑定套餐时,将  
				--comboname=NULL,                  
				preallocation = b.preAllocation,  
				intype = b.inType,  
				mincombofee = b.MinComboFEE,  
				inuse = b.inuse  
		 FROM   seriespool b WITH(NOLOCK),Unicom_Orders  a WITH(NOLOCK)
		 WHERE  b.SeriesNumber <> @seriesnumber  
				AND a.DocCode = @olddoccode
	END*/                    
	SELECT @doccode = @oldDoccode   
	RETURN
END
