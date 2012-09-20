
/*            
* 函数名称：[fn_QueryCustomersInfo1]
* 功能描述：客户资料查询    
* 参数:见声名部分            
* 编写：三断笛            
* 时间：2010/07/24
* 备注：该函数用于制单时引入客户资料.在本函数要求录入编号,姓名或证件号码的任意一项,而且进行精确匹配.防止客户资料泄露.
* 示例：       
* --------------------------------------------------------------------            
* 修改：            
* 时间：            
* 备注：            
*             
*/      
-- select * from customers    
ALTER FUNCTION [dbo].[fn_QueryCustomersInfo2]
(
 
	@VoucherType VARCHAR(50),
	@voucherCode   VARCHAR(30)
)--客户姓名
RETURNS @table TABLE(
            CustomerID VARCHAR(50),
            CustomerCode VARCHAR(20),
            [Name] VARCHAR(50),
            VoucherType VARCHAR(50),
            VoucherCode VARCHAR(30),
            BirthDay VARCHAR(50),
            SEX varchar(50),
            ValidDate DATETIME,
            VoucherAddress VARCHAR(200),
            curAddress VARCHAR(200),
            PhoneNumber VARCHAR(50),
            ZipCode VARCHAR(50),
            TotalConsumption MONEY,
            ConsumptionCount INT,
            PhoneNumber1 VARCHAR(50),
            CustomerState VARCHAR(50)
        )
AS
    
BEGIN
	--没有输入资料则不返回信息
	IF   @voucherCode = ''
	    RETURN
	
	INSERT INTO @table
	SELECT TOP 100 ---最多返回100行数据    
	       customerid, CustomerCode, NAME, vouchertype, VoucherCode, convert(varchar(10),birthday,120),sex,convert(varchar(10), ValidDate,120),
	       VoucherAddress, curAddress, PhoneNumber, Zipcode, TotalConsumption, 
	       ConsumptionCount, PhoneNumber, CASE 
	                                           WHEN blacklist = 1 THEN '黑名单'
	                                           ELSE '老客户'
	                                      END
	FROM   URP11.JTURP.dbo.customers a WITH (HOLDLOCK)
	WHERE   (@VoucherCode = '' OR a.VoucherCode = @VoucherCode)
	IF @@ROWCOUNT=0
		BEGIN
			IF @VoucherType='身份证'
				begin
					INSERT INTO @table
					SELECT TOP 100 ---最多返回100行数据    
						   NULL, NULL, NULL, NULL, @VoucherCode, convert(varchar(10),a.Birthday,120),a.sex, GETDATE(),
						   a.RegionFullName, a.RegionFullName, NULL, NULL, 0, 
						   0, NULL,CASE WHEN a.Valid=1 THEN '新客户' else '非法证件' end
					FROM dbo.CheckIDCard(@voucherCode) a
				END
			ELSE
				BEGIN
					INSERT INTO @table
					SELECT TOP 100 ---最多返回100行数据    
						   NULL, NULL, NULL, NULL, @VoucherCode, NULL,GETDATE(),'男', GETDATE(),
						    NULL, NULL, NULL, 0, 
						   0, NULL,  '新客户'  
				END
					 
			
		END
	RETURN
END


 