alter proc sp_ReComputeSDorgMatLedger
	@FormID int,											--���ݹ��ܺ�
	@Doccode varchar(50),							--���ݱ���
	@CompanyID varchar(50),						--��˾
	@PeriodID varchar(50),							--�ڼ�
	@SDOrgID varchar(50)='',						--���ű���
	@DocDate datetime='',							--��������
	@InputMatgroup varchar(200)='',			--������Ĵ���
	@InputMatcode varchar(200)='',				--���������Ʒ����
	@RefFormID int  =0,								--���ù��ܺ�
	@RefCode varchar(50)='',						--���õ���
	@OptionID varchar(max)='',					--ѡ��
	@Usercode varchar(50)='',						--ִ����
	@TerminalID varchar(50)=''						--ִ���ն˱���
as
BEGIN
	set NOCOUNT on
	DECLARE @map MONEY,@ratemap MONEY,@matcode VARCHAR(50), @matcode1 VARCHAR(50),@rowid VARCHAR(50)
	declare @RefDate datetime,@RefPlantID varchar(50),@RefSdorgID varchar(50)
	declare @plantid varchar(50),@digit int,@totalmoney money,@ratemoney money,@mode money,@type int,@i int,@Count int
	declare @XMLResult nvarchar(max),@XMLData nvarchar(max)
	declare @hDocument int
	--�û����������ɱ�����Ϣ
	create table #table  (
		ID int identity(1,1),
		PeriodID varchar(50),
		PlantID varchar(50),
		SDOrgID varchar(50),
		matcode varchar(50),
		Rowid varchar(50),
		digit int DEFAULT 0,
		totalmoney money default 0,
		ratemoney money DEFAULT 0,
		Mode int DEFAULT 0,
		ComputeType varchar(50) DEFAULT ''
	)
		--��������������ı����
	 Create Table XMLDataTable (
 		Matcode varchar(50),						--��Ʒ����
		RowID varchar(50),							
 		OldStock int,									--ԭ���
 		OldStockValue money,					--ԭ�����
 		OldRateValue money,						--ԭ�ӳɽ��
		Digit int,										--�޸Ŀ����
		Totalmoney money,						--�޸Ŀ����
		RateMoney money,						--�޸ļӳɽ��
 		Stock int,										--��������
 		StockValue money,							--��������
 		RateValue money,							--����ӳɽ��
		Mode char,									--�����ģʽ 1����������2���⸺����3���������4��⸺��
		ComputeType  varchar(50)				--����ģʽ
 		)
	
 	IF @formid IN (1509,1520,1599) --�ɹ���ⵥ����ӯ��ⵥ
	BEGIN
		insert into #table
		select  a.matcode,a.rowid,a.Digit,a.netmoney,a.netmoney,a.netmoney,3,''
		From imatdoc_d a with(nolock)
		where a.DocCode=@Doccode
		 
		--UPDATE imatdoc_d SET rateprice = netprice,ratemoney = netmoney WHERE doccode=@doccode
		--SELECT netprice,ratemoney,* FROM vCommsales WHERE doccode='GDR2013020200000'
	END
	
	IF @formid IN (4630)  --������ⵥ
	BEGIN
		insert into #table
		select a.matcode,a.rowid,a.Digit,a.totalmoney,a.netmoney,a.netmoney,3,''
		from Commsales_d a with(nolock) 
		where a.DocCode=@Doccode 
		--UPDATE Commsales_d SET rateprice = netprice,ratemoney = netmoney WHERE doccode=@doccode
	END
	IF @formid IN (2420) --�����˻���ȡ���۳��ⵥ�ɱ����
	BEGIN
		--ȡ�����۵���
		--SELECT @refcode=ClearDocCode,@sdorgid=sdorgid
		--  FROM spickorderhd with(nolock) WHERE doccode=@doccode
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
						from spickorderitem sp with(nolock) 
						inner join sPickorderitem  sph with(nolock) on sp.DocCode=@Doccode  AND sph.DocCode=@refcode AND   sp.MatCode=sph.MatCode And isnull(sp.seriesCode,'')=isnull(sph.seriesCode,'')
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
				insert into #table(matcode,Rowid,digit,totalmoney,ratemoney,Mode,ComputeType)
				select b.MatCode,b.rowid,b.digit,
				--������������ӵ����ʽ��˵��.ȡ����ɱ��ͼӳɳ���ɱ�.�ɱ�Ϊ����,����ȡ����ֵ.�������п��ܼ�¼�ڳ�����,Ҳ���ܼ�¼�������(�ø�����¼),��Ȼ����ȡ������,��������Ϊ0,��תȡ�����.
				--����ɱ�Ϊ��������Գ�������,�����и�����,����������Ϊ0,������nullif�������Ϊ0�����,�����ǽ�0ת����NULL,��ֹ����Ϊ0�Ĵ���
				--��Ȼ���˳���Ϊ0��ΪNULL,���Ҳ����Ϊ0,�ͽ����ת��NULL,Ȼ��ת��ȡinledgeramount,���ת���ǿ�coalesceʵ�ֵ�
				--��Ȼ,�κα��ʽ�Ľ������ΪNULL,�����ǲ�ϣ���ɱ�ΪNUL,�����������һ��ISNULL,�����ܵ�NULLת����0
				--Ҫ�ǻ��������Ļ����������,��ǧ�޲�Ҫ������,��Ϊ������Ҳ����ȫ������α��ʽ�ĺ���,ͬʱҲ���������˵������.
				--2013-02-02 03:26 ���ϵ�
				isnull(abs(coalesce(nullif(1.0000*i.outledgeramount/nullif(i.outledgerdigit,0),0),nullif(1.0000*i.inledgeramount/nullif(i.inledgerdigit,0),0))),0),
				isnull(abs(coalesce(nullif(1.0000*i.outrateamount/nullif(i.outledgerdigit,0),0),nullif(1.0000*i.inrateamount/nullif(i.inledgerdigit,0),0))),0),4,''
				from istockledgerlog i with(nolock)  inner join cte b on i.id=b.id
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
	--���γ��ⵥ
	if @FormID in(2424)
		BEGIN
			insert into #table(matcode,Rowid,digit,totalmoney,ratemoney,Mode,ComputeType)
				select sp.MatCode,sp.rowid,isnull(digit,0),isnull(sp.totalmoney,0),isnull(sp.ratemoney,0),1,''
				from sPickorderitem sp with(nolock) 
				where sp.DocCode=@Doccode
		END
	--������ⵥ,�ȴ������,�ٴ������.
	IF @formid IN (1507) --�ӵ������ⵥȡ�ɱ�
	BEGIN
		---------------------------------------------------------��������----------------------------------------------------
		--ȡ�õ���������Ϣ
		select @RefPlantID=ih.plantid,@RefSdorgID=ih.sdorgid,@RefDate=ih.DocDate
		from imatdoc_h ih with(nolock)
		where ih.DocCode=@Refcode
		and ih.FormID=@RefFormID
		if @@ROWCOUNT=0
			BEGIN
				raiserror('�����ڵ��γ��ⵥ,�ɱ������޷�����,����ϵϵͳ����Ա.',16,1)
				return
			END
		--SELECT @rowid=rowid,@matcode=matcode,@plantid=companyid,@sdorgid=sdorgid,@periodid=periodid,@digit=digit,@totalmoney=totalmoney,@ratemoney=ratemoney
		--�ȴ�������ĳɱ�
		exec sp_ReComputeSDorgMatLedger 2424,@RefCode,@RefPlantID,@PeriodID,@RefSdorgID,@RefDate,@InputMatgroup,@InputMatcode ,default,default,default,default,@Usercode,@TerminalID
		--������⣬ȡ��������ĳɱ�����������ⵥΪ2012-12�ڼ�ǰ����ȡ2012-12��ʼ�ɱ�imatledger_bak
		if @refDate<'2013-01-01'
			BEGIN
				insert into #table(matcode,Rowid,digit,totalmoney,ratemoney,Mode,ComputeType)
				select sp.MatCode,sp.rowid,sp.Digit,isnull(1.0000*iml.stockvalue/nullif(iml.stock,0),0),isnull(1.0000*iml.ratevalue/nullif(iml.stock,0),0),3,''
				from sPickorderitem sp with(nolock) inner join imatsdorgbalance  iml with(nolock)
				on sp.MatCode=iml.MatCode
				and iml.sdorgid=@SDOrgID
				and iml.periodid='2012-12'
				return
			END
		else
			BEGIN
				insert into #table(matcode,Rowid,digit,totalmoney,ratemoney,Mode,ComputeType)
				select sp.MatCode,sp.rowid,isnull(sp.digit,0),isnull(sph.totalmoney,0),isnull(sph.ratemoney,0),3,''
				from sPickorderitem sp with(nolock) inner join sPickorderitem sph with(nolock)
				on sp.DocCode=@Doccode and sph.DocCode=@RefCode and sp.MatCode=sph.MatCode
			END
		
		--------------------------------------------���봦��--------------------------------------------
		--insert into #table(matcode,Rowid,digit,totalmoney,ratemoney,Mode,ComputeType)
		--ȡ�õ�����ⵥ�ɱ�
		/*UPDATE d SET matcost=s.netmoney,price=s.netprice,totalmoney=s.netmoney,netprice=s.netprice,netmoney=s.netmoney,rateprice=s.rateprice,ratemoney=s.ratemoney
		FROM imatdoc_h h left join imatdoc_d d ON h.doccode=d.doccode LEFT JOIN spickorderitem s ON h.refCode=s.DocCode
		AND d.matcode=s.matcode WHERE d.doccode=@doccode--'RT20130106000480'
		*/
	END
	--4061�ڲ��ɹ���⣬���ڲ��������۳���ɱ���⣬�ӹ�˾�ӳɳɱ��ӵ���
	IF @formid IN (4061) --�ڲ��ɹ����ȡ���۳���ɱ�
	BEGIN
		insert into #table(matcode,Rowid,digit,totalmoney,ratemoney,Mode,ComputeType)
		select a.MatCode,a.rowid,b.digit,b.netmoney,1.0000*b.digit*b.rateprice*(100+img.addpresent)/100,3,''
		from imatdoc_d a with(nolock) inner join sPickorderitem  b with(nolock)
		inner join iMatGeneral img with(nolock) on b.MatCode=img.MatCode
		on a.MatCode=b.MatCode
		and a.DocCode=@Doccode
		and b.DocCode=@RefCode
		--ȡ�õ�����ⵥ�ɱ�
		/*UPDATE d SET matcost=s.netprice,price=s.netprice,totalmoney=s.netmoney,netprice=s.netprice,netmoney=s.netmoney,rateprice=s.rateprice*(100+l.addpresent)/100,ratemoney=s.digit*s.rateprice*(100+l.addpresent)/100
		FROM imatdoc_h h left join imatdoc_d d ON h.doccode=d.doccode LEFT JOIN spickorderitem s ON h.refCode=s.DocCode
		AND d.matcode=s.matcode LEFT JOIN imatgeneral l ON s.matcode=l.matcode WHERE d.doccode=@doccode--'RT20130106000480'
		*/
	END
	--4032�ڲ������˻������ڲ��ɹ��˻��ĳ���ɱ����
	IF @formid IN (4032)
	BEGIN
		insert into #table(matcode,Rowid,digit,totalmoney,ratemoney,Mode,ComputeType)
		select a.MatCode,a.rowid,a.digit,b.netmoney,1.0000*b.digit*b.rateprice/(100+img.addpresent)/100,4,''
		from imatdoc_d a with(nolock) inner join sPickorderitem  b with(nolock) 
			on a.MatCode=b.MatCode
			and a.DocCode=@Doccode
			and b.DocCode=@RefCode
		inner join iMatGeneral img with(nolock) 
			on a.MatCode=img.MatCode
		if @@ROWCOUNT=0
			BEGIN
				raiserror('�ڲ������˻���δȡ�ö�Ӧ�Ĳɹ��˻�����',16,1)
				return
			END
		--ȡ�õ�����ⵥ�ɱ�
		/*
		UPDATE d SET price=s.netprice,totalmoney=s.netmoney,netprice=s.netprice,netmoney=s.netmoney,rateprice=s.rateprice/(100+l.addpresent)/100,ratemoney=s.digit*s.rateprice/(100+l.addpresent)/100
		FROM imatdoc_h h left join imatdoc_d d ON h.doccode=d.doccode LEFT JOIN spickorderitem s ON h.refCode=s.DocCode
		AND d.matcode=s.matcode LEFT JOIN imatgeneral l ON s.matcode=l.matcode WHERE d.doccode=@doccode--'RT20130106000480'
		*/
	END
	--2418�����˻���4951�������˻���������У����Կ��ɱ��˻���⣬��û�У����Ըò������һ�γ���ɱ����
	IF @formid IN (2418,4951)
	BEGIN
		--ȡ������������Ʒ���һ�γ����¼
		;with cte as(
				select max(id) as id,sp.MatCode,sp.rowid,sp.Digit
				from sPickorderitem sp with(nolock) Left join istockledgerlog i with(nolock) on  i.sdorgid=@sdorgid and i.matcode=sp.MatCode		--�˴���Left Join ȡ������������Ʒ�����ݡ�
				where sp.DocCode=@Doccode
				and (i.indigit<0 or i.outdigit>0)						--������������0,���������С��0,����Ϊ�ǳ���
				group by sp.MatCode,sp.rowid,sp.Digit
				) 
				insert into #table(matcode,Rowid,digit,totalmoney,ratemoney,Mode,ComputeType)
				select b.MatCode,b.rowid,b.digit,
				--������������ӵ����ʽ��˵��.ȡ����ɱ��ͼӳɳ���ɱ�.�ɱ�Ϊ����,����ȡ����ֵ.�������п��ܼ�¼�ڳ�����,Ҳ���ܼ�¼�������(�ø�����¼),��Ȼ����ȡ������,��������Ϊ0,��תȡ�����.
				--����ɱ�Ϊ��������Գ�������,�����и�����,����������Ϊ0,������nullif�������Ϊ0�����,�����ǽ�0ת����NULL,��ֹ����Ϊ0�Ĵ���
				--��Ȼ���˳���Ϊ0��ΪNULL,���Ҳ����Ϊ0,�ͽ����ת��NULL,Ȼ��ת��ȡinledgeramount,���ת���ǿ�coalesceʵ�ֵ�
				--��Ȼ,�κα��ʽ�Ľ������ΪNULL,�����ǲ�ϣ���ɱ�ΪNUL,�����������һ��ISNULL,�����ܵ�NULLת����0
				--Ҫ�ǻ��������Ļ����������,��ǧ�޲�Ҫ������,��Ϊ������Ҳ����ȫ������α��ʽ�ĺ���,ͬʱҲ���������˵������.
				--2013-02-02 03:26 ���ϵ�
				isnull(abs(coalesce(nullif(1.0000*i.outledgeramount/nullif(i.outledgerdigit,0),0),nullif(1.0000*i.inledgeramount/nullif(i.inledgerdigit,0),0))),0),
				isnull(abs(coalesce(nullif(1.0000*i.outrateamount/nullif(i.outledgerdigit,0),0),nullif(1.0000*i.inrateamount/nullif(i.inledgerdigit,0),0))),0),4,''
				from istockledgerlog i with(nolock)  right join cte b on i.id=b.id			--�˴���������,ȡ������������Ʒ������������
			--���п����Ʒ�ĳɱ�����Ϊ��ʱ�ɱ�
			update a
				set a.totalmoney=a.digit*isnull(1.0000*iml.StockValue/nullif(iml.Stock,0),0),
				a.ratemoney=a.digit*isnull(1.0000*iml.ratevalue/nullif(iml.Stock,0),0)
			from #table a Inner join  iMatsdorgLedger iml with(nolock)
			on a.matcode=iml.MatCode
			and iml.sdorgid=@SDOrgID
			and iml.Stock>0
		/*
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
		*/
	END
	--���ŵ�������������
	--1553���ŵ�������1557�������ص����Կ��ɱ���⣬��û��棬���Գ���ɱ����,������Ʒ�Ƿ���ͬ
	--OptionIDΪ1��ʾ����,Ϊ2��ʾ���
	IF @formid IN (1553,1557)
	BEGIN
		--�ȴ������ĳɱ����Լ�ʱ�ɱ�����
		if @OptionID=1
			BEGIN
				--�����¼
				insert into #table(matcode,Rowid,digit,totalmoney,ratemoney,Mode,ComputeType)
				Select i.matcode1,i.rowid,1,0,0,2,''
				From iserieslogitem i with(nolock)
				where i.doccode=@Doccode
				--���³ɱ�,��ΪiSerieslogItem��ܴ�,���Բ�ֱ����ɱ������,����ȡ���������ݺ��ٸ��³ɱ�
				update a
					set a.totalmoney=a.digit*isnull(1.0000*iml.StockValue/nullif(iml.Stock,0),0),
					a.ratemoney=a.digit*isnull(1.0000*iml.ratevalue/nullif(iml.Stock,0),0)
				from #table a inner join iMatsdorgLedger iml with(nolock)
					on a.matcode=iml.MatCode
					and iml.sdorgid=@SDOrgID
					--ע��ִ��������󣬻�ִ�гɱ����㣬������ɱ�������ɱ��ֶΣ������ʹ��
			END
		--�ٴ������ �Կ��ɱ���⣬��û��棬���Գ���ɱ����,������Ʒ�Ƿ���ͬ
		else if @OptionID=2 
			BEGIN
				--��Ĭ��ȫ���Գ���ɱ����
				insert into #table(matcode,Rowid,digit,totalmoney,ratemoney,Mode,ComputeType)
				Select i.matcode,i.rowid,1,netmoney,netmoney,3,''
				From iserieslogitem i with(nolock)
				where i.doccode=@Doccode
				--���п�棬���������ʱ�ɱ�
				update a
					set a.totalmoney=a.digit*isnull(1.0000*iml.StockValue/nullif(iml.Stock,0),0),
					a.ratemoney=a.digit*isnull(1.0000*iml.ratevalue/nullif(iml.Stock,0),0)
				from #table a inner join iMatsdorgLedger iml with(nolock)
					on a.matcode=iml.MatCode
					and iml.sdorgid=@SDOrgID
			END
		else
			BEGIN
				raiserror('��Ч��ѡ��ֵ,�޷�����ɱ�.',16,1)
				return
			END
		
		/*
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
		deallocate cur*/
		
	END
 
	----------------------------------------------------------------��ʼ����ɱ�-------------------------------------------------------------------
	/*
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
	*/
	select @XMLResult='<root>'
	declare cur CURSOR READ_ONLY fast_forward forward_only for
	select a.matcode,a.Rowid,a.digit,a.totalmoney,a.ratemoney,a.Mode,a.ComputeType
	From #table a  inner join iMatGeneral img with(nolock) on a.MatCode=img.MatCode
		inner join iMatGroup img2 with(nolock) on img.MatGroup=img2.matgroup
		where a.DocCode=@Doccode
		and (@InputMatcode='' or exists(select 1 from commondb.dbo.SPLIT(isnull(@InputMatcode,''),',') s where img.MatCode=s.List))
		and (@InputMatgroup='' or  exists(select 1 from commondb.dbo.SPLIT(isnull(@InputMatgroup,''),',') s where img2.PATH like '%/'+s.List+'/%'))
	order by a.ID
	open cur
	fetch next FROM cur into @matcode,@rowid,@digit,@totalmoney,@ratemoney,@mode,@type
	while @@FETCH_STATUS=0
		BEGIN
			
			exec sp_ComputeSdorgMatLedger @Doccode,@FormID,@rowid,@matcode,@plantid,@sdorgid,@PeriodID,@digit,@totalmoney,@ratemoney,@mode,@type,@XMLData output
			if @XMLData<>'' Select @XMLResult=@XMLResult+@XMLData
			fetch next FROM cur into @matcode,@rowid,@digit,@totalmoney,@ratemoney,@mode,@type
		END
	close cur
	deallocate cur
	select @XMLResult=@XMLResult+'</root>'
	exec sp_xml_preparedocument @hDocument output,@XMLData
	Insert Into #XMLDataTable
	Select * From OpenXML(@hDocument,'/root/row',1) with #XMLDataTable
	exec sp_XML_RemoveDocument @hDocument
	--ִ�����
	exec sp_outputMatLedgerResult @Doccode,@FormID,@plantid,@PeriodID,@OptionID,@Usercode,@TerminalID
	return
END