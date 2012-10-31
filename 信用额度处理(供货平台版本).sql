/*
过程名称:sp_UpdateCredit
功能:更新信用额度
参数:见声名
返回值:无
编写:三断笛
时间:2012-08-17
功能说明:
备注: 1.对过程对金额相当敏感. 2.要注意对事务和锁的使用.尤其是分布式事务. 3.任何数字字段或变量,都要加上ISNULL. 4.狙击一切可能发生的异常,包括不可能发生的.
begin tran
exec [sp_UpdateCredit] 6090,'DD20120924000020','2.1.769.02.04',0,'2'
rollback
select * from oSDOrgCreditlog osc where osc.Doccode='DD20120924000020' order by osc.Docdate desc
select * from osdorgcredit where sdorgid='2.020.426'
*/
 
ALTER proc [dbo].[sp_UpdateCredit]
	@Formid int,							--功能号
	@Doccode varchar(20),					--单号
	@SDOrgID	varchar(50),				--门店编码
	@ControlBalance bit=1,					--是否控制信用额度,默认为1
	@OptionID varchar(100)='',				--@OptionID为空则表示确认,为默认值.1表示提交审核 2表示作废或退回
	@Remark varchar(500)='',				--备注
	@Usercode varchar(50)='',				--修改人
	@TerminalID varchar(50)=''				--终端编码
as
	BEGIN
		set nocount On
		Set Xact_abort On;
/*************************************************变量定义*****************************************************/

		declare @SDorgName           varchar(200),					--部门名称
		        @Event               varchar(50),					--事件
		        @tips					varchar(500),				--提示信息
		        --修改前的额度信息
		        @OverRunLimit        money,							--可超支额度
		        @Credit              money,							--信用额度
		        @Balance             money,							--信用额度余额(=信用额度-本单应扣额度)
		        @FrozenAmount        money,							--已冻结额度
		        @AvailabBalance      money,							--当前可用额度(=信用额度+可超支额度-已冻结额度-本单冻结额度-本单应扣额度)
		        --修改的额度信息
		        @ChangeCredit        money,							--本单应扣额度
		        @ChangeFrozenAmount  money,							--本单冻结额度
				@ChangeAmount	money,								--应收金额.该字段在提交审核时是冻结金额,在确认时是扣额度金额.
				@Commission	money,									--佣金
				@Rewards	money,									--现金奖励
				@Refcode varchar(50),								--引用单号
				@AccountSdorgid varchar(50),						--信用额度控制门店
				@dptType varchar(50),								--门店类型
				@minType varchar(50),								--部门性质
				@ParentRowID varchar(50),							--部门上级节点
				@SourceDoccode varchar(20),							--源单号.指取消冻结额度时的原冻结额度的单据.
				@FrozenStatus varchar(20),							--信用额度冻结状态,提交审核时"已冻结",确认时"已取消"
				@Doctype varchar(50),								--单据类型
				@FormType int,										--窗体模板类型
				@TranCount int,										--事务数
				@Rowcount int,
				@sql nvarchar(max),
				@osdtype varchar(50)	
		--定义表变量以存储修改前的信用额度信息
		declare @table table(
			Sdorgid varchar(50),
			Account varchar(50),
			OverRunLimit money,
			FrozenAmount money,
			Balance money,
			AvailableBalance money,
			curBalance money,
			curAvailableBalance money
		)
/*************************************************传入参数检查**************************************************/

if @Formid not in(9102,9146,9237,9167,9244,6090,4950,2401,4956,9267,2041,4951,6052) return
/*************************************************初始化数据*****************************************************/
		--若未传入部门信息,则抛出异常
		if ISNULL(@SDOrgID,'')=''
			BEGIN
				raiserror('无部门信息,拒绝更新信息额度,请联系系统管理员',16,1)
				return
			END
		--取出部门信息
		select @dptType=dpttype,@ParentRowID=parentrowid,@SDorgName=SDOrgName,@minType =mintype,@osdtype=osdtype
		from osdorg with(nolock)
		where sdorgid=@SDOrgID
		if @@ROWCOUNT=0
			BEGIN
				raiserror('部门信息不存在,拒绝更新信息额度,请联系系统管理员',16,1)
				return
			END
		--若非加盟店,则直接退出,不再继续.要注意此时的部门编码可能是加盟店,也可能是加盟商,需要兼容这两个级别的部门.
		if isnull(@dptType,'') not in('加盟店') and isnull(@osdtype,'') not in('加盟') return
		
/*************************************************开户业务*****************************************************/
		--开户
		if @Formid in(9102,9146,9237)
			begin
				--取出单据信息,若存储过程外有临时表,则优先从临时表取出数据
				if object_id('tempdb.dbo.Unicom_Orders') is null
					BEGIN
						select @ChangeAmount=isnull(totalmoney2,0),@Commission=isnull(uo.commission,0),@Rewards=isnull(uo.rewards,0)
						from Unicom_Orders uo with(nolock)
						where uo.DocCode=@Doccode
						select @Rowcount=@@ROWCOUNT
					END
				else
					BEGIN
						select @ChangeAmount=isnull(totalmoney2,0),@Commission=isnull(uo.commission,0),@Rewards=isnull(uo.rewards,0)
						from #Unicom_Orders uo with(nolock)
						where uo.DocCode=@Doccode
						select @Rowcount=@@ROWCOUNT
						--如果没有,再努力尝试一次,不要放弃.
						if @Rowcount=0
							BEGIN
								select @ChangeAmount=isnull(totalmoney2,0),@Commission=isnull(uo.commission,0),@Rewards=isnull(uo.rewards,0)
								from Unicom_Orders uo with(nolock)
								where uo.DocCode=@Doccode
								select @Rowcount=@@ROWCOUNT
							END
					END
					--实在没有的话,只能抛出异常了.
					if @ROWCOUNT=0
							BEGIN
								raiserror('单据不存在,无法对信用额度进行更改.',16,1)
								return
							END
				--提交审核,信用额度不变,增加预占额度
				if @OptionID='1'
					BEGIN
						select @ChangeFrozenAmount=@ChangeAmount,@ChangeCredit=0,@Event='开户提交审核冻结额度',@FrozenStatus='待处理'
					end
				--退回审核,取消冻结额度
				else if @OptionID='2'
					BEGIN
						select @ChangeFrozenAmount= - @ChangeAmount,@ChangeCredit=0,@Event='开户取消,取消冻结额度',@FrozenStatus='已处理',@SourceDoccode=@Doccode
					END

				--确认单据,扣信用额度,减少预占额度
				else if @OptionID=''
					BEGIN
						select @ChangeCredit=@ChangeAmount-@Commission,@ChangeFrozenAmount=-@ChangeAmount,@Event='确认单据扣减额度,取消冻结额度.',@SourceDoccode=@Doccode,@FrozenStatus='已处理'
					end
				--若操作类型不存在,则抛出异常,防止非法操作
				else
					BEGIN
						raiserror('更新信用额度操作类型未能识别,执行失败,请联系系统管理员',16,1)
						return
					END
				--取出上级门店,作为信用额度控制
				select @AccountSdorgid=sdorgid ,@SDorgName=sdorgname from oSDOrg os  with(nolock) where os.rowid=@ParentRowID
				--取出额度信息
			end
/*************************************************开户返销业务*****************************************************/
		--返销,提交审核时,不改变任何额度
		if @Formid in(9244)
			begin
				--取出单据信息,若存储过程外有临时表,则优先从临时表取出数据
				if object_id('tempdb.dbo.Unicom_Orders') is null
					BEGIN
						select  @ChangeAmount=isnull(-uo.totalmoney2,0)+isnull(uo.commission,0)+isnull(@Rewards,0),@Commission=isnull(uo.commission,0),
						@Rewards=isnull(uo.rewards,0), @ChangeFrozenAmount=0,@Event='开户返销补回信用额度.'
						from Unicom_Orders uo with(nolock)
						where uo.DocCode=@Doccode
						select @Rowcount=@@ROWCOUNT
					END
				else
					BEGIN
						select  @ChangeAmount=isnull(-uo.totalmoney2,0)+isnull(uo.commission,0)+isnull(@Rewards,0),@Commission=isnull(uo.commission,0),
						@Rewards=isnull(uo.rewards,0), @ChangeFrozenAmount=0,@Event='开户返销补回信用额度.'
						from #Unicom_Orders uo with(nolock)
						where uo.DocCode=@Doccode
						select @Rowcount=@@ROWCOUNT
						if @ROWCOUNT=0
							BEGIN
								select  @ChangeAmount=isnull(-uo.totalmoney2,0)+isnull(uo.commission,0)+isnull(@Rewards,0),@Commission=isnull(uo.commission,0),
								@Rewards=isnull(uo.rewards,0), @ChangeFrozenAmount=0,@Event='开户返销补回信用额度.'
								from Unicom_Orders uo with(nolock)
								where uo.DocCode=@Doccode
								select @Rowcount=@@ROWCOUNT
							END
					END
					if @ROWCOUNT=0
						BEGIN
							raiserror('单据不存在,无法对信用额度进行更改.',16,1)
							return
						END
				select @ChangeCredit=@ChangeAmount,@ChangeFrozenAmount=0
				--取出上级门店,作为信用额度控制
				select @AccountSdorgid=sdorgid  from oSDOrg os with(nolock) where os.rowid=@ParentRowID
			end
/*************************************************充值缴费业务*****************************************************/
		--充值缴费
		if @Formid in(9167,9267)
			begin
				declare @intype varchar(20)
				--取出单据信息,若存储过程外有临时表,则优先从临时表取出数据
				if object_id('tempdb.dbo.Unicom_Orders') is null
					BEGIN
						select @SDOrgID=uo.sdorgid,@SDorgName=uo.sdorgname,@ChangeAmount=isnull(TotalMoney,0),@intype=uo.intype
						from BusinessAcceptance_H  uo with(nolock)
						where uo.DocCode=@Doccode
						select @Rowcount=@@ROWCOUNT
					END
				else
					BEGIN
						select @SDOrgID=uo.sdorgid,@SDorgName=uo.sdorgname,@ChangeAmount=isnull(TotalMoney,0),@intype=uo.intype
						from #BusinessAcceptance_H  uo with(nolock)
						where uo.DocCode=@Doccode
						select @Rowcount=@@ROWCOUNT
						if @Rowcount=0
							BEGIN
								select @SDOrgID=uo.sdorgid,@SDorgName=uo.sdorgname,@ChangeAmount=isnull(TotalMoney,0),@intype=uo.intype
								from BusinessAcceptance_H  uo with(nolock)
								where uo.DocCode=@Doccode
								select @Rowcount=@@ROWCOUNT
							END
					END
				if @ROWCOUNT=0
					BEGIN
						raiserror('单据不存在,无法对信用额度进行更改.',16,1)
						return
					END
				--提交审核,信用额度不变,增加预占额度
				if @OptionID='1'
					BEGIN
						select @ChangeFrozenAmount=  @ChangeAmount,@ChangeCredit=0,@Event='充值提交审核冻结额度.',@FrozenStatus='待处理'
					end
				--退回审核,信用额度不变,取消预占额度
				else if @OptionID='2'
					BEGIN
						select @ChangeCredit=0,@ChangeFrozenAmount=  -@ChangeAmount,@ChangeCredit=0,@Event='充值失败,取消冻结额度.',@FrozenStatus='已处理',@SourceDoccode=@Doccode
					end
				--确认单据,扣信用额度,减少预占额度
				else if @OptionID=''
					BEGIN
						select @ChangeCredit=@ChangeAmount,@ChangeFrozenAmount=-@ChangeAmount,@Event='充值成功扣减信用额度,取消冻结额度.',@SourceDoccode=@Doccode,@FrozenStatus='已处理' 
					end
				--若操作类型不存在,则抛出异常,防止非法操作
				else
					BEGIN
						raiserror('更新信用额度操作类型未能识别,执行失败,请联系系统管理员',16,1)
						return
					END
				--取出上级门店,作为信用额度控制
				select @AccountSdorgid=sdorgid ,@SDorgName=sdorgname from oSDOrg os with(nolock) where os.rowid=@ParentRowID
			end
/*************************************************总部订货申请单*****************************************************/
		--总部订货申请单,增加冻结额度
		if @Formid in(6090)
			BEGIN
				if @OptionID in('','2')
					begin
						select @ChangeAmount=isnull(SumNetMoney,0)
						from ord_shopbestgoodsdoc with(nolock)
						where DocCode=@Doccode
						select @rowcount=@@rowcount
					end
				--分货时取差额.
				if @OptionID in('3')
					begin
						select @ChangeAmount=isnull(SumNetMoney,0)-isnull(userdigit4,0)
						from ord_shopbestgoodsdoc with(nolock)
						where DocCode=@Doccode
						select @rowcount=@@rowcount
					end
				if @ROWCOUNT=0
					BEGIN
						raiserror('单据不存在,无法对信用额度进行更改.',16,1)
						return
					END
				--作废订单,取消额度冻结
				if @OptionID='2'
					BEGIN
						select @ChangeFrozenAmount=-@ChangeAmount,@Event='订货作废,取消冻结额度.',@SourceDoccode=@Doccode,@FrozenStatus='已处理'
					end
				--分货取额度
				else if @OptionID='3'
					BEGIN
						select @ChangeFrozenAmount=-@ChangeAmount,@Event='分货处理额度.',@FrozenStatus='待处理'
					END
				--确认订单,冻结额度
				else if @OptionID=''
					BEGIN
						select @ChangeFrozenAmount=@ChangeAmount,@Event='订货冻结额度.',@FrozenStatus='待处理'
					end
				--若操作类型不存在,则抛出异常,防止非法操作
				else
					BEGIN
						raiserror('更新信用额度操作类型未能识别,执行失败,请联系系统管理员',16,1)
						return
					END
				--取出上级门店,作为信用额度控制
				select @AccountSdorgid=sdorgid ,@SDorgName=sdorgname from oSDOrg os with(nolock) where os.rowid=@ParentRowID
			END
		--发货指令单中止发货
		if @Formid in(6052)
			BEGIN
				--供货平台此处取分货金额.
				select @ChangeAmount=isnull(b.userdigit4,0),@Refcode=b.DocCode
				from imatdoc_h a with(nolock) 
				inner join ord_shopbestgoodsdoc b with(nolock) on a.UserTxt1=b.DocCode 
				where a.FormID=6052 
				and a.DocCode=@doccode
				and b.FormID=6090
				and b.phflag='已处理'
				if @@ROWCOUNT=0
					BEGIN
						raiserror('该指令单没有待处理的订货单,无法对信用额度进行操作',16,1)
						return
					END
				if @OptionID='2'
					BEGIN
						select @ChangeFrozenAmount=-@ChangeAmount,@Event='中止发货取消订货冻结额度.',@SourceDoccode=@doccode,@FrozenStatus='已处理'
					END
				else
					BEGIN
						raiserror('更新信用额度操作类型未能识别,执行失败,请联系系统管理员',16,1)
						return
					END
				--取出上级门店,作为信用额度控制
				select @AccountSdorgid=sdorgid ,@SDorgName=sdorgname from oSDOrg os with(nolock) where os.rowid=@ParentRowID
			END
 /*************************************************送货单*****************************************************/
		--送货单,减少信用额度,减少预占额度(有订货单时)
		if @Formid in(4950)
			BEGIN
				--取出单据信息,若存储过程外有临时表,则优先从临时表取出数据
				if object_id('tempdb.dbo.sPickorderHD') is null
					BEGIN
						select @SDOrgID = os.sdorgid,@ChangeAmount = isnull(cavermoney,0),@ChangeCredit = isnull(cavermoney,0),
						@Refcode = UserTxt1,@ChangeFrozenAmount = 0,@Event = '发货扣减信用额度.'
						from   sPickorderHD sph with(nolock)
							   inner join oStorage os with(nolock)on  sph.instcode = os.stCode
						where  DocCode = @Doccode
						select @Rowcount=@@ROWCOUNT
					END
				else
					BEGIN
						select @SDOrgID = os.sdorgid,@ChangeAmount = isnull(cavermoney,0),@ChangeCredit = isnull(cavermoney,0),
						@Refcode = UserTxt1,@ChangeFrozenAmount = 0,@Event = '发货扣减信用额度.'
						from   #sPickorderHD sph with(nolock)
							   inner join oStorage os with(nolock)on  sph.instcode = os.stCode
						where  DocCode = @Doccode
						select @Rowcount=@@ROWCOUNT
						if @Rowcount=0
							BEGIN
								select @SDOrgID = os.sdorgid,@ChangeAmount = isnull(cavermoney,0),@ChangeCredit = isnull(cavermoney,0),
								@Refcode = UserTxt1,@ChangeFrozenAmount = 0,@Event = '发货扣减信用额度.'
								from   sPickorderHD sph with(nolock)
									   inner join oStorage os with(nolock)on  sph.instcode = os.stCode
								where  DocCode = @Doccode
								select @Rowcount=@@ROWCOUNT
							END
					END
				if @ROWCOUNT=0
					BEGIN
						raiserror('单据不存在,无法对信用额度进行更改.',16,1)
						return
					END
				--取出上级门店,作为信用额度控制
				select @AccountSdorgid=sdorgid ,@SDorgName=sdorgname from oSDOrg os with(nolock) where os.rowid=@ParentRowID
				--若是根据订货单发的货,则需要减少冻结额度,减少的冻结额度为订货额度,而非发货时的额度.
				if isnull(@Refcode,'')!=''
					begin
						--供货平台此处取分货金额.
						select @ChangeFrozenAmount=-isnull(b.userdigit4,0),@Event=@Event+'取消订货冻结额度.',@SourceDoccode=b.doccode,@FrozenStatus='已处理'
						from imatdoc_h a with(nolock) 
						inner join ord_shopbestgoodsdoc b with(nolock) on a.UserTxt1=b.DocCode 
						where a.FormID=6052 
						and a.DocCode=@Refcode
						and b.FormID=6090
						and b.phflag='已处理'
					END
			end
/*************************************************退货单*****************************************************/
		--退货单,增加信用额度
		if @Formid in(4951)
			BEGIN
				select @SDOrgID =os.sdorgid,@ChangeAmount = isnull(-cavermoney, 0),@AccountSdorgid=sph.cltCode2,
				       @ChangeCredit = isnull(-cavermoney,0),@ChangeFrozenAmount = 0,@Event = '退货单退回信用额度.'
				from   sPickorderHD sph with(nolock)
				       inner join oStorage os with(nolock)on  sph.instcode = os.stCode
				where  DocCode = @Doccode
				if @@ROWCOUNT=0
					BEGIN
						raiserror('单据不存在,无法对信用额度进行更改.',16,1)
					END
 
			    --取出上级门店,作为信用额度控制
				--select @AccountSdorgid=sdorgid ,@SDorgName=sdorgname from oSDOrg os with(nolock) where os.rowid=@ParentRowID
			end
/*************************************************返现单*****************************************************/
		--返现单,增加冻结额度,信用额度不变
		if @Formid in(4956)
			begin
				
				select  @ChangeAmount=isnull(amount,0),@ChangeCredit=0,@AccountSdorgid=@Sdorgid
				from farcashindoc with(nolock)
				where DocCode=@Doccode
				if @@ROWCOUNT=0
					BEGIN
						raiserror('单据不存在,无法对信用额度进行更改.',16,1)
						return
					END
				if isnull(@OptionID,'')=''
					BEGIN
						select @ChangeFrozenAmount=isnull(@ChangeAmount,0),@Event='信用额度返现冻结额度.',@FrozenStatus='待处理'
					end
				--返现单作废
				else if @OptionID='2'
					BEGIN
						select @ChangeFrozenAmount=isnull(-@ChangeAmount,0),@Event='信用额度作废,取消冻结额度.',@FrozenStatus='已处理',@SourceDoccode=@Doccode
					end
				--若操作类型不存在,则抛出异常,防止非法操作
				else
					BEGIN
						raiserror('未知操作类型,执行失败!',16,1)
						return
					END
			end
 /*************************************************往来收款单*****************************************************/
		--往来收款单
		if @Formid in(2041)
			BEGIN
				select  @ChangeAmount=isnull(amount,0),@ChangeCredit=-isnull(amount,0),@refcode=refcode,@Event='调整额度.',@AccountSdorgid=cltcode
				from farcashindoc with(nolock)
				where DocCode=@Doccode
				if @@ROWCOUNT=0
					BEGIN
						raiserror('单据不存在,无法对信用额度进行更改.',16,1)
						return
					END
				--判断是否是返现单,若是返现单还需要减少返现单的申请额度
				if isnull(@Refcode,'')!=''
					begin
						--取返现申请单的金额作为取消冻结额度的金额.不可以直接使用调整单的金额作为取消冻结的金额.
						select @ChangeFrozenAmount=-isnull(amount,0),@Event='信用额度返现成功,取消冻结额度.',@SourceDoccode=@Refcode,@FrozenStatus='已处理'
							from farcashindoc with(nolock)
						where DocCode=@refcode
						and @Formid in(4956)
					end
			end
/******************************************************统一检查信用额度******************************************************/
		--若信用额度部门信息为空,则抛出异常
		if ISNULL(@AccountSdorgid,'')=''
			BEGIN
				raiserror('无信用额度部门信息,拒绝更新信息额度,请联系系统管理员',16,1)
				return
			END
		---------------------------------------------------------------取出信用额度信息---------------------------------------------------------
		--分布式查询采用动态SQL方式
		If @Formid In(9102,9146,9237,6090,9167,9244,9267)
			Begin
				SET @sql = 'select @AvailabBalance=ISNULL(AvailableBalance,0),@OverRunLimit=ISNULL(OverrunLimit,0),@FrozenAmount= ISNULL(FrozenAmount,0), ' + char(10)
				 + '				@Balance=isnull(Balance,0) ' + char(10)
				 + '				from OpenQuery(URP11,''Select AvailableBalance,OverrunLimit,FrozenAmount,Balance From JTURP.dbo.oSDOrgCredit  ' + char(10)
				 + '				where SDorgID='''''+@AccountSdorgid +'''''' + char(10)
				 + '				and Account=''''113107'''''')'
				--Print @sql
				Exec sp_executesql @sql,N'@AvailabBalance money output,@OverRunLimit money output,@FrozenAmount money output,@Balance money output',
				@AvailabBalance=@AvailabBalance Output,@OverRunLimit=@OverRunLimit Output,@FrozenAmount=@FrozenAmount Output,@Balance=@Balance output
				select @Rowcount=@@ROWCOUNT
			End
		Else
			--非分布式操作本地直接完成即可.
			BEGIN
				select @AvailabBalance=ISNULL(osc.AvailableBalance,0),@OverRunLimit=ISNULL(osc.OverrunLimit,0),@FrozenAmount= ISNULL(osc.FrozenAmount,0),
				@Balance=isnull(Balance,0)
				from oSDOrgCredit   osc
				where osc.SDorgID=@AccountSdorgid
				and osc.Account='113107'
				select @Rowcount=@@ROWCOUNT
			END
		if @ROWCOUNT=0 and @Formid not in (2041)
			BEGIN
				raiserror('不存在此部门的信用额度信息,请初始化额度后再操作!',16,1)
				return
			END
	---------------------------------------------------------------检查信用额度------------------------------------------------------------------
		--当提交审核或确认时,对信用额度进行检查
		if isnull(@OptionID,'') in('','1') and @ControlBalance=1
			Begin
				 
				if isnull(@AvailabBalance,0)+isnull(@Commission,0)+isnull(@Rewards,0)-isnull(@ChangeCredit,0)-isnull(@ChangeFrozenAmount,0)<0
					BEGIN
						SELECT @tips = 
						            '您的信用额度不足，请及时充值并确认已经通过审核的单据！' + dbo.crlf() +
						            '您当前余额:' + convert(varchar(50),isnull(@Balance,0)) + dbo.crlf() +
						            '可超支额度:'+convert(varchar(50),isnull(@OverRunLimit,0)) + dbo.crlf() +
						            '本单应扣额度:' + convert(varchar(50),isnull(@ChangeCredit,0)) + dbo.crlf() +
						            '冻结额度:' + convert(varchar(50),isnull(@FrozenAmount,0))
						 RAISERROR(@tips,16,1) 
						 RETURN
					END
			END
/******************************************************统一更新信用额度信息******************************************************/
			--保证在分布式环境中事务可用.
			set xact_abort on
			--记录当前事务量.若此前已经有事务则不再启动事务,交由外部事务处理.若外部无事务,则启动一个事务.
			select @TranCount=@@TRANCOUNT	
			if @TranCount=0	begin tran
			begin try
				--更新信用额度
				--分布式更新需要采用动态SQL方式更新
				If @Formid In(9102,9146,9237,6090,9167,9244,9267)
					BEGIN
						SET @sql = '			update Openquery(URP11,''SELECT FrozenAmount,Balance,ModifyDate,ModifyUser,terminalID,ModifyDoccode From JTURP.dbo.oSDOrgCredit a Where SDOrgID='''''+@AccountSdorgid+''''' AND Account=''''113107'''''')' + char(10)
						 + '				set    FrozenAmount  = isnull(FrozenAmount,0) + isnull(@ChangeFrozenAmount,0), ' + char(10)
						 + '					   Balance       = isnull(Balance,0) -isnull(@ChangeCredit,0), ' + char(10)
						 + '					   ModifyDate = getdate(), ' + char(10)
						 + '					   ModifyUser = @Usercode, ' + char(10)
						 + '					   terminalID=@TerminalID, ' + char(10)
						 + '					   ModifyDoccode = @Doccode'
 
						Exec sp_executesql @sql,N'@ChangeFrozenAmount money,@ChangeCredit money, @Usercode varchar(50),@TerminalID varchar(50),@Doccode varchar(50),@AccountSdorgid varchar(50)',
						@ChangeFrozenAmount=@ChangeFrozenAmount,@ChangeCredit=@ChangeCredit,@Usercode=@Usercode,@TerminalID=@TerminalID,@Doccode=@Doccode,@AccountSdorgid=@AccountSdorgid
					End
				Else
				--本地更新则直接update
					BEGIN
						update a
						set    FrozenAmount  = isnull(FrozenAmount,0) + isnull(@ChangeFrozenAmount,0),
							   Balance       = isnull(a.Balance,0) -isnull(@ChangeCredit,0),
							   ModifyDate = getdate(),
							   ModifyUser = @Usercode,
							   terminalID=@TerminalID,
							   ModifyDoccode = @Doccode
							  /* output inserted.sdorgid,
							   inserted.account,
							   deleted.overrunlimit,
							   deleted.frozenamount,
							   deleted.balance,
							   deleted.AvailableBalance,
							   inserted.balance,
							   inserted.availableBalance into @table*/
						from   oSDOrgCredit a ---->注意此处不要加上with(nolock)
						where  a.SDOrgID = @AccountSdorgid
							   and a.Account = '113107'
					END
				
			/*update Openquery(URP11,'SELECT FrozenAmount,Balance,ModifyDate,ModifyUser,terminalID,ModifyDoccode From oSDOrgCredit a Where SDOrgID=''' +@AccountSdorgid+''' ADN Account=''113107'''
				set    FrozenAmount  = isnull(FrozenAmount,0) + isnull(@ChangeFrozenAmount,0),
					   Balance       = isnull(a.Balance,0) -isnull(@ChangeCredit,0),
					   ModifyDate = getdate(),
					   ModifyUser = @Usercode,
					   terminalID=@TerminalID,
					   ModifyDoccode = @Doccode*/
			

				--若不存在,则要报错
				if @@ROWCOUNT=0
					BEGIN
						--若是信用额度初始化,则插入一条记录.
						if @Formid in(2041)
							BEGIN
								INSERT into oSDOrgCredit( SDOrgID, Account, OverrunLimit, FrozenAmount, Balance, 
								       CreateDate, CreateUser, TerminalID, 
								       CreateDoccode)
								SELECT @AccountSdorgid,'11307',isnull(@OverRunLimit, 0),
								       isnull(@ChangeFrozenAmount,0),isnull(@ChangeCredit,0),getdate(),@Usercode,@TerminalID,@Doccode
							END
						--其余情况均报错
						else
							BEGIN
								--当外部无事务时,则上面代码有启动事务,需要回滚前面的事务.
								if @trancount=0 and @@TRANCOUNT>0 rollback
								raiserror('不存在此部门的信用额度信息,请初始化额度后再操作!',16,1)
							END
						
					END
				--插入更新记录
				
				/*
				insert into oSdorgCreditLog( Doccode, FormID, FormType, Docdate, DocType, 
					   Account, [Event], SDorgID, SDorgName, OverRunLimit, 
					   CreditAmount, FrozenAmount, ChangeFrozenAmount, ChangeCredit, 
					   Commission, Rewards, Balance, AvailabBalance, Usercode, 
					   Remark, TerminalID, FrozenStatus, refCode)
				select @Doccode,@Formid,@FormType,getdate(),@Doctype,'113107',@Event,@SDOrgID,@SDorgName,a.OverRunLimit,a.Balance,a.FrozenAmount,
					   @ChangeFrozenAmount,@ChangeCredit,@Commission,@Rewards,a.curBalance,
					   a.curAvailableBalance,@Usercode,@Remark,@TerminalID,@FrozenStatus,
					   @Refcode
				from   @table a
				*/
				If @Formid In(9102,9146,9237,6090,9167,9244,9267)
					BEGIN
						Insert into Openquery(URP11,'Select   Doccode, FormID, FormType, Docdate, DocType, 
						   Account, [Event], SDorgID, SDorgName, OverRunLimit, 
						   CreditAmount, FrozenAmount, ChangeFrozenAmount, ChangeCredit, 
						   Commission, Rewards, Balance, AvailabBalance, Usercode, 
						   Remark, TerminalID, FrozenStatus, refCode,AccountSdorgid from JTURP.dbo.oSdorgCreditLog')
						select @Doccode,@Formid,@FormType,getdate(),@Doctype,'113107',@Event,@SDOrgID,@SDorgName,@OverRunLimit,@Balance,@FrozenAmount,
							   @ChangeFrozenAmount,@ChangeCredit,@Commission,@Rewards,isnull(@Balance,0) -isnull(@ChangeCredit,0),
							   isnull(@AvailabBalance,0)-isnull(@ChangeFrozenAmount,0)-isnull(@ChangeCredit,0),@Usercode,@Remark,@TerminalID,@FrozenStatus,
							   @Refcode,@AccountSdorgid
					End
				Else
					BEGIN
						insert into oSdorgCreditLog( Doccode, FormID, FormType, Docdate, DocType, 
						   Account, [Event], SDorgID, SDorgName, OverRunLimit, 
						   CreditAmount, FrozenAmount, ChangeFrozenAmount, ChangeCredit, 
						   Commission, Rewards, Balance, AvailabBalance, Usercode, 
						   Remark, TerminalID, FrozenStatus, refCode,AccountSdorgid)
						select @Doccode,@Formid,@FormType,getdate(),@Doctype,'113107',@Event,@SDOrgID,@SDorgName,@OverRunLimit,@Balance,@FrozenAmount,
							   @ChangeFrozenAmount,@ChangeCredit,@Commission,@Rewards,isnull(@Balance,0) -isnull(@ChangeCredit,0),
							   isnull(@AvailabBalance,0)-isnull(@ChangeFrozenAmount,0)-isnull(@ChangeCredit,0),@Usercode,@Remark,@TerminalID,@FrozenStatus,
							   @Refcode,@AccountSdorgid
					END
				--当有原始单号,且冻结状态处理完毕时,更新原冻结额度状态
				if isnull(@SourceDoccode,'') != ''
				   and @FrozenStatus = '已处理'
				Begin
					If  @Formid In(9102,9146,9237,6090,9167,9244,9267)
						BEGIN
							/*Update Openquery(URP11,'Select frozenstatus,Refcode From oSdorgCreditLog  where  Doccode  ='''+ @SourceDoccode+'''and frozenStatus  = ''待处理''')
							set    frozenstatus      = @FrozenStatus,
								   Refcode           = @SourceDoccode
							*/
							SET @sql = 'Update Openquery(URP11,''Select frozenstatus,Refcode From JTURP.dbo.oSdorgCreditLog  where  Doccode  ='''''+ @SourceDoccode+'''''and frozenStatus  = ''''待处理'''''') ' + char(10)
									 + '							set    frozenstatus      = @FrozenStatus, ' + char(10)
									 + '								   Refcode           = @SourceDoccode'
							Print @sql
							Exec sp_executesql @sql,N'@SourceDoccode varchar(30),@FrozenStatus varchar(20)',
							@SourceDoccode=@SourceDoccode,@FrozenStatus=@FrozenStatus
						End
					Else
						BEGIN
							update oSdorgCreditLog
							set    frozenstatus      = @FrozenStatus,
								   Refcode           = @SourceDoccode
							where  Doccode           = @SourceDoccode
								   and frozenStatus  = '待处理'
						END
					
				end
				--当外部无事务时,则前面的代码启动了事物,需要提交之.
				if @TranCount =0 commit
			end try
			begin catch
				if @TranCount=0 and @@TRANCOUNT>0 rollback
				select @tips='更新信用额度失败!'+dbo.crlf()+'异常信息:' +isnull(error_message(),'')+dbo.crlf()+'请联系系统管理员.'
				raiserror(@tips,16,1)
				return
			end catch	
	end
/*
USE [URPDB]
GO

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_oSDOrgCredit_OverrunLimit]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[oSDOrgCredit] DROP CONSTRAINT [DF_oSDOrgCredit_OverrunLimit]
END

GO

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_oSDOrgCredit_FrozenAmount]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[oSDOrgCredit] DROP CONSTRAINT [DF_oSDOrgCredit_FrozenAmount]
END

GO

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_oSDOrgCredit_Balance]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[oSDOrgCredit] DROP CONSTRAINT [DF_oSDOrgCredit_Balance]
END

GO

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_oSDOrgCredit_CreateDate]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[oSDOrgCredit] DROP CONSTRAINT [DF_oSDOrgCredit_CreateDate]
END

GO

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_oSDOrgCredit_ModifyDate]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[oSDOrgCredit] DROP CONSTRAINT [DF_oSDOrgCredit_ModifyDate]
END

GO

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_oSDOrgCredit_APPName]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[oSDOrgCredit] DROP CONSTRAINT [DF_oSDOrgCredit_APPName]
END

GO

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_oSDOrgCredit_sUserName]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[oSDOrgCredit] DROP CONSTRAINT [DF_oSDOrgCredit_sUserName]
END

GO

USE [URPDB]
GO

 
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[oSDOrgCredit]') AND type in (N'U'))
DROP TABLE [dbo].[oSDOrgCredit]
GO

USE [URPDB]
GO

 
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[oSDOrgCredit](
	[SDOrgID] [varchar](30) NOT NULL,
	[Account] [varchar](10) NOT NULL,
	[OverrunLimit] [money] NULL,
	[FrozenAmount] [money] NULL,
	[Balance] [money] NULL,
	[AvailableBalance]  AS ((isnull([OverrunLimit],(0))+isnull([Balance],(0)))-isnull([FrozenAmount],(0))),
	[CreateDoccode] [varchar](50) NULL,
	[CreateDate] [datetime] NULL,
	[CreateUser] [varchar](50) NULL,
	[ModifyDoccode] [varchar](50) NULL,
	[ModifyDate] [datetime] NULL,
	[ModifyUser] [varchar](50) NULL,
	[APPName] [varchar](500) NULL,
	[sUserName] [varchar](50) NULL,
	[TerminalID] [varchar](50) NULL,
 CONSTRAINT [PK_oSDOrgCredit] PRIMARY KEY CLUSTERED 
(
	[SDOrgID] ASC,
	[Account] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[oSDOrgCredit] ADD  CONSTRAINT [DF_oSDOrgCredit_OverrunLimit]  DEFAULT ((0)) FOR [OverrunLimit]
GO

ALTER TABLE [dbo].[oSDOrgCredit] ADD  CONSTRAINT [DF_oSDOrgCredit_FrozenAmount]  DEFAULT ((0)) FOR [FrozenAmount]
GO

ALTER TABLE [dbo].[oSDOrgCredit] ADD  CONSTRAINT [DF_oSDOrgCredit_Balance]  DEFAULT ((0)) FOR [Balance]
GO

ALTER TABLE [dbo].[oSDOrgCredit] ADD  CONSTRAINT [DF_oSDOrgCredit_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
GO

ALTER TABLE [dbo].[oSDOrgCredit] ADD  CONSTRAINT [DF_oSDOrgCredit_ModifyDate]  DEFAULT (getdate()) FOR [ModifyDate]
GO

ALTER TABLE [dbo].[oSDOrgCredit] ADD  CONSTRAINT [DF_oSDOrgCredit_APPName]  DEFAULT (app_name()) FOR [APPName]
GO

ALTER TABLE [dbo].[oSDOrgCredit] ADD  CONSTRAINT [DF_oSDOrgCredit_sUserName]  DEFAULT (suser_name()) FOR [sUserName]
GO





USE [URPDB]
GO

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_oSdorgCreditLog_OverRunLimit]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[oSdorgCreditLog] DROP CONSTRAINT [DF_oSdorgCreditLog_OverRunLimit]
END

GO

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_oSdorgCreditLog_CreditAmount]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[oSdorgCreditLog] DROP CONSTRAINT [DF_oSdorgCreditLog_CreditAmount]
END

GO

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_Table_1_FrozenLimit]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[oSdorgCreditLog] DROP CONSTRAINT [DF_Table_1_FrozenLimit]
END

GO

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_oSdorgCreditLog_ChangeFrozenAmount]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[oSdorgCreditLog] DROP CONSTRAINT [DF_oSdorgCreditLog_ChangeFrozenAmount]
END

GO

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_oSdorgCreditLog_ChangeAmount]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[oSdorgCreditLog] DROP CONSTRAINT [DF_oSdorgCreditLog_ChangeAmount]
END

GO

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_oSdorgCreditLog_Commission]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[oSdorgCreditLog] DROP CONSTRAINT [DF_oSdorgCreditLog_Commission]
END

GO

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_oSdorgCreditLog_Rewards]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[oSdorgCreditLog] DROP CONSTRAINT [DF_oSdorgCreditLog_Rewards]
END

GO

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_oSdorgCreditLog_Balance]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[oSdorgCreditLog] DROP CONSTRAINT [DF_oSdorgCreditLog_Balance]
END

GO

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_oSdorgCreditLog_AvailabBalance]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[oSdorgCreditLog] DROP CONSTRAINT [DF_oSdorgCreditLog_AvailabBalance]
END

GO

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_oSdorgCreditLog_APPName]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[oSdorgCreditLog] DROP CONSTRAINT [DF_oSdorgCreditLog_APPName]
END

GO

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_oSdorgCreditLog_sUserName]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[oSdorgCreditLog] DROP CONSTRAINT [DF_oSdorgCreditLog_sUserName]
END

GO

USE [URPDB]
GO 
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[oSdorgCreditLog]') AND type in (N'U'))
DROP TABLE [dbo].[oSdorgCreditLog]
GO

USE [URPDB]
GO

 
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[oSdorgCreditLog](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Doccode] [varchar](50) NULL,
	[FormID] [int] NULL,
	[FormType] [int] NULL,
	[Docdate] [datetime] NULL,
	[DocType] [varchar](50) NULL,
	[Account] [varchar](50) NULL,
	[Event] [varchar](50) NULL,
	[SDorgID] [varchar](50) NULL,
	[SDorgName] [varchar](50) NULL,
	[OverRunLimit] [money] NULL,
	[CreditAmount] [money] NULL,
	[FrozenAmount] [money] NULL,
	[ChangeFrozenAmount] [money] NULL,
	[ChangeCredit] [money] NULL,
	[Commission] [money] NULL,
	[Rewards] [money] NULL,
	[Balance] [money] NULL,
	[AvailabBalance] [money] NULL,
	[Usercode] [varchar](50) NULL,
	[Remark] [varchar](500) NULL,
	[TerminalID] [varchar](50) NULL,
	[APPName] [varchar](500) NULL,
	[sUserName] [varchar](50) NULL,
	[Frozenstatus] [varchar](50) NULL,
	[refCode] [varchar](50) NULL,
 CONSTRAINT [PK_oSdorgCreditLog] PRIMARY KEY NONCLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[oSdorgCreditLog] ADD  CONSTRAINT [DF_oSdorgCreditLog_OverRunLimit]  DEFAULT ((0)) FOR [OverRunLimit]
GO

ALTER TABLE [dbo].[oSdorgCreditLog] ADD  CONSTRAINT [DF_oSdorgCreditLog_CreditAmount]  DEFAULT ((0)) FOR [CreditAmount]
GO

ALTER TABLE [dbo].[oSdorgCreditLog] ADD  CONSTRAINT [DF_Table_1_FrozenLimit]  DEFAULT ((0)) FOR [FrozenAmount]
GO

ALTER TABLE [dbo].[oSdorgCreditLog] ADD  CONSTRAINT [DF_oSdorgCreditLog_ChangeFrozenAmount]  DEFAULT ((0)) FOR [ChangeFrozenAmount]
GO

ALTER TABLE [dbo].[oSdorgCreditLog] ADD  CONSTRAINT [DF_oSdorgCreditLog_ChangeAmount]  DEFAULT ((0)) FOR [ChangeCredit]
GO

ALTER TABLE [dbo].[oSdorgCreditLog] ADD  CONSTRAINT [DF_oSdorgCreditLog_Commission]  DEFAULT ((0)) FOR [Commission]
GO

ALTER TABLE [dbo].[oSdorgCreditLog] ADD  CONSTRAINT [DF_oSdorgCreditLog_Rewards]  DEFAULT ((0)) FOR [Rewards]
GO

ALTER TABLE [dbo].[oSdorgCreditLog] ADD  CONSTRAINT [DF_oSdorgCreditLog_Balance]  DEFAULT ((0)) FOR [Balance]
GO

ALTER TABLE [dbo].[oSdorgCreditLog] ADD  CONSTRAINT [DF_oSdorgCreditLog_AvailabBalance]  DEFAULT ((0)) FOR [AvailabBalance]
GO

ALTER TABLE [dbo].[oSdorgCreditLog] ADD  CONSTRAINT [DF_oSdorgCreditLog_APPName]  DEFAULT (app_name()) FOR [APPName]
GO

ALTER TABLE [dbo].[oSdorgCreditLog] ADD  CONSTRAINT [DF_oSdorgCreditLog_sUserName]  DEFAULT (suser_name()) FOR [sUserName]
GO




*/