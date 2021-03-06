 
/*
函数名称:fn_MatchCustomer
参数:见声名
功能描述:根据客户编码等参数匹配客户信息
返回值:返回客户编码
编写:三断笛
时间:2011-11-22
备注:
-----
修改:2012-09-29  三断笛
备注:不再根据联系电话来匹配客户信息.太耗资源,而且不够准确.
*/
ALTER FUNCTION [fn_MatchCustomer](
	@CustomerCode VARCHAR(50),
	@VoucherCode VARCHAR(50),
	@Name VARCHAR(50),
	@SeriesNumber VARCHAR(20),
	@PhoneNumer VARCHAR(50),
	@PhoneNumer1 VARCHAR(50)
)
RETURNS VARCHAR(50)
AS
	BEGIN
		DECLARE @CustomerID VARCHAR(50)
		--如果有客户编码,则直接取得客户资料
		IF ISNULL(@CustomerCode,'')<>'' 
			BEGIN
				SELECT TOP 1 @CustomerID=customerid FROM SOP_dim_Customers a WITH(NOLOCK) WHERE a.strCustomerCode=@CustomerCode
				if isnull(@CustomerID,'')!='' 	RETURN @CustomerID
			END
		
		IF ISNULL(@VoucherCode,'')<>''
			BEGIN
				SELECT TOP 1 @CustomerID=customerid FROM SOP_dim_Customers a  WITH(NOLOCK) WHERE a.strVoucherCode=@VoucherCode
				if isnull(@CustomerID,'')!='' 	RETURN @CustomerID
			END
 
		RETURN @CustomerID
	END