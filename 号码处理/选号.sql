/*                                  
* 函数名称：[sp_SelectPackageSeriesNumber_New]                   
* 功能描述：查询套包的手机号号码池          
* 参数:见声名部分                                  
* 编写：三断笛                                  
* 时间：2012-08-27            
* 备注： 此函数用于给业务员套包销售时选号用,只每次只随机返回符合条件150条未锁定的记录,                        
* 而且每次都不返回不必要的字段,也不会关联其他表进行查询,本过程也不支持前缀%的模糊查询,尽量提高查询效率.                 
该查询能得到号码段和特征码任意一个有定义(且必须其中有一个定义)的号码.                
* 示例：exec [sp_SelectPackageSeriesNumber] '','SYSTEM','1','','3G',$0.0000,$1000.0000,'','','','','',0,''                
exec [sp_SelectPackageSeriesNumber_New] '','','769300','2.1.757.03.01','8','3G',0,0,'AA','','','','SeriesNumber like ''___[^4][^4][^4][^4][^4][^4][^4][^4]''','',''
select * from _sysuser where sdorgname ='%惠州%'
* --------------------------------------------------------------------                                  
* 修改：
* 时间：                                  
* 备注：                                  
*                                   
*/                                 
ALTER  PROC [sp_SelectPackageSeriesNumber_New]
	@BusiType VARCHAR(50)='',					--业务类型
	@packageID VARCHAR(20)='',					--套包编号
	@usercode VARCHAR(20) ,						--用户编码                  
	@sdorgid VARCHAR(20) ,						--门店编码                   
	@seriesnumber VARCHAR(2000) = '',			--号码                                  
	@NetType VARCHAR(10) = '3G',				--网络类型                                
	@minprice MONEY = 200,						--最低零售价                                  
	@maxprice MONEY = 0,						--最高零售价                                                                                                 
	@condition_Code VARCHAR(MAX) = '',			--特征码                                                  
	@refformid INT = 0,							--
	@refcode VARCHAR(20) = '',    
	@ReservationDoccode nVARCHAR(20) = '',
	@SearchOptions nVARCHAR(500)='',			--扩展搜索选项.拼接SQL语句传入.不需要WHERE关键字 如 SeriesNumber like ''186[^4][^4][^4][^4][^4][^4][^4][^4]'''
	@OrderOptions VARCHAR(200)='',				--排序选项.拼接SQL语句传入,不需要ORDER BY关键字. 如 Totalmoney desc,price desc
	@Page INT=1,								--页数
	@TotalCount INT=0 OUTPUT,					--数据行数
	@TotalPage	INT=0 OUTPUT					--页数
 AS                        
BEGIN                
/********************************************************公共变量定义**************************************************/                
                  
 --用户信息                        
 DECLARE @sdgroup VARCHAR(20), @sdgroupName  VARCHAR(50),@agent BIT   --@agent表示是否代理网点                    
 --门店信息                        
 DECLARE @sdorgname VARCHAR(50), @areaName VARCHAR(50), @areaid  VARCHAR(30)     ,@mintype VARCHAR(50)            
 DECLARE @seriesnumber1 VARCHAR(200),@condition_Code1 VARCHAR(200),@dpttype VARCHAR(40),@limitSeriesNumber bit                
 DECLARE @SDOrgPath VARCHAR(500),@AllowOuterNumber BIT,@RowCount int,@AreaPath varchar(500)
 DECLARE  @sql nVARCHAR(MAX),@DeclareSQL nVARCHAR(MAX)
 
  /*******************************************************查询条件检查*************************************************/                
	IF isnull(@sdorgid,'')=''    
		BEGIN    
			RAISERROR('无门店信息,无法执行选号.',16,1)
		   SELECT NULL AS SeriesNumber,NULL AS NetType,NULL AS STATE,NULL AS                     
				actived,NULL AS ServiceFEE,NULL AS PhoneRate,NULL AS Price,NULL AS                     
				cardfee,NULL AS MinComboFEE,NULL AS otherFEE,NULL AS TotalMoney,NULL AS                     
				Condition_Code,NULL AS grade,NULL AS CardNumber,NULL AS                     
				CardMatCode,NULL AS CardMatName,NULL AS remark,NULL as PreAllocation,                
			NULL as ComboCode,NULL AS comboName,NULL AS rewards,NULL AS inuse,NULL AS FreeCalls,NULL as uTotalmoney            
		                    
			RETURN @@ROWCOUNT
			
		END
	if @SearchOptions='' select @SearchOptions='Preallocation=0'
		/*
   IF ISNULL(@usercode,'')=''
	BEGIN
		RAISERROR('无用户信息,无法执行选号.',16,1)
		return
	END*/
	--如果是套包销售单,则必须保存单据后才能执行该操作                
	IF @refformid IN (9114)   AND @refcode IN ('', '单号')
	BEGIN
	    RAISERROR('单据未保存,不允许执行选号.', 16, 1) 
	    RETURN @@ROWCOUNT
	END             
	               
	--用户,门店及地区信息   select * from osdorggroup                     
	/*SELECT @sdgroup=a.SDGroup,@sdgroupName=a.sdgroupname                
	FROM oSDGroup a WITH(NOLOCK) WHERE a.SDGroup=@usercode                
    IF @@ROWCOUNT=0
		BEGIN
			RAISERROR('用户信息不存在,禁止操作.',16,1)
			return
		END*/
	 --取用户信息及门店信息                     
	 SELECT  @areaid =  ISNULL(areaid,'') ,  @dpttype=isnull(o.dptType,''), @SDOrgPath=path             
			  FROM   osdorg o WITH(NOLOCK)
	 WHERE  o.sdorgid=@sdorgid
	 IF @@ROWCOUNT=0
		BEGIN
			RAISERROR('门店信息不存在,禁止操作.',16,1)
			return
		END
	IF ISNULL(@SDOrgPath,'')=''
		BEGIN
			RAISERROR('门店信息异常,无法执行选号,请联系系统管理员.',16,1)
			return
		END
	select @areapath =path from garea where areaid=@areaid
	IF @@ROWCOUNT=0
		BEGIN
			RAISERROR('区域信息不存在,无法执行选号.',16,1)
			return
		END 
  --判断门店是否限制选号                 
	if dbo.fn_getSDOrgConfig(@sdorgid,'ShareSeriesPool')=0               
	  SELECT @limitSeriesNumber=1                
	ELSE                
	  SELECT @limitSeriesNumber=0              
	--处理号码参数
	IF left(@seriesnumber,3) NOT IN('130','131','132','186','156','145','185','155')
		BEGIN
			SELECT @seriesnumber='___%'+@seriesnumber+'%'
		END
 /**************************************************************取配置信息**************************************************/                
                 
  --从配置表中取配置信息                
 DECLARE @n INT                
 SELECT @n=propertyvalue FROM _sysNumberAllocationCfgValues snacv with(NOLOCK) WHERE snacv.PropertyName='选号屏号码数量'                
 IF ISNULL(@n,0)<=1 SET @n=150                
                 
  /************************************************************初始化查询结果集**********************************************/                
   --套包选号
 /* IF ISNULL(@packageID,'')<>''
	BEGIN
		   SELECT @seriesnumber1=isnull(ph.begincard,''),@condition_Code1=isnull(ph.endcard,'')                
			FROM policy_h ph WHERE ph.DocCode=@packageID             
		--平台在执行操作前会设置隔离级别为Uncommitted级别,需要手动调整为Committed级别才能使用Readpast锁                        
		 SET TRANSACTION ISOLATION LEVEL READ COMMITTED                     
		 --用CTE先取出符合状态,门店,和激活条件的数据,在此基础上再对存储过程的参数进行匹配查询.这样的分批查询比合并在一起查询效率高许多.                        
		 ;WITH cte_SeriesNumber(SeriesNumber,sdorgid,areaid,NetType,STATE,actived,                    
		  ServiceFEE,PhoneRate,Price,cardfee,MinComboFEE,otherFEE,TotalMoney,                     
		  Condition_Code,grade,CardNumber,CardMatCode,CardMatName,remark,                
		  privatesdorgid,preAllocation,ComboCode,ComboName,rewards,inuse,agent,valid,dpttype,ReservedDoccode,FreeCalls) AS (                
		  --先根据套包单中的号码段和特征码取号码
		   SELECT a.SeriesNumber,a.sdorgid,a.areaid,a.NetType,a.State,a.actived,                    
				  ServiceFEE,PhoneRate,Price,cardfee,MinComboFEE,otherFEE,TotalMoney,                    
				  Condition_Code,grade,a.CardNumber,a.CardMatCode,a.CardMatName,a.remark,privatesdorgid,                
				  preAllocation,ComboCode,ComboName,Rewards,inuse,agent,valid,dpttype,ReservedDoccode,Freecalls          
		   FROM   SeriesPool a WITH(READPAST)																	--加上READPAST锁,不读取所有被锁定的行,防止脏读,减少阻塞                    
		   WHERE  a.state = '待选'
			   AND a.valid = 1																					--已开放的号码
			   AND (@seriesnumber1 =''   or EXISTS(SELECT 1 FROM   dbo.split(@seriesnumber1,',') WHERE  a.SeriesNumber LIKE list))                
			--匹配号码为空,但特征码为空的情况                
			and (@condition_Code1='' or EXISTS(SELECT 1 FROM   dbo.split(@condition_Code1,',') WHERE  a.Condition_Code = list))
			AND (@seriesnumber = '' OR a.seriesnumber LIKE @seriesnumber + '%')
			AND (@condition_Code = '' OR a.condition_code = @condition_Code )
			AND ((@minprice = '' OR @minprice = 0) OR a.TotalMoney >= @minprice)
			AND ((@maxprice = '' OR @maxprice = 0) OR a.TotalMoney <= @maxprice) 
			AND (@NetType = '' OR a.NetType = @NetType)
			--匹配区域
			AND (ISNULL(a.areaid, '') = ''	OR @areapath LIKE '%/' + a.areaid + '/%')
			--是否允许共享号码.若不允许,则只能选择预约到本店的号码,若允许,则可以没有预约
			 AND ((@limitSeriesNumber = 1 AND (ISNULL(a.PrivateSdorgid, '') <> '')) OR (@limitSeriesNumber = 0 OR ISNULL(a.dpttype, '所有') = '所有'))
			 --预约门店,可以按层级预约
			 AND (ISNULL(a.PrivateSdorgid, '') = ''
					OR (ISNULL(a.PrivateSdorgid, '') <> ''
						AND EXISTS(SELECT 1
								   FROM   SPLIT(a.privatesdorgid, ',') a 
						           WHERE @SDorgPath LIKE '%/'+a.list+'/%'
							)
					   )
			 )
			 --门店类型匹配
			   AND (a.dpttype = ''
					OR ISNULL(a.PrivateSdorgid, '') != ''					--若号码已有预约门店,则不判断门店类型.
					OR ISNULL(a.dpttype, '所有') = '所有'					--预约门店可以为所有
					OR (ISNULL(a.dpttype, '所有') <> '所有'
						AND EXISTS(SELECT 1
								   FROM   commondb.dbo.SPLIT(ISNULL(a.dpttype,''), ',')
								   WHERE  @dpttype = list
							)
					   ) --OR @usercode='system'
			   )
				--预约编号匹配
			   AND ((ISNULL(a.ReservedDoccode, '') = ''
					 OR (ISNULL(a.ReservedDoccode, '') <> ''
						 AND a.ReservedDoccode = @ReservationDoccode
						)
					)
			   )
		  )
		  		 --随机返回150个符合条件的号码                        
		SELECT TOP(@n)
			SeriesNumber, a.NetType, a.State, a.actived, ServiceFEE, PhoneRate, Price, cardfee, MinComboFEE, otherFEE, TotalMoney, 
			   Condition_Code, grade, a.CardNumber, a.CardMatCode, a.CardMatName, a.remark, privatesdorgid, ISNULL(preAllocation, 0) AS 
			   preAllocation, ComboCode, ComboName, Rewards, ISNULL(inuse, 0)  AS inuse, FreeCalls
		FROM   cte_SeriesNumber a 
		ORDER BY preallocation DESC, NEWID()
		SELECT @RowCount=@@ROWCOUNT
		  */
		   
		SET @DeclareSQL= '@packageID VARCHAR(20), @usercode VARCHAR(20),@sdorgid  VARCHAR(20),@seriesnumber VARCHAR(2000), ' + char(10)
         + '@NetType VARCHAR(10), @minprice MONEY,@maxprice  MONEY,@condition_Code VARCHAR(MAX), ' + char(10)
         + '@ReservationDoccode VARCHAR(20), @areaid VARCHAR(30), @seriesnumber1     VARCHAR(200), ' + char(10)
         + '@condition_Code1 VARCHAR(200), @dpttype VARCHAR(40), @limitSeriesNumber BIT,  ' + char(10)
         + '@SDOrgPath VARCHAR(500), @AllowOuterNumber BIT, @AreaPath VARCHAR(500)'
         
		SET @sql = ';WITH cte_SeriesNumber(SeriesNumber,sdorgid,areaid,NetType,STATE,actived,                     ' + char(10)
         + '		  ServiceFEE,PhoneRate,Price,cardfee,MinComboFEE,otherFEE,TotalMoney, comboFee,                     ' + char(10)
         + '		  Condition_Code,grade,CardNumber,CardMatCode,CardMatName,remark,                 ' + char(10)
         + '		  privatesdorgid,preAllocation,ComboCode,ComboName,rewards,inuse,agent,valid,dpttype,ReservedDoccode,FreeCalls,uTotalmoney) AS (                 ' + char(10)
         + '		  --先根据套包单中的号码段和特征码取号码 ' + char(10)
         + '		   SELECT a.SeriesNumber,a.sdorgid,a.areaid,a.NetType,a.State,a.actived,                     ' + char(10)
         + '				  ServiceFEE,PhoneRate,Price,cardfee,MinComboFEE,otherFEE,TotalMoney,comboFee,                    ' + char(10)
         + '				  Condition_Code,grade,a.CardNumber,a.CardMatCode,a.CardMatName,a.remark,privatesdorgid,                 ' + char(10)
         + '				  preAllocation,ComboCode,ComboName,Rewards,inuse,agent,valid,dpttype,ReservedDoccode,Freecalls,isnull(totalmoney,0)-isnull(Cardfee,0) as uTotalmoney' + char(10)
         + '		   FROM   SeriesPool a WITH(READPAST)																	--加上READPAST锁,不读取所有被锁定的行,防止脏读,减少阻塞                     ' + char(10)
         + '		   WHERE  a.state = ''待选'' ' + char(10)
         + '			   AND a.valid = 1																					--已开放的号码 ' + char(10)
         + '			AND (@seriesnumber = '''' OR a.seriesnumber LIKE @seriesnumber + ''%'') ' + char(10)
         + '			AND (@condition_Code = '''' OR a.condition_code = @condition_Code ) ' + char(10)
         + '			AND ((@minprice = '''' OR @minprice = 0) OR a.TotalMoney >= @minprice) ' + char(10)
         + '			AND ((@maxprice = '''' OR @maxprice = 0) OR a.TotalMoney <= @maxprice)  ' + char(10)
         + '			AND (@NetType = '''' OR a.NetType = @NetType) ' + char(10)
         + '			--匹配区域 ' + char(10)
         + '			AND (ISNULL(a.areaid, '''') = ''''	OR @areapath LIKE ''%/'' + a.areaid + ''/%'') ' + char(10)
         + '			--是否允许共享号码.若不允许,则只能选择预约到本店的号码,若允许,则可以没有预约 ' + char(10)
         + '			 AND (@limitSeriesNumber = 0 or (@limitSeriesNumber = 1 AND ISNULL(a.PrivateSdorgid, '''') <> '''')) ' + char(10)
         + '			 --预约门店,可以按层级预约 ' + char(10)
         + '			 AND (ISNULL(a.PrivateSdorgid, '''') = '''' ' + char(10)
         + '					OR (ISNULL(a.PrivateSdorgid, '''') <> '''' ' + char(10)
         + '						AND EXISTS(SELECT 1 ' + char(10)
         + '								   FROM   Commondb.dbo.SPLIT(a.privatesdorgid, '','') a  ' + char(10)
         + '						           WHERE @SDorgPath LIKE ''%/''+a.list+''/%'' ' + char(10)
         + '							) ' + char(10)
         + '					   ) ' + char(10)
         + '			 ) ' + char(10)
         + '			 --门店类型匹配 ' + char(10)
         + '			   AND (a.dpttype = '''' ' + char(10)
         + '					OR ISNULL(a.PrivateSdorgid, '''') != ''''					--若号码已有预约门店,则不判断门店类型. ' + char(10)
         + '					OR ISNULL(a.dpttype, ''所有'') = ''所有''					--预约门店可以为所有 ' + char(10)
         + '					OR (ISNULL(a.dpttype, ''所有'') <> ''所有'' ' + char(10)
         + '						AND EXISTS(SELECT 1 ' + char(10)
         + '								   FROM   commondb.dbo.SPLIT(ISNULL(a.dpttype,''''), '','') ' + char(10)
         + '								   WHERE  @dpttype = list ' + char(10)
         + '							) ' + char(10)
         + '					   ) --OR @usercode=''system'' ' + char(10)
         + '			   ) ' + char(10)
         + '				--预约编号匹配 ' + char(10)
         + '			   AND ((ISNULL(a.ReservedDoccode, '''') = '''' ' + char(10)
         + '					 OR (ISNULL(a.ReservedDoccode, '''') <> '''' ' + char(10)
         + '						 AND a.ReservedDoccode = @ReservationDoccode ' + char(10)
         + '						) ' + char(10)
         + '					) ' + char(10)
         + '			   ) ' + char(10)

	IF ISNULL(@packageID,'')<>''
		BEGIN
			SELECT @seriesnumber1=isnull(ph.begincard,''),@condition_Code1=isnull(ph.endcard,'')                
			FROM policy_h ph WHERE ph.DocCode=@packageID
			IF @@ROWCOUNT=0
				BEGIN
					RAISERROR('无效的套包政策.',16,1)
					return
				END 
			SELECT @sql=@sql
			 + '			   AND (@seriesnumber1 =''''   or EXISTS(SELECT 1 FROM   commondb.dbo.split(@seriesnumber1,'','') WHERE  a.SeriesNumber LIKE list))                 ' + char(10)
			 + '			--匹配号码为空,但特征码为空的情况                 ' + char(10)
			 + '			and (@condition_Code1='''' or EXISTS(SELECT 1 FROM   commondb.dbo.split(@condition_Code1,'','') WHERE  a.Condition_Code = list))) ' + char(10)
		END
	else
		BEGIN
			set @sql=@sql+char(10)+         + '		  )'+CHAR(10)
		END
	SELECT @sql=@sql
		 + '		SELECT TOP('+convert(varchar(5),@n)+') ' + char(10)
         + '			SeriesNumber, a.NetType, a.State, a.actived, ServiceFEE, PhoneRate, Price, cardfee, MinComboFEE, otherFEE, TotalMoney,  ' + char(10)
         + '			   Condition_Code, grade, a.CardNumber, a.CardMatCode, a.CardMatName, a.remark, privatesdorgid, ISNULL(preAllocation, 0) AS  ' + char(10)
         + '			   preAllocation, ComboCode, ComboName, Rewards, ISNULL(inuse, 0)  AS inuse, FreeCalls,uTotalmoney' + char(10)
         + '		FROM   cte_SeriesNumber a '+CHAR(10)
 
	IF @SearchOptions<>''
		BEGIN
			select @sql=@sql+'Where '+@SearchOptions+CHAR(10)
		END
	IF @OrderOptions<>''
		BEGIN
			SELECT @sql=@sql+'Order by preallocation DESC,'+@OrderOptions+', NEWID()'+CHAR(10)
		END
	ELSE
	BEGIN
			SELECT @sql=@sql+'Order by preallocation DESC, NEWID()'+CHAR(10)
	END
	EXEC sp_executesql @sql,@DeclareSQL,
		@packageID, @usercode,@sdorgid  ,@seriesnumber  ,  
         @NetType, @minprice=@minprice,@maxprice =@maxprice,@condition_Code=@condition_Code, 
         @ReservationDoccode=@ReservationDoccode,@areaid= @areaid,@seriesnumber1= @seriesnumber1, 
         @condition_Code1=@condition_Code1, @dpttype=@dpttype,@limitSeriesNumber=@limitSeriesNumber,
         @SDOrgPath=@SDOrgPath, @AllowOuterNumber =@AllowOuterNumber,  @AreaPath =@AreaPath
   SELECT @RowCount=@@ROWCOUNT
		/***********************************************************查询号码*********************************************************/                
		
  --如果没有数据,且录入的是一个合法的号码则进行下一步判断
	IF @RowCount = 0 AND dbo.isValidSeriesNumber(@seriesnumber,0)=1 AND @seriesnumber LIKE '%'+@seriesnumber1+'%'  
		BEGIN
			SELECT @AllowOuterNumber=dbo.fn_getSDOrgConfig(@sdorgid,'AllowOuterNumber')
			--如果此门店允许开池外号码,而且此号码不在号码池中,那将此号码选出
			IF @AllowOuterNumber=1 AND NOT EXISTS(SELECT 1 FROM SeriesPool sp WHERE sp.SeriesNumber=@seriesnumber)
				begin              
					 SELECT @seriesnumber AS SeriesNumber,NULL AS NetType,NULL AS STATE,NULL AS                     
							actived,NULL AS ServiceFEE,NULL AS PhoneRate,NULL AS Price,NULL AS                     
							cardfee,NULL AS MinComboFEE,NULL AS otherFEE,NULL AS TotalMoney,NULL AS                     
							Condition_Code,NULL AS grade,NULL AS CardNumber,NULL AS                     
							CardMatCode,NULL AS CardMatName,'池外号码' AS remark,NULL as PreAllocation,                
							NULL as ComboCode,NULL AS comboName ,NULL AS rewards,NULL AS  inuse,NULL AS FreeCalls
							
					-- INTO #t1
					SELECT @RowCount=@@ROWCOUNT
					IF @RowCount=0
						BEGIN
							SELECT NULL AS SeriesNumber,NULL AS NetType,NULL AS STATE,NULL AS                     
							actived,NULL AS ServiceFEE,NULL AS PhoneRate,NULL AS Price,NULL AS                     
							cardfee,NULL AS MinComboFEE,NULL AS otherFEE,NULL AS TotalMoney,NULL AS                     
							Condition_Code,NULL AS grade,NULL AS CardNumber,NULL AS                     
							CardMatCode,NULL AS CardMatName,'池外号码' AS remark,NULL as PreAllocation,                
							NULL as ComboCode,NULL AS comboName ,NULL AS rewards,NULL AS  inuse,NULL AS FreeCalls
						END
				end               
		END
	RETURN  @RowCount    
END                 


