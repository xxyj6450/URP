/*
declare @doccode varchar(50)
declare @curcode integer
declare @codeflag varchar(10)
declare @codelength integer,@strDate varchar(50)

exec sp_newdoccode 2419,'',@doccode output

select @doccode


select * from gformCode where formid=2419
select @codeflag='RK',@strDate='20050109',@codelength=16,@curcode=104


--update gformCode set curcode=101 where formid=2419 and gdocdate='20050109'



  select @doccode = @codeflag + @strDate + substring('00000000000000000',1,
    @codelength-len(@codeflag)-len(@strDate)-len(cast(@curcode as varchar)))+
    cast(@curcode as varchar)

select @doccode

*/
--增加起始值和步长,可以由多台服务器分布式控制单号,而且不会重复. 2012-08-23 三断笛
/*
declare @Doccode varchar(30)
exec [sp_newdoccode] 2420,'',@Doccode output
print @Doccode


*/
ALTER PROCEDURE [dbo].[sp_newdoccode]
	@formid formid,
	@opid orgcode,
	@doccode varchar(50) OUTPUT,
	@baseDigit INT = 0 --新增BaseDigit参数,可以从指定的指定的基数起生成编号
AS
	DECLARE @curcode integer
	DECLARE @codeflag varchar(10)
	DECLARE @codelength integer
	--定义起始值和步长
	declare @StartNumber int,@Step int
	select @StartNumber=1,@Step=100
	--select  convert(datetime,convert ( varchar(10),getdate()))
	
	SELECT @codeflag = codeflag,@codelength = isnull(codelength,0),@curcode = curcode
	FROM   gdoctype
	WHERE  formid = @formid
	
	IF @@rowcount = 0
	BEGIN
	    raiserror ('未发现规定的功能号',16,1)
	    return
	END
	
	DECLARE @strY varchar(4)
	DECLARE @strM varchar(2)
	DECLARE @strD varchar(2)
	DECLARE @strDate varchar(8)
	
	SELECT @strY = convert(char(4),datepart(yyyy,getdate())) 
	SELECT @strM = convert(char(2),datepart(month,getdate())) 
	IF len(@strM) = 1
	    SELECT @strM = '0' + @strM
	
	SELECT @strD = convert(char(2),datepart(day,getdate())) 
	IF len(@strD) = 1
	    SELECT @strD = '0' + @strD
	
	IF @formid = 4401
	    SELECT @strDate = @strY + @strM + '00'
	ELSE  
	IF @formid <> 4401
	    SELECT @strDate = @strY + @strM + @strD
	--if @codelength = 0 
	
	SELECT @codelength = 20								--长度加长到20位
	
	--取出当前的序列号,若为空则取起始值.
	SELECT @curcode = isnull(curcode,0)					--此处若当前值为NULL,则修改为起始值,而非1
	FROM   gformCode with (updlock)
	WHERE  formid = @formid
	       AND gdocdate = @strDate
	       
	--正面将最新的序列号值写入记录表
	IF @@rowcount = 0
		begin
			--若当前日期没有单据号记录,则插入起始值.注意新插入的值要增加基础值baseDigit
			INSERT into gformCode( formid, curcode, gdocdate)
			VALUES(@formid,@StartNumber+ISNULL(@basedigit,0),@strDate )
			--当前值为初始值
			select @curcode=@StartNumber+ISNULL(@basedigit,0)
		end
	ELSE
		begin
			--若当日已存在单据号,则按步长增加.注意此处不要再加基数值BaseDigit
			UPDATE gformCode
			SET    curcode = curcode + @Step							--按步长增加
			WHERE  formid = @formid
				   AND gdocdate = @strDate
			--此时再获取本次应获取的序列号值,为前一个序列号值+step.
			SELECT @curcode = isnull(@curcode,@StartNumber)   + @Step
		end
	
	SELECT @doccode = @codeflag + @strDate + substring('000000000000000000000',1,
	        @codelength -len(@codeflag) -len(@strDate) -len(cast(@curcode as varchar))
	       ) +
	       cast(@curcode as varchar)
	
	--售后维修单单号处理,同上
	IF exists(SELECT 1
	          FROM   gdoctype
	          WHERE  formid = 1562
	                 AND formid = @formid
	   )
	BEGIN
	    SELECT @codelength = 15
	    SELECT @curcode = isnull(curcode,0)
	    FROM   gformCode with (updlock)
	    WHERE  formid = @formid
	           AND gdocdate = @strDate
	    
	    IF @@rowcount = 0
			BEGIN
				INSERT into gformCode( formid, curcode, gdocdate)
				VALUES(@formid,@StartNumber+ISNULL(@basedigit,0),@strDate )
				select @curcode=@StartNumber+ISNULL(@basedigit,0)
			END
	        
	    ELSE
	    	BEGIN
	    		UPDATE gformCode
					SET    curcode = curcode + @Step
					WHERE  formid = @formid
						   AND gdocdate = @strDate
				SELECT @curcode = isnull(@curcode,@StartNumber) + @Step
	    	END
	        
	    
	    
	    SELECT @doccode = @codeflag + @strDate + substring(
	            '000000000000000000000',1,@codelength -len(@codeflag) -len(@strDate) -len(cast(@curcode as varchar))
	           ) +
	           cast(@curcode as varchar)
	END                             