/*
过程名称:sp_quickChangeSIMStatus
功能:快速修改SIM卡状态,需要用户验证
参数:见声名
返回值:无
编写:三断笛
时间:2012-01-3-
示例:
备注:

*/
ALTER PROC [sp_quickChangeSIMStatus]
	@ICCID VARCHAR(30),
	@Status INT=0,
	@UserCode VARCHAR(50),
	@Password VARCHAR(200),
	@TerminalID VARCHAR(50),
	@remark VARCHAR(500)=''
AS
	BEGIN
		SET NOCOUNT ON;
		DECLARE @tranCount INT,@msg VARCHAR(2000),@areaID varchar(10),@option varchar(2000),@FormID int,@doccode varchar(30)
		DECLARE @Table table(ICCID VARCHAR(30),SeriesCode VARCHAR(30),SeriesNumber VARCHAR(20),Doccode VARCHAR(20),Formid INT,Formtype INT,NewValue bit)
		--先校验用户
		IF dbo.fn_CheckUserLogin(@UserCode,@Password,7,@TerminalID,'','')<>1
			BEGIN
				SELECT @msg=dbo.crlf()+'用户校验失败,请重试!'
				RAISERROR(@msg,16,1)
				return
			END
		--调整隔离级别
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED
		--开启事务
		SELECT @tranCount=@@TRANCOUNT
		IF @tranCount=0
			BEGIN TRAN
 
		BEGIN try
			--修改锁定状态
			IF @Status=1
				begin
					UPDATE iSIMInfo
						SET	isLocked =ISNULL(isLocked,0)^1
						OUTPUT DELETED.ICCID,DELETED.SeriesCode,DELETED.SeriesNumber,DELETED.Doccode,DELETED.FormID,5,INSERTED.isLocked INTO @table
					WHERE ICCID=@ICCID
					INSERT INTO iSIMInfo_Log(SeriesCode,ICCID,USIM,[Event],EventTime,TerminerID,Sdgroup,SeriesNumber,Remark,doccode,Formid,Formtype)
					SELECT seriescode,iccid,iccid,'修改锁定状态',getdate(),@terminalID,@usercode,SeriesNumber,
					isnull(@remark,'')+'状态修改至'+CONVERT(Varchar(3),newvalue),doccode,Formid,Formtype From @Table
				END
			--修改激活状态
			IF @Status=2
				begin
					UPDATE iSIMInfo
						SET  
						isActived =ISNULL(isActived,0)^1
						OUTPUT DELETED.ICCID,DELETED.SeriesCode,DELETED.SeriesNumber,DELETED.Doccode,DELETED.FormID,5,INSERTED.isLocked INTO @table
					WHERE ICCID=@ICCID
					INSERT INTO iSIMInfo_Log(SeriesCode,ICCID,USIM,[Event],EventTime,TerminerID,Sdgroup,SeriesNumber,Remark,doccode,Formid,Formtype)
					SELECT seriescode,iccid,iccid,'修改激活状态',getdate(),@terminalID,@usercode,SeriesNumber,
					isnull(@remark,'')+'状态修改至'+CONVERT(Varchar(3),newvalue),doccode,Formid,Formtype From @Table
				END
			--修改已写状态
			IF @Status=3
				begin
					UPDATE iSIMInfo
						SET  
						isWriteen =ISNULL(isWriteen,0)^1,
						WritenDate = GETDATE(),
						WriteenCount = ISNULL(WriteenCount,0)+1
					OUTPUT DELETED.ICCID,DELETED.SeriesCode,DELETED.SeriesNumber,DELETED.Doccode,DELETED.FormID,5,INSERTED.isLocked  INTO @table
					WHERE ICCID=@ICCID
					INSERT INTO iSIMInfo_Log(SeriesCode,ICCID,USIM,[Event],EventTime,TerminerID,Sdgroup,SeriesNumber,Remark,doccode,Formid,Formtype)
					SELECT seriescode,iccid,iccid,'修改写卡状态',getdate(),@terminalID,@usercode,SeriesNumber,
					isnull(@remark,'')+'状态修改至'+CONVERT(Varchar(3),newvalue),doccode,Formid,Formtype From @Table
				END
			--修改作废状态
			IF @Status=4
				begin
					UPDATE iSIMInfo
						SET  isValid =ISNULL(isValid,0)^1
					OUTPUT DELETED.ICCID,DELETED.SeriesCode,DELETED.SeriesNumber,DELETED.Doccode,DELETED.FormID,5,INSERTED.isLocked  INTO @table
					WHERE ICCID=@ICCID
					INSERT INTO iSIMInfo_Log(SeriesCode,ICCID,USIM,[Event],EventTime,TerminerID,Sdgroup,SeriesNumber,Remark,Doccode,Formid,FormType)
					SELECT seriescode,iccid,iccid,'修改作废状态',getdate(),@terminalID,@usercode,SeriesNumber,
					isnull(@remark,'')+'状态修改至'+CONVERT(Varchar(3),newvalue),doccode,Formid,Formtype From @Table
				END
			--删除SIM卡
			IF @Status=5
				BEGIN
					SELECT * FROM iSIMInfo is1 WHERE is1.SeriesCode='8986011288600416683'
					--若SIM卡已经有数据,则不允许删除
					IF EXISTS(SELECT 1 FROM iSIMInfo is1 WHERE ISNULL(is1.IMSI_SAFE,'')!='' AND is1.ICCID=@ICCID) AND @UserCode!='SYSTEM'
						BEGIN
							RAISERROR('该SIM卡已经有数据,不允许删除!',16,1)
							return
						END
					DELETE FROM iSIMInfo
					OUTPUT DELETED.ICCID,DELETED.SeriesCode,DELETED.SeriesNumber,DELETED.Doccode,DELETED.FormID,5,deleted.isLocked  INTO @table
					WHERE ICCID=@ICCID
					INSERT INTO iSIMInfo_Log(SeriesCode,ICCID,USIM,[Event],EventTime,TerminerID,Sdgroup,SeriesNumber,Remark,Doccode,Formid,FormType)
					SELECT seriescode,iccid,iccid,'删除SIM卡',getdate(),@terminalID,@usercode,SeriesNumber,
					isnull(@remark,'')+'删除SIM卡'+CONVERT(Varchar(3),newvalue),doccode,Formid,Formtype From @Table
				END
			--清空单据信息
			IF @Status=6
				begin
					
					update iSIMInfo
					SET doccode=NULL,
					FormID=NULL,
					SeriesNumber = NULL,
					isLocked = 0,
					isActived = 0
					OUTPUT DELETED.ICCID,DELETED.SeriesCode,DELETED.SeriesNumber,DELETED.Doccode,DELETED.FormID,5,inserted.isLocked  INTO @table
					WHERE ICCID=@ICCID
					INSERT INTO iSIMInfo_Log(SeriesCode,ICCID,USIM,[Event],EventTime,TerminerID,Sdgroup,SeriesNumber,Remark,Doccode,Formid,FormType)
					SELECT seriescode,iccid,iccid,'清空SIM卡信息',getdate(),@terminalID,@usercode,SeriesNumber,
					isnull(@remark,'')+'清空SIM卡信息'+CONVERT(Varchar(3),newvalue),doccode,Formid,Formtype From @Table
				END
			--加入IMSI信息
			IF @Status=7
				begin
					if len(isnull(@remark,''))<>15
						begin
							raiserror('请在备注处录入正确的IMSI信息.',16,1)
							return
						end
					select @FormID=formid ,@doccode=doccode,@option=optionid from isiminfo with(nolock) where iccid=@ICCID
					if @@ROWCOUNT=0
						BEGIN
							raiserror('SIM卡不存在!',16,1)
							return
						END
					if isnull(@doccode,'')=''
						BEGIN
							raiserror('该SIM卡无单据信息,无法更新IMSI数据.',16,1)
							return
						END
					if isnull(@FormID,0)=0
						BEGIN
							raiserror('该SIM卡无业务类型信息,无法更新IMSI数据.',16,1)
							return
						END
					if isnull(@option,'')=''
						BEGIN
							if @FormID=9158
								BEGIN
									select @areaID=left(os.areaid,3) from BusinessAcceptance_H bah with(nolock),oSDOrg os with(nolock) where bah.docCode=@doccode and os.SDOrgID=bah.SdorgID
								END
								if @FormID in(9102,9146,9237)
								BEGIN
									select @areaID=left(os.areaid,3) from Unicom_Orders bah with(nolock),oSDOrg os with(nolock) where bah.docCode=@doccode and os.SDOrgID=bah.SdorgID
								END
								select @option=isi.OptionID
								  from iSIMOptionInfo isi where isi.AreaID=@areaID
						END
					
					update iSIMInfo
					SET IMSI = @remark,
					OptionID = @option
					OUTPUT DELETED.ICCID,DELETED.SeriesCode,DELETED.SeriesNumber,DELETED.Doccode,DELETED.FormID,5,inserted.isLocked  INTO @table
					WHERE ICCID=@ICCID
					INSERT INTO iSIMInfo_Log(SeriesCode,ICCID,USIM,[Event],EventTime,TerminerID,Sdgroup,SeriesNumber,Remark,Doccode,Formid,FormType)
					SELECT seriescode,iccid,iccid,'补充SIM卡信息',getdate(),@terminalID,@usercode,SeriesNumber,
					isnull(@remark,'')+'补充SIM卡信息'+CONVERT(Varchar(3),newvalue),doccode,Formid,Formtype From @Table
				END
				IF @tranCount=0 COMMIT
			END try
			--错误捕获
			BEGIN CATCH
				--回滚事务
				IF @tranCount=0
					ROLLBACK
 
				--抛出异常
				SELECT @msg='操作失败!'+dbo.crlf()+
				ERROR_MESSAGE()+dbo.crlf()
				RAISERROR(@msg,16,1)
				return
				
			END catch
			return
	END