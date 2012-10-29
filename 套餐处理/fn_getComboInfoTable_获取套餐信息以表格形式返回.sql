/*  
* 函数名称:[fn_getComboInfoTable]  
*功能:以表格形式返回套餐最低预存款信息
* 编写:三断笛  
* 时间:2012-10-26
* 备注:无  
SELECT dbo.fn_getComboInfo_test('1.4.769.01.01','18617249002','B计划96元3G套餐','TBD2011052800001','0')  
SELECT dbo.fn_getComboInfo('1.4.769.01.01','18617249002','B计划96元3G套餐','TBD2011052800001','0')  
SELECT * From dbo.[fn_getComboInfoTable]('1.1.769.01.03','18617249002','13','TBD2011051700003')  
select price, * from seriespool where seriesnumber='18617249002'
select * from osdorg where sdorgid='1.1.769.01.03'
*/  

create Function [dbo].[fn_getComboInfoTable]
(
	@sdorgid Varchar(30), 
	@SeriesNumber varchar(20),
	@Combocode Varchar(50), 
	@PackageID Varchar(20)
)
Returns @table table(
	sdorgid varchar(50),
	combocode varchar(50),
	packageID varchar(50),
	minPrice money,
	Deposits money,
	DepositsMatcode varchar(50),
	DepositsMatName varchar(200)
	)
As
  
Begin
	--DECLARE @sdorgid VARCHAR(20),@comboName VARCHAR(50)
	--set @sdorgid='1.4.769.10.01'
	--SET @comboName='126元3GiPhone套餐'  
	Declare @minprice Money, @Areaid Varchar(20), @areaID1 Varchar(2000),
	@Deposits money,@bitControlPrice bit,@DepositsMatcode varchar(50),@DepositsMatName varchar(200)
	declare @SeriesNumberPrice money,					--号码中预存款
	@AreaComboMinPrice money,							--区域套餐设置预存款
	@PackageComboMinPrice money,						--套包绑定套餐中最低预存款
	@bitPackageCombo bit										--套包绑定套餐是否有设置
	--取出当前所在区域  
	Select @areaid = areaid
	From   osdorg With(Nolock)
	Where  sdorgid = @sdorgid --先从门店判断区域  

	--取套包的预存款  
	Select @minprice = minprice, @areaid1 = areaid
	From   policy_h ph
	Where  ph.DocCode = @PackageID
	
	select @bitPackageCombo=0
	Select @Deposits=isnull(x.Deposits,0),@PackageComboMinPrice=isnull(x.minprice,0),
	@DepositsMatcode=x.DepositsMatcode,@DepositsMatName=x.DepositsMatName
	From   dbo.fn_getDepositsInfo(@PackageID,@AreaID,@combocode) x
	if @@ROWCOUNT>0 	select @bitPackageCombo=1
	If @minprice Is Not Null
		begin
			insert into @table(sdorgid,combocode,packageID,minPrice,Deposits,DepositsMatcode,DepositsMatName)
			select @sdorgid,@Combocode,@PackageID,isnull(@minprice,0),isnull(@Deposits,0),@DepositsMatcode,@DepositsMatName
			Return 
		END
		  --取出号码的预存款信息
	select @bitControlPrice=isnull(sp.ControlPrice,0),@SeriesNumberPrice=isnull(sp.Price,0)
	  from SeriesPool sp with(nolock) where sp.SeriesNumber=@seriesNumber
	  if @bitPackageCombo=1
		BEGIN
		  --若号码有标志最低预存款,则取号码预存款与套包绑定套餐中预存款的高者
			if isnull(@bitControlPrice,0)=1
				BEGIN
					insert into @table(sdorgid,combocode,packageID,minPrice,Deposits,DepositsMatcode,DepositsMatName)
					select @sdorgid,@Combocode,@PackageID,
					case when isnull(@SeriesNumberPrice,0)>=isnull(@PackageComboMinPrice,0) then isnull(@SeriesNumberPrice,0) else isnull(@PackageComboMinPrice,0) end,
					isnull(@Deposits,0),@DepositsMatcode,@DepositsMatName
					Return
				END
			else
				-------------------------若号码未设置预存款,则直接返回套包绑定套餐的预存款-------------
				BEGIN
					insert into @table(sdorgid,combocode,packageID,minPrice,Deposits,DepositsMatcode,DepositsMatName)
					select @sdorgid,@Combocode,@PackageID,
					isnull(@PackageComboMinPrice,0),isnull(@Deposits,0),@DepositsMatcode,@DepositsMatName
					Return
				END
		END
	-----------------------------------------若套包绑定套餐未设置预存款,则从号码和区域套餐设置中最高值----------------------------------------
	else
	BEGIN
			--从区域套餐设置中取出最低预存款
			;With cte_Sdorg As(Select a.sdorgid, a.rowid, a.parentrowid, 0  As Level
	                  From   oSDOrg    a
	                  Where  a.SDOrgID = @sdorgid 
					 Union All   
					 Select a.sdorgid, a.rowid, a.parentrowid, c.level + 1
					 From   oSDOrg a, cte_Sdorg c
					 Where  a.rowid = c.parentrowid	)
					Select Top 1 @AreaComboMinPrice=isnull(  a.minprice,0)
								  From   Combo_cfg a, cte_sdorg     b
								  Where  a.SDOrgID = b.sdorgid
										 And a.MinPrice Is Not Null
										 And a.ComboCode=@ComboCode
								  Order By b.Level Desc
					insert into @table(sdorgid,combocode,packageID,minPrice,Deposits,DepositsMatcode,DepositsMatName)
					select @sdorgid,@Combocode,@PackageID,
					case when isnull(@SeriesNumberPrice,0)>=isnull(@AreaComboMinPrice,0) then isnull(@SeriesNumberPrice,0) else isnull(@AreaComboMinPrice,0) end,isnull(@Deposits,0),
					@DepositsMatcode,@DepositsMatName
					Return
	END
	return
End  
  
  