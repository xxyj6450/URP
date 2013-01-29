/*
过程名称：sp_LogStock_matledger_Seriescode
功能描述：记录每日库存，串号与成本日志
参数：见声名
返回值：
编写：三断笛
时间：2013-1-25
备注：
示例：exec sp_LogStock_matledger_Seriescode '2012-01-02','1.1.769.11.01'
select * from rj_iSeriesLog where sdorgid='1.1.769.11.01'
select *from rj_matStorageLog  where sdorgid='1.1.769.11.01'
select * from rj_MatsdorgLedgerLog  where sdorgid='1.1.769.11.01'
*/
alter proc sp_LogStock_matledger_Seriescode
	@baldate datetime,
	@sdorgid varchar(50)='',
	@plantID varchar(10)='',
	@optionID int=0,						--选项开关,默认传0,1:刷新串号,2:刷新库存,4:刷新成本,也可用这几个开关项的和来组合开关
	@usercode varchar(50)='',
	@TerminalID varchar(50)=''
as
	BEGIN
		set NOCOUNT ON
		declare @tips varchar(max),@trancount int
		--检查日期参数
		if isdate(@baldate)=0
			BEGIN
				raiserror('传入的日期参数非正确的日期格式，请重试。',16,1)
				return
			END
		--格式化日期
		select @baldate=convert(datetime,convert(varchar(10),@baldate,120))
		--记录事务信息
		select @trancount=@@TRANCOUNT
		if @trancount=0
				begin TRAN
		else
			save tran tran1
		begin try
			--串号记录，先删除已有的，再插入
			if @optionID=0 or @optionID&1=1
				BEGIN
					--仅能刷新最后一天的数据，禁止刷新以前的
					if exists(select 1 from rj_iSeriesLog a with(nolock) 
					          where baldate>@baldate 
								and  (@sdorgid='' or  sdorgid=@sdorgid)
								and (@plantID='' or plantid=@plantID)
					)
					BEGIN
						raiserror('禁止处理过往数据，仅能对最新数据进行操作.',16,1)
						return
					END
					delete from rj_iSeriesLog 
					where baldate=@baldate 
					and  (@sdorgid='' or  sdorgid=@sdorgid)
					and (@plantID='' or plantid=@plantID)
					
					insert into rj_iSeriesLog(plantID,sdorgid,stcode,Seriescode,baldate,matcode)
					select  b.PlantID,b.sdorgid,b.stCode,a.SeriesCode,@baldate,a.MatCode
					from iSeries a inner join oStorage b on a.stcode=b.stCode
					where a.state='在库'
					and (@sdorgid='' or  b.sdorgid=@sdorgid)
					and (@plantID='' or b.PlantID=@plantID)
				END
			
			--库存记录，先删除已有的，再插入
			if @optionID=0 or @optionID&2=2
				BEGIN
					--仅能刷新最后一天的数据，禁止刷新以前的
					if exists(select 1 from rj_matStorageLog a with(nolock) 
					          where baldate>@baldate 
								and  (@sdorgid='' or  sdorgid=@sdorgid)
								and (@plantID='' or plantid=@plantID)
					)
					BEGIN
						raiserror('禁止处理过往数据，仅能对最新数据进行操作.',16,1)
						return
					END
					
					delete from rj_matStorageLog 
					where baldate=@baldate 
					and (@sdorgid='' or  sdorgid=@sdorgid) 
					and (@plantID='' or plantid=@plantID)
					
					insert into rj_matStorageLog(plantID,sdorgid,stcode,unLimitStock,OnOrderStock,transStock,baldate,matcode)
					select  b.PlantID,b.sdorgid,b.stCode,a.unlimitStock,a.onorderstock,a.ontransstock, @baldate,a.MatCode
					from iMatStorage a inner join oStorage b on a.stcode=b.stCode
					where (@sdorgid='' or    b.sdorgid=@sdorgid)
					and (@plantID='' or b.PlantID=@plantID)
					and a.unlimitStock>0
				END
			
			--成本记录，先删除已有的，再插入
			if @optionID=0 or @optionID&4=4
				BEGIN
					--仅能刷新最后一天的数据，禁止刷新以前的
					if exists(select 1 from rj_MatsdorgLedgerLog a with(nolock) 
					          where baldate>@baldate 
								and  (@sdorgid='' or  sdorgid=@sdorgid)
								and (@plantID='' or plantid=@plantID)
					)
					BEGIN
						raiserror('禁止处理过往数据，仅能对最新数据进行操作.',16,1)
						return
					END
					
					delete from rj_MatsdorgLedgerLog 
					where baldate=@baldate
					 and  (@sdorgid='' or  sdorgid=@sdorgid) 
					 and (@plantID='' or plantid=@plantID)
					 
					insert into rj_MatsdorgLedgerLog(plantid,sdorgid,Stock,StockValue,Map,ratevalue,ratemap,baldate,matcode)
					select a.PlantID, a.sdorgid,a.Stock,a.StockValue,a.MAP,a.ratevalue,a.ratemap,@baldate,a.MatCode
					from iMatsdorgLedger a
					where (@sdorgid='' or    a.sdorgid=@sdorgid)
					and (@plantID='' or a.PlantID=@plantID)
				END
			if @trancount=0 commit
		end try
		begin catch
			select @tips=dbo.getLastError('记录串与，库存，成本日志失败.')
			if @trancount=0 
				rollback
			else if xact_state()<>-1
				rollback TRAN tran1
			raiserror(@tips,16,1)
		end catch
 
	END
 