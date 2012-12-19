/*
过程名称:sp_FinishCouponsFlow
参数:见声名
返回值:
功能描述:结束优惠券流程,将未使用的优惠券退回给用户继续使用.
备注:本功能只在URP主服务器.目的是提升跨服务器操作的性能,只需要调用过程,不需要再拉取数据到本地.其他服务器使用链接服务器方式访问该过程.
编写:三断笛
时间:2012-12-19
示例:
*/
create proc sp_UpdateCouponsFlow
	@FormID int,
	@Doccode varchar(50),
	@FlowInstanceID varchar(50),					--流程编码
	@FlowStatus varchar(50)='未完成',
	@Couponsbarcode varchar(2000),
	@OptionId varchar(50)='',
	@Usercode varchar(50)='',
	@TerminalID varchar(50)=''
as
	BEGIN
		set NOCOUNT on;
		declare @sql varchar(max)
		--若流程已完成,则将未使用的优惠券都退回给用户使用.
		if @FlowStatus='已完成'
			BEGIN
				if exists(select 1 from oSDOrgCouponsFlow a with(nolock) where a.FlowInstanceID=@FlowInstanceID and a.FlowStatus='未处理') 
					begin
						--先还原优惠券状态
							update a
								set a.State='已赠',
								a.Remark='优惠券未使用,自动还原为正常状态.'
							from iCoupons a with(nolock),oSDOrgCouponsFlow b with(nolock)
							where a.CouponsBarcode=b.Couponsbarcode
							and b.FlowStatus='未处理'
							and a.State='使用中'
							and b.FlowInstanceId=@FlowInstanceID
							--再修改流程标志
							update a
								set a.FlowStatus='已处理',remark='优惠券未使用,自动还原为正常状态.'
							from oSDOrgCouponsFlow  a with(nolock)
							where a.FlowInstanceID=@FlowStatus
					end
			END
		--当流程未结束,正式兑换优惠券时,将优惠券标志已使用
		if @FlowStatus='未完成' and @couponsbarcode<>''
			BEGIN
				update a
								set a.State='已兑换',
								a.Remark='优惠券兑换完毕'
							from iCoupons a with(nolock),oSDOrgCouponsFlow b with(nolock)
							where a.CouponsBarcode=b.Couponsbarcode
							and b.FlowStatus='未处理'
							and a.State='使用中'
							and b.FlowInstanceId=@FlowInstanceID
							--再修改流程标志
							update a
								set a.FlowStatus='已处理',remark='优惠券未使用,自动还原为正常状态.'
							from oSDOrgCouponsFlow  a with(nolock)
							where a.FlowInstanceID=@FlowStatus
			END
 
	END