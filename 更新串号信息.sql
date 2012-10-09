/*
过程名称:sp_quickUpdateSeriescode
参数:见声名
功能:更新串号信息
编写:三断笛
时间:2012-09-05
备注:
*/
alter proc sp_quickUpdateSeriescode
	@Seriescode varchar(50),									--串号
	@OptionID varchar(200),									--操作
	@Usercode varchar(50),										--用户编码
	@Password varchar(50),										--密码
	@mParam varchar(200),										--参数1
	@lParam varchar(200),										--参数2
	@Remark varchar(500),										--备注
	@TerminalID varchar(50)									--终端编码
as
	BEGIN
		set nocount on;
		--解锁
		if @OptionID='Unlock'
			BEGIN
				update iSeries
					set isava = 0,
					isbg = 0,
					Occupyed = 0,
					OccupyedDoc = null
				where SeriesCode=@Seriescode
			END
		return
	END
	
	