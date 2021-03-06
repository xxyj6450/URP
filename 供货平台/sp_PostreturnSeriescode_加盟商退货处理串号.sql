/*
过程名称:sp_PostReturnSeirescode
参数:见声名
返回值:
功能说明:退货时将供货平台串号删除
编写:三断笛
时间:2012-11-23
备注:本功能只在供货平台中执行.用于将供货平台发货的串号移除出串号表,并将已售串号表中存在的串号移回串号表.
示例:
begin tran
exec sp_PostReturnSeirescode  4951,'JDR2012121700020','SYSTEM','D113.01','2.1.312.07.36'

rollback
*/
 
ALTER PROC [sp_PostReturnSeirescode]
	@FormID INT,
	@Doccode VARCHAR(50),
	@usercode VARCHAR(50),
	@stcode VARCHAR(50),
	@instcode VARCHAR(50),
	@Optionid VARCHAR(50)='',
	@TerminalID VARCHAR(50)=''
AS
	BEGIN
		SET NOCOUNT ON;
		SET XACT_ABORT ON;
		DECLARE @refcode VARCHAR(50),@trancount INT,@tips VARCHAR(MAX)
		DECLARE @table TABLE(seriescode VARCHAR(50))
		declare    @sql nvarchar(max), @SQL_Seriescode varchar(max),@sql_Fields varchar(max)
		--取出处理串号表单号
		SELECT @refcode=doccode FROM dbo.iseriesloghd i WITH(NOLOCK) WHERE i.refCode=@Doccode
		--再取出处理串号表串号
		SELECT i.seriescode,i.matcode,i.matname,CONVERT(VARCHAR(50),'') AS fhstcode,CONVERT(VARCHAR(50),'') AS fhstname,CONVERT(VARCHAR(50),'') AS STATE,
		CONVERT(VARCHAR(50),'') AS SYSTEMID,CONVERT(VARCHAR(50),'') AS SYSTEMNAME,CONVERT(VARCHAR(50),'') AS instanceid,CONVERT(VARCHAR(50),'') AS accessname
		into #iseries
		from dbo.iserieslogitem i WITH(NOLOCK)
		WHERE i.doccode=@refcode
		--从串号表更新发货仓库及串号数据
		UPDATE a
			SET a.fhstcode=i2.fhstcode,
			a.fhstname=i2.fhstname,
			a.STATE=i2.state
		FROM #iseries a INNER JOIN URP11.JTURP.dbo.iSeries i2 WITH(NOLOCK) ON a.seriescode=i2.SeriesCode
		--补充系统及访问方式等信息
		UPDATE a
			SET a.systemid=ss.ID,
			a.systemname=ss.SystemName,
			a.instanceid=si.InstanceID,
			a.accessname=si.AccessName
		FROM #iseries a,oStorage os WITH(nolock),_sysSYSTEMS ss,_sysInstances si
		WHERE a.fhstcode=os.stCode
		AND os.SYSTEMID=ss.ID
		AND ss.InstanceID=si.InstanceID
		SELECT @trancount=@@trancount
		select @SQL_Seriescode=''
		select @SQL_Seriescode=@SQL_Seriescode+''''''+seriescode+''''''+','
		from #iseries b
		where ISNULL(b.accessname,'URP11.JTURP')<>'URP11.JTURP'
		select @SQL_Seriescode=left(@SQL_Seriescode,len(@SQL_Seriescode)-1)
		IF @trancount=0 BEGIN TRAN
		BEGIN TRY
			--删除串号表中来源不为URP销售系统的串号
			select @sql='Delete From Openquery(URP11,''Select Seriescode From JTURP.dbo.iSeries Where Seriescode in('+@SQL_Seriescode+')'')'
 
			exec(@sql)
			--当有删除数据时,才考虑移回串号.
			IF @@ROWCOUNT>0
				BEGIN
					--再将已售串号表中存在的串号插回串号表
					INSERT INTO URP11.JTURP.dbo.iSeries
					SELECT iss.* FROM URP11.JTURP.dbo.iSeriesSales iss WITH(NOLOCK),#iSeries b
					WHERE iss.SeriesCode=b.seriescode
					and ISNULL(b.accessname,'URP11.JTURP')<>'URP11.JTURP'
					IF @@ROWCOUNT>0
						BEGIN
							--记录操作日志
							INSERT INTO iSeriesLog(Seriescode,EnterName,FormID,FormType,DocType,Doccode,stcode,instcode,Remark,TerminalID)
							SELECT seriescode,@usercode,@FormID,5,'加盟商退货',@doccode,@stcode,@instcode,'加盟商退货还原串号',@terminalid
							from #iSeries b
							where   ISNULL(b.accessname,'URP11.JTURP')<>'URP11.JTURP'
						END
				end
			IF    XACT_STATE()=1 commit
		END TRY
		BEGIN CATCH
			 IF @@trancount>9 rollback
			 SELECT @tips=dbo.getLastError( '退货移除串号发生异常.'  )
			 RAISERROR(@tips,16,1)
			 return
		END CATCH
		
	END
	