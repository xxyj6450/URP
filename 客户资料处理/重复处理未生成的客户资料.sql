begin tran
declare  @formid INT,        
 @doccode VARCHAR(500),        
 @opionID INT,        
 @refformid INT,        
 @refcode VARCHAR(500)  
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
		
 declare abc CURSOR FAST_FORWARD FOR 
select  ISNULL(uo.old,0),
	     uo.SeriesNumber, uo.sdorgid, uo.sdgroup,
	     uo.sdorgname, uo.sdgroupname, uo.DocType,
	   uo.PackageID, uo.PackageName, uo.userdigit4,
	    uo.ComboCode, uo.ComboName, uo.DocDate,
	    case uo.comboFEEType WHEN '全月套餐' then 0 when '半月套餐' then 1 WHEN '套外资费' then 2 else 3 end,
	     ISNULL(uo.userdigit4,0), uo.ICCID, uo.SeriesCode, uo.MatCode, uo.HDText,
	    --客户信息
	     cltname, uo.usertxt2, uo.VoucherType, uo.BirthDay, uo.validdate, uo.PhoneNumber,@PhoneNumber1=PhoneNumber1,
	     uo.Sex, uo.cust_Post, uo.Fax, uo.ContactAddress, uo.drivername,uo.ReservedDoccode, uo.ZipCode, uo.cust_IM, uo.Email,
	    ---公司信息
	    uo.cust_BusinessLicense,uo.cust_Industry,uo.cust_CompanyName,
	    uo.cust_CompnayAddress,uo.cust_SalaryDate,uo.cust_WOKU,  uo.BirthDay
  from Unicom_Orders uo where uo.CustomerID='EEE2353D-FAA0-4A49-BC15-A22FD982108C'
order by uo.DocDate 
 		select @Event='客户资料更新'
 		open abc
 		fetch next FROM abc into  @old, @seriesNumber,@SDOrgID,@SDGroup,
	    @SDOrgName,@SDGroupName,@docType, @PackageID,@packageName,@Totalmoney,
	    @ComboCode,@comboName,@DocDate,  @ComboFeeType, @Totalmoney,@SIMCode,@SeriesCode,@MatCode,@Remark,
	    --客户信息
	    @customerName ,@Vouchercode, @voucherType,@birthday,@ValidDate,@PhoneNumber,@PhoneNumber1,
	    @sex,@post,@cust_Fax,@ContactAddress,@VoucherAddress,
	    @ReservedDoccode,@cust_Zipcode,@cust_IM,@cust_Email,
	    ---公司信息
	    @cust_BusinessLicense,@cust_Industry,@cust_CompanyName,
	    @cust_CompanyAddress,@cust_SalaryDate,@cust_WOKU, @birthday
while @@FETCH_STATUS=0
	BEGIN
		IF ISNULL(@CustomerId,'')=''
			begin
				select @isNewCustomer=1
				SELECT @CustomerId=dbo.fn_MatchCustomer(@CustomerCode,@Vouchercode,@customerName,@seriesNumber,@PhoneNumber,@PhoneNumber1)
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
			--当是新登记客户,或原单据中无客户信息时,才进行更新.
			if @isNewCustomer>0
				BEGIN
					update Unicom_Orders
						set CustomerID = @CustomerId,
						UserID = @UserID
					where DocCode=@doccode
				END
		fetch next FROM abc into  @old, @seriesNumber,@SDOrgID,@SDGroup,
				@SDOrgName,@SDGroupName,@docType, @PackageID,@packageName,@Totalmoney,
				@ComboCode,@comboName,@DocDate,  @ComboFeeType, @Totalmoney,@SIMCode,@SeriesCode,@MatCode,@Remark,
				--客户信息
				@customerName ,@Vouchercode, @voucherType,@birthday,@ValidDate,@PhoneNumber,@PhoneNumber1,
				@sex,@post,@cust_Fax,@ContactAddress,@VoucherAddress,
				@ReservedDoccode,@cust_Zipcode,@cust_IM,@cust_Email,
				---公司信息
				@cust_BusinessLicense,@cust_Industry,@cust_CompanyName,
				@cust_CompanyAddress,@cust_SalaryDate,@cust_WOKU, @birthday
	END
close abc
deallocate abc
