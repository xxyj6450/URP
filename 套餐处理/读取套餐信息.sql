/*

* 函数名称:fn_getPackageCombo

* 功能:根据套包,门店获取相应的套餐信息

* 参数:@packageid 套包id    ----根据套包得到套包所属的区域
       @sdorgid 门店id      ----根据门店得到门店所属的区域
       @seriesnumber 号码   ----根据号码得到最低套餐消费,网别,号码绑定的套餐
* 编写:曹赛军
* 时间:2011-7-20

* 函数逻辑:

  if 号码存在(池内号码)
     if 有套包(非单开户)
        if 号码已售
			 取号码销售时绑定的套餐
        else 未售
             if 号码绑定了套餐(预开户)
			     取号码绑定的套餐
             else
                 if 套包绑定了套餐
                 then 取套包绑定的套餐
                 else 
                     根据 1.套包区域  2.部门区域 3.号码区域  4.外加网别,号码最低套餐消费得到套餐 
                 endif
     else 无套包(单开户)
		  根据 1.部门区域 2.号码区域 3.外加网别,号码最低套餐消费得到套餐
     endif
  else 号码不存在(池外号码)
     if 有套包
         根据 1.套包区域  2.部门区域 3.号码区域  4.外加网别,号码最低套餐消费得到套餐
     else 无套包
         根据 1.部门区域 2.号码区域 3.外加网别,号码最低套餐消费得到套餐
     endif
  endif
     
 * 根据 1.套包区域  2.部门区域 3.号码区域  4.外加网别,号码最低套餐消费得到套餐规则
                    
  1.如果此套包只属于一个区域,则不需要再进一步判断套餐中的区域设置,因为只有一个区域
  2.如果套包设置中未设置区域,或设置了多个区域,则需要进一步按套餐中的区域过滤套餐
  3.套餐中的区域设置规则
	A.不设置任何区域,则该套餐对所有区域可见
	B.设置一个区域,则该套餐仅对此区域及其子区域可见
	C.设置多个区域,用逗号分隔,则对这些区域及其子区域可见
  

 备注
    1.池外号码无已销售未销售记录,无绑定套餐
    
    
 * 函数调用示例
   select * from fn_getPackageCombo('TBD2011052800001','18664065841','1.1.769.01.03')
 
---------------------------------------------------------------------------------------------
修改:
1.对数据表的读取增加with(nolock)选项,防止锁
2.增加对套餐相关的存费送费信息的读取
修改人:三断笛
时间:2012-09-04
-------------------------------------------------------------------------------------------------
修改:
1.对套餐读取逻辑进行大量简化.
2.区域只从部门编码中读取.不再理会套包中区域与号码区,及号码归属地.
3.不再因号码在不在号码池而进行分别处理.选择套餐与号码是否在号码池无关.
4.更准确处理套餐区域匹配.
5.不再处理联通代收代付.由专用的函数来处理.
修改版 :三断笛
时间:2012-10-26
示例:select * from [fn_getPackageCombo]('TBD2012052700001','15606554222','2.1.576.09.21')
*/
 
alter function [dbo].[fn_getPackageCombo](
	@packageid varchar(20),
	@seriesnumber varchar(50),
    @sdorgid varchar(50)
)
returns @table table(
	 combocode varchar(20),					--套餐编码
	 comboname varchar(100),					--套餐名
	 combotype varchar(50),						--套餐类别
	 price money,										--套餐价格
	 areaid varchar(200),							--区域
	 comboplan varchar(50),						--套餐计划
	 DepositsMatcode varchar(50),			--存费送费商品编码
	 DepositsMatName Varchar(200),		--存费送费商品名称
	 Deposits Money								--存费送费金额

)
as
begin
        declare @packageareaids varchar(500);			--套包设置中的区域,可能有多个,以逗号分开
        declare @sdorgareaid  varchar(500);				--门店所属的区域,只有一个
        declare @filterareaids varchar(500);					--最终按此区域过滤套餐

        declare @combofee money;							--号码最低套餐费
        declare @nettype varchar(50);							--号码网别
        declare @combocode  varchar(50)					--号码预开户预绑定的套餐
        declare @salecombocode varchar(50);			--号码销售时绑定的套餐
        declare @state varchar(50);								--号码销售状态         
        declare @preallocation bit;								--号码是否预开户
        declare @seriesnumberareaid  varchar(50);		--号码区域
        declare @seriesnumbercnt int							--号码是否存在
        declare @ActiveState varchar(50)						--号码激活状态

        --获取门店区域
        select @sdorgareaid=areaid from osdorg With(Nolock) where sdorgid=@sdorgid;  
        --获取号码信息
        Select @combofee = mincombofee, @nettype = nettype, @combocode = combocode, @salecombocode = salecombocode, @state = 
               [state], @preallocation = preallocation, @seriesnumberareaid     = areaid
        From   seriespool With(Nolock)
        Where  seriesnumber = @seriesnumber;
        set @seriesnumbercnt=@@rowcount;
        if @seriesnumbercnt<>0  --号码存在(池内号码)  
        begin         
			  if  @ActiveState<>'未激活' --号码状态不正确,不显示套餐
				  begin
					 return
				  end
			  else --正常的号码才显示套餐
				  begin
					 if isnull(@combocode,'')<>'' and @preallocation=1 --预开户,取预绑定的套餐
						 begin
				 			--从套餐表取出套餐
							insert into @table (combocode,comboname,combotype,price,areaid,comboplan)
							select ch.combocode,ch.comboname,ch.combotype,ch.price,ch.comboareaid,ch.comboplan 
							from  combo_h ch
							where ch.ComboCode=@combocode
							
							order by ch.ComboPlan,ch.Price;
							--取得预开户套餐,直接返回.
							if @@ROWCOUNT>0 return
						 end
				  end
		end
		--如果套包绑定了符合条件的套餐,则取绑定的符合条件的套餐
	   insert into @table (combocode,comboname,combotype,price,areaid,comboplan,DepositsMatcode,DepositsMatName,Deposits)
	   select ch.combocode,ch.comboname,ch.combotype,ch.price,ch.comboareaid,ch.comboplan,d.DepositsMatcode,d.DepositsMatName,d.Deposits 
	   from  packageserieslog_h h  With(Nolock) 
			join packageserieslog_d d  With(Nolock) on h.doccode=d.doccode and h.refcode=@packageid and h.formid=9108
				and (isnull(d.areaid,'')='' or isnull(@sdorgareaid,'')='' 
						or exists(select * from commondb.dbo.split(coalesce( d.areaid,@sdorgareaid,''),',') s,garea x where x.areaid=@sdorgareaid and  x.path like '%/'+ list+'/%')
				)
			 join combo_h ch on d.combocode=ch.combocode
	   where ch.Price >=isnull(@combofee,0)						--需要过滤套餐资费
			 order by ch.ComboPlan,ch.Price;
		if @@ROWCOUNT=0
			begin
				--筛选套餐,加入号码网别,最低套餐消费
				insert into @table (combocode,comboname,combotype,price,areaid,comboplan)
				select ch.combocode,ch.comboname,ch.combotype,ch.price,ch.comboareaid,ch.comboplan 
				from  combo_h ch 
				--需要在套餐中判断区域
				where (isnull(ch.ComboAreaID,'')='' or @sdorgareaid='' or exists(select 1 from gArea ga 
																					outer apply commondb.dbo.SPLIT(coalesce(ch.ComboAreaID,@sdorgareaid,''),',')  c 
																					where ga.areaid=@sdorgareaid 
																					and ga.PATH like '%/'+c.List+'/%' )
				)
					  and ch.actived=1   --激活的套餐
					  and ch.validdate>=getdate() --处于有效期
					  and ch.price>=isnull(@combofee,0) --套餐价格大于或等于号码最低套餐消费
					  order by ch.ComboPlan,ch.Price
			end
		return
end