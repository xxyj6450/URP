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
*/  

ALTER Function [dbo].[fn_getComboInfo]
(
	@sdorgid Varchar(30), @seriesNumber Varchar(20), @comboName Varchar(50), @PackageID Varchar(20),@OptionID Varchar(100)
)
Returns Money
As
  
Begin
	--DECLARE @sdorgid VARCHAR(20),@comboName VARCHAR(50)
	--set @sdorgid='1.4.769.10.01'
	--SET @comboName='126元3GiPhone套餐'  
	Declare @minprice Money, @Areaid Varchar(20), @areaID1 Varchar(2000),@Deposits money
	
	--取出当前所在区域  
	Select @areaid = areaid
	From   osdorg With(Nolock)
	Where  sdorgid = @sdorgid --先从门店判断区域  
	If Isnull(@areaid, '') = ''
	Begin
	    --再从号码池判断区域  
	    Select @areaid = areaid
	    From   seriespool With(Nolock)
	    Where  seriesnumber = @seriesnumber
	    
	    If Isnull(@areaid, '') = ''
	    Begin
	        --再从号码归属表判断区域  
	        Select @areaid = areaid
	        From   mcaller With(Nolock)
	        Where  numberseg = Left(@seriesnumber, 7)
	    End
	End 
	--取套包的预存款  
	Select @minprice = minprice, @areaid1 = areaid
	From   policy_h ph
	Where  ph.DocCode = @PackageID
	
	Select @areaid1 = Isnull(@areaid1, ''), @areaid = Isnull(@areaid, '')
	
	If @minprice Is Not Null 
		BEGIN
			If isnull(@OptionID,'') In('','0')
				Begin
					Select @Deposits=x.Deposits
					From   dbo.fn_getPackageCombo(@PackageID, @seriesNumber, @sdorgid) x
					Where  x.comboName = @comboName 
					Return isnull(@minprice,0)+Isnull(@Deposits,0)
				END
			Else If isnull(@OptionID,'') In('1')
				BEGIN
					Return isnull(@minprice,0)
				End
			Else If isnull(@OptionID,'') In('2')
				BEGIN
					Select @Deposits=x.Deposits
					From   dbo.fn_getPackageCombo(@PackageID, @seriesNumber, @sdorgid) x
					Where  x.comboName = @comboName 
					Return Isnull(@Deposits,0)
				End
			Return 0
		END
	--如果套包预存款不为空,则往下判断  
	    ;
	
	With cte_Sdorg As(Select a.sdorgid, a.rowid, a.parentrowid, 0  As Level
	                  From   oSDOrg                                   a
	                  Where  a.SDOrgID = @sdorgid 
	 Union All   
	 Select a.sdorgid, a.rowid, a.parentrowid, c.level + 1
	 From   oSDOrg a, cte_Sdorg c
	 Where  a.rowid = c.parentrowid
	)
	,cte_combo As(Select Top 1                      minprice
	              From   Combo_cfg a, cte_sdorg     b
	              Where  a.SDOrgID = b.sdorgid
	                     And a.MinPrice Is Not Null
	                     And a.ComboName = @comboName
	              Order By Level Desc
	) 
	,cte_minprice(minprice,Deposits) As(--取号码设定的预存款  
	 Select Isnull(price, 0),0
	 From   SeriesPool sp
	 Where  sp.SeriesNumber = @seriesnumber 
	 Union All 
	 --取区域套餐设置中的预存款  
	 Select Isnull(minprice, 0),0
	 From   cte_combo 
	 Union All 
	 --取套包绑定套餐中的预存款  
	 /*SELECT ISNULL(minprice,0) FROM PackageSeriesLog_H a,PackageSeriesLog_D b   
	 WHERE a.Doccode=b.Doccode AND a.RefCode=@PackageID AND a.Formid=9108  
	 AND comboName=@comboName  
	 AND ( --套包政策中有区域设置,且仅为一个区域,则不对套包_套餐绑定单进行区域过滤  
	 (ISNULL(@AreaID1,'')<>'' and CHARINDEX(',',@AreaID1,1)=0)   
	 OR ( --如果套包政策中未设置区域,或设置了多个区域,则需要从套包_套餐绑定单中进行区域过滤  
	 (ISNULL(@AreaID1,'')='' OR CHARINDEX(',',@AreaID1,1)>0)  
	 --如果套包_套餐中未设置区域,或未能取得号码所在区域,则不进行过滤   
	 and (isnull(b.AreaID,'')='' OR ISNULL(@AreaID,'')=''   
	 --或者号码所在区域在套包_套餐所设置的区域中  
	 OR exists(select 1 FROM dbo.[Split](b.AreaID,',') s where @areaid like s.list+'%')  
	 )  select packageid,* from Unicom_Orders where doccode='PS20120101004509'
	 )  SELECT ISNULL(price,0),* FROM dbo.fn_getPackageCombo('TBD2011053000002','18664559237') x   WHERE x.comboName='B计划66元3G套餐' 
	 )*/ 
	 --改从fn_getPackageCombo取套餐,保证与套餐设置的统一,更加准确  
	 Select Isnull(price, 0),Isnull(x.Deposits,0)
	 From   dbo.fn_getPackageCombo(@PackageID, @seriesNumber, @sdorgid) x
	 Where  x.comboName = @comboName 
	 Union All 
	 --取套餐设置中的预存款  
	 Select Isnull(minprice, 0),0
	 From   Combo_H ch
	 Where  ch.ComboName = @comboName
	)  
	Select @minprice = Max(minprice)
	From   cte_minprice 
	If isnull(@OptionID,'') In('','0')
		Begin
			Select @Deposits=x.Deposits
			From   dbo.fn_getPackageCombo(@PackageID, @seriesNumber, @sdorgid) x
			Where  x.comboName = @comboName 
			Return isnull(@minprice,0)+Isnull(@Deposits,0)
		END
	Else If isnull(@OptionID,'') In('1')
		BEGIN
			Return isnull(@minprice,0)
		End
	Else If isnull(@OptionID,'') In('2')
		BEGIN
			Select @Deposits=x.Deposits
			From   dbo.fn_getPackageCombo(@PackageID, @seriesNumber, @sdorgid) x
			Where  x.comboName = @comboName 
			Return Isnull(@Deposits,0)
		End
	 
		Return 0
End  
  
  