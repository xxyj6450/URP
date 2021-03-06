set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

/*            
* 函数名称：sp_CreateCustomerDoc          
* 功能描述：动态创建和打开客户资料录入单           
* 参数:见声名部分            
* 编写：三断笛            
* 时间：2010/06/10           
* 备注：该存储过程仅是个生成和打开客户资料录入单的中间处理过程，并不是实际客户资料录入单           
* 示例：  sp_CreateCustomerDoc 9102,'RW20100727000062'       
* --------------------------------------------------------------------            
* 修改：当选择的是老客户时,如果没有相关的老客户资料登记单,则重新创建一张,
	如果存在老客户资料登记单,而老客户没有传附件及相片,则弹出老客户单让其修改,否则就直接打开老客户资料登记单,不允许修改      
* 时间：2010/07/26
* 备注：系统运行初期录入了部分客户资料,而在正式上线时,将这些客户资料登记单清空,但是没有清空老客户资料,导致部分客户没有资料登记单.而且在2010/07/23前,
系统未限制必须上传客户证件资料,导致部分老客户无证件资料.所以增加一些后续处理,解决以上两个问题.

整体处理流程如下:
初始化:取相关的单据单号,单据状态,客户编码,证件等信息
0.取单据状态及审核状态
  0.1 如果单据审核状态不为退回和未提交审核,则以确认方式打开客户资料登记单
1.取单据客户信息
2.如果没有客户(有可能该单已经登记客户,但是又清除了客户资料)
  2.1 取判断是否存在客户登记单@refcode
    2.2.1 如果没有,则@olddoccode =null,创建新单据,返回新单据功能号
    2.2.2 如果有,则@olddoccode=@refcode 返回老功能号
3.如果有客户
  3.1 查询是否有未生成客户编码的相关客户资料登记单,如果有,则删除之
  3.2 查询该客户的登记单
    3.2.1 如果有该客户的资料登记单
      3.2.1.1 如果客户资料登记单无证件
        3.2.1.1.1 以未确认状态打开无证件的客户资料登记单
      3.2.1.2 如果客户资料登记单有证件
        3.2.1.2.1 以确认状态打开客户资料登记单
    3.2.2 如果没有该客户的资料登记单
      3.2.2.1 从客户资料表取资料,创建客户资料单
*             
*/     
ALTER PROC [dbo].[sp_CreateCustomerDoc]    
 @refformid INT,    
 @refcode VARCHAR(20),    
 @optionID INT=0,    
 @linkdocinfo VARCHAR(200)='' OUTPUT      
AS    
 BEGIN
/***************************************************公共变量定义区******************************************/  
	--原单变量
	DECLARE @OldDocCode VARCHAR(20),@customerCode VARCHAR(20),@chekcstate VARCHAR(20)
	DECLARE @DocStatus1 INT,@areaid VARCHAR(20)
	DECLARE @sdgroup VARCHAR(20),@sdgroupname VARCHAR(50)    
	DECLARE @sdorgid VARCHAR(20),@sdorgname VARCHAR(50)
	DECLARE @seriesnumber VARCHAR(20),@email VARCHAR(200)
	--客户资料登记单变量
	DECLARE @CSTCode VARCHAR(20),@voucherCode VARCHAR(40),@DocStatus INT,@customercode1 VARCHAR(20)
	--其他变量
	DECLARE @newDoccode VARCHAR(20),@formId VARCHAR(10)  --用于标志要打开单据的功能和及单号   
	DECLARE @doccode2 VARCHAR(20)
	SET NOCOUNT on    
/***************************************************初始化******************************************************/
	--查询是否已存在客户资料单,顺便取单据相关信息    
	SELECT @OldDocCode=doccode,@voucherCode=VoucherCode,@DocStatus=DocStatus,@customerCode=CustomerCode
	  FROM customers_h WHERE  refcode=@refcode
	
/****************************************************0.取单据状态及审核状态********************************************/

	IF @refformid IN(9102,9146)							--套包销售和客户新入网单
		begin    
			--取业务单单号状态    
			SELECT @DocStatus1=docstatus,@sdgroup=sdgroup,@sdgroupname=sdgroupname,    
			@sdorgid=sdorgid,@sdorgname=sdorgname,@chekcstate=checkState,@customerCode=cltCode
			 FROM Unicom_Orders WHERE FormID=@refformid AND DocCode=@refcode  
 			--取手机,邮箱等信息
			SELECT @seriesnumber=seriesnumber,@email=@seriesnumber+'@wo.com.cn' FROM Unicom_Orders uo WHERE uo.DocCode=@refcode
			SELECT @formId=9128							--创建客户资料登记单
		END
	IF @refformid IN(9153,9158,9159,9160,9165,9167)		--其他业务受理
		BEGIN
				--取业务单单号状态    
			SELECT @DocStatus1=docstatus,@sdgroup=sdgroup,@sdgroupname=sdgroupname,    
			@sdorgid=sdorgid,@sdorgname=sdorgname,@chekcstate=checkState,@customerCode=cltCode
			FROM BusinessAcceptance_H bah WHERE FormID=@refformid AND DocCode=@refcode  
 			--取手机,邮箱等信息
			SELECT @seriesnumber=seriesnumber,@email=@seriesnumber+'@wo.com.cn' FROM Unicom_Orders uo WHERE uo.DocCode=@refcode
			SELECT @formId=9128							--创建客户资料登记单
			
		END
	IF @refformid IN(9153,9159)								--其他业务受理(过户,客户资料修改..)
		BEGIN
			IF @refformid IN(9153)
				SELECT @formId=9128
			ELSE IF (@refformid IN(9159))
				begin
					SELECT @customerCode=c.CustomerCode FROM Customers c 
						INNER JOIN BusinessAcceptance_H bah ON (c.VoucherType=bah.VoucherType AND c.VoucherCode=bah.VoucherCode)
						WHERE bah.formid=@refformid AND bah.doccode=@refcode
				IF @customerCode IS NOT null
						SELECT @formId=9136,@optionID=1							--如果存在这个老客户,则转至客户资料修改单
					ELSE
						SELECT @formId=9128 , @optionID=0						--如果不存在这个客户,则转至客户资料登记单
				end
		END
	IF @refformid IN(9139)								--新入网审核
		BEGIN
			--取得客户编码
			/*SELECT cltname,cltcode FROM Unicom_Orders uo WHERE uo.DocCode='RW20100722000058'
			SELECT  ch.DocStatus, formid, doccode
			  FROM Customers_H ch WHERE ch.CustomerCode='JT000645' AND ch.DocStatus<>0 AND ch.Formid=9128*/
			SELECT @customerCode=cltcode FROM Unicom_Orders uo WHERE uo.DocCode=@refcode
			--取得单号
			SELECT @newDoccode=doccode,@formId=formid FROM Customers_H ch WHERE ch.CustomerCode=@customerCode AND customercode IS NOT null AND formid =9128
		  --打开该客户资料单          
		  PRINT @newDoccode
		  PRINT @formId
		  SELECT @linkdocinfo=convert(varchar(20),@formid)+';16;'+ @newDoccode
		  return
		END
	IF @refformid IN(9157)
		BEGIN
			SELECT @customerCode=customercode1 FROM BusinessAcceptance_H  uo WHERE uo.DocCode=@refcode
			--取得单号
			SELECT @newDoccode=doccode,@formId=formid FROM Customers_H ch WHERE ch.CustomerCode=@customerCode AND ch.DocStatus<>0 AND formid =9128
		  --打开该客户资料单          
		  PRINT @newDoccode
		  PRINT @formId
		  SELECT @linkdocinfo=convert(varchar(20),@formid)+';16;'+ @newDoccode
		  return
		end
/*****************************0.1 如果单据审核状态不为退回和未提交审核,则以确认方式打开客户资料登记单***************************/
	IF @formId IN(9102,9146,9153,9158,9159,9160,9165,9167)
		BEGIN
			IF @chekcstate<>'退回' and @chekcstate is not null
				BEGIN
					SELECT @linkdocinfo=CONVERT(VARCHAR(10),@formId)+';16;'+ @OldDocCode
					return
				END
/**************************2.如果没有客户(有可能该单已经登记客户,但是又清除了客户资料)****************************************/
			IF @customerCode IS NULL
				BEGIN
					IF @olddoccode IS NOT NULL
						BEGIN
							SELECT @linkdocinfo=CONVERT(VARCHAR(10),@formId)+';16;'+ @OldDocCode
							return
						END
				END
			ELSE		----3.如果有客户
				BEGIN
					-- 3.1 查询是否有未生成客户编码的相关客户资料登记单,如果有,则删除之
					DELETE FROM Customers
					WHERE formid=@formId
					AND doccode=@OldDocCode
					AND docstatus=0
					AND CustomerCode IS NULL
					--3.2 查询该客户的登记单
					SELECT @doccode2=doccode FROM Customers_H ch WHERE ch.Formid=@formId AND ch.CustomerCode=@customerCode
					--3.2.1 如果有该客户的资料登记单
					IF @doccode2 IS NOT NULL
						BEGIN
							--3.2.1.1 如果客户资料登记单无证件
							IF  EXISTS(SELECT 1 FROM customers_h a LEFT JOIN  Customers_H_files chf 
								ON a.DocCode=chf.DocCode  WHERE chf.DocCode IS NULL AND a.Photo IS NULL
								AND a.DocCode=@doccode2)
								BEGIN
									-- 3.2.1.1.1 以未确认状态打开无证件的客户资料登记单
									UPDATE Customers_H SET DocStatus = 0 WHERE DocCode=@doccode2
								END
							ELSE	--3.2.1.2 如果客户资料登记单有证件
								BEGIN
									--3.2.1.2.1 以确认状态打开客户资料登记单
									UPDATE Customers_H SET DocStatus = 1 WHERE DocCode=@doccode2
								end
							SELECT @linkdocinfo=CONVERT(VARCHAR(10),@formId)+';16;'+ @doccode2
							return
						END
					ELSE			--3.2.2 如果没有该客户的资料登记单
						BEGIN
							-- 3.2.2.1 从客户资料表取资料,创建客户资料单
							EXEC sp_newdoccode @formId,'',@newDoccode OUTPUT
							INSERT INTO Customers_H(DocCode,DocDate,formid,docstatus,doctype,refcode,refformid, 
										developstaffid,DevelopStaffName,developsdorgid,developsdorgname,EnterDate,Entername,EMail,
							CustomerCode,[Name],VoucherType,VoucherCode,VoucherAddress,ValidDate,Grade,PhoneNumber,PhoneNumber1,fax,ZipCode,
							BirthDay,BirthdayString,LunarDate,LunarDateString,Industry,Company,CompanyLicense,CompanyAddress,Photo,qq,sex,
							curAddress)            
										select @newDoccode,convert(varchar(10),GETDATE(),120),@formid,0,'客户资料登记',@refcode,@refformid    
										,@sdgroup,@sdgroupname,@sdorgid,@sdorgname,CONVERT(VARCHAR(20),GETDATE(),120),@sdgroupname,email,
										CustomerCode,[Name],VoucherType,VoucherCode,VoucherAddress,ValidDate,Grade,PhoneNumber,PhoneNumber1,fax,ZipCode,
										BirthDay,BirthdayString,LunarDate,LunarDateString,Industry,Company,
										CompanyLicense,CompanyAddress,Photo,qq,sex,c.curAddress
							FROM Customers c WHERE c.CustomerCode=@customerCode
							SELECT @linkdocinfo='9128;16;'+ @newDoccode
							return
						end
				end
/**************************************************** 创建和打开客户资料登记单*********************************/
			--当存在客户资料单时，直接打开它 select docstatus from customers_H    
			IF @OldDocCode IS NOT NULL    
			 BEGIN
				--如果业务单据审核状态为NULL或退回,则将客户登记单标记为未确认状态,允许用户再次修改登记资料
				IF @chekcstate IS NULL OR @chekcstate='退回'
					UPDATE Customers_H SET DocStatus = 0 WHERE DocCode=@OldDocCode
				ELSE		--如果业务单据审核状态不为NULL或退回,则不允许修改客户资料
					UPDATE Customers_H SET docstatus=1 WHERE doccode=@OldDocCode
			  --直接打客户资料登记单         
			  SELECT @linkdocinfo=@formid+';16;'+ @olddoccode    
			  return    
			 END    
			ELSE --如果没有客户单，则创建一个,将客户的联系电话默认为开户号码,将将电子邮箱默认为其186邮箱
			 BEGIN  
 				IF (@chekcstate IS NULL OR @chekcstate='退回') and @docstatus1=0					--仅未确认且状态为空或退回时可以录入客户资料
 					begin  
						  EXEC sp_newdoccode @formId,'',@newDoccode OUTPUT
						IF @formId IN(9128)
							begin   
								INSERT INTO Customers_H(DocCode,DocDate,formid,docstatus,doctype,refcode,refformid, 
								developstaffid,DevelopStaffName,developsdorgid,developsdorgname,EnterDate,Entername,PhoneNumber1,EMail)            
								VALUES(@newDoccode,convert(varchar(10),GETDATE(),120),@formid,0,'客户资料登记',@refcode,@refformid    
								,@sdgroup,@sdgroupname,@sdorgid,@sdorgname,CONVERT(VARCHAR(20),GETDATE(),120),@sdgroupname,@seriesnumber,@email)
							END
						IF @formId IN(9136)
							BEGIN
								INSERT INTO Customers_H(DocCode,DocDate,formid,docstatus,doctype,refcode,refformid, 
									developstaffid,DevelopStaffName,developsdorgid,developsdorgname,EnterDate,Entername,EMail,
								customercode,name,VoucherType,VoucherCode,VoucherAddress,curAddress,ZipCode,PhoneNumber,sex,grade,BirthDay,
								LunarDate,validdate,PhoneNumber1,Photo,Company,CompanyLicense,CompanyAddress)
								SELECT @newDoccode,convert(varchar(10),GETDATE(),120),@formid,0,'客户资料修改',@refcode,@refformid    
									,@sdgroup,@sdgroupname,@sdorgid,@sdorgname,CONVERT(VARCHAR(20),GETDATE(),120),@sdgroupname,@email,
									customercode,name,VoucherType,VoucherCode,VoucherAddress,curAddress,c.ZipCode,PhoneNumber,sex,grade,BirthDay,
								LunarDate,validdate,PhoneNumber1,Photo,Company,CompanyLicense,CompanyAddress
								FROM Customers c  WHERE c.CustomerCode=@customerCode
							end  
						  --打开该客户资料单          
						  SELECT @linkdocinfo=@formid+';16;'+ @newDoccode
					end     
			 END  
			 return  
		END
    













