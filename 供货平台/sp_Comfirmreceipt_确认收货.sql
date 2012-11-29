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
exec sp_ComfirmReceipt 'JDC2012112800026',4950,'SYSTEM','102','2.1.769.09.29','','1243010B-4C4E-40FE-AAC5-B3AD367AA74D','1',''

select instanceid,stcode,instcode from spickorderhd where doccode='JDC2012112800026'
print dbo.instanceid()
rollback
1.868429010299206[联想A60+黑色]
2.862726019083960[中兴V889D-WCDMA黑色]
3.867439011788645[天语W619渠道版黄色]
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
		@AccessName varchar(200),@SYSTEMNAME varchar(50)
		
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
		
		/************************************************初始化数据******************************************************************/
		
		/***********************************************************业务处理****************************************************/
		select @TRANCOUNT=@@TRANCOUNT
		if @trancount=0 begin tran
		begin try
			--回填送货单
			if @InstanceID=dbo.InstanceID()
				BEGIN
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
				END
			else
				BEGIN
						select @sql='Update '+@AccessName+'.dbo.spickorderhd'+dbo.crlf()+
						'set getok=''已收货'','+dbo.crlf()+
						'	getday=convert(varchar(30),getdate(),120),'+dbo.crlf()+
						'	getname = '''+@Usercode+''''+dbo.crlf()+
						'where DocCode='''+@Doccode+''''+dbo.crlf()+
						'and getok=''未收货'''
						PRINT @sql
						exec(@sql)
						if @@ROWCOUNT=0
							BEGIN
								raiserror('找不到送货单或送货单不在可收货状态,请核实此单是否已发货,若有疑问请联系当地总仓.',16,1)
								return
							END
				END
			--PRINT '执行到这里'
			--如果发货平台(串号来源)就是URP销售系统(目的系统),就不再对串号进行处理了
			if @AccessName='URP11.JTURP' return
			--取出串号表字段
			select @sql_Fields=''
			select @sql_Fields=@sql_Fields+s.name+','
			from syscolumns s
			where s.id=object_id('iSeries')
			select @sql_Fields=left(@sql_Fields,len(@sql_Fields)-1)
			
			--取出串号单
			select @refcode=doccode from iseriesloghd i with(nolock) where i.refCode=@Doccode
			--取出串号缓存至临时表,以供后续使用.
			select i2.seriescode,i2.rowid,i2.matcode,i2.matname,i2.docitem,convert(varchar(20),'') as state
			into #iSeries 
			from iserieslogitem i2 with(nolock)
			where i2.doccode=@refcode
			--取出这些串号在URP中的串号状态
			update a
				set a.state=b.state
			from #iseries a inner join URP11.JTURP.dbo.iSeries b with(nolock) on a.seriescode=b.seriescode
			
			--判断串号在URP系统中是否存在,若存在非已售的串号,则抛出异常.
			select @tips='以下串号已在URP系统中已存在,无法继续操作.'+dbo.crlf()
			select @tips=@tips+convert(varchar(5),b.docitem)+'.'+b.seriescode+'['+b.matname+']'+dbo.crlf()
			from   #iSeries b
			where isnull(b.state,'已售') not in('已售','')
			if @@ROWCOUNT>0
				BEGIN
					raiserror(@tips,16,1)
					return
				END
		
			--将URP中已售的串号移走
			select @SQL_Seriescode=''
			select @SQL_Seriescode=@SQL_Seriescode+''''+seriescode+''''+','
			from #iseries 
			where state='已售'
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
								return
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
							 + '			where b.state='''''
					--print @sql
					EXEC sp_executesql @sql,N'@sql_Fields varchar(max)',@sql_Fields=@sql_Fields
					
					--记录操作日志
					if @@ROWCOUNT>0
						BEGIN
							SET @sql = 'insert into openquery(URP11,''Select Seriescode,Formid,Formtype,doccode,doctype,stcode,instcode,remark  From JTURP.dbo.iSeriesLog'') ' + char(10)
									 + '				select  seriescode,4950 as formid,5 as formtype,'''+@doccode+''' as doccode,'+dbo.crlf()+
									 '''加盟商送货单'' as doctype,'''+@stcode+''' as instcode,'''+@fhstcode+''' as stcode,''加盟商收货转出已售串号'' as remark '+dbo.crlf()+
									 ' From #iSeries where state='''''
									-- print @sql
									exec sp_executesql @sql/*,N'@Formid int,@SQL_Seriescode varchar(max),@doccode varchar(30),@stcode varchar(50),@fhstcode varchar(50)',
									@formid=@formid,@SQL_Seriescode=@SQL_Seriescode,@Doccode=@Doccode,@stcode=@stcode,@fhstcode=@fhstcode,@remark=@remark*/
						END		
					--操作完毕回填事务
					if @TRANCOUNT=0 commit
			END TRY
			begin catch
				if @TRANCOUNT=0 and xact_state()!=-1 rollback
				select @tips='收货发生异常.'+dbo.crlf()+isnull(error_message(),'')+dbo.crlf()+'异常发生于'+isnull(error_procedure(),'')+'第'+convert(varchar(10),isnull(error_line(),0))+'行'
				raiserror(@tips,16,1)
				return
			end catch
	END
	
	 