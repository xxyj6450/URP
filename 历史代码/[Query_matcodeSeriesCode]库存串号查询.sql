--QueryinventorySeriesCode                                            
-- select * from QueryinventorySeriesCode('2011-02-01','2011-07-01','','','1.4.769.01.05','','','','','','','','','','','',''  )                     
-- select * from dbo.QueryinventorySeriesCode('2005-11-08','2011-05-01','','','','','1.4.769.01.05','','�ڿ�','','','','','','','','')                                         
--beginday;endday;vndcode;matcode;mattype;sdorgid;stcode;seriescode;state;returncode;MATGROUP;matlife;issend;station1;preallocation;issale;salemun                               
--select mattype,* from iseries                                            
alter FUNCTION [dbo].[Query_matcodeSeriesCode]          
(          
 @beginday       DATETIME,          
 @endday         DATETIME,          
 @vndcode        VARCHAR(500),          
 @matcode        VARCHAR(3000),          
 @MatType        VARCHAR(200),          
 @sdorgid        VARCHAR(200),          
 @stcode         VARCHAR(100),          
 @seriescode     VARCHAR(500),          
 @state          VARCHAR(100),          
 @returncode     VARCHAR(20),          
 @MATGROUP       VARCHAR(50),          
 @matlife        VARCHAR(50),          
 @issend         VARCHAR(10),          
 @station        VARCHAR(50),          
 @preallocation  VARCHAR(20),          
 @issale         VARCHAR(30),          
 @salemun        VARCHAR(50),          
 @companyid      VARCHAR(50)          
)          
RETURNS @table TABLE(SeriesCode VARCHAR(50), ---����                                            
         matcode VARCHAR(50), ---���Ϻ�                                            
         matname VARCHAR(100), ---������                                            
         mattype VARCHAR(50), ---�ֻ��ͺ�                                            
         STATE VARCHAR(10), ----״̬                                            
         stcode VARCHAR(50), ---�ֿ�                                            
         stname VARCHAR(150),vndcode VARCHAR(50), ---��Ӧ�̺�                                            
         vndname VARCHAR(200), --��Ӧ����                                            
         purprice MONEY, --�ɹ���                                            
         purGRdate DATETIME, --�ɹ��ջ�ʱ��                                            
         purGRDocCode VARCHAR(20), ---�ɹ��ջ�����                                            
         purReturnDate DATETIME, --�˻�����                                            
         purReturnPrice DATETIME, ---�˻�ʱ��                                            
         purReturnDocCode VARCHAR(20), ---�˻�������                                            
         purSPmoney MONEY, --��Ӧ���ۼƱ��۽��                                            
         purAchivePrice MONEY, ---                                            
         purClearPrice MONEY, --������                                            
         payamount MONEY, --�����                                            
         returncode VARCHAR(50), --������          
                                 --      createdate datetime,---������������          
                                 --      createdoccode varchar(20),--�������ŵ���,--�������ŵ���          
                                 --  returncode varchar(20),          
                                 --  returnname varchar(40),                                            
         returndoccode VARCHAR(20),--  returndate datetime,                                            
         salesuom VARCHAR(50),--  packagecode varchar(20),          
                              --  costprice money,                                            
         matgroup VARCHAR(20),YXDATE DATETIME,gift VARCHAR(50),fk INT,matlife VARCHAR(50), --��Ʒ״̬                                            
         digit INT,matgroupname VARCHAR(50),stcode1 VARCHAR(50), --������ۺ�                                            
         stname1 VARCHAR(120),shdjdate DATETIME, --������ۺ�ʱ��                                             
         shdjHDMemo VARCHAR(100), --������ۺ����˵��                                       
         station VARCHAR(50), --��λ                              
         issend VARCHAR(10),shdjusertxt VARCHAR(100), --�ۺ󸽼���Ϣ                                         
         preallocation BIT, --Ԥ����                                           
         seriesnumber VARCHAR(50),salesdate DATETIME,salemun VARCHAR(50),          
      areaid VARCHAR(50),areaname VARCHAR(500),PackageID           
         VARCHAR(50),Formgroup VARCHAR(20),isContractSale BIT,           salesprice MONEY,areacode VARCHAR(50),          
         ExtendWarrantyDate DATETIME,          
         ExtendWarrantyDoc VARCHAR(20),    
   seriestype varchar(50),  
  ESSID varchar(50)          
        )          
AS           
  ---�����Ƿ��Լ���ֶΣ�yx          
  --�������۵���              
              
                                
BEGIN          
 -- if @stcode=''          
 -- return                                            
 DECLARE @bpreallocation BIT                                
 SELECT @bpreallocation = CASE           
                               WHEN @preallocation = 'Ԥ����' THEN 1          
                               ELSE 0          
                          END          
           
 IF @stcode = '*'          
     SELECT @stcode = ''           
 ----         update iseries set issend = 0 where seriescode in ('358852010023382','356677010433402')                                                 
if @state='' or @state like '%����%'
	BEGIN
				INSERT INTO @table( SeriesCode, matcode, matname, mattype, stcode, stname,           
				STATE, vndcode, purprice, purGRdate, purGRDocCode, purReturnDate,           
				purReturnPrice, purReturnDocCode, purSPmoney, purAchivePrice,           
				purClearPrice, payamount, vndname, matgroup, matgroupname, salesuom,           
				returndoccode, --returncode,returnname ,returndoccode,returndate,createdate ,createdoccode,                                            
				YXDATE, gift, fk, matlife, digit, stcode1, shdjdate, shdjHDMemo,           
				station, issend, shdjusertxt, returncode, seriesnumber, salesdate,           
				salemun, areaid, areaname, PackageID, formgroup, isContractSale,           
				salesprice, areacode,ExtendWarrantyDate,ExtendWarrantyDoc,seriestype,ESSID)          
			 SELECT SeriesCode,a.matcode,l.matname,l.mattype,a.stcode,e.name40,STATE,a.vndcode,          
					a.purprice,purGRdate,purGRDocCode,purReturnDate,purReturnPrice,          
					purReturnDocCode,purSPmoney,purAchivePrice,purClearPrice,payamount,b.vndname,          
					p.matgroup,p.matgroupname,l.salesuom,a.returndoccode,--returncode,returnname ,returndoccode,returndate ,createdate ,createdoccode ,                                            
					YXDATE,gift,fk,l.matlife,1,stcode1,shdjdate,shdjHDMemo,station,(CASE           
																						 ISNULL(issend, 0)          
																						 WHEN   0 THEN   'δ�ͳ�'          
																						 WHEN   1 THEN   '���ͳ�'          
																						 WHEN  2 THEN   '�ѷ���'          
																					END          
					),shdjusertxt,a.returncode,a.seriesnumber,salesdate,(CASE a.salemun WHEN -1 THEN '�ۺ��' ELSE '���ۺ��' END) AS           
					salemun,a.areaid,a.areaname,a.PackageID,a.formgroup,a.isContractSale,          
					a.salesprice,a.areacode,a.ExtendWarrantyDate,a.ExtendWarrantyDoc,a.seriestype,a.ESSID          
			 FROM   --vseries a            select *,areaname from oStorage                                
					iseriesSaled a with(nolock) 
					LEFT JOIN imatgeneral l  with(nolock) ON  a.matcode = l.matcode          
					LEFT JOIN pvndgeneral b  with(nolock) ON  a.vndcode = b.vndcode          
					LEFT JOIN imatgroup p  with(nolock) ON  l.matgroup = p.matgroup          
					LEFT JOIN oStorage e  with(nolock)  ON  a.stcode = e.stcode          
			 WHERE  --(purgrdate between @beginday and @endday or purgrdate is null) and                                   
				(@state = '' or a.state='����'
				)          
				AND (@stcode = '' OR @stcode = a.stcode)          
				AND (@matgroup = '' OR l.matgroup LIKE @matgroup + '%') --exists(select * from imatgroup aa,getinstr(@matgroup) bb,imatgroup cc          
							 --where aa.matgroup = bb.list and left(cc.treecontrol,len(aa.treecontrol)) = aa.treecontrol and cc.matgroup = l.matgroup))          
				AND (@mattype = '' OR l.mattype LIKE @mattype + '%')--in (select * from getinstr(@mattype)))          
																	--and   (a.state='Ӧ��' or a.state='�ڿ�' or a.state='��;' or a.state='����' or a.state='���' or a.state='�ۺ�' or a.state='����' or a.state is null)     --�˾�ĳ�In                 
				AND (@vndcode = '' OR a.vndcode = @vndcode)          
				AND (@matcode = '' OR EXISTS(SELECT 1          
							  FROM   getinstr(@matcode)          
							  WHERE  list = a.matcode))          
				AND (a.seriescode LIKE @SeriesCode + '%' OR @seriescode = '')          
				AND (@returncode = '' OR a.returncode = @returncode)          
				AND (@matlife = '' OR l.matlife = @matlife)          
				AND (@station = '' OR a.station = @station)          
				AND (@preallocation = ''          
						OR ISNULL(a.preAllocation,0) = @bpreallocation          
					)          
				AND (@salemun = ''          
						OR (CASE a.salemun WHEN -1 THEN '��' ELSE '��' END) = @salemun          
					)          
				AND (@issale = ''          
						OR (CASE salemun          
								 WHEN 1 THEN '����������'          
								 WHEN 0 THEN '�����̿��'          
							END          
						   ) = @issale          
					)          
				--AND e.insystem = 1          
				AND (@companyid = '' OR e.plantid = @companyid)          
				AND (@issend = '' OR a.issend = @issend) --2011-08-12 ���ͳ�������������ѯ�� ɾ�������Delete���� ���ϵ�          
														 -- update @table set vndname=b.vndname from @table a,pvndgeneral b where a.vndcode=b.vndcode          
														 --��������  ������ѯ���Ѿ�������SalesUOM�ֶ�,���������������� 2011-08-12 ���ϵ�       
	END
	if @state='' or @state<>'����'
		BEGIN
				INSERT INTO @table( SeriesCode, matcode, matname, mattype, stcode, stname,           
				STATE, vndcode, purprice, purGRdate, purGRDocCode, purReturnDate,           
				purReturnPrice, purReturnDocCode, purSPmoney, purAchivePrice,           
				purClearPrice, payamount, vndname, matgroup, matgroupname, salesuom,           
				returndoccode, --returncode,returnname ,returndoccode,returndate,createdate ,createdoccode,                                            
				YXDATE, gift, fk, matlife, digit, stcode1, shdjdate, shdjHDMemo,           
				station, issend, shdjusertxt, returncode, seriesnumber, salesdate,           
				salemun, areaid, areaname, PackageID, formgroup, isContractSale,           
				salesprice, areacode,ExtendWarrantyDate,ExtendWarrantyDoc,seriestype,ESSID)          
				 SELECT SeriesCode,a.matcode,l.matname,l.mattype,a.stcode,e.name40,STATE,a.vndcode,          
						a.purprice,purGRdate,purGRDocCode,purReturnDate,purReturnPrice,          
						purReturnDocCode,purSPmoney,purAchivePrice,purClearPrice,payamount,b.vndname,          
						p.matgroup,p.matgroupname,l.salesuom,a.returndoccode,--returncode,returnname ,returndoccode,returndate ,createdate ,createdoccode ,                                            
						YXDATE,gift,fk,l.matlife,1,stcode1,shdjdate,shdjHDMemo,station,(CASE           
																							 ISNULL(issend, 0)          
																							 WHEN   0 THEN   'δ�ͳ�'          
																							 WHEN   1 THEN   '���ͳ�'          
																							 WHEN  2 THEN   '�ѷ���'          
																						END          
						),shdjusertxt,a.returncode,a.seriesnumber,salesdate,(CASE a.salemun WHEN -1 THEN '�ۺ��' ELSE '���ۺ��' END) AS           
						salemun,a.areaid,a.areaname,a.PackageID,a.formgroup,a.isContractSale,          
						a.salesprice,a.areacode,a.ExtendWarrantyDate,a.ExtendWarrantyDoc,a.seriestype,a.ESSID          
				 FROM   --vseries a            select *,areaname from oStorage                                
						iseries a          
						LEFT JOIN imatgeneral l ON  a.matcode = l.matcode          
						LEFT JOIN pvndgeneral b ON  a.vndcode = b.vndcode          
						LEFT JOIN imatgroup p ON  l.matgroup = p.matgroup          
						LEFT JOIN oStorage e ON  a.stcode = e.stcode          
				 WHERE  --(purgrdate between @beginday and @endday or purgrdate is null) and                                   
						(@state = ''          
							OR EXISTS(SELECT 1          
									  FROM   getinstr(@state)          
									  WHERE  list = a.state          
							   )          
						)          
						AND (@stcode = '' OR @stcode = a.stcode)          
						AND (@matgroup = '' OR l.matgroup LIKE @matgroup + '%') --exists(select * from imatgroup aa,getinstr(@matgroup) bb,imatgroup cc          
									 --where aa.matgroup = bb.list and left(cc.treecontrol,len(aa.treecontrol)) = aa.treecontrol and cc.matgroup = l.matgroup))          
						AND (@mattype = '' OR l.mattype LIKE @mattype + '%')--in (select * from getinstr(@mattype)))          
																			--and   (a.state='Ӧ��' or a.state='�ڿ�' or a.state='��;' or a.state='����' or a.state='���' or a.state='�ۺ�' or a.state='����' or a.state is null)     --�˾�ĳ�In          
						AND (a.state IN ('Ӧ��', '�ڿ�', '��;', '����', '���', '�ۺ�', '����','����')          
							)          
						AND (@vndcode = '' OR a.vndcode = @vndcode)          
						AND (@matcode = '' OR EXISTS(SELECT 1          
									  FROM   getinstr(@matcode)          
									  WHERE  list = a.matcode))          
						AND (a.seriescode LIKE @SeriesCode + '%' OR @seriescode = '')          
						AND (@returncode = '' OR a.returncode = @returncode)          
						AND (@matlife = '' OR l.matlife = @matlife)          
						AND (@station = '' OR a.station = @station)          
						AND (@preallocation = ''          
								OR ISNULL(a.preAllocation,0) = @bpreallocation          
							)          
						AND (@salemun = ''          
								OR (CASE a.salemun WHEN -1 THEN '��' ELSE '��' END) = @salemun          
							)          
						AND (@issale = ''          
								OR (CASE salemun          
										 WHEN 1 THEN '����������'          
										 WHEN 0 THEN '�����̿��'          
									END          
								   ) = @issale          
							)          
						--AND e.insystem = 1          
						AND (@companyid = '' OR e.plantid = @companyid)          
						AND (@issend = '' OR a.issend = @issend) --2011-08-12 ���ͳ�������������ѯ�� ɾ�������Delete���� ���ϵ�          
														 -- update @table set vndname=b.vndname from @table a,pvndgeneral b where a.vndcode=b.vndcode          
														 --��������  ������ѯ���Ѿ�������SalesUOM�ֶ�,���������������� 2011-08-12 ���ϵ�            
		END
    
 /*update @table set salesuom=b.salesuom                                            
 from @table a,imatgeneral b where a.matcode=b.matcode                                            
 -- update @table set matgroupname = b.matgroupname from @table a ,imatgroup b where a.matgroup = b.matgroup   */           
 --�����ۺ��������                                            
 UPDATE @table          
 SET    stname1 = name40          
 FROM   @table e,          
        vstorage b          
 WHERE  e.stcode1 = b.stcode          
        AND ISNULL(e.stcode1,'') <> ''           
 /*  2011-08-12 ע�ʹ˲��� ����δ���ŵ���ѯ����� ���ϵ�                
 if isnull(@issend,'') = 'δ�ͳ�'                                            
 begin                                             
 delete from @table where issend <>'δ�ͳ�'                                             
 end                                            
 if isnull(@issend,'') = '���ͳ�'                                            
 begin                                             
 delete from @table where issend <>'���ͳ�'                                             
 end                                            
 if isnull(@issend,'') = '�ѷ���'                                            
 begin                                             
 delete from @table where issend <>'�ѷ���'                                             
 end                                            
 */           
 --select matgroup,* from vseries where matgroup is null          
 --select * from imatgeneral where matcode = 'S0201610002'                                            
           
 RETURN          
END