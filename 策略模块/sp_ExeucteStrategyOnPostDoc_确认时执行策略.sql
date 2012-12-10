/*
��������:sp_ExeucteStrategyOnPostDoc
����:������
����ֵ:
����:�ڵ���ȷ��ʱִ�в���
��д:���ϵ�
ʱ��:2012-12-07
��ע:
ʾ��:
begin tran
exec sp_ExeucteStrategyOnPostDoc 9237,'RS20121210000561','','system',''

SELECT * FROM Coupons_MaxCode cmc
select * from icoupons where couponscode='1007'
 select  top 10 * from numbers
rollback 
*/
alter PROC sp_ExeucteStrategyOnPostDoc
	@Formid INT,
	@Doccode VARCHAR(50),
	@OptionId VARCHAR(50)='',
	@Usercode VARCHAR(50)='',
	@TerminalID VARCHAR(50)=''
AS
	BEGIN
		DECLARE @tranCount INT,@tips VARCHAR(5000)
		SET NOCOUNT ON;
		SET XACT_ABORT ON;
		IF @Formid IN(9237)
			BEGIN
				Select * Into #DocData
				From   v_unicomOrders_HD With(Nolock)
				Where  DocCode = @doccode
				Select @tranCount = @@TRANCOUNT
				If @tranCount = 0 Begin Tran  
				Begin Try
					--ִ�в���
					Exec sp_ExecuteStrategy @formid, @doccode, 2, '', @Usercode,@TerminalID
					If @tranCount = 0 Commit
				End Try
				Begin Catch
					Select @tips = Error_message() + dbo.crlf() + '�쳣���̣�' + Error_procedure() + dbo.crlf() + '�쳣�����ڵڣ�' + Convert(Varchar(10), Error_line()) + '��'
					If @tranCount = 0 Rollback
					   Raiserror(@tips, 16, 1) 
					   Return
				End Catch
			END
	END
	 