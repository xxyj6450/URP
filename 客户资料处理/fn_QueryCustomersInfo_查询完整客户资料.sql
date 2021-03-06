/*            
* 函数名称：fn_QueryCustomersInfo    
* 功能描述：客户资料查询    
* 参数:见声名部分            
* 编写：三断笛            
* 时间：2010/06/10            
* 备注：为防止客户资料泄露,这里仅显示100项
* 示例：select * from fn_QueryCustomersInfo('jt000001','','','','','','','','','','','','')        
* --------------------------------------------------------------------            
* 修改：            
* 时间：            
* 备注：            
*             
*/      
-- select * from customers    
ALTER FUNCTION [dbo].[fn_QueryCustomersInfo](    
 @CustomerCode VARCHAR(20),    --客户编码    
 @CustomerName VARCHAR(20),    --客户姓名    
 @VoucherCode VARCHAR(30),    --证件编号    
 @grade VARCHAR(20),   --级别  
 @PhoneNumber VARCHAR(30),  --联系电话,会匹配客户的所有联系方式  
 @Birthday DATETIME,   --生日,公历  
 @lunarDate DATETIME,   --生日,农历  
 @Address VARCHAR(50),   --地址,会匹配客户所有的地址  
 @begindate DATETIME,   --发展起始时间  
 @enddate DATETIME,    --发展结束时间  
 @DevelopStaffId VARCHAR(20), --发展员工  
 @Developsdorgid VARCHAR(20), --发展部门  
 @blackList BIT)     --是否黑名单  
RETURNS @table TABLE(
CustomerID varchar(50),
 CustomerCode varchar(20),    
 [Name] varchar(50) ,    
 Sex varchar(2) ,    
 VoucherType varchar(30) ,    
 VoucherCode varchar(30) ,    
 ValidDate datetime ,    
 PhoneNumber varchar(50) ,    
 PhoneNumber1 varchar(50) ,    
 Fax varchar(50) ,    
 Industry varchar(20) ,    
 Company varchar(50) ,    
 Department varchar(50) ,    
 Post varchar(20) ,    
 ZipCode varchar(50) ,    
 BirthDay datetime ,    
 LunarDate datetime ,    
 VoucherAddress varchar(200) ,    
 curAddress varchar(200) ,    
 EMail varchar(50) ,    
 TotalConsumption money ,    
 ConsumptionCount INT,    
 Grade varchar(50) ,    
 DevelopStaffID varchar(20) ,    
 DevelopStaffName varchar(20) ,    
 DevelopSdorgID varchar(20) ,    
 DevelopSdorgName varchar(100) ,    
 Photo image ,    
 Enterdate DATETIME,    
 Remark varchar(200),  
 Blacklist BIT,
QQ VARCHAR(20),
CompanyLicense VARCHAR(50),
CompanyAddress VARCHAR(200),
URL VARCHAR(200),
OpenAccountLimit int
)    
AS    
 BEGIN    
  INSERT INTO @table    
   SELECT TOP 100      ---最多返回100行数据    
          customerID, strCustomerCode,strcustomerNAME,strSex,strVoucherType,strVoucherCode,convert(varchar(10),dtmValidDate,120),    
          strPhoneNumber,strPhoneNumber1,strFax,strIndustry,strCompany,strDepartment,strPost,    
          strZipCode, convert(varchar(10),a.dtmBirthday,120),dtmLunarDate,strVoucherAddress,strcurAddress,strEMail,a.dblTotalConsumption,intConsumptionCount,strGrade,    
          strDevelopStaffID,NULL,strDevelopSdorgID,    
          NULL,NULL,dtmenterdate,strRemark,a.bitBlackList,a.strQQ,a.strCompanyLicense,a.strCompanyAddress,a.[strURL],a.OpenAccountLimit    
   FROM   sop_dim_customers a WITH (noLOCK)   
   WHERE (@Customercode='' OR a.strcustomercode LIKE '%'+@customercode+'%')    
   AND (@CustomerName='' OR a.strcustomername LIKE @CustomerName+'%')    
   AND (@VoucherCode='' OR a.strVoucherCode LIKE '%'+@VoucherCode+'%')    
   AND (@grade='' OR a.strgrade=@grade)    
   AND (@PhoneNumber='' OR a.strphonenumber LIKE @PhoneNumber+'%' OR a.strphonenumber1 LIKE @PhoneNumber +'%' OR a.strfax LIKE @PhoneNumber +'%')    
   AND (@Birthday='' OR a.dtmbirthday=@Birthday)    
   AND (@lunarDate='' OR a.dtmlunarDate =@lunarDate)    
   AND (@Address='' OR a.strVoucheraddress LIKE @Address+'%' OR a.strcuraddress LIKE @address +'%')    
   AND (@DevelopStaffId='' OR a.strDevelopStaffID=@DevelopStaffId)    
   AND (@Developsdorgid='' OR a.strdevelopsdorgid=@Developsdorgid)    
   AND (@begindate='' OR a.dtmenterdate>=@begindate)    
   AND (@enddate='' OR a.dtmenterdate <=@enddate+1)  
   AND (@blackList='' OR a.bitBlackList=@blackList)  
  return    
 end     
     



