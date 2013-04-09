/*
函数名称:sp_BatchPostDoc
功能:确认单据
参数:见声名
返回:见声名
编写:三断笛
时间:2012-01-15
备注:可以用于批量确认单据.但是要确认47服务器上的后台调度服务已经开启
确认前必须先检查单据,因为自动确认不会执行单据检查
*/
	alter PROC sp_BatchPostDoc
		@FormID INT,
		@Doccode VARCHAR(50),
		@UserCode VARCHAR(50),
		@FormType INT,
		@Remark VARCHAR(200)='',
		@TerminalId VARCHAR(50)=''
	AS
		BEGIN
			SET NOCOUNT ON;
			DECLARE @Msg VARCHAR(5000),@Docdate datetime,@Periodid varchar(7)
			SELECT @Msg=''
			--单据确认检查
			IF @FormID IN(9102,9146,9153,9158,8159,9160,9165,9167,9180,9752,9755,9267)
				BEGIN
					
					SELECT @Msg=dbo.crlf()+'单据'+@Doccode+'未能通过单据检查,请手工确认!'
					SELECT @Msg =@msg+dbo.crlf()+convert(varchar(5),row_number() over (ORDER BY x.errorflag))+'.'+x.infomessage
					FROM dbo.fn_checkAllocationDoc(@FormID,@Doccode) x
					WHERE x.errorflag=1
					IF @@ROWCOUNT>0
						begin
							RAISERROR(@msg,16,1)
							RETURN
						END
				END
			select @Docdate=convert(varchar(10),getdate(),120),@Periodid=convert(varchar(7),getdate(),120)
			--写子账明细账
			exec SetFsubLedger @Doccode,@FormID,'1001',@Docdate,'',@Periodid
			--将单据插入自动确认列表
			INSERT INTO gtaskdocpost(FormID,Doccode,Usercode,formtype,docmemo,terminalid)
			SELECT @FormID,@Doccode,@UserCode,@FormType,@Remark,@TerminalId
		END