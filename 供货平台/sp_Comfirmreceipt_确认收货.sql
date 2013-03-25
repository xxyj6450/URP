/*
函数名称:sp_ComfirmReceipt
功能:确认收货
参数:见声名
返回值:
编写:三断笛
时间:2012-11-21
备注:该过程仅在供货平台执行
业务逻辑:
	若单据已经收货,则抛出异常
	确认收货时,将供货平台发货的串号准备好,待写入URP.
	若URP平台已经存在应收的此串号,收抛出异常,中止发货.
	若发货仓库为URP销售平台,则不转移串号.否则需要转移串号.
	若URP平台已经存在已售的此串号,则将URP中已存在的已售串号转移至已售串号表,再将新串号转移至URP串号表.
	转移URP已有串号时记录操作日志;将串号转移至URP时记录操作日志.
	回填送货单收货状态.
示例:

HYQ201303220000000010
 
begin tran
exec sp_ComfirmReceipt 'JDC2013013100000',4950,'SYSTEM','2.1.769.26.01','111.769','','FF2DCB8D-62C1-463C-8684-1A869E2F1117','1',''
 select * from urp11.jturp.dbo.icoupons where stcode='2.1.769.26.01'
 select * from urp11.jturp.dbo.strategylog 
 select * from urp11.jturp.dbo.coupons_d where doccode='QZS2013012300000'
 update iseries
	set state='送货'
 where seriescode='111222222222222'
  rollback
  commit
 set xact_abort on
 begin tran
exec sp_ComfirmReceipt 'JDC2013010600260',4950,'SYSTEM','2.1.512.02.50','001.512','','FF2DCB8D-62C1-463C-8684-1A869E2F1117',''
 select * from urp11.jturp.dbo.icoupons where stcode='2.1.512.02.50'
 select * from urp11.jturp.dbo.strategylog 
 select * from urp11.jturp.dbo.coupons_d where doccode='QZS2013012200000'
 select * from urp11.jturp.dbo.iseries where seriescode in('869459018502979')
begin tran
exec sp_ComfirmReceipt 'JDC2012121500460',4950,'SYSTEM','2.1.791.03.25','111.769','','E36D5919-925A-4C78-95FB-B9E0A2007A6F','1',''

*/
 
alter proc sp_ComfirmReceipt
	@Doccode varchar(20),						--单号
	@Formid int,										--功能号
	@Usercode varchar(50),						--用户名
	@stcode varchar(50)='',						--收货仓库
	@fhstcode varchar(50)='',					--分货仓库
	@remark varchar(50)='',						--备注
	@InstanceID varchar(50)='',				--v_spickorderhd_Distributed的InstanceID
	@optionID varchar(50)='',					--收货传1
	@TerminalID varchar(50)=''					--终端编码
as
	BEGIN
		set NOCOUNT on;
		set XACT_ABORT on;
		
		/***************************************************变量声名*********************************************************************/
		declare @refcode varchar(20),  @sql nvarchar(max),@tips varchar(max),@ret int,
		@trancount int,@SQL_Seriescode varchar(max),@sql_Fields varchar(max),
		@AccessName varchar(200),@SYSTEMNAME varchar(50),@SeriesRowcount INT,
		@DatabaseName VARCHAR(50),@ServerName VARCHAR(50),@rowcount int,@DocDataXML nvarchar(max),@ResultXML varchar(8000),@DataSourceXML nvarchar(max)
		declare @hXMLDocument int,@Definition varchar(max)
		/**************************************************参数检查********************************************************************/
		--若实例ID为空,则尝试从配送仓库中取出服务器实例ID
		if isnull(@InstanceID,'')=''
			BEGIN
				 select @InstanceID=ss.InstanceID
									from oStorage os with(nolock) inner join _sysSYSTEMS ss with(nolock) on os.SYSTEMID=ss.ID
				 if @@ROWCOUNT=0
					BEGIN
						raiserror('未找到发货平台信息,无法继续操作.',16,1)
						return
					END
			END
		--取出访问信息
		select @AccessName=si.AccessName
						  from _sysInstances si where si.InstanceID=@InstanceID
		if @@ROWCOUNT=0 or isnull(@AccessName,'')=''
			BEGIN
				raiserror('未找到发货平台访问信息,无法继续操作.',16,1)
				return
			END
		SELECT @ServerName=SUBSTRING(@AccessName,0,CHARINDEX('.',@AccessName))
		SELECT @DatabaseName=SUBSTRING(@AccessName,CHARINDEX('.',@AccessName)+1,50)
 
		/************************************************初始化数据******************************************************************/
		--创建串号临时表，用于存储本次收货的串号。不论是本地服务器还是远程服务器都先将串号存储进来，减少对串号表的操作和远程服务器操作。
		CREATE TABLE #iSeries (
			ID int,
			Seriescode VARCHAR(50),
			RowID VARCHAR(50),
			Matcode VARCHAR(50),
			MatName VARCHAR(50),
			Docitem INT,
			STATE VARCHAR(50),
			RefState varchar(50),
			CouponsBarcode varchar(50),
			CouponsCode varchar(50)
		)
		--创建数据源临时表,用于策略匹配
		Create TABLE #DataSource(
			Doccode varchar(20),
			FormID int,
			DocDate datetime,
			SDOrgID varchar(50),
			dptType varchar(50),
			stcode varchar(50),
			stName varchar(200),
			AreaID varchar(50),
			SDOrgPath varchar(200),
			AreaPath varchar(200),
			RowID varchar(50),
			SeriesCode varchar(50),
			Matcode varchar(50),
			MatName varchar(200),
			Matgroup varchar(50),
			MatgroupPath varchar(200),
			Digit int,
			Price money,
			Totalmoney money
		)
		--创建单据数据临时表,用于传入至策略执行中
		Create TABLE #DocData(
			Doccode varchar(20),
			FormID int,
			DocDate datetime,
			SDOrgID varchar(50),
			SDOrgName varchar(200),
			stcode varchar(50),
			stName varchar(200),
			dptType varchar(50),
			AreaID varchar(50),
			SDOrgPath varchar(200),
			AreaPath varchar(200)
			)
		--若送货单在本机，则直接从本机取数据。
		IF @InstanceID=dbo.InstanceID()
			BEGIN
				--取出串号单
				select @refcode=doccode from iseriesloghd i with(nolock) where i.refCode=@Doccode
				IF @@ROWCOUNT>0
					BEGIN
						--取出串号缓存至临时表,以供后续使用.
						INSERT INTO #iSeries(ID,Seriescode,RowID,Matcode,MatName,Docitem,STATE,RefState,CouponsBarcode,Couponscode)							
						select row_number() over(partition by i2.matcode order by (select 1)) as ID,
						i2.seriescode,i2.rowid,i2.matcode,i2.matname,i2.docitem,convert(varchar(20),'') as state,convert(varchar(20),'') as Refstate,
						Convert(varchar(50),'') as couponsBarcode,Convert(varchar(50),'') as couponscode
						from iserieslogitem i2 with(nolock)
						where i2.doccode=@refcode
						SELECT @SeriesRowcount=@@ROWCOUNT
					END
				ELSE
					BEGIN
						SELECT @SeriesRowcount=0
					END
				 
			END
		ELSE--若送货单不在本机，则从远程服务器取数据。
		BEGIN
 
				SELECT @sql='Select @Refcode=Doccode From Openquery('+@ServerName+','+dbo.crlf()+
				''' Select Doccode From '+@DatabaseName +'.dbo.iSeriesLogHD i with(nolock) Where i.refcode='''''+@Doccode+''''''')'
 
				EXEC sp_executesql @sql,N'@Refcode varchar(50) output',@refcode=@refcode OUTPUT
				IF @@ROWCOUNT>0
					BEGIN
						SELECT @Sql='INSERT INTO #iSeries(ID,Seriescode,RowID,Matcode,MatName,Docitem) '+dbo.crlf()+
						' select row_number() over(partition by i2.matcode order by (select 1)) as ID,'+dbo.crlf()+
						' i2.seriescode,i2.rowid,i2.matcode,i2.matname,i2.docitem'+dbo.crlf()+
						' from OpenQuery('+@ServerName +','+dbo.crlf()+
						''' Select Seriescode,RowID,Matcode,MatName,DocItem From '+@DatabaseName +'.dbo.iserieslogitem i2 with(nolock)'+dbo.crlf()+
						' where i2.doccode='''''+@refcode+''''''') i2'
						--print @sql
						EXEC(@sql)
						SELECT @SeriesRowcount=@@ROWCOUNT
					END
				ELSE
					BEGIN
						SELECT @SeriesRowcount=0
					END
			END
 
		--当存在串号时,取出串号信息
		IF isnull(@SeriesRowcount,0)>0
			BEGIN
				---取出这些串号在URP中的串号状态
				if @InstanceID=dbo.InstanceID()     
					BEGIN
 
						update a
							set a.state=b.state
						from #iseries a inner join dbo.iSeries b with(nolock) on a.seriescode=b.seriescode
						--生成单据数据源
						Insert Into #DataSource(Doccode,FormID,Docdate,SDOrgID,dptType,stcode,stname,AreaID,SDOrgPath,AreaPath,Seriescode,rowid,Matcode,MatName,Matgroup,MatgroupPath,Digit,Price,Totalmoney)
						select @Doccode,@Formid,convert(varchar(10),getdate(),120),sph.sdorgid2,os.dpttype,sph.instcode,sph.instname,os.AreaID,os.PATH,ga.PATH,
						sp.Seriescode,sp.rowid,sp.MatCode,sp.MatName,img.MatGroup,img2.PATH,sp.Digit,sp.price,sp.totalmoney
						From sPickorderHD sph with(nolock) inner join sPickorderitem sp with(nolock) on sph.DocCode=sp.DocCode
						inner join oSDOrg os with(nolock) on sph.sdorgid2=os.SDOrgID
						inner join gArea ga with(nolock) on os.AreaID=ga.areaid
						inner join iMatGeneral img with(nolock) on sp.MatCode=img.MatCode
						inner join iMatGroup img2 with(nolock) on img.MatGroup=img2.matgroup
						where sph.DocCode=@Doccode
						Insert Into #DocData(Doccode,FormID,Docdate,SDOrgID,stcode,stname,dptType,AreaID,SDOrgPath,AreaPath)
						select @Doccode,@Formid,convert(varchar(10),getdate(),120),sph.sdorgid2,sph.instcode,sph.instname,os.dpttype,os.AreaID,os.PATH,ga.PATH
						From sPickorderHD sph with(nolock) --inner join sPickorderitem sp with(nolock) on sph.DocCode=sp.DocCode
						inner join oSDOrg os with(nolock) on sph.sdorgid2=os.SDOrgID
						inner join gArea ga with(nolock) on os.AreaID=ga.areaid
						where sph.DocCode=@Doccode
					END
				ELSE
				BEGIN
						---取出这些串号在URP中的串号状态
						update a
							set a.state=b.state
						from #iseries a inner join URP11.JTURP.dbo.iSeries b with(nolock) on a.seriescode=b.seriescode
						--生成单据数据源
					select @sql='	Insert Into #DataSource(Doccode,FormID,Docdate,SDOrgID,dptType,stcode,stname,AreaID,SDOrgPath,AreaPath,'+char(10)
						+' rowid,Seriescode,Matcode,MatName,Matgroup,MatgroupPath,Digit,Price,Totalmoney)'+char(10)
						+' select @Doccode,@Formid,convert(varchar(10),getdate(),120),sph.sdorgid2,dpttype,sph.instcode,sph.instname,AreaID,SDOrgPATH,AreaPATH,'+char(10)
						+' RowID,Seriescode,MatCode,MatName,MatGroup,MatgroupPATH,Digit,price,totalmoney'+char(10)
						+' From OpenQuery('+@ServerName+',''Select sph.sdorgid2,os.dpttype,sph.instcode,sph.instname,os.AreaID,os.PATH as SDOrgPath,ga.PATH as AreaPath,'+char(10)
						+' sp.rowid,sp.Seriescode,sp.MatCode,img.MatName,img.MatGroup,img2.PATH as MatgroupPath,'+char(10)
						+' sp.Digit,sp.price,sp.totalmoney'+char(10)
						+' From '+@DatabaseName +'.dbo.sPickorderHD sph with(nolock) inner join '+@DatabaseName +'.dbo.sPickorderitem sp with(nolock) on sph.DocCode=sp.DocCode'+char(10)
						+'	inner join '+@DatabaseName +'.dbo.oSDOrg os with(nolock) on sph.sdorgid2=os.SDOrgID'+char(10)
						+'	inner join '+@DatabaseName +'.dbo.gArea ga with(nolock) on os.AreaID=ga.areaid'+char(10)
						+'	inner join  '+@DatabaseName +'.dbo.iMatGeneral img with(nolock) on sp.MatCode=img.MatCode'+char(10)
						+'	inner join  '+@DatabaseName +'.dbo.iMatGroup img2 with(nolock) on img.MatGroup=img2.matgroup'+char(10)
						+'	where sph.DocCode='''''+@Doccode+''''''') sph'
						--print @sql
						exec sp_executesql @sql,N'@Doccode varchar(20),@FormID int',@Doccode=@Doccode,@Formid=@Formid
						select @sql='	Insert Into #DocData(Doccode,FormID,Docdate,SDOrgID,stcode,stname,dptType,AreaID,SDOrgPath,AreaPath)'+char(10)
						+' select @Doccode,@Formid,convert(varchar(10),getdate(),120),sdorgid2,instcode,instname,dpttype,AreaID,SDorgPATH,AreaPATH'+char(10)
						+' From OpenQuery('+@ServerName+',''Select sph.sdorgid2,sph.instcode,sph.instname,sph.dpttype,os.AreaID,os.PATH as SDOrgPath,ga.PATH as AreaPath'+char(10)
						+' From '+@DatabaseName +'.dbo.sPickorderHD sph with(nolock) '+char(10)
						+'	inner join '+@DatabaseName +'.dbo.oSDOrg os with(nolock) on sph.sdorgid2=os.SDOrgID'+char(10)
						+'	inner join '+@DatabaseName +'.dbo.gArea ga with(nolock) on os.AreaID=ga.areaid'+char(10)
						+'	where sph.DocCode='''''+@Doccode+''''''') sph'
						--print @sql
						exec sp_executesql @sql,N'@Doccode varchar(20),@FormID int',@Doccode=@Doccode,@Formid=@Formid
				END
				SELECT @tips='以下串号不在送货状态,无法收货.'+dbo.crlf()
				SELECT @tips=@tips+seriescode+'目前状态为['+ISNULL(STATE,'')+']'+dbo.crlf()
				FROM #iSeries
				WHERE ISNULL(STATE,'')<>'送货'
				IF @@ROWCOUNT>0
					BEGIN
						RAISERROR(@tips,16,1)
						return
					END
			END
		--将数据源转换成XML
		if exists(select 1 from #DocData)
			BEGIN
				set @DocDataXML=(select * from #DocData for xml raw,root('root'))
				
				--将业务数据接入
				set @Definition='Doccode varchar(20),	FormID int,DocDate datetime,SDOrgID varchar(50),dptType varchar(50),AreaID varchar(50),SDOrgPath varchar(200),stcode varchar(50),stName varchar(200),
				AreaPath varchar(200),SeriesCode varchar(50),RowID varchar(50),Matcode varchar(50),MatName varchar(200),Matgroup varchar(50),MatgroupPath varchar(200),Digit int,Price money,Totalmoney money'
				set @DataSourceXML= (select * from #DataSource ds for xml raw)
				select @DataSourceXML='<root><DataTable TableName="#XMLDataSource" Definition="' +@Definition+'">'+@DataSourceXML+'</DataTable>'
				--select @DataSourceXML='<DataTable TableName="#DocData" Definition="'+@Definition+'">'+@DocDataXML+'</DataTable>'
				
				--再将串号数据也拼入
				select @Definition='ID int,Seriescode VARCHAR(50),	RowID VARCHAR(50),Matcode VARCHAR(50),MatName VARCHAR(50),Docitem INT,STATE VARCHAR(50)'
				select @DataSourceXML=@DataSourceXML+'<DataTable TableName="#iSeries" Definition="'+@Definition +'">'+
				Convert(nvarchar(max),(Select ID,Seriescode,RowID,Matcode,MatName,Docitem,state from #iSeries For xml raw))+'</DataTable></root>'
				
			END
		--print @DataSourceXML
		/***********************************************************业务处理****************************************************/
		select @TRANCOUNT=@@TRANCOUNT
		if @trancount=0 begin tran
		begin try
			--执行优惠券策略
			exec @ret=URP11.JTURP.dbo.sp_DistributedExecuteStrategy @Formid,@Doccode,4,'',@Usercode,@TerminalID,@DocDataXML ,@DataSourceXML,@ResultXML output
 
			--将串号与优惠券绑定
			if isnull(@ResultXML,'')<>''
				BEGIN
					--此处需要将varchar(8000)转换成nvarchar(max)
					declare @data nvarchar(max)
					select @Data=convert(nvarchar(max),@ResultXML)
					exec sp_xml_preparedocument @hXMLDocument output,@data
					update a
						set a.CouponsBarcode=b.Couponsbarcode,
						a.CouponsCode=b.couponscode
					from #iSeries a,OpenXML(@hXMLDocument,'/root/Strategygroup/OutputStrategy/row',1)   with(Seriescode varchar(50),CouponsBarCode varchar(50),CouponsCode varchar(50)) b
					where a.Seriescode=b.seriescode
					exec sp_xml_removedocument @hXMLDocument
				END
			--回填送货单
			if @InstanceID=dbo.InstanceID()
				BEGIN
					--更新单据状态
					update sPickorderHD
						set getok='已收货',
						getday=convert(varchar(30),getdate(),120),
						getname = @Usercode
					where DocCode=@Doccode
					and isnull(getok,'未收货')='未收货'
					and DocStatus<>0
					if @@ROWCOUNT=0
						BEGIN
							raiserror('找不到送货单或送货单不在可收货状态,请核实此单是否已发货,若有疑问请联系当地总仓.',16,1)
							return
						END
					IF isnull(@SeriesRowcount,0)>0
						BEGIN
							--再更新串号状态
							UPDATE A
								SET a.[state]='应收',
								a.CouponsBarcode=b.CouponsBarcode,
								a.CouponsCode=b.CouponsCode
							FROM iSeries a WITH(NOLOCK),#iseries b
							WHERE a.SeriesCode=b.seriescode
							AND a.[state]='送货'
							IF @@ROWCOUNT=0
								BEGIN
									RAISERROR('没有串号送货成功,请重试,若重试后问题仍未得到解决,请联系发货仓库.',16,1)
									return
								END
							--再更新串号状态
							UPDATE b
								SET b.[refstate]=a.state
							FROM URP11.JTURP.dbo.iSeries a WITH(NOLOCK),#iseries b
							WHERE a.SeriesCode=b.seriescode
							
						END
				END
			else
			BEGIN
					--PRINT '更新单据状态'
					select @sql='Update Openquery('+@ServerName+',''Select getok,getday,getname,doccode From '+dbo.crlf()+
					@DatabaseName+'.dbo.spickorderhd '+dbo.crlf()+
					' where DocCode='''''+@Doccode+''''''+dbo.crlf()+
					' And Docstatus<>0 and isnull(getok,''''未收货'''')=''''未收货'''''')'+dbo.crlf()+
					' set getok=''已收货'','+dbo.crlf()+
					'	getday=convert(varchar(30),getdate(),120),'+dbo.crlf()+
					'	getname = '''+@Usercode+''''+dbo.crlf()
					--PRINT @sql
					exec(@sql)
					if @@ROWCOUNT=0
						BEGIN
							--PRINT @AccessName
							raiserror('找不到送货单或送货单不在可收货状态,请核实此单是否已发货,若有疑问请联系当地总仓.',16,1)
							return
						END
 
					--再更新串号状态
					IF isnull(@SeriesRowcount,0)>0
						BEGIN
							--PRINT '更新串号状态'
							select @SQL_Seriescode=''
							select @SQL_Seriescode=@SQL_Seriescode+''''''+seriescode+''''''+','
							from #iseries 
							where state='送货'
							select @SQL_Seriescode=left(@SQL_Seriescode,len(@SQL_Seriescode)-1)
							select @sql='UPDATE openquery( '+@ServerName+','+ dbo.crlf()
							+'''Select State From '+@DatabaseName+'.dbo.iSeries where State=''''送货'''' And Seriescode in('+@SQL_Seriescode+')'') '
							+'	SET [state]=''应收'''+dbo.crlf()
 
							EXEC(@sql)
							IF @@ROWCOUNT=0
								BEGIN
									RAISERROR('没有串号送货成功,请重试,若重试后问题仍未得到解决,请联系发货仓库.',16,1)
									return
								END						
						END
						
				END
				
			--如果发货平台(串号来源)就是URP销售系统(目的系统),就不再对串号进行处理了
			if @AccessName='URP11.JTURP' RETURN
			--若没有串号,也不往下执行
			IF ISNULL(@SeriesRowcount,0)<=0 RETURN
 
			--取出串号表字段
			select @sql_Fields=''
			select @sql_Fields=@sql_Fields+s.name+','
			from syscolumns s
			where s.id=object_id('iSeries')
			select @sql_Fields=left(@sql_Fields,len(@sql_Fields)-1)
			--判断串号在URP系统中是否存在,若存在非已售的串号,则抛出异常.
 
			select @tips='以下串号已在URP系统中已存在,无法继续操作.'+dbo.crlf()
			select @tips=@tips+convert(varchar(5),b.docitem)+'.'+b.seriescode+'['+b.matname+'],库存状态为[' +isnull(b.refstate,'')+']'+dbo.crlf()
			from   #iSeries b
			where isnull(b.refstate,'已售') not in('已售','送货','出库','')
			if @@ROWCOUNT>0
				BEGIN
					raiserror(@tips,16,1)
					return
				END
 
			--将URP中已售的串号移走
			select @SQL_Seriescode=''
			select @SQL_Seriescode=@SQL_Seriescode+''''+a.seriescode+''''+','
			from #iseries a
			where a.refstate in('已售','出库')
 
			if @@ROWCOUNT>0
				BEGIN
					--取出串号字符串
					select @SQL_Seriescode=left(@SQL_Seriescode,len(@SQL_Seriescode)-1)
					--
					/*
					insert into openquery(URP11,'Select '+@sql_Fields +' From JTURP.dbo.iSeriesSales')
					select @sql_Fields From  openquery(URP11,'Select '+@sql_Fields+' From JTURP.iSeries where seriescode in('+@SQL_Seriescode+')')
					*/
 
					
						--将已售串号移入已售串号表
						SET @sql = 'insert into openquery(URP11,''Select '+@sql_Fields +' From JTURP.dbo.iSeriesSales'') ' + char(10)
								 + '				select '+@sql_Fields +' From  openquery(URP11,''Select '+@sql_Fields +' From JTURP.dbo.iSeries where seriescode in('+replace(@SQL_Seriescode,'''','''''')+')'')'
						--print @sql
						
						exec sp_executesql @sql,N'@sql_Fields varchar(max),@SQL_Seriescode varchar(max)',
						@sql_Fields=@sql_Fields,@SQL_Seriescode=@SQL_Seriescode
						if @@ROWCOUNT>0
							BEGIN
								--删除串号
								/*
								delete from openquery(URP11,'select seriescode from JTURP.dbo.iSeries is2 where seriescode in('+@SQL_Seriescode+')')
								*/
 
 
								SET @sql = 'delete from openquery(URP11,''select seriescode from JTURP.dbo.iSeries is2 where seriescode in('+replace(@SQL_Seriescode,'''','''''')+')'')'
								exec sp_executesql @sql,N'@SQL_Seriescode varchar(max)',@SQL_Seriescode=@SQL_Seriescode
								--记录操作日志
								SET @sql = 'insert into openquery(URP11,''Select Seriescode,Formid,Formtype,doccode,doctype,stcode,instcode,remark  From JTURP.dbo.iSeriesLog'') ' + char(10)
								 + '				select Seriescode,Formid,Formtype,doccode,doctype,stcode,instcode,remark '+ dbo.crlf()+
								 ' From  openquery(URP11,''Select seriescode,4950 as formid,5 as formtype,'''''+@doccode + ''''' as doccode,'+dbo.crlf()+
								 '''''加盟商送货单'''' as doctype,'''''+@stcode+''''' as instcode,'''''+@fhstcode+''''' as stcode,''''加盟商收货转出已售串号'''' as remark '+dbo.crlf()+
								 ' From JTURP.dbo.iSeries where seriescode in(' +replace(@SQL_Seriescode,'''','''''')+')'')'
								 
								exec sp_executesql @sql,N'@Formid int,@doccode varchar(30),@stcode varchar(50),@fhstcode varchar(50)',
								@formid=@formid,@Doccode=@Doccode,@stcode=@stcode,@fhstcode=@fhstcode--,@remark=@remark
							END
					end
					
					--将其余串号写入串号表
					/*insert into openquery(URP11,'Select '+@SQL_Seriescode+' From JTURP.dbo.iseries')
					select is2.* from iSeries is2 with(nolock) inner join #iseries b on is2.SeriesCode=b.seriescode
					where b.state is null*/
					
					SET @sql = 'insert into openquery(URP11,''Select '+@sql_Fields+' From JTURP.dbo.iseries'') ' + char(10)
							 + '			select is2.* from iSeries is2 with(nolock) inner join #iseries b on is2.SeriesCode=b.seriescode ' + char(10)
							 + '			where b.state=''送货'''
  
					EXEC ( @sql)
					select @rowcount=@@ROWCOUNT
 
					--记录操作日志
					if @ROWCOUNT>0
						BEGIN
 
							SET @sql = 'insert into openquery(URP11,''Select Seriescode,Formid,Formtype,doccode,doctype,stcode,instcode,remark  From JTURP.dbo.iSeriesLog'') ' + char(10)
									 + '				select  seriescode,4950 as formid,5 as formtype,'''+@doccode+''' as doccode,'+dbo.crlf()+
									 '''加盟商送货单'' as doctype,'''+@stcode+''' as instcode,'''+@fhstcode+''' as stcode,''加盟商收货转入新串号'' as remark '+dbo.crlf()+
									 ' From #iSeries where state=''送货'''
									-- print @sql
									exec sp_executesql @sql/*,N'@Formid int,@SQL_Seriescode varchar(max),@doccode varchar(30),@stcode varchar(50),@fhstcode varchar(50)',
									@formid=@formid,@SQL_Seriescode=@SQL_Seriescode,@Doccode=@Doccode,@stcode=@stcode,@fhstcode=@fhstcode,@remark=@remark*/
						END
					ELSE
					BEGIN
 
							RAISERROR('未能将串号转移至URP销售系统,请联系系统管理员.',16,1)
							return
						END
					--操作完毕回填事务
					if @TRANCOUNT=0  commit
			END TRY
			begin catch
				if @trancount=0 and @@TRANCOUNT>0 rollback
				select @tips=dbo.getLastError('收货发生异常.')
				raiserror(@tips,16,1)
				return
			end catch
	END
	
	 