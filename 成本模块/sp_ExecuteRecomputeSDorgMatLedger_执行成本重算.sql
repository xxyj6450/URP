/*
示例:
begin tran
 
exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-01','2013-01-31','','','','','RT20130124000000','',''
 
rollback
commit
 
*/

 
alter proc sp_ExecuteRecomputeSDorgMatLedger
	@BeginDate DATETIME='',									--重算起始时间
	@EndDate datetime='',										--重算结束时间
	@CompanyID varchar(200)='',								--重算公司,可用逗号分隔多个公司
	@SDorgID varchar(200)='',									--重算部门,可以是任意部门节点,可用逗号分隔多个部门
	@Matgroup varchar(max)='',								--重算商品大类,可以是任意大类节点,可用逗号分隔多个大类
	@Matcode varchar(max)='',									--重算商品编码,可用逗号分隔多个商品编码
	@OptionID varchar(200)='',									--选项值
	@StartID int=0,													--起始ID,可从库存明细账指定的ID开始重算
	@Usercode varchar(50)='',									--执行人
	@TerminalID varchar(50)=''									--执行终端
as
	BEGIN
		set NOCOUNT ON
		declare @Doccode varchar(50),@FormID int,@DocDate datetime,@SDorgID1 varchar(50),@InsertTime datetime,@Stcode varchar(50)
		declare @CompanyID1 varchar(50),@PeriodID varchar(7),@RefCode varchar(50),@RefFormID int,@tips varchar(max)
		declare cur_Doc CURSOR READ_ONLY fast_forward forward_only  for
		--按InsertTime排序,每个单据的Inserttime相同,按Inserttime排序计算
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
		and isnull(digit,0)<>0														--过滤掉数量为０的
		group by i.doccode,i.formid,i.docdate,i.CompanyID,i.PeriodID,i.SDorgID,inserttime
		order by inserttime
 
		open cur_Doc
		fetch next FROM cur_Doc into @Doccode,@FormID,@DocDate,@CompanyID1,@PeriodID,@SDorgID1,@InsertTime
		
		while @@FETCH_STATUS=0
			BEGIN
 
				--print @CompanyID1 +','+@PeriodID +','+convert(varchar(10),@FormID)+','+ @Doccode
				--调拔入库单取出调拔出库信息
				if @FormID  in(1507)
					BEGIN
						select @RefCode=refCode,@RefFormID=2424
						from imatdoc_h with(nolock)
						where DocCode=@Doccode
					END
				--零售退货单取出原退货单
				if @FormID in(2420)
					BEGIN
						select @RefFormID=2419,@RefCode=sph.ClearDocCode
						from sPickorderHD sph with(nolock)
						where sph.DocCode=@Doccode
					END
				--公司内采购入库取出公司内销售出库单信息
				if @FormID in(4061)
					BEGIN
						select @RefFormID=4031,@RefCode=refcode
						from imatdoc_h a with(nolock)
						where a.DocCode=@Doccode
					END
				--4032内部销售退货，以内部采购退货的出库成本入库
				if @FormID in(4032)
					BEGIN
						select @RefFormID=4062,@RefCode=refcode
						From spickorderhd a with(nolock)
						where a.DocCode=@Doccode
					END
				--串号调整，返厂返回 先计算出库
				if @FormID in(1553,1557)
					BEGIN
						select @Optionid=1
					END
			BEGIN TRY
				exec sp_ReComputeSDorgMatLedger @FormID,@Doccode,@CompanyID1,@PeriodID,@SDorgID1,
				@DocDate,@Matgroup,@Matcode,@RefFormID,@RefCode,@Optionid,@InsertTime ,@Usercode,@TerminalID
				--串号调整，返厂返回 还需要再计算入库
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
	
 
	