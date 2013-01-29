/*
�������ƣ�sp_LogStock_matledger_Seriescode
������������¼ÿ�տ�棬������ɱ���־
������������
����ֵ��
��д�����ϵ�
ʱ�䣺2013-1-25
��ע��
ʾ����exec sp_LogStock_matledger_Seriescode '2012-01-02','1.1.769.11.01'
select * from rj_iSeriesLog where sdorgid='1.1.769.11.01'
select *from rj_matStorageLog  where sdorgid='1.1.769.11.01'
select * from rj_MatsdorgLedgerLog  where sdorgid='1.1.769.11.01'
*/
alter proc sp_LogStock_matledger_Seriescode
	@baldate datetime,
	@sdorgid varchar(50)='',
	@plantID varchar(10)='',
	@optionID int=0,						--ѡ���,Ĭ�ϴ�0,1:ˢ�´���,2:ˢ�¿��,4:ˢ�³ɱ�,Ҳ�����⼸��������ĺ�����Ͽ���
	@usercode varchar(50)='',
	@TerminalID varchar(50)=''
as
	BEGIN
		set NOCOUNT ON
		declare @tips varchar(max),@trancount int
		--������ڲ���
		if isdate(@baldate)=0
			BEGIN
				raiserror('��������ڲ�������ȷ�����ڸ�ʽ�������ԡ�',16,1)
				return
			END
		--��ʽ������
		select @baldate=convert(datetime,convert(varchar(10),@baldate,120))
		--��¼������Ϣ
		select @trancount=@@TRANCOUNT
		if @trancount=0
				begin TRAN
		else
			save tran tran1
		begin try
			--���ż�¼����ɾ�����еģ��ٲ���
			if @optionID=0 or @optionID&1=1
				BEGIN
					--����ˢ�����һ������ݣ���ֹˢ����ǰ��
					if exists(select 1 from rj_iSeriesLog a with(nolock) 
					          where baldate>@baldate 
								and  (@sdorgid='' or  sdorgid=@sdorgid)
								and (@plantID='' or plantid=@plantID)
					)
					BEGIN
						raiserror('��ֹ����������ݣ����ܶ��������ݽ��в���.',16,1)
						return
					END
					delete from rj_iSeriesLog 
					where baldate=@baldate 
					and  (@sdorgid='' or  sdorgid=@sdorgid)
					and (@plantID='' or plantid=@plantID)
					
					insert into rj_iSeriesLog(plantID,sdorgid,stcode,Seriescode,baldate,matcode)
					select  b.PlantID,b.sdorgid,b.stCode,a.SeriesCode,@baldate,a.MatCode
					from iSeries a inner join oStorage b on a.stcode=b.stCode
					where a.state='�ڿ�'
					and (@sdorgid='' or  b.sdorgid=@sdorgid)
					and (@plantID='' or b.PlantID=@plantID)
				END
			
			--����¼����ɾ�����еģ��ٲ���
			if @optionID=0 or @optionID&2=2
				BEGIN
					--����ˢ�����һ������ݣ���ֹˢ����ǰ��
					if exists(select 1 from rj_matStorageLog a with(nolock) 
					          where baldate>@baldate 
								and  (@sdorgid='' or  sdorgid=@sdorgid)
								and (@plantID='' or plantid=@plantID)
					)
					BEGIN
						raiserror('��ֹ����������ݣ����ܶ��������ݽ��в���.',16,1)
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
			
			--�ɱ���¼����ɾ�����еģ��ٲ���
			if @optionID=0 or @optionID&4=4
				BEGIN
					--����ˢ�����һ������ݣ���ֹˢ����ǰ��
					if exists(select 1 from rj_MatsdorgLedgerLog a with(nolock) 
					          where baldate>@baldate 
								and  (@sdorgid='' or  sdorgid=@sdorgid)
								and (@plantID='' or plantid=@plantID)
					)
					BEGIN
						raiserror('��ֹ����������ݣ����ܶ��������ݽ��в���.',16,1)
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
			select @tips=dbo.getLastError('��¼���룬��棬�ɱ���־ʧ��.')
			if @trancount=0 
				rollback
			else if xact_state()<>-1
				rollback TRAN tran1
			raiserror(@tips,16,1)
		end catch
 
	END
 