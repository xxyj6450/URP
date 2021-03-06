/*              
 * 函数名称：sp_ProcessCustomers          
* 功能描述：处理客户资料录入单        
* 参数:见声名部分              
* 编写：三断笛              
* 时间：2010/06/09              
* 备注：对客户资料SOP_DIM_CUSTOMERS的写入策略时,所有通过客户资料登记的客户,都写入此表.通过开户表的客户写入用户表,并且做好客户表关联.其他业务,用证件,或手机号做为是否为新客户的判断依据
*处理逻辑:
	1.
* 示例：begin tran  exec [sp_ProcessCustomers] 9146,'PS20120929000142',0,'','' rollback      
* --------------------------------------------------------------------              
* 修改： 
* 时间：
* 备注： 
*  select * from customers_h where doccode='CST2010062200001'      
*/        
ALTER PROC [dbo].[sp_ProcessCustomers]        
 @formid INT,        
 @doccode VARCHAR(500),        
 @opionID INT,        
 @refformid INT,        
 @refcode VARCHAR(500)        
AS        
BEGIN
	--单据信息
	DECLARE  @refformid2    INT,  @refcode2  VARCHAR(20), @SIMCode VARCHAR(30),@old int,
	        @SDOrgID VARCHAR(20),@SDOrgName VARCHAR(200), @SDGroup VARCHAR(20),@SDGroupName VARCHAR(50),
	        @DocDate DATETIME,@ReservedDoccode VARCHAR(20),@ComboCode VARCHAR(20),@comboName VARCHAR(100),
	        @PackageID VARCHAR(20),@packageName VARCHAR(200),@docType VARCHAR(20),@Remark VARCHAR(200),
	        @Totalmoney money,@MatCode VARCHAR(20),@EnterName VARCHAR(20),@EnterDate DATETIME,@SeriesCode VARCHAR(30),@ComboFeeType INT,
	        @CustomerCode1 VARCHAR(20),@CustomerName1 VARCHAR(50),@VoucherCode1 VARCHAR(30),@VoucherAddress1 VARCHAR(200),
	        @refrefFormid INT,@refrefCode VARCHAR(20),@Pardon VARCHAR(20)
	    --客户信息
		declare  @CustomerCode VARCHAR(500), @customerName  VARCHAR(500),@cust_IM varchar(200),@cust_Email varchar(200),@cust_Zipcode varchar(20),
		@cust_Website varchar(200),@cust_CompanyAddress varchar(200),@cust_BusinessLicense varchar(50),
		@cust_Industry varchar(200),@cust_CompanyName varchar(200),@cust_SalaryDate varchar(40),
		@cust_WOKU varchar(500),@birthday datetime,@vouchercode varchar(50),@voucherType varchar(20),
		@ValidDate datetime,@sex varchar(10),@post varchar(50),@customerSource varchar(50),@cust_Fax varchar(50),
		@ContactAddress varchar(500),@VoucherAddress varchar(500),@cust_CompnayAddress varchar(500),
		@PhoneNumber VARCHAR(50),@PhoneNumber1 VARCHAR(50),@seriesNumber VARCHAR(20),
		@CustomerId VARCHAR(40),@UserID VARCHAR(40),@isNewCustomer int
	--其他信息
	DECLARE @TranCount int,@Event varchar(500),@tips  VARCHAR(500)
	DECLARE @table TABLE(
		CustomerID VARCHAR(40),
		CustomerCode VARCHAR(20),
		UserId VARCHAR(40),
		PhoneNumber VARCHAR(30),
		PhoneNumber1 VARCHAR(30))
	SET NOCOUNT ON
	--SET XACT_ABORT on
 
	IF @formid IN (9128, 9136)
	BEGIN
	    IF @formid IN (9128)
	    BEGIN
	        --检查单据是中否已经有客户编号,如果存在,则只客户该客户资料,如果不存在,则创建之      
	        SELECT @CustomerCode = customercode, @refformid2 = refformid2, @refcode2 = 
	               refcode2,@Vouchercode=VoucherCode,@customerName=NAME,@PhoneNumber=PhoneNumber,@PhoneNumber1=PhoneNumber1,@seriesNumber=SeriesNumber,
	               @CustomerId=CustomerID
	        FROM   customers_H WITH(NOLOCK)
	        WHERE  DocCode = @doccode

	        IF ISNULL(@CustomerCode,'')=''
	           OR @customercode='客户编号' --如果客户单中没有客户编码,则创建新客户编码
	        BEGIN
	            --生成客户编码 select  dbo.fn_getNewCustomerCode()        
	            SET LOCK_TIMEOUT 3000 --最多等待3秒钟      
	            SELECT @CustomerCode = dbo.fn_getNewCustomerCode()      
	            IF ISNULL(@CustomerCode,'')=''
	               OR @@error<>0
	            BEGIN
	                RAISERROR('生成客户编码失败,请重试!',16,1) 
	                RETURN
	            END 
	            
	            --修改事务隔离级别,锁住这条记录        
	            SET TRANSACTION ISOLATION LEVEL READ COMMITTED 
	            BEGIN TRAN --开启事务，防止脏读与脏写   select * from Customers where vouchercode=''      
	            --将数据插入客户表
	            INSERT INTO Customers( customercode, NAME, sex, Vouchertype, 
	                   vouchercode, validdate, phonenumber, phonenumber1, fax, 
	                   industry, company, department, post, zipcode, birthday, 
	                   lunardate, voucheraddress, curaddress, email, grade, 
	                   developstaffid, developstaffname, developsdorgid, 
	                   developsdorgname, entername, enterdate, remark, photo, QQ, 
	                   CompanyLicense, CompanyAddress, [URL],CustomerSource,CustomerType)
	            SELECT @CustomerCode, NAME, sex, Vouchertype, vouchercode, 
	                   validdate, phonenumber, phonenumber1, fax, industry, 
	                   company, department, post, zipcode, birthday, lunardate, 
	                   voucheraddress, curaddress, email, grade, developstaffid, 
	                   developstaffname, developsdorgid, developsdorgname, 
	                   entername, enterdate, remark, photo, qq, ch.CompanyLicense, 
	                   ch.CompanyAddress, ch.[URL],ch.CustomerSource,customertype
	            FROM   Customers_H ch   WITH(NOLOCK)
	            WHERE  doccode = @doccode
	            --将数据插入全局客户表
	            --先查找是否有从其他渠道登记过客户资料,匹配条件是名字与号码必须都能匹配.
        		IF ISNULL(@CustomerId,'')='' 
				SELECT @CustomerId=dbo.fn_MatchCustomer(@CustomerCode,@Vouchercode,@customerName,@seriesNumber,@PhoneNumber,@PhoneNumber1)
	            IF @CustomerId IS NULL
					begin
						SELECT @CustomerId=NEWID()
						INSERT INTO SOP_dim_Customers(customerID,strCustomerCode, strCustomerName, 
							   strCustomerType, strGrade, strQQ, strEMail, 
							   strZIPCODE, strPost, strDepartment, strURL, 
							   strCompanyAddress, strCompanyLicense, strCompany, 
							   strIndustry, strFax, strPhoneNumber1, strPhoneNumber, 
							   strcurAddress, strVoucherAddress, strLunarDateString, 
							   dtmLunarDate, strBirthdayString, dtmBirthDay, 
							   dtmValidDate, strVoucherCode, strVoucherType, strSex, 
							   strRemark, dtmIndate, intOrderCount, 
							   IMPORTDATE, dtmModifyDate, strModifyName, dtmEnterDate, 
							   strEnterName, strDevelopSdorgID, strDevelopStaffID, 
							   dtmdocDate, strDoccode, strGrade2, intCustomerSource)
						OUTPUT @customerid,INSERTED.strcustomercode,NULL,INSERTED.strphonenumber,inserted.strphonenumber1 INTO @table
						SELECT @CustomerId, @CustomerCode,ch.Name,ch.customertype,ch.Grade,ch.QQ,ch.EMail,
								ch.ZipCode,ch.Post,ch.Department,ch.[URL],ch.CompanyAddress,
								ch.CompanyLicense,ch.Company,ch.Industry,ch.Fax,ch.PhoneNumber1,ch.PhoneNumber,
								ch.curAddress,ch.VoucherAddress,ch.LunarDateString,ch.LunarDate,
								ch.BirthDaystring,ch.BirthDay,ch.ValidDate,ch.VoucherCode,ch.VoucherType,ch.Sex,
								ch.Remark,GETDATE(),1,GETDATE(),ch.ModifyDate,ch.ModifyName,ch.EnterDate,ch.EnterName,
								ch.DevelopSdorgID,ch.DevelopStaffID,ch.DocDate,ch.refcode,NULL,ch.CustomerSource
						FROM Customers_H ch  WITH(NOLOCK)
						WHERE ch.DocCode=@doccode
						SELECT @isNewCustomer=1
					END
 
				--将客户编码回填至客户资料表 只有在新增客户资料时才有必要填写 其余情况无需填写
				UPDATE b
				SET customercode = @CustomerCode,CustomerID=@CustomerId
				FROM   customers_h b  WITH(NOLOCK)
				WHERE  doccode = @doccode
				--如果已经找到了匹配的客户编号,则更新客户信息
				IF ISNULL(@isNewCustomer,0)=0
					 begin
						UPDATE SOP_dim_Customers
							SET    strCustomerName = a.NAME,
								   strsex = a.Sex,
								   dtmValidDate = a.ValidDate,
								   strPhoneNumber = a.PhoneNumber,
								   strphonenumber1 = a.phonenumber1,
								   strfax = a.Fax,
								   strIndustry = a.Industry,
								   strcompany = a.Company,
								   strDepartment = a.Department,
								   strpost = a.Post,
								   strzipcode = a.ZipCode,
								   dtmBirthDay = a.BirthDay,
								   dtmLunarDate = a.LunarDate,
								   strVoucherAddress = a.VoucherAddress,
								   strcuraddress=a.curAddress,
								   stremail = a.EMail,
								   strGrade = a.grade,
								   strRemark = a.Remark,
								   strQQ = a.QQ,
								   strCompanyLicense = a.CompanyLicense,
								   strCompanyAddress = a.CompanyAddress,
								   strURL = a.[URL],
								   SOP_dim_Customers.CustomerID = a.CustomerID
							OUTPUT @customerid,INSERTED.strcustomercode,NULL,INSERTED.strphonenumber,inserted.strphonenumber1 INTO @table
							FROM   customers_H a WITH(NOLOCK)
							WHERE  a.DocCode = @doccode
								   AND SOP_dim_Customers.strcustomercode = a.customercode
					 END
				--更新客户资料表的客户编码
				UPDATE b
					SET customerid=@CustomerId
				FROM customers b  WITH(NOLOCK)
				WHERE b.customercode=@CustomerCode
				
	            IF @@ERROR<>0
	            BEGIN
	                SELECT @tips = '新增客户资料失败!,'+ERROR_MESSAGE() 
	                ROLLBACK 
	                RAISERROR(@tips,16,1) 
	                RETURN
	            END
	            ELSE
	            BEGIN
	                COMMIT TRAN --提交
	            END 
	        END
	        ELSE
	            ---如果已经生成客户编码,则更新之       COMMIT
	        BEGIN
	            -- BEGIN TRAN
	            IF ISNULL(@CustomerId,'')='' 
					SELECT @CustomerId=dbo.fn_MatchCustomer(@CustomerCode,@Vouchercode,@customerName,@seriesNumber,@PhoneNumber,@PhoneNumber1)
	            UPDATE Customers_H
					SET customerid=@CustomerId
	            WHERE DocCode=@doccode
				AND isnull(@CustomerId,'')=''
	            UPDATE Customers
	            SET    NAME = a.NAME,
	                   sex = a.Sex,
	                   ValidDate = a.ValidDate,
	                   PhoneNumber = a.PhoneNumber,
	                   phonenumber1 = a.phonenumber1,
	                   fax = a.Fax,
	                   Industry = a.Industry,
	                   company = a.Company,
	                   Department = a.Department,
	                   post = a.Post,
	                   zipcode=a.ZipCode,
	                   BirthDay = a.BirthDay,
	                   LunarDate = a.LunarDate,
	                   VoucherAddress = a.VoucherAddress,
	                   curAddress = a.curAddress,
	                   email = a.EMail,
	                   Grade = a.grade,
	                   Remark = a.Remark,
	                   Photo = a.Photo,
	                   QQ = a.QQ,
	                   CompanyLicense = a.CompanyLicense,
	                   CompanyAddress = a.CompanyAddress,
	                   URL = a.[URL],
						Customers.customerid=a.CustomerID 
	            FROM   customers_H a with(nolock)
	            WHERE  a.DocCode = @doccode
	                   AND Customers.customercode = a.customercode
	         ------------------------------------------------------将数据写入全局客户资料表-----------------------------------
			 --更新客户信息
	            UPDATE SOP_dim_Customers
	            SET    strCustomerName = a.NAME,
	                   strsex = a.Sex,
	                   dtmValidDate = a.ValidDate,
	                   strPhoneNumber = a.PhoneNumber,
	                   strphonenumber1 = a.phonenumber1,
	                   strfax = a.Fax,
	                   strIndustry = a.Industry,
	                   strcompany = a.Company,
	                   strDepartment = a.Department,
	                   strpost = a.Post,
	                   strzipcode = a.ZipCode,
	                   dtmBirthDay = a.BirthDay,
	                   dtmLunarDate = a.LunarDate,
	                   strVoucherAddress = a.VoucherAddress,
	                   stremail = a.EMail,
	                   strGrade = a.grade,
	                   strRemark = a.Remark,
	                   strQQ = a.QQ,
	                   strCompanyLicense = a.CompanyLicense,
	                   strCompanyAddress = a.CompanyAddress,
	                   strURL = a.[URL]
				OUTPUT @customerid,INSERTED.strcustomercode,NULL,INSERTED.strphonenumber,inserted.strphonenumber1 INTO @table
	            FROM   customers_H a with(nolock)
	            WHERE  a.DocCode = @doccode
	                   AND SOP_dim_Customers.strcustomercode = a.customercode
	        END
	       
------------------------------------------------------------------------------------------------------------------------------
	
	        --将客户资料回填至业务单        
	        IF @refformid2 IN (9102, 9146,9237) --回填放号业务单
	        BEGIN
	            UPDATE Unicom_Orders
	            SET    cltCode = b.customercode,
	                   cltname = b.name,
	                   drivername = b.VoucherAddress,
	                   contactaddress=b.curAddress,
	                   UserTxt2 = b.vouchercode,
	                   blacklist = 0,
	                   consumptioncount = 0,
	                   CustomerID = b.customerid,
	                   validdate=b.validdate,
	                   birthday=b.birthday,
	                   vouchertype=b.vouchertype,
	                   zipcode=b.zipcode,
	                   phonenumber=b.phonenumber,
	                   phonenumber1=b.phonenumber1,
	                   sex=b.sex
	            FROM   Customers_H b with(nolock)
	            WHERE  b.CustomerCode = @CustomerCode
	                   AND b.DocCode = @doccode
	                   AND b.refcode2 = Unicom_Orders.DocCode
	                   AND Unicom_Orders.DocStatus = 0
	                   AND  isnull(Unicom_Orders.checkState,'退回')='退回'  
	        END
	        --过户 客户资料变更
	        IF @refformid2 IN (9153,9159)
				BEGIN
					UPDATE BusinessAcceptance_H
					SET    customercode1 = b.customercode,
						   customername1 = b.name,
						   voucheraddress = b.voucheraddress,
						   vouchercode1 = b.vouchercode,
						   customerid=b.customerid
					FROM   Customers_H b with(nolock)
					WHERE  BusinessAcceptance_H.DocCode = b.refcode
						   AND b.DocCode = @doccode
				END
			--银行托收 同时补充其他功能号 2011-09-20 三断笛
			IF @refformid2 IN(9180,9158,9160,9165,9167,9267)
				BEGIN
					UPDATE BusinessAcceptance_H
					SET    customercode = b.customercode,
						   customername = b.name,
						   voucheraddress = b.voucheraddress,
						   vouchercode = b.vouchercode,
						   customerid=b.customerid
					FROM   Customers_H b with(nolock)
					WHERE  BusinessAcceptance_H.DocCode = b.refcode
						   AND b.DocCode = @doccode
				END
	    END

	    IF @formid IN (9136) --客户资料修改
	    BEGIN
	        UPDATE Customers
	        SET    sex = a.sex,
	               Vouchertype = a.Vouchertype,
	               phonenumber = a.phonenumber,
	               phonenumber1 = a.phonenumber1,
	               fax = a.fax,
	               industry = a.industry,
	               company = a.company,
	               department = a.department,
	               post = a.post,
	               zipcode = a.zipcode,
	               birthday = a.birthday,
	               lunardate = a.lunardate,
	               voucheraddress = a.voucheraddress,
	               curaddress = a.curaddress,
	               email = a.email,
	               grade = a.grade,
	               remark = a.remark,
	               Photo = a.Photo
	        FROM   customers_H a with(nolock)
	        WHERE  a.DocCode = @doccode
	               AND Customers.CustomerCode = a.CustomerCode
	    END
	    
	END      
-------------------------------------------------------------客户资料修改完毕---------------------------------------------------------------
	IF @formid IN (9102, 9146,9237) --放号时修改客户消费记录
	begin

		select @Event='客户资料更新'
		--取单据基本信息
	    SELECT @old=ISNULL(uo.old,0),
	    @seriesNumber=uo.SeriesNumber,@SDOrgID=uo.sdorgid,@SDGroup=uo.sdgroup,
	    @SDOrgName=uo.sdorgname,@SDGroupName=uo.sdgroupname,@docType=uo.DocType,
	    @PackageID=uo.PackageID,@packageName=uo.PackageName,@Totalmoney=uo.userdigit4,
	    @ComboCode=uo.ComboCode,@comboName=uo.ComboName,@DocDate=uo.DocDate,
	    @ComboFeeType=case uo.comboFEEType WHEN '全月套餐' then 0 when '半月套餐' then 1 WHEN '套外资费' then 2 else 3 end,
	    @Totalmoney=ISNULL(uo.userdigit4,0),@SIMCode=uo.ICCID,@SeriesCode=uo.SeriesCode,@MatCode=uo.MatCode,@Remark=uo.HDText,
	    --客户信息
	    @CustomerId=uo.CustomerID,@CustomerCode = cltcode, @customerName = cltname,@Vouchercode=uo.usertxt2,
	    @voucherType=uo.VoucherType,@birthday=uo.BirthDay,@ValidDate=uo.validdate,@PhoneNumber=uo.PhoneNumber,@PhoneNumber1=PhoneNumber1,
	    @sex=uo.Sex,@post=uo.cust_Post,@cust_Fax=uo.Fax,@ContactAddress=uo.ContactAddress,@VoucherAddress=uo.drivername,
	    @ReservedDoccode=uo.ReservedDoccode,@cust_Zipcode=uo.ZipCode,@cust_IM=uo.cust_IM,@cust_Email=uo.Email,
	    ---公司信息
	    @cust_BusinessLicense=uo.cust_BusinessLicense,@cust_Industry=uo.cust_Industry,@cust_CompanyName=uo.cust_CompanyName,
	    @cust_CompanyAddress=uo.cust_CompnayAddress,@cust_SalaryDate=uo.cust_SalaryDate,@cust_WOKU=uo.cust_WOKU,
	    @birthday=uo.BirthDay
	    FROM   Unicom_Orders uo with(nolock)
	    WHERE  uo.DocCode = @doccode
	    select @Event='更新消费次数'
		IF ISNULL(@CustomerId,'')=''
			begin
				select @isNewCustomer=1
				SELECT @CustomerId=dbo.fn_MatchCustomer('',@Vouchercode,@customerName,@seriesNumber,@PhoneNumber,@PhoneNumber1)
				print '匹配的客户资料' + isnull(@CustomerId,'')
	            IF isnull(@CustomerId,'')=''
					begin
						select @isNewCustomer=2
						SELECT @CustomerId=NEWID()
						INSERT INTO SOP_dim_Customers(customerID,strCustomerCode, strCustomerName, 
							   strCustomerType, strGrade, strQQ, strEMail, 
							   strZIPCODE, strPost, strDepartment, strURL, 
							   strCompanyAddress, strCompanyLicense, strCompany, 
							   strIndustry, strFax, strPhoneNumber1, strPhoneNumber, 
							   strcurAddress, strVoucherAddress, strLunarDateString, 
							   dtmLunarDate, strBirthdayString, dtmBirthDay, 
							   dtmValidDate, strVoucherCode, strVoucherType, strSex, 
							   strRemark, dtmIndate, intOrderCount, 
							   IMPORTDATE, dtmModifyDate, strModifyName, dtmEnterDate, 
							   strEnterName, strDevelopSdorgID, strDevelopStaffID, 
							   dtmdocDate, strDoccode, strGrade2,strCustomerSource,strWOKU,strReservedDoccode,intConsumptionCount,dblTotalConsumption)
							    
						OUTPUT @customerid,INSERTED.strcustomercode,NULL,INSERTED.strphonenumber,inserted.strphonenumber1 INTO @table
						SELECT @CustomerId, @CustomerCode,@customerName,NULL as strCustomerType,NULL as Grade,@cust_IM,@cust_Email,
								@cust_ZipCode,@post as strPost,NULL as strDepartment,@cust_Website,@cust_CompnayAddress,
								@cust_BusinessLicense,@cust_CompanyName,@cust_Industry,@cust_Fax,isnull(@PhoneNumber,@PhoneNumber1),@seriesNumber,
								@ContactAddress,@VoucherAddress,NULL as strLunarDateString,NULL as dtmLunarDate,
								NULL as strBirthdayString,@BirthDay,@ValidDate,@Vouchercode,@VoucherType,@Sex,
								@Remark,GETDATE(),1,GETDATE(),getdate(),getdate(),getdate(),@SDGroup,
								@sdgroup,@sdgroupname,@DocDate,@DocCode,NULL as strGrade2,@customerSource, @cust_WOKU,@ReservedDoccode,
								1,isnull(@Totalmoney,0)
					END
			end
			print @CustomerId
			--如果已经找到了匹配的客户编号,则更新客户信息
			IF ISNULL(@isNewCustomer,0)=0
				 begin
					UPDATE SOP_dim_Customers
						SET    strCustomerName =@customerName,
							   strsex = @Sex,
							   dtmValidDate = @ValidDate,
							   strPhoneNumber = coalesce(@seriesNumber ,@PhoneNumber,strPhoneNumber),
							   strphonenumber1=coalesce(@PhoneNumber, @phonenumber1,strPhoneNumber,strphonenumber1),
							   strfax = @cust_Fax,
							   strIndustry = @cust_Industry,
							   strcompany = @cust_CompanyName,
							   strpost = @post,
							   strzipcode =@cust_Zipcode,
							   dtmBirthDay = @BirthDay,
							   strVoucherAddress = @VoucherAddress,
							   strcuraddress= @ContactAddress,
							   stremail =@cust_Email,
							   strRemark =@remark,
							   strQQ = @cust_IM,
							   strCompanyLicense = @cust_BusinessLicense,
							   strCompanyAddress = @cust_CompanyAddress,
							   strURL = @cust_Website,
							   intConsumptionCount = ISNULL(intConsumptionCount,0)+1,
								dblTotalConsumption =ISNULL(@Totalmoney,0)+ISNULL(dblTotalConsumption,0)
						OUTPUT @customerid,INSERTED.strcustomercode,NULL,INSERTED.strphonenumber,inserted.strphonenumber1 INTO @table
						Where SOP_dim_Customers.CustomerID = @CustomerId
				 END
	    SELECT @TranCount=@@TRANCOUNT
	    SET TRANSACTION ISOLATION LEVEL READ COMMITTED
		BEGIN TRY
			select @Event='记录消费信息'
			--插入用户表
			IF exists(select 1 from policy_h ph,T_PolicyGroup pg where ph.PolicygroupID=pg.PolicyGroupID and ph.DocCode=@PackageID and pg.OpenAccount=1)
				begin
					select @Event='记录用户信息'
					SELECT @UserID=NEWID()
					
					INSERT INTO SOP_dim_Profile( UserID, CustomerID, CustomerCode, strSeriesNumber, strSeriesCode,
						   strMatcode,strSIMCode, STATUS, strName, strGrade, strDoccode,intComboCode,intComboFeeType, 
						   dtmdocDate, strDevelopStaffID, strDevelopSdorgID,
						   strEnterName, dtmEnterDate, strModifyName, dtmModifyDate, 
						   ReservedDoccode,PackageID)
					OUTPUT INSERTED.customerid,INSERTED.customercode,INSERTED.userid,NULL,NULL INTO @table
					SELECT @UserID,@customerid,@CustomerCode,@seriesNumber,@SeriesCode,
					@matcode,@SIMCode,1,@CustomerName,NULL as strGrade,
					@doccode,@ComboCode ,@ComboFeeType ,@docDate,@SDGroup,@SDOrgID,@EnterName,@EnterDate,GETDATE(),GETDATE(),
					@reServedDoccode,@PackageID
					
				end
			select @Event='用户信息回填业务单据'
			--当是新登记客户,或原单据中无客户信息时,才进行更新.
			if @isNewCustomer>0
				BEGIN
					update Unicom_Orders
						set CustomerID = @CustomerId,
						UserID = @UserID
					where DocCode=@doccode
				END
 
		END TRY
		BEGIN CATCH
			SELECT @tips=dbo.crlf()+@Event +'异常.'+dbo.crlf()+
			error_message()+dbo.crlf()+
			'错误发生于'+error_procedure()+'第'+convert(varchar(8),ERROR_LINE())+'行.'+dbo.crlf()+
			'请联系系统管理员.'
			RAISERROR(@tips,16,1)
 
			return
		END catch
	END
	--业务不同,初始化客户编码
	SELECT @CustomerId=null
	--零售销售单
	IF @formid IN(2419,2420)
		BEGIN
			SELECT @refformid=isnull(refformid,0),@CustomerCode=isnull(cltcode,'888888'),@customerName=ISNULL(sph.cltName,'零售客户'),
			@seriesnumber=usertxt2,@docDate=docdate,@SDOrgID=sph.sdorgid,@SDOrgName=sph.sdorgname,@SDGroup=sph.sdgroup,@SDGroupName=sph.sdgroupname,
			@totalmoney=isnull(userdigit4,0),@refrefFormid=refrefformid,@refrefCode=sph.refrefcode,@Pardon=sph.prdno,@CustomerId=sph.CustomerID
			FROM sPickorderHD sph with(nolock) WHERE sph.DocCode=@doccode
			--如果有客户编码,而且不为散客,则退出
			IF isnull(@CustomerId,dbo.normalcustomerID())<>dbo.normalcustomerID() return
			--初始化新客户标志
			SELECT @isNewCustomer=0
			--如果是非零售单,则直接退回,因为已经登记过  
			IF @refformid<>0 RETURN
			--判断号码是否合法,不合法则跳过 在单据保存时会执行此项检查,不允许出现不合格的电话号码
			IF dbo.isValidSeriesNumber(@seriesNumber,0)=0 RETURN
			--判断号码是否已存在于客户表 对于零售客户,如果是888888零售客户,则只要号码不在客户表中就算新客户,如果不是888888客户,则都不算新客户
			--如果号码相同,还要求姓名相同,如果姓名不相同,则要求姓氏相同,并且登记时间小于1年,大于1年则当新客户处理
			SELECT @CustomerId = NULL
			--先用客户编码匹配一次
			SELECT @CustomerId=customerid FROM SOP_dim_Customers sdc with(nolock) WHERE sdc.strCustomerCode=@CustomerCode
			IF @CustomerId IS NULL	
				begin
					SELECT top 1 @CustomerId=s.customerid FROM SOP_dim_Customers s with(nolock)						--取最近一个登记时间的客户,
					WHERE s.strPhoneNumber=@seriesNumber
					AND (s.strCustomerName=@customerName OR (
																(@customerName like left(s.strcustomername,1)+'%[生|先生|小姐|女士]' 
																or s.strCustomerName LIKE LEFT(@customerName,1)+'%[生|先生|小姐|女士]')
															AND DATEDIFF(YEAR,s.IMPORTDATE,GETDATE())<=1)
					)
					ORDER BY s.strCustomerCode DESC, s.dtmIndate DESC
				end
			IF @CustomerId IS NULL																--如果没有此客户的话,则插入之
				BEGIN
					SET @CustomerId=NEWID()
					INSERT INTO SOP_dim_Customers(CustomerID,strCustomerCode, strCustomerName, 
							   strCustomerType, strGrade, dtmIndate, intOrderCount,intConsumptionCount,strPhoneNumber,
							   strDevelopSdorgID, strDevelopStaffID,dtmdocDate, strDoccode)
					SELECT @CustomerId,@CustomerCode,@customerName,'零售客户','普通客户',getdate(),1,@totalmoney,@seriesNumber,@sdorgid,@sdgroup,@docdate,@doccode
					SELECT @isNewCustomer=1
				END
			--回填业务单据表
			UPDATE sPickorderHD SET CustomerID = @CustomerId WHERE DocCode=@doccode
			--更新客户消费记录
			IF @isNewCustomer=0
				begin
					UPDATE SOP_dim_Customers
						SET intOrderCount = ISNULL(intOrderCount,0)+CASE @formid WHEN 2419 THEN 1 WHEN 2420 THEN -1 end,
						intConsumptionCount = ISNULL(intConsumptionCount,0)+case @formid  when 2419 then @Totalmoney WHEN 2420 THEN -@Totalmoney END
					WHERE CustomerID=@CustomerId
				END
			--如果是运营商业务返销,标志返销,分两次判断,防止过多的判断浪费资源
			IF @formid=2420 AND @Pardon='运营商返销' and @refrefFormid  IN(9102,9146)
				BEGIN
					if EXISTS(SELECT 1 FROM Unicom_Orders uo with(nolock) WHERE uo.DocCode=@refrefCode AND isnull(old,0)=0)
					BEGIN
						UPDATE SOP_dim_Profile
							SET [Status] = -1
						WHERE CustomerID=@CustomerId
						AND strSeriesNumber=@seriesNumber
					END
				end
		end
	------------------------------------------------------返销业务-----------------------------------------
	if @formid in(9244)
		begin
			--取出用户信息
			select @seriesNumber=uo.SeriesNumber,@CustomerId=uo.CustomerID,@UserID=uo.UserID,@totalmoney=isnull(userdigit4,0),
			@CustomerCode=uo.cltCode,@DocDate=uo.DocDate,@docType=uo.DocType,@customerName=uo.cltName,@SDOrgID=uo.sdorgid,
			@SDOrgName=uo.sdorgname,@SDGroup=uo.sdgroup,@SDGroupName=uo.sdgroupname,@refcode=uo.refcode
			from Unicom_Orders uo with(nolock) 
			where uo.DocCode=@doccode
			--用户信息标上返销
			update SOP_dim_Profile
				set [Status] = -1
			where strSeriesNumber=@seriesNumber
			and CustomerID=@CustomerId
			--更新客户消费金额
			update a
				set intOrderCount = isnull(intOrderCount,0)+1,			--消费次数加1
				intConsumptionCount=isnull(intConsumptionCount,0)-isnull(@Totalmoney,0)					--消费金额减掉
			from SOP_dim_Customers a with(nolock)
			where CustomerID=@CustomerId
			--更新原单据
			update Unicom_Orders
				set bitReturnd = 1
			where DocCode=@refcode
			--更新原开户明细
			update NumberAllocation_Log
				set bitReturnd = 1
			where Doccode=@refcode
		END
	------------------------------------------------------其他业务受理-------------------------------------
	IF @formid IN(9153)
		BEGIN
			SELECT @CustomerCode=  bah.CustomerCode   ,
			@customerName= bah.CustomerName  ,
			@VoucherCode=  bah.vouchercode ,
			@VoucherAddress= bah.VoucherAddress ,
			@PhoneNumber=bah.SeriesNumber,
			@PhoneNumber1=bah.PhoneNumber,
			@cust_Zipcode=bah.ZipCode,
			@sex=bah.Sex,
			@birthday=bah.Birthday,
			@seriesNumber=bah.SeriesNumber,@comboName=bah.ComboName,
			@SDOrgID=bah.SdorgID,@SDGroup=bah.Sdgroup,@CustomerId=bah.CustomerID,
			@docType=bah.DocType,@EnterDate=bah.EnterDate,@EnterName=bah.EnterName,
			@Totalmoney=isnull(bah.TotalMoney,0)
			FROM BusinessAcceptance_H bah with(nolock) WHERE bah.docCode=@doccode
			--假定不是新客户
			SELECT @isNewCustomer=0
			--如果证件不为空,则可以考虑登记,用证件匹配
			IF @CustomerId IS NULL AND  @Vouchercode IS NOT NULL 
				BEGIN
					SELECT @CustomerId = sdc.CustomerID,@CustomerCode=strcustomercode
					FROM SOP_dim_Customers   sdc with(nolock)
					WHERE  sdc.strVoucherCode = @Vouchercode
				END
			--如果还是匹配不到,则认为是新客户,新建客户资料
			IF @CustomerId IS NULL	
				BEGIN
					SELECT @CustomerId = NEWID()
					INSERT INTO SOP_dim_Customers( customerID, 
						   strCustomerCode, strCustomerName, strCustomerType, 
						   strGrade, strPhoneNumber1, strPhoneNumber, 
						   strcurAddress, strVoucherAddress, strVoucherCode,strSex,dtmBirthDay,strZIPCODE,
						   strVoucherType, dtmIndate, IMPORTDATE, 
						   dtmEnterDate, strEnterName, strDevelopSdorgID, 
						   strDevelopStaffID, dtmdocDate, strDoccode,intConsumptionCount,intOrderCount)
					SELECT @CustomerId, NULL, @customerName, NULL, 
						   '普通客户', @PhoneNumber, @PhoneNumber1, @VoucherAddress, 
						   @VoucherAddress, @Vouchercode, @sex,@birthday,@cust_Zipcode,'身份证', @EnterDate, 
						   GETDATE(), @EnterDate, @EnterName, @SDOrgID, @SDGroup, @DocDate, @doccode,@Totalmoney,1
					SELECT @isNewCustomer=1
				END
			--更新客户资料表
			IF @isNewCustomer=0
				begin
					UPDATE SOP_dim_Customers
						SET intOrderCount = ISNULL(intOrderCount,0)+1,
						intConsumptionCount = ISNULL(intConsumptionCount,0)+@Totalmoney			
					WHERE CustomerID=@CustomerId
					
				END
			--回填业务单据表
			if @isNewCustomer=1
				BEGIN
					UPDATE BusinessAcceptance_H SET CustomerID = @CustomerId,CustomerCode = @CustomerCode WHERE docCode=@doccode
				END
			--如果是过户,更新用户与客户的绑定
			UPDATE SOP_dim_Profile
				SET CustomerID = @CustomerId
			WHERE strSeriesNumber=@seriesNumber
			AND [Status]=1
 
		END
END