/*
�������ƣ�[sp_OutputStrategy_Score]
���ܣ����Դ���ӿ�
������������
���أ�
��д�����ϵ�
ʱ�䣺2012-02-18
��ע��
ʾ����
----------------------------------------------
*/
create PROC [dbo].[sp_OutputStrategy_Score]	
	@FormID varchar(50),
	@Doccode VARCHAR(20),
	@FieldFormID varchar(10)='',	--�ֶ�ӳ�书�ܺ�
	@StrategyGroup VARCHAR(20),		--������
	@ComputeType VARCHAR(50)='',	--�������ͣ��ۼӣ�����
	@OutputType VARCHAR(50)='',		--������ͣ���ʾ��д���ݱ�
	@OutputTable VARCHAR(50)='',	--�����
	@OutputFields VARCHAR(500)='',	--������ֶ�
	@RowFlag VARCHAR(100)='',		--������ݵ��б�־������������Դ��ƥ��
	@StrategyCode VARCHAR(20)='',	--���Ա���
	@Optionid VARCHAR(100)='',		--��չѡ��
	@UserCode VARCHAR(50)='',		--ִ����
	@TerminalID VARCHAR(50)='',		--ִ���ն�
	@Result varchar(max)=NULL output			--����ֵ
AS
	BEGIN
		SET NOCOUNT ON;
		DECLARE @sql VARCHAR(8000),@tips varchar(max)
		--����ԭ���ֽӿڽ������
		 exec sp_OutputStrategy @FormID,@Doccode,@FieldFormID,@StrategyGroup,@ComputeType,@OutputType,@OutputTable,@OutputFields,@RowFlag,@StrategyCode,@Optionid,@UserCode,@TerminalID,@Result output
		 --���������������ϸ��
		 update a 
			set Score =convert(money, b.StrategyValue) 
		 from ScoreLedgerLog a,#strategy b,#DataSource c
		 where a.Doccode=@Doccode
		 and b.docRowFlag=c.rowid
		 and a.Matcode=c.matcode
		 and a.Doccode=c.doccode
		return
	END
	
