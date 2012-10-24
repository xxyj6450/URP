/*  
* 函数名称:[[fn_getPackageEXEX]]  
* 功能描述:根据条件获取套包  
* 参数:见声名部分  
* 编写:三断笛  
* 2010/5/28  
* 备注: 查询条件比较灵活，请翻阅MSDN的cross apply部分
* 示例:select * from dbo.fn_getPackage('2010-06-07','2010-06-07','','','','')
*-------------------------------------------------------------------------------
*修改时间：2012/04/11
*修改人：三断笛
*修改说明：对此功能进行扩展升级，新增参数，并新调整查询条件。可以根据商品信息反查政策。
*备注：匹配方式从大小至小的方式逐层过滤查询
*--------------------------------------------------------------------------------
*修改时间:2012/10/22
*修改人:三断笛
*修改说明:重新修改此函数.将此函数从fn_getPackageEX移植过来,并且进行了大量的扩充.
*示例：select * from dbo.[fn_getPackageEXEX]('2012-04-11','2012-04-11','','','','','','','8986011285100820499','','','','是','','')
select * from dbo.[fn_getPackageEXEX]('2012-04-11','2012-04-11','','','','','769','','','','','','是','','')
*/   
alter   FUNCTION [dbo].fn_getPackageEXEX(  
	@begindate DATETIME,  
	@enddate DATETIME,  
	@PackageID  VARCHAR(50), 
	@PackageName VARCHAR(200),
	@ExternalName varchar(200),
	@BusiType VARCHAR(200), 
	@companyID VARCHAR(20),  
	@AreaID VARCHAR(20),  
	@sdorgid VARCHAR(30),
	@Seriescode VARCHAR(50),
	@Matcode VARCHAR(50),						
	@Matgroup VARCHAR(50),					
	@Valid VARCHAR(10),						
	@Reserved VARCHAR(50),
	@SeriesNumber varchar(20)
)    
RETURNS @table TABLE (  
	PackageID VARCHAR(20),							--政策编码
	PackageName VARCHAR(200),					--政策名称
	ExternalName varchar(200),						--门店显示名称
	PackageType VARCHAR(200),						--政策类型
	PackageTypeName varchar(200),					--套包政策类型
	begindate DATETIME,									--起始时间
	ENDDate DATETIME,									--结束时间
	CompanyID VARCHAR(100),						--公司编码
	CompanyName VARCHAR(200),					--公司名称
	AreaID VARCHAR(100),								--区域编码
	AreaName VARCHAR(200),							--区域名称
	SdorgID VARCHAR(500),								--部门编码
	SdorgName VARCHAR(200),						--部门名称
	Valid BIT,													--是否有效
	Reserved BIT,											--是否预约套包
	STATE INT,												--状态值,当为1时,弹出提示,禁止操作,为2时仅提示用户.
	Remark VARCHAR(500),								--备注.提示信息.当状态为1时弹出提示,当状态为2时,提示用户
	SeriesCode varchar(50),								--串号
	Matcode VARCHAR(50),								--商品编码
	MatName VARCHAR(100),							--商品名称
	SalePrice Money,										--售价
	StockState varchar(20),								--库存状态
	OpenAccount bit										--是否开户
 )  
as    
 BEGIN  
 	DECLARE @stcode VARCHAR(50),@StockState VARCHAR(50),@SdorgID1 VARCHAR(50),@AreaID1 VARCHAR(50),@companyID1 VARCHAR(50)
 	DECLARE @OpenAccount BIT,@Old BIT,@hasPhone AS BIT,@hasBusiType BIT,@Rowcount INT,@busiTypeName VARCHAR(200),@StockState1 Varchar(50)
 	DECLARE @Matgroup1 VARCHAR(50),@MatName1 VARCHAR(100),@MatgroupName1 VARCHAR(100),@matcode1 VARCHAR(50),@MatName Varchar(200)
 	Declare @Occupyed Int,@saled Int
 	declare @preallocation_PackageId varchar(20),@Preallocation_Name varchar(200)
 	IF ISNULL(@BusiType,'')!=''
 		BEGIN
 			SELECT @OpenAccount=ISNULL(pg.OpenAccount,0),@Old=ISNULL(pg.oldCustomerBusi,0),
 			@hasPhone=ISNULL(@hasPhone,0),@busiTypeName=pg.PolicyGroupName,
 			@StockState1=pg.stockstate
 			FROM T_PolicyGroup pg WHERE pg.PolicyGroupID=@BusiType
 			IF @@ROWCOUNT=0
 				SET @hasBusiType=0
 			ELSE
 				SET @hasBusiType=1
 		End
 	--参数校验,防止用户输入的商品编码不属于输入的大类,那是矛盾的参数
 	If Isnull(@Matcode,'')!='' And Isnull(@Matgroup1,'')!=''
 		BEGIN
 			If Not Exists(Select 1 From iMatGeneral img With(Nolock),iMatGroup img1 With(Nolock) Where img.MatGroup=img.MatGroup And img1.path Like '%/'+@Matgroup+'/%')
 				BEGIN
 					Insert into @table(Seriescode,[STATE],Remark)
 					Select @seriescode, 1,'输入的商品编码不属于商品大类,二者冲突,无法进行匹配,请纠正后再操作.'
 					return
 				END
 		End
 	--参数检验,防止输入的部门不属于公司
	--若串号不为空，则取串号的信息
	IF ISNULL(@Seriescode,'')!='' 
		Begin
			--初始化库存状态
			Select @StockState='无状态',@Occupyed=0,@Saled=0
			--取串号信息
			SELECT  @matcode1=matcode,@stcode=i.stcode,@StockState=i.[state],@Occupyed=Coalesce(Nullif(i.isava,0),Nullif(i.isbg,0),Nullif(i.Occupyed,0)),@saled=Isnull(i.salemun,0)
			From iSeries i
			WHERE i.SeriesCode=@Seriescode
			SELECT @Rowcount=@@ROWCOUNT
			--若有业务类型,则判断业务类型与串号状态是否匹配
			If @hasBusiType=1
				BEGIN
					If @StockState1!='' And Not Exists(Select 1 From T_PolicyGroup pg With(Nolock) Outer Apply  commondb.dbo.[SPLIT](isnull(pg.StockState,'在库'),',') s 
					                                   Where s.List =@StockState 
					                                   And Isnull(pg.hasPhone,0)=1
					                                   And pg.[PATH] Like '%/'+@BusiType+'/%'
					)
					BEGIN
						Insert into @table(seriescode,[STATE],Remark)
						Select @Seriescode, 1,'终端库存状态为['+case when @StockState='无状态' then '非公司机' else @StockState end +'],不允许参与当前活动.'
						return
					END
					                                   
				End
			--判断是否被占用
			/*If @Occupyed=1
				BEGIN
					Insert into @table(seriescode,[STATE],Remark)
					Select @Seriescode, 1,'该终端已被其他单据占用,请更换其他终端.'
					return
				End*/
			--若该终端被占用或已售,而业务类型不允许已售机型,则抛出异常
			If @saled=1 Or @Occupyed=1
				BEGIN
					If Not Exists(Select 1 From T_PolicyGroup pg Outer Apply commondb.dbo.[SPLIT](Isnull(pg.StockState,'在库'),',') s 
									Where pg.[PATH] Like '%/'+@BusiType+'/%' 
									And s.List='已售'
									And pg.hasPhone=1
					)
					Begin
						If @saled=1
							BEGIN
								Insert into @table(seriescode,[STATE],Remark)
								Select @Seriescode, 1,'该终端已售,不允许办理'+case when isnull(@busiTypeName ,'')='' then '此' else @busiTypeName end +'类业务.'
								return
							END
						If @Occupyed=1
							BEGIN
								Insert into @table(seriescode,[STATE],Remark)
								Select @Seriescode, 1,'该终端已被占用,不允许办理'+case when isnull(@busiTypeName ,'')='' then '此' else @busiTypeName end +'类业务.'
								return
								return
							END
					END
				END 
			--如果没有匹配到串号,则进行TAC码匹配
			IF @ROWCOUNT=0 
				BEGIN
					--匹配TAC码,只匹配相似度最高的一个.
					SELECT top 1  @Matgroup1=i.Matgroup,@MatgroupName1=i.MatgroupName
					FROM T_TACCode  i WITH(NOLOCK) WHERE PATINDEX(i.TACCode+'%',@Seriescode)>0
					order by len(i.taccode) desc
					SELECT @Rowcount=@@ROWCOUNT
					--若仍未匹配到,则要直接退出返回
					IF @ROWCOUNT=0
						BEGIN
							INSERT INTO @table(Seriescode,[STATE],Remark)  
							SELECT @Seriescode, 1,'该终端未能通过TAC码校验,请检查终端串码是否正确,并重新录入串码进行操作.'+dbo.crlf()+
							'若此问题仍未得到解决请尝试更换终端并重试,或联系系统管理员.'
							return
						End
					--参数校验,防止录入的商品大类参数与TAC码匹配的大类不一致
					If Isnull(@Matgroup1,'')!='' And Isnull(@Matgroup,'')!=''
						BEGIN
							If Not Exists(Select 1 From iMatGroup img With(Nolock) Where img.matgroup=@Matgroup And img.path Like '%/'+@Matgroup1+'/%')
							And Not Exists(Select 1 From iMatGroup img With(Nolock) Where img.matgroup=@Matgroup1 and img.[PATH] Like '%/'+@Matgroup+'/%')
								BEGIN
									Insert into @table([STATE],Remark)
 									Select 1,'输入的商品编码不属于商品大类,二者冲突,无法进行匹配,请纠正后再操作.'
 									return
								END
						END
					If Isnull(@Matcode,'')='' And Isnull(@Matgroup,'')='' 
						BEGIN
							Select @Matgroup=Isnull(@Matgroup1,''),@matcode=''
						End
					--读取政策
					INSERT INTO @table(PackageID,PackageName,ExternalName,PackageType,PackageTypeName, begindate,ENDDate,CompanyID,CompanyName,AreaID,AreaName,SdorgID,SdorgName,
					Reserved,[STATE],Matcode,MatName,StockState,saleprice,OpenAccount,Valid,Remark)
					SELECT a.doccode,a.PackageName,a.ExternalName, a.PolicygroupID,a.DocType, a.begindate,a.enddate,a.companyid,a.companyname,a.areaid,a.areaName,a.SdOrgID,a.SdorgName,
					a.OnlyReservedCustomer,0,coalesce(psld.matcode,pd.matcode,@matgroup1,pd.matgroup),coalesce(psld.mattype, psld.matname,pd.MatName,@MatgroupName1,pd.matgroupname)
					,@StockState,0,isnull(pg.OpenAccount,0),isnull(a.actived,0),a.hdmemo
					FROM policy_h a  WITH(NOLOCK) inner join policy_d pd  WITH(NOLOCK) ON a.DocCode=pd.DocCode
					INNER JOIN T_PolicyGroup pg With(Nolock) ON a.PolicygroupID=pg.PolicyGroupID
					left join PackageSeriesLog_H pslh on pslh.RefCode=a.DocCode and pslh.Formid=9220
					left join PackageSeriesLog_D psld on pslh.Doccode=psld.Doccode
					left join PackageSeriesLog_H c on c.RefCode=a.DocCode and c.Formid=9147
					left join PackageSeriesLog_D d on c.Doccode=d.Doccode
					WHERE a.formid=9110
					and  (@valid in('','否')  or (@Valid in('是') and  a.DocStatus<>0))															--仅当要求政策为生效时,才要求政策状态为已确认
					AND (@PackageID='' or a.DocCode=@PackageID)
					AND (@PackageName='' or @PackageID!='' or  (@PackageID='' and a.PackageName LIKE '%'+@PackageName+'%'))				--仅当套包编码为空时,才查询套包名称
					AND (@ExternalName='' or @PackageID!='' or (@PackageID='' and a.ExternalName LIKE '%'+@ExternalName+'%'))				--仅当套包编码为空时,才查询门店显示名称
					AND (@begindate='' OR a.begindate<=@begindate)
					AND (@enddate='' OR a.enddate>=@enddate)
					And (@Valid='' or  a.actived= case when @Valid ='是' then 1 when @valid='否' then 0 end )
					And Isnull(pd.valid,0)=1
					And (Isnull(pd.beginDate,'')='' Or @begindate='' Or pd.begindate<=@begindate)
					And (Isnull(pd.endDate,'')='' Or @enddate='' Or pd.enddate>=@endDate)
					And pg.hasPhone=1																					--必须有手机
					AND (@BusiType=''
							--当传入的业务类型比政策业务类型级别高时,匹配传入业务类型下层所有业务类型,并且认为套包政策中的业务类型级别为叶子级别.
							OR  pg.[PATH] LIKE '%/'+@BusiType+'/%' )
						AND (@Reserved in('是') or (@Reserved in('','否') and ISNULL(a.OnlyReservedCustomer,0)=0) )-- OR ISNULL(a.OnlyReservedCustomer,0)=CASE @Reserved WHEN '是' then 1 else 0 END)
						and exists(select 1 from commondb.dbo.split(isnull(pg.StockState,'在库'),',') where list in ('无状态','已售'))
						--匹配公司
					AND (@companyID=''  OR (ISNULL(a.companyid,'')=''  and isnull(a.sdorgid,'')='')
							--直接匹配公司
							OR (ISNULL(a.companyid,'')!='' AND @companyID!=''  --AND ISNULL(a.sdorgid,'')=''
								AND  exists(select 1 from commondb.dbo.split(ISNULL(a.companyid,''),',') WHERE list=@companyID)
							)
							--部门也是与公司相关，所以再尝试从部门列表中取出公司来匹配
							--当公司信息为空时,才考虑从部门信息中匹配公司信息.只匹配政策中部门的子级,不匹配政策中部门的父级.因为实际上一个部门的父级,子级都是同一个公司.
							OR (isnull(a.sdorgid,'')!='' AND @companyID!=''  And Isnull(a.companyid,'')=''
								and EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.sdorgid,''),',') x 
											inner join osdorg y WITH(NOLOCK) on y.path like '%/'+x.list+'/%'
											inner join oPlantSDOrg os  WITH(NOLOCK) ON  y.sdorgid=os.SDOrgID 
											where os.PlantID=@companyID)
								)
					)
					
					--匹配区域
					AND (
							--若区域参数为空,则不进行区域匹配了
							@AreaID=''	
							--直接匹配区域，并可按区域级别查询
							OR (ISNULL(a.areaid,'')!='' AND @AreaID!='' --AND ISNULL(a.sdorgid,'')='' 
								AND (
										--先将区域作为子节点匹配.即假设用户输入的区域参数比政策中的区域级别低
										EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.areaid,''),',') x,gArea g  WITH(NOLOCK) WHERE g.areaid=@AreaID AND g.[PATH] LIKE '/%'+x.list+'/%')
										--再将区域作为父节点匹配.即假设用户输入的区域参数比政策中的区域级别高.
										or EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.areaid,''),',') x,gArea g  WITH(NOLOCK) WHERE g.areaid=x.List AND g.[PATH] LIKE '/%'+@AreaID+'/%')
								))
							--部门也与区域相关,若未设置区域,但设置了部门,还尝试从部门获取区域信息进行匹配
								or (isnull(a.areaid,'')='' and @AreaID!='' and isnull(a.sdorgid,'')!=''
									AND(
										--将区域作为父节点匹配.即假设用户输入的区域参数比政策中的区域级别高. 
										EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.sdorgid,''),',') x,gArea g  WITH(NOLOCK),oSDOrg os with(nolock) 
														WHERE os.path like '%/'+x.List+'/%'									--遍历部门及共子部门 
														and os.AreaID=g.areaid
														AND g.[PATH] LIKE '%/'+@AreaID+'/%')								--因为已经遍历了政策设置的部门及其子部门,所以这里的区域也匹配了子门店的区域.不需要再将区域作为子节点进行匹配.
										)
								)
							--若政策中部门和区域都为空,则表示所有区域都可以.
							or (isnull(a.areaid,'')='' and isnull(a.sdorgid,'')='')
					)
					--匹配门店
					AND(@sdorgid='' or (isnull(a.sdorgid,'')='' and isnull(a.companyid,'')='')
							--匹配门店，并按层级匹配
							OR(ISNULL(a.sdorgid,'')!='' AND @sdorgid!='' 
								AND (
										--先将门店作为子节点匹配,假设政策中设置的门店级别比参数中的门店级别高
										EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.sdorgid,''),',') x,oSDOrg o  WITH(NOLOCK) WHERE o.SDOrgID=@sdorgid AND o.path LIKE '%/'+x.list+'/%')
										 --先将门店作为子节点匹配,假设政策中设置的门店级别比参数中的门店级别高
										or EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.sdorgid,''),',') x,oSDOrg o  WITH(NOLOCK) WHERE o.SDOrgID=x.List AND o.path LIKE '%/'+@sdorgid+'/%')
								)
							)
							--若政策中未设置门店,则尝试从公司中匹配该门店信息,并且认为传入的门店编码可以在各个层级.
							Or (Isnull(a.sdorgid,'')='' And @sdorgid!='' And Isnull(a.companyid,'')!=''
								And (
									exists(Select 1 From commondb.dbo.[SPLIT](Isnull(a.companyid,''),',') s,oPlantSDOrg ops 
											 Where s.List=ops.PlantID 
											 And ops.SDOrgID=@sdorgid
									)
								)
							)
					)
					--匹配商品大类,必须是政策设置中大类的子类
					And (@Matgroup='' 
						or (@Matgroup!='' and (
									Exists(Select 1 From iMatGroup img Where img.matgroup=@Matgroup And Path Like '%/'+pd.matgroup+'/%')
									or exists(select 1 from iMatGroup img where img.matgroup=pd.matgroup and img.PATH like '%/'+@Matgroup+'/%')
								)
						)
					)
					and (@Matcode=''
							or (@Matcode!=''
								and (
										(isnull(pd.MatCode,'')!='' or pd.MatCode=@Matcode)
										or (isnull(pd.MatCode,'')='' 
											and exists(select 1 from iMatGeneral img with(nolock) inner join iMatGroup img2 on img.MatGroup=img2.matgroup
															where img.MatCode=@Matcode 
															and img2.PATH like '%/'+pd.matgroup+'/%')
										)
								)
							)
					)
					and (isnull(psld.SeriesNumber,'')='' or (isnull(psld.SeriesNumber,'')!='' and  @Seriescode  like isnull(psld.SeriesNumber,'')+'%'))
					and (@SeriesNumber='' or  isnull(d.SeriesNumber,'')='' or (isnull(d.SeriesNumber,'')!='' and @SeriesNumber like isnull(d.SeriesNumber,'')+'%'))
					--商品信息匹配
					--And (@Matcode!='' or Isnull(pd.MatCode,'')='' Or pd.MatCode=@Matcode)
					Group By a.doccode, a.PackageName,a.ExternalName,a.PolicygroupID,a.DocType,a.begindate,a.enddate,a.companyid,a.companyname,a.areaid,a.areaName,a.SdOrgID,a.SdorgName,
					a.OnlyReservedCustomer,coalesce(psld.matcode,pd.matcode,@matgroup1,pd.matgroup),coalesce(psld.mattype, psld.matname,pd.MatName,@MatgroupName1,pd.matgroupname),
					isnull(pg.OpenAccount,0),isnull(a.actived,0),a.hdmemo
					--order by a.RecommendLevel desc
					IF @@ROWCOUNT=0
						BEGIN
							INSERT INTO @table(Seriescode,[STATE],Remark)  
							SELECT @Seriescode, 1,'该终端尚不能办理'+case when isnull(@busiTypeName ,'')='' then '此' else @busiTypeName end +'类业务.'+
							'请选择其他业务办理,或选购其他机型.'
							return
						END
					else
						------若匹配到了政策,还需要判断是否预开号码且绑定了政策.还需要根据号码过滤政策
						BEGIN
							--若号码为预开,且绑定了政策,则删除非绑定的政策
							if isnull(@SeriesNumber,'')<>'' and exists(select 1 from @table a  where OpenAccount=1)					--此处先判断是否包含开户政策.若不包含则不往下执行了.
								BEGIN
									select @preallocation_PackageId=a.packageid
									  from seriespool a with(nolock) where a.SeriesNumber=@SeriesNumber
									  --若绑定了套包,则删除结果集中的其他套包
									  if isnull(@preallocation_PackageId,'')<>''
										BEGIN
											delete a from  @table a
											where a.packageid<>@preallocation_PackageId and a.OpenAccount=1								--此处只删除开户的政策.
											--若删的没套包了,则说明不符合规则
											if not exists(select 1 from @table)
												BEGIN
													select @Preallocation_Name=packagename from policy_h ph with(nolock) where ph.DocCode=@preallocation_PackageId
													INSERT INTO @table(Seriescode,[STATE],Remark)  
													SELECT @Seriescode, 1,'您选择的号码'+@seriesnumber+'已绑定['+isnull(@Preallocation_Name,'')+']政策,与当前业务类型不符.'+dbo.crlf()+
													'可能您使用的机型无法参与该政策,请尝试更换其他机型,或办理其他业务.'+dbo.crlf()+
													'若仍有疑问,请联系系统管理员.' 
													return
												END
										END
								END
						END
					return
				End
			--若串号存在,且取出了仓库信息,则从仓库信息关联其他信息
			IF ISNULL(@stcode,'')!=''
				BEGIN
					--再取出部门，区域和公司信息
					SELECT @sdorgid1=isnull(sdorgid,''),@AreaID1=ISNULL(AreaID,''),@companyID1=isnull(plantid,'') FROM oStorage o WITH(NOLOCK) WHERE o.stCode=@stcode
					--检查
					IF @sdorgid!='' AND @sdorgid!=@SdorgID1
						Begin
							--若是在库的机,则不允许跨门店使用
							if @StockState in('在库','应收')
								BEGIN
									if NOT EXISTS (select 1 from StorageConfig sc,oStorage os where sc.pubstcode=@stcode  and sc.stcode=os.stCode and os.sdorgid=@sdorgid)
										BEGIN
											Insert into @table(Seriescode,[STATE],Remark)
											Select @Seriescode,1,'该终端不在您仓库,无法办理业务,请确认此终端已调入.'
											return
										END
								END
							
							--若仓库信息不一致,而且业务类型不允许使用已售机,则抛出异常
							/*If Not Exists(Select 1 From T_PolicyGroup pg Outer Apply commondb.dbo.[SPLIT](Isnull(pg.StockState,'在库'),',') s Where s.list='已售')
								begin
									Insert into @table(Seriescode,[STATE],Remark)
									Select @Seriescode,1,'该终端不在您仓库,无法办理业务,请确认此终端已调入.'
									Return
								end*/
						END
					--当部门,公司,区域参数没有时,就将仓库信息关联的这些数据填充上,若已经有,则不覆盖
					--Select @AreaID=@AreaID1,@companyID=@companyID1
					IF @sdorgid='' 	SELECT @sdorgid=@SdorgID1

					IF @AreaID='' AND @sdorgid='' SELECT @AreaID=@areaid1
					
					IF @companyID='' AND @sdorgid='' SELECT @companyID=@companyID1
				END
			--当有串号信息时,尝试从串号信息关联出其商品信d息
			IF ISNULL(@Matcode1,'')!=''
				begin
					--再取出商品信息,若传入参数中无这些商品信息,则以串号关联的商品信息覆盖之,否则以参数中的商品信息为准
					SELECT @Matgroup=COALESCE(nullif(@Matgroup,''),ISNULL(ig.MatGroup,'')),@MatName=ig.matname,
					@Matcode=COALESCE(NULLIF(@Matcode,''),@Matcode1)
					 FROM iMatGeneral ig WITH(NOLOCK) WHERE ig.MatCode=@Matcode1
				end
			
			INSERT INTO @table(Seriescode,PackageID,PackageName,ExternalName,PackageType,PackageTypeName,begindate,ENDDate,CompanyID,CompanyName,AreaID,AreaName,SdorgID,SdorgName,
					Reserved,[STATE],Matcode,MatName,SalePrice,StockState,OpenAccount,Valid,Remark) 
			SELECT @Seriescode,a.doccode, a.PackageName,a.ExternalName,a.PolicygroupID,a.DocType,a.begindate,a.enddate,a.companyid,a.companyname,a.areaid,a.areaName,a.SdOrgID,a.SdorgName,
			a.OnlyReservedCustomer,0,@matcode,@MatName,0 as saleprice,@StockState,isnull(pg.OpenAccount,0),isnull(a.actived,0),a.hdmemo
			FROM policy_h a  WITH(NOLOCK) inner join policy_d pd  WITH(NOLOCK) ON a.DocCode=pd.DocCode
			INNER JOIN T_PolicyGroup pg ON a.PolicygroupID=pg.PolicyGroupID
			--Outer Apply dbo.uf_salesSDOrgpricecalcu3(@Matcode,@sdorgid,@Seriescode) ss
			left join PackageSeriesLog_H pslh on pslh.RefCode=a.DocCode and pslh.Formid=9220
			left join PackageSeriesLog_D psld on pslh.Doccode=psld.Doccode
			left join PackageSeriesLog_H c on c.RefCode=a.DocCode and pslh.Formid=9147
			left join PackageSeriesLog_D d on c.Doccode=d.Doccode
			WHERE a.formid=9110  
			AND (@PackageID='' or a.DocCode=@PackageID)
			AND (@PackageName='' or @PackageID!='' or  (@PackageID='' and a.PackageName LIKE '%'+@PackageName+'%'))				--仅当套包编码为空时,才查询套包名称
			AND (@ExternalName='' or @PackageID!='' or (@PackageID='' and a.ExternalName LIKE '%'+@ExternalName+'%'))				--仅当套包编码为空时,才查询门店显示名称
			AND (@begindate='' OR a.begindate<=@begindate)
			AND (@enddate='' OR a.enddate>=@enddate)
			And (@Valid='' or  a.actived= case when @Valid ='是' then 1 when @valid='否' then 0 end )
			and  (@valid in('','否')  or (@Valid in('是') and  a.DocStatus<>0))															--仅当要求政策为生效时,才要求政策状态为已确认
			And Isnull(pd.valid,0)=1
			And (Isnull(pd.beginDate,'')='' Or @begindate='' Or pd.begindate<=@begindate)
			And (Isnull(pd.endDate,'')='' Or @enddate='' Or pd.enddate>=@begindate)
			And pg.hasPhone=1																		--必须有手机
			AND (@BusiType=''
				--当传入的业务类型比政策业务类型级别高时,匹配传入业务类型下层所有业务类型,并且认为套包政策中的业务类型级别为叶子级别.
				OR  pg.[PATH] LIKE '%/'+@BusiType+'/%' )
			AND (@Reserved in('是') or (@Reserved in('','否') and ISNULL(a.OnlyReservedCustomer,0)=0) )
			--AND isnull(pd.inStock,'在库') in('在库','应收')
			And (Exists(Select 1 From commondb.dbo.[SPLIT](isnull(pg.StockState,''),',') s Where s.List=@StockState))
			--匹配公司
			AND (@companyID=''  OR (ISNULL(a.companyid,'')=''  and isnull(a.sdorgid,'')='')
					--直接匹配公司
					OR (ISNULL(a.companyid,'')!='' AND @companyID!=''  --AND ISNULL(a.sdorgid,'')=''
						AND  exists(select 1 from commondb.dbo.split(ISNULL(a.companyid,''),',') WHERE list=@companyID)
					)
					--部门也是与公司相关，所以再尝试从部门列表中取出公司来匹配
					--当公司信息为空时,才考虑从部门信息中匹配公司信息.只匹配政策中部门的子级,不匹配政策中部门的父级.因为实际上一个部门的父级,子级都是同一个公司.
					OR (isnull(a.sdorgid,'')!='' AND @companyID!=''  And Isnull(a.companyid,'')=''
						and EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.sdorgid,''),',') x 
									inner join osdorg y WITH(NOLOCK) on y.path like '%/'+x.list+'/%'
									inner join oPlantSDOrg os  WITH(NOLOCK) ON  y.sdorgid=os.SDOrgID 
									where os.PlantID=@companyID)
						)
			)
			
			--匹配区域
			AND (
					--若区域参数为空,则不进行区域匹配了
					@AreaID=''	
					--直接匹配区域，并可按区域级别查询
					OR (ISNULL(a.areaid,'')!='' AND @AreaID!='' --AND ISNULL(a.sdorgid,'')='' 
						AND (
								--先将区域作为子节点匹配.即假设用户输入的区域参数比政策中的区域级别低
								EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.areaid,''),',') x,gArea g  WITH(NOLOCK) WHERE g.areaid=@AreaID AND g.[PATH] LIKE '/%'+x.list+'/%')
								--再将区域作为父节点匹配.即假设用户输入的区域参数比政策中的区域级别高.
								or EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.areaid,''),',') x,gArea g  WITH(NOLOCK) WHERE g.areaid=x.List AND g.[PATH] LIKE '/%'+@AreaID+'/%')
						))
					--部门也与区域相关,若未设置区域,但设置了部门,还尝试从部门获取区域信息进行匹配
						or (isnull(a.areaid,'')='' and @AreaID!='' and isnull(a.sdorgid,'')!=''
							AND(
								--将区域作为父节点匹配.即假设用户输入的区域参数比政策中的区域级别高. 
								EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.sdorgid,''),',') x,gArea g  WITH(NOLOCK),oSDOrg os with(nolock) 
												WHERE os.path like '%/'+x.List+'/%'									--遍历部门及共子部门 
												and os.AreaID=g.areaid
												AND g.[PATH] LIKE '%/'+@AreaID+'/%')								--因为已经遍历了政策设置的部门及其子部门,所以这里的区域也匹配了子门店的区域.不需要再将区域作为子节点进行匹配.
								)
						)
					--若政策中部门和区域都为空,则表示所有区域都可以.
					or (isnull(a.areaid,'')='' and isnull(a.sdorgid,'')='')
			)
			--匹配门店
			AND(@sdorgid='' or (isnull(a.sdorgid,'')='' and isnull(a.companyid,'')='')
					--匹配门店，并按层级匹配
					OR(ISNULL(a.sdorgid,'')!='' AND @sdorgid!='' 
						AND (
								--先将门店作为子节点匹配,假设政策中设置的门店级别比参数中的门店级别高
								EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.sdorgid,''),',') x,oSDOrg o  WITH(NOLOCK) WHERE o.SDOrgID=@sdorgid AND o.path LIKE '%/'+x.list+'/%')
								 --先将门店作为子节点匹配,假设政策中设置的门店级别比参数中的门店级别高
								or EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.sdorgid,''),',') x,oSDOrg o  WITH(NOLOCK) WHERE o.SDOrgID=x.List AND o.path LIKE '%/'+@sdorgid+'/%')
						)
					)
					--若政策中未设置门店,则尝试从公司中匹配该门店信息,并且认为传入的门店编码可以在各个层级.
					Or (Isnull(a.sdorgid,'')='' And @sdorgid!='' And Isnull(a.companyid,'')!=''
						And (
							exists(Select 1 From commondb.dbo.[SPLIT](Isnull(a.companyid,''),',') s,oPlantSDOrg ops 
									 Where s.List=ops.PlantID 
									 And ops.SDOrgID=@sdorgid
							)
						)
					)
			)
			--匹配商品大类,必须是政策设置中大类的子类
			And (@Matgroup='' 
				or (@Matgroup!='' and (
							Exists(Select 1 From iMatGroup img Where img.matgroup=@Matgroup And Path Like '%/'+pd.matgroup+'/%')
							or exists(select 1 from iMatGroup img where img.matgroup=pd.matgroup and img.PATH like '%/'+@Matgroup+'/%')
						)
				)
			)
			and (@Matcode=''
					or (@Matcode!=''
						and (
								(isnull(pd.MatCode,'')!='' or pd.MatCode=@Matcode)
								or (isnull(pd.MatCode,'')='' 
									and exists(select 1 from iMatGeneral img with(nolock) inner join iMatGroup img2 on img.MatGroup=img2.matgroup
													where img.MatCode=@Matcode 
													and img2.PATH like '%/'+pd.matgroup+'/%')
								)
						)
					)
			)
			and (isnull(psld.SeriesNumber,'')='' or (isnull(psld.SeriesNumber,'')!='' and  @Seriescode  like isnull(psld.SeriesNumber,'')+'%'))
			and (@SeriesNumber='' or isnull(d.SeriesNumber,'')='' or (isnull(psld.SeriesNumber,'')!='' and @SeriesNumber like isnull(psld.SeriesNumber,'')+'%'))
			--商品信息匹配
			And (@Matcode!='' or Isnull(pd.MatCode,'')='' Or pd.MatCode=@Matcode)
			Group By a.doccode,  a.PackageName,a.ExternalName,a.PolicygroupID,a.DocType,a.begindate,a.enddate,a.companyid,a.companyname,a.areaid,a.areaName,a.SdOrgID,a.SdorgName,
			a.OnlyReservedCustomer,isnull(pg.OpenAccount,0),isnull(a.actived,0),a.hdmemo
			--order by a.RecommendLevel desc
			IF @@ROWCOUNT=0
				BEGIN
					INSERT INTO @table(Seriescode,[STATE],Remark)  
					SELECT @Seriescode,1,'该终端尚不能办理'+case when isnull(@busiTypeName ,'')='' then '此' else @busiTypeName end +'类业务.'+
					'请选择其他业务办理,或选购其他机型.'
					return
				END
			else
				------若匹配到了政策,还需要判断是否预开号码且绑定了政策.还需要根据号码过滤政策
						BEGIN
							--若号码为预开,且绑定了政策,则删除非绑定的政策
							if isnull(@SeriesNumber,'')<>'' and exists(select 1 from @table a  where OpenAccount=1)					--此处先判断是否包含开户政策.若不包含则不往下执行了.
								BEGIN
									select @preallocation_PackageId=a.packageid
									  from seriespool a with(nolock) where a.SeriesNumber=@SeriesNumber
									  --若绑定了套包,则删除结果集中的其他套包
									  if isnull(@preallocation_PackageId,'')<>''
										BEGIN
											delete a from  @table a
											where a.packageid<>@preallocation_PackageId and a.OpenAccount=1								--此处只删除开户的政策.
											--若删的没套包了,则说明不符合规则
											if not exists(select 1 from @table)
												BEGIN
													select @Preallocation_Name=packagename from policy_h ph with(nolock) where ph.DocCode=@preallocation_PackageId
													INSERT INTO @table(Seriescode,[STATE],Remark)  
													SELECT @Seriescode, 1,'您选择的号码'+@seriesnumber+'已绑定['+isnull(@Preallocation_Name,'')+']政策,与当前业务类型不符.'+dbo.crlf()+
													'可能您使用的机型无法参与该政策,请尝试更换其他机型,或办理其他业务.'+dbo.crlf()+
													'若仍有疑问,请联系系统管理员.' 
													return
												END
										END
								END
						END
			return
		END
	ELSE
	Begin
			--没未录入串号时,则不理会串号
			INSERT INTO @table(PackageID,PackageName,ExternalName,PackageType,PackageTypeName,begindate,ENDDate,CompanyID,CompanyName,AreaID,AreaName,SdorgID,SdorgName,
					Reserved,[STATE],OpenAccount,Valid,remark)
			SELECT a.doccode,a.PackageName,a.ExternalName,a.PolicygroupID,a.DocType,
			a.begindate,a.enddate,a.companyid,a.companyname,a.areaid,a.areaName,a.SdOrgID,a.SdorgName,
			a.OnlyReservedCustomer,0,isnull(pg.OpenAccount,0),isnull(a.actived,0),a.hdmemo
			FROM policy_h a  WITH(NOLOCK) --inner join policy_d pd  WITH(NOLOCK) ON a.DocCode=pd.DocCode
			INNER JOIN T_PolicyGroup pg ON a.PolicygroupID=pg.PolicyGroupID
			left join policy_d pd on a.DocCode=pd.DocCode
			left join PackageSeriesLog_H c on c.RefCode=a.DocCode and c.Formid=9147
			left join PackageSeriesLog_D d on c.Doccode=d.Doccode
			WHERE a.formid=9110  
			AND (@PackageID='' or a.DocCode=@PackageID)
			AND (@PackageName='' or @PackageID!='' or  (@PackageID='' and a.PackageName LIKE '%'+@PackageName+'%'))				--仅当套包编码为空时,才查询套包名称
			AND (@ExternalName='' or @PackageID!='' or (@PackageID='' and a.ExternalName LIKE '%'+@ExternalName+'%'))				--仅当套包编码为空时,才查询门店显示名称
			AND (@begindate='' OR a.begindate<=@begindate)
			AND (@enddate='' OR a.enddate>=@enddate)
			--And (Isnull(pd.beginDate,'')='' Or @begindate='' Or pd.begindate<=@begindate)
			--And (Isnull(pd.endDate,'')='' Or @enddate='' Or pd.enddate>=@endDate)
			AND (@Reserved in('是') or (@Reserved in('','否') and ISNULL(a.OnlyReservedCustomer,0)=0) )			--当有预约编号时才出现预约套包,否则不出现预约套包.
			And (@Valid='' or  a.actived= case when @Valid ='是' then 1 when @valid='否' then 0 end )
			and  (@valid in('','否')  or (@Valid in('是') and  a.DocStatus<>0))															--仅当要求政策为生效时,才要求政策状态为已确认
			--And Isnull(pg.hasPhone,0)=0
			AND (@BusiType=''
				--当传入的业务类型比政策业务类型级别高时,匹配传入业务类型下层所有业务类型,并且认为套包政策中的业务类型级别为叶子级别.
				OR  pg.[PATH] LIKE '%/'+@BusiType+'/%' )
 
			--匹配公司
			AND (@companyID=''  OR (ISNULL(a.companyid,'')=''  and isnull(a.sdorgid,'')='')
					--直接匹配公司
					OR (ISNULL(a.companyid,'')!='' AND @companyID!=''  --AND ISNULL(a.sdorgid,'')=''
						AND  exists(select 1 from commondb.dbo.split(ISNULL(a.companyid,''),',') WHERE list=@companyID)
					)
					--部门也是与公司相关，所以再尝试从部门列表中取出公司来匹配
					--当公司信息为空时,才考虑从部门信息中匹配公司信息.只匹配政策中部门的子级,不匹配政策中部门的父级.因为实际上一个部门的父级,子级都是同一个公司.
					OR (isnull(a.sdorgid,'')!='' AND @companyID!=''  And Isnull(a.companyid,'')=''
						and EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.sdorgid,''),',') x 
									inner join osdorg y WITH(NOLOCK) on y.path like '%/'+x.list+'/%'
									inner join oPlantSDOrg os  WITH(NOLOCK) ON  y.sdorgid=os.SDOrgID 
									where os.PlantID=@companyID)
						)
			)
			--匹配区域
			AND (
					--若区域参数为空,则不进行区域匹配了
					@AreaID=''	
					--直接匹配区域，并可按区域级别查询
					OR (ISNULL(a.areaid,'')!='' AND @AreaID!='' --AND ISNULL(a.sdorgid,'')='' 
						AND (
								--先将区域作为子节点匹配.即假设用户输入的区域参数比政策中的区域级别低
								EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.areaid,''),',') x,gArea g  WITH(NOLOCK) WHERE g.areaid=@AreaID AND g.[PATH] LIKE '/%'+x.list+'/%')
								--再将区域作为父节点匹配.即假设用户输入的区域参数比政策中的区域级别高.
								or EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.areaid,''),',') x,gArea g  WITH(NOLOCK) WHERE g.areaid=x.List AND g.[PATH] LIKE '/%'+@AreaID+'/%')
						))
					--部门也与区域相关,若未设置区域,但设置了部门,还尝试从部门获取区域信息进行匹配
						or (isnull(a.areaid,'')='' and @AreaID!='' and isnull(a.sdorgid,'')!=''
							AND(
								--将区域作为父节点匹配.即假设用户输入的区域参数比政策中的区域级别高. 
								EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.sdorgid,''),',') x,gArea g  WITH(NOLOCK),oSDOrg os with(nolock) 
												WHERE os.path like '%/'+x.List+'/%'									--遍历部门及共子部门 
												and os.AreaID=g.areaid
												AND g.[PATH] LIKE '%/'+@AreaID+'/%')								--因为已经遍历了政策设置的部门及其子部门,所以这里的区域也匹配了子门店的区域.不需要再将区域作为子节点进行匹配.
								)
						)
					--若政策中部门和区域都为空,则表示所有区域都可以.
					or (isnull(a.areaid,'')='' and isnull(a.sdorgid,'')='')
			)
			--匹配门店
			AND(@sdorgid='' or (isnull(a.sdorgid,'')='' and isnull(a.companyid,'')='')
					--匹配门店，并按层级匹配
					OR(ISNULL(a.sdorgid,'')!='' AND @sdorgid!='' 
						AND (
								--先将门店作为子节点匹配,假设政策中设置的门店级别比参数中的门店级别高
								EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.sdorgid,''),',') x,oSDOrg o  WITH(NOLOCK) WHERE o.SDOrgID=@sdorgid AND o.path LIKE '%/'+x.list+'/%')
								 --先将门店作为子节点匹配,假设政策中设置的门店级别比参数中的门店级别高
								or EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.sdorgid,''),',') x,oSDOrg o  WITH(NOLOCK) WHERE o.SDOrgID=x.List AND o.path LIKE '%/'+@sdorgid+'/%')
						)
					)
					--若政策中未设置门店,则尝试从公司中匹配该门店信息,并且认为传入的门店编码可以在各个层级.
					Or (Isnull(a.sdorgid,'')='' And @sdorgid!='' And Isnull(a.companyid,'')!=''
						And (
							exists(Select 1 From commondb.dbo.[SPLIT](Isnull(a.companyid,''),',') s,oPlantSDOrg ops 
									 Where s.List=ops.PlantID 
									 And ops.SDOrgID=@sdorgid
							)
						)
					)
			)
			--匹配商品大类,必须是政策设置中大类的子类
			And (@Matgroup='' 
				or (@Matgroup!='' and (
							Exists(Select 1 From iMatGroup img Where img.matgroup=@Matgroup And Path Like '%/'+pd.matgroup+'/%')
							or exists(select 1 from iMatGroup img where img.matgroup=pd.matgroup and img.PATH like '%/'+@Matgroup+'/%')
						)
				)
			)
			and (@Matcode=''
					or (@Matcode!=''
						and (
								(isnull(pd.MatCode,'')!='' or pd.MatCode=@Matcode)
								or (isnull(pd.MatCode,'')='' 
									and exists(select 1 from iMatGeneral img with(nolock) inner join iMatGroup img2 on img.MatGroup=img2.matgroup
													where img.MatCode=@Matcode 
													and img2.PATH like '%/'+pd.matgroup+'/%')
								)
						)
					)
			)
			and (@SeriesNumber='' or isnull(d.SeriesNumber,'')='' or (isnull(d.SeriesNumber,'')!='' and @SeriesNumber like isnull(d.SeriesNumber,'')+'%'))
			Group By a.doccode,a.PackageName,a.ExternalName,a.PolicygroupID,a.DocType,a.begindate,a.enddate,a.companyid,a.companyname,a.areaid,a.areaName,a.SdOrgID,a.SdorgName,
			a.OnlyReservedCustomer,isnull(pg.OpenAccount,0),isnull(a.actived,0),a.hdmemo
			--order by a.RecommendLevel desc
			IF @@ROWCOUNT=0
				BEGIN
					INSERT INTO @table(Seriescode,[STATE],Remark)  
					SELECT @Seriescode,1,'您尚不能办理'+case when isnull(@busiTypeName ,'')='' then '此' else @busiTypeName end +'类业务.'+
					'请选择其他业务办理'
					return
				END
			else
	 
				------若匹配到了政策,还需要判断是否预开号码且绑定了政策.还需要根据号码过滤政策
				BEGIN
					--若号码为预开,且绑定了政策,则删除非绑定的政策
					if isnull(@SeriesNumber,'')<>'' and exists(select 1 from @table a,T_PolicyGroup b where a.PackageType=b.PolicyGroupID and b.OpenAccount=1)
						BEGIN
							select @preallocation_PackageId=a.packageid
							  from seriespool a with(nolock) where a.SeriesNumber=@SeriesNumber
							  --若绑定了套包,则删除结果集中的其他套包
							  if isnull(@preallocation_PackageId,'')<>''
								BEGIN
									delete a from  @table a
									where a.packageid<>@preallocation_PackageId and a.OpenAccount=1
									--若删的没套包了,则说明不符合规则
									if not exists(select 1 from @table)
										BEGIN
											select @Preallocation_Name=packagename from policy_h ph with(nolock) where ph.DocCode=@preallocation_PackageId
											INSERT INTO @table(Seriescode,[STATE],Remark)  
											SELECT @Seriescode, 1,'您选择的号码'+@seriesnumber+'已绑定['+isnull(@Preallocation_Name,'')+']政策,与当前业务类型不符.'+dbo.crlf()+
											'请选择办理其他业务.'+dbo.crlf()+
											'若仍有疑问,请联系系统管理员.'+@Matgroup
											return
										END
								END
						END
				END
			return
		END
  RETURN   
 END
