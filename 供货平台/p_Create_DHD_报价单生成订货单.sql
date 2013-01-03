/*
  exec [p_Create_DHD] 'adfda','a,1;b,2;c,3'
*/

alter PROCEDURE [dbo].[p_Create_DHD]
    @sdorgid VARCHAR(300) ,
    @mat VARCHAR(MAX),						--订单信息,格式如下matcode,digit,stock,price;matcode,digit,stock,price;以分号分行,以逗号分隔信息
    @Usercode varchar(50)='',
    @UserName varchar(200)=''
AS 
    BEGIN
    	set NOCOUNT ON;
    	declare @NewDoccode varchar(50),@msg varchar(max)
    	declare @SDorgName varchar(200),@Stcode varchar(50),@stName varchar(200),@ParentSDorgID varchar(50),@ParentSDOrgName varchar(200)
    	declare @dptType varchar(50),@CompanyID varchar(50),@CompanyName varchar(200),@ParentRowID varchar(50)
    	declare @ps_stcode varchar(50),@ps_stname varchar(200),@Totalmoney money
	 /*
		1.订货单标志是否华强北处理.若是华强北商品,且有库存,则打上标志,必须走采购流程,计划部不可见.
		2.不存在我公司商品和华强北商品重叠的情况.
	 */
        IF ISNULL(@sdorgid, '') = ''
            OR ISNULL(@mat, '') = '' 
            BEGIN 
                RAISERROR('订货门店或订购商品为空',16,1);
                RETURN;
            END 
 		--订购表
        DECLARE @dhdtable TABLE
            (
              sdorgid VARCHAR(300) ,
              matcode VARCHAR(300) ,
              matname varchar(200),
              matgroup varchar(50),
              mattype varchar(50),
              salesuom varchar(50),
              matstatus varchar(50),
              packagecode varchar(50),
              baseuom varchar(50),
              digit INT ,
              stock INT,
              Price money,
              Totalmoney money,
              PurchaseFlag bit
            );
        --解析订单数据
        --先解析行
            ;with cte (id,data) as(
		select row_number() over(order by (select 1)) as ID,s.List 
		  from commondb.dbo.SPLIT(@mat,';') s
            )
        --再解析列
		,cte1(id,id1,data) as(
		select a.id,row_number() OVER (partition by a.id order by (select 1)) as id1,s2.List 
		  from cte a outer APPLY commondb.dbo.SPLIT(a.data,',') s2
		where a.data<>''
		)
		--再合并成需要的结果集
		,cte2(id,matcode,digit,stock,Price) as (
			select id,
		max(case when id1=1 then data else null end) as matcode, 
		max(case when id1=2 then convert(int,data) else null end) as digit,
		max(case when id1=3 then convert(int,data) else null end) as stock,
		max(case when id1=4 then convert(money,data) else null end) as price
		from cte1
		group by id)
		--将解析的数据写入订货单变量
		insert into @dhdtable
		select @sdorgid,a.matcode,img.matname,img.matgroup,img.mattype,img.salesuom,
		img.matstatus,img.packagecode,img.baseuom,a.digit,a.stock,a.price,isnull(a.digit,0)*isnull(a.price,0),img.PurchaseFlag
		from cte2 a left join iMatGeneral img on a.matcode=img.MatCode							--为防止传入的商品编码不存在,这里要用LEFT JOIN,以便以后面校验
		select * from @dhdtable
		--校验数据
		if @@ROWCOUNT=0
			BEGIN
				select @msg='订单数据异常,无法继续操作,请联系系统管理员.' + dbo.crlf() +@mat
				raiserror(@msg,16,1)
				return
			END
		--用商品名称校验商品编码是否正确
		if exists(select 1 from @dhdtable where isnull(matname,'')='')
			BEGIN
				select @msg='订单商品数据异常,无法继续,请联系系统管理员.' + dbo.crlf() +@mat
				raiserror(@msg,16,1)
				return
			END
		--校验订货数量
		if exists(select 1 from @dhdtable where isnull(digit,0)<=0)
			BEGIN
				select @msg='订单数量异常,无法继续,,请联系系统管理员.' + dbo.crlf() +@mat
				raiserror(@msg,16,1)
				return
			END
		--取出信息
		select @SDOrgName=SDOrgName,@dptType=dptType,@ParentRowID=parentrowid
		from osdorg with(nolock)
		where SDOrgID=@sdorgid
		if @@ROWCOUNT=0
			BEGIN
				select @msg='部门数据异常,无法继续,,请联系系统管理员.' + dbo.crlf() +@mat
				raiserror(@msg,16,1)
				return
			END
		--取出仓库信息
		select @Stcode=stcode,@stName=name40,@CompanyID=os.PlantID,@ps_stcode=os.ps_stcode1,@ps_stname=os.ps_stname1
		from oStorage os with(nolock)
		where os.sdorgid=@sdorgid
		if @@ROWCOUNT=0
			BEGIN
				select @msg='仓库数据异常,无法继续,,请联系系统管理员.' + dbo.crlf() +@mat
				raiserror(@msg,16,1)
				return
			END
		--取出父级部门信息
		select @ParentSDorgID=os.SDOrgID,@ParentSDOrgName=os.SDOrgName
		from oSDOrg os with(nolock)
		where os.rowid=@ParentRowID
		if @@ROWCOUNT=0
			BEGIN
				select @msg='加盟商数据异常,无法继续,,请联系系统管理员.' + dbo.crlf() +@mat
				raiserror(@msg,16,1)
				return
			END
		if exists(select 1 from @dhdtable where Price is null)
			BEGIN
				select @msg='订货价格数据异常,无法继续,,请联系系统管理员.' + dbo.crlf() +@mat
				raiserror(@msg,16,1)
				return
			END
		begin tran
		begin try
			--生成非采购流程订单
			if exists(select 1 from @dhdtable where isnull(PurchaseFlag,0)=0)
				BEGIN
					exec sp_newdoccode 6090,'',@NewDoccode out
					--求总金额
					set @Totalmoney=(select sum(isnull(price,0)*isnull(digit,0)) from @dhdtable where isnull(PurchaseFlag,0)=0 group by sdorgid)
					--生成单头
					insert into ord_shopbestgoodsdoc(
						DocCode,DocDate,FormID,DocStatus,CompanyID,sdorgid,sdorgname,
						EnterName,EnterDate,ModifyName,ModifyDate,PostName,PostDate,
						phflag,SumNetMoney,formname,Arrivaltime,ps_st,ps_stname,usertxt3,
						sttypeid,sales_mode,cltcode,cltname,stcode,stname,pcompanyid,purchase)
					select @NewDoccode,convert(varchar(10),getdate(),120),6090,100,@CompanyID,@sdorgid,@SDorgName,
					@UserName,convert(varchar(20),getdate(),120),@UserName,convert(varchar(20),getdate(),120),@UserName,convert(varchar(20),getdate(),120),
					'未处理',@totalmoney,'总部订货申请单',convert(varchar(10),getdate()+1,120),@ps_stcode,@ps_stname,NULL as usertxt3,
					@dptType,'紧急销售模式',@parentSDorgID,@ParentSDorgName,@stcode,@stname,NULL,0
					--生成单据明细
					insert into ord_shopbestgoodsdtl(
						doccode,docitem,rowid,matcode,matname,matgroup,salesuom,ask_digit,salesprice,totalmoney,baseuom,matstatus,mattype,end4,stock_digit,hasStock)
					select @NewDoccode,row_number() OVER (order by (select 1)),newid(),a.matcode,a.matname,a.matgroup,a.salesuom,
					a.digit,a.Price,isnull(a.Price,0)*isnull(a.digit,0),a.baseuom,a.matstatus,a.mattype,0,a.stock,1
					from @dhdtable a
					where isnull(a.PurchaseFlag,0)=0
					--执行过帐
					exec check_order @newdoccode
					exec sp_UpdateCredit 6090,@newDoccode,@SDOrgID,1,'','',@Usercode,''
				END
			--生成采购流程订单
			if exists(select 1 from @dhdtable where isnull(PurchaseFlag,0)=1)
				BEGIN
					exec sp_newdoccode 6090,'',@NewDoccode out
					--求总金额
					set @Totalmoney=(select sum(isnull(price,0)*isnull(digit,0)) from @dhdtable	where isnull(PurchaseFlag,0)=1 group by sdorgid)
					--生成单头
					insert into ord_shopbestgoodsdoc(
						DocCode,DocDate,FormID,DocStatus,CompanyID,sdorgid,sdorgname,
						EnterName,EnterDate,ModifyName,ModifyDate,PostName,PostDate,
						phflag,SumNetMoney,formname,Arrivaltime,ps_st,ps_stname,usertxt3,
						sttypeid,sales_mode,cltcode,cltname,stcode,stname,pcompanyid,purchase)
					select @NewDoccode,convert(varchar(10),getdate(),120),6090,100,@CompanyID,@sdorgid,@SDorgName,
					@UserName,convert(varchar(20),getdate(),120),@UserName,convert(varchar(20),getdate(),120),@UserName,convert(varchar(20),getdate(),120),
					'未处理',@totalmoney,'总部订货申请单',convert(varchar(10),getdate()+1,120),@ps_stcode,@ps_stname,NULL as usertxt3,
					@dptType,'紧急销售模式',@parentSDorgID,@ParentSDorgName,@stcode,@stname,NULL,1
					--生成单据明细
					insert into ord_shopbestgoodsdtl(
						doccode,docitem,rowid,matcode,matname,matgroup,salesuom,ask_digit,salesprice,totalmoney,baseuom,matstatus,mattype,end4,stock_digit,hasStock)
					select @NewDoccode,row_number() OVER (order by (select 1)),newid(),a.matcode,a.matname,a.matgroup,a.salesuom,
					a.digit,a.Price,isnull(a.Price,0)*isnull(a.digit,0),a.baseuom,a.matstatus,a.mattype,0,a.stock,1
					from @dhdtable a
					where isnull(a.PurchaseFlag,0)=1
					--执行过帐
					exec check_order @newdoccode
					exec sp_UpdateCredit 6090,@newDoccode,@SDOrgID,1,'','',@Usercode,''
				END
				commit
		end try
		begin catch
			rollback
			select @msg=dbo.getLastError('生成订货单失败.')
			raiserror(@msg,16,1)
			return
		end catch
			--select top 100 * from ord_shopbestgoodsdoc os where os.DocCode like 'DD%' order by os.DocDate desc
			--select top 100 * from ord_shopbestgoodsdtl   os  where os.DocCode like 'DD%' and os.doccode='DD20121226000520' order by os.doccode desc
/*
        INSERT  INTO @dhdtable
                ( sdorgid ,
                  matcode ,
                  digit ,
                  hqbstock ,
                  dystock 
                )
                SELECT  a.sdorgid ,
                        LEFT(b.list, CHARINDEX(',', b.list) - 1) ,
                        RIGHT(b.list, CHARINDEX(',', b.list) - 1) ,
                        0 ,
                        0
                FROM    ( SELECT    @sdorgid AS sdorgid
                        ) AS a
                        CROSS JOIN ( SELECT *
                                     FROM   commondb.dbo.split(@mat, ';')
                                   ) AS b
		--更新订购表库存
		UPDATE t SET t.hqbstock=sv.stock from @dhdtable t JOIN  sMatStorage_VND sv ON t.matcode=sv.Matcode	
			
		DECLARE @ps_stcode1 VARCHAR(300);
		SELECT @ps_stcode1= o.ps_stcode1 FROM  dbo.oStorage o WHERE  o.stCode=@SDorgID;
		UPDATE t SET t.dystock = stk.totaldigit
		from @dhdtable t OUTER APPLY dbo.f_ret_stockdigit(t.MatCode,@ps_stcode1,@ps_stcode1) stk;
		--生成分货单
		SELECT TOP 100  * FROM sMatStorage_VND
        SELECT  *
        FROM    @dhdtable;
*/
			
    END