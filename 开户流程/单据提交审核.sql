/*                                                                                                              
* 函数名称：sp_RequestCheckDoc                                                                                            
* 功能描述：新入网请求审核                                                                                            
* 参数:见声名部分                                                                                                              
* 编写：三断笛                                                                                                              
* 时间：2010/06/22
*执行逻辑:
1.开户业务
	1.1 取出单据头信息
	1.2 删除不需要的单据明细
	1.3 将单据明细信息写入临时表缓存,以备用.没有单据明细表的话,根据规则创建之
	1.4 对于9237开户,先执行单据保存,以计算一些数据,然后再重新读取单据头信息
	1.5 单据基本状态信息判断
	1.6 SIM卡处理
	1.7 客户资料处理
	1.8 库存处理
	1.9 价格处理
	1.10 政策规则处理
	1.11 延保产品处理
	1.12 优惠券处理
	1.13 检查结束,对单据状态,SIM卡等进行善后
	select * from oSDOrgCredit
* 备注:
select * from icoupons where couponsbarcode='HYQ201303250000000025'
* 示例：      begin tran exec sp_RequestCheckDoc  9146,'PS20121205001141','system','system','18665707441','','管理员'  rollback                              
begin tran exec sp_RequestCheckDoc  9237,'RS20130325000101','system','system','18689455343','','管理员'  rollback      
update unicom_orders
	set checkstate=NULL
where doccode='PS20120920000421'           
select mintype from v_UnicomOrders     
rollback
select packageid, seriescode,iccid, seriesnumber,* from unicom_orders where doccode='PS20121001003561'
select checkstate, sdorgname, seriesnumber,iccid,* from unicom_orders where seriesnumber='18620666252'     
select * from isiminfo where iccid='89860112875004932233'      
                                                
* --------------------------------------------------------------------                                                                                                              
* 修改：                                                                                                              
* 时间：                                                                                                              
* 备注：                                                                                                              
*  
*/                                                                                            
ALTER proc [sp_RequestCheckDoc]   
	@formid INT,                                                                                              
	@doccode VARCHAR(20),                                                                                            
	@audits VARCHAR(2000),                                                                                            
	@userCode VARCHAR(20)='',                        
	@seriesnumber VARCHAR(20)='',                         
	@remark VARCHAR(200)='',                                                                                            
	@userName VARCHAR(20)='',
	@TerminalID varchar(50)=''                       
AS                                                                                              
BEGIN             
 ---不要删除下面这一行                                                                                        
 SET NOCOUNT ON;      
 SET XACT_ABORT ON      
 /****************************************************公共变量定义*********************************************************/                                                                                            
 DECLARE @doctype VARCHAR(50) ,        
    @sdorgid VARCHAR(20) ,        
    @sdorgName VARCHAR(120) , 
    @ComboFEEType varchar(50),							--资费类型  
    @formtype INT ,        
    @matname VARCHAR(100) ,        
    @checkState VARCHAR(50) ,        
    @dptType VARCHAR(50) ,        
    @PhoneRate MONEY ,        
    @creditleft MONEY ,        
    @UserDigit4 MONEY ,        
    @ServiceFEE MONEY ,        
    @Price MONEY ,        
    @OtherFEE MONEY                         
 DECLARE @matcode VARCHAR(30) ,        
    @docitem INT ,        
    @tips VARCHAR(2000) ,        
    @forceCheckdoc BIT ,        
    @packageID VARCHAR(20),      
    @PackageType varchar(50),
    @LinkInfo varchar(100)      
 DECLARE @old BIT ,        
    @customerCode VARCHAR(20) ,        
    @summoney MONEY ,        
    @Companyid2 VARCHAR(200) ,        
    @preallocation BIT , 
    @inType varchar(20),
    @done MONEY ,        
    @cltCode2 VARCHAR(50) ,        
    @SeriesCode VARCHAR(30) ,        
    @Packagecode VARCHAR(20) ,        
    @tranCount INT ,        
    @PackageDoccode VARCHAR(20) ,        
    @sdgroup VARCHAR(30) ,        
    @PackageGroupName VARCHAR(500) ,        
    @stcode VARCHAR(50) ,        
    @AreaID VARCHAR(50) ,        
    @ICCID VARCHAR(30) ,        
    @docstatus INT ,        
    @AreaPath VARCHAR(500) ,        
    @cardmoney MONEY ,  
    @ReservedCardmoney money,								--预约卡费
    @CardSpecial BIT ,        
    @ReservedDoccode VARCHAR(20) ,        
    @docdate DATETIME ,        
    @cltCode VARCHAR(50) ,        
    @cltname VARCHAR(50) ,        
    @Vouchercode VARCHAR(200) ,        
    @VourcherAddress VARCHAR(500) ,        
    @ErrorText VARCHAR(4000) ,        
    @HasError BIT ,        
    @node INT ,        
    @value VARCHAR(20) ,        
    @minprice MONEY ,        
    @comboName VARCHAR(200) ,        
    @ComboCode VARCHAR(50) ,        
    @areaID1 VARCHAR(500) ,        
    @areaname1 VARCHAR(500) ,             
    @mustReadCard BIT ,        
    @SIMSeriesCode VARCHAR(50) ,        
    @CardMatcode VARCHAR(50),        
    @SDOrgPath VARCHAR(500), 
    @VIPID varchar(50),    
    @CardMatName varchar(200),        
    @CardPrice money,        
    @CardFEE1 money,        
    @MatMoney MONEY,       
    @Matprice money, 
    @olddoccode varchar(20),      
    @Totalmoney2 MONEY,      
    @Totalmoney3 MONEY,      
    @Totalmoney4 MONEY,      
    @Credit MONEY,    
    @packageName VARCHAR(200),
    @Password VARCHAR(200) ,  
    @refcode VARCHAR(20),
    @HDText varchar(max),
    @MatCouponsBarcode varchar(50),					--终端优惠券编码
    @MatDeductAmount money,								--终端优惠金额
    @OpenAccountLimit INT,									--客户开户限制个数
    @dptOpenAcccountLimit int,								--部门开户限制个数
    @CustomerID VARCHAR(50),								--客户编码,为唯一的guid
    @Minage int,														--最小开户年龄
    @Vouchertype varchar(50),									--证件类型
    @PhoneNumber varchar(50),								--联系电话
    @PhoneNumber1 varchar(50),								--固定电话
    @ContactAddress varchar(500),							--联系地址
    @Birthday datetime,											--生日
    @ValidDate datetime,											--有效期
    @NetType VARCHAR(50),									--网络类型,为3G,2G等
    @PreSIMCode varchar(50),									--预开户绑定的空白卡
    @PreSeriescode varchar(50),								--预开户绑定的手机串号
    @SerialNumberState varchar(50),						--号码状态
    @SerialNumberRefcode varchar(50),					--号码绑定的单号
    @BusiType Varchar(50),										--业务类型
    @BasicDeposits Money,										--基本预存款
    @minDeposits	Money,										--最低预存款
    @Deposits Money,												--代收联通款
    @DepositsNameCode Varchar(50),						--代收联通款编码
    @DepositsNameName Varchar(200),					--代收联通款名称
    @Totalmoney_H Money,										--单据头金额和
    @Totalmoney_D Money,										--单据明细金额和
    @DeductAmount Money,									--单据明细抵扣金额和
    @MatScore Money,											--单据名称商品积分和
    @bitHasPhone Bit,												--业务类型中是否包含手机
    @bitOpenAccount Bit,											--业务类型中是否开户
	@busiStockState Varchar(20),								--业务类型中对库存的限制
	@SeriesState Varchar(20),									--实际串号的库存状态,在终端校验一段代码中有使用.
	@SQL Nvarchar(Max)											--动态执行的sql
	Create table #DocData(
		Doccode varchar(50),
		FormID int,
		stcode varchar(50),
		SDOrgID varchar(50),
		SDorgPath varchar(200),
		AreaID varchar(50),
		AreaPath varchar(50),
		dpttype varchar(50),
		docdate datetime)
		
		
 /***************************************************入网审核处理************************************************************/                                          
 IF @formid IN (9102, 9146,9237) --客户新入网单
 BEGIN
 /*****************************************************取出数据********************************************************/        
     SELECT @doctype = doctype, @sdorgid = uo.sdorgid, @sdorgName = uo.sdorgname,                         
            @doctype = uo.DocType, @formtype = 5, @dptType = uo.dptType, @packageID = uo.PackageID,
             @combocode=combocode,@comboname=comboname,@customercode = cltcode,@summoney=uo.summoney,
            @Companyid2=uo.Companyid2,@hdText=uo.HDText,@dptType=uo.dptType,@ComboFEEType=uo.comboFEEType,
            @PhoneRate=PhoneRate,@creditleft=creditleft,@UserDigit4=@UserDigit4,@ServiceFEE=ServiceFEE,                        
            @Price=Price,@OtherFEE=OtherFEE,@done=done,@cltCode2=cltcode2,@Packagecode=uo.PackageCode,@ICCID=uo.iccid,@CardMatName=uo.CardMatName,                   
            @cardmoney=ISNULL(cardfee1,0),@ReservedCardmoney=uo.cardmoney, @CardSpecial=uo.CardSpecial,@ReservedDoccode=uo.ReservedDoccode,@docstatus=uo.DocStatus,                    
            @cltCode=uo.cltCode,@cltname=uo.cltName,@Vouchercode=uo.usertxt2,@VourcherAddress=uo.drivername,@preallocation=uo.preAllocation,                    
            @stcode=uo.stcode,@sdgroup=uo.sdgroup,@checkstate=uo.checkState,@docdate=docdate,@node=isnull(uo.node,0),
            @SIMSeriesCode=left(iccid,19),@CardMatcode=CardMatCode,@CardFEE1=CardFEE1,@Matprice=isnull(uo.MatPrice,0),
            @Matcode=matcode,@MatMoney=MatMoney,@SeriesCode=uo.SeriesCode,@matname =matname,@refcode=refcode,@NetType=uo.NetType,
            @Totalmoney3=uo.totalmoney3,@Totalmoney4=uo.totalmoney4,@Credit=uo.Credit,@packageName=uo.PackageName, @BusiType =uo.busiType,
            @Deposits=Isnull( uo.Deposits,0),@BasicDeposits= isnull(uo.BasicDeposits,''),@minDeposits=Isnull(minDeposits,0),
			@totalmoney_H = Isnull(phonerate, 0) + Isnull(otherfee, 0) + Isnull(servicefee, 0) + Isnull(PackagePrice, 0) + Isnull(cardfee1, 0) +Isnull(uo.Price, 0) + Isnull(MatMoney, 0),
			@birthday=convert(datetime,uo.BirthDay),@ValidDate=convert(datetime,uo.validdate),@ContactAddress=uo.ContactAddress,
			@PhoneNumber=uo.PhoneNumber,@PhoneNumber1=PhoneNumber1,@MatDeductAmount =isnull(uo.matDeductAmount,0), @MatCouponsBarcode=uo.matCouponsbarcode,@VIPID=uo.vipid
     FROM   Unicom_Orders uo   WITH(NOLOCK)
     WHERE  uo.DocCode = @doccode
     if @@RowCount=0
		begin
			raiserror('单据不存在,操作无法继续.',16,1)
			return
		end 
        --删除数量为零的可选商品                                                    
    DELETE FROM Unicom_OrderDetails        
        WHERE DocCode = @doccode        
            AND optional = 1        
            AND ISNULL(Digit, 0) = 0 
     --取出单据明细信息
	Select * Into #Unicom_OrderDetails From Unicom_OrderDetails uod With(Nolock) Where uod.DocCode=@doccode
     --取出部门信息                    
     SELECT @AreaID=areaid,@SdorgPath=path FROM oSDOrg os  WITH(NOLOCK)   WHERE os.SDOrgID=@sdorgid        
     --取出区域路径                  
     SELECT @AreaPath=PATH FROM gArea ga WHERE ga.areaid=@AreaID
	 
	--如果有组合商品,则还取出组合商品的单号                        
	IF @Packagecode IS NOT NULL                        
	SELECT @PackageDoccode=doccode,@PackageGroupName=ph.packname            
	FROM policy_h ph WHERE ph.FormID=9115 AND ph.packid=@Packagecode
	--根据业务类型取出业务数据
	Select @BusiType=ph.PolicygroupID,@bitHasPhone=Isnull(pg.hasPhone,0),@bitOpenAccount=Isnull(pg.OpenAccount,1),
	@old=Isnull(pg.oldCustomerBusi,0),@busiStockState=Isnull(pg.StockState,'在库')
	From policy_h ph,T_PolicyGroup pg
	Where ph.DocCode=@packageID
	And ph.PolicygroupID=pg.PolicyGroupID
	If @@ROWCOUNT=0
		BEGIN
			Raiserror('业务类型不存在,业务无法继续,请重新制单.',16,1)
			return
		END

	--对套餐进行校验和控制
	if isnull(@combocode,'')='' and @bitopenaccount=1
		begin
		
			Select @ComboCode=ComboCode From combo_h Where ComboName=@comboName
			if @@ROWCOUNT=0
				begin
					raiserror('套餐信息不存在,请重新选择套餐.',16,1)
				end
				
		end
	--取网络类型
	IF ISNULL(@NetType,'')=''
	BEGIN
		select @NetType=combotype from combo_h with(nolock) where ComboCode=@ComboCode
		if isnull(@NetType,'')=''
			BEGIN
				SELECT @NetType=dbo.fn_getNetType(@seriesnumber)
			END
			--网络类型判断
			IF ISNULL(@NetType,'')=''
				BEGIN
					RAISERROR('未知网段类型,请联系系统管理员!',16,1)
					return
				END
	End
	--取出预存款,代收联通款数据
	/*Select @minDeposits=dbo.fn_getComboInfo(@sdorgid,@seriesnumber,@comboName,@PackageID,'1'),@Deposits=gpc.Deposits,
	@DepositsNameCode=gpc.DepositsMatcode,@DepositsNameName=gpc.DepositsMatName
	From dbo.fn_getPackageCombo(@packageID,@seriesnumber,@sdorgid) gpc
	Where gpc.combocode=@ComboCode*/
	Select @minDeposits=isnull(gpc.minPrice,0),@Deposits=isnull(gpc.Deposits,0),
	@DepositsNameCode=gpc.DepositsMatcode,@DepositsNameName=gpc.DepositsMatName
	From dbo.fn_getComboInfoTable(@Sdorgid,@Seriesnumber,@combocode,@packageID) gpc
	if @dptType in('加盟店')
		BEGIN
			exec sp_ExecuteExpression @formid,@doccode,0,@Totalmoney2 output
		END
	--初始化数据
	 UPDATE unicom_orders
	 SET    commission = 0,
			score = 0,
			score1 = 0,
			totalmoney2=@totalmoney2,
			totalscore = 0,
			nettype=@NetType,
			DocDate = CONVERT(VARCHAR(10), GETDATE(), 120),
			ComboCode = isnull(nullif(combocode,''),@ComboCode),									--只有当套餐编码为空的时候才修改
			DepositsMatcode = @DepositsNameCode,
			DepositsMatName = @DepositsNameName,
			Deposits =Isnull( @Deposits,0),
			minDeposits=Isnull(@minDeposits,0),
			BasicDeposits =isnull(price,0)-Isnull(@Deposits,0),
			matDeductAmount  = case when isnull(matCouponsbarcode,'')='' then 0 else matDeductAmount end					--若无优惠券,则清空金额.
	 WHERE  doccode = @doccode
----------------------------------------------------------业务计算------------------------------------------
    Select * Into #iSeries From iSeries is1 with(nolock) where is1.SeriesCode in(isnull(@SeriesCode,''),left(isnull(@ICCID,''),19))
    insert into #DocData(Doccode,FormID,stcode,SDOrgID,SDorgPath,AreaID,AreaPath,dpttype,docdate)
	Select @doccode,@formid,@stcode,@sdorgid,@SDOrgPath,@AreaID,@AreaPath,@dptType,@docdate 
	--From   v_unicomOrders_HD With(Nolock)
	--Where  DocCode = @doccode
	if @dptType<>'加盟店'
		BEGIN
			;with cte(doccode,formid,seriescode,rowid,matcode,digit,price,totalmoney,price2,couponsbarcode,DeductAmout)as(
				--商品明细
				select @doccode,@formid,seriescode,rowid,matcode,digit,price,totalmoney,uod.price2,couponsbarcode,deductamout
				  from #Unicom_OrderDetails uod with(nolock) WHERE uod.DocCode=@doccode 
			union all
				--手机
				select @doccode,@formid,@seriescode,CONVERT(VARCHAR(50), newid()),@matcode,1,@matprice,@matMoney,0,@MatCouponsBarcode,@MatDeductAmount
				where isnull(@matcode,'')<>''
			union all
				--空白卡
				select @doccode,@formid,NULL,CONVERT(VARCHAR(50), newid()),@cardmatcode,1,@CardFEE1,@CardFEE1,0,NULL,0 where isnull(@cardmatcode,'')<>'' 
			union ALL
				--服务费
				select @doccode,@formid,NULL,CONVERT(VARCHAR(50), newid()),propertyvalue,1,@ServiceFee,@ServiceFee,0,NULL,0
				From dbo.fn_sysGetNumberAllocationConfig('靓号服务费') fsgnac
			union all
				--靓号预存款
				select @doccode,@formid,NULL,CONVERT(VARCHAR(50), newid()),propertyvalue,1,@phoneRate,@phoneRate,0,NULL,0
				From dbo.fn_sysGetNumberAllocationConfig('靓号预存费') fsgnac
			union all
				--基本预存款
				select @doccode,@formid,NULL,CONVERT(VARCHAR(50), newid()),propertyvalue,1,@price,@price,0,NULL,0
				From dbo.fn_sysGetNumberAllocationConfig('基本预存款') fsgnac
			union all
				--其它费用
				select @doccode,@formid,NULL,CONVERT(VARCHAR(50), newid()),propertyvalue,1,@otherFee,@otherFee,0,NULL,0
				From dbo.fn_sysGetNumberAllocationConfig('其它费用') fsgnac
			)
			--生成数据源
			Select @doccode as Doccode,@formid as FormID,@DocDate as DocDate,@sdorgid as SDorgID,os.SDOrgName,
			os.dptType,os.path as SDorgPath,os.AreaID,ga.areaname,ga.path as areaPath,@Combocode as Combocode,@PackageID as PackageID,
			a.rowid,a.seriescode,a.matcode,img.matname,a.digit,a.price,a.totalmoney,a.price2,img.MatGroup,img2.path as matgroupPath,ph.PolicygroupID,ph.DocType as PackageType,
			ISNULL(ch.Price,0) as comboPrice,a.couponsbarcode,isnull(a.DeductAmout,0) as DeductAmout,isnull(@node,0) as node
			Into #preare_DataSource 
			from cte a inner join iMatGeneral img with(nolock) on a.matcode=img.MatCode
			inner join iMatGroup img2 with(nolock) on img.matgroup=img2.matgroup
			inner join oSDOrg os with(nolock) on os.SDOrgID=@sdorgid
			inner join gArea ga with(nolock) on os.AreaID=ga.areaid
			Inner join policy_h ph with(nolock) on ph.DocCode=@PackageID
			Left join combo_h ch on ch.ComboCode=@Combocode
			--从数据源生成积分明细
			delete from ScoreLedgerLog where Doccode=@doccode
			insert into ScoreLedgerLog(Doccode,FormID,RowID,Matcode,couponsbarcode,deductamout)
			select @doccode,@formid,rowid,matcode,couponsbarcode,deductamout
			from #preare_DataSource uod with(nolock)
		end
	Select @tranCount = @@TRANCOUNT
	If @tranCount = 0 Begin Tran  
	Begin Try
		--执行策略
		Exec sp_ExecuteStrategy @formid, @doccode, 1, '', '', ''
		If @tranCount = 0 Commit
	End Try
	Begin Catch
		Select @tips = Error_message() + dbo.crlf() + '异常过程：' + Error_procedure() + dbo.crlf() + '异常发生于第：' + Convert(Varchar(10), Error_line()) + '行'
		If @tranCount = 0 Rollback
		   Raiserror(@tips, 16, 1) 
		   Return
	End Catch

     --重新读取修改后的数据      
  SELECT @doctype = doctype, @sdorgid = uo.sdorgid, @sdorgName = uo.sdorgname,                         
            @doctype = uo.DocType, @formtype = 5, @dptType = uo.dptType, @packageID =                         
            uo.PackageID, @combocode=combocode,@comboname=comboname,@customercode = cltcode,@summoney=uo.summoney,
            @Companyid2=uo.Companyid2,@HDtext=uo.HDText,@dptType=uo.dptType,@ComboFEEType=uo.comboFEEType,
            @PhoneRate=PhoneRate,@creditleft=creditleft,@UserDigit4=@UserDigit4,@ServiceFEE=ServiceFEE,                        
            @Price=Price,@OtherFEE=OtherFEE,@done=done,@cltCode2=cltcode2,@Packagecode=uo.PackageCode,@ICCID=uo.iccid,@CardMatName=uo.CardMatName,                   
            @cardmoney=ISNULL(cardfee1,0),@ReservedCardmoney=uo.cardmoney,@CardSpecial=uo.CardSpecial,@ReservedDoccode=uo.ReservedDoccode,@docstatus=uo.DocStatus,                    
            @cltCode=uo.cltCode,@cltname=uo.cltName,@Vouchercode=uo.usertxt2,@VourcherAddress=uo.drivername,@preallocation=uo.preAllocation,                    
            @stcode=uo.stcode,@sdgroup=uo.sdgroup,@checkstate=uo.checkState,@docdate=docdate,@node=isnull(uo.node,0),
            @SIMSeriesCode=left(iccid,19),@CardMatcode=CardMatCode,@CardFEE1=CardFEE1, @Matprice=isnull(uo.MatPrice,0),
            @Matcode=matcode,@MatMoney=MatMoney,@SeriesCode=uo.SeriesCode,@matname =matname,@refcode=refcode,@NetType=uo.NetType,
            @Totalmoney3=uo.totalmoney3,@Totalmoney4=uo.totalmoney4,@Credit=uo.Credit,@packageName=uo.PackageName, @BusiType =uo.busiType,
            @Deposits=Isnull( uo.Deposits,0),@BasicDeposits= isnull(uo.BasicDeposits,''),@minDeposits=Isnull(minDeposits,0),
			@totalmoney_H = Isnull(phonerate, 0) + Isnull(otherfee, 0) + Isnull(servicefee, 0) + Isnull(PackagePrice, 0) + Isnull(cardfee1, 0) +Isnull(uo.Price, 0) + Isnull(MatMoney, 0),
			@birthday=convert(datetime,uo.BirthDay),@ValidDate=convert(datetime,uo.validdate),@ContactAddress=uo.ContactAddress,
			@PhoneNumber=uo.PhoneNumber,@PhoneNumber1=PhoneNumber1,@MatDeductAmount =isnull(uo.matDeductAmount,0),@MatCouponsBarcode=uo.matCouponsbarcode,@VIPID=uo.vipid
     FROM   Unicom_Orders uo   WITH(NOLOCK)
     WHERE  uo.DocCode = @doccode     
	
	--取出号码信息
	If Isnull(@bitOpenAccount,0)=1
		BEGIN
			select @PreSIMCode=cardnumber,@PreSeriescode=seriescode,@SerialNumberState=sp.[STATE], @SerialNumberRefcode=isnull(sp.RefCode,@doccode)
			from SeriesPool sp with(nolock) where sp.SeriesNumber=@seriesnumber
		END
 -- begin tran exec sp_RequestCheckDoc  9237,'RS20120323000007','system','system','18665473974','','管理员'  rollback       
 
  /***********************************************************************单据基本信息控制*******************************************************/                       
     --检查单据状态                                                                                             
     IF @docstatus>0  OR (@checkstate IS NOT NULL AND @checkstate<>'退回')                        
     BEGIN
         RAISERROR('单据当前状态不允许执行审核请求!',16,1)                         
         RETURN
     END                         
     --如果需要开户,但是号码状态不为已选,或号码绑定的单不为本单,则抛出异常
     If @bitOpenAccount=1 and (@SerialNumberState In('已选','已售') and isnull(@SerialNumberRefcode,@doccode)!=@Doccode)        
     Begin
     	Raiserror('号码资源因长时间闲置已被占用或无效,请重新选号.',16,1)
     	return                              
     END
     --如果需要开户,但是号码状态不为已选,或号码绑定的单不为本单,则尝试重新占号
     If  @bitOpenAccount=1 and (@SerialNumberState='待选')                      
     Begin
     	EXEC sp_OccupySeriesNumber @BusiType ,@packageID ,@usercode, @seriesnumber, @formid, @doccode, @sdorgid, @formid                              
     END               
     --必须录入会员卡号          
	 if @dptType<>'加盟店' and isnull(@VIPID,'')='' and @BusiType<>'01.01.04'
		BEGIN
			raiserror('必须录入会员卡卡号才能继续提交审核,若有疑问请咨询会员系统技术支持[刘俊清]联系电话[13560357780]',16,1)
			return
		END
 --若出现套包名称不为空,而套包编码为空的异常    
	IF ISNULL(@packageName,'')!='' AND ISNULL(@packageID,'')=''    
	BEGIN    
		RAISERROR('当前单据政策出现异常,请重新选择套包政策.',16,1)    
		return    
	End
--预存款检查
	If Isnull(@Price,0)<Isnull(@minDeposits,0)+Isnull(@Deposits,0)
		Begin
			Select @tips='基本预存款不得低于'+convert(varchar(20),Isnull(@minDeposits,0)+Isnull(@Deposits,0))+'元'
			Raiserror(@tips,16,1)
			return
		END
	--门店开户数限制
	select @dptOpenAcccountLimit=isnull(dbo.fn_getSDOrgConfig(@sdorgid,'dptOpenAcccountLimit'),0)
	if isnull(@dptOpenAcccountLimit,0)<>0
		BEGIN
			if isnull(@dptOpenAcccountLimit,0)<0
				BEGIN
					select @tips='您的开户操作需要审核后才可继续.若有疑问,'+case when @dpttype='加盟店' then '请联系加盟部处理.' else '请向子公司申请后联系后台处理.' end
					raiserror(@tips,16,1)
					return
				END
			if isnull(@dptOpenAcccountLimit,0)>0
				BEGIN
					if @dptOpenAcccountLimit<=(select count(*) from Unicom_Orders uo with(nolock) 
					                           where uo.DocDate=convert(varchar(10),getdate(),120) 
					                           and uo.sdorgid=@sdorgid 
					                           and uo.checkState in('待审核','通过审核')
					)
					BEGIN
						select @tips='您的开户操作需要审核后才可继续.若有疑问,'+case when @dpttype='加盟店' then '请联系加盟部处理.' else '请向子公司申请后联系后台处理.' end
						raiserror(@tips,16,1)
						return
					END
				END
		END
 /**********************************************8***********SIM卡处理******************************************/ 

     --取出空白卡串号信息,当需要空白卡,且有ICCID时才取出信息
     If @bitOpenAccount=1
		BEGIN
			--预约客户特殊处理,不要求卡号,但是依然要有空白卡信息,以出库存
			IF ISNULL(@ICCID,'')='' AND ISNULL(@ReservedDoccode,'')=''
				BEGIN
					RAISERROR('空白卡未录入,请读卡!',16,1)
					return
				End
			--若空白卡长度小于19位,则抛出异常.忽略预约客户与预开户.145上网卡只需要录11位卡号.
			IF (LEN(@ICCID)<19 and len(@ICCID)<>11)  AND ISNULL(@ReservedDoccode,'')='' And Isnull(@preallocation,0)=0
				BEGIN
					RAISERROR('空白卡长度不足20位,请重新读卡!',16,1)
					return
				end
			--若空白卡长度不得大于20位
			IF LEN(@ICCID)>20
				BEGIN
					RAISERROR('空白卡长度不能超过20位,请重新读卡!',16,1)
					return
				end

			--检查预开户号码
			if isnull(@preallocation,0)=1 and isnull(@PreSIMCode,'')!='' and  left(@ICCID,19)!=isnull(@PreSIMCode,'')
			BEGIN
				raiserror('号码%s为预开号码,已绑定SIM卡[%s],请使用正确的SIM卡.',16,1,@Seriesnumber,@PreSIMCode)
				return
			END
 
			--空白卡信息处理
			DECLARE @stcode1 VARCHAR(50),@State VARCHAR(20)
			--取出空白卡信息
			 SELECT @CardMatcode=a.MatCode,@stcode1=a.stcode,@State=a.[state] 
			 From #iSeries  a WITH(Nolock)  WHERE a.SeriesCode=@SIMSeriescode
			 And State<>'出库'
 
			--若不在串号表中,则当成默认的空白卡处理
			IF @@ROWCOUNT=0 
				BEGIN
					
					--根据网段获取SIM卡商品编码
					/*IF @NetType IN('3G')
						SELECT @CardMatcode=x.PropertyValue 
							 FROM dbo.fn_sysGetNumberAllocationConfig('128K空白卡商品编码') x
					ELSE
						SELECT @CardMatcode=x.PropertyValue 
							 FROM dbo.fn_sysGetNumberAllocationConfig('64K空白卡商品编码') x
					*/
					--防止无SIM卡商品信息
			        IF ISNULL(@CardMatcode,'')=''
						BEGIN
							RAISERROR('无SIM卡商品信息,请选择对应SIM卡商品.',16,1)
							return
						END
					/*if Len(@ICCID)=19 and isnumeric(@ICCID)=1
						BEGIN
							select @ICCID=dbo.fn_getICCID(@ICCID)
						END*/
					--检查空白卡库存
					/*iF NOT EXISTS(SELECT 1 FROM iMatStorage ims WITH(NOLOCK) WHERE ims.MatCode=@CardMatcode AND ims.stCode=@stcode AND ims.unlimitStock>0) AND @dptType NOT IN('加盟店')
						BEGIN
							RAISERROR('SIM卡库存不足,不允许出库,请联系仓管人员!%s,%s',16,1,@CardMatcode,@stcode)
							return
						END*/
				END
			--若在串号表中存在,则对串号表中的信息进行处理
			ELSE
			BEGIN
				--库存状态检查
				IF @State NOT IN('在库','应收')
					BEGIN
						RAISERROR('SIM卡当前库存状态为[%s],不可销售!',16,1,@state)
						return
					END
				--仓库检查
				IF @stcode<>@stcode1 and @dptType!='加盟店'
					BEGIN
						RAISERROR('SIM卡不在本仓库,请调入后再使用.',16,1)
						return
					END
				--检查卡段与号码段是否正确      select   dbo.fn_checksim('1.3.769.05.03','18664108663','8986011066580608540')                                                     
				 IF (      
						dbo.fn_checksim(@sdorgid, @SIMseriesCode, @seriesnumber) = 0      
						AND ISNULL(@old, 0) = 0      
					)      
				 BEGIN      
					 RAISERROR('您选择的SIM卡号段不正确,请仔细检查!', 16, 1)       
					 RETURN      
				 END 
			END
			--取出空白卡商品信息
			SELECT @CardMatName=matname,@mustReadCard=img.mustReadCard
			  FROM iMatGeneral img WITH(NOLOCK) WHERE img.MatCode=@CardMatcode
		END
	ELSE
		--不需要开户的情况
		BEGIN
			--若本身不需要开户,但是也录了空白卡,则将空白卡清空
			IF ISNULL(@ICCID,'')!=''
				BEGIN
					UPDATE unicom_orders
						SET ICCID = NULL,CardNumber = NULL,CardMatCode = NULL,CardMatName = NULL,CardFEE1 = NULL
					WHERE DocCode=@doccode
				END
			/*IF ISNULL(@ICCID,''
			--改成直接提示错误
			RAISERROR('本单不需要开户,请删除空白卡信息再提交!',16,1)
			return*/
		END

 /***************************************************************SIM处理结束**********************************************/         
 
 /***************************************************************客户资料处理*********************************************/        

  --一证一户限制.2012-07-10 三断笛
  
SELECT @OpenAccountLimit=dbo.fn_getSDOrgConfig(@sdorgid,'LimitOpenAccount')
  --当门店或区域限制开户个数时才进行限制
  IF @OpenAccountLimit>0
	BEGIN
		DECLARE @Count INT,@Count1 INT
		SELECT @count=0,@count1=0
		--取出这个客户可开户个数
		SELECT @Count=OpenAccountLimit,@CustomerID=CustomerID
		  FROM URP11.JTURP.dbo.SOP_DIM_customers WITH(NOLOCK) Where strVoucherCode=@Vouchercode
		--若此门店客户允许开户个数大于此客户的允许开户个数,则以此门店的允许最大开户个数为准
		--若此门店客户允许开户个数小于此客户的允许开户个数,则以此客户的开户个数为准.
		IF isnull(@OpenAccountLimit,0)>isnull(@Count,0)  SET @Count=@OpenAccountLimit
		--只有当开户个数限制大于0时才限制
		IF isnull(@Count,0)>0
			BEGIN
				--计算此客户已开户个数
				SELECT @count1=COUNT(*) FROM SOP_dim_Profile sdp WITH(NOLOCK) WHERE sdp.CustomerID=@CustomerID AND sdp.[Status]>=0 GROUP BY sdp.CustomerID
				--当限制开户个数为1时,再统计此证件开户状态为待审核与通过审核的单据数量.
				if isnull(@Count,0)=1
					BEGIN
						select @Count1=isnull(@Count1,0)+count(*) from Unicom_Orders uo with(nolock) where uo.usertxt2=@Vouchercode and uo.checkState in('待审核','通过审核') and uo.formid in(9102,9146,9237)
					END
				else
					--当限制开户数量大于1时,只统计该证件的待审核单据数,不统计通过审核单据数量,防止重复统计.
					BEGIN
						select @Count1=isnull(@Count1,0)+count(*) from Unicom_Orders uo with(nolock) where uo.usertxt2=@Vouchercode and uo.checkState in('待审核') and uo.formid in(9102,9146,9237)
					END
				--当已开户个数达上限时,禁止开户
				IF isnull(@count1,0)>=isnull(@count,0)
					BEGIN
						select @tips='客户[%s]已开户达%d个,超过开户数量上限%d户,'+case when @dpttype='加盟店' then '请联系加盟部处理.' else '请向子公司申请后联系后台处理.' end
						RAISERROR(@tips,16,1,@Vouchercode, @count1,@count )
						return
					END
			END
	END  
  
   --黑名单客户不允许开户                      
  /*IF EXISTS ( SELECT 1        
FROM customers        
     WHERE CustomerCode = @customerCode        
      AND BlackList = 1 )         
  BEGIN                      
   RAISERROR('该客户已被列入黑名单,不允许开户,如有疑问,请联系运营服务部.',16,1)                      
   RETURN                      
  END*/
  IF dbo.isValidSeriesNumber(isnull(@phoneNumber,''),0) = 0  
  BEGIN
  		select @tips='您输入的联系电话'+isnull(@phoneNumber,'')+'格式不正确!,请输入正确的移动电话或固定电话,固话请按[区号](-)[电话](-)[分机号(可选)]格式录入,如076989972111' 
        raiserror(@tips,16,1)
        return
     END  
     if ISNULL(@phoneNumber1,'') <> ''  
               AND dbo.isValidSeriesNumber(@phoneNumber1,0) = 0  
     BEGIN  
         select @tips='您输入的固定电话'+isnull(@phoneNumber1,'')+'格式不正确!,请输入正确的移动电话或固定电话,固话请按[区号](-)[电话](-)[分机号(可选)]格式录入,如076989972111'
         raiserror(@tips ,16,1)
         return
     END   
     IF @phoneNumber = @seriesnumber and @bitOpenAccount=1
     BEGIN  
        raiserror('联系电话不能为开户受理号码!' ,16,1)
        return
     END   
     --对身份证进行检查         
     IF @vouchertype = '身份证'  
     BEGIN  
         /* IF EXISTS(SELECT 1  
                   FROM   CheckIDCard(@vouchercode)  
                   WHERE   convert(varchar(10),Birthday,120) <> convert(varchar(10),@birthday,120)
            )  
         BEGIN  
             INSERT INTO @table  
             SELECT 1,1,'身份证出生日期与您录入的出生日期不一致!'  +convert(varchar(10),@birthday,120)+','+ISNULL(@vouchercode,'')
         END    */
         --检查身份证长度     
         IF LEN(@VoucherCode) NOT IN (15, 18)
         BEGIN  
            raiserror('您输入的身份证号码长度不对，请检查！'  ,16,1)
            return
         END   
         --检查身份证号码是否正确 select * from  customers                                  
         IF EXISTS(SELECT 1  
                   FROM   checkidcard(@vouchercode) b  
                   WHERE  b.Valid = 0  
            )  
         BEGIN  
             raiserror('您输入的身份证号码非法,请提供正确的身份证信息.'  ,16,1)
             return
         END  
     END   
     --证件号码长度太短    
     IF LEN(@VoucherCode) < 6  
     BEGIN  
         raiserror('您输入的证件号码太短!' ,16,1)
         return
     END      
     
     --限制客户地址格式     
     SELECT @tips='您输入的“现地址”格式不正确,“现地址”请以：' + CASE areaid  
                                                                       WHEN   
                                                                            '755' THEN   
                                                                            '深圳市××区××镇(村路园厦)××号(室)'  
                                                                       ELSE   
                                                                            '××市(州)××镇(区)××村××路(巷)××号'  
                                                                            +   
                                                                            '“格式录入'  
                                                                  END  
     FROM   oSDOrg WITH(NOLOCK)  
     WHERE  sdorgid = @sdorgid  
            AND ((areaid <> '755'  
                     AND PATINDEX('%[市州县]%[镇区]%[路巷村]%号%',@ContactAddress) = 0  
                 )  
                    OR (areaid = '755'  
                           AND PATINDEX('%深圳市%区%[镇村路园厦]%[号室]%',@ContactAddress) = 0  
                       )  
                ) 
       and isnull(@AreaPath,'') not like '%/02/%'
       if @@ROWCOUNT>0
		BEGIN
			raiserror(@tips,16,1)
			return
		END
     --禁止18周岁以下用户操作
	SELECT @Minage=dbo.fn_getSDOrgConfig(@sdorgid,@Minage) 
	IF @Minage>0 and DATEDIFF(YEAR,@birthday,GETDATE()) < @Minage   
		BEGIN
			select @tips='未满'+convert(varchar(10),@minage)+'周岁不允许办理此业务!'
			raiserror(@tips,16,1)
			return
		END
	--证件有效期已过时不允许办理    
	IF @validDate <= GETDATE()  
	BEGIN  
		raiserror('证件已过有效期，不允许办理此业务！'  ,16,1)
		return
	END
  --检查老客户是否上传了附件 2011-07-30 修复一个bug,并且添加了只对部门配置中要求上传证件的部门进行检查                        
  IF dbo.fn_getSDOrgConfig(@sdorgid, 'uploadvoucher') = 1      
  BEGIN      
      IF  NOT EXISTS(      
                 SELECT 1      
                 FROM   Unicom_Orders_files  WITH(NOLOCK)       
                 WHERE  doccode = @doccode      
             )      
      BEGIN      
          RAISERROR('您选择的客户尚未上传证件,请点击【上传资料】按钮上传客户证件.',16,1)       
          RETURN      
      END      
  END        
/***************************************************************客户资料处理结束*********************************************/       

/***************************************************************库存与串号处理*********************************************/

	If @bitHasPhone=1
		Begin
			Declare @matcode1 Varchar(50),@isava Int,@isbg Int,@salemun Int,@fk int
			If Isnull(@SeriesCode,'')=''
				BEGIN
					Raiserror('本活动要求包含手机,请录入终端后再提交.',16,1)
					return
				End
			/*if isnull(@matname,'')='手机' 
				BEGIN
					raiserror('请在手机[品牌型号]处输入完整的手机型号手再提交审核.',16,1)
					return
				END*/
			Select @SeriesState='无状态'
			Select @matcode1=matcode,@SeriesState=State,@isava=is1.isava,@isbg=is1.isbg,@salemun=is1.salemun,@fk=fk,@stcode1=stcode
			From  #iSeries is1  With(Nolock)  Where is1.SeriesCode=@SeriesCode
			If  Not Exists(Select 1 From commondb.dbo.split( isnull(@busiStockState,'在库'),',') x Where x.List=@SeriesState)
				BEGIN
					Raiserror('终端库存状态与政策不符,此终端库存状态为[%s]本活动要求终端库存状态为[%s]',16,1,@SeriesState, @busiStockState)
					return
				End
			--若商品信息不符,也要抛出异常
			If isnull(@matcode1,'')<>isnull(@matcode,'') And @SeriesState<>'无状态'
				BEGIN
					Raiserror('单据商品信息与实际信息不符,请重新录入终端串号进行校验.',16,1)
					return
				End
			--若策略中未允许已售,则不允许封库机,售后机,被占用机型的使用.
			If Not Exists(Select 1 From commondb.dbo.[SPLIT](Isnull(@busiStockState,'在库'),',') s Where s.list='已售')
				BEGIN
					If Isnull(@fk,0)=1
						BEGIN
							Raiserror('该终端已封库,不允许销售.',16,1)
							return
						End
					If Isnull(@isava,0)=1 Or Isnull(@isbg,0)=1
						BEGIN
							Raiserror('该终端已被占用,不允许重复使用.',16,1)
							return
						End
					If Isnull(@salemun,0)=1
						BEGIN
							Raiserror('该终端已售,不允许再次销售.',16,1)
							return
						End
					If Isnull(@salemun,0)=-1
						BEGIN
							Raiserror('该终端目前处理售后处理状态,不允许销售,请联系售后处理.',16,1)
							return
						END
					IF @stcode1<>(select stcode from oStorage os where os.sdorgid=@sdorgid)
						BEGIN
							if not exists(select 1 from StorageConfig where pubstcode=@stcode1 and stcode=@stcode)
								BEGIN
									raiserror('该终端不在本仓库,请确认终端已调入.',16,1)
								END
						END
				END
			
			SELECT @tips='该终端不能参与此活动,请选购其他机型或参与其他活动.' 
			FROM iMatGeneral img2 WITH(NOLOCK)
			inner join iMatGroup img WITH(NOLOCK) ON img2.matgroup=img.matgroup
			Where img2.MatCode=@matcode  
			and not  EXISTS(SELECT 1 FROM policy_d pd 
							 WHERE pd.DocCode=@packageid
							 AND (
		                 			(isnull(pd.MatCode,'')!='' AND pd.MatCode=img2.MatCode)
		                 			OR(ISNULL(pd.MatCode,'')='' 
		                 				AND img.[PATH]  LIKE '%/'+pd.matgroup+'/%')
		                 			 And pd.valid=1
		                 			 And (Isnull(pd.beginDate,'')='' Or pd.beginDate<=convert(datetime,convert(varchar(10),getdate(),120)))
		                 			 And (Isnull(pd.endDate,'')='' Or pd.endDate>=convert(datetime,convert(varchar(10),getdate(),120)))
							 )
							  
			                
			)
			AND EXISTS(SELECT 1 FROM dbo.fn_sysGetNumberAllocationConfig('手机大类') x WHERE img.path  LIKE '%/'+x.propertyvalue+'/%')
			IF @@ROWCOUNT>0
				BEGIN
					RAISERROR(@tips,16,1)
					return
				END
		End    
     --检查商品库存
    if @dptType<>'加盟店'
		BEGIN
			SELECT @tips = ''                                                  
			SELECT @tips = @tips + '您输入的商品' + uod.matname + '库存不足，请仔细检查!' + CHAR(10)        
				FROM iMatStorage is1 with(nolock)
				INNER JOIN #preare_DataSource uod ON is1.matcode = uod.MatCode         
				INNER JOIN iMatGeneral ig with(nolock) ON uod.MatCode = ig.MatCode        
				WHERE ig.MatState = 1        
					AND ISNULL(is1.unlimitStock, 0) < uod.Digit        
					AND ISNULL(@dpttype, '') <> '加盟店'        
					AND is1.stCode = @stcode                                  
			IF @@rowcount >0
				BEGIN                        
					RAISERROR(@tips,16,1)                        
					RETURN                        
				END
			--串号长度检查
			select * from #preare_DataSource
			select @tips=''
			select @tips=@tips+'商品'+img.matname+'串号长度应为'+convert(varchar(2),isnull(img.MatImeiLong,0))+'位,目前为'+convert(varchar(2),len(isnull(a.seriescode,'')))
			from #preare_DataSource a inner join iMatGeneral img with(nolock) on a.matcode=img.MatCode
			where img.MatFlag=1
			and len(isnull(a.seriescode,''))<>isnull(img.MatImeiLong,0)
			if @@ROWCOUNT>0
				BEGIN
					RAISERROR(@tips,16,1)                        
					RETURN    
				END
		END                                                                    
    

/***************************************************************************库存与串号处理结束*********************************************/       
     
/*******************************************************************信用额度控制***********************************************************/        
       
     IF @dptType='加盟店' --and isnull(@creditleft,0)<0                        
     BEGIN
         exec sp_UpdateCredit @formid,@doccode,@sdorgid,1,'1',@remark,@userCode,@TerminalID
 
     END      
  
 /*******************************************************************信用额度控制结束***********************************************************/        
/**************************************************************价格控制段********************************************************************/                        
	if isnull(@dptType,'')<>'加盟店'
		begin		
			select @tips=''
			;with cte(matcode,matname) as(
				select b.matcode,b.matname
				from #Unicom_orderdetails a inner join imatgeneral b with(nolock) on a.matcode=b.MatCode
				inner join imatgroup c on b.matgroup=c.matgroup
				where exists(select * from dbo.fn_sysGetNumberAllocationConfig('手机大类,配件大类,数码产品大类') x where c.path like '%/'+x.propertyvalue+'/%')
				union all
				select @matcode,@matname
				where isnull(@matcode,'')<>'' and isnull(@busiStockState,'在库') like '%在库%'
				)
			select @tips=@tips+'商品['+isnull(a.matname,'')+'］未作价格管理，禁止销售。' +dbo.crlf()
				from cte a outer apply dbo.uf_salesSDOrgpricecalcu3(a.matcode,@sdorgid,'') uss where isnull(uss.sdorgid,'')=''
				if @@ROWCOUNT>0
				BEGIN
					raiserror(@tips,16,1)
					return
				END
		END
   --套包中价格控制                                              
    SELECT @tips = '您选择的商品' + CHAR(10)
    ;With cte_mat(matcode,totalmoney) As(
    	Select @matcode,@MatMoney
    	Union All
    	Select @CardMatcode,@cardmoney
    	where @ReservedCardmoney is not null					--若有预约卡费,则不控制
    	)
    SELECT @tips = @tips + @MatName + '不得低于' + isnull(CONVERT(VARCHAR(10), b.minprice),0) + ',不得高于' + isnull(CONVERT(VARCHAR(10), b.maxprice),99999) + dbo.crlf()
        FROM   iMatGeneral c with(nolock)
        Inner Join cte_mat a ON   c.MatCode =a.MatCode
        LEFT JOIN iMatGroup d ON  c.MatGroup = d.matgroup
        Left Join policy_d b On  b.DocCode = @packageID   
        AND ( 
        			( ISNULL(b.MatCode, '') <> ''  AND c.MatCode = b.MatCode )        
                  OR ( ISNULL(b.MatCode, '') = ''   AND ISNULL(b.matgroup, '') <> ''      AND d.[PATH] LIKE '%/' + b.MatGroup + '/%'     ) 
             
                     )
        WHERE    b.LimitPrice = 1
            AND (
            	 ISNULL(a.totalmoney, 0)  < isnull(b.MinPrice,0)
                OR ISNULL(a.totalmoney, 0)   > isnull(b.MaxPrice,99999))
			and (isnull(b.beginDate,'')=''  or getdate()>=b.beginDate)
			and (isnull(b.endDate,'')='' or getdate()<=b.endDate)
		If @@ROWCOUNT>0
        BEGIN                        
            RAISERROR(@tips,16,1)                        
            RETURN                        
        END                        
                                
     SELECT @tips = '您选择的商品' + CHAR(10)
    ;With cte_mat(seriescode,matcode,digit,totalmoney) As(
    	Select @SeriesCode, @matcode,1,@MatMoney
    	Where @bitHasPhone=1
    	And Not Exists(Select 1 From commondb.dbo.split(Isnull(@busiStockState,'在库'),',') s Where s.list in('已售','无状态'))			--已售的机,无状态的机,不做价格控制
    	Union All
    	Select Left(@ICCID,19), @CardMatcode,1,@cardmoney
    	where @ReservedCardmoney is null										--若有预约卡费,则不控制
    	Union All
    	Select uod.seriesCode, matcode,isnull(digit,0),totalmoney
    	  From Unicom_OrderDetails uod Where uod.DocCode=@doccode
    	)                      
     SELECT @tips = @tips + c.MatName + '售价为['+convert(varchar(20),isnull(m.totalmoney,0)/NULLIF(ISNULL(digit, 0), 0)  ) +']低于最低零售价[' + CONVERT(VARCHAR(52), CONVERT(MONEY, ss.selfprice)) + ']元.' + CHAR(10)        
     From  imatgeneral c  
		Inner Join cte_mat m on c.MatCode=m.matcode
        inner JOIN imatgroup d ON c.matgroup = d.matgroup       
        Outer Apply dbo.uf_salesSDOrgpricecalcu3(c.MatCode,@sdorgid,m.seriescode) ss 
     Where  ISNULL(@cltCode2, '') = ''        
            AND @dpttype <> '加盟店'        
            AND ISNULL(ss.selfprice, 0) > ISNULL(m.totalmoney, 0) / NULLIF(ISNULL(digit, 0), 0)        
            AND ( ISNULL(@packageID, '') = ''        
                  OR NOT EXISTS ( SELECT 1        
                                    FROM policy_d b        
                                    WHERE b.DocCode = @packageID               
                                        AND b.LimitPrice = 1        
                                        AND ( ( ISNULL(b.MatCode, '') <> ''        
                                                AND m.MatCode = b.MatCode        
                                              )        
                                   OR ( ISNULL(b.MatCode, '') = ''        
                                                   AND ISNULL(b.matgroup, '') <> ''        
                                                   AND d.[PATH] LIKE '%/' + b.MatGroup + '/%'               
                                                 )        
                                            ) )        
                )        
            AND m.Digit <> 0                        
                      --同时排除在组合商品中的商品                        
            AND ( ISNULL(@packagecode, '') = ''        
                  OR ( ISNULL(@packagecode, '') <> ''
                       AND m.MatCode NOT IN ( SELECT matcode
                                                FROM policy_d pd
                                                WHERE DocCode = @packagedoccode )
                     )
                )
     If @@ROWCOUNT>0
        BEGIN
            RAISERROR(@tips,16,1)
            RETURN
        END
     --对组合商品的价格进行控制                        
     IF @Packagecode IS NOT NULL
        BEGIN
            SELECT @tips = CHAR(10) + '您选择的商品符合[' + ISNULL(@packagegroupname, '') + ']政策,但以下商品' + CHAR(10)                        
            SELECT @tips = @tips + b.matname + '低于政策价格[' + CONVERT(VARCHAR(20), CONVERT(MONEY, b.price)) + ']元' + CHAR(10)        
                FROM #Unicom_OrderDetails a ,
                    policy_d b 
                WHERE a.MatCode = b.MatCode
                    AND b.DocCode = @PackageDoccode
                    AND a.DocCode = @doccode
                    AND ISNULL(a.totalmoney, 0) / NULLIF(ISNULL(digit, 0), 0) < ISNULL(b.price, 0)      --此处需要注意对NULL值,除数为零及数量进行处理                        
                    AND a.Digit > 0 
            IF @@ROWCOUNT>0 
                BEGIN
                    RAISERROR(@tips,16,1) 
                    RETURN
                END
        END
/***************************************************************************价格控制结束******************************************************************/        

/*************************************************************************政策检查开始********************************************************************/               

  --控制资费方式,2012-03-15日开始执行                  
   DECLARE @now INT                  
   SELECT @now = DAY(GETDATE())                    
                 
   IF @now <= 20   and  ISNULL(@ComboFEEType, '') = '套外资费'
     BEGIN                  
		RAISERROR('二十号前不能选择套外资费，只能选择“全月套餐”或者“套餐减半”!',16,1)                  
		RETURN                  
    END                                 
    --团购政策                        
    IF @packageID = 'TBD2011102600001'         
        BEGIN                        
            IF ISNULL(@summoney, 0) <> 880         
                BEGIN                        
                    RAISERROR('本套包要求录入分期付款金额880元.',16,1)                        
                    RETURN                        
                END                         
            IF ISNULL(@Companyid2, 0) <> '3.020.0008'         
                BEGIN                        
                    RAISERROR('本套包必须选择担保公司[糯米团]',16,1)                        
                    RETURN                        
                END                        
            IF LEN(ISNULL(@HDText, '')) < 2 --OR ISNUMERIC(ISNULL(@remark,0))=0                        
                BEGIN                        
                    RAISERROR('本套包要求在备注栏中录入大于2位的密码.',16,1)                        
                    RETURN               
                END                        
        END
    ------------------------Iphone控制选号费和配件费用----------------------------------------------------
	/*IF @PackageID IN('TBD2012121300060','TBD2012121300080','TBD2012121300100','TBD2012121300120','TBD2012121300140',
	'TBD2012121300160','TBD2012121300200','TBD2012121300180','TBD2012121400000')
	AND ISNULL(@ServiceFEE,0)<100
	AND ISNULL((SELECT SUM(isnull(totalmoney,0)) FROM #Unicom_orderdetails WHERE matgroup LIKE '6.%'),0)<100
		BEGIN
			RAISERROR('本活动要求至少购买总额100元以上配件(不限个数),或选择包含100元以上选号费的靓号.',16,1)
			return
		END*/
	IF @PackageID IN('TBD2012121300040 ')
 
	AND ISNULL((SELECT SUM(isnull(totalmoney,0)) FROM #Unicom_orderdetails WHERE matgroup LIKE '6.%'),0)<300
		BEGIN
			RAISERROR('本活动要求至少购买总额300元以上配件(不限个数).',16,1)
			return
		END
/****************************************************************政策检查结束********************************************************************/

  /*********************************************************从单据确认检查函数转移而来的检查****************************************************/                  
  --延保功能控制                    
     --延保的串号不能不在明细表中                    
     IF EXISTS(                  
     SELECT 1                   
     FROM   SeriesCode_HD a                  
  WHERE  a.FormID = 2445                  
            AND a.Refcode = @doccode                  
            AND NOT EXISTS(SELECT 1                  
                           FROM   #Unicom_OrderDetails b                  
                           WHERE  b.DocCode = @doccode                  
                                  AND a.SeriesCode = b.seriesCode                  
            ))                  
     BEGIN                  
      RAISERROR('延保串号与销售串号不一致.',16,1)                  
      return                  
     END                  
     --延保产品不一致                    
     IF EXISTS(                  
     SELECT 1                  
     FROM   SeriesCode_HD a  WITH(NOLOCK)    
     WHERE  a.formid = 2445                  
            AND a.RefCode = @doccode                  
            AND NOT EXISTS(SELECT 1                  
                           FROM   #Unicom_OrderDetails b                  
                           WHERE  a.ExtendWarrantyMatcode = b.MatCode                  
                                  AND b.DocCode = @doccode                  
            )                  
            )                  
     BEGIN                  
		RAISERROR('销售单据延保产品与延保单延保产品不一致',16,1)                  
		return                  
     end
     --延保单必须要确认                    
     IF EXISTS(                  
     SELECT 1                  
     FROM   SeriesCode_HD sch                  
     WHERE  sch.RefCode = @doccode                  
            AND sch.FormID = 2445                  
            AND sch.DocStatus = 0                  
     )                  
     BEGIN                  
      RAISERROR('延保单尚未确认,请先确认延保单.',16,1)                  
      return                  
     END                  
       --必须有延保单                  
    IF EXISTS(SELECT 1 FROM #Unicom_OrderDetails uod WHERE uod.DocCode=@doccode and uod.MatName LIKE '%延保%' and digit>0)                  
    AND NOT EXISTS(SELECT 1 FROM SeriesCode_HD sch  WITH(NOLOCK) WHERE sch.RefCode=@doccode)                  
  BEGIN                  
   RAISERROR('您选择了延保产品但是尚未制延保单,请单击窗中顶部的[延保]按钮制延保单',16,1)                  
   return                  
  END
  ---优惠券校验      
  BEGIN TRY
  		exec sp_CheckPresentCoupons @formid,@doccode,default,default,@stcode,@CustomerID,@packageID,@ComboCode,'#PreCheck#'
  END TRY
  BEGIN CATCH
		select @tips=dbo.getLastError('优惠券赠送失败.')
		raiserror(@tips,16,1)
		return
  END CATCH     
   BEGIN TRY
  		exec sp_CheckDeductCoupons @formid,@doccode,default,default,@stcode,@CustomerID,@packageID,@ComboCode,'#PreCheck#'
  END TRY
  BEGIN CATCH
		select @tips=dbo.getLastError('优惠券赠送失败.')
		raiserror(@tips,16,1)
		return
  END CATCH      
 --检查预约编号                    
	IF EXISTS(                  
	 SELECT 1                  
	 FROM    PotentialCustomer b With(Nolock)                  
	 WHERE @Vouchercode = b.VoucherCode                  
			AND @ReservedDoccode IS NULL                  
			AND ISNULL(b.ReservedResult,'') IN ('成功')                  
			AND ISNULL(b.[Status],'') IN ('预约成功', '预约成功,等待上门处理')             
			AND b.ReservationDate >= @docDate + 1                  
	)                  
	BEGIN                  
		RAISERROR('该客户为预约客户,请从预约客户服务做单',16,1)                  
		return                  
	END                  
 --日结以后不允许提单                  
	IF EXISTS(SELECT 1 FROM rj_baltag a With(Nolock) WHERE a.sdorgid=@sdorgid AND CONVERT(varchar(10),a.baldate,120)=CONVERT(varchar(10),@docdate,120) AND a.checkflag=1)                  
	AND @doccode<>'PS20120929016501'                  
		BEGIN                  
			RAISERROR('单据当前日期已日结,不允许提单.请反日结后再制单.',16,1)                  
			return                  
		END
 /*********************************************************单据检查结束，开始单据状态修改******************************************************************/

BEGIN TRY    
        
  SELECT @tranCount=@@TRANCOUNT      
  if @tranCount =0 BEGIN tran      
      -------SIM卡处理         
   --begin tran exec sp_RequestCheckDoc  9146,'PS20120323000048','system','system','15697696624','','管理员'  rollback           
   IF ISNULL(@ICCID,'') != ''
      AND ISNULL(@mustReadCard,0) = 1 --AND dbo.fn_getSDOrgConfig(@sdorgid,'rwCardBackground')=1
   BEGIN
       BEGIN TRY
       		--2.更新SIM卡状态                          	
       		EXEC sp_ChangeSIMStatus @ICCID,@SIMSeriesCode,1,@doccode,@formid,5,@seriesnumber,
       			 @sdgroup,@sdorgid,'SIM卡开户单据提交审核.' 
       		--3.更新完以后再重新检查状态                  
       		IF NOT EXISTS (SELECT 1
       					   FROM   iSIMInfo is1 WITH(NOLOCK)
       					   WHERE  is1.ICCID = @ICCID
       							  AND is1.Doccode = @doccode
       							  AND is1.SeriesNumber = @seriesnumber
       		   )
       		BEGIN
       			RAISERROR('更新SIM卡信息失败,请重试!',16,1)
       		END
       END TRY                  
       BEGIN CATCH
			SELECT @tips = dbo.crlf() + 'SIM卡提交失败!' + dbo.crlf() + ISNULL(ERROR_MESSAGE(),'') + '请联系系统管理员!' 
			RAISERROR(@tips,16,1) 
			RETURN
       END CATCH
   End
   --重新计算合计
   Select @Totalmoney_D=Sum(Isnull(totalmoney,0)),@DeductAmount=sum(Isnull(uod.DeductAmout,0))--,@MatScore=sum(Isnull(uod.price2,0))
   From #Unicom_OrderDetails uod with(nolock) 
   Where uod.DocCode=@doccode 
   and digit>0
   --取出商品积分合计
   select @MatScore=sum(score) from ScoreLedgerLog sll with(nolock) where sll.Doccode=@doccode
   --修改申请人申请时间,并且有必要清空上一次审核人的信息                                                            
        Update Unicom_Orders
        Set	checkState = '待审核', applyer = @usercode, applyerName = @username, 
				Auditingdate = Getdate(), Audits = Null, Auditingname = Null, CardNumber = @SIMSeriesCode, 
				CardMatCode =@CardMatcode, CardMatName= @CardMatName,BasicDeposits = Isnull(Price,0)-Isnull(Deposits,0),
				userdigit4=Isnull(@Totalmoney_H,0)+Isnull(@Totalmoney_D,0),
				Score1 = Isnull(@MatScore,0),
				TotalScore = Isnull(@MatScore,0)+Isnull(Score,0),
				DeductAmout = Isnull(@DeductAmount,0)+isnull(matDeductAmount,0),ICCID =@ICCID,
				HDText = isnull(HDText,'')+char(10)+isnull(@remark,'')
        Where	doccode =@doccode
        IF @tranCount=0 AND   @@TRANCOUNT>0 COMMIT
    END TRY
    BEGIN CATCH
		  IF @tranCount=0 AND  @@TRANCOUNT>0 ROLLBACK
				SELECT @tips = '提交审核失败.' + dbo.crlf() + ERROR_MESSAGE() + dbo.crlf() + '请重试或联系系统管理员.'
				RAISERROR(@tips,16,1)
				RETURN
  END Catch
     /**********************************************串号处理************************************************/         
		--当有串号时,对串号进行占用标注
        IF @FormID IN ( 9102, 9146,9237 ) and exists(select 1 from #iSeries)
            BEGIN         
            	/*Print Convert(Varchar(50),Getdate(),120)
				--更新已请求审核的串号，不允许再用           
                UPDATE iseries        
                    SET isava = 1,Occupyed = 1,OccupyedDoc = @doccode     
                WHERE seriescode=@SeriesCode Or SeriesCode=@SIMSeriesCode 
                Print Convert(Varchar(50),Getdate(),120)
                --释放锁定的串号                                                                                  
                UPDATE iSeries        
                    SET Occupyed = 0, OccupyedDoc = Null,isava = 0,isbg = 0        
                    WHERE OccupyedDoc = @doccode
                Print Convert(Varchar(50),Getdate(),120)*/
				SET @sql =		  '                --释放锁定的串号                                                                                   ' + char(10)
				 + '                UPDATE OpenQuery(URP11,''Select isava,Occupyed,OccupyedDoc,isbg From JTURP.dbo.iseries Where OccupyedDoc='''''+@Doccode+''''''' )' + char(10)
				 + '                    SET Occupyed = 0, OccupyedDoc = Null,isava = 0,isbg = 0         ' + char(10)
				 + '                UPDATE OpenQuery(URP11,''Select isava,Occupyed,OccupyedDoc,isbg From JTURP.dbo.iseries Where Seriescode='''''+isnull(@SeriesCode,'')+''''' Or Seriescode='''''+isnull(@SIMSeriesCode,'')+''''''' )' + char(10)
				 + '                    SET isava = 1,Occupyed = 1,OccupyedDoc = @doccode,isbg=1; ' + char(10)
				 + '                Print Convert(Varchar(50),Getdate(),120) ' + char(10)
				Exec sp_executesql @sql,N'@Seriescode varchar(30),@SIMSeriescode varchar(30),@Doccode varchar(30)',@SeriesCode=@SeriesCode,@SIMSeriesCode=@SIMSeriesCode,@doccode=@doccode
				
            END           
            --锁定优惠券,仅锁定本机数据,不修改主服务器
			;with cte as(
				select @MatCouponsBarcode as Couponsbarcode
				union all
				select couponsbarcode from #unicom_orderdetails 
			)
			update a 
				set a.Occupyed=1,
				a.OccupyedDoccode=@doccode
			from iCoupons a,cte b 
			where a.CouponsBarcode=b.couponsbarcode
   --修改号码释放时间,不再被自动释放  
                                                                                           
        UPDATE SeriesPool        
            SET ReleaseDate = '2049-12-31'        
            WHERE SeriesNumber = @seriesnumber
               --插入单据创建时间                                              
        IF NOT EXISTS ( SELECT 1        
                            FROM CheckNumberAllocationDoc_LOG   WITH(NOLOCK)       
                            WHERE doccode = @doccode        
                                AND checkstate = '创建单据' )         
            BEGIN                  
                INSERT INTO CheckNumberAllocationDoc_LOG ( doccode, formid, seriesnumber, checkstate, entername, enterdate, remark, UserName, doctype, formtype,        
                                                           sdorgid, sdorgname )        
                        SELECT doccode, formid, seriesnumber, '创建单据', sdgroup, enterdate, hdtext, entername, doctype, 5, sdorgid, sdorgname        
                            FROM Unicom_Orders uo   WITH(NOLOCK)       
                            WHERE uo.DocCode = @doccode                  
            End   
 End
 /**********************************************************************开户提交完毕**********************************************/  
if @formid in(9244)
	BEGIN
		--密码校验
		SELECT @Password=usertxt4,@packageID=uo.PackageID,@packageName=uo.PackageName,
		@sdorgid=uo.sdorgid,@sdorgName=uo.sdorgname,@dptType='开户返销单',@formType=16,@refcode=refcode
		  FROM Unicom_Orders uo WITH(NOLOCK) WHERE uo.DocCode=@doccode
		--检查单据状态                                                                                             
		 IF @docstatus>0  OR (@checkstate IS NOT NULL AND @checkstate<>'退回')                        
		 BEGIN                        
			 RAISERROR('单据当前状态不允许执行审核请求!',16,1)                         
			 RETURN                        
		 END

		IF dbo.fn_CheckUserLogin(@userCode,@Password,7,'','','')<>1
			BEGIN
				RAISERROR('用户校验失败,请重试!',16,1)
				return
			END
		IF EXISTS(SELECT 1 FROM Unicom_Orders uo WITH(NOLOCK) WHERE uo.DocCode=@refcode AND uo.bitReturnd=1)
			BEGIN
				RAISERROR('此单已返销,不允许再次操作!',16,1)
				return
			END
		--修改申请人申请时间,并且有必要清空上一次审核人的信息                                                            
        UPDATE Unicom_Orders        
            SET checkState = '待审核', applyer = @usercode, applyerName = @username, Auditingdate = GETDATE(), Audits = NULL, Auditingname = NULL        
            WHERE doccode = @doccode  
	END 
 /*************************************************************************************其他业务受理审核处理***********************************************************/    
 --先取出基本信息,并做业务基本判断                                                                                    
 IF @formid IN (9153, 9158, 9159, 9160,9165, 9167, 9180,9752,9755)                        
 BEGIN
 	--用update初始化数据,并给变量赋值.
     update uo
     set  @doctype = uo.DocType, @sdorgid = uo.sdorgid, @sdorgName = uo.sdorgname,@SDOrgPath=os.PATH,@NetType=uo.NetType,     
 @formtype = 16, @dptType = os.dptType,@ICCID=uo.ICCID,@SeriesCode=LEFT(@ICCID,19),@seriesnumber=uo.SeriesNumber,                    
            @matcode=uo.MatCode,@stcode=uo.Stcode,@SIMSeriesCode=LEFT(@ICCID,19),@checkState=uo.CheckState,
            @docstatus=uo.DocStatus,@Vouchercode=uo.VoucherCode,@Totalmoney_H=isnull(uo.TotalMoney,0),@DocDate=uo.DocDate,
            @SIMSeriesCode=left(iccid,19),@inType=uo.intype,@VIPID=uo.vipid,@AreaID=os.AreaID,uo.TotalScore=0
     FROM   BusinessAcceptance_H uo   WITH(NOLOCK),oSDOrg os
     WHERE  uo.DocCode = @doccode
     AND uo.SdorgID=os.SDOrgID
     if @@ROWCOUNT=0
		BEGIN
			raiserror('单据不存在,无法继续操作,请重新制单.',16,1)
			return
		END
	--取出区域信息
	select @AreaPath=path from gArea ga where ga.areaid=@AreaID
		
   /*SELECT @doctype = doctype                        
     FROM   BusinessAcceptance_H uo    WITH(NOLOCK)                      
     WHERE  uo.DocCode = @doccode */                        
     --检查单据状态                                                                                             
     IF @docstatus<>0 or isnull(@checkState,'未提交审核') not in('退回','拒绝审核','未提交审核')              
     BEGIN                        
         RAISERROR('单据当前状态不允许执行审核请求!',16,1)                         
         RETURN                        
     END                        
     --必须录入会员卡号          
	 if   @dptType<>'加盟店' and isnull(@VIPID,'')='' 
		BEGIN
			raiserror('必须录入会员卡卡号才能继续提交审核,若有疑问请咨询会员系统技术支持[刘俊清]联系电话[13560357780]',16,1)
			return
		END
     IF len(@seriesnumber)<>11                   
     BEGIN                        
         RAISERROR('号码长度不正确,请留意空白字符,并确认号码是否为11位.',16,1)                         
         RETURN                        
     END
     IF ISNULL(@NetType,'')='' SELECT @NetType=dbo.fn_getNetType(@seriesnumber) 
     -----执行积分计算时
		insert into #DocData(Doccode,FormID,stcode,SDOrgID,SDorgPath,AreaID,AreaPath,dpttype,docdate)
		Select @doccode,@formid,@stcode,@sdorgid,@SDOrgPath,@AreaID,@AreaPath,@dptType,@docdate
		 
		BEGIN TRY
			EXEC sp_ExecuteStrategy @formid,@doccode,1,null,@usercode,null
		END TRY
		BEGIN CATCH
			SELECT @tips=dbo.getLastError('策略执行失败.')
			 RAISERROR(@tips,16,1)             
		END CATCH
 END                   
                       
/********************************************************客户资料检查*****************************************************/
  --检查证件                        
 --2011-09-18 增加对银行托收的限制                        
 IF @formid IN (9153, 9159)                        
 BEGIN                     
     --检查客户资料是否完整                                                                   
     IF isnull(@vouchercode,'')=''
     BEGIN                        
         RAISERROR( '客户资料未录入或录入的客户资料不正确,请先录入正确的客户资料再执行此操作!', 16,1)                         
         RETURN                        
     END                         
      
 END                          
/********************************************************需要收费单据对单据金额进行检查*********************************************/
 IF @formid IN (9158, 9160, 9165, 9180,9167)                        
 BEGIN                                         
                
     --检查金额不能为0   修改不等补换卡9158                                                                               
     IF ISNULL(@totalmoney_H,0)<0        
     BEGIN                        
         RAISERROR('实收金额不能小于零！',16,1)                         
         RETURN                        
     END                    
 END
 --充值缴费信用额度控制
 if @formid in(9167) and @dptType='加盟店'
	BEGIN
		exec sp_UpdateCredit @formid,@doccode,@sdorgid,1,'1',@remark,@userCode,@TerminalID
	END
/**********************************************************补换卡对SIM卡进行控制*********************************************************/
IF @formid IN(9158)
	BEGIN
		--取出空白卡串号信息,当需要空白卡,且有ICCID时才取出信息
			IF ISNULL(@ICCID,'')=''
				BEGIN
					RAISERROR('空白卡未录入,请读卡!',16,1)
					return
				END
			
			--取出空白卡信息
			 SELECT @CardMatcode=a.MatCode,@stcode1=a.stcode,@State=a.[state] 
			 From iSeries a WITH(NOLOCK)   
			 WHERE a.SeriesCode=@SIMSeriesCode
			and a.state not in('出库')
			--若不在串号表中,则当成默认的空白卡处理
			IF @@ROWCOUNT=0 
				BEGIN
					--网络类型判断
					IF ISNULL(@NetType,'')=''
						BEGIN
							RAISERROR('未知网段类型,请联系系统管理员!',16,1)
							return
						END
					--根据网段获取SIM卡商品编码
					/*
					IF @NetType IN('3G')
						SELECT @CardMatcode=x.PropertyValue 
							 FROM dbo.fn_sysGetNumberAllocationConfig('128K空白卡商品编码') x
					ELSE
						SELECT @CardMatcode=x.PropertyValue 
							 FROM dbo.fn_sysGetNumberAllocationConfig('64K空白卡商品编码') x
							 */
					--防止无SIM卡商品信息
			        IF ISNULL(@CardMatcode,'')=''
						BEGIN
							RAISERROR('无空白卡商品信息,请联系系统管理员.',16,1)
							return
						END

					--检查空白卡库存
					/*IF NOT EXISTS(SELECT 1 FROM iMatStorage ims WITH(NOLOCK) WHERE ims.MatCode=@CardMatcode AND ims.stCode=@stcode AND ims.unlimitStock>0) AND @dptType NOT IN('加盟店')
						BEGIN
							RAISERROR('SIM卡库存不足,不允许出库,请联系仓管人员!%s',16,1,@cardmatcode)
							return
						END*/
				END
			--若在串号表中存在,则对串号表中的信息进行处理
			ELSE
			BEGIN
				--库存状态检查
				IF @State NOT IN('在库','应收')
					BEGIN
						RAISERROR('SIM卡当前库存状态为[%s],不可销售!',16,1,@state)
						return
					END
				--仓库检查
				IF @stcode<>@stcode1
					BEGIN
						RAISERROR('SIM卡不在本仓库,不可使用!',16,1)
						return
					END
			END
			--取出空白卡商品信息
			SELECT @CardMatName=matname,@mustReadCard=img.mustReadCard
			  FROM iMatGeneral img WITH(NOLOCK) WHERE img.MatCode=@CardMatcode

	-------SIM卡处理
	IF ISNULL(@mustReadCard,0)=1
	BEGIN       
		BEGIN try                  
			EXEC sp_ChangeSIMStatus @ICCID,@SIMSeriesCode,1,@doccode,@formid,16,@seriesnumber,@sdgroup,@sdorgid,'补卡提交审核'                  
			--3.更新完以后再重新检查状态                  
			IF NOT EXISTS(SELECT 1 FROM iSIMInfo is1  WITH(NOLOCK)  WHERE is1.ICCID=@ICCID AND is1.Doccode=@doccode AND is1.SeriesNumber=@seriesnumber)                  
			 BEGIN                  
			  RAISERROR('更新SIM卡信息失败,请重试!',16,1)                  
			 END                          
		END TRY                  
		BEGIN CATCH                  
			SELECT @tips=dbo.crlf()+'SIM卡提交失败!'+dbo.crlf()+ERROR_MESSAGE()+'请联系系统管理员!'                  
			RAISERROR(@tips,16,1)                  
			return                  
		END catch                     
    END
	 SET @sql =		  '                --释放锁定的串号                                                                                   ' + char(10)
					 + '                UPDATE OpenQuery(URP11,''Select isava,Occupyed,OccupyedDoc,isbg From JTURP.dbo.iseries Where OccupyedDoc='''''+@Doccode+''''''' )' + char(10)
					 + '                    SET Occupyed = 0, OccupyedDoc = Null,isava = 0,isbg = 0         ' + char(10)
					 + '                UPDATE OpenQuery(URP11,''Select isava,Occupyed,OccupyedDoc,isbg From JTURP.dbo.iseries Where Seriescode='''''+isnull(@SIMSeriesCode,'')+''''''' )' + char(10)
					 + '                    SET isava = 1,Occupyed = 1,OccupyedDoc = @doccode,isbg=1; ' + char(10)
					 + '                Print Convert(Varchar(50),Getdate(),120) ' + char(10)
					Exec sp_executesql @sql,N'@Seriescode varchar(30),@SIMSeriescode varchar(30),@Doccode varchar(30)',@SeriesCode=@SeriesCode,@SIMSeriesCode=@SIMSeriesCode,@doccode=@doccode
	      
 END                                                                                  
--充值缴费控制
 IF @formid IN (9167)                        
 BEGIN                        
               
     --门店充值，不用提交审核，可直接确认                                                                                
     IF   ISNULL(@dptType,'')<>'加盟店'       AND ISNULL(@intype,'') = '门店充值'                        
                    
     BEGIN                        
         RAISERROR('门店充值，不用请求审核，请直接确认本单！',16,1)                         
         RETURN                        
     END                         
     --加盟店不能选择门店充值                                                                                
     IF  ISNULL(@dptType,'') = '加盟店'       AND ISNULL(@intype,'') = '门店充值'                        
               
     BEGIN                        
         RAISERROR('不能选择门店充值，再选择“公司充值”提交上来，请检查！',     16,1  )                         
         RETURN                        
     END                                              
/*************************************************单据检查结束*********************************************************/                        
                       
 END
 /*****************************************************统一修改单据状态*********************************/
 IF @formid IN (9153, 9158, 9159, 9160,9165, 9167, 9180,9752,9755)
	BEGIN
		UPDATE BusinessAcceptance_H                        
			SET    checkState = '待审核',                        
			applyer = @usercode,                        
			applyerName = @username,                        
			Auditingdate = GETDATE(),                        
			Audits = NULL,                        
			Auditingname = NULL,
			SimCode1 =CASE WHEN formid =9158 THEN  @SIMSeriesCode ELSE simcode1 end,
			MatCode = CASE WHEN formid=9158 THEN @CardMatcode ELSE matcode end,Remark = isnull(remark,'')+isnull(@remark,'')
			WHERE  doccode = @doccode  
		
	END
 /******************************************************宽带业务受理****************************************************/                        
 IF @formid IN (9225)
 BEGIN
	 SELECT @checkState = checkstate
	 FROM   Unicom_BroadbandService_HD ubsh
	 WHERE  ubsh.Doccode = @doccode
     
	 IF ISNULL(@checkState,'未提交审核') <> '未提交审核'
	 BEGIN
		 RAISERROR('当前单据状态不允许提交审核!',16,1) 
		 RETURN
	 END 
	 /*****************************************************单据检查结束*******************************************/                        
	 UPDATE Unicom_BroadbandService_HD
	 SET    ApplyerCode  = @userCode,
			ApplyDate    = GETDATE(),
			checkState   = '待审核'
	 WHERE  Doccode      = @doccode
 END
 /*************************************************************************记录状态*****************************************************************************/                         
                         
 --记录审核操作   alter table CheckNumberAllocationDoc_LOG add UserName varchar(20)                                                                                
 INSERT INTO CheckNumberAllocationDoc_LOG( doccode, formid, seriesnumber,                         
        checkstate, entername, enterdate, remark, UserName, doctype, formtype,                         
        sdorgid, sdorgname,packageID,PackageName,checkType)                        
 VALUES(@doccode,@formid,@seriesnumber,'请求审核',@usercode,GETDATE(),@remark,
 @username,@doctype,@formtype,@sdorgid,@sdorgname,@packageid,@packagename,'开户审核' )                         
 ------------------------------------------------------------不需要执行审核的部门------------------------------------------------                        
 IF dbo.fn_getsdorgconfig(@sdorgid,'autocheck') = 0                    
 BEGIN                    
     --在无需开户审核门店中取出一些特殊的必须要求审核的套包                                                                                  
     IF @formid IN (9146)                    
     BEGIN                    
         SELECT @forceCheckdoc = forceCheckdoc                    
         FROM   policy_h ph                    
         WHERE  ph.DocCode = @packageID                        
                             
         IF ISNULL(@forceCheckdoc,0) = 1                    
         BEGIN                    
             GOTO exitline --如果是强制要求审核的套包 则跳出此段                    
         END                    
     END  
     BEGIN TRY                    
        
      --自动锁定单据                                                                                  
      EXEC sp_LockCheckingDoc @formid,@doccode,'system','管理员',1                     
      --自动通过审核                                                                                   
      EXEC sp_CheckNumberAllocationDoc @formid,@doccode,@seriesnumber,                    
           '通过审核','system','管理员','系统自动通过审核','system','制单正确'                    
                    
     END TRY                        
 BEGIN CATCH                    
                  
  SELECT @tips ='单据自动通过审核失败!'+dbo.crlf()+ISNULL( ERROR_MESSAGE(),'')+dbo.crlf()+'错误发生于'+isnull(error_procedure(),'')    
  RAISERROR(@tips,16,1)                     
  RETURN                    
 END CATCH                      
                         
 END                        
    exitline:                        
 /***************************************************************邮件发送*********************************************/                         
--发送电子邮件                                                       
 DECLARE @subject  VARCHAR(200),                        
         @body     VARCHAR(2000)                        
                         
 SELECT @audits = ''                                                                                            
 SELECT @audits = @audits+';'+usercode                        
 FROM   NumberAllocationAudits                        
                         
 SELECT @subject = @doctype+'单据['+@doccode+']请求审核', @body = '单据['+@doccode                        
       +']请求审核.'+CHAR(10)+                        
        '单号:'+@doccode+CHAR(10)+                        
        '申请人:'+@username+CHAR(10)+                        
        '申请时间:'+CONVERT(VARCHAR(20),GETDATE(),120)+CHAR(10)+                        
        '审核说明:'+@remark+CHAR(10)+                        
        '请尽快处理该单!'                         
        --EXEC sp_sendemail @usercode,@audits,@subject,@body                        
END