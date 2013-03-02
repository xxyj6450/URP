create proc sp_ReComputeSDorgMatLedger
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
	@InsertTime datetime ='',						--��ϸ������ʱ��
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
	declare @tips varchar(max)
	--�û����������ɱ�����Ϣ
	create table #table  (
		ID int identity(1,1),
		FormID int,
		Doccode varchar(50),
		PeriodID varchar(50),
		PlantID varchar(50),
		SDOrgID varchar(50),
		Seriescode varchar(50),
		matcode varchar(50),
		Rowid varchar(50),
		digit int DEFAULT 0,
		totalmoney money default 0,
		ratemoney money DEFAULT 0,
		Mode int DEFAULT 0,
		ComputeType varchar(50) DEFAULT ''
	)
	--��������������ı����
	 Create Table #XMLDataTable (
 		Matcode varchar(50),						--��Ʒ����
		RowID varchar(50),							--x
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
	print '����ɱ�:'+isnull(convert(varchar(30),@InsertTime ,120),'')+'--->'+@Companyid +','+@PeriodID +','+@SDOrgID +','+convert(varchar(10),@FormID)+','+ @Doccode+','+'>>>>'+convert(varchar(30),getdate(),120)
	--1509�ɹ���ⵥ���Բɹ����ĳɱ�/�ӳɳɱ����,��Դ��sp_countcost
	--1520��ӯ��⣬�Թ���¼��ɱ����
	--1599������ⵥ������¼��ɱ����
 	IF @formid IN (1509,1520,1599) --�ɹ���ⵥ����ӯ��ⵥ
	BEGIN
		insert into #table(matcode,Rowid,digit,totalmoney,ratemoney,Mode,ComputeType)
		select  a.matcode,a.rowid,a.Digit,a.netmoney,a.netmoney,3,''
		From imatdoc_d a with(nolock)
		where a.DocCode=@Doccode
		 
		--UPDATE imatdoc_d SET rateprice = netprice,ratemoney = netmoney WHERE doccode=@doccode
		--SELECT netprice,ratemoney,* FROM vCommsales WHERE doccode='GDR2013020200000'
	END
	--���ϳ��ⵥ,ֱ��ȡ���ݵĽ��,���ϳ��ⵥ
	if @FormID in(1504,1523)
		BEGIN
			insert into #table(matcode,Rowid,digit,totalmoney,ratemoney,Mode,ComputeType)
			select  a.matcode,a.rowid,a.Digit,a.netmoney,a.ratemoney,2,''
			From imatdoc_d a with(nolock)
			where a.DocCode=@Doccode
		END
	--1501,1598�������ⵥ,�̿����ⵥ,�Ե��ݽ�����ɱ�
	if @FormID in(1501,1598)
		BEGIN
			insert into #table(matcode,Rowid,digit,totalmoney,ratemoney,Mode,ComputeType)
			select  a.matcode,a.rowid,a.Digit,a.netmoney,a.ratemoney,1,''
			From imatdoc_d a with(nolock)
			where a.DocCode=@Doccode
		END
	--4630���д�����ⵥ�������ĳɱ�/�ӳɳɱ����,��Դ��[sp_countcost]
	IF @formid IN (4630)  --������ⵥ
	BEGIN
		insert into #table(matcode,Rowid,digit,totalmoney,ratemoney,Mode,ComputeType)
		select a.matcode,a.rowid,a.Digit,a.netmoney,a.netmoney,3,''
		from Commsales_d a with(nolock) 
		where a.DocCode=@Doccode 
		--UPDATE Commsales_d SET rateprice = netprice,ratemoney = netmoney WHERE doccode=@doccode
	END
	--4631 ��Ӧ�̴����˻���,�Ե����Ͻ�����
	if @FormID in(4631)
		BEGIN
			insert into #table(matcode,Rowid,digit,totalmoney,ratemoney,Mode,ComputeType)
			select a.matcode,a.rowid,a.Digit,a.netmoney,a.ratemoney,1,''
			from Commsales_d a with(nolock) 
			where a.DocCode=@Doccode 
		END
	--�������۵�
	if @FormID in(2419,2401,2450,4950)
		BEGIN
			insert into #table(matcode,Rowid,digit,totalmoney,ratemoney,Mode,ComputeType)
			select sp.MatCode,sp.rowid,digit,netmoney,sp.ratemoney,1,''					
			from sPickorderitem sp with(nolock)
			where sp.DocCode=@Doccode
		END
	--�п���ȡ���ɱ�,û����ȡԴ���۵��ɱ�,����Դ���۵�,��ȡ���һ�����۳ɱ�.
	IF @formid IN (2420) --�����˻���ȡ���۳��ⵥ�ɱ����
	BEGIN
		--ȡ���ɱ�
		--����,����ж��Ƿ��п��ɱ���
		--�Ƿ��п��ɱ��ı�׼�ǣ����ɱ��޼�¼������ɱ�������Ϊ0��NULL�����п�棬��stockvalueΪNULL����������Ϊ0
		--��������У���isnull(iml.StockValue,0)/nullif(iml.Stock,0)����ɱ���������ʽֻ����stockΪ0��NULLʱ�Ż�õ�NULLֵ��������������ᡣ
		--����ֵ���µ�totalmoney�ֶ�
		--����ֻ���ж�Totalmoney�Ƿ�ΪNULL�����ж��Ƿ��п��ɱ�
		insert into #table(Doccode,FormID,Seriescode,matcode,Rowid,digit,totalmoney,ratemoney,Mode,ComputeType)
						select @Doccode,@FormID, sp.seriesCode, sp.MatCode,sp.rowid,sp.digit,1.00*sp.digit*isnull(iml.StockValue,0)/nullif(iml.Stock,0),1.00*sp.digit*isnull(iml.ratevalue,0)/nullif(iml.Stock,0),4,''			 
						from spickorderitem sp with(nolock) Left join iMatsdorgLedger iml with(nolock) on sp.MatCode=iml.MatCode and iml.sdorgid=@SDOrgID
						inner join iMatGeneral img with(nolock) on sp.matcode=img.MatCode
						where sp.DocCode=@Doccode
						and img.MatState=1								--ֻ���������������Ʒ
		--������Ʒ�޿��ɱ������Դ�Դ����ȡ
		if exists(select 1 from #table where totalmoney is null)
			BEGIN
				--��Դ�������Դ����ȡ�ɱ�
				if isnull(@refcode,'')<>'' 
					BEGIN
						--������һ�����۵���ͬһ����Ʒ���ֶ���,Ҳ�������˻�����Ʒ�����۵��в�����
						--insert into #table(matcode,Rowid,digit,totalmoney,ratemoney,Mode,ComputeType)
						--select sp.MatCode,sp.rowid,sp.digit,sph.MatCost,sph.ratemoney,4,''			--����matcost,����netmoney,��Ϊǰ����൥��ûдnetmoney
						update sp
							set totalmoney = sph.MatCost,ratemoney = sph.ratemoney
						from #table sp with(nolock) 
						inner join sPickorderitem  sph with(nolock) on sp.DocCode=@Doccode  AND sph.DocCode=@refcode AND   sp.MatCode=sph.MatCode And isnull(sp.seriesCode,'')=isnull(sph.seriesCode,'')
						where sp.totalmoney is null						--ֻ������ΪNULL������
						if @@ROWCOUNT=0
							BEGIN
								raiserror('δ�����������˻��������۵�,�޷������˻��ɱ�.',16,1)
								return
							END	
					END
				--��û���˻���,��ȡ����Ʒ�ڴ��ŵ�����һ�γ���ɱ�
				else
				BEGIN
					;with cte as(
						select max(i.id) as id,sp.MatCode,sp.rowid,sp.Digit
						from #table sp with(nolock) inner join istockledgerlog i with(nolock) on  i.sdorgid=@sdorgid and i.matcode=sp.MatCode		 
						inner join istockledgerlog i2 with(nolock) on sp.DocCode=i2.doccode and i2.matcode=sp.MatCode
						where sp.DocCode=@Doccode
						and (i.indigit<0 or i.outdigit>0)						--������������0,���������С��0,����Ϊ�ǳ���
						and i.inserttime<i2.inserttime								--ֻȡ��ǰ�˻�����ǰ�����һ�γ���
						group by sp.MatCode,sp.rowid,sp.Digit
						) 
						--insert into #table(matcode,Rowid,digit,totalmoney,ratemoney,Mode,ComputeType)
						--select b.MatCode,b.rowid,b.digit,
						--������������ӵ����ʽ��˵��.ȡ����ɱ��ͼӳɳ���ɱ�.�ɱ�Ϊ����,����ȡ����ֵ.�������п��ܼ�¼�ڳ�����,Ҳ���ܼ�¼�������(�ø�����¼),��Ȼ����ȡ������,��������Ϊ0,��תȡ�����.
						--����ɱ�Ϊ��������Գ�������,�����и�����,����������Ϊ0,������nullif�������Ϊ0�����,�����ǽ�0ת����NULL,��ֹ����Ϊ0�Ĵ���
						--��Ȼ���˳���Ϊ0��ΪNULL,���Ҳ����Ϊ0,�ͽ����ת��NULL,Ȼ��ת��ȡinledgeramount,���ת���ǿ�coalesceʵ�ֵ�
						--��Ȼ,�κα��ʽ�Ľ������ΪNULL,�����ǲ�ϣ���ɱ�ΪNUL,�����������һ��ISNULL,�����ܵ�NULLת����0
						--Ҫ�ǻ��������Ļ����������,��ǧ�޲�Ҫ������,��Ϊ������Ҳ����ȫ������α��ʽ�ĺ���,ͬʱҲ���������˵������.
						--2013-02-02 03:26 ���ϵ�
						update a
							set a.totalmoney=isnull(abs(coalesce(nullif(1.0000*i.outledgeramount/nullif(i.outledgerdigit,0),0),nullif(1.0000*i.inledgeramount/nullif(i.inledgerdigit,0),0))),0),
						ratemoney=isnull(abs(coalesce(nullif(1.0000*i.outrateamount/nullif(i.outledgerdigit,0),0),nullif(1.0000*i.inrateamount/nullif(i.inledgerdigit,0),0))),0)
						from   istockledgerlog i with(nolock)  inner join cte b on i.id=b.id inner join #table a on b.rowid=a.Rowid and a.matcode=b.matcode
						where a.totalmoney is null
				END
			END
			--select * From #table
			--����ƥ���,��������Ʒû�����һ�γ����¼,���׳��쳣,û�гɱ�Ҳ���˻�?
			select @tips=''
			select @tips=@tips+'��Ʒ'+ a.matcode+'δȡ������ɱ����޷��˻���'+char(10)
			from #table a
			if @@ROWCOUNT=0
				BEGIN
					raiserror(@tips,16,1)
					return
				END
	END
	--���γ��ⵥ,��˾�����۵�,��Դ��sp_delloutcost
	if @FormID in(2424,4031)
		BEGIN
			insert into #table(Doccode,Formid,plantid,periodid,sdorgid,matcode,Rowid,digit,totalmoney,ratemoney,Mode,ComputeType)
				select @Doccode,@FormID, @CompanyID,@PeriodID,@SDOrgID, sp.MatCode,sp.rowid,isnull(digit,0),isnull(sp.netmoney,0),isnull(sp.ratemoney,0),1,''
				from sPickorderitem sp with(nolock) 
				where sp.DocCode=@Doccode
				--and isnull(sp.Digit,0)<>0
		END
	--��˾�ڲɹ��˻�,��Դ��sp_delloutcost
	IF @formid=4062
	BEGIN
		insert into #table(matcode,Rowid,digit,totalmoney,ratemoney,Mode,ComputeType)
				select sp.MatCode,sp.rowid,isnull(digit,0),isnull(sp.netmoney,0),isnull(sp.ratemoney,0),2,''
				from imatdoc_d sp with(nolock) 
				where sp.DocCode=@Doccode
				--select * from iMatsdorgLedger iml where iml.sdorgid='101.05.02' and matcode='1.11.013.1.1.1'
	END
	--������ⵥ,�ȴ������,�ٴ������.
	--������⣬ȡ��������ĳɱ�����������ⵥΪ2012-12�ڼ�ǰ����ȡ2012-12��ʼ�ɱ�imatledger_bak
	IF @formid IN (1507) --�ӵ������ⵥȡ�ɱ�
	BEGIN
		---------------------------------------------------------��������----------------------------------------------------
		--ȡ�õ���������Ϣ
		update ih set @RefPlantID=ih.companyid,@RefSdorgID=ih.sdorgid,@RefDate=ih.DocDate,ih.DocDate = @Docdate,ih.periodid = @PeriodID
		from sPickorderHD  ih with(nolock)
		where ih.DocCode=@Refcode
		and ih.FormID=@RefFormID
		if @@ROWCOUNT=0
			BEGIN
				raiserror('�����ڵ��γ��ⵥ,�ɱ������޷�����,����ϵϵͳ����Ա.',16,1)
				return
			END
		--SELECT @rowid=rowid,@matcode=matcode,@plantid=companyid,@sdorgid=sdorgid,@periodid=periodid,@digit=digit,@totalmoney=totalmoney,@ratemoney=ratemoney
		--�ȴ�������ĳɱ�
		exec sp_ReComputeSDorgMatLedger 2424,@RefCode,@RefPlantID,@PeriodID,@RefSdorgID,@DocDate,@InputMatgroup,@InputMatcode ,default,default,default,@Usercode,@TerminalID
		--������⣬ȡ��������ĳɱ�����������ⵥΪ2012-12�ڼ�ǰ����ȡ2012-12��ʼ�ɱ�imatledger_bak
		if @refDate<'2013-01-01'
			BEGIN
				insert into #table( Doccode,FormID,plantid,periodid,sdorgid,matcode,Rowid,digit,totalmoney,ratemoney,Mode,ComputeType)
				select  @Doccode,@FormID,@CompanyID,@PeriodID,@SDOrgID, sp.MatCode,sp.rowid,sp.Digit,isnull(1.0000*iml.stockvalue/nullif(iml.stock,0),0),isnull(1.0000*iml.ratevalue/nullif(iml.stock,0),0),3,''
				from sPickorderitem sp with(nolock) inner join imatsdorgbalance  iml with(nolock)
				on sp.MatCode=iml.MatCode
				and iml.sdorgid=@SDOrgID
				and iml.periodid='2012-12'
				and sp.DocCode=@Refcode
			END
		else
			BEGIN
				insert into #table( Doccode,FormID,plantid,periodid,sdorgid,matcode,Rowid,digit,totalmoney,ratemoney,Mode,ComputeType)
				select  @Doccode,@FormID,@CompanyID,@PeriodID,@SDOrgID,sp.MatCode,sp.rowid,isnull(sp.digit,0),isnull(sph.netmoney,0),isnull(sph.ratemoney,0),3,''
				from imatdoc_d sp with(nolock) inner join sPickorderitem sph with(nolock)
				on sp.DocCode=@Doccode and sph.DocCode=@RefCode and sp.MatCode=sph.MatCode
			END
	END
	--4061�ڲ��ɹ���⣬���ڲ��������۳���ɱ���⣬�ӹ�˾�ӳɳɱ��ӵ���
	IF @formid IN (4061) --�ڲ��ɹ����ȡ���۳���ɱ�
	BEGIN
		--�ȴ���˾�����۵��ɱ�
		if isnull(@RefCode,'')='' 
			begin 
				raiserror('δ���빫˾�����۵���Ϣ,�޷�����˾�ڲɹ����ɱ�',16,1)
				return
			end
		--ȡ����˾�����۵���Ϣ
		update a set  @RefDate=a.DocDate,@RefPlantID=a.plantid,@RefSdorgID=a.sdorgid,docdate=@DocDate,a.periodid = @PeriodID
		From spickorderhd a with(nolock)
		where a.FormID=@RefFormID
		and a.DocCode=@RefCode
		if @@ROWCOUNT=0
			BEGIN
				raiserror('�����ڶ�Ӧ�Ĺ�˾�ڲ����۵�,�޷�����˾�ڲɹ����ɱ�.',16,1)
				return
			END
		exec sp_ReComputeSDorgMatLedger 4031,@RefCode,@RefPlantID,@PeriodID,@RefSdorgID,@DocDate,@InputMatgroup,@InputMatcode ,default,default,default,@Usercode,@TerminalID
		--�ټ����ڲ��ɹ����ɱ�
		insert into #table(matcode,Rowid,digit,totalmoney,ratemoney,Mode,ComputeType)
		select a.MatCode,a.rowid,b.digit,b.netmoney,1.0000*b.digit*b.rateprice*(100+img.addpresent)/100,3,''
		from imatdoc_d a with(nolock) inner join sPickorderitem  b with(nolock)
		inner join iMatGeneral img with(nolock) on b.MatCode=img.MatCode
		on a.MatCode=b.MatCode
		and a.DocCode=@Doccode
		and b.DocCode=@RefCode
	END
	--4032�ڲ������˻������ڲ��ɹ��˻��ĳ���ɱ����
	IF @formid IN (4032)
	BEGIN
		--�ȴ���˾�����۵��ɱ�
		if isnull(@RefCode,'')='' 
			begin 
				raiserror('δ���빫˾�ڲɹ��˻�����Ϣ,�޷�����˾�������˻��ɱ�',16,1)
				return
			end
		--ȡ����˾�����۵���Ϣ
		update a set @RefDate=a.DocDate,@RefPlantID=a.plantid,@RefSdorgID=a.sdorgid,a.DocDate = @DocDate,a.PeriodID = @PeriodID
		From imatdoc_h a with(nolock)
		where a.FormID=@RefFormID
		and a.DocCode=@RefCode
		if @@ROWCOUNT=0
			BEGIN
				raiserror('�����ڶ�Ӧ�Ĺ�˾�ڲɹ��˻���,�޷�����˾�������˻��ɱ�.',16,1)
				return
			END
		
		exec sp_ReComputeSDorgMatLedger 4062,@RefCode,@RefPlantID,@PeriodID,@RefSdorgID,@DocDate,@InputMatgroup,@InputMatcode ,default,default,default,@Usercode,@TerminalID
		
		insert into #table(matcode,Rowid,digit,totalmoney,ratemoney,Mode,ComputeType)
		select b.MatCode,b.rowid,b.digit,a.netmoney,1.0000*b.digit*a.rateprice/(100+img.addpresent)/100,4,''
		from imatdoc_d a with(nolock) inner join sPickorderitem  b with(nolock) 
			on a.MatCode=b.MatCode
			and b.DocCode=@Doccode
			and a.DocCode=@RefCode
		inner join iMatGeneral img with(nolock) 
			on a.MatCode=img.MatCode
		if @@ROWCOUNT=0
			BEGIN
				raiserror('�ڲ������˻���δȡ�ö�Ӧ�Ĳɹ��˻�����',16,1)
				return
			END
		--select * from #table a,iMatsdorgLedger iml where a.matcode=iml.MatCode and iml.sdorgid=@SDOrgID
		
	END
	--2418�����˻���4951�������˻���������У����Կ��ɱ��˻���⣬��û�У����Ըò������һ�γ���ɱ����
	IF @formid IN (2418,4951)
	BEGIN
		--ȡ������������Ʒ���һ�γ����¼
		;with cte as(
				select max(i.id) as id,sp.MatCode,sp.rowid,sp.Digit
				from sPickorderitem sp with(nolock) Left join istockledgerlog i with(nolock) on  i.sdorgid=@sdorgid and i.matcode=sp.MatCode		--�˴���Left Join ȡ������������Ʒ�����ݡ�
				inner join istockledgerlog i2 with(nolock) on sp.DocCode=i2.doccode and i2.matcode=sp.MatCode
				where sp.DocCode=@Doccode
				and (i.indigit<0 or i.outdigit>0)						--������������0,���������С��0,����Ϊ�ǳ���
				and i.inserttime<i2.inserttime
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
				/*--���п�棬���������ʱ�ɱ�
				update a
					set a.totalmoney=a.digit*isnull(1.0000*iml.StockValue/nullif(iml.Stock,0),0),
					a.ratemoney=a.digit*isnull(1.0000*iml.ratevalue/nullif(iml.Stock,0),0)
				from #table a inner join iMatsdorgLedger iml with(nolock)
					on a.matcode=iml.MatCode
					and iml.sdorgid=@SDOrgID*/
			END
		else
			BEGIN
				raiserror('��Ч��ѡ��ֵ,�޷�����ɱ�.',16,1)
				return
			END

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
	--Select * From #table
	select @XMLResult='<root>'
	--�������α�ѭ������ɱ�
	declare cur CURSOR READ_ONLY fast_forward forward_only for
	select a.matcode,a.Rowid,a.digit,a.totalmoney,a.ratemoney,a.Mode,a.ComputeType
	From #table a  inner join iMatGeneral img with(nolock) on a.MatCode=img.MatCode
		inner join iMatGroup img2 with(nolock) on img.MatGroup=img2.matgroup
	where  (@InputMatcode='' or exists(select 1 from commondb.dbo.SPLIT(isnull(@InputMatcode,''),',') s where img.MatCode=s.List))
		and (@InputMatgroup='' or  exists(select 1 from commondb.dbo.SPLIT(isnull(@InputMatgroup,''),',') s where img2.PATH like '%/'+s.List+'/%'))
		and isnull(a.digit,0)<>0										--����Ϊ0����Ʒ����
		and isnull(img.MatState,0)=1								--�ǿ����Ʒ����
	order by a.ID
	open cur
	fetch next FROM cur into @matcode,@rowid,@digit,@totalmoney,@ratemoney,@mode,@type
	while @@FETCH_STATUS=0
		BEGIN
			BEGIN TRY
				--print '�����쳣:'+isnull(@Companyid,'') +','+isnull(@PeriodID,'') +','+isnull(@SDOrgID,'') +','+convert(varchar(10),@FormID)+','+ @Doccode+','+@matcode+','+convert(varchar(10),isnull(@Digit,0))+','+convert(varchar(10),isnull(@totalmoney,0))+','+convert(varchar(10),isnull(@ratemoney,0))+'>>>>'+convert(varchar(30),getdate(),120)
				exec sp_ComputeSdorgMatLedger @Doccode,@FormID,@rowid,@matcode,@Companyid,@sdorgid,@PeriodID,@digit,@totalmoney,@ratemoney,@mode,@type,@XMLData output
			END TRY
			BEGIN CATCH
				 --select * from #table
				 --select * from iMatsdorgLedger iml where iml.sdorgid=@SDOrgID and iml.MatCode=@matcode
				select @tips= '�����쳣:'+isnull(@Companyid,'') +','+isnull(@PeriodID,'') +','+isnull(@SDOrgID,'') +','+convert(varchar(10),@FormID)+','+ @Doccode+','+@matcode+','+convert(varchar(10),isnull(@Digit,0))+','+convert(varchar(10),isnull(@totalmoney,0))+','+convert(varchar(10),isnull(@ratemoney,0))+','+convert(varchar(50),@mode)+'>>>>'+convert(varchar(30),getdate(),120)
				select @tips=@tips +char(10)+dbo.getLastError('�ɱ����㷢������.')
				if error_number()=8134 or @matcode like '2.%'
					BEGIN
						print @tips
					END
				else
				BEGIN
						raiserror(@tips,16,1)
						return
					END
			END CATCH
			
			--�����������,�����ӵ�XML�����
			if @XMLData<>'' Select @XMLResult=@XMLResult+@XMLData
			fetch next FROM cur into @matcode,@rowid,@digit,@totalmoney,@ratemoney,@mode,@type
		END
	close cur
	deallocate cur
	--ѭ�����,����XML������
	select @XMLResult=@XMLResult+'</root>'
	--��XML��ԭ����ʱ��,���������
	exec sp_xml_preparedocument @hDocument output,@XMLResult
	Insert Into #XMLDataTable
	Select * From OpenXML(@hDocument,'/root/row',1) with #XMLDataTable
	exec sp_XML_RemoveDocument @hDocument
	--print @XMLResult
	--select * From #XMLDataTable
	/*insert into #ResultTable(Doccode,Formid,refformid,refcode,plantid,sdorgid,periodid,matcode,rowid,
	oldstock,oldstockvalue,oldratevalue,
	digit,totalmoney,ratemoney,
	stock,stockvalue,ratevalue,
	mode,computetype,optionid)
	select @Doccode,@FormID,@RefFormID,@RefCode,@CompanyID,@SDOrgID,@PeriodID,Matcode,RowID,
	OldStock,OldStockValue,OldRateValue,Digit,Totalmoney,RateMoney,
	Stock,StockValue,RateValue,Mode,ComputeType,@OptionID 
	From #XMLDataTable*/
	--ִ�����
	begin try
		
		exec sp_outputMatLedgerResult @Doccode,@FormID,@DocDate,@Companyid,@SDOrgID ,@PeriodID,@OptionID,@Usercode,@TerminalID
	end try
	BEGIN catch
		--select * from #table
		select @tips= '�����쳣:'+isnull(@Companyid,'') +','+isnull(@PeriodID,'') +','+isnull(@SDOrgID,'') +','+convert(varchar(10),@FormID)+','+ isnull(@Doccode,'')+','+isnull(@matcode,'')+','+convert(varchar(10),isnull(@Digit,0))+','+convert(varchar(10),isnull(@totalmoney,0))+','+convert(varchar(10),isnull(@ratemoney,0))+'>>>>'+convert(varchar(30),getdate(),120)
		select @tips=@tips+char(10)+dbo.getLastError('����ɱ����ݴ���.')
		raiserror(@tips,16,1)
		return
	END catch
	return
END