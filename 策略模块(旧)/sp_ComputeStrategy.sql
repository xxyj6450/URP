/*
过程名称：sp_ComputeStrategy
功能：策略处理接口
参数：见声名
返回：
编写：三断笛
时间：2012-02-18
备注：
示例：
----------------------------------------------
*/
ALTER PROC [sp_ComputeStrategy]
	@FormID varchar(20),
	@Doccode VARCHAR(20),
	@FieldFormID varchar(50)='',	--字段映射功能号
	@StrategyGroup VARCHAR(20),
	@OutputFields VARCHAR(500)='',	--输出的字段
	@StrategyCode VARCHAR(20)='',
	@RowFlag VARCHAR(50)='',
	@Optionid VARCHAR(100)='',
	@UserCode VARCHAR(50)='',
	@TerminalID VARCHAR(50)='',
	@Result XML=''
AS
	BEGIN
		SET NOCOUNT ON;
		DECLARE @sql VARCHAR(4000),@Filter VARCHAR(max),@tips varchar(max)
		--拼装活动行,当单据明细中有多行,而需要逐行计算时,需要在动态表达式的Filter参数中确定活动行.
		--在本模块中,唯一行(@Rowflag)参数即为活动行.
		--但每次调用本模块的唯一行标志并不确定,故采用动态SQL方式执行.
		--若看不明白此动态SQL的写法,可以参考下面的固定SQL写法.
		--另外要注意在动态表达式中使用活动行与直接在数据源中过程的区别.具体请参阅动态表达式说明文档.
 		IF ISNULL(@RowFlag,'')=''
 			begin
 				set @Filter=''
 			end
 		ELSE
 			BEGIN
 				--注意理解此处的单引号数量
 				SET @Filter=''''+isnull(@RowFlag,'')+'=''''''+a.DocRowFlag+'''''''''
 			end
		SET @sql = 'Update a ' + char(10)
				 + '	set StrategyValue=dbo.ExecuteScalar(0,StrategyValueExpression, ''Select * From #DataSource b'''
				 + '	,'+@Filter+',-1,''Select * from fn_getFormulaFields('''''  
				 + 		convert(varchar(50),COALESCE(@FieldFormID,@FormID,''))+''''')'',0) ' + char(10)
				 + 'From #Strategy a ' + char(10)
				 + 'WHERE ISNULL(StrategyValueExpression,'''')<>'''''
		begin try
			
			EXEC(@sql)
		end try
		begin catch
			select @tips='执行策略'+isnull(@StrategyCode,'')+'计算失败!'+@RowFlag +dbo.crlf()+error_Message()+dbo.crlf()+@sql
			/*--记录数据
			insert into StrategyErrorLog
			Select @Strategygroup,a.*,'执行策略计算失败!',@sql,error_Message(),error_line(),error_procedure(),getdate()
			from #Strategy a
			 --select * from StrategyErrorLog
			 --delete StrategyErrorLog*/
			--抛出异常
			raiserror(@tips,16,1)
			return
		end catch
		--以下是活动行固定为RowID时的SQL写法,供参考.
		/*
		Update a 
			set StratetyValue=dbo.ExecuteScalar(0,StratetyValueExpression, 'Select * From #DataSource','RowID='''+a.RowID+'''',-1,'Select * from fn_getFormulaFields(''9146,2801'')',0) 
		from #Strategy a 
		WHERE ISNULL(StratetyValueExpression,'')<>''*/
 
		Return
	END
