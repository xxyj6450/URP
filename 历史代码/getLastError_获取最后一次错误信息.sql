/*
函数名称:getLastError
功能:格式化错误信息并返回
参数:见声名
编写:三断笛
时间:2012-11-22
备注:在发生错误时,使用这个函数,可以格式化错误信息返回.
示例:
BEGIN TRY
	raiserror('发生了一个天大的错误',16,1)
END TRY
BEGIN CATCH
	print dbo.getLastError('操作异常!')
END CATCH

*/
create function getLastError(
	@Message nvarchar(500)
)
returns nvarchar(max)
as
	BEGIN
		declare @ErrorInfo nvarchar(max)
		select @ErrorInfo=isnull(@Message,'')+dbo.crlf()+
		isnull(error_message(),'')+dbo.crlf()+
		'异常发生于'+isnull(error_procedure(),'')+'第'+convert(varchar(10),isnull(error_line(),0))+'行'
		return @ErrorInfo
	END