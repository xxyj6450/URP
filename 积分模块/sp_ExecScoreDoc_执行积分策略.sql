/*                                                                      
* 函数名称：sp_ExecScoreDoc                                                    
* 功能描述：执行调用积分策略设置                                                 
* 参数:见声名部分                                                                      
* 编写：子虚乌有                                                                      
* 时间：2013/01/22                                                                   
* 备注：该存储过程用于调用策略执行策略设置中的积分规则,计算积分                                                
* 示例：exec sp_ExecScoreDoc 9102,'RW20100706000003',0          
begin tran                                              
exec sp_ExecScoreDoc 9752,'SP20130321000001',0       
rollback 
sp_ExecScoreDoc 9146;doccode;0;@usercode   

EXEC sp_ExecuteStrategy 9752,'SP20130321000001',1,null,'',null,@result output                                               
*/      
alter PROC [dbo].[sp_ExecScoreDoc]                                                  
 @formid INT,                                                  
 @doccode VARCHAR(500),                                                  
 @optionID INT = 0,                                                  
 @usercode VARCHAR(500) = ''                                                  
AS                                                  
BEGIN      
 SET NOCOUNT ON; 
 SET XACT_ABORT ON; 
 DECLARE @result VARCHAR(MAX),@tips VARCHAR(MAX)     
 declare @sdorgid varchar(50),@matcode varchar(50),@cardmatcode varchar(50),@matprice money,@price money,
 @phoneRate money,@ServiceFee money,@CardFEE1 money,@otherFee money,@matMoney money,@Combocode varchar(50),
 @PackageID varchar(50),@DocDate datetime,@seriescode varchar(50)
 declare @MatCouponsBarcode varchar(30),@MatDeductAmount money,@node int
 CREATE TABLE #DocData (
 	Doccode VARCHAR(20),
 	FormID INT,
 	DocDate DATETIME,
 	SDOrgID VARCHAR(50),
 	AreaID VARCHAR(50),
 	SDorgPath VARCHAR(500),
 	AreaPath VARCHAR(500),
 	dpttype VARCHAR(50)
 )
 
 IF @formid IN (2419,2420)
 BEGIN
 	update sPickorderitem
 		set price2=0
 	where DocCode=@doccode
 	INSERT INTO #DocData(Doccode,FormID,SDOrgID,SDorgPath,AreaID,AreaPath,dpttype,DocDate)
		SELECT uo.DocCode,uo.FormID,uo.sdorgid,o.[PATH],g.areaid,g.[PATH],o.dptType,uo.DocDate
		FROM spickorderhd uo WITH(NOLOCK) INNER JOIN oSDOrg o with(nolock) ON uo.sdorgid=o.SDOrgID
		INNER JOIN gArea g ON o.AreaID=g.areaid
		where uo.DocCode=@doccode
 END
 IF @FormID IN(9146,9102,9237,9244)
	BEGIN
		select @sdorgid=uo.sdorgid,@matcode=uo.MatCode,@cardmatcode=uo.CardMatCode,@CardFEE1=isnull(uo.CardFEE1,0),
		@price=isnull(uo.Price,0),@phoneRate=isnull(uo.PhoneRate,0),@ServiceFee=isnull(uo.ServiceFEE,0),@otherFee=uo.OtherFEE,
		@matprice=uo.MatPrice,@Combocode=uo.ComboCode,@PackageID=uo.PackageID,@DocDate=uo.DocDate,@seriescode=uo.SeriesCode,
		@MatCouponsBarcode=uo.matCouponsbarcode,@MatDeductAmount=uo.matDeductAmount,@node=uo.node
		from Unicom_Orders uo with(nolock)
		where uo.DocCode=@doccode
		INSERT INTO #DocData(Doccode,FormID,SDOrgID,SDorgPath,AreaID,AreaPath,dpttype,DocDate)
		SELECT @DocCode,@FormID,@sdorgid,o.[PATH],g.areaid,g.[PATH],o.dptType,@DocDate
		FROM   oSDOrg o with(nolock)  
		INNER JOIN gArea g ON o.AreaID=g.areaid
		where  o.sdorgid=@SDOrgID
		;with cte(doccode,formid,seriescode,rowid,matcode,digit,price,totalmoney,price2,couponsbarcode,DeductAmout)as(
				--商品明细
				select @doccode,@formid,seriescode,rowid,matcode,digit,price,totalmoney,uod.price2,couponsbarcode,deductamout
				  from #Unicom_OrderDetails uod with(nolock) WHERE uod.DocCode=@doccode 
			union all
				--手机
				select @doccode,@formid,@seriescode,CONVERT(VARCHAR(50), newid()),@matcode,1,@matprice,@matMoney,0,@MatCouponsBarcode,@MatDeductAmount
				where isnull(@matcode,'')<>''
			union all
				--空白卡
				select @doccode,@formid,NULL,CONVERT(VARCHAR(50), newid()),@cardmatcode,1,@CardFEE1,@CardFEE1,0,NULL,0 where isnull(@cardmatcode,'')<>'' 
			union ALL
				--服务费
				select @doccode,@formid,NULL,CONVERT(VARCHAR(50), newid()),propertyvalue,1,@ServiceFee,@ServiceFee,0,NULL,0
				From dbo.fn_sysGetNumberAllocationConfig('靓号服务费') fsgnac
			union all
				--靓号预存款
				select @doccode,@formid,NULL,CONVERT(VARCHAR(50), newid()),propertyvalue,1,@phoneRate,@phoneRate,0,NULL,0
				From dbo.fn_sysGetNumberAllocationConfig('靓号预存费') fsgnac
			union all
				--基本预存款
				select @doccode,@formid,NULL,CONVERT(VARCHAR(50), newid()),propertyvalue,1,@price,@price,0,NULL,0
				From dbo.fn_sysGetNumberAllocationConfig('基本预存款') fsgnac
			union all
				--其它费用
				select @doccode,@formid,NULL,CONVERT(VARCHAR(50), newid()),propertyvalue,1,@otherFee,@otherFee,0,NULL,0
				From dbo.fn_sysGetNumberAllocationConfig('其它费用') fsgnac
			)
			--生成数据源
			Select @doccode as Doccode,@formid as FormID,@DocDate as DocDate,@sdorgid as SDorgID,os.SDOrgName,
			os.dptType,os.path as SDorgPath,os.AreaID,ga.areaname,ga.path as areaPath,@Combocode as Combocode,@PackageID as PackageID,
			a.rowid,a.seriescode,a.matcode,img.matname,a.digit,a.price,a.totalmoney,a.price2,img.MatGroup,img2.path as matgroupPath,ph.PolicygroupID,ph.DocType as PackageType,
			ISNULL(ch.Price,0) as comboPrice,a.couponsbarcode,isnull(a.DeductAmout,0) as DeductAmout,isnull(@node,0) as node
			Into #preare_DataSource 
			from cte a inner join iMatGeneral img with(nolock) on a.matcode=img.MatCode
			inner join iMatGroup img2 with(nolock) on img.matgroup=img2.matgroup
			inner join oSDOrg os with(nolock) on os.SDOrgID=@sdorgid
			inner join gArea ga with(nolock) on os.AreaID=ga.areaid
			Inner join policy_h ph with(nolock) on ph.DocCode=@PackageID
			Left join combo_h ch on ch.ComboCode=@Combocode
			--从数据源生成积分明细
			delete from ScoreLedgerLog where Doccode=@doccode
			insert into ScoreLedgerLog(Doccode,FormID,RowID,Matcode,couponsbarcode,deductamout)
			select @doccode,@formid,rowid,matcode,couponsbarcode,deductamout
			from #preare_DataSource uod with(nolock)
		

	END
	
 IF @FormID IN(9153,9158,9159,9160,9165,9167,9180,9267,9755,9752)
	BEGIN
		-----执行积分计算时,先把单据上的积分清空
		UPDATE BusinessAcceptance_H	SET TotalScore = 0 WHERE docCode=@doccode
		
		INSERT INTO #DocData(Doccode,FormID,SDOrgID,SDorgPath,AreaID,AreaPath,dpttype,docdate)
		SELECT uo.DocCode,uo.FormID,uo.sdorgid,o.[PATH],g.areaid,g.[PATH],o.dptType,uo.DocDate
		FROM BusinessAcceptance_H  uo WITH(NOLOCK) INNER JOIN oSDOrg o with(nolock) ON uo.sdorgid=o.SDOrgID
		INNER JOIN gArea g with(nolock) ON o.AreaID=g.areaid
		where uo.docCode=@doccode
	END

	BEGIN TRY
		EXEC sp_ExecuteStrategy @formid,@doccode,2,null,@usercode,null,@result OUTPUT
		/*IF @formid IN (9146)
		begin
			update Unicom_Orders SET TotalScore = Score+b.Score1 ,Score1 = b.Score1
			FROM Unicom_Orders a,(SELECT SUM(Score) AS Score1 FROM ScoreLedgerLog WHERE Doccode=@doccode) b
			WHERE  doccode=@doccode
		end
		*/
	END TRY
	BEGIN CATCH
		SELECT @tips=dbo.getLastError('策略执行失败.')
		 RAISERROR(@tips,16,1)             
	END CATCH     
END