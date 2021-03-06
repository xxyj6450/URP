/*                              
* 函数名称：[sp_OccupySeriesNumber]                         
* 功能描述：查询手机号号码池                              
* 参数:见声名部分                              
* 编写：三断笛                              
* 时间：2010/06/11                             
* 备注：                
* 而且每次都不返回不必要的字段,也不会关联其他表进行查询,本过程也不支持前缀%的模糊查询,尽量提高查询效率.                    
* 示例： begin tran            
            exec sp_CreateSalesDoc   9146,'PS20120115000206','system','system'
exec sp_OccupySeriesNumber 'system','13418108920'   exec sp_OccupySeriesNumber 'SYSTEM','18666859852',0,'','1'              
exec sp_OccupySeriesNumber 'A10000001','18676936611',9114,'TBS2010061800001','1.3.020.01.01',-1              
exec sp_OccupySeriesNumber 'system','18676057388','','','1',-1              
exec sp_OccupySeriesNumber 'system','18665156641',9114,'TBS2010090500096','1.4.769.09.05',9146  
begin tran            
declare @link varchar(500)
exec sp_OccupySeriesNumber '01.01.01.01.01','', '0200102','18688449933','9237','','2.1.020.01.02',9237,'',@link output
print @link
 rollback            
 select * from _sysuser where usercode='0200102'
* --------------------------------------------------------------------                              
* 修改：增加限制选号功能 限制某些类型的门店只允许选指定类型的号码而不允许选择普通的号码            
* 时间：20100826            
* 备注：        
 
*                                
*/                              
ALTER PROC [dbo].[sp_OccupySeriesNumber]
	@BusiType VARCHAR(50),
	@PackageID VARCHAR(50)='',
	@usercode VARCHAR(20),    --工号,除system之外,必须在员工资料表中存在.                
	@SeriesNumber VARCHAR(20),   --用户选择的号码                
	@refformid INT = NULL,    --调用该存储过程的业务单据功能号,默认为NULL              
	@refcode VARCHAR(20) = '',   --调用该存储过程的业务单据单号                
	@sdorgid VARCHAR(30) = '',   --门店编号,                    
	@optionID INT = -1,     --选项,可以用来表示选号以后创建单据的功能号,如9102,9146            
	@ReservationDoccode VARCHAR(20) = '',---预约编号         
	@linkdocinfo VARCHAR(200) = '' OUTPUT  --链接信息
AS                
BEGIN
	/*************************************************************公共变量定义***************************************/                    
	DECLARE @tips               VARCHAR(MAX)     
	DECLARE @OldDocCode         VARCHAR(20)						---原业务单                       
	DECLARE @newDoccode         VARCHAR(20)						--新业务单                      
	DECLARE @DocStatus          INT,							--单据状态
	        @DocStatus1         INT,							
	        @areaid             VARCHAR(20)
	DECLARE @sdgroup            VARCHAR(20),
	        @sdgroupname        VARCHAR(50)
	
	DECLARE @sdorgname          VARCHAR(50),
	        @dpttype            VARCHAR(40),
	        @limitSeriesNumber  BIT,
	        @rowCount           INT,
	        @tranCount INT,
	        @AreaPath VARCHAR(500),@Error INT,
	        @sdorgPath VARCHAR(500)
	--如果存储过程中包含的一些语句并不返回许多实际数据，则该设置由于大量减少了网络流量，因此可显著提高性能。 摘自MSDN。              
	SET NOCOUNT ON
	/***************************************************************单据检查*******************************************/ 

	--根据部门编码和工号获取员工其他信息，同时也是对员工信息的验证             
	SELECT @sdgroup = usercode,@sdgroupname = username
	FROM _sysuser with(nolock)
	WHERE  usercode = @usercode
	IF @@ROWCOUNT=0
		BEGIN
			RAISERROR('用户信息不存在,不允许执行本操作.',16,1)
			return
		END
	SELECT @sdorgname = sdorgname,@areaid = areaid,@dpttype = dptType
	FROM   osdorg with(nolock)
	WHERE  sdorgid = @sdorgid 
	IF @@ROWCOUNT=0
		BEGIN
			RAISERROR('部门信息不存在,不允许执行本操作.',16,1)
			return
		END
	SELECT @AreaPath=PATH FROM gArea ga  with(nolock) WHERE ga.areaid=@areaid
	IF @@ROWCOUNT=0
		BEGIN
			RAISERROR('区域信息不存在,不允许执行本操作',16,1)
			return
		END
	--判断是否有限制选号  
	IF dbo.fn_getSDOrgConfig(@sdorgid,'ShareSeriesPool') = 0
	    SELECT @limitSeriesNumber = 1
	ELSE
	    SELECT @limitSeriesNumber = 0 
 
	--选择的号码不允许为空              
	IF ISNULL(@SeriesNumber,'') = ''
	BEGIN
	    RAISERROR ('您尚未选择号码，请先选号后再执行此操作！',16,1) 
	    RETURN
	END
	IF @refformid not IN (-1, 0, 9114, 9102, 9146, 9224,9237) --仅对指定功能号有效
		BEGIN
			RAISERROR('该功能禁止预占号码,请联系系统管理员.',16,1)
			return
		END

	/*******************************************************锁号码池********************************************************/              
	DECLARE @now          DATETIME --记录锁定时间              
	DECLARE @releaseDate  DATETIME,
	        @nn           AS INT --记录号码释放时间
	                   --从属性配置中取号码资源释放时间              
	
	SELECT @nn = propertyvalue
	FROM   _sysNumberAllocationCfgValues snacv
	WHERE  snacv.PropertyName = 'ReleaseDate'
	IF @nn IS NULL     SET @nn = 30
	
	SELECT @now = GETDATE(),@releaseDate = DATEADD(n,@nn,GETDATE())
	BEGIN TRY
		--修改事务隔离级别,锁住这条记录                
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED
		SELECT @tranCount=@@TRANCOUNT
		IF @tranCount=0	BEGIN TRAN
		--      select LockedUsercode,OccupyTime,PrivateSdorgid,valid,* from  seriespool  where seriesnumber='18665199253'        
		UPDATE SeriesPool
		SET    sdorgid = @sdorgid,
		       LockedUsercode = @usercode,
		       OccupyTime = @now,
		       STATE = '已选',
		       SeriesPool.ReleaseDate = @releaseDate 
		FROM   SeriesPool a WITH(READPAST) --跳过被锁定的行
 
		WHERE  SeriesNumber = @SeriesNumber
		       AND ([STATE] = '待选' AND actived = '未激活')
		       AND @AreaPath LIKE '%/'+a.AreaID+'/%'
		       AND a.valid = 1
		       AND ((@limitSeriesNumber = 1
		                AND (ISNULL(a.PrivateSdorgid,'') <> '')
		            )
		               OR (@limitSeriesNumber = 0 OR isnull(a.dpttype,'所有') = '所有')
		               )
		SELECT @rowCount = @@ROWCOUNT,@Error=@@error 
		--判断是否锁定成功,当上述语句影响的行数为1时,而且要求上述操作未发生错误,则认为锁定成功,否则认为锁定失败              
	IF (@ROWCOUNT <> 1 OR @ERROR <> 0)
		   --如果锁定的不止一条记录或未锁定记录，则回滚事务
			BEGIN
	 
				SELECT @tips = '您选择的号码资源' + isnull(@seriesnumber,'') + 
			   '无效或资源已被占用，选号操作失败，请重试.'+dbo.crlf()+'错误详情:'+ISNULL(ERROR_MESSAGE(),'')
				RAISERROR(@tips,16,1)
				IF @@tranCount>0 ROLLBACK TRAN
				RETURN
			END
	/**********************************************************后续处理*****************************************************/
		ELSE
		    --如果锁定成功则继续进行处理
		BEGIN
           --打开或新建单据              
		    
		        IF @refformid = @optionID  AND @refcode <> '' 
		        BEGIN
		        	SELECT @newDoccode = @refcode 
		        End
		   
		        --根据@optionID创建新单号              
		        EXEC sp_createseriesdoc @Busitype,@PackageID ,@optionid,@seriesnumber,@sdorgid,@sdorgname,
		             @sdgroup,@sdgroupname,@refformid,@refcode,'客户新入网',@ReservationDoccode,
		             @newdoccode OUTPUT 
		        
				if @@trancount>0 AND @TRANCOUNT=0 COMMIT TRAN
		        --将单号与号码绑定              
		        UPDATE SeriesPool
		        SET    RefCode = @newDoccode
		        WHERE  seriesnumber = @SeriesNumber
		               AND [STATE] = '已选'
		               AND LockedUsercode = @usercode
		        --记录号码操作事件
                INSERT INTO SeriesNumber_Log(SeriesNumber, EVENT, RefFormid, refCode, refFormType, DocType, 
                       UserCode, UserName, SdorgID, SdOrgName, EnterDate)
                SELECT @SeriesNumber, '选号', @refformid, @refcode, 5, '选号', @sdgroup, @sdgroupname, @sdorgid, 
                       @sdorgname, GETDATE()
                --将已绑定的号码释放
		        UPDATE SeriesPool
		        SET    sdorgid = NULL,
		               STATE = '待选',
		               LockedUsercode = NULL,
		               OccupyTime = NULL,
		               RefCode = NULL
		        WHERE  RefCode = @newDoccode
		               AND SeriesNumber <> @SeriesNumber
		        --将释放号码事件写入到号码记录表              
		        INSERT INTO SeriesNumber_Log( SeriesNumber, EVENT, RefFormid, 
		               refCode, refFormType, DocType, UserCode, UserName, 
		               SdorgID, SdOrgName, EnterDate)
		        SELECT @SeriesNumber,'选号释放',@refformid,@refcode,5,'选号释放',
		               @sdgroup,@sdgroupname,@sdorgid,@sdorgname,GETDATE()
		END
		SELECT @linkdocinfo = CONVERT(VARCHAR(10),@optionID) + ';'+CONVERT(varchar(10),CASE WHEN @OptionID IN(9237,9102) THEN 16 ELSE 5 END) +';' + @newDoccode 
		RETURN
	END TRY
	BEGIN CATCH
		IF @@tranCount>0  ROLLBACK
		SELECT @tips = '号码资源占用失败,系统异常:' + CHAR(10) + '错误原因:' +isnull( ERROR_MESSAGE(),'') + CHAR(10) + '错误发生'+isnull(error_procedure(),'')+'第' + CONVERT(VARCHAR(5),ERROR_LINE()) + '行.'
		RAISERROR(@tips,16,1)
		RETURN
	END CATCH
END