--                    QueryinventorySeriesCode                          
-- select * from QueryinventorySeriesCode('','','','','*','','�ۺ�','','','')                          
             --beginday;endday;vndcode;matcode;mattype;sdorgid;stcode;seriescode;state;returncode;MATGROUP;matlife;issend;station1;preallocation;issale;salemun             
--select top 10 * from iseries where state='Ӧ��'      select * from iseries where seriescode='352540040950775'    
/*
�ֱ������۴��źͷ����۴���
�޸�ʱ��:2012/11/02 
�޸���:���ϵ�

*/               
CREATE                    function [dbo].[QueryinventorySeriesCode_saledate] ( @beginday datetime,@endday datetime,                         
        @vndcode varchar(500),                          
        @matcode varchar(300),                          
        @MatType varchar(200),                          
        @sdorgid varchar(200),                          
        @stcode varchar(100),                          
 @seriescode varchar(500),                          
 @state varchar(20),                          
 @returncode varchar(20),@MATGROUP varchar(50),@matlife varchar(50),@issend varchar(10)                          
 ,@station varchar(50) ,                      
 @preallocation  VARCHAR(20),          
 @issale varchar(30),@salemun varchar(50)                        
         )                          
        returns @table table(                          
        SeriesCode varchar(50),---����                          
        matcode varchar(50),---���Ϻ�                          
        matname varchar(100),---������                          
        mattype varchar(50),---�ֻ��ͺ�                          
        state varchar(10),----״̬                          
        stcode varchar(50),---�ֿ�                          
        stname varchar(150),                          
        vndcode varchar(50),---��Ӧ�̺�                          
        vndname varchar(200),--��Ӧ����                          
        purprice money,--�ɹ���                          
        purGRdate datetime,--�ɹ��ջ�ʱ��                          
        purGRDocCode varchar(20),---�ɹ��ջ�����                          
        purReturnDate datetime,--�˻�����                          
        purReturnPrice datetime,---�˻�ʱ��                          
        purReturnDocCode varchar(20),---�˻�������                          
        purSPmoney money,--��Ӧ���ۼƱ��۽��                          
        purAchivePrice money,---                          
        purClearPrice money,--������                          
        payamount money,--�����                          
 returncode varchar(50), --������                          
--      createdate datetime,---������������                          
--      createdoccode varchar(20),--�������ŵ���,--�������ŵ���                               
--  returncode varchar(20),                          
--  returnname varchar(40),                          
  returndoccode varchar(20),                          
--  returndate datetime,                          
  salesuom varchar(50),                           
--  packagecode varchar(20),                          
--  costprice money,                          
  matgroup varchar(20),                           
 YXDATE DATETIME,                          
 gift varchar(50),                          
 fk int,                          
 matlife varchar(50),  --��Ʒ״̬                          
        digit int ,                           
 matgroupname varchar(50) ,                          
 stcode1 varchar(50), --������ۺ�                          
 stname1 varchar(120),                          
 shdjdate datetime, --������ۺ�ʱ��                           
 shdjHDMemo varchar(100),   --������ۺ����˵��                          
 station varchar(50),   --��λ                          
 issend varchar(10),                          
 shdjusertxt varchar(100), --�ۺ󸽼���Ϣ                       
 preallocation bit,--Ԥ����                         
 seriesnumber varchar(50),salesdate datetime,salemun varchar(50)         )as                          
begin                          
                    
-- if @stcode=''                          
-- return                          
DECLARE @bpreallocation BIT              
SELECT @bpreallocation=CASE when @preallocation='Ԥ����' then 1 else 0 end                       
if @stcode='*'            
 select @stcode=''                    
----         update iseries set issend = 0 where seriescode in ('358852010023382','356677010433402')                               
if @state='' or @state like '%����%'
	BEGIN
		insert into @table (SeriesCode , matcode , matname ,mattype ,stcode,stname, state ,vndcode ,purprice , purGRdate ,purGRDocCode ,purReturnDate ,purReturnPrice ,                          
		purReturnDocCode , purSPmoney ,purAchivePrice,purClearPrice,payamount,vndname,matgroup,matgroupname,salesuom,returndoccode,                          
		--returncode,returnname ,returndoccode,returndate,createdate ,createdoccode,                          
		YXDATE,gift,fk ,matlife , digit ,stcode1,shdjdate,shdjHDMemo ,station,issend,shdjusertxt,returncode,seriesnumber,salesdate,salemun)                          
		                          
		select SeriesCode , a.matcode , l.matname ,l.mattype ,a.stcode,e.name40, state ,a.vndcode ,a.purprice , purGRdate ,purGRDocCode ,purReturnDate ,purReturnPrice ,                          
		purReturnDocCode , purSPmoney ,purAchivePrice,purClearPrice,payamount,b.vndname,p.matgroup,p.matgroupname,l.Uom,a.returndoccode,                          
		--returncode,returnname ,returndoccode,returndate ,createdate ,createdoccode ,                          
		YXDATE,gift,fk,l.matlife , 1 ,stcode1,shdjdate,shdjHDMemo,station,                          
		(case isnull(issend,0) when 0 then 'δ�ͳ�' when 1 then '���ͳ�' when 2 then '�ѷ���'  end),shdjusertxt,a.returncode,a.seriesnumber,salesdate,(case a.salemun when -1 then '�ۺ��' else '���ۺ��' end) as salemun                          
		from --vseries a            select * from iseries              
		iseries a                           
		left join imatgeneral l with(nolock) on a.matcode=l.matcode                           
		left join pvndgeneral b with(nolock)  on a.vndcode=b.vndcode                          
		left join imatgroup p with(nolock)  on l.matgroup=p.matgroup                          
		left join oStorage e with(nolock)  on a.stcode=e.stcode                          
		where (salesdate between @beginday and @endday) and salesdate is not null and                                
		and   (@stcode='' or a.stcode in (select * from getinstr(@stcode)))                          
		and   (@matgroup = '' or exists(select * from imatgroup aa,getinstr(@matgroup) bb,imatgroup cc                          
				  where aa.matgroup = bb.list and left(cc.treecontrol,len(aa.treecontrol)) = aa.treecontrol and cc.matgroup = l.matgroup))                          
		and   (@mattype='' or l.mattype like '%'+@mattype+'%')--in (select * from getinstr(@mattype)))                                           
		and   (@vndcode='' or a.vndcode in (select * from getinstr(@vndcode)))                          
		and   (@matcode='' or a.matcode in (select * from getinstr(@matcode)))                          
		and   (a.seriescode like '%'+ @SeriesCode+'%' or @seriescode='')                          
		and   (@returncode='' or a.returncode in (select * from getinstr(@returncode)))                          
		and   (@matlife='' or l.matlife in (select * from getinstr(@matlife)))                          
		and   (@station='' or a.station in (select * from getinstr(@station)))                         
		AND (@preallocation='' OR  isnull(a.preAllocation,0)=@bpreallocation)       
		and  (@salemun='' or (case a.salemun when -1 then '��' else '��' end)=@salemun)                     
		and (@issale='' or (case salemun when 1 then '����������' when 0 then '�����̿��' end)=@issale) 
	END
if @state='' and @state<>'����'
	BEGIN
		insert into @table (SeriesCode , matcode , matname ,mattype ,stcode,stname, state ,vndcode ,purprice , purGRdate ,purGRDocCode ,purReturnDate ,purReturnPrice ,                          
		purReturnDocCode , purSPmoney ,purAchivePrice,purClearPrice,payamount,vndname,matgroup,matgroupname,salesuom,returndoccode,                          
		--returncode,returnname ,returndoccode,returndate,createdate ,createdoccode,                          
		YXDATE,gift,fk ,matlife , digit ,stcode1,shdjdate,shdjHDMemo ,station,issend,shdjusertxt,returncode,seriesnumber,salesdate,salemun)                          
		                          
		select SeriesCode , a.matcode , l.matname ,l.mattype ,a.stcode,e.name40, state ,a.vndcode ,a.purprice , purGRdate ,purGRDocCode ,purReturnDate ,purReturnPrice ,                          
		purReturnDocCode , purSPmoney ,purAchivePrice,purClearPrice,payamount,b.vndname,p.matgroup,p.matgroupname,l.Uom,a.returndoccode,                          
		--returncode,returnname ,returndoccode,returndate ,createdate ,createdoccode ,                          
		YXDATE,gift,fk,l.matlife , 1 ,stcode1,shdjdate,shdjHDMemo,station,                          
		(case isnull(issend,0) when 0 then 'δ�ͳ�' when 1 then '���ͳ�' when 2 then '�ѷ���'  end),shdjusertxt,a.returncode,a.seriesnumber,salesdate,(case a.salemun when -1 then '�ۺ��' else '���ۺ��' end) as salemun                          
		from --vseries a            select * from iseries              
		iseries a                           
		left join imatgeneral l with(nolock)  on a.matcode=l.matcode                           
		left join pvndgeneral b with(nolock)  on a.vndcode=b.vndcode                          
		left join imatgroup p with(nolock)  on l.matgroup=p.matgroup                          
		left join oStorage e with(nolock)  on a.stcode=e.stcode                          
		where (salesdate between @beginday and @endday) and salesdate is not null and               
		(@state='' or a.state in (select * from getinstr(@state)))                          
		and   (@stcode='' or a.stcode in (select * from getinstr(@stcode)))                          
		and   (@matgroup = '' or exists(select * from imatgroup aa,getinstr(@matgroup) bb,imatgroup cc                          
				  where aa.matgroup = bb.list and left(cc.treecontrol,len(aa.treecontrol)) = aa.treecontrol and cc.matgroup = l.matgroup))                          
		and   (@mattype='' or l.mattype like '%'+@mattype+'%')--in (select * from getinstr(@mattype)))                           
		and   (a.state='Ӧ��' or a.state='�ڿ�' or a.state='��;' or a.state='����' or a.state='���' or a.state='�ۺ�' or a.state='����' or a.state is null)                          
		and   (@vndcode='' or a.vndcode in (select * from getinstr(@vndcode)))                          
		and   (@matcode='' or a.matcode in (select * from getinstr(@matcode)))                          
		and   (a.seriescode like '%'+ @SeriesCode+'%' or @seriescode='')                          
		and   (@returncode='' or a.returncode in (select * from getinstr(@returncode)))                          
		and   (@matlife='' or l.matlife in (select * from getinstr(@matlife)))                          
		and   (@station='' or a.station in (select * from getinstr(@station)))                         
		AND (@preallocation='' OR  isnull(a.preAllocation,0)=@bpreallocation)       
		and  (@salemun='' or (case a.salemun when -1 then '��' else '��' end)=@salemun)                     
		and (@issale='' or (case salemun when 1 then '����������' when 0 then '�����̿��' end)=@issale)         
	END
 
-- update @table set vndname=b.vndname from @table a,pvndgeneral b where a.vndcode=b.vndcode                          
--��������                          
 update @table set salesuom=b.salesuom                          
 from @table a,imatgeneral b where a.matcode=b.matcode                          
-- update @table set matgroupname = b.matgroupname from @table a ,imatgroup b where a.matgroup = b.matgroup                          
--�����ۺ��������                          
update @table set stname1=name40 from @table e ,vstorage b where e.stcode1=b.stcode and isnull(e.stcode1,'')<>''                          
                          
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
          
--select matgroup,* from vseries where matgroup is null                          
--select * from imatgeneral where matcode = 'S0201610002'                          
                
return                          
end                           
                          
-- select * from vseries where mattype='ŵN2300'