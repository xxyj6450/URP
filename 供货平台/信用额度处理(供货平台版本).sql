/*
过程名称:sp_UpdateCredit
功能:更新信用额度
参数:见声名
返回值:无
编写:三断笛
时间:2012-08-17
功能说明:
备注: 1.对过程对金额相当敏感. 2.要注意对事务和锁的使用.尤其是分布式事务. 3.任何数字字段或变量,都要加上ISNULL. 4.狙击一切可能发生的异常,包括不可能发生的.
--------------------------------------------------------------------------
更新时间:2012-12-24
修改人:三断笛
更新内容:
修改信用额度处理逻辑.以流程的形式处理额度,主要是用于解决额度处理复杂流程的问题.
本次升级主要解决订货供货流程中冻结额度的记录问题.
发起流程时可能冻结额度.此时冻结状态为待处理.
在后续的流程处理过程中,会不断减少冻结额度(后续流程不应增加冻结额度,冻结额度的增加只能有流程发起人员操作,而不应由流程处理人员操作.).
在流程结束前,这些步骤所减少的冻结额度都呈待处理状态,以供查询流程的冻结额度.当流程彻底结束时,将所有后续流程标志成已处理.取消额度日志中所有冻结额度.
而这些后续的流程可能是某个节点后发散形成多个并发的流程,各个分支流程并不知道自己是否是整个流程的终点,也就是说不知道整个流程何时彻底结束,即何时取消所有冻结额度.
鉴于以上问题,做以下设计:
1.增加额度流程表,记录流程编码(单号),冻结额度与已解冻额度标志.任何业务可以使用此流程表进行更复杂的控制.
2.新增流程时,持启动流程标志(@StartFlow)将流程标志,冻结额度,写入额度流程表.
3.对信用额度的处理与处理状态无关.即不管流程是否存在,流程是否结束,对额度的处理都不改变.以下流程仅影响额度明细日志.
4.若流程存在,
	4.1一个流程节点,若不会中止流程,且会改变冻结额度,则持"待处理"标志,流程ID标志,源单据标志.
		4.1.1 若流程冻结额度<=已处理额度+本次冻结额度,则抛出异常
		4.1.2 若流程冻结额度>=已处理额度+本次冻结额度,将在流程上增加一笔解冻额度,并同时增加一行待处理的冻结额度.
	4.2一个流程节点,若可能将中止流程,则持"已处理"标志,流程ID标志,源单据标志.
		4.2.1 若此时流程冻结额度<=已处理额度+本次冻结额度,则在流程上增加一笔冻结额度,并同时增加一行待处理冻结额度.
	4.3 若此时流程冻结额度>=已处理额度+本次冻结额度,则自动将整个流程的所有节点标志"已处理"
5.若流程不存在
	5.1 若持"已处理"标志,则直接终止整个流程,所有流程节点标志"已处理".
	5.2 若持"待处理"标志,则增加一行额度明细,状态为"待处理"

代码逻辑将尽量简化上述流程的分支,用顺序流方式表述,并尽量重用代码.流程如下:
1.取出信用额度,流程信息及单据信息.
2.根据业务设置是否启动流程,是否结束流程.
3.控制信用额度.
4.若流程存在,且流程冻结额度<=已处理额度+本次冻结额度,则抛出异常,并退出.
5.修改信用额度.
6.若持"启动流程"标志,则插入一条新流程.
7.增加额度日志.
8.若流程存在,在流程记录中增加一笔处理额度.
9.若持"已处理"标志
	9.1 若流程存在,且此时流程冻结额度>=已处理额度+本次冻结额度,则自动将整个流程的所有节点标志"已处理"
	9.2 若流程不存在,则将源单据流程改成"已处理"

begin tran
exec [sp_UpdateCredit] 6093,'GFH2013030402006','2.1.576.01.91',1,'1','分货单订货金额错误导致未补冻结分货差额，最终无法分货。管理员调整之。2013-03-06 三断笛','SYSTEM',''
rollback
commit
begin tran
exec [sp_UpdateCredit] 9237,'JDC2012113000000','2.1.769.09.29',1,'1'

 
BEGIN tran
	EXEC  sp_UpdateCredit 6052,'DTZ2012121700006','2.1.769.02.23',0,'2','发货中止,取消额度冻结.'
	
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
		        @Event               varchar(50),								--事件
		        @tips					varchar(5000),							--提示信息
		        --修改前的额度信息
		        @OverRunLimit        money,								--可超支额度
		        @Credit              money,									--信用额度
		        @Balance             money,									--信用额度余额(=信用额度-本单应扣额度)
		        @FrozenAmount        money,								--已冻结额度
		        @AvailabBalance      money,								--当前可用额度(=信用额度+可超支额度-已冻结额度-本单冻结额度-本单应扣额度)
		        --修改的额度信息
		        @ChangeCredit        money,								--本单应扣额度
		        @ChangeFrozenAmount  money,							--本单冻结额度
				@ChangeAmount	money,									--应收金额.该字段在提交审核时是冻结金额,在确认时是扣额度金额.
				@Commission	money,										--佣金
				@DeductAmount money,									--现金奖抵扣金额
				@Rewards	money,												--现金奖励
				@Refcode varchar(50),										--引用单号
				@AccountSdorgid varchar(50),							--信用额度控制门店
				@dptType varchar(50),										--门店类型
				@minType varchar(50),										--部门性质
				@ParentRowID varchar(50),									--部门上级节点
				@SourceDoccode varchar(20),							--源单号.指取消冻结额度时的原冻结额度的单据.
				@FrozenStatus varchar(20),									--信用额度冻结状态,提交审核时"已冻结",确认时"已取消"
				@Doctype varchar(50),										--单据类型
				@FormType int,													--窗体模板类型
				@TranCount int,													--事务数
				@Rowcount int,
				@sql nvarchar(max),
				@osdtype varchar(50),
				@StartFlow bit,													--启动流程
				@FlowStatus VARCHAR(50),									--流程状态
				@FlowExists BIT,												--流程是否存在
				@FlowUnFrozenAmount money,							--本浏览已经解冻金额
				@FlowInstanceID varchar(50),								--流程实例ID.用于记录一整个业务流程的标志,如订货流程,可以以订货单号为流程编号.
				@FlowFrozenAmount money								--本流程已经冻结的金额
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

if @Formid not in(9102,9146,9237,9167,9244,6090,4950,2401,4956,9267,2041,4951,6052,6093) return
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
		SELECT @Rowcount=0
/*************************************************开户业务*****************************************************/
		--开户
		if @Formid in(9102,9146,9237)
			begin
				--取出单据信息,若存储过程外有临时表,则优先从临时表取出数据
				if object_id('tempdb.dbo.Unicom_Orders') IS not null
					BEGIN
						select @ChangeAmount=isnull(totalmoney2,0),@Commission=isnull(uo.commission,0),@Rewards=isnull(uo.rewards,0),@DeductAmount=isnull(uo.deductamount,0)
						from #Unicom_Orders uo with(nolock)
						where uo.DocCode=@Doccode
						select @Rowcount=@@ROWCOUNT
					END
					--如果没有,再努力尝试一次,不要放弃.
					if isnull(@Rowcount,0)=0
						BEGIN
							select @ChangeAmount=isnull(totalmoney2,0),@Commission=isnull(uo.commission,0),@Rewards=isnull(uo.rewards,0),@DeductAmount=isnull(uo.DeductAmout,0)
							from Unicom_Orders uo with(nolock)
							where uo.DocCode=@Doccode
							select @Rowcount=@@ROWCOUNT
						END
					--实在没有的话,只能抛出异常了.
					if isnull(@ROWCOUNT,0) =0
							BEGIN
								raiserror('单据不存在,无法对信用额度进行更改.',16,1)
								return
							END
				--提交审核,信用额度不变,增加预占额度
				if @OptionID='1'
					BEGIN
						select @ChangeFrozenAmount=@ChangeAmount,@ChangeCredit=0,@Event='开户提交审核冻结额度',
						@FrozenStatus='待处理'
					end
				--退回审核,取消冻结额度
				else if @OptionID='2'
					BEGIN
						select @ChangeFrozenAmount= - @ChangeAmount,@ChangeCredit=0,@Event='开户取消,取消冻结额度',
						@FrozenStatus='已处理',@SourceDoccode=@Doccode
					END
				--确认单据,扣信用额度,减少预占额度
				else if @OptionID=''
					BEGIN
						select @ChangeCredit=@ChangeAmount-@Commission-isnull(@DeductAmount,0),@ChangeFrozenAmount=-@ChangeAmount,
						@Event='确认单据扣减额度,取消冻结额度.',@SourceDoccode=@Doccode,@FrozenStatus='已处理'
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
						select @ChangeCredit=0,@ChangeFrozenAmount=  -@ChangeAmount,@ChangeCredit=0,@Event='充值失败,取消冻结额度.',
						@FrozenStatus='已处理',@SourceDoccode=@Doccode
					end
				--确认单据,扣信用额度,减少预占额度
				else if @OptionID=''
					BEGIN
						select @ChangeCredit=@ChangeAmount,@ChangeFrozenAmount=-@ChangeAmount,
						@Event='充值成功扣减信用额度,取消冻结额度.',@SourceDoccode=@Doccode,@FrozenStatus='已处理' 
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
				--订单作废
				select @ChangeAmount=isnull(SumNetMoney,0),@FlowInstanceID=@Doccode
				from ord_shopbestgoodsdoc with(nolock)
				where DocCode=@Doccode
				if @@ROWCOUNT=0
					BEGIN
						raiserror('单据不存在,无法对信用额度进行更改.',16,1)
						return
					END
				--作废订单,取消额度冻结
				if @OptionID='2'
					BEGIN
						select @ChangeFrozenAmount=-@ChangeAmount,@Event='订货作废,取消冻结额度.',
						@SourceDoccode=@Doccode,@FrozenStatus='已处理',@FlowInstanceID=@Doccode
					end

				--确认订单,冻结额度
				else if @OptionID=''
					BEGIN
						select @ChangeFrozenAmount=@ChangeAmount,@Event='订货冻结额度.',@FrozenStatus='待处理',@FlowInstanceID=@Doccode,@StartFlow=1
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
		--订货分货单,分货时需要将冻结额度的差额返还
		if @Formid in(6093)
			BEGIN
				--ALTER TABLE ord_shopbestgoodsdoc ADD  REFDOC VARCHAR(50)
				--分货时取差额.
				select @ChangeAmount=isnull(SumNetMoney,0)-isnull(userdigit,0),@FlowInstanceID=ISNULL(RefDoc,'')
				from ord_shopbestgoodsdoc with(nolock)
				where DocCode=@Doccode
				select @rowcount=@@rowcount
				IF @rowcount=0
					BEGIN
						raiserror('单据不存在,无法对信用额度进行更改.',16,1)
						return
					end
				--分货取额度
				 if @OptionID IN('','1')
					BEGIN
						select @ChangeFrozenAmount=-@ChangeAmount,@Event='分货处理额度.',@FrozenStatus='已处理'
					END
				--若操作类型不存在,则抛出异常,防止非法操作
				else
				BEGIN
					select @tips='更新信用额度操作类型未能识别,执行失败,请联系系统管理员'+convert(varchar(20),@optionid)
					raiserror(@tips,16,1)
					return
				END
				--取出上级门店,作为信用额度控制
				select @AccountSdorgid=sdorgid ,@SDorgName=sdorgname from oSDOrg os with(nolock) where os.rowid=@ParentRowID
			END
		--发货指令单中止发货
		if @Formid in(6052)
			BEGIN
				--供货平台此处取分货金额.
				select @Refcode=a.UserTxt1,@FlowInstanceID=ISNULL(a.UserTxt1,'')
				from imatdoc_h a with(nolock) 
				where a.FormID=6052
				and a.DocCode=@doccode
				if @@ROWCOUNT=0
					BEGIN
						raiserror('指令单不存在,不允许操作.',16,1)
						return
					END
				--取出本单更改金额
				select @ChangeAmount=sum(isnull(totalmoney,0))
				from imatdoc_d with(nolock)
				where DocCode=@Doccode
				if @OptionID='2'
					BEGIN
						if left(@FlowInstanceID,2)='DD'
							BEGIN
								select @ChangeFrozenAmount=-@ChangeAmount,@Event='中止发货取消订货冻结额度.',
								@SourceDoccode=@doccode,@FrozenStatus='已处理'
							END
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
				if object_id('tempdb.dbo.sPickorderHD') IS not null
					BEGIN
						select @SDOrgID = os.sdorgid,@ChangeAmount = isnull(cavermoney,0),@ChangeCredit = isnull(cavermoney,0),
						@Refcode = UserTxt1,@ChangeFrozenAmount = 0,@Event = '发货扣减信用额度.'
						from   #sPickorderHD sph with(nolock)
							   inner join oStorage os with(nolock)on  sph.instcode = os.stCode
						where  DocCode = @Doccode
						select @Rowcount=@@ROWCOUNT
					end
					if isnull(@Rowcount,0)=0
						BEGIN
							select @SDOrgID = os.sdorgid,@ChangeAmount = isnull(cavermoney,0),@ChangeCredit = isnull(cavermoney,0),
							@Refcode = UserTxt1,@ChangeFrozenAmount = 0,@Event = '发货扣减信用额度.'
							from   sPickorderHD sph with(nolock)
								   inner join oStorage os with(nolock)on  sph.instcode = os.stCode
							where  DocCode = @Doccode
							select @Rowcount=@@ROWCOUNT
						END
				if isnull(@ROWCOUNT,0)=0
					BEGIN
						raiserror('单据不存在,无法对信用额度进行更改.',16,1)
						return
					END
				--取出上级门店,作为信用额度控制
				select @AccountSdorgid=sdorgid ,@SDorgName=sdorgname from oSDOrg os with(nolock) where os.rowid=@ParentRowID
				--若是根据订货单发的货,则需要减少冻结额度,减少的冻结额度为订货额度,而非发货时的额度.
				if isnull(@Refcode,'')!=''
					begin
						--取订货单
						select @Event=@Event+'减少订货冻结额度.',@SourceDoccode=a.UserTxt1,@FlowInstanceID=isnull(a.usertxt1,'')
						from imatdoc_h a with(nolock)
						where a.doccode=@Refcode
						if @@rowcount=0
							begin
								raiserror('发货指令单不存在,无法检索到订货信息,无法处理信用额度.',16,1)
								return
							end
						--只有当订货单号是以DD开头的订货单时,才处理信用额度.
						if @SourceDoccode like 'DD%'
							begin
								--取指令单上的分货金额,用于减少冻结额度.
								select @ChangeFrozenAmount=-sum(isnull(b.totalmoney,0)),@FrozenStatus='已处理'
								from  imatdoc_d   b with(nolock) 
								where  b.DocCode=@Refcode
								group by b.doccode
							end
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
						return
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
		If @Formid In(9102,9146,9237,6090,9167,9244,9267,6052)
			Begin
				SET @sql = 'select @AvailabBalance=ISNULL(AvailableBalance,0),@OverRunLimit=ISNULL(OverrunLimit,0),@FrozenAmount= ISNULL(FrozenAmount,0), ' + char(10)
				 + '				@Balance=isnull(Balance,0) ' + char(10)
				 + '				from OpenQuery(URP11,''Select AvailableBalance,OverrunLimit,FrozenAmount,Balance From JTURP.dbo.oSDOrgCredit  ' + char(10)
				 + '				where SDorgID='''''+isnull(@AccountSdorgid,'') +'''''' + char(10)
				 + '				and Account=''''113107'''''')'
				--Print @sql
				Exec sp_executesql @sql,N'@AvailabBalance money output,@OverRunLimit money output,@FrozenAmount money output,@Balance money output',
				@AvailabBalance=@AvailabBalance Output,@OverRunLimit=@OverRunLimit Output,@FrozenAmount=@FrozenAmount Output,@Balance=@Balance output
				select @Rowcount=@@ROWCOUNT
 
				--若非启动流程,则取出已有流程的信息,并标志流程是否存在.
				if isnull(@StartFlow,0)=0 AND isnull(@FlowInstanceID,'')<>''
					BEGIN
						SET @sql = 'select @FlowFrozenAmount=ISNULL(FrozenAmount,0),@FlowUnFrozenAmount=ISNULL(ProcessedAmount,0),@FlowStatus=ISNULL(FlowStatus,''未完成'')'
						 + '				from OpenQuery(URP11,''Select FrozenAmount,ProcessedAmount ,FlowStatus From JTURP.dbo.oSDOrgCreditFlow  ' + char(10)
						 + '				where FlowInstanceID='''''+isnull(@FlowInstanceID,'') +''''''')' + char(10)
						--Print @sql
						Exec sp_executesql @sql,N'@FlowFrozenAmount money output,@FlowUnFrozenAmount money output,@FlowStatus varchar(50) output',
						@FlowFrozenAmount=@FlowFrozenAmount Output,@FlowUnFrozenAmount=@FlowUnFrozenAmount OUTPUT,@FlowStatus=@FlowStatus output
						SELECT @FlowExists=CASE WHEN @@ROWCOUNT=0 THEN 0 ELSE 1 end
					END
 
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
				--若非启动流程,则取出已有流程的信息,并标志流程是否存在.
				if isnull(@StartFlow,0)=0 AND ISNULL(@FlowInstanceID,'')<>''
					BEGIN
						select @FlowFrozenAmount=ISNULL(FrozenAmount,0),@FlowUnFrozenAmount=ISNULL(ProcessedAmount,0),@FlowStatus=ISNULL(FlowStatus,'未完成')
						from dbo.oSDOrgCreditFlow WITH(NOLOCK)
						where FlowInstanceID= @FlowInstanceID
						SELECT @FlowExists=CASE WHEN @@ROWCOUNT=0 THEN 0 ELSE 1 END
					end
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
				 
				if isnull(@AvailabBalance,0)+isnull(@Commission,0)+isnull(@Rewards,0)-isnull(@ChangeCredit,0)-isnull(@ChangeFrozenAmount,0)+ISNULL(@OverRunLimit,0)+isnull(@DeductAmount,0)<0
					BEGIN
						SELECT @tips = 
						            '您的信用额度不足，请及时充值并确认已经通过审核的单据！' + dbo.crlf() +
						            '您可超支额度:'+convert(varchar(50),isnull(@OverRunLimit,0)) + dbo.crlf() +
						            '您已冻结额度:' + convert(varchar(50),isnull(@FrozenAmount,0))+dbo.crlf()+
						            '您当前余额:' + convert(varchar(50),isnull(@Balance,0)) + dbo.crlf() +
						            '您当前可用余额:' + convert(varchar(50),ISNULL(@AvailabBalance,0)) + dbo.crlf() +
						            '本单应扣额度:' + convert(varchar(50),isnull(@ChangeCredit,0)) + dbo.crlf() +
						            '本单冻结额度'+convert(varchar(50),isnull(@ChangeFrozenAmount,0)) + dbo.crlf() +
						            '本单佣金'+convert(varchar(50),isnull(@Commission,0)) + dbo.crlf() +
						            '本单优惠金额'+convert(varchar(50),isnull(@DeductAmount,0)) + dbo.crlf() 
						 RAISERROR(@tips,16,1) 
						 RETURN
					END
			END
		--流程状态控制
		IF @FlowExists=1 AND ISNULL(@FlowStatus,'未完成')='已完成'
			BEGIN
				RAISERROR('流程[%s]已解冻的额度达到冻结额度,流程结束,禁止继续操作.',16,1,@flowinstanceid)
				return
			END
			
/******************************************************统一更新信用额度信息******************************************************/
			--保证在分布式环境中事务可用.
			set xact_abort on
			--记录当前事务量.若此前已经有事务则不再启动事务,交由外部事务处理.若外部无事务,则启动一个事务.
			select @TranCount=@@TRANCOUNT,@Rowcount=0
			if @TranCount=0	begin tran
			begin try
				--更新信用额度
				print 606
				--分布式更新需要采用动态SQL方式更新
				If @Formid In(9102,9146,6090,9167,9244,9267,6052,4950)
					BEGIN
						begin try
							SET @sql = '	update Openquery(URP11,''SELECT FrozenAmount,Balance,ModifyDate,ModifyUser,terminalID,ModifyDoccode '+CHAR(10)
							 + '				From JTURP.dbo.oSDOrgCredit a Where SDOrgID='''''+isnull(@AccountSdorgid,'')+''''' AND Account=''''113107'''''')' + char(10)
							 + '				set    FrozenAmount  = isnull(FrozenAmount,0) + isnull(@ChangeFrozenAmount,0), ' + char(10)
							 + '					   Balance       = isnull(Balance,0) -isnull(@ChangeCredit,0), ' + char(10)
							 + '					   ModifyDate = getdate(), ' + char(10)
							 + '					   ModifyUser = @Usercode, ' + char(10)
							 + '					   terminalID=@TerminalID, ' + char(10)
							 + '					   ModifyDoccode = @Doccode'
							Exec sp_executesql @sql,N'@ChangeFrozenAmount money,@ChangeCredit money, @Usercode varchar(50),@TerminalID varchar(50),@Doccode varchar(50),@AccountSdorgid varchar(50)',
							@ChangeFrozenAmount=@ChangeFrozenAmount,@ChangeCredit=@ChangeCredit,@Usercode=@Usercode,
							@TerminalID=@TerminalID,@Doccode=@Doccode,@AccountSdorgid=@AccountSdorgid
							SELECT @Rowcount=@@ROWCOUNT
						end try
						begin catch
							select @tips=dbo.getLastError('更新信用额度失败。')
							raiserror(@tips,16,1)
							return
						end catch
						--若起始流程,则插入一条记录.
						if @StartFlow=1
							BEGIN
								Insert into Openquery(URP11,'Select  FlowInstanceID,Formid,FrozenAmount from JTURP.dbo.oSdorgCreditFlow')
								select @FlowInstanceID,@Formid,@ChangeFrozenAmount
							END
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
						SELECT @Rowcount=@@ROWCOUNT
						--若起始流程,则插入一条浏览记录.
						if @StartFlow=1
							BEGIN
								Insert into  dbo.oSdorgCreditFlow(FlowInstanceID,Formid,FrozenAmount )
								select @FlowInstanceID,@Formid,@ChangeFrozenAmount
							END
					END
			/*update Openquery(URP11,'SELECT FrozenAmount,Balance,ModifyDate,ModifyUser,terminalID,ModifyDoccode From oSDOrgCredit a Where SDOrgID=''' +@AccountSdorgid+''' ADN Account=''113107'''
				set    FrozenAmount  = isnull(FrozenAmount,0) + isnull(@ChangeFrozenAmount,0),
					   Balance       = isnull(a.Balance,0) -isnull(@ChangeCredit,0),
					   ModifyDate = getdate(),
					   ModifyUser = @Usercode,
					   terminalID=@TerminalID,
					   ModifyDoccode = @Doccode*/

				--若不存在,则要报错
				if @ROWCOUNT=0
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
								--PRINT @AccountSdorgid
								if @trancount=0 and @@TRANCOUNT>0 rollback
								raiserror('未更新信用额度信息,因为不存在此部门的信用额度信息,请初始化额度后再操作!',16,1)
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
 
				If @Formid In(9102,9146,9237,6090,9167,9244,9267,6052)
					BEGIN
						Insert into Openquery(URP11,'Select   Doccode, FormID, FormType, Docdate, DocType, 
						   Account, [Event], SDorgID, SDorgName, OverRunLimit, 
						   CreditAmount, FrozenAmount, ChangeFrozenAmount, ChangeCredit, 
						   Commission, Rewards,DeductAmount, Balance, AvailabBalance, Usercode, 
						   Remark, TerminalID, FrozenStatus, refCode,AccountSdorgid,FlowInstanceID from JTURP.dbo.oSdorgCreditLog')
						select @Doccode,@Formid,@FormType,getdate(),@Doctype,'113107',@Event,@SDOrgID,@SDorgName,@OverRunLimit,@Balance,@FrozenAmount,
							   @ChangeFrozenAmount,@ChangeCredit,@Commission,@Rewards,@DeductAmount,isnull(@Balance,0) -isnull(@ChangeCredit,0),
							   isnull(@AvailabBalance,0)-isnull(@ChangeFrozenAmount,0)-isnull(@ChangeCredit,0),@Usercode,@Remark,@TerminalID,
							   CASE  
										WHEN @FrozenStatus='已处理' and @FlowExists=1 and isnull(@FlowStatus,'')='未完成' then '待处理'
										else @FrozenStatus
								end, 
							   @Refcode,@AccountSdorgid,@FlowInstanceID
 
						--若非起始节点的待处理,则修改已处理额度.
						 if isnull(@StartFlow,0)=0 AND ISNULL(@FlowExists,0)=1
							BEGIN
								SET @sql = '			update Openquery(URP11,''SELECT ProcessedAmount,ModifyDate,ModifyUser,terminalID,ModifyDoccode,FlowStatus,FrozenAmount From JTURP.dbo.oSDOrgCreditFlow a Where FlowInstanceID='''''+isnull(@FlowInstanceID,'')+'''''''   )' + char(10)
									 + '				set    ProcessedAmount  = isnull(ProcessedAmount,0) - isnull(@ChangeFrozenAmount,0), ' + char(10)
									 +'				FlowStatus=CASE WHEN isnull(ProcessedAmount,0) - isnull(@ChangeFrozenAmount,0)>=ISNULL(FrozenAmount,0) THEN ''已完成'' else isnull(FlowStatus,''未完成'') end,' +char(10)
									 + '					   ModifyDate = getdate(), ' + char(10)
									 + '					   ModifyUser = @Usercode, ' + char(10)
									 + '					   terminalID=@TerminalID, ' + char(10)
									 + '					   ModifyDoccode= @Doccode'
									Exec sp_executesql @sql,N'@ChangeFrozenAmount money,@ChangeCredit money, @Usercode varchar(50),@TerminalID varchar(50),@Doccode varchar(50),@AccountSdorgid varchar(50)',
									@ChangeFrozenAmount=@ChangeFrozenAmount,@ChangeCredit=@ChangeCredit,@Usercode=@Usercode,
									@TerminalID=@TerminalID,@Doccode=@Doccode,@AccountSdorgid=@AccountSdorgid 
							END
					End
				Else
					BEGIN
						insert into oSdorgCreditLog( Doccode, FormID, FormType, Docdate, DocType, 
						   Account, [Event], SDorgID, SDorgName, OverRunLimit, 
						   CreditAmount, FrozenAmount, ChangeFrozenAmount, ChangeCredit, 
						   Commission, Rewards,DeductAmount, Balance, AvailabBalance, Usercode, 
						   Remark, TerminalID, FrozenStatus, refCode,AccountSdorgid,FlowInstanceID)
						select @Doccode,@Formid,@FormType,getdate(),@Doctype,'113107',@Event,@SDOrgID,@SDorgName,@OverRunLimit,@Balance,@FrozenAmount,
							   @ChangeFrozenAmount,@ChangeCredit,@Commission,@Rewards,@DeductAmount,isnull(@Balance,0) -isnull(@ChangeCredit,0),
							   isnull(@AvailabBalance,0)-isnull(@ChangeFrozenAmount,0)-isnull(@ChangeCredit,0),@Usercode,@Remark,@TerminalID,
							   CASE  
										WHEN @FrozenStatus='已处理' and isnull(@FlowExists,0)=1 and isnull(@FlowStatus,'')='未完成' then '待处理'
										else @FrozenStatus
								end,
							   @Refcode,@AccountSdorgid,@FlowInstanceID
						--若非起始节点的待处理,则修改已处理额度.
						 if   isnull(@StartFlow,0)=0 AND ISNULL(@FlowExists,0)=1
							BEGIN
								update a
								set ProcessedAmount  = isnull(ProcessedAmount,0) - isnull(@ChangeFrozenAmount,0),
									   ModifyDate = getdate(),
									   ModifyUser = @Usercode,
									   terminalID=@TerminalID,
									   ModifyDoccode = @Doccode 
									   ,FlowStatus=CASE WHEN isnull(ProcessedAmount,0) - isnull(@ChangeFrozenAmount,0)>=ISNULL(a.FrozenAmount,0) THEN '已完成' else isnull(a.FlowStatus,'未完成') end
								from   oSDOrgCreditFlow a
								where a.flowInstanceID=@FlowInstanceID
							end
					END
 
				--当有原始单号,且冻结状态处理完毕时,更新原冻结额度状态
				if  isnull(@SourceDoccode,'')!='' and @FrozenStatus = '已处理'
				Begin
					If  @Formid In(9102,9146,9237,6090,9167,9244,9267,4950,6093,6052)
						BEGIN
							/*Update Openquery(URP11,'Select frozenstatus,Refcode From oSdorgCreditLog  where  Doccode  ='''+ @SourceDoccode+'''and frozenStatus  = ''待处理''')
							set    frozenstatus      = @FrozenStatus,
								   Refcode           = @SourceDoccode
							*/
							--若流程存在,且已处理额度大于等于冻结额度,则终止流程.
							IF @FlowExists=1 AND ISNULL(@FlowFrozenAmount,0)<=ISNULL(@FlowUnFrozenAmount,0)-ISNULL(@ChangeFrozenAmount,0)  AND ISNULL(@FlowInstanceID,'')<>''
								BEGIN
									SET @sql = 'Update Openquery(URP11,''Select frozenstatus,Refcode From JTURP.dbo.oSdorgCreditLog  where  FlowInstanceID  ='''''+ isnull(@FlowInstanceID,'')+''''''+char(10)+
									 ' and frozenStatus  = ''''待处理'''''')' + char(10)
											 + '							set    frozenstatus      = ''已处理'', ' + char(10)
											 + '								   Refcode           = @Doccode'
									--Print @sql
									Exec sp_executesql @sql,N'@SourceDoccode varchar(30),@FrozenStatus varchar(20),@Doccode varchar(50)',
									@SourceDoccode=@SourceDoccode,@FrozenStatus=@FrozenStatus,@Doccode=@Doccode
									--若流程已结束,则尝试将未使用的优惠券还原.
									--exec URP11.JTURP.dbo.sp_UpdateCouponsFlow @Formid,@Doccode,@FlowInstanceID,'已完成','',@Usercode,@terminalid
								END
							IF ISNULL(@FlowExists,0)=0
								BEGIN
									SET @sql = 'Update Openquery(URP11,''Select frozenstatus,Refcode From JTURP.dbo.oSdorgCreditLog  where  Doccode  ='''''+ isnull(@SourceDoccode,'')+''''''+char(10)+
									 '  and frozenStatus  = ''''待处理'''''')  ' + char(10)
											 + '							set    frozenstatus      = @FrozenStatus, ' + char(10)
											 + '								   Refcode           = @Doccode'
									--Print @sql
									Exec sp_executesql @sql,N'@SourceDoccode varchar(30),@FrozenStatus varchar(20),@Doccode varchar(50)',
									@SourceDoccode=@SourceDoccode,@FrozenStatus=@FrozenStatus,@Doccode=@Doccode
									
								END
						End
					Else
						BEGIN
							IF @FlowExists=1 AND ISNULL(@FlowFrozenAmount,0)<=ISNULL(@FlowUnFrozenAmount,0)-ISNULL(@ChangeFrozenAmount,0) AND ISNULL(@FlowInstanceID,'')<>''
								BEGIN
									update oSdorgCreditLog
									set    frozenstatus      = @FrozenStatus,
										   Refcode           = @SourceDoccode
									WHERE FlowInstanceID=@FlowInstanceID
										   and frozenStatus  = '待处理'
									--若流程已结束,则尝试将未使用的优惠券还原.
									--exec sp_UpdateCouponsFlow @Formid,@Doccode,@FlowInstanceID,'已完成','',@Usercode,@terminalid
								END
							IF ISNULL(@FlowExists,0)=0
								BEGIN
									update oSdorgCreditLog
									set    frozenstatus      = @FrozenStatus,
										   Refcode           = @SourceDoccode
									where  Doccode           = @SourceDoccode
										   and frozenStatus  = '待处理'
								END
						END
				END
				 
				--当外部无事务时,则前面的代码启动了事物,需要提交之.
				if @TranCount =0 commit
			end try
			begin catch

				if @TranCount=0 and @@TRANCOUNT>0  rollback
				
				select @tips=dbo.getLastError('更新信用额度失败!' )
				raiserror(@tips,16,1)
				return
			end catch	
	end
 