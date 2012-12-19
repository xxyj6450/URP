/*
过程名称:sp_ExeucteStrategyOnPostDoc
参数:见声名
返回值:
功能:在单据确认时执行策略
编写:三断笛
时间:2012-12-07
备注:
示例:
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
					--执行策略
					Exec sp_ExecuteStrategy @formid, @doccode, 2, '', @Usercode,@TerminalID
					If @tranCount = 0 Commit
				End Try
				Begin Catch
					Select @tips = Error_message() + dbo.crlf() + '异常过程：' + Error_procedure() + dbo.crlf() + '异常发生于第：' + Convert(Varchar(10), Error_line()) + '行'
					If @tranCount = 0 Rollback
					   Raiserror(@tips, 16, 1) 
					   Return
				End Catch
			END
	END
	 