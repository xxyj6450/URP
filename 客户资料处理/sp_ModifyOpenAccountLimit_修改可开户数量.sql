 
/*
过程名称:sp_ModifyOpenAccountLimit
功能:修改客户开户数限制
参数:见声名
编写:三断笛
时间:2012-07-09
备注:
*/
ALTER PROC [dbo].[sp_ModifyOpenAccountLimit]
	@CustomerCode SQL_VARIANT,
	@OpenAccountLimit INT 
AS
	BEGIN
		SET NOCOUNT ON;
		UPDATE sop_dim_Customers
			SET OpenAccountLimit = @OpenAccountLimit
		WHERE CustomerID= convert(varchar(50), @customercode)
	END
	
 