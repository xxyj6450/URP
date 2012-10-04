/*
��������:sp_quickChangeSIMStatus
����:�����޸�SIM��״̬,��Ҫ�û���֤
����:������
����ֵ:��
��д:���ϵ�
ʱ��:2012-01-3-
ʾ��:
��ע:
set xact_abort on
begin tran
exec  [sp_quickChangeSIMStatus] '89860112851077562082',1,'SYSTEM','','',''
commit
rollback
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
		set XACT_ABORT on;
		DECLARE @tranCount INT,@msg VARCHAR(2000),@sql nvarchar(max),@Fields nvarchar(max),@Option varchar(2000),@FormID int,@doccode varchar(30),@AreaID varchar(20)
		DECLARE @Table table(ICCID VARCHAR(30),SeriesCode VARCHAR(30),SeriesNumber VARCHAR(20),Doccode VARCHAR(20),Formid INT,Formtype INT,NewValue bit)
		select @Fields='Remark,isValid,isWriteen,isActived,isLocked,BusiType,'+
		+'CardType,ProcID,BipCode,Brand,City,Inrecords,OptionID,IMSI_SAFE,IMSI,FormID,Doccode,USIM,SeriesNumber,SeriesCode,Status,ICCID'
		--��У���û�
		IF dbo.fn_CheckUserLogin(@UserCode,@Password,7,@TerminalID,'','')<>1 and @Usercode<>'SYSTEM'
			BEGIN
				SELECT @msg=dbo.crlf()+'�û�У��ʧ��,������!'
				RAISERROR(@msg,16,1)
				return
			END
		--��������
		SELECT @tranCount=@@TRANCOUNT
		BEGIN try
			--�޸�����״̬
			IF @Status=1
				begin
					UPDATE iSIMInfo
						SET	isLocked =ISNULL(isLocked,0)^1
						OUTPUT DELETED.ICCID,DELETED.SeriesCode,DELETED.SeriesNumber,DELETED.Doccode,DELETED.FormID,5,INSERTED.isLocked INTO @table
					WHERE ICCID=@ICCID
					INSERT INTO iSIMInfo_Log(SeriesCode,ICCID,USIM,[Event],EventTime,TerminerID,Sdgroup,SeriesNumber,Remark,doccode,Formid,Formtype)
					SELECT seriescode,iccid,iccid,'�޸�����״̬',getdate(),@terminalID,@usercode,SeriesNumber,
					isnull(@remark,'')+'״̬�޸���'+CONVERT(Varchar(3),newvalue),doccode,Formid,Formtype From @Table
					--ͬʱ��������������Ϣ
					/*Update OpenQuery(URP11,'Select isLocked From JTURP.dbo.iSIMInfo Where ICCID='''+@ICCID+'''')
					set isLocked=ISNULL(isLocked,0)^1
					*/
					set xact_abort on;
					SET @sql = 'Update OpenQuery(URP11,''Select isLocked From JTURP.dbo.iSIMInfo  Where ICCID='''''+@ICCID+''''''') ' + char(10)
							 + '					set isLocked=ISNULL(isLocked,0)^1'
					exec sp_executesql @sql
					if @@ROWCOUNT=0
						BEGIN
							Select @sql='Insert into OpenQuery(URP11,''Select '+@Fields+' From  JTURP.dbo.iSIMInfo  '')'+Char(10)+
							'SELECT '+@Fields +' From iSIMInfo with(nolock) Where ICCID='''+@ICCID+''''
							Exec sp_executesql @sql
						END

				END
			--�޸ļ���״̬
			IF @Status=2
				begin
					UPDATE iSIMInfo
						SET  
						isActived =ISNULL(isActived,0)^1
						OUTPUT DELETED.ICCID,DELETED.SeriesCode,DELETED.SeriesNumber,DELETED.Doccode,DELETED.FormID,5,INSERTED.isLocked INTO @table
					WHERE ICCID=@ICCID
					INSERT INTO iSIMInfo_Log(SeriesCode,ICCID,USIM,[Event],EventTime,TerminerID,Sdgroup,SeriesNumber,Remark,doccode,Formid,Formtype)
					SELECT seriescode,iccid,iccid,'�޸ļ���״̬',getdate(),@terminalID,@usercode,SeriesNumber,
					isnull(@remark,'')+'״̬�޸���'+CONVERT(Varchar(3),newvalue),doccode,Formid,Formtype From @Table
					--ͬʱ�޸���������SIM����Ϣ
					set xact_abort on;
					SET @sql = 'Update OpenQuery(URP11,''Select isActived From JTURP.dbo.iSIMInfo with(nolock) Where ICCID='''''+@ICCID+''''''') ' + char(10)
							 + '					set isActived=ISNULL(isActived,0)^1'
					exec sp_executesql @sql
					if @@ROWCOUNT=0
						BEGIN
							Select @sql='Insert into OpenQuery(URP11,''Select '+@Fields+' From  JTURP.dbo.iSIMInfo with(nolock)'')'+Char(10)+
							'SELECT '+@Fields +' From iSIMInfo with(nolock) Where ICCID='''+@ICCID+''''
							Exec sp_executesql @sql
						END
				END
			--�޸���д״̬
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
					SELECT seriescode,iccid,iccid,'�޸�д��״̬',getdate(),@terminalID,@usercode,SeriesNumber,
					isnull(@remark,'')+'״̬�޸���'+CONVERT(Varchar(3),newvalue),doccode,Formid,Formtype From @Table
					--ͬʱ�޸���������SIM����Ϣ
					set xact_abort on;
					SET @sql = 'Update OpenQuery(URP11,''Select isWriteen,WritenDate From JTURP.dbo.iSIMInfo with(nolock) Where ICCID='''''+@ICCID+''''''') ' + char(10)
							 + '					set isActived=ISNULL(isWriteen,0)^1,WritenDate=getdate()'
					exec sp_executesql @sql
					if @@ROWCOUNT=0
						BEGIN
							Select @sql='Insert into OpenQuery(URP11,''Select '+@Fields+' From  JTURP.dbo.iSIMInfo  with(nolock)'')'+Char(10)+
							'SELECT '+@Fields +' From iSIMInfo  with(nolock) Where ICCID='''+@ICCID+''''
							Exec sp_executesql @sql
						END
				END
			--�޸�����״̬
			IF @Status=4
				begin
					UPDATE iSIMInfo
						SET  isValid =ISNULL(isValid,0)^1
					OUTPUT DELETED.ICCID,DELETED.SeriesCode,DELETED.SeriesNumber,DELETED.Doccode,DELETED.FormID,5,INSERTED.isLocked  INTO @table
					WHERE ICCID=@ICCID
					INSERT INTO iSIMInfo_Log(SeriesCode,ICCID,USIM,[Event],EventTime,TerminerID,Sdgroup,SeriesNumber,Remark,Doccode,Formid,FormType)
					SELECT seriescode,iccid,iccid,'�޸�����״̬',getdate(),@terminalID,@usercode,SeriesNumber,
					isnull(@remark,'')+'״̬�޸���'+CONVERT(Varchar(3),newvalue),doccode,Formid,Formtype From @Table
					--ͬʱ�޸���������SIM����Ϣ
					set xact_abort on;
					SET @sql = 'Update OpenQuery(URP11,''Select isValid From JTURP.dbo.iSIMInfo  with(nolock) Where ICCID='''''+@ICCID+''''''') ' + char(10)
							 + '					set isActived=ISNULL(isValid,0)^1'
					exec sp_executesql @sql
					if @@ROWCOUNT=0
						BEGIN
							Select @sql='Insert into OpenQuery(URP11,''Select '+@Fields+' From  JTURP.dbo.iSIMInfo with(nolock)'')'+Char(10)+
							'SELECT '+@Fields +' From iSIMInfo with(nolock) Where ICCID='''+@ICCID+''''
							Exec sp_executesql @sql
						END
				END
			--ɾ��SIM��
			IF @Status=5
				BEGIN
					SELECT * FROM iSIMInfo is1 WHERE is1.SeriesCode='8986011288600416683'
					--��SIM���Ѿ�������,������ɾ��
					IF EXISTS(SELECT 1 FROM iSIMInfo is1 WHERE ISNULL(is1.IMSI_SAFE,'')!='' AND is1.ICCID=@ICCID) AND @UserCode!='SYSTEM'
						BEGIN
							RAISERROR('��SIM���Ѿ�������,������ɾ��!',16,1)
							return
						END
					DELETE FROM iSIMInfo
					OUTPUT DELETED.ICCID,DELETED.SeriesCode,DELETED.SeriesNumber,DELETED.Doccode,DELETED.FormID,5,deleted.isLocked  INTO @table
					WHERE ICCID=@ICCID
					INSERT INTO iSIMInfo_Log(SeriesCode,ICCID,USIM,[Event],EventTime,TerminerID,Sdgroup,SeriesNumber,Remark,Doccode,Formid,FormType)
					SELECT seriescode,iccid,iccid,'ɾ��SIM��',getdate(),@terminalID,@usercode,SeriesNumber,
					isnull(@remark,'')+'ɾ��SIM��'+CONVERT(Varchar(3),newvalue),doccode,Formid,Formtype From @Table
				END
			--��յ�����Ϣ
			IF @Status=6
				begin
					update iSIMInfo
					SET doccode=NULL,
					FormID=NULL
					OUTPUT DELETED.ICCID,DELETED.SeriesCode,DELETED.SeriesNumber,DELETED.Doccode,DELETED.FormID,5,inserted.isLocked  INTO @table
					WHERE ICCID=@ICCID
					INSERT INTO iSIMInfo_Log(SeriesCode,ICCID,USIM,[Event],EventTime,TerminerID,Sdgroup,SeriesNumber,Remark,Doccode,Formid,FormType)
					SELECT seriescode,iccid,iccid,'���SIM����Ϣ',getdate(),@terminalID,@usercode,SeriesNumber,
					isnull(@remark,'')+'���SIM����Ϣ'+CONVERT(Varchar(3),newvalue),doccode,Formid,Formtype From @Table
				END
				--����IMSI��Ϣ
				IF @Status=7
					begin
						if len(isnull(@remark,''))<>15
							begin
								raiserror('���ڱ�ע��¼����ȷ��IMSI��Ϣ.',16,1)
								return
							end
					select @FormID=formid ,@doccode=doccode,@option=optionid from isiminfo with(nolock) where iccid=@ICCID
					if @@ROWCOUNT=0
						BEGIN
							raiserror('SIM��������!',16,1)
							return
						END
					if isnull(@doccode,'')=''
						BEGIN
							raiserror('��SIM���޵�����Ϣ,�޷�����IMSI����.',16,1)
							return
						END
					if isnull(@FormID,0)=0
						BEGIN
							raiserror('��SIM����ҵ��������Ϣ,�޷�����IMSI����.',16,1)
							return
						END
					if isnull(@option,'')=''
						BEGIN
							if @FormID=9158
								BEGIN
									select @areaID=left(os.SDOrgID,3) from BusinessAcceptance_H bah with(nolock),oSDOrg os with(nolock) where bah.docCode=@doccode and os.SDOrgID=bah.SdorgID
								END
								if @FormID in(9102,9146,9237)
								BEGIN
									select @areaID=left(os.SDOrgID,3) from Unicom_Orders bah with(nolock),oSDOrg os with(nolock) where bah.docCode=@doccode and os.SDOrgID=bah.SdorgID
								END
								select @option=isi.OptionID
								  from iSIMOptionInfo isi where isi.AreaID=@areaID
						END
						update iSIMInfo
						SET IMSI = @remark,
						OptionID = @Option
						OUTPUT DELETED.ICCID,DELETED.SeriesCode,DELETED.SeriesNumber,DELETED.Doccode,DELETED.FormID,5,inserted.isLocked  INTO @table
						WHERE ICCID=@ICCID
						INSERT INTO iSIMInfo_Log(SeriesCode,ICCID,USIM,[Event],EventTime,TerminerID,Sdgroup,SeriesNumber,Remark,Doccode,Formid,FormType)
						SELECT seriescode,iccid,iccid,'����SIM����Ϣ',getdate(),@terminalID,@usercode,SeriesNumber,
						isnull(@remark,'')+'����SIM����Ϣ'+CONVERT(Varchar(3),newvalue),doccode,Formid,Formtype From @Table
						--ͬʱ�޸���������SIM����Ϣ
						set xact_abort on;
						SET @sql = 'Update OpenQuery(URP11,''Select IMSI,OptionID From JTURP.dbo.iSIMInfo  with(nolock) Where ICCID='''''+@ICCID+''''''') ' + char(10)
								 + '					set IMSI='''+@remark +''',OptionID='''+@Option+''''
						exec sp_executesql @sql
						if @@ROWCOUNT=0
						BEGIN
							Select @sql='Insert into OpenQuery(URP11,''Select '+@Fields+' From  JTURP.dbo.iSIMInfo with(nolock)'')'+Char(10)+
							'SELECT '+@Fields +' From iSIMInfo with(nolock) Where ICCID='''+@ICCID+''''
							Exec sp_executesql @sql
						END
					END
 
			END try
			--���󲶻�
			BEGIN CATCH
				--�׳��쳣
				SELECT @msg='����ʧ��!'+dbo.crlf()+
				ERROR_MESSAGE()+dbo.crlf()
				RAISERROR(@msg,16,1)
				return
				
			END catch
			return
	END