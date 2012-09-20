/*  
* ��������:[fn_getPackageEX]  
* ��������:����������ȡ�װ�  
* ����:����������  
* ��д:���ϵ�  
* 2010/5/28  
* ��ע: ��ѯ�����Ƚ����뷭��MSDN��cross apply����
* ʾ��:select * from dbo.fn_getPackage('2010-06-07','2010-06-07','','','','')
*-------------------------------------------------------------------------------
*�޸�ʱ�䣺2012/04/11
*�޸��ˣ����ϵ�
*�޸�˵�����Դ˹��ܽ�����չ�������������������µ�����ѯ���������Ը�����Ʒ��Ϣ�������ߡ�
*��ע��ƥ�䷽ʽ�Ӵ�С��С�ķ�ʽ�����˲�ѯ
*ʾ����select * from dbo.fn_getPackageEX('2012-04-11','2012-04-11','','','','','','','','','','','��','','',1)
select * from dbo.fn_getPackageEX('2012-04-11','2012-04-11','','','','','769','','012379001816895','','','','��','','',1)
---------------------------------------------------------------------------------------------
*�޸�ʱ��:2012/07/25
*�޸���:���ϵ�
*�޸�˵��:�޸Ĳ��������߼�.�������˴�����Ϣʱ,��Ȼ���ſ��Թ������ŵ�,����,��˾��������Ʒ��Ϣ,��ֻ�е�������Щ��������δ����ʱ,
�ſ��ǽ����Ź�����������Ϣ���ǲ�����Ϣ,���򱣳ֲ�����Ϣ����,��ʹ������Ϣ�봮����Ϣ��һ��.
---------------------------------------------------------------------------------------------
*�޸�ʱ��:2012/09/01
*�޸���:���ϵ�
*�޸�˵��:����TAC��ƥ����ҵ������ƥ��.�����Ų��ڿ�ʱ��ƥ��TAC��.ͬʱ��ͬ��ҵ�����ͶԿ��Ҫ��Ҳ��ͬ,��Ҫ����ƥ��.
*����ҵ������޸Ĳ�����Χ.Լ������:
@AreaID:��Ϊ�ò���¼������ŵ���������.Ҳ�ɲ�¼.
@sdorgid:��Ϊ�ò���¼���Ҷ���ŵ����,���κ��ӽڵ�
@Matcode:Ϊ��,������
@Mattype:������
@Matgroup:������
@Valid:������
*/  
ALTER  FUNCTION [dbo].[fn_getPackageEX](  
	@begindate DATETIME,  
	@enddate DATETIME,  
	@PackageID  VARCHAR(50), 
	@PackageName VARCHAR(200),
	@PackageType VARCHAR(200), 
	@companyID VARCHAR(20),  
	@AreaID VARCHAR(20),  
	@sdorgid VARCHAR(30),
	@Seriescode VARCHAR(50),
	@Matcode VARCHAR(50),					--����ʹ��,��Ҫ��
	@Mattype VARCHAR(50),					--����ʹ��,��Ҫ��
	@Matgroup VARCHAR(50),					--����ʹ��,��Ҫ��
	@Valid VARCHAR(10),						--����ʹ��,��Ҫ��
	@InvalidParameter VARCHAR(50),			--ʧЧ�Ĳ���
	@Reserved VARCHAR(50),
	@BusiType VARCHAR(50),
	@OptionID varchar(100)
)    
RETURNS @table TABLE (  
	PackageID VARCHAR(20),						--���߱���
	PackageName VARCHAR(200),					--��������
	Busitype VARCHAR(200),						--��������
	begindate DATETIME,							--��ʼʱ��
	ENDDate DATETIME,							--����ʱ��
	CompanyID VARCHAR(100),						--��˾����
	CompanyName VARCHAR(200),					--��˾����
	AreaID VARCHAR(100),						--�������
	AreaName VARCHAR(200),						--��������
	SdorgID VARCHAR(500),						--���ű���
	SdorgName VARCHAR(200),						--��������
	Valid BIT,									--�Ƿ���Ч
	Reserved BIT,								--�Ƿ�ԤԼ�װ�
	STATE INT,									--״ֵ̬,��Ϊ1ʱ,������ʾ,��ֹ����,Ϊ2ʱ����ʾ�û�.
	Remark VARCHAR(500),						--��ע.��ʾ��Ϣ.��״̬Ϊ1ʱ������ʾ,��״̬Ϊ2ʱ,��ʾ�û�
	SeriesCode varchar(50),						--����
	Matcode VARCHAR(50),						--��Ʒ����
	MatName VARCHAR(100),						--��Ʒ����
	SalePrice Money,							--�ۼ�
	StockState varchar(20)						--���״̬
 )  
as    
 BEGIN  
 	DECLARE @stcode VARCHAR(50),@StockState VARCHAR(50),@SdorgID1 VARCHAR(50),@AreaID1 VARCHAR(50),@companyID1 VARCHAR(50)
 	DECLARE @OpenAccount BIT,@Old BIT,@hasPhone AS BIT,@hasBusiType BIT,@Rowcount INT,@busiTypeName VARCHAR(200),@StockState1 Varchar(50)
 	DECLARE @Matgroup1 VARCHAR(50),@MatName1 VARCHAR(100),@MatgroupName1 VARCHAR(100),@matcode1 VARCHAR(50),@MatName Varchar(200)
 	Declare @Occupyed Int,@saled Int 
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
 	--����У��,��ֹ�û��������Ʒ���벻��������Ĵ���,����ì�ܵĲ���
 	If Isnull(@Matcode,'')!='' And Isnull(@Matgroup1,'')!=''
 		BEGIN
 			If Not Exists(Select 1 From iMatGeneral img With(Nolock),iMatGroup img1 With(Nolock) Where img.MatGroup=img.MatGroup And img1.path Like '%/'+@Matgroup+'/%')
 				BEGIN
 					Insert into @table(Seriescode,[STATE],Remark)
 					Select @seriescode, 1,'�������Ʒ���벻������Ʒ����,���߳�ͻ,�޷�����ƥ��,��������ٲ���.'
 					return
 				END
 		End
 	--��������,��ֹ����Ĳ��Ų����ڹ�˾
	--�����Ų�Ϊ�գ���ȡ���ŵ���Ϣ
	IF ISNULL(@Seriescode,'')!='' 
		Begin
			--��ʼ�����״̬
			Select @StockState='��״̬',@Occupyed=0,@Saled=0
			--ȡ������Ϣ
			SELECT  @matcode1=matcode,@stcode=i.stcode,@StockState=i.[state],@Occupyed=Coalesce(Nullif(i.isava,0),Nullif(i.isbg,0),Nullif(i.Occupyed,0)),@saled=Isnull(i.salemun,0)
			From iSeries i
			WHERE i.SeriesCode=@Seriescode
			SELECT @Rowcount=@@ROWCOUNT
			--����ҵ������,���ж�ҵ�������봮��״̬�Ƿ�ƥ��
			If @hasBusiType=1
				BEGIN
					If @StockState1!='' And Not Exists(Select 1 From T_PolicyGroup pg With(Nolock) Outer Apply  commondb.dbo.[SPLIT](isnull(pg.StockState,'�ڿ�'),',') s 
					                                   Where s.List =@StockState 
					                                   And Isnull(pg.hasPhone,0)=1
					                                   And pg.[PATH] Like '%/'+@BusiType+'/%'
					)
					BEGIN
						Insert into @table(seriescode,[STATE],Remark)
						Select @Seriescode, 1,'�ն˿��״̬Ϊ['+case when @StockState='��״̬' then '�ǹ�˾��' else @StockState end +'],��������뵱ǰ�.'
						return
					END
					                                   
				End
			--�ж��Ƿ�ռ��
			/*If @Occupyed=1
				BEGIN
					Insert into @table(seriescode,[STATE],Remark)
					Select @Seriescode, 1,'���ն��ѱ���������ռ��,����������ն�.'
					return
				End*/
			--�����ն˱�ռ�û�����,��ҵ�����Ͳ��������ۻ���,���׳��쳣
			If @saled=1 Or @Occupyed=1
				BEGIN
					If Not Exists(Select 1 From T_PolicyGroup pg Outer Apply commondb.dbo.[SPLIT](Isnull(pg.StockState,'�ڿ�'),',') s 
									Where pg.[PATH] Like '%/'+@BusiType+'/%' 
									And s.List='����'
									And pg.hasPhone=1
					)
					Begin
						If @saled=1
							BEGIN
								Insert into @table(seriescode,[STATE],Remark)
								Select @Seriescode, 1,'���ն�����,���������'+case when isnull(@busiTypeName ,'')='' then '��' else @busiTypeName end +'��ҵ��.'
								return
							END
						If @Occupyed=1
							BEGIN
								Insert into @table(seriescode,[STATE],Remark)
								Select @Seriescode, 1,'���ն��ѱ�ռ��,���������'+case when isnull(@busiTypeName ,'')='' then '��' else @busiTypeName end +'��ҵ��.'
								return
								return
							END
					END
				END 
			--���û��ƥ�䵽����,�����TAC��ƥ��
			IF @ROWCOUNT=0 
				BEGIN
					--ƥ��TAC��,ֻƥ�����ƶ���ߵ�һ��.
					SELECT top 1  @Matgroup1=i.Matgroup,@MatgroupName1=i.MatgroupName
					FROM T_TACCode  i WITH(NOLOCK) WHERE PATINDEX(i.TACCode+'%',@Seriescode)>0
					order by len(i.taccode) desc
					SELECT @Rowcount=@@ROWCOUNT
					--����δƥ�䵽,��Ҫֱ���˳�����
					IF @ROWCOUNT=0
						BEGIN
							INSERT INTO @table(Seriescode,[STATE],Remark)  
							SELECT @Seriescode, 1,'���ն�δ��ͨ��TAC��У��,�����ն˴����Ƿ���ȷ,������¼�봮����в���.'+dbo.crlf()+
							'����������δ�õ�����볢�Ը����ն˲�����,����ϵϵͳ����Ա.'
							return
						End
					--����У��,��ֹ¼�����Ʒ���������TAC��ƥ��Ĵ��಻һ��
					If Isnull(@Matgroup1,'')!='' And Isnull(@Matgroup,'')!=''
						BEGIN
							If Not Exists(Select 1 From iMatGroup img With(Nolock) Where img.matgroup=@Matgroup And img.path Like '%/'+@Matgroup1+'/%')
							And Not Exists(Select 1 From iMatGroup img With(Nolock) Where img.matgroup=@Matgroup1 and img.[PATH] Like '%/'+@Matgroup+'/%')
								BEGIN
									Insert into @table([STATE],Remark)
 									Select 1,'�������Ʒ���벻������Ʒ����,���߳�ͻ,�޷�����ƥ��,��������ٲ���.'
 									return
								END
						END
					If Isnull(@Matcode,'')='' And Isnull(@Matgroup,'')='' 
						BEGIN
							Select @Matgroup=Isnull(@Matgroup1,'')
						End
					--��ȡ����
					INSERT INTO @table(PackageID,PackageName,Busitype,begindate,ENDDate,CompanyID,CompanyName,AreaID,AreaName,SdorgID,SdorgName,
					Reserved,[STATE],Matcode,MatName,StockState,saleprice)
					SELECT a.doccode,isnull(NULLIF(a.ExternalName,''), a.PackageName),a.PolicygroupID,a.begindate,a.enddate,a.companyid,a.companyname,a.areaid,a.areaName,a.SdOrgID,a.SdorgName,
					a.OnlyReservedCustomer,0,@matgroup1,@matgroupname1,@StockState,0
					FROM policy_h a  WITH(NOLOCK) inner join policy_d pd  WITH(NOLOCK) ON a.DocCode=pd.DocCode
					INNER JOIN T_PolicyGroup pg With(Nolock) ON a.PolicygroupID=pg.PolicyGroupID
					WHERE formid=9110  
					AND (@PackageID='' or a.DocCode=@PackageID)
					AND (@PackageName='' or a.PackageName LIKE '%'+@PackageName+'%')
					AND (@PackageType='' OR a.DocType=@PackageType)
					AND (@begindate='' OR a.begindate<=@begindate)
					AND (@enddate='' OR a.enddate>=@enddate)
					And a.actived=1
					And Isnull(pd.valid,0)=1
					And (Isnull(pd.beginDate,'')='' Or @begindate='' Or a.begindate<=@begindate)
					And (Isnull(pd.endDate,'')='' Or @enddate='' Or a.enddate>=@begindate)
					And pg.hasPhone=1																					--�������ֻ�
					AND (@BusiType=''
						--�������ҵ�����ͱ�����ҵ�����ͼ����ʱ,ƥ�䴫��ҵ�������²�����ҵ������,������Ϊ�װ������е�ҵ�����ͼ���ΪҶ�Ӽ���.
						OR  pg.[PATH] LIKE '%/'+@BusiType+'/%' )
					AND (@Reserved='' OR ISNULL(a.OnlyReservedCustomer,0)=CASE @Reserved WHEN '��' then 1 else 0 END)
					and exists(select 1 from commondb.dbo.split(isnull(pg.StockState,'�ڿ�'),',') where list in ('��״̬','����'))
					--ƥ�乫˾
					AND (@companyID=''  OR ISNULL(a.companyid,'')='' 
					--ֱ��ƥ�乫˾
					OR (ISNULL(a.companyid,'')!='' AND @companyID!='' -- AND ISNULL(a.sdorgid,'')=''
						AND  exists(select 1 from commondb.dbo.split(ISNULL(a.companyid,''),',') WHERE list=@companyID)
					)
					--����Ҳ���빫˾��أ������ٳ��ԴӲ����б���ȡ����˾��ƥ��
					--����˾��ϢΪ��ʱ,�ſ��ǴӲ�����Ϣ��ƥ�乫˾��Ϣ
					OR (isnull(a.sdorgid,'')!='' AND @companyID!=''  And Isnull(a.companyid,'')=''
						and EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.sdorgid,''),',') x 
									inner join osdorg y WITH(NOLOCK) on y.path like '%/'+x.list+'/%'
									inner join oPlantSDOrg os  WITH(NOLOCK) ON  x.list=os.SDOrgID 
									where os.PlantID=@companyID)
						)
					)
					
					--ƥ������
					AND (@AreaID='' Or Isnull(a.areaid,'')=''
							--ֱ��ƥ�����򣬲��ɰ����򼶱��ѯ
							OR (ISNULL(a.areaid,'')!='' AND @AreaID!='' --AND ISNULL(a.sdorgid,'')='' 
								AND (
										--�Ƚ�������Ϊ�ӽڵ�ƥ��.�������û��������������������е����򼶱��
										EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.areaid,''),',') x,gArea g  WITH(NOLOCK) WHERE g.areaid=@AreaID AND g.[PATH] LIKE '/%'+x.list+'/%')
								)
							)
							--�ٳ��ԴӲ���������ȡ������,�����ò������ڵ����������������ѯ.
							--��������δ��������ʱ,���ǴӲ���������ƥ��������Ϣ
							OR (ISNULL(a.sdorgid,'')!='' AND @AreaID!=''  And Isnull(a.areaid,'')=''
								AND (	
										 EXISTS(SELECT 1 FROM commondb.dbo.[Split](isnull(a.sdorgid,''),',') x inner join oSDOrg o WITH(NOLOCK)   on o.path LIKE '%/'+x.list+'/%' 
												where o.areaid=@AreaID)
								)
							)
					)
					--ƥ���ŵ�
					AND(@sdorgid=''
							--ƥ���ŵ꣬�����㼶ƥ��
							OR(ISNULL(a.sdorgid,'')!='' AND @sdorgid!='' 
								AND (
										--�Ƚ��ŵ���Ϊ�ӽڵ�ƥ��,�������������õ��ŵ꼶��Ȳ����е��ŵ꼶���
										EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.sdorgid,''),',') x,oSDOrg o  WITH(NOLOCK) WHERE o.SDOrgID=@sdorgid AND o.path LIKE '%/'+x.list+'/%')
								)
							)
							--��������δ�����ŵ�,���Դӹ�˾��ƥ����ŵ���Ϣ,������Ϊ������ŵ��������ڸ����㼶.
							Or (Isnull(a.sdorgid,'')='' And @sdorgid!='' And Isnull(a.companyid,'')!=''
								And (
									exists(Select 1 From commondb.dbo.[SPLIT](Isnull(a.companyid,''),',') s,oPlantSDOrg ops 
											 Where s.List=ops.PlantID 
											 And ops.SDOrgID=@sdorgid
									)
								)
							)
					)
	
					--and exists(select 1 from T_TACCode t,iMatGroup img where t.matgroup=img.matgroup and @Seriescode like t.taccode+'%' and img.PATH like '%/'+pd.matgroup+'/%')
					--ƥ����Ʒ����,���������������д��������
					And (@Matgroup!='' And Exists(Select 1 From iMatGroup img Where img.matgroup=@Matgroup And Path Like '%/'+pd.matgroup+'/%'))
					--��Ʒ��Ϣƥ��
					--And (@Matcode!='' or Isnull(pd.MatCode,'')='' Or pd.MatCode=@Matcode)
					Group By a.doccode,isnull(NULLIF(a.ExternalName,''), a.PackageName),a.PolicygroupID,a.begindate,a.enddate,a.companyid,a.companyname,a.areaid,a.areaName,a.SdOrgID,a.SdorgName,
					a.OnlyReservedCustomer
					--order by a.RecommendLevel desc
					IF @@ROWCOUNT=0
						BEGIN
							INSERT INTO @table(Seriescode,[STATE],Remark)  
							SELECT @Seriescode, 1,'���ն��в��ܰ���'+case when isnull(@busiTypeName ,'')='' then '��' else @busiTypeName end +'��ҵ��.'+
							'��ѡ������ҵ�����,��ѡ����������.'+@Matgroup
							return
						END
					return
				End
			--�����Ŵ���,��ȡ���˲ֿ���Ϣ,��Ӳֿ���Ϣ����������Ϣ
			IF ISNULL(@stcode,'')!=''
				BEGIN
					--��ȡ�����ţ�����͹�˾��Ϣ
					SELECT @sdorgid1=isnull(sdorgid,''),@AreaID1=ISNULL(AreaID,''),@companyID1=isnull(plantid,'') FROM oStorage o WITH(NOLOCK) WHERE o.stCode=@stcode
					--���
					IF @sdorgid!='' AND @sdorgid!=@SdorgID1
						Begin
							--���ֿ���Ϣ��һ��,����ҵ�����Ͳ�����ʹ�����ۻ�,���׳��쳣
							If Not Exists(Select 1 From T_PolicyGroup pg Outer Apply commondb.dbo.[SPLIT](Isnull(pg.StockState,'�ڿ�'),',') s Where s.list='����')
								begin
									Insert into @table(Seriescode,[STATE],Remark)
									Select @Seriescode,1,'���ն˲������ֿ�,�޷�����ҵ��,��ȷ�ϴ��ն��ѵ���.'
									Return
								end
						END
					--������,��˾,�������û��ʱ,�ͽ��ֿ���Ϣ��������Щ���������,���Ѿ���,�򲻸���
					Select @AreaID=@AreaID1,@companyID=@companyID1
					/*IF @sdorgid='' 	SELECT @sdorgid=@SdorgID1

					IF @AreaID='' AND @sdorgid='' SELECT @AreaID=@areaid1
					
					IF @companyID='' AND @sdorgid='' SELECT @companyID=@companyID1*/
				END
			--���д�����Ϣʱ,���ԴӴ�����Ϣ����������Ʒ��dϢ
			IF ISNULL(@Matcode1,'')!=''
				begin
					--��ȡ����Ʒ��Ϣ,���������������Щ��Ʒ��Ϣ,���Դ��Ź�������Ʒ��Ϣ����֮,�����Բ����е���Ʒ��ϢΪ׼
					SELECT @Matgroup=COALESCE(nullif(@Matgroup,''),ISNULL(ig.MatGroup,'')),@MatName=ig.matname,
					@Matcode=COALESCE(NULLIF(@Matcode,''),@Matcode1)
					 FROM iMatGeneral ig WITH(NOLOCK) WHERE ig.MatCode=@Matcode1
				end
			
			INSERT INTO @table(Seriescode,PackageID,PackageName,Busitype,begindate,ENDDate,CompanyID,CompanyName,AreaID,AreaName,SdorgID,SdorgName,
					Reserved,[STATE],Matcode,MatName,SalePrice,StockState) 
			SELECT @Seriescode,a.doccode,isnull(NULLIF(a.ExternalName,''), a.PackageName),a.PolicygroupID,a.begindate,a.enddate,a.companyid,a.companyname,a.areaid,a.areaName,a.SdOrgID,a.SdorgName,
			a.OnlyReservedCustomer,0,@matcode,@MatName,ss.saleprice,@StockState
			FROM policy_h a  WITH(NOLOCK) inner join policy_d pd  WITH(NOLOCK) ON a.DocCode=pd.DocCode
			INNER JOIN T_PolicyGroup pg ON a.PolicygroupID=pg.PolicyGroupID
			Outer Apply dbo.uf_salesSDOrgpricecalcu3(@Matcode,@sdorgid,@Seriescode) ss
			WHERE formid=9110  
			AND (@PackageID='' or a.DocCode=@PackageID)
			AND (@PackageName='' or a.PackageName LIKE '%'+@PackageName+'%')
			AND (@PackageType='' OR a.DocType=@PackageType)
			AND (@begindate='' OR a.begindate<=@begindate)
			AND (@enddate='' OR a.enddate>=@enddate)
			And a.Actived=1
			And Isnull(pd.valid,0)=1
			And (Isnull(pd.beginDate,'')='' Or @begindate='' Or a.begindate<=@begindate)
			And (Isnull(pd.endDate,'')='' Or @enddate='' Or a.enddate>=@begindate)
			And pg.hasPhone=1																		--�������ֻ�
			AND (@BusiType=''
				--�������ҵ�����ͱ�����ҵ�����ͼ����ʱ,ƥ�䴫��ҵ�������²�����ҵ������,������Ϊ�װ������е�ҵ�����ͼ���ΪҶ�Ӽ���.
				OR  pg.[PATH] LIKE '%/'+@BusiType+'/%' )
			AND (@Reserved='' OR ISNULL(a.OnlyReservedCustomer,0)=CASE @Reserved WHEN '��' then 1 else 0 END)
			--AND isnull(pd.inStock,'�ڿ�') in('�ڿ�','Ӧ��')
			And (Exists(Select 1 From commondb.dbo.[SPLIT](isnull(pg.StockState,''),',') s Where s.List=@StockState))
			--ƥ�乫˾
			AND (@companyID=''  OR ISNULL(a.companyid,'')='' 
			--ֱ��ƥ�乫˾
			OR (ISNULL(a.companyid,'')!='' AND @companyID!=''  --AND ISNULL(a.sdorgid,'')=''
				AND  exists(select 1 from commondb.dbo.split(ISNULL(a.companyid,''),',') WHERE list=@companyID)
			)
			--����Ҳ���빫˾��أ������ٳ��ԴӲ����б���ȡ����˾��ƥ��
			--����˾��ϢΪ��ʱ,�ſ��ǴӲ�����Ϣ��ƥ�乫˾��Ϣ
			OR (isnull(a.sdorgid,'')!='' AND @companyID!=''  And Isnull(a.companyid,'')=''
				and EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.sdorgid,''),',') x 
							inner join osdorg y WITH(NOLOCK) on y.path like '%/'+x.list+'/%'
							inner join oPlantSDOrg os  WITH(NOLOCK) ON  x.list=os.SDOrgID 
							where os.PlantID=@companyID)
				)
			)
			
			--ƥ������
			AND (@AreaID='' Or Isnull(a.areaid,'')=''
					--ֱ��ƥ�����򣬲��ɰ����򼶱��ѯ
					OR (ISNULL(a.areaid,'')!='' AND @AreaID!='' --AND ISNULL(a.sdorgid,'')='' 
						AND (
								--�Ƚ�������Ϊ�ӽڵ�ƥ��.�������û��������������������е����򼶱��
								EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.areaid,''),',') x,gArea g  WITH(NOLOCK) WHERE g.areaid=@AreaID AND g.[PATH] LIKE '/%'+x.list+'/%')
						)
					)
					--�ٳ��ԴӲ���������ȡ������,�����ò������ڵ����������������ѯ.
					--��������δ��������ʱ,���ǴӲ���������ƥ��������Ϣ
					OR (ISNULL(a.sdorgid,'')!='' AND @AreaID!=''  And Isnull(a.areaid,'')=''
						AND (	
								 EXISTS(SELECT 1 FROM commondb.dbo.[Split](isnull(a.sdorgid,''),',') x inner join oSDOrg o WITH(NOLOCK)   on o.path LIKE '%/'+x.list+'/%' 
										where o.areaid=@AreaID)
						)
					)
			)
			--ƥ���ŵ�
			AND(@sdorgid=''
					--ƥ���ŵ꣬�����㼶ƥ��
					OR(ISNULL(a.sdorgid,'')!='' AND @sdorgid!='' 
						AND (
								--�Ƚ��ŵ���Ϊ�ӽڵ�ƥ��,�������������õ��ŵ꼶��Ȳ����е��ŵ꼶���
								EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.sdorgid,''),',') x,oSDOrg o  WITH(NOLOCK) WHERE o.SDOrgID=@sdorgid AND o.path LIKE '%/'+x.list+'/%')
						)
					)
					--��������δ�����ŵ�,���Դӹ�˾��ƥ����ŵ���Ϣ,������Ϊ������ŵ��������ڸ����㼶.
					Or (Isnull(a.sdorgid,'')='' And @sdorgid!='' And Isnull(a.companyid,'')!=''
						And (
							exists(Select 1 From commondb.dbo.[SPLIT](Isnull(a.companyid,''),',') s,oPlantSDOrg ops 
									 Where s.List=ops.PlantID 
									 And ops.SDOrgID=@sdorgid
							)
						)
					)
			)
			--ƥ����Ʒ����,���������������д��������
			And (@Matgroup!='' And Exists(Select 1 From iMatGroup img Where img.matgroup=@Matgroup And Path Like '%/'+pd.matgroup+'/%'))
			--��Ʒ��Ϣƥ��
			And (@Matcode!='' or Isnull(pd.MatCode,'')='' Or pd.MatCode=@Matcode)
			Group By a.doccode,Isnull(Nullif(a.ExternalName, ''), a.PackageName),a.PolicygroupID,a.begindate,a.enddate,a.companyid,a.companyname,a.areaid,a.areaName,a.SdOrgID,a.SdorgName,
			a.OnlyReservedCustomer,ss.saleprice
			--order by a.RecommendLevel desc
			IF @@ROWCOUNT=0
				BEGIN
					INSERT INTO @table(Seriescode,[STATE],Remark)  
					SELECT @Seriescode,1,'���ն��в��ܰ���'+case when isnull(@busiTypeName ,'')='' then '��' else @busiTypeName end +'��ҵ��.'+
					'��ѡ������ҵ�����,��ѡ����������.'
					return
				END
			return
		END
	ELSE
	Begin
			
			--ûδ¼�봮��ʱ,����ᴮ��
			INSERT INTO @table(PackageID,PackageName,Busitype,begindate,ENDDate,CompanyID,CompanyName,AreaID,AreaName,SdorgID,SdorgName,
					Reserved,[STATE])
			SELECT a.doccode,isnull(NULLIF(a.ExternalName,''), a.PackageName),a.PolicygroupID,
			a.begindate,a.enddate,a.companyid,a.companyname,a.areaid,a.areaName,a.SdOrgID,a.SdorgName,
			a.OnlyReservedCustomer,0
			FROM policy_h a  WITH(NOLOCK) --inner join policy_d pd  WITH(NOLOCK) ON a.DocCode=pd.DocCode
			INNER JOIN T_PolicyGroup pg ON a.PolicygroupID=pg.PolicyGroupID
			WHERE formid=9110  
			AND (@PackageID='' or a.DocCode=@PackageID)
			AND (@PackageName='' or a.PackageName LIKE '%'+@PackageName+'%')
			AND (@PackageType='' OR a.DocType=@PackageType)
			AND (@begindate='' OR a.begindate<=@begindate)
			AND (@enddate='' OR a.enddate>=@enddate)
			and ((@Reserved='' and isnull(a.OnlyReservedCustomer,0)=0) or @Reserved<>'' )					--����ԤԼ���ʱ�ų���ԤԼ�װ�,���򲻳���ԤԼ�װ�.
			And a.actived=1
			And Isnull(pg.hasPhone,0)=0
			AND (@BusiType=''
				--�������ҵ�����ͱ�����ҵ�����ͼ����ʱ,ƥ�䴫��ҵ�������²�����ҵ������,������Ϊ�װ������е�ҵ�����ͼ���ΪҶ�Ӽ���.
				OR  pg.[PATH] LIKE '%/'+@BusiType+'/%' )
			AND (@Reserved='' OR ISNULL(a.OnlyReservedCustomer,0)=CASE @Reserved WHEN '��' then 1 else 0 END)
			--ƥ�乫˾
			AND (@companyID=''  OR ISNULL(a.companyid,'')='' 
					--ֱ��ƥ�乫˾
					OR (ISNULL(a.companyid,'')!='' AND @companyID!=''  --AND ISNULL(a.sdorgid,'')=''
						AND  exists(select 1 from commondb.dbo.split(ISNULL(a.companyid,''),',') WHERE list=@companyID)
					)
					--����Ҳ���빫˾��أ������ٳ��ԴӲ����б���ȡ����˾��ƥ��
					--����˾��ϢΪ��ʱ,�ſ��ǴӲ�����Ϣ��ƥ�乫˾��Ϣ
					OR (isnull(a.sdorgid,'')!='' AND @companyID!=''  And Isnull(a.companyid,'')=''
						and EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.sdorgid,''),',') x 
									inner join osdorg y WITH(NOLOCK) on y.path like '%/'+x.list+'/%'
									inner join oPlantSDOrg os  WITH(NOLOCK) ON  x.list=os.SDOrgID 
									where os.PlantID=@companyID)
						)
			)
			
			--ƥ������
			AND (@AreaID='' Or Isnull(a.areaid,'')=''
					--ֱ��ƥ�����򣬲��ɰ����򼶱��ѯ
					OR (ISNULL(a.areaid,'')!='' AND @AreaID!='' --AND ISNULL(a.sdorgid,'')='' 
						AND (
								--�Ƚ�������Ϊ�ӽڵ�ƥ��.�������û��������������������е����򼶱��
								EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.areaid,''),',') x,gArea g  WITH(NOLOCK) WHERE g.areaid=@AreaID AND g.[PATH] LIKE '/%'+x.list+'/%')
						)
					)
					--�ٳ��ԴӲ���������ȡ������,�����ò������ڵ����������������ѯ.
					--��������δ��������ʱ,���ǴӲ���������ƥ��������Ϣ
					OR (ISNULL(a.sdorgid,'')!='' AND @AreaID!=''  And Isnull(a.areaid,'')=''
						AND (	
								 EXISTS(SELECT 1 FROM commondb.dbo.[Split](isnull(a.sdorgid,''),',') x inner join oSDOrg o WITH(NOLOCK)   on o.path LIKE '%/'+x.list+'/%' 
										where o.areaid=@AreaID)
						)
					)
			)
			--ƥ���ŵ�
			AND(@sdorgid=''
					--ƥ���ŵ꣬�����㼶ƥ��
					OR(ISNULL(a.sdorgid,'')!='' AND @sdorgid!='' 
						AND (
								--�Ƚ��ŵ���Ϊ�ӽڵ�ƥ��,�������������õ��ŵ꼶��Ȳ����е��ŵ꼶���
								EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.sdorgid,''),',') x,oSDOrg o  WITH(NOLOCK) WHERE o.SDOrgID=@sdorgid AND o.path LIKE '%/'+x.list+'/%')
								 
						)
					)
					--��������δ�����ŵ�,���Դӹ�˾��ƥ����ŵ���Ϣ,������Ϊ������ŵ��������ڸ����㼶.
					Or (Isnull(a.sdorgid,'')='' And @sdorgid!='' And Isnull(a.companyid,'')!=''
						And (
							exists(Select 1 From commondb.dbo.[SPLIT](Isnull(a.companyid,''),',') s,oPlantSDOrg ops 
									 Where s.List=ops.PlantID 
									 And ops.SDOrgID=@sdorgid
							)
						)
					)
			)
			--ƥ����Ʒ����,���������������д��������
			/*And (@Matgroup!='' And Exists(Select 1 From iMatGroup img Where img.matgroup=@Matgroup And Path Like '%/'+pd.matgroup+'/%'))
			--��Ʒ��Ϣƥ��
			And (@Matcode!='' or Isnull(pd.MatCode,'')='' Or pd.MatCode=@Matcode)*/
			Group By a.doccode,Isnull(Nullif(a.ExternalName, ''), a.PackageName),a.PolicygroupID,a.begindate,a.enddate,a.companyid,a.companyname,a.areaid,a.areaName,a.SdOrgID,a.SdorgName,
			a.OnlyReservedCustomer
			--order by a.RecommendLevel desc
			IF @@ROWCOUNT=0
				BEGIN
					INSERT INTO @table(Seriescode,[STATE],Remark)  
					SELECT @Seriescode,1,'���в��ܰ���'+case when isnull(@busiTypeName ,'')='' then '��' else @busiTypeName end +'��ҵ��.'+
					'��ѡ������ҵ�����'
					return
				END
			return
			return
		END
  RETURN   
 END