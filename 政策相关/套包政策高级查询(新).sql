/*  
* ��������:[[fn_getPackageEXEX]]  
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
*--------------------------------------------------------------------------------
*�޸�ʱ��:2012/10/22
*�޸���:���ϵ�
*�޸�˵��:�����޸Ĵ˺���.���˺�����fn_getPackageEX��ֲ����,���ҽ����˴���������.
*ʾ����select * from dbo.[fn_getPackageEXEX]('2012-04-11','2012-04-11','','','','','','','8986011285100820499','','','','��','','')
select * from dbo.[fn_getPackageEXEX]('2012-04-11','2012-04-11','','','','','769','','','','','','��','','')
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
	PackageID VARCHAR(20),							--���߱���
	PackageName VARCHAR(200),					--��������
	ExternalName varchar(200),						--�ŵ���ʾ����
	PackageType VARCHAR(200),						--��������
	PackageTypeName varchar(200),					--�װ���������
	begindate DATETIME,									--��ʼʱ��
	ENDDate DATETIME,									--����ʱ��
	CompanyID VARCHAR(100),						--��˾����
	CompanyName VARCHAR(200),					--��˾����
	AreaID VARCHAR(100),								--�������
	AreaName VARCHAR(200),							--��������
	SdorgID VARCHAR(500),								--���ű���
	SdorgName VARCHAR(200),						--��������
	Valid BIT,													--�Ƿ���Ч
	Reserved BIT,											--�Ƿ�ԤԼ�װ�
	STATE INT,												--״ֵ̬,��Ϊ1ʱ,������ʾ,��ֹ����,Ϊ2ʱ����ʾ�û�.
	Remark VARCHAR(500),								--��ע.��ʾ��Ϣ.��״̬Ϊ1ʱ������ʾ,��״̬Ϊ2ʱ,��ʾ�û�
	SeriesCode varchar(50),								--����
	Matcode VARCHAR(50),								--��Ʒ����
	MatName VARCHAR(100),							--��Ʒ����
	SalePrice Money,										--�ۼ�
	StockState varchar(20),								--���״̬
	OpenAccount bit										--�Ƿ񿪻�
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
							Select @Matgroup=Isnull(@Matgroup1,''),@matcode=''
						End
					--��ȡ����
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
					and  (@valid in('','��')  or (@Valid in('��') and  a.DocStatus<>0))															--����Ҫ������Ϊ��Чʱ,��Ҫ������״̬Ϊ��ȷ��
					AND (@PackageID='' or a.DocCode=@PackageID)
					AND (@PackageName='' or @PackageID!='' or  (@PackageID='' and a.PackageName LIKE '%'+@PackageName+'%'))				--�����װ�����Ϊ��ʱ,�Ų�ѯ�װ�����
					AND (@ExternalName='' or @PackageID!='' or (@PackageID='' and a.ExternalName LIKE '%'+@ExternalName+'%'))				--�����װ�����Ϊ��ʱ,�Ų�ѯ�ŵ���ʾ����
					AND (@begindate='' OR a.begindate<=@begindate)
					AND (@enddate='' OR a.enddate>=@enddate)
					And (@Valid='' or  a.actived= case when @Valid ='��' then 1 when @valid='��' then 0 end )
					And Isnull(pd.valid,0)=1
					And (Isnull(pd.beginDate,'')='' Or @begindate='' Or pd.begindate<=@begindate)
					And (Isnull(pd.endDate,'')='' Or @enddate='' Or pd.enddate>=@endDate)
					And pg.hasPhone=1																					--�������ֻ�
					AND (@BusiType=''
							--�������ҵ�����ͱ�����ҵ�����ͼ����ʱ,ƥ�䴫��ҵ�������²�����ҵ������,������Ϊ�װ������е�ҵ�����ͼ���ΪҶ�Ӽ���.
							OR  pg.[PATH] LIKE '%/'+@BusiType+'/%' )
						AND (@Reserved in('��') or (@Reserved in('','��') and ISNULL(a.OnlyReservedCustomer,0)=0) )-- OR ISNULL(a.OnlyReservedCustomer,0)=CASE @Reserved WHEN '��' then 1 else 0 END)
						and exists(select 1 from commondb.dbo.split(isnull(pg.StockState,'�ڿ�'),',') where list in ('��״̬','����'))
						--ƥ�乫˾
					AND (@companyID=''  OR (ISNULL(a.companyid,'')=''  and isnull(a.sdorgid,'')='')
							--ֱ��ƥ�乫˾
							OR (ISNULL(a.companyid,'')!='' AND @companyID!=''  --AND ISNULL(a.sdorgid,'')=''
								AND  exists(select 1 from commondb.dbo.split(ISNULL(a.companyid,''),',') WHERE list=@companyID)
							)
							--����Ҳ���빫˾��أ������ٳ��ԴӲ����б���ȡ����˾��ƥ��
							--����˾��ϢΪ��ʱ,�ſ��ǴӲ�����Ϣ��ƥ�乫˾��Ϣ.ֻƥ�������в��ŵ��Ӽ�,��ƥ�������в��ŵĸ���.��Ϊʵ����һ�����ŵĸ���,�Ӽ�����ͬһ����˾.
							OR (isnull(a.sdorgid,'')!='' AND @companyID!=''  And Isnull(a.companyid,'')=''
								and EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.sdorgid,''),',') x 
											inner join osdorg y WITH(NOLOCK) on y.path like '%/'+x.list+'/%'
											inner join oPlantSDOrg os  WITH(NOLOCK) ON  y.sdorgid=os.SDOrgID 
											where os.PlantID=@companyID)
								)
					)
					
					--ƥ������
					AND (
							--���������Ϊ��,�򲻽�������ƥ����
							@AreaID=''	
							--ֱ��ƥ�����򣬲��ɰ����򼶱��ѯ
							OR (ISNULL(a.areaid,'')!='' AND @AreaID!='' --AND ISNULL(a.sdorgid,'')='' 
								AND (
										--�Ƚ�������Ϊ�ӽڵ�ƥ��.�������û��������������������е����򼶱��
										EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.areaid,''),',') x,gArea g  WITH(NOLOCK) WHERE g.areaid=@AreaID AND g.[PATH] LIKE '/%'+x.list+'/%')
										--�ٽ�������Ϊ���ڵ�ƥ��.�������û��������������������е����򼶱��.
										or EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.areaid,''),',') x,gArea g  WITH(NOLOCK) WHERE g.areaid=x.List AND g.[PATH] LIKE '/%'+@AreaID+'/%')
								))
							--����Ҳ���������,��δ��������,�������˲���,�����ԴӲ��Ż�ȡ������Ϣ����ƥ��
								or (isnull(a.areaid,'')='' and @AreaID!='' and isnull(a.sdorgid,'')!=''
									AND(
										--��������Ϊ���ڵ�ƥ��.�������û��������������������е����򼶱��. 
										EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.sdorgid,''),',') x,gArea g  WITH(NOLOCK),oSDOrg os with(nolock) 
														WHERE os.path like '%/'+x.List+'/%'									--�������ż����Ӳ��� 
														and os.AreaID=g.areaid
														AND g.[PATH] LIKE '%/'+@AreaID+'/%')								--��Ϊ�Ѿ��������������õĲ��ż����Ӳ���,�������������Ҳƥ�������ŵ������.����Ҫ�ٽ�������Ϊ�ӽڵ����ƥ��.
										)
								)
							--�������в��ź�����Ϊ��,���ʾ�������򶼿���.
							or (isnull(a.areaid,'')='' and isnull(a.sdorgid,'')='')
					)
					--ƥ���ŵ�
					AND(@sdorgid='' or (isnull(a.sdorgid,'')='' and isnull(a.companyid,'')='')
							--ƥ���ŵ꣬�����㼶ƥ��
							OR(ISNULL(a.sdorgid,'')!='' AND @sdorgid!='' 
								AND (
										--�Ƚ��ŵ���Ϊ�ӽڵ�ƥ��,�������������õ��ŵ꼶��Ȳ����е��ŵ꼶���
										EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.sdorgid,''),',') x,oSDOrg o  WITH(NOLOCK) WHERE o.SDOrgID=@sdorgid AND o.path LIKE '%/'+x.list+'/%')
										 --�Ƚ��ŵ���Ϊ�ӽڵ�ƥ��,�������������õ��ŵ꼶��Ȳ����е��ŵ꼶���
										or EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.sdorgid,''),',') x,oSDOrg o  WITH(NOLOCK) WHERE o.SDOrgID=x.List AND o.path LIKE '%/'+@sdorgid+'/%')
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
					--��Ʒ��Ϣƥ��
					--And (@Matcode!='' or Isnull(pd.MatCode,'')='' Or pd.MatCode=@Matcode)
					Group By a.doccode, a.PackageName,a.ExternalName,a.PolicygroupID,a.DocType,a.begindate,a.enddate,a.companyid,a.companyname,a.areaid,a.areaName,a.SdOrgID,a.SdorgName,
					a.OnlyReservedCustomer,coalesce(psld.matcode,pd.matcode,@matgroup1,pd.matgroup),coalesce(psld.mattype, psld.matname,pd.MatName,@MatgroupName1,pd.matgroupname),
					isnull(pg.OpenAccount,0),isnull(a.actived,0),a.hdmemo
					--order by a.RecommendLevel desc
					IF @@ROWCOUNT=0
						BEGIN
							INSERT INTO @table(Seriescode,[STATE],Remark)  
							SELECT @Seriescode, 1,'���ն��в��ܰ���'+case when isnull(@busiTypeName ,'')='' then '��' else @busiTypeName end +'��ҵ��.'+
							'��ѡ������ҵ�����,��ѡ����������.'
							return
						END
					else
						------��ƥ�䵽������,����Ҫ�ж��Ƿ�Ԥ�������Ұ�������.����Ҫ���ݺ����������
						BEGIN
							--������ΪԤ��,�Ұ�������,��ɾ���ǰ󶨵�����
							if isnull(@SeriesNumber,'')<>'' and exists(select 1 from @table a  where OpenAccount=1)					--�˴����ж��Ƿ������������.��������������ִ����.
								BEGIN
									select @preallocation_PackageId=a.packageid
									  from seriespool a with(nolock) where a.SeriesNumber=@SeriesNumber
									  --�������װ�,��ɾ��������е������װ�
									  if isnull(@preallocation_PackageId,'')<>''
										BEGIN
											delete a from  @table a
											where a.packageid<>@preallocation_PackageId and a.OpenAccount=1								--�˴�ֻɾ������������.
											--��ɾ��û�װ���,��˵�������Ϲ���
											if not exists(select 1 from @table)
												BEGIN
													select @Preallocation_Name=packagename from policy_h ph with(nolock) where ph.DocCode=@preallocation_PackageId
													INSERT INTO @table(Seriescode,[STATE],Remark)  
													SELECT @Seriescode, 1,'��ѡ��ĺ���'+@seriesnumber+'�Ѱ�['+isnull(@Preallocation_Name,'')+']����,�뵱ǰҵ�����Ͳ���.'+dbo.crlf()+
													'������ʹ�õĻ����޷����������,�볢�Ը�����������,���������ҵ��.'+dbo.crlf()+
													'����������,����ϵϵͳ����Ա.' 
													return
												END
										END
								END
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
							--�����ڿ�Ļ�,��������ŵ�ʹ��
							if @StockState in('�ڿ�','Ӧ��')
								BEGIN
									if NOT EXISTS (select 1 from StorageConfig sc,oStorage os where sc.pubstcode=@stcode  and sc.stcode=os.stCode and os.sdorgid=@sdorgid)
										BEGIN
											Insert into @table(Seriescode,[STATE],Remark)
											Select @Seriescode,1,'���ն˲������ֿ�,�޷�����ҵ��,��ȷ�ϴ��ն��ѵ���.'
											return
										END
								END
							
							--���ֿ���Ϣ��һ��,����ҵ�����Ͳ�����ʹ�����ۻ�,���׳��쳣
							/*If Not Exists(Select 1 From T_PolicyGroup pg Outer Apply commondb.dbo.[SPLIT](Isnull(pg.StockState,'�ڿ�'),',') s Where s.list='����')
								begin
									Insert into @table(Seriescode,[STATE],Remark)
									Select @Seriescode,1,'���ն˲������ֿ�,�޷�����ҵ��,��ȷ�ϴ��ն��ѵ���.'
									Return
								end*/
						END
					--������,��˾,�������û��ʱ,�ͽ��ֿ���Ϣ��������Щ���������,���Ѿ���,�򲻸���
					--Select @AreaID=@AreaID1,@companyID=@companyID1
					IF @sdorgid='' 	SELECT @sdorgid=@SdorgID1

					IF @AreaID='' AND @sdorgid='' SELECT @AreaID=@areaid1
					
					IF @companyID='' AND @sdorgid='' SELECT @companyID=@companyID1
				END
			--���д�����Ϣʱ,���ԴӴ�����Ϣ����������Ʒ��dϢ
			IF ISNULL(@Matcode1,'')!=''
				begin
					--��ȡ����Ʒ��Ϣ,���������������Щ��Ʒ��Ϣ,���Դ��Ź�������Ʒ��Ϣ����֮,�����Բ����е���Ʒ��ϢΪ׼
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
			AND (@PackageName='' or @PackageID!='' or  (@PackageID='' and a.PackageName LIKE '%'+@PackageName+'%'))				--�����װ�����Ϊ��ʱ,�Ų�ѯ�װ�����
			AND (@ExternalName='' or @PackageID!='' or (@PackageID='' and a.ExternalName LIKE '%'+@ExternalName+'%'))				--�����װ�����Ϊ��ʱ,�Ų�ѯ�ŵ���ʾ����
			AND (@begindate='' OR a.begindate<=@begindate)
			AND (@enddate='' OR a.enddate>=@enddate)
			And (@Valid='' or  a.actived= case when @Valid ='��' then 1 when @valid='��' then 0 end )
			and  (@valid in('','��')  or (@Valid in('��') and  a.DocStatus<>0))															--����Ҫ������Ϊ��Чʱ,��Ҫ������״̬Ϊ��ȷ��
			And Isnull(pd.valid,0)=1
			And (Isnull(pd.beginDate,'')='' Or @begindate='' Or pd.begindate<=@begindate)
			And (Isnull(pd.endDate,'')='' Or @enddate='' Or pd.enddate>=@begindate)
			And pg.hasPhone=1																		--�������ֻ�
			AND (@BusiType=''
				--�������ҵ�����ͱ�����ҵ�����ͼ����ʱ,ƥ�䴫��ҵ�������²�����ҵ������,������Ϊ�װ������е�ҵ�����ͼ���ΪҶ�Ӽ���.
				OR  pg.[PATH] LIKE '%/'+@BusiType+'/%' )
			AND (@Reserved in('��') or (@Reserved in('','��') and ISNULL(a.OnlyReservedCustomer,0)=0) )
			--AND isnull(pd.inStock,'�ڿ�') in('�ڿ�','Ӧ��')
			And (Exists(Select 1 From commondb.dbo.[SPLIT](isnull(pg.StockState,''),',') s Where s.List=@StockState))
			--ƥ�乫˾
			AND (@companyID=''  OR (ISNULL(a.companyid,'')=''  and isnull(a.sdorgid,'')='')
					--ֱ��ƥ�乫˾
					OR (ISNULL(a.companyid,'')!='' AND @companyID!=''  --AND ISNULL(a.sdorgid,'')=''
						AND  exists(select 1 from commondb.dbo.split(ISNULL(a.companyid,''),',') WHERE list=@companyID)
					)
					--����Ҳ���빫˾��أ������ٳ��ԴӲ����б���ȡ����˾��ƥ��
					--����˾��ϢΪ��ʱ,�ſ��ǴӲ�����Ϣ��ƥ�乫˾��Ϣ.ֻƥ�������в��ŵ��Ӽ�,��ƥ�������в��ŵĸ���.��Ϊʵ����һ�����ŵĸ���,�Ӽ�����ͬһ����˾.
					OR (isnull(a.sdorgid,'')!='' AND @companyID!=''  And Isnull(a.companyid,'')=''
						and EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.sdorgid,''),',') x 
									inner join osdorg y WITH(NOLOCK) on y.path like '%/'+x.list+'/%'
									inner join oPlantSDOrg os  WITH(NOLOCK) ON  y.sdorgid=os.SDOrgID 
									where os.PlantID=@companyID)
						)
			)
			
			--ƥ������
			AND (
					--���������Ϊ��,�򲻽�������ƥ����
					@AreaID=''	
					--ֱ��ƥ�����򣬲��ɰ����򼶱��ѯ
					OR (ISNULL(a.areaid,'')!='' AND @AreaID!='' --AND ISNULL(a.sdorgid,'')='' 
						AND (
								--�Ƚ�������Ϊ�ӽڵ�ƥ��.�������û��������������������е����򼶱��
								EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.areaid,''),',') x,gArea g  WITH(NOLOCK) WHERE g.areaid=@AreaID AND g.[PATH] LIKE '/%'+x.list+'/%')
								--�ٽ�������Ϊ���ڵ�ƥ��.�������û��������������������е����򼶱��.
								or EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.areaid,''),',') x,gArea g  WITH(NOLOCK) WHERE g.areaid=x.List AND g.[PATH] LIKE '/%'+@AreaID+'/%')
						))
					--����Ҳ���������,��δ��������,�������˲���,�����ԴӲ��Ż�ȡ������Ϣ����ƥ��
						or (isnull(a.areaid,'')='' and @AreaID!='' and isnull(a.sdorgid,'')!=''
							AND(
								--��������Ϊ���ڵ�ƥ��.�������û��������������������е����򼶱��. 
								EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.sdorgid,''),',') x,gArea g  WITH(NOLOCK),oSDOrg os with(nolock) 
												WHERE os.path like '%/'+x.List+'/%'									--�������ż����Ӳ��� 
												and os.AreaID=g.areaid
												AND g.[PATH] LIKE '%/'+@AreaID+'/%')								--��Ϊ�Ѿ��������������õĲ��ż����Ӳ���,�������������Ҳƥ�������ŵ������.����Ҫ�ٽ�������Ϊ�ӽڵ����ƥ��.
								)
						)
					--�������в��ź�����Ϊ��,���ʾ�������򶼿���.
					or (isnull(a.areaid,'')='' and isnull(a.sdorgid,'')='')
			)
			--ƥ���ŵ�
			AND(@sdorgid='' or (isnull(a.sdorgid,'')='' and isnull(a.companyid,'')='')
					--ƥ���ŵ꣬�����㼶ƥ��
					OR(ISNULL(a.sdorgid,'')!='' AND @sdorgid!='' 
						AND (
								--�Ƚ��ŵ���Ϊ�ӽڵ�ƥ��,�������������õ��ŵ꼶��Ȳ����е��ŵ꼶���
								EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.sdorgid,''),',') x,oSDOrg o  WITH(NOLOCK) WHERE o.SDOrgID=@sdorgid AND o.path LIKE '%/'+x.list+'/%')
								 --�Ƚ��ŵ���Ϊ�ӽڵ�ƥ��,�������������õ��ŵ꼶��Ȳ����е��ŵ꼶���
								or EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.sdorgid,''),',') x,oSDOrg o  WITH(NOLOCK) WHERE o.SDOrgID=x.List AND o.path LIKE '%/'+@sdorgid+'/%')
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
			--��Ʒ��Ϣƥ��
			And (@Matcode!='' or Isnull(pd.MatCode,'')='' Or pd.MatCode=@Matcode)
			Group By a.doccode,  a.PackageName,a.ExternalName,a.PolicygroupID,a.DocType,a.begindate,a.enddate,a.companyid,a.companyname,a.areaid,a.areaName,a.SdOrgID,a.SdorgName,
			a.OnlyReservedCustomer,isnull(pg.OpenAccount,0),isnull(a.actived,0),a.hdmemo
			--order by a.RecommendLevel desc
			IF @@ROWCOUNT=0
				BEGIN
					INSERT INTO @table(Seriescode,[STATE],Remark)  
					SELECT @Seriescode,1,'���ն��в��ܰ���'+case when isnull(@busiTypeName ,'')='' then '��' else @busiTypeName end +'��ҵ��.'+
					'��ѡ������ҵ�����,��ѡ����������.'
					return
				END
			else
				------��ƥ�䵽������,����Ҫ�ж��Ƿ�Ԥ�������Ұ�������.����Ҫ���ݺ����������
						BEGIN
							--������ΪԤ��,�Ұ�������,��ɾ���ǰ󶨵�����
							if isnull(@SeriesNumber,'')<>'' and exists(select 1 from @table a  where OpenAccount=1)					--�˴����ж��Ƿ������������.��������������ִ����.
								BEGIN
									select @preallocation_PackageId=a.packageid
									  from seriespool a with(nolock) where a.SeriesNumber=@SeriesNumber
									  --�������װ�,��ɾ��������е������װ�
									  if isnull(@preallocation_PackageId,'')<>''
										BEGIN
											delete a from  @table a
											where a.packageid<>@preallocation_PackageId and a.OpenAccount=1								--�˴�ֻɾ������������.
											--��ɾ��û�װ���,��˵�������Ϲ���
											if not exists(select 1 from @table)
												BEGIN
													select @Preallocation_Name=packagename from policy_h ph with(nolock) where ph.DocCode=@preallocation_PackageId
													INSERT INTO @table(Seriescode,[STATE],Remark)  
													SELECT @Seriescode, 1,'��ѡ��ĺ���'+@seriesnumber+'�Ѱ�['+isnull(@Preallocation_Name,'')+']����,�뵱ǰҵ�����Ͳ���.'+dbo.crlf()+
													'������ʹ�õĻ����޷����������,�볢�Ը�����������,���������ҵ��.'+dbo.crlf()+
													'����������,����ϵϵͳ����Ա.' 
													return
												END
										END
								END
						END
			return
		END
	ELSE
	Begin
			--ûδ¼�봮��ʱ,����ᴮ��
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
			AND (@PackageName='' or @PackageID!='' or  (@PackageID='' and a.PackageName LIKE '%'+@PackageName+'%'))				--�����װ�����Ϊ��ʱ,�Ų�ѯ�װ�����
			AND (@ExternalName='' or @PackageID!='' or (@PackageID='' and a.ExternalName LIKE '%'+@ExternalName+'%'))				--�����װ�����Ϊ��ʱ,�Ų�ѯ�ŵ���ʾ����
			AND (@begindate='' OR a.begindate<=@begindate)
			AND (@enddate='' OR a.enddate>=@enddate)
			--And (Isnull(pd.beginDate,'')='' Or @begindate='' Or pd.begindate<=@begindate)
			--And (Isnull(pd.endDate,'')='' Or @enddate='' Or pd.enddate>=@endDate)
			AND (@Reserved in('��') or (@Reserved in('','��') and ISNULL(a.OnlyReservedCustomer,0)=0) )			--����ԤԼ���ʱ�ų���ԤԼ�װ�,���򲻳���ԤԼ�װ�.
			And (@Valid='' or  a.actived= case when @Valid ='��' then 1 when @valid='��' then 0 end )
			and  (@valid in('','��')  or (@Valid in('��') and  a.DocStatus<>0))															--����Ҫ������Ϊ��Чʱ,��Ҫ������״̬Ϊ��ȷ��
			--And Isnull(pg.hasPhone,0)=0
			AND (@BusiType=''
				--�������ҵ�����ͱ�����ҵ�����ͼ����ʱ,ƥ�䴫��ҵ�������²�����ҵ������,������Ϊ�װ������е�ҵ�����ͼ���ΪҶ�Ӽ���.
				OR  pg.[PATH] LIKE '%/'+@BusiType+'/%' )
 
			--ƥ�乫˾
			AND (@companyID=''  OR (ISNULL(a.companyid,'')=''  and isnull(a.sdorgid,'')='')
					--ֱ��ƥ�乫˾
					OR (ISNULL(a.companyid,'')!='' AND @companyID!=''  --AND ISNULL(a.sdorgid,'')=''
						AND  exists(select 1 from commondb.dbo.split(ISNULL(a.companyid,''),',') WHERE list=@companyID)
					)
					--����Ҳ���빫˾��أ������ٳ��ԴӲ����б���ȡ����˾��ƥ��
					--����˾��ϢΪ��ʱ,�ſ��ǴӲ�����Ϣ��ƥ�乫˾��Ϣ.ֻƥ�������в��ŵ��Ӽ�,��ƥ�������в��ŵĸ���.��Ϊʵ����һ�����ŵĸ���,�Ӽ�����ͬһ����˾.
					OR (isnull(a.sdorgid,'')!='' AND @companyID!=''  And Isnull(a.companyid,'')=''
						and EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.sdorgid,''),',') x 
									inner join osdorg y WITH(NOLOCK) on y.path like '%/'+x.list+'/%'
									inner join oPlantSDOrg os  WITH(NOLOCK) ON  y.sdorgid=os.SDOrgID 
									where os.PlantID=@companyID)
						)
			)
			--ƥ������
			AND (
					--���������Ϊ��,�򲻽�������ƥ����
					@AreaID=''	
					--ֱ��ƥ�����򣬲��ɰ����򼶱��ѯ
					OR (ISNULL(a.areaid,'')!='' AND @AreaID!='' --AND ISNULL(a.sdorgid,'')='' 
						AND (
								--�Ƚ�������Ϊ�ӽڵ�ƥ��.�������û��������������������е����򼶱��
								EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.areaid,''),',') x,gArea g  WITH(NOLOCK) WHERE g.areaid=@AreaID AND g.[PATH] LIKE '/%'+x.list+'/%')
								--�ٽ�������Ϊ���ڵ�ƥ��.�������û��������������������е����򼶱��.
								or EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.areaid,''),',') x,gArea g  WITH(NOLOCK) WHERE g.areaid=x.List AND g.[PATH] LIKE '/%'+@AreaID+'/%')
						))
					--����Ҳ���������,��δ��������,�������˲���,�����ԴӲ��Ż�ȡ������Ϣ����ƥ��
						or (isnull(a.areaid,'')='' and @AreaID!='' and isnull(a.sdorgid,'')!=''
							AND(
								--��������Ϊ���ڵ�ƥ��.�������û��������������������е����򼶱��. 
								EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.sdorgid,''),',') x,gArea g  WITH(NOLOCK),oSDOrg os with(nolock) 
												WHERE os.path like '%/'+x.List+'/%'									--�������ż����Ӳ��� 
												and os.AreaID=g.areaid
												AND g.[PATH] LIKE '%/'+@AreaID+'/%')								--��Ϊ�Ѿ��������������õĲ��ż����Ӳ���,�������������Ҳƥ�������ŵ������.����Ҫ�ٽ�������Ϊ�ӽڵ����ƥ��.
								)
						)
					--�������в��ź�����Ϊ��,���ʾ�������򶼿���.
					or (isnull(a.areaid,'')='' and isnull(a.sdorgid,'')='')
			)
			--ƥ���ŵ�
			AND(@sdorgid='' or (isnull(a.sdorgid,'')='' and isnull(a.companyid,'')='')
					--ƥ���ŵ꣬�����㼶ƥ��
					OR(ISNULL(a.sdorgid,'')!='' AND @sdorgid!='' 
						AND (
								--�Ƚ��ŵ���Ϊ�ӽڵ�ƥ��,�������������õ��ŵ꼶��Ȳ����е��ŵ꼶���
								EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.sdorgid,''),',') x,oSDOrg o  WITH(NOLOCK) WHERE o.SDOrgID=@sdorgid AND o.path LIKE '%/'+x.list+'/%')
								 --�Ƚ��ŵ���Ϊ�ӽڵ�ƥ��,�������������õ��ŵ꼶��Ȳ����е��ŵ꼶���
								or EXISTS(SELECT 1 FROM commondb.dbo.SPLIT(ISNULL(a.sdorgid,''),',') x,oSDOrg o  WITH(NOLOCK) WHERE o.SDOrgID=x.List AND o.path LIKE '%/'+@sdorgid+'/%')
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
					SELECT @Seriescode,1,'���в��ܰ���'+case when isnull(@busiTypeName ,'')='' then '��' else @busiTypeName end +'��ҵ��.'+
					'��ѡ������ҵ�����'
					return
				END
			else
	 
				------��ƥ�䵽������,����Ҫ�ж��Ƿ�Ԥ�������Ұ�������.����Ҫ���ݺ����������
				BEGIN
					--������ΪԤ��,�Ұ�������,��ɾ���ǰ󶨵�����
					if isnull(@SeriesNumber,'')<>'' and exists(select 1 from @table a,T_PolicyGroup b where a.PackageType=b.PolicyGroupID and b.OpenAccount=1)
						BEGIN
							select @preallocation_PackageId=a.packageid
							  from seriespool a with(nolock) where a.SeriesNumber=@SeriesNumber
							  --�������װ�,��ɾ��������е������װ�
							  if isnull(@preallocation_PackageId,'')<>''
								BEGIN
									delete a from  @table a
									where a.packageid<>@preallocation_PackageId and a.OpenAccount=1
									--��ɾ��û�װ���,��˵�������Ϲ���
									if not exists(select 1 from @table)
										BEGIN
											select @Preallocation_Name=packagename from policy_h ph with(nolock) where ph.DocCode=@preallocation_PackageId
											INSERT INTO @table(Seriescode,[STATE],Remark)  
											SELECT @Seriescode, 1,'��ѡ��ĺ���'+@seriesnumber+'�Ѱ�['+isnull(@Preallocation_Name,'')+']����,�뵱ǰҵ�����Ͳ���.'+dbo.crlf()+
											'��ѡ���������ҵ��.'+dbo.crlf()+
											'����������,����ϵϵͳ����Ա.'+@Matgroup
											return
										END
								END
						END
				END
			return
		END
  RETURN   
 END
