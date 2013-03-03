/*
��������:getLastError
����:��ʽ��������Ϣ������
����:������
��д:���ϵ�
ʱ��:2012-11-22
��ע:�ڷ�������ʱ,ʹ���������,���Ը�ʽ��������Ϣ����.
ʾ��:
BEGIN TRY
	raiserror('������һ�����Ĵ���',16,1)
END TRY
BEGIN CATCH
	print dbo.getLastError('�����쳣!')
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
		'�쳣������'+isnull(error_procedure(),'')+'��'+convert(varchar(10),isnull(error_line(),0))+'��'
		return @ErrorInfo
	END