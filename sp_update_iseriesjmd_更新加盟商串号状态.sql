/*
2012-11-02 将加盟商已售串号转移到已售串号表,直营店,进驻厅等串号在零售单进行转移. 三断笛


*/
alter PROC [sp_update_iseriesjmd](@FormID INT = 9146, @doccode VARCHAR(50))    
AS    
BEGIN
	SET NOCOUNT ON    
	DECLARE @dpttype VARCHAR(50), @SeriesCode VARCHAR(50), @simseriescode VARCHAR(50),@refcode VARCHAR(50) ,@PackageID varchar(50),@tips varchar(5000)
	SELECT @dpttype = dpttype, @SeriesCode = seriescode, @simseriescode = 
	       CardNumber,@refcode=uo.refcode,@PackageID=uo.PackageID
	FROM   Unicom_Orders uo with(nolock)
	WHERE  uo.DocCode = @doccode
	declare @table table(
		Seriescode varchar(50)
		)
	IF @Formid IN (9102, 9146,9237) and @dptType = '加盟店'
	BEGIN
	    UPDATE c
	    SET    salemun = 1,
	    c.state = '已售'
	    output inserted.seriescode into @table
	    FROM   iseries c with(nolock)
	    WHERE   seriescode in( isnull( @seriescode,''),isnull(@simseriescode,''))
	    --若有串号更新,则转移串号
	    if @@ROWCOUNT>0
			BEGIN
				--事务发生任何异常就回滚
				set XACT_ABORT on;
				--开启事务
				begin tran
				BEGIN try
					--先插入已售串号表
					insert into iSeriesSaled
					Select is2.* From iSeries is2 with(nolock) inner join @table b on is2.SeriesCode=b.Seriescode
					--只有当确实插入了数据,才删除原串号表数据,否则抛出异常.
					if @@ROWCOUNT>0
						BEGIN
							--再从串号表中删除串号
							delete a
							from iSeries a with(nolock),@table b
							where a.seriescode=b.Seriescode
						END
					else
					BEGIN
							rollback
							raiserror('串号转移至已售串号表失败,请重试!',16,1)
							return
					END
					if @@TRANCOUNT>0 commit
				END try
				begin catch
					if @@TRANCOUNT>0 rollback
					select @tips='转移串号发生异常.'+dbo.crlf()+isnull(error_message(),'')
					raiserror(@tips,16,1)
					return
				end catch
			END
			
	    
	END
	--非加盟店 在串号表标记套包
	IF @Formid IN (9102, 9146,9237) and @dptType != '加盟店'
	BEGIN
	    UPDATE c
	    SET c.PackageID =@PackageID
	    FROM   iseries c with(nolock)
	    WHERE   seriescode in( isnull( @seriescode,''),isnull(@simseriescode,''))
	END
	--返销
	IF @Formid IN (9244) and @dptType = '加盟店'
	BEGIN
		SELECT @SeriesCode=seriescode,@simseriescode=simcode
		FROM NumberAllocation_Log a WITH(NOLOCK)
		WHERE a.Doccode=@refcode
	    UPDATE c
	    SET    salemun = 0,
	    c.[state] = '应收',
	    isbg=0,
	    c.isava = 0,
	    c.Occupyed = 0,
	    c.OccupyedDoc = null
	    FROM   iseries c with(nolock)
	    WHERE    seriescode in( isnull( @seriescode,''),isnull(@simseriescode,''))
	END
END