 /*
* 函数名称：[sp_OccupySeriesNumberEX]                         
* 功能描述：预占号码增强版                            
* 参数:见声名部分                              
* 编写：三断笛                              
* 时间：2010/06/11                             
* 备注:此过程支持新客户,老客户业务.支持池内号码与池外号码的占用.
*------------------------------------------
修改:三断笛
时间:2012-08-30
备注:重新架构此过程          
begin tran
exec [sp_OccupySeriesNumberEX] 'system','system','18664559147',9114,'TBS2012011800908','1.1.755.02.01',9146,'','TBD2010121600001'
select refcode,intype, * from seriespool where seriesnumber='18664559147'
rollback
*/
ALTER PROC [dbo].[sp_OccupySeriesNumberEX]
	@BusiType VARCHAR(50),			--业务类型
	@usercode VARCHAR(20),			--工号,除system之外,必须在员工资料表中存在.  
	@username VARCHAR(50),                
	@SeriesNumber VARCHAR(20),		--用户选择的号码                  
	@refformid INT=NULL,			--调用该存储过程的业务单据功能号,默认为NULL                
	@refcode VARCHAR(20)='',		--调用该存储过程的业务单据单号                  
	@sdorgid VARCHAR(30)='',		--门店编号,                         
	@optionID INT=-1,				--选项,可以用来表示选号以后创建单据的功能号,如9102,9146
	@ReservationDoccode VARCHAR(20)='',		---预约编号
	@PackageID VARCHAR(20),
	@linkdocinfo VARCHAR(200)='' OUTPUT		--链接信息
AS
	BEGIN
		DECLARE @areaid VARCHAR(20),@areaid1 VARCHAR(20),@areaname1 VARCHAR(50),@tips VARCHAR(8000),
		@newDoccode VARCHAR(20),@sdorgname VARCHAR(200),@OpenAccount BIT,@old bit,@value INT,@errMsg VARCHAR(2000)
		DECLARE @RowCount INT,@tranCount int
		SET NOCOUNT ON;
		IF isnull(@BusiType,'')=''
			BEGIN
				RAISERROR('业务类型信息缺失,无法执行本次操作,请联系系统管理员.',16,1)
				return
			END
		SELECT @OpenAccount=isnull(pg.OpenAccount,0),@old=ISNULL(pg.oldCustomerBusi,0)
		                    FROM T_PolicyGroup pg WHERE pg.PolicyGroupID=@BusiType
		--防止业务类型不存在
		IF @@ROWCOUNT=0
			BEGIN
				RAISERROR('业务类型不存在,无法执行本次操作,请联系系统管理员.',16,1)
				return
			END
		--防止开户和老客户同时被设置.
		IF ISNULL(@OpenAccount,0)=1 and ISNULL(@old,0)=1
			BEGIN
				RAISERROR('业务类型冲突,无法执行本次操作.',16,1)
				return
			END
		--判断号码
		IF (@OpenAccount=1 OR @old=1) AND  dbo.fn_checkSeriesnumber(@SeriesNumber)=0                                            
		 begin                               
		  RAISERROR('您输入的号码非法,请重新输入.',16,1)                                            
		  RETURN                                            
		 END
		--判断如果是老客户套包不给选号码                                            
		IF (@old=1 OR (@OpenAccount=0 AND @old=0))  AND EXISTS(SELECT 1 FROM SeriesPool sp WHERE sp.SeriesNumber=@SeriesNumber AND sp.Actived='未激活')
		 begin                               
		  RAISERROR('您录入的号码尚未激活,不允许办理老客户业务.',16,1)                                            
		  RETURN                                            
		 End
		Print @OpenAccount
		--若是开户业务,则尝试占用号码,并生成单据
		IF @OpenAccount=1
			BEGIN
				--若不存在可用的号码(注意readpast会跳过正在被锁定的行)则提示错误.
				IF NOT EXISTS(SELECT 1 FROM SeriesPool sp WITH(READPAST) WHERE sp.SeriesNumber=@SeriesNumber AND sp.[STATE]='待选' and sp.Actived='未激活')
					BEGIN
						RAISERROR('您输入的号码已被占用,请重新选择号码.',16,1)                                            
						return
					END                      
				--判断系统中是否有此号码
				IF EXISTS(SELECT 1 FROM SeriesPool sp WITH(READPAST) WHERE sp.SeriesNumber=@SeriesNumber)
					BEGIN
						--如果有号码,则判断此号码是否符号选号屏号码规则
						BEGIN try
							 EXEC @RowCount =sp_SelectPackageSeriesNumber_New
								@BusiType=@BusiType,
								@packageID=@PackageID,
                   				@usercode = @usercode,
                   				@sdorgid = @sdorgid,
                   				@seriesnumber = @seriesnumber,
                   				@NetType = '',
                   				@minprice = '',
                   				@maxprice = '',
                   				@condition_Code = '',
                   				@refformid =@refformid,
                   				@refcode =@refcode,
                   				@ReservationDoccode=@ReservationDoccode
							IF @ROWCOUNT=0
								BEGIN
									RAISERROR('您输入的号码资源无效,不允许开户,请重新选择号码.',16,1)
									return
								END
						END TRY
						BEGIN catch
							SELECT @tips='开户异常.'+dbo.crlf()+ISNULL(ERROR_MESSAGE(),'')
							RAISERROR(@tips,16,1)
							return
						END CATCH
					END
				ELSE
					/********************************如果号码不存在*******************************************/
					BEGIN
						--如果不允许开池外号码,则报错
							IF dbo.fn_getSDOrgConfig(@sdorgid,'AllowOuterNumber')=0  
							BEGIN
								RAISERROR('权限不足,不允许开池外号码,请重新选择号码.',16,1)
								return
							END 
					END
			--如果是开户,则预占号码,并且生成单据
					BEGIN TRY
					EXEC sp_OccupySeriesNumber
						@BusiType=@BusiType,
						@PackageID=@PackageID,
						@usercode = @usercode,
						@SeriesNumber = @SeriesNumber,
						@refformid = @refformid,
						@refcode = @refcode,
						@sdorgid = @sdorgid,
						@optionID = @optionID,
						@ReservationDoccode = @ReservationDoccode,
						@linkdocinfo = @linkdocinfo OUTPUT
						return
					END TRY
					BEGIN CATCH
						SELECT @errMsg='预占号码资源失败.'+dbo.crlf()+isnull(ERROR_MESSAGE(),'')
						RAISERROR(@errMsg,16,1)
					END catch
				END
				--若不开户,则不预约号码,只生成单据
				else IF isnull(@OpenAccount,0)=0       --仅对指定功能号有效              
					 Begin
					 	Print @optionID
						IF @refformid = @optionID   AND @refcode <> '' SELECT @newDoccode = @refcode              
						--根据@optionID创建新单号              
						IF @optionID IN(9237,9146)  
						Begin
							Print '执行了这里'
						  EXEC sp_createseriesdoc @BusiType,@PackageID, @optionid, @seriesnumber, @sdorgid, @sdorgname, @usercode, @username, 
							   @refformid, @refcode, '套包销售', @ReservationDoccode, @newdoccode OUTPUT
						END
						ELSE IF @optionID IN(9102) 
							Begin
								Print '执行了这里'
								EXEC sp_createseriesdoc  @BusiType,@PackageID,@optionid, @seriesnumber, @sdorgid, @sdorgname, @usercode, @username, 
							   @refformid, @refcode, '客户新入网', @ReservationDoccode, @newdoccode OUTPUT     
							END   
					 END
				--重复选号则直接打开单据              
				IF @optionID IN (9102, 9146)
				BEGIN
					SELECT @linkdocinfo = CONVERT(VARCHAR(10), @optionID) + ';5;' + @newDoccode 
				END
				ELSE IF @optionID IN(9237,9244)
				BEGIN
					SELECT @linkdocinfo = CONVERT(VARCHAR(10), @optionID) + ';16;' + @newDoccode 
				END
				RETURN
END

 
