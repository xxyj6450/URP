/*
ʾ��:
begin tran
 
exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-01','2013-01-31','','','','','RT20130124000000','',''
 
rollback
commit
 
*/

 
alter proc sp_ExecuteRecomputeSDorgMatLedger
	@BeginDate DATETIME='',									--������ʼʱ��
	@EndDate datetime='',										--�������ʱ��
	@CompanyID varchar(200)='',								--���㹫˾,���ö��ŷָ������˾
	@SDorgID varchar(200)='',									--���㲿��,���������ⲿ�Žڵ�,���ö��ŷָ��������
	@Matgroup varchar(max)='',								--������Ʒ����,�������������ڵ�,���ö��ŷָ��������
	@Matcode varchar(max)='',									--������Ʒ����,���ö��ŷָ������Ʒ����
	@OptionID varchar(200)='',									--ѡ��ֵ
	@StartID int=0,													--��ʼID,�ɴӿ����ϸ��ָ����ID��ʼ����
	@Usercode varchar(50)='',									--ִ����
	@TerminalID varchar(50)=''									--ִ���ն�
as
	BEGIN
		set NOCOUNT ON
		declare @Doccode varchar(50),@FormID int,@DocDate datetime,@SDorgID1 varchar(50),@InsertTime datetime,@Stcode varchar(50)
		declare @CompanyID1 varchar(50),@PeriodID varchar(7),@RefCode varchar(50),@RefFormID int,@tips varchar(max)
		declare cur_Doc CURSOR READ_ONLY fast_forward forward_only  for
		--��InsertTime����,ÿ�����ݵ�Inserttime��ͬ,��Inserttime�������
		Select  i.Doccode,i.formid,i.docdate,i.companyid,i.periodid,i.sdorgid, max(i.inserttime) as inserttime
		From istockledgerlog i with(nolock)
		inner join iMatGeneral img with(nolock) on i.matcode=img.MatCode
		inner join iMatGroup img2 with(nolock) on img.MatGroup=img2.matgroup
		where (@BeginDate='' or i.docdate>=@BeginDate)
		and (@EndDate='' or i.docdate<=@EndDate)
		and (@CompanyID='' or exists(select 1 from commondb.dbo.split(isnull(@CompanyID,''),',') x where  i.companyid=x.List))
		and (@SDorgID='' or exists(select 1 from commondb.dbo.split(isnull(@SDorgID,''),',') x where  i.sdorgid=x.List))
		and (@Matcode='' or exists(select 1 from commondb.dbo.split(isnull(@Matcode,''),',') x where  iMG.matcode=x.List))
		and (@Matgroup='' or exists(select 1 from commondb.dbo.split(isnull(@Matgroup,''),',') x where  img2.path like '%/'+x.List+'/%'))
		and i.formid in(1501,1504,1507,1509,1520,1523,1553,1557,1598,1599,2401,2418,2419,2420,2450,4032,4061,4630,4631,4950,4951)
		and (@OptionID='' or i.doccode=@OptionID)
		and i.ID>=@StartID
		and isnull(digit,0)<>0														--���˵�����Ϊ����
		group by i.doccode,i.formid,i.docdate,i.CompanyID,i.PeriodID,i.SDorgID,inserttime
		order by inserttime
 
		open cur_Doc
		fetch next FROM cur_Doc into @Doccode,@FormID,@DocDate,@CompanyID1,@PeriodID,@SDorgID1,@InsertTime
		
		while @@FETCH_STATUS=0
			BEGIN
 
				--print @CompanyID1 +','+@PeriodID +','+convert(varchar(10),@FormID)+','+ @Doccode
				--������ⵥȡ�����γ�����Ϣ
				if @FormID  in(1507)
					BEGIN
						select @RefCode=refCode,@RefFormID=2424
						from imatdoc_h with(nolock)
						where DocCode=@Doccode
					END
				--�����˻���ȡ��ԭ�˻���
				if @FormID in(2420)
					BEGIN
						select @RefFormID=2419,@RefCode=sph.ClearDocCode
						from sPickorderHD sph with(nolock)
						where sph.DocCode=@Doccode
					END
				--��˾�ڲɹ����ȡ����˾�����۳��ⵥ��Ϣ
				if @FormID in(4061)
					BEGIN
						select @RefFormID=4031,@RefCode=refcode
						from imatdoc_h a with(nolock)
						where a.DocCode=@Doccode
					END
				--4032�ڲ������˻������ڲ��ɹ��˻��ĳ���ɱ����
				if @FormID in(4032)
					BEGIN
						select @RefFormID=4062,@RefCode=refcode
						From spickorderhd a with(nolock)
						where a.DocCode=@Doccode
					END
				--���ŵ������������� �ȼ������
				if @FormID in(1553,1557)
					BEGIN
						select @Optionid=1
					END
			BEGIN TRY
				exec sp_ReComputeSDorgMatLedger @FormID,@Doccode,@CompanyID1,@PeriodID,@SDorgID1,
				@DocDate,@Matgroup,@Matcode,@RefFormID,@RefCode,@Optionid,@InsertTime ,@Usercode,@TerminalID
				--���ŵ������������� ����Ҫ�ټ������
				if @FormID in(1553,1557)
					BEGIN
						select @Optionid=2
						exec sp_ReComputeSDorgMatLedger @FormID,@Doccode,@CompanyID1,@PeriodID,@SDorgID1,
						@DocDate,@Matgroup,@Matcode,@RefFormID,@RefCode,@Optionid,@InsertTime ,@Usercode,@TerminalID
					END
			END TRY
			BEGIN CATCH
				select @tips=dbo.getLastError('')
				close cur_Doc
				deallocate cur_doc
				raiserror(@tips,16,1)
				return
			END CATCH
				
					fetch next FROM cur_Doc into @Doccode,@FormID,@DocDate,@CompanyID1,@PeriodID,@SDorgID1,@InsertTime
			END
		close cur_Doc
		deallocate cur_doc
	END
	
 
	