/*
��������:sp_quickUpdateSeriescode
����:������
����:���´�����Ϣ
��д:���ϵ�
ʱ��:2012-09-05
��ע:
*/
alter proc sp_quickUpdateSeriescode
	@Seriescode varchar(50),									--����
	@OptionID varchar(200),									--����
	@Usercode varchar(50),										--�û�����
	@Password varchar(50),										--����
	@mParam varchar(200),										--����1
	@lParam varchar(200),										--����2
	@Remark varchar(500),										--��ע
	@TerminalID varchar(50)									--�ն˱���
as
	BEGIN
		set nocount on;
		--����
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
	
	