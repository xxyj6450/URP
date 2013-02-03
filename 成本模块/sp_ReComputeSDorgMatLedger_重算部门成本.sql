alter proc sp_ReComputeSDorgMatLedger
	@FormID int,
	@Doccode varchar(50),
	@OptionID varchar(max)='',
	@Usercode varchar(50)='',
	@TerminalID varchar(50)=''
as
BEGIN
	DECLARE @map MONEY,@ratemap MONEY,@refcode VARCHAR(50),@sdorgid VARCHAR(50),
	@matcode VARCHAR(50),@companyid VARCHAR(50),@matcode1 VARCHAR(50),@rowid VARCHAR(50),@PeriodID varchar(50)
	declare @plantid varchar(50),@digit int,@totalmoney money,@ratemoney money,@mode money,@type int,@i int,@Count int
	declare @RefDate DATETIME
	create table #table  (
		ID int identity(1,1),
		matcode varchar(50),
		Rowid varchar(50),
		digit int DEFAULT 0,
		totalmoney money default 0,
		ratemoney money DEFAULT 0,
		Mode int DEFAULT 0,
		ComputeType varchar(50) DEFAULT ''
	)
	
 	IF @formid IN (1509,1520) --�ɹ���ⵥ����ӯ��ⵥ
	BEGIN
		insert into #table
		select  matcode,a.rowid,a.Digit,a.netmoney,a.netmoney,a.netmoney,3,''
		From imatdoc_d a with(nolock)
		where a.DocCode=@Doccode
		--UPDATE imatdoc_d SET rateprice = netprice,ratemoney = netmoney WHERE doccode=@doccode
		--SELECT netprice,ratemoney,* FROM vCommsales WHERE doccode='GDR2013020200000'
	END
	
	IF @formid IN (4630)  --������ⵥ
	BEGIN
		insert into #table
		select matcode,a.rowid,a.Digit,a.totalmoney,a.netmoney,a.netmoney,3,''
		from Commsales_d a with(nolock)
		where a.DocCode=@Doccode
		--UPDATE Commsales_d SET rateprice = netprice,ratemoney = netmoney WHERE doccode=@doccode
	END
	IF @formid IN (2420) --�����˻���ȡ���۳��ⵥ�ɱ����
	BEGIN
		--ȡ�����۵���
		SELECT @refcode=ClearDocCode,@sdorgid=sdorgid
		  FROM spickorderhd with(nolock) WHERE doccode=@doccode
		--ȡ��������Ϣ
		if isnull(@refcode,'')<>''
			BEGIN
				select @RefDate=sph.DocDate
				from sPickorderHD sph with(nolock) 
				where sph.DocCode=@refcode
				--����ҵ�����,��������������2012��12����ǰ,��ȡ2012��12�·ݵ���ĩ���,����ȡ���۵������۳ɱ�
				if @RefDate<'2013-01-01'
					BEGIN
						insert into #table(matcode,Rowid,totalmoney,ratemoney,Mode,ComputeType)
						select sp.MatCode,sp.rowid,isnull(i.stockvalue/nullif(stock,0),0),isnull(i.ratevalue/nullif(stock,0),0),4,''
						from sPickorderitem sp with(nolock) inner join imatsdorgbalance i with(nolock) on sp.MatCode=i.matcode and i.sdorgid=@sdorgid and i.periodid='2012-12'
						where sp.DocCode=@Doccode
					END
				else
				BEGIN
						--������һ�����۵���ͬһ����Ʒ���ֶ���,Ҳ�������˻�����Ʒ�����۵��в�����
						insert into #table(matcode,Rowid,totalmoney,ratemoney,Mode,ComputeType)
						select sp.MatCode,sp.rowid,sp.netmoney,sph.ratemoney,4,''
						from spickorderitem sp with(nolock),sPickorderitem  sph with(nolock)    
						where sph.DocCode=@refcode
						and sp.DocCode=@Doccode
						and sp.MatCode=sph.MatCode
						and isnull(sp.seriesCode,'')=isnull(sph.seriesCode,'')
					END
				
			END
		--��û���˻���,��ȡ����Ʒ�ڴ��ŵ�����һ�γ���ɱ�
		else
		BEGIN
			;with cte as(
				select max(id) as id,sp.MatCode,sp.rowid,sp.Digit
				from sPickorderitem sp with(nolock) inner join istockledgerlog i with(nolock) on  i.sdorgid=@sdorgid and i.matcode=sp.MatCode		 
				where sp.DocCode=@Doccode
				and (i.indigit<0 or i.outdigit>0)						--������������0,���������С��0,����Ϊ�ǳ���
				group by sp.MatCode,sp.rowid,sp.Digit
				) 
				--insert into #table(matcode,Rowid,totalmoney,ratemoney,Mode,ComputeType)
				select b.MatCode,b.rowid,b.digit,
				--������������ӵ����ʽ��˵��.ȡ����ɱ��ͼӳɳ���ɱ�.�ɱ�Ϊ����,����ȡ����ֵ.�������п��ܼ�¼�ڳ�����,Ҳ���ܼ�¼�������(�ø�����¼),��Ȼ����ȡ������,��������Ϊ0,��תȡ�����.
				--����ɱ�Ϊ��������Գ�������,�����и�����,����������Ϊ0,������nullif�������Ϊ0�����,�����ǽ�0ת����NULL,��ֹ����Ϊ0�Ĵ���
				--��Ȼ���˳���Ϊ0��ΪNULL,���Ҳ����Ϊ0,�ͽ����ת��NULL,Ȼ��ת��ȡinledgeramount,���ת���ǿ�coalesceʵ�ֵ�
				--��Ȼ,�κα��ʽ�Ľ������ΪNULL,�����ǲ�ϣ���ɱ�ΪNUL,�����������һ��ISNULL,�����ܵ�NULLת����0
				--Ҫ�ǻ��������Ļ����������,����Ҫ������,��Ϊ������Ҳ����ȫ������α��ʽ�ĺ���,ͬʱҲ���������˵������.
				--2013-02-02 03:26 ���ϵ�
				isnull(abs(coalesce(nullif(1.0000*i.outledgeramount/nullif(i.outledgerdigit,0),0),nullif(1.0000*i.inledgeramount/nullif(i.inledgerdigit,0),0))),0),
				isnull(abs(coalesce(nullif(1.0000*i.outrateamount/nullif(i.outledgerdigit,0),0),nullif(1.0000*i.inrateamount/nullif(i.inledgerdigit,0),0))),0),4,''
				from istockledgerlog i  inner join cte b on i.id=b.id
				--����ƥ���,��������Ʒû�����һ�γ����¼,���׳��쳣,û�гɱ�Ҳ���˻�?
				if (select count(*) from sPickorderitem sp with(nolock) where sp.DocCode=@Doccode)<>(select count(*) from #table)
					BEGIN
						raiserror('��Ʒδ�г����¼,�޷�ȡ�����һ�γ���ɱ�,�޷��˻�.',16,1)
						return
					END
			END
		
		--SELECT @map=netprice,@ratemap= FROM spickorderitem where doccode=@refcode
		--�����˻���ⵥ�ɱ�
		--SELECT m.rateprice,m.ratemoney,s.rateprice,s.ratemoney,m.netprice,m.netmoney,s.netprice,s.netmoney,*
		/*UPDATE m SET netprice=s.netprice,netmoney=s.netmoney,rateprice=s.rateprice,ratemoney=s.ratemoney,matcost=s.netmoney
		FROM spickorderhd d left join spickorderitem m ON d.doccode=m.doccode LEFT JOIN spickorderitem s ON d.ClearDocCode=s.DocCode
		AND m.matcode=s.matcode AND ISNULL(m.seriescode,'')=ISNULL(s.seriesCode,'') WHERE d.doccode=@doccode--'RT20130106000480'*/
	END
	IF @formid IN (1507) --�ӵ������ⵥȡ�ɱ�
	BEGIN
		--ȡ�õ������ⵥ��
		
		--ȡ�õ�����ⵥ�ɱ�
		UPDATE d SET matcost=s.netmoney,price=s.netprice,totalmoney=s.netmoney,netprice=s.netprice,netmoney=s.netmoney,rateprice=s.rateprice,ratemoney=s.ratemoney
		FROM imatdoc_h h left join imatdoc_d d ON h.doccode=d.doccode LEFT JOIN spickorderitem s ON h.refCode=s.DocCode
		AND d.matcode=s.matcode WHERE d.doccode=@doccode--'RT20130106000480'
	END
	
	IF @formid IN (4061) --�ڲ��ɹ����ȡ���۳���ɱ�
	BEGIN

		--ȡ�õ�����ⵥ�ɱ�
		UPDATE d SET matcost=s.netprice,price=s.netprice,totalmoney=s.netmoney,netprice=s.netprice,netmoney=s.netmoney,rateprice=s.rateprice*(100+l.addpresent)/100,ratemoney=s.digit*s.rateprice*(100+l.addpresent)/100
		FROM imatdoc_h h left join imatdoc_d d ON h.doccode=d.doccode LEFT JOIN spickorderitem s ON h.refCode=s.DocCode
		AND d.matcode=s.matcode LEFT JOIN imatgeneral l ON s.matcode=l.matcode WHERE d.doccode=@doccode--'RT20130106000480'
	END
	IF @formid IN (4032) --�ڲ����������˻�ȡ�ڲ��ɹ��˻��ɱ�
	BEGIN

		--ȡ�õ�����ⵥ�ɱ�
		UPDATE d SET price=s.netprice,totalmoney=s.netmoney,netprice=s.netprice,netmoney=s.netmoney,rateprice=s.rateprice/(100+l.addpresent)/100,ratemoney=s.digit*s.rateprice/(100+l.addpresent)/100
		FROM imatdoc_h h left join imatdoc_d d ON h.doccode=d.doccode LEFT JOIN spickorderitem s ON h.refCode=s.DocCode
		AND d.matcode=s.matcode LEFT JOIN imatgeneral l ON s.matcode=l.matcode WHERE d.doccode=@doccode--'RT20130106000480'
	END
	IF @formid IN (2418,4951)
	BEGIN
		SELECT @companyid=companyid,@sdorgid=sdorgid FROM spickorderhd WHERE doccode=@doccode
		
		declare cur cursor scroll for
		select distinct matcode from spickorderitem WHERE doccode=@doccode
		open cur
		fetch first from cur into @matcode
		while @@fetch_status=0
		begin
		 SELECT @map=stockvalue/stock,@ratemap=ratevalue/stock FROM iMatsdorgLedger WHERE plantid=@companyid AND sdorgid=@sdorgid AND matcode=@matcode AND stock>0
		 UPDATE spickorderitem SET netprice=@map,netmoney=digit*@map,rateprice=digit*@ratemap,ratemoney=digit*@ratemap,matcost=digit*@map
		 WHERE doccode=@doccode
		 --ȡ�������ɱ�����ȡ���һ�����ɱ�
		 IF @map IS NULL
		 begin
		 SELECT TOP 1 @map=(case when formid in (2418,2420,4951,4032) then outledgeramount/outledgerdigit else inledgeramount/inledgerdigit END) 
		 FROM istockledgerlog WHERE formid IN (1509,4630,1507,1520,1512,4061,1599,2418,2420,4951,4032) and sdorgid=@sdorgid ORDER BY inserttime desc
		 END
		 --���򱨴����������
		 IF @map IS NULL
		 BEGIN
		 	RAISERROR('ȡ�����ɱ�������ȷ�ϣ�����!',16,1)
		 	return
		 END
		 fetch next from cur into @matcode
		end
		close cur
		deallocate cur
	END
	--���ŵ�������������
	IF @formid IN (1553,1557)
	BEGIN
		declare cur cursor scroll for
		select distinct e.sdorgid,m.rowid,m.matcode,m.matcode1 from iseriesloghd d left join iserieslogitem m ON d.doccode=m.doccode 
		LEFT JOIN vStorage e ON d.stcode=e.stcode
		--WHERE d.doccode='IC20130106000120'
		WHERE d.doccode=@doccode
		open cur
		fetch first from cur into @sdorgid,@rowid,@matcode,@matcode1
		while @@fetch_status=0
		BEGIN
			SELECT @map=stockvalue/stock FROM iMatsdorgLedger WHERE sdorgid=@sdorgid AND matcode=@matcode1		--������Ʒ�ĳɱ�
			--�����Ʒ�ĳɱ�
			SELECT @ratemap=stockvalue/stock FROM iMatsdorgLedger WHERE sdorgid=@sdorgid AND matcode=@matcode AND stock>0	--�����Ʒ�ĳɱ�
			IF  @ratemap IS NULL
			BEGIN
				SET @ratemap=@map
			END
			UPDATE iserieslogitem SET netmoney=@ratemap,netmoney1=@map WHERE doccode=@doccode AND rowid=@rowid
		 fetch next from cur into @sdorgid,@rowid,@matcode,@matcode1
		end
		close cur
		deallocate cur
	END
	----------------------------------------------------------------��ʼ����ɱ�-------------------------------------------------------------------
	select @i=1,@count=count(*) from #table
	if @Count<=0 return
	
	while @i<=@count 
		BEGIN
			select @digit=digit,@totalmoney=totalmoney,@ratemoney=ratemoney
			from #table
			where id=@i
			exec sp_ComputeSdorgMatLedger @Doccode,@FormID,@rowid,@matcode,@plantid,@sdorgid,@PeriodID,@digit,@totalmoney,@ratemoney,@mode,@type
			set @i=@i+1
		END
	
	return
END