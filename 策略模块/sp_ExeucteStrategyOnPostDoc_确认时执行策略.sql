/*
过程名称:sp_ExecuteStrategyOnPostDoc
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
ALTER PROC [dbo].[sp_ExecuteStrategyOnPostDoc]
	@Formid INT,
	@Doccode VARCHAR(50),
	@OptionId VARCHAR(50)='',
	@Usercode VARCHAR(50)='',
	@TerminalID VARCHAR(50)=''
AS
	BEGIN
		SET NOCOUNT ON;
		SET XACT_ABORT ON;
		DECLARE @tranCount INT,@tips VARCHAR(5000)
		declare @stcode varchar(50),	@SDOrgID varchar(50),@SDorgPath varchar(200),
		@AreaID varchar(50),	@AreaPath varchar(50),@dpttype varchar(50),@docdate datetime
		
		Create table #DocData(
		Doccode varchar(50),
		FormID int,
		stcode varchar(50),
		SDOrgID varchar(50),
		SDorgPath varchar(200),
		AreaID varchar(50),
		AreaPath varchar(50),
		dpttype varchar(50),
		docdate datetime
		)
		if @Formid not in(9146,9102,9237,9267) return
		IF @Formid IN(9146,9102,9237)
			BEGIN
				select @Doccode=uo.DocCode,@SDOrgID=uo.sdorgid,@docdate=uo.DocDate,@stcode=uo.stcode
				from Unicom_Orders uo with(nolock)
				where uo.DocCode=@Doccode
			end
		if @Formid in(9267)
			BEGIN
				select @Doccode=uo.DocCode,@SDOrgID=uo.sdorgid,@docdate=uo.DocDate,@stcode=uo.stcode
				from BusinessAcceptance_H  uo with(nolock)
				where uo.DocCode=@Doccode
			END
		--取出部门信息
		select @AreaID=os.AreaID,@SDorgPath=os.PATH,@dpttype=os.dpttype
		  from oSDOrg os with(nolock) where os.SDOrgID=@SDOrgID
		--取出区域信息
		select @AreaPath=path from gArea ga with(nolock) where ga.areaid=@AreaID
		--写入单据数据源
		insert into #DocData(Doccode,FormID,stcode,SDOrgID,SDorgPath,AreaID,AreaPath,dpttype,docdate)
		Select @doccode,@formid,@stcode,@sdorgid,@SDOrgPath,@AreaID,@AreaPath,@dptType,@docdate
		Select @tranCount = @@TRANCOUNT
		If @tranCount = 0 Begin Tran  
		Begin Try
			--执行策略
			Exec sp_ExecuteStrategy @formid, @doccode, 4, '', @Usercode,@TerminalID
			If @tranCount = 0 Commit
		End Try
		Begin Catch
			Select @tips = Error_message() + dbo.crlf() + '异常过程：' + Error_procedure() + dbo.crlf() + '异常发生于第：' + Convert(Varchar(10), Error_line()) + '行'
			If @tranCount = 0 Rollback
				Raiserror(@tips, 16, 1) 
				Return
		End Catch
	END
	 