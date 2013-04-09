/*
��������:sp_BatchPostDoc
����:ȷ�ϵ���
����:������
����:������
��д:���ϵ�
ʱ��:2012-01-15
��ע:������������ȷ�ϵ���.����Ҫȷ��47�������ϵĺ�̨���ȷ����Ѿ�����
ȷ��ǰ�����ȼ�鵥��,��Ϊ�Զ�ȷ�ϲ���ִ�е��ݼ��
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
			--����ȷ�ϼ��
			IF @FormID IN(9102,9146,9153,9158,8159,9160,9165,9167,9180,9752,9755,9267)
				BEGIN
					
					SELECT @Msg=dbo.crlf()+'����'+@Doccode+'δ��ͨ�����ݼ��,���ֹ�ȷ��!'
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
			--д������ϸ��
			exec SetFsubLedger @Doccode,@FormID,'1001',@Docdate,'',@Periodid
			--�����ݲ����Զ�ȷ���б�
			INSERT INTO gtaskdocpost(FormID,Doccode,Usercode,formtype,docmemo,terminalid)
			SELECT @FormID,@Doccode,@UserCode,@FormType,@Remark,@TerminalId
		END