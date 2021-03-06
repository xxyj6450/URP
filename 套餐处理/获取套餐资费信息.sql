/*  
* 函数名称:fn_getComboInfo  
* 编写:三断笛  
* 时间:2011-04-30  
* 备注:无  
* select packageid, * from unicom_orders where doccode='PS20110430000832'  
* 示例:SELECT dbo.fn_getComboInfo('1.4.769.10.01','PS20110430000832','B计划96元3G套餐','TBD2010121600001','0')  
*-------------------------  
*更新：增加对区域的处理。因套包政策中绑定的套餐已经支持分区域，故取套餐信息也要支持分区域。区域信息经三层提取，保证数据的准确与完整  
编写：三断笛  
时间 ：2011-10-30  
*更新:取套包套餐绑定中的套餐设置时,改用fn_getPackageCombo直接取,这样最准确.  
*编写:三断笛  
*时间:2011-11-16  
SELECT dbo.fn_getComboInfo_test('1.1.769.01.03','18664065841','B计划96元3G套餐','TBD2011052800001','0')  
SELECT dbo.fn_getComboInfo('1.1.769.01.03','18664065841','B计划96元3G套餐','TBD2011052800001','2')  
select areaid,* from osdorg where sdorgname like '%时尚%'
('TBD2011052800001','18664065841','1.1.769.01.03')
*/  

alter Function [dbo].[fn_getComboInfo]
(
	@sdorgid Varchar(30), 
	@seriesNumber Varchar(20), 
	@comboName Varchar(50), 
	@PackageID Varchar(20),
	@OptionID Varchar(100)									--选项 0:取得总预存款 最低预存款+代收联通款 1:取得最低预存款 2:取得代收联通款
)
Returns money
As
  
Begin
	--DECLARE @sdorgid VARCHAR(20),@comboName VARCHAR(50)
	--set @sdorgid='1.4.769.10.01'
	--SET @comboName='126元3GiPhone套餐'  
	Declare @minprice Money, @Areaid Varchar(20),
	@Deposits money,@bitControlPrice bit,@ComboCode varchar(50)
	declare @SeriesNumberPrice money,					--号码中预存款
	@AreaComboMinPrice money,							--区域套餐设置预存款
	@PackageComboMinPrice money,						--套包绑定套餐中最低预存款
	@bitPackageCombo bit										--套包绑定套餐是否有设置
	--取出当前所在区域  
	Select @areaid = areaid
	From   osdorg With(Nolock)
	Where  sdorgid = @sdorgid --先从门店判断区域
	--若门店不存在,返回-1
	if @@ROWCOUNT=0 return -1
	--取出套餐信息
	select @combocode= combocode from combo_h with(nolock) where ComboName=@comboName
	--若套餐不存在,返回-2
	if @@ROWCOUNT=0 return -2	
	--取套包的预存款  
	Select @minprice = minprice
	From   policy_h ph with(nolock)
	Where  ph.DocCode = @PackageID

	If isnull(@OptionID,'') In('','0','2')
		Begin
			select @bitPackageCombo=0
			Select @Deposits=isnull(x.Deposits,0),@PackageComboMinPrice=isnull(x.minprice,0)
			From   dbo.fn_getDepositsInfo(@PackageID,@AreaID,@combocode) x
			if @@ROWCOUNT>0 	select @bitPackageCombo=1
		END
	If @minprice Is Not Null 
		begin
			If isnull(@OptionID,'') In('0')
				BEGIN
					return isnull(@minprice,0)+Isnull(@Deposits,0)
				END
			else if  isnull(@OptionID,'') In('1')
				BEGIN
					return isnull(@minprice,0)
				END
			else if  isnull(@OptionID,'') In('2')
				BEGIN
					return Isnull(@Deposits,0)
				END
			Return 0
		END
		  --取出号码的预存款信息
	select @bitControlPrice=isnull(sp.ControlPrice,0),@SeriesNumberPrice=isnull(sp.Price,0)
	  from SeriesPool sp with(nolock) where sp.SeriesNumber=@seriesNumber
	  if @bitPackageCombo=1
		BEGIN
		  --若号码有标志最低预存款,则取号码预存款与套包绑定套餐中预存款的高者
			if isnull(@bitControlPrice,0)=1
				BEGIN
					if @OptionID in('0')
						BEGIN
							return isnull(@Deposits,0)+case when isnull(@SeriesNumberPrice,0)>=isnull(@PackageComboMinPrice,0) then isnull(@SeriesNumberPrice,0) else isnull(@PackageComboMinPrice,0) end
						END
					if @OptionID in('1')
						BEGIN
							return case when isnull(@SeriesNumberPrice,0)>=isnull(@PackageComboMinPrice,0) then isnull(@SeriesNumberPrice,0) else isnull(@PackageComboMinPrice,0) end
						END
					if @OptionID in('2')
						BEGIN
							return isnull(@Deposits,0)
						END
				END
			else
				-------------------------若号码未设置预存款,则直接返回套包绑定套餐的预存款-------------
				BEGIN
					if @OptionID in('0')
						BEGIN
							return  isnull(@PackageComboMinPrice,0)+isnull(@Deposits,0)
						END
					if @OptionID in('1')
						BEGIN
							return isnull(@PackageComboMinPrice,0)
						END
					if @OptionID in('2')
						BEGIN
							return isnull(@Deposits,0)
						END
				END
		END
	-----------------------------------------若套包绑定套餐未设置预存款,则从号码和区域套餐设置中最高值----------------------------------------
	else
	BEGIN
			--从区域套餐设置中取出最低预存款
			;With cte_Sdorg As(Select a.sdorgid, a.rowid, a.parentrowid, 0  As Level
	                  From   oSDOrg    a with(nolock)
	                  Where  a.SDOrgID = @sdorgid 
					 Union All   
					 Select a.sdorgid, a.rowid, a.parentrowid, c.level + 1
					 From   oSDOrg a with(nolock), cte_Sdorg c
					 Where  a.rowid = c.parentrowid	)
					Select Top 1 @AreaComboMinPrice=isnull(  a.minprice,0)
								  From   Combo_cfg a, cte_sdorg     b
								  Where  a.SDOrgID = b.sdorgid
										 And a.MinPrice Is Not Null
										 And a.ComboCode=@ComboCode
								  Order By b.Level Desc
				BEGIN
					if @OptionID in('0')
						BEGIN
							return  isnull(@Deposits,0)+case when isnull(@SeriesNumberPrice,0)>=isnull(@AreaComboMinPrice,0) then isnull(@SeriesNumberPrice,0) else isnull(@AreaComboMinPrice,0) end
						END
					if @OptionID in('1')
						BEGIN
							return case when isnull(@SeriesNumberPrice,0)>=isnull(@AreaComboMinPrice,0) then isnull(@SeriesNumberPrice,0) else isnull(@AreaComboMinPrice,0) end
						END
					if @OptionID in('2')
						BEGIN
							return isnull(@Deposits,0)
						END
				END
		END
		return 0
End  
  
  