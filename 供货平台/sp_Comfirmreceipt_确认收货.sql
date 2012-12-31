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
begin tran
exec sp_ComfirmReceipt 'JDC2012121700326',4950,'SYSTEM','2.1.755.61.12','D101.01','','1243010B-4C4E-40FE-AAC5-B3AD367AA74D','1',''
 
 update iseries
	set state='送货'
 where seriescode='111222222222222'
 rollback
 set xact_abort on
 begin tran
exec sp_ComfirmReceipt 'JDC2012121802580',4950,'SYSTEM','2.1.020.09.05','001.020','','E36D5919-925A-4C78-95FB-B9E0A2007A6F','1',''

begin tran
exec sp_ComfirmReceipt 'JDC2012121500460',4950,'SYSTEM','2.1.791.03.25','111.769','','E36D5919-925A-4C78-95FB-B9E0A2007A6F','1',''

 
select instanceid,stcode,instcode from spickorderhd where doccode='JDC2012112800026'
print dbo.instanceid()
rollback
1.868429010299206[联想A60+黑色]
select * from ostorage where stcode='102'2.862726019083960[中兴V889D-WCDMA黑色]
print dbo.instanceid()488EFECF-8488-40D4-A4AF-36B1216D07483.867439011788645[天语W619渠道版黄色]
 4.866022011488076[联想A690黑色]
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
		declare @refcode varchar(20),  @sql nvarchar(max),@tips varchar(max),
		@trancount int,@SQL_Seriescode varchar(max),@sql_Fields varchar(max),
		@AccessName varchar(200),@SYSTEMNAME varchar(50),@SeriesRowcount INT,
		@DatabaseName VARCHAR(50),@ServerName VARCHAR(50),@rowcount int
		
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
		CREATE TABLE #iSeries (
			Seriescode VARCHAR(50),
			RowID VARCHAR(50),
			Matcode VARCHAR(50),
			MatName VARCHAR(50),
			Docitem INT,
			STATE VARCHAR(50),
			RefState varchar(50)
		)
		IF @InstanceID=dbo.InstanceID()
			BEGIN
				--取出串号单
				select @refcode=doccode from iseriesloghd i with(nolock) where i.refCode=@Doccode
				IF @@ROWCOUNT>0
					BEGIN
						--取出串号缓存至临时表,以供后续使用.
						INSERT INTO #iSeries
						select i2.seriescode,i2.rowid,i2.matcode,i2.matname,i2.docitem,convert(varchar(20),'') as state,convert(varchar(20),'') as Refstate
						from iserieslogitem i2 with(nolock)
						where i2.doccode=@refcode
						SELECT @SeriesRowcount=@@ROWCOUNT
					END
				ELSE
					BEGIN
						SELECT @SeriesRowcount=0
					END
				 
			END
		ELSE
		BEGIN
 
				SELECT @sql='Select @Refcode=Doccode From Openquery('+@ServerName+','+dbo.crlf()+
				''' Select Doccode From '+@DatabaseName +'.dbo.iSeriesLogHD i with(nolock) Where i.refcode='''''+@Doccode+''''''')'
 
				EXEC sp_executesql @sql,N'@Refcode varchar(50) output',@refcode=@refcode OUTPUT
				IF @@ROWCOUNT>0
					BEGIN
						SELECT @Sql='INSERT INTO #iSeries '+dbo.crlf()+
						' select i2.seriescode,i2.rowid,i2.matcode,i2.matname,i2.docitem,convert(varchar(20),'''') as state, convert(varchar(20),'''') as state'+dbo.crlf()+
						' from OpenQuery('+@ServerName +','+dbo.crlf()+
						''' Select Seriescode,RowID,Matcode,MatName,DocItem From '+@DatabaseName +'.dbo.iserieslogitem i2 with(nolock)'+dbo.crlf()+
						' where i2.doccode='''''+@refcode+''''''') i2'
						print @sql
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
					END
				ELSE
				BEGIN
 
						---取出这些串号在URP中的串号状态
						update a
							set a.state=b.state
						from #iseries a inner join URP11.JTURP.dbo.iSeries b with(nolock) on a.seriescode=b.seriescode
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
		
		/***********************************************************业务处理****************************************************/
		select @TRANCOUNT=@@TRANCOUNT
		if @trancount=0 begin tran
		begin try
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
					if @@ROWCOUNT=0
						BEGIN
							raiserror('找不到送货单或送货单不在可收货状态,请核实此单是否已发货,若有疑问请联系当地总仓.',16,1)
							return
						END
					IF isnull(@SeriesRowcount,0)>0
						BEGIN
							--再更新串号状态
							UPDATE A
								SET a.[state]='应收'
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
					' and isnull(getok,''''未收货'''')=''''未收货'''''')'+dbo.crlf()+
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
					if @TRANCOUNT=0 and xact_state() =1 commit
			END TRY
			begin catch
 
				if  xact_state() =-1 rollback
				select @tips=dbo.getLastError('收货发生异常.')
				raiserror(@tips,16,1)
				return
			end catch
	END
	
	 