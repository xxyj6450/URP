/*
��������:sp_ComfirmReceipt
����:ȷ���ջ�
����:������
����ֵ:
��д:���ϵ�
ʱ��:2012-11-21
��ע:�ù��̽��ڹ���ƽִ̨��
ҵ���߼�:
	�������Ѿ��ջ�,���׳��쳣
	ȷ���ջ�ʱ,������ƽ̨�����Ĵ���׼����,��д��URP.
	��URPƽ̨�Ѿ�����Ӧ�յĴ˴���,���׳��쳣,��ֹ����.
	�������ֿ�ΪURP����ƽ̨,��ת�ƴ���.������Ҫת�ƴ���.
	��URPƽ̨�Ѿ��������۵Ĵ˴���,��URP���Ѵ��ڵ����۴���ת�������۴��ű�,�ٽ��´���ת����URP���ű�.
	ת��URP���д���ʱ��¼������־;������ת����URPʱ��¼������־.
	�����ͻ����ջ�״̬.
ʾ��:

HYQ201303220000000010
 
begin tran
exec sp_ComfirmReceipt 'JDC2013013100000',4950,'SYSTEM','2.1.769.26.01','111.769','','FF2DCB8D-62C1-463C-8684-1A869E2F1117','1',''
 select * from urp11.jturp.dbo.icoupons where stcode='2.1.769.26.01'
 select * from urp11.jturp.dbo.strategylog 
 select * from urp11.jturp.dbo.coupons_d where doccode='QZS2013012300000'
 update iseries
	set state='�ͻ�'
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
	@Doccode varchar(20),						--����
	@Formid int,										--���ܺ�
	@Usercode varchar(50),						--�û���
	@stcode varchar(50)='',						--�ջ��ֿ�
	@fhstcode varchar(50)='',					--�ֻ��ֿ�
	@remark varchar(50)='',						--��ע
	@InstanceID varchar(50)='',				--v_spickorderhd_Distributed��InstanceID
	@optionID varchar(50)='',					--�ջ���1
	@TerminalID varchar(50)=''					--�ն˱���
as
	BEGIN
		set NOCOUNT on;
		set XACT_ABORT on;
		
		/***************************************************��������*********************************************************************/
		declare @refcode varchar(20),  @sql nvarchar(max),@tips varchar(max),@ret int,
		@trancount int,@SQL_Seriescode varchar(max),@sql_Fields varchar(max),
		@AccessName varchar(200),@SYSTEMNAME varchar(50),@SeriesRowcount INT,
		@DatabaseName VARCHAR(50),@ServerName VARCHAR(50),@rowcount int,@DocDataXML nvarchar(max),@ResultXML varchar(8000),@DataSourceXML nvarchar(max)
		declare @hXMLDocument int,@Definition varchar(max)
		/**************************************************�������********************************************************************/
		--��ʵ��IDΪ��,���Դ����Ͳֿ���ȡ��������ʵ��ID
		if isnull(@InstanceID,'')=''
			BEGIN
				 select @InstanceID=ss.InstanceID
									from oStorage os with(nolock) inner join _sysSYSTEMS ss with(nolock) on os.SYSTEMID=ss.ID
				 if @@ROWCOUNT=0
					BEGIN
						raiserror('δ�ҵ�����ƽ̨��Ϣ,�޷���������.',16,1)
						return
					END
			END
		--ȡ��������Ϣ
		select @AccessName=si.AccessName
						  from _sysInstances si where si.InstanceID=@InstanceID
		if @@ROWCOUNT=0 or isnull(@AccessName,'')=''
			BEGIN
				raiserror('δ�ҵ�����ƽ̨������Ϣ,�޷���������.',16,1)
				return
			END
		SELECT @ServerName=SUBSTRING(@AccessName,0,CHARINDEX('.',@AccessName))
		SELECT @DatabaseName=SUBSTRING(@AccessName,CHARINDEX('.',@AccessName)+1,50)
 
		/************************************************��ʼ������******************************************************************/
		--����������ʱ�����ڴ洢�����ջ��Ĵ��š������Ǳ��ط���������Զ�̷��������Ƚ����Ŵ洢���������ٶԴ��ű�Ĳ�����Զ�̷�����������
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
		--��������Դ��ʱ��,���ڲ���ƥ��
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
		--��������������ʱ��,���ڴ���������ִ����
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
		--���ͻ����ڱ�������ֱ�Ӵӱ���ȡ���ݡ�
		IF @InstanceID=dbo.InstanceID()
			BEGIN
				--ȡ�����ŵ�
				select @refcode=doccode from iseriesloghd i with(nolock) where i.refCode=@Doccode
				IF @@ROWCOUNT>0
					BEGIN
						--ȡ�����Ż�������ʱ��,�Թ�����ʹ��.
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
		ELSE--���ͻ������ڱ��������Զ�̷�����ȡ���ݡ�
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
 
		--�����ڴ���ʱ,ȡ��������Ϣ
		IF isnull(@SeriesRowcount,0)>0
			BEGIN
				---ȡ����Щ������URP�еĴ���״̬
				if @InstanceID=dbo.InstanceID()     
					BEGIN
 
						update a
							set a.state=b.state
						from #iseries a inner join dbo.iSeries b with(nolock) on a.seriescode=b.seriescode
						--���ɵ�������Դ
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
						---ȡ����Щ������URP�еĴ���״̬
						update a
							set a.state=b.state
						from #iseries a inner join URP11.JTURP.dbo.iSeries b with(nolock) on a.seriescode=b.seriescode
						--���ɵ�������Դ
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
				SELECT @tips='���´��Ų����ͻ�״̬,�޷��ջ�.'+dbo.crlf()
				SELECT @tips=@tips+seriescode+'Ŀǰ״̬Ϊ['+ISNULL(STATE,'')+']'+dbo.crlf()
				FROM #iSeries
				WHERE ISNULL(STATE,'')<>'�ͻ�'
				IF @@ROWCOUNT>0
					BEGIN
						RAISERROR(@tips,16,1)
						return
					END
			END
		--������Դת����XML
		if exists(select 1 from #DocData)
			BEGIN
				set @DocDataXML=(select * from #DocData for xml raw,root('root'))
				
				--��ҵ�����ݽ���
				set @Definition='Doccode varchar(20),	FormID int,DocDate datetime,SDOrgID varchar(50),dptType varchar(50),AreaID varchar(50),SDOrgPath varchar(200),stcode varchar(50),stName varchar(200),
				AreaPath varchar(200),SeriesCode varchar(50),RowID varchar(50),Matcode varchar(50),MatName varchar(200),Matgroup varchar(50),MatgroupPath varchar(200),Digit int,Price money,Totalmoney money'
				set @DataSourceXML= (select * from #DataSource ds for xml raw)
				select @DataSourceXML='<root><DataTable TableName="#XMLDataSource" Definition="' +@Definition+'">'+@DataSourceXML+'</DataTable>'
				--select @DataSourceXML='<DataTable TableName="#DocData" Definition="'+@Definition+'">'+@DocDataXML+'</DataTable>'
				
				--�ٽ���������Ҳƴ��
				select @Definition='ID int,Seriescode VARCHAR(50),	RowID VARCHAR(50),Matcode VARCHAR(50),MatName VARCHAR(50),Docitem INT,STATE VARCHAR(50)'
				select @DataSourceXML=@DataSourceXML+'<DataTable TableName="#iSeries" Definition="'+@Definition +'">'+
				Convert(nvarchar(max),(Select ID,Seriescode,RowID,Matcode,MatName,Docitem,state from #iSeries For xml raw))+'</DataTable></root>'
				
			END
		--print @DataSourceXML
		/***********************************************************ҵ����****************************************************/
		select @TRANCOUNT=@@TRANCOUNT
		if @trancount=0 begin tran
		begin try
			--ִ���Ż�ȯ����
			exec @ret=URP11.JTURP.dbo.sp_DistributedExecuteStrategy @Formid,@Doccode,4,'',@Usercode,@TerminalID,@DocDataXML ,@DataSourceXML,@ResultXML output
 
			--���������Ż�ȯ��
			if isnull(@ResultXML,'')<>''
				BEGIN
					--�˴���Ҫ��varchar(8000)ת����nvarchar(max)
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
			--�����ͻ���
			if @InstanceID=dbo.InstanceID()
				BEGIN
					--���µ���״̬
					update sPickorderHD
						set getok='���ջ�',
						getday=convert(varchar(30),getdate(),120),
						getname = @Usercode
					where DocCode=@Doccode
					and isnull(getok,'δ�ջ�')='δ�ջ�'
					and DocStatus<>0
					if @@ROWCOUNT=0
						BEGIN
							raiserror('�Ҳ����ͻ������ͻ������ڿ��ջ�״̬,���ʵ�˵��Ƿ��ѷ���,������������ϵ�����ܲ�.',16,1)
							return
						END
					IF isnull(@SeriesRowcount,0)>0
						BEGIN
							--�ٸ��´���״̬
							UPDATE A
								SET a.[state]='Ӧ��',
								a.CouponsBarcode=b.CouponsBarcode,
								a.CouponsCode=b.CouponsCode
							FROM iSeries a WITH(NOLOCK),#iseries b
							WHERE a.SeriesCode=b.seriescode
							AND a.[state]='�ͻ�'
							IF @@ROWCOUNT=0
								BEGIN
									RAISERROR('û�д����ͻ��ɹ�,������,�����Ժ�������δ�õ����,����ϵ�����ֿ�.',16,1)
									return
								END
							--�ٸ��´���״̬
							UPDATE b
								SET b.[refstate]=a.state
							FROM URP11.JTURP.dbo.iSeries a WITH(NOLOCK),#iseries b
							WHERE a.SeriesCode=b.seriescode
							
						END
				END
			else
			BEGIN
					--PRINT '���µ���״̬'
					select @sql='Update Openquery('+@ServerName+',''Select getok,getday,getname,doccode From '+dbo.crlf()+
					@DatabaseName+'.dbo.spickorderhd '+dbo.crlf()+
					' where DocCode='''''+@Doccode+''''''+dbo.crlf()+
					' And Docstatus<>0 and isnull(getok,''''δ�ջ�'''')=''''δ�ջ�'''''')'+dbo.crlf()+
					' set getok=''���ջ�'','+dbo.crlf()+
					'	getday=convert(varchar(30),getdate(),120),'+dbo.crlf()+
					'	getname = '''+@Usercode+''''+dbo.crlf()
					--PRINT @sql
					exec(@sql)
					if @@ROWCOUNT=0
						BEGIN
							--PRINT @AccessName
							raiserror('�Ҳ����ͻ������ͻ������ڿ��ջ�״̬,���ʵ�˵��Ƿ��ѷ���,������������ϵ�����ܲ�.',16,1)
							return
						END
 
					--�ٸ��´���״̬
					IF isnull(@SeriesRowcount,0)>0
						BEGIN
							--PRINT '���´���״̬'
							select @SQL_Seriescode=''
							select @SQL_Seriescode=@SQL_Seriescode+''''''+seriescode+''''''+','
							from #iseries 
							where state='�ͻ�'
							select @SQL_Seriescode=left(@SQL_Seriescode,len(@SQL_Seriescode)-1)
							select @sql='UPDATE openquery( '+@ServerName+','+ dbo.crlf()
							+'''Select State From '+@DatabaseName+'.dbo.iSeries where State=''''�ͻ�'''' And Seriescode in('+@SQL_Seriescode+')'') '
							+'	SET [state]=''Ӧ��'''+dbo.crlf()
 
							EXEC(@sql)
							IF @@ROWCOUNT=0
								BEGIN
									RAISERROR('û�д����ͻ��ɹ�,������,�����Ժ�������δ�õ����,����ϵ�����ֿ�.',16,1)
									return
								END						
						END
						
				END
				
			--�������ƽ̨(������Դ)����URP����ϵͳ(Ŀ��ϵͳ),�Ͳ��ٶԴ��Ž��д�����
			if @AccessName='URP11.JTURP' RETURN
			--��û�д���,Ҳ������ִ��
			IF ISNULL(@SeriesRowcount,0)<=0 RETURN
 
			--ȡ�����ű��ֶ�
			select @sql_Fields=''
			select @sql_Fields=@sql_Fields+s.name+','
			from syscolumns s
			where s.id=object_id('iSeries')
			select @sql_Fields=left(@sql_Fields,len(@sql_Fields)-1)
			--�жϴ�����URPϵͳ���Ƿ����,�����ڷ����۵Ĵ���,���׳��쳣.
 
			select @tips='���´�������URPϵͳ���Ѵ���,�޷���������.'+dbo.crlf()
			select @tips=@tips+convert(varchar(5),b.docitem)+'.'+b.seriescode+'['+b.matname+'],���״̬Ϊ[' +isnull(b.refstate,'')+']'+dbo.crlf()
			from   #iSeries b
			where isnull(b.refstate,'����') not in('����','�ͻ�','����','')
			if @@ROWCOUNT>0
				BEGIN
					raiserror(@tips,16,1)
					return
				END
 
			--��URP�����۵Ĵ�������
			select @SQL_Seriescode=''
			select @SQL_Seriescode=@SQL_Seriescode+''''+a.seriescode+''''+','
			from #iseries a
			where a.refstate in('����','����')
 
			if @@ROWCOUNT>0
				BEGIN
					--ȡ�������ַ���
					select @SQL_Seriescode=left(@SQL_Seriescode,len(@SQL_Seriescode)-1)
					--
					/*
					insert into openquery(URP11,'Select '+@sql_Fields +' From JTURP.dbo.iSeriesSales')
					select @sql_Fields From  openquery(URP11,'Select '+@sql_Fields+' From JTURP.iSeries where seriescode in('+@SQL_Seriescode+')')
					*/
 
					
						--�����۴����������۴��ű�
						SET @sql = 'insert into openquery(URP11,''Select '+@sql_Fields +' From JTURP.dbo.iSeriesSales'') ' + char(10)
								 + '				select '+@sql_Fields +' From  openquery(URP11,''Select '+@sql_Fields +' From JTURP.dbo.iSeries where seriescode in('+replace(@SQL_Seriescode,'''','''''')+')'')'
						--print @sql
						
						exec sp_executesql @sql,N'@sql_Fields varchar(max),@SQL_Seriescode varchar(max)',
						@sql_Fields=@sql_Fields,@SQL_Seriescode=@SQL_Seriescode
						if @@ROWCOUNT>0
							BEGIN
								--ɾ������
								/*
								delete from openquery(URP11,'select seriescode from JTURP.dbo.iSeries is2 where seriescode in('+@SQL_Seriescode+')')
								*/
 
 
								SET @sql = 'delete from openquery(URP11,''select seriescode from JTURP.dbo.iSeries is2 where seriescode in('+replace(@SQL_Seriescode,'''','''''')+')'')'
								exec sp_executesql @sql,N'@SQL_Seriescode varchar(max)',@SQL_Seriescode=@SQL_Seriescode
								--��¼������־
								SET @sql = 'insert into openquery(URP11,''Select Seriescode,Formid,Formtype,doccode,doctype,stcode,instcode,remark  From JTURP.dbo.iSeriesLog'') ' + char(10)
								 + '				select Seriescode,Formid,Formtype,doccode,doctype,stcode,instcode,remark '+ dbo.crlf()+
								 ' From  openquery(URP11,''Select seriescode,4950 as formid,5 as formtype,'''''+@doccode + ''''' as doccode,'+dbo.crlf()+
								 '''''�������ͻ���'''' as doctype,'''''+@stcode+''''' as instcode,'''''+@fhstcode+''''' as stcode,''''�������ջ�ת�����۴���'''' as remark '+dbo.crlf()+
								 ' From JTURP.dbo.iSeries where seriescode in(' +replace(@SQL_Seriescode,'''','''''')+')'')'
								 
								exec sp_executesql @sql,N'@Formid int,@doccode varchar(30),@stcode varchar(50),@fhstcode varchar(50)',
								@formid=@formid,@Doccode=@Doccode,@stcode=@stcode,@fhstcode=@fhstcode--,@remark=@remark
							END
					end
					
					--�����മ��д�봮�ű�
					/*insert into openquery(URP11,'Select '+@SQL_Seriescode+' From JTURP.dbo.iseries')
					select is2.* from iSeries is2 with(nolock) inner join #iseries b on is2.SeriesCode=b.seriescode
					where b.state is null*/
					
					SET @sql = 'insert into openquery(URP11,''Select '+@sql_Fields+' From JTURP.dbo.iseries'') ' + char(10)
							 + '			select is2.* from iSeries is2 with(nolock) inner join #iseries b on is2.SeriesCode=b.seriescode ' + char(10)
							 + '			where b.state=''�ͻ�'''
  
					EXEC ( @sql)
					select @rowcount=@@ROWCOUNT
 
					--��¼������־
					if @ROWCOUNT>0
						BEGIN
 
							SET @sql = 'insert into openquery(URP11,''Select Seriescode,Formid,Formtype,doccode,doctype,stcode,instcode,remark  From JTURP.dbo.iSeriesLog'') ' + char(10)
									 + '				select  seriescode,4950 as formid,5 as formtype,'''+@doccode+''' as doccode,'+dbo.crlf()+
									 '''�������ͻ���'' as doctype,'''+@stcode+''' as instcode,'''+@fhstcode+''' as stcode,''�������ջ�ת���´���'' as remark '+dbo.crlf()+
									 ' From #iSeries where state=''�ͻ�'''
									-- print @sql
									exec sp_executesql @sql/*,N'@Formid int,@SQL_Seriescode varchar(max),@doccode varchar(30),@stcode varchar(50),@fhstcode varchar(50)',
									@formid=@formid,@SQL_Seriescode=@SQL_Seriescode,@Doccode=@Doccode,@stcode=@stcode,@fhstcode=@fhstcode,@remark=@remark*/
						END
					ELSE
					BEGIN
 
							RAISERROR('δ�ܽ�����ת����URP����ϵͳ,����ϵϵͳ����Ա.',16,1)
							return
						END
					--������ϻ�������
					if @TRANCOUNT=0  commit
			END TRY
			begin catch
				if @trancount=0 and @@TRANCOUNT>0 rollback
				select @tips=dbo.getLastError('�ջ������쳣.')
				raiserror(@tips,16,1)
				return
			end catch
	END
	
	 