/*                                                                    
* 函数名称：sp_ExecAfterSaveDoc                                                  
* 功能描述：单据保存后执行                                                
* 参数:见声名部分                                                                    
* 编写：三断笛                                                                    
* 时间：2010/06/29                                                                  
* 备注：该存储过程在单据保存时执行一些操作,比如单据求和,单据检查和数据修改,都可以在这里写入代码                                                
* 示例：exec sp_ExecAfterSaveDoc 9102,'RW20100706000003',0        
begin tran                                            
exec sp_ExecAfterSaveDoc 9102,'RW20120809000007',0     
rollback                                               
exec sp_ExecAfterSaveDoc 9110,'TBD2010072700004',0                                                 
* --------------------------------------------------------------------                                                                    
* 修改：                                                                    
* 时间：                                
* 备注：                                                                    
*                                                                 
*/    
ALTER PROC [dbo].[sp_ExecAfterSaveDoc]                                                
 @formid INT,                                                
 @doccode VARCHAR(500),                                                
 @optionID INT = 0,                                                
 @usercode VARCHAR(500) = ''                                                
AS                                                
BEGIN    
 SET NOCOUNT ON    
 DECLARE @seriesnumber VARCHAR(500), @sdorgid VARCHAR(500), @sdgroup                     
             VARCHAR(500), @areaid VARCHAR(500), @matname VARCHAR(200), @blnNotNeddCard  BIT,
              @areaID1    VARCHAR(500), @areaname1 VARCHAR(500), @tips VARCHAR(2000), @seriesCode         
             VARCHAR(500), @stcode VARCHAR(500), @old INT, @ComboCode  VARCHAR(50),@docDate DATETIME,    
             @PackageID VARCHAR(50), @NONeedAllocate BIT,@comboName VARCHAR(200),@dpttype VARCHAR(50),    
             @price MONEY,@value VARCHAR(20),@sdorgName VARCHAR(200),@userName VARCHAR(50),@minprice MONEY,    
             @PackageCode VARCHAR(20),@ErrorText VARCHAR(4000),@HasError bit,@ICCID VARCHAR(30),@done BIT,@node INT,@DocStatus INT,
             @Matcode VARCHAR(50),@SIMSeriescode VARCHAR(50),@matmoney MONEY,@CardMoney MONEY,@CardMatCode VARCHAR(50),@tranCount int,
             @CheckState varchar(50),@Nettype VARCHAR(50),@totalmoney_H Money,@Totalmoney_D money,
             @Rewards_d money,@MatRewards money,@cardRewards money,
             @deductAmount_D money,@matDeductAmount money
IF @formid IN (9158)
 BEGIN
     
     
     UPDATE BusinessAcceptance_H  
     SET    totalmoney1  = ISNULL(totalmoney, 0) -ISNULL(totalmoney2, 0)
     WHERE  doccode      = @doccode
 END
     
 IF @formid IN (9102, 9146,9237) ---客户新入网与套包销售    
 BEGIN    
		--取出单头的必要信息    
		SELECT @seriesnumber = seriesnumber, @sdorgid = uo.sdorgid, @sdgroup =     
			uo.sdgroup, @areaid = os.areaid, @stcode = uo.stcode, @ComboCode =     
			ComboCode, @PackageID = PackageID, @old =ISNULL( old,0), @NONeedAllocate =     
			isnull(uo.NONeedAllocate,0),@comboName=uo.ComboName,@price=isnull(uo.Price,0),@sdorgName=uo.sdorgname,@userName=uo.ModifyName,    
			@dpttype=uo.dptType,@docDate=uo.DocDate,@ICCID=uo.ICCID,@done=ISNULL(done,0),@node=ISNULL(uo.node,0),@DocStatus=DocStatus,
			@matmoney=isnull(uo.MatMoney,0),@CardMoney=isnull(uo.CardFEE1,0),@Matcode=matcode,
			@CardMatcode=uo.CardMatCode,@seriesCode=uo.SeriesCode,@SIMSeriescode=uo.CardNumber,@Nettype=uo.NetType,
			@totalmoney_H = Isnull(phonerate, 0) + Isnull(otherfee, 0) + Isnull(servicefee, 0) + Isnull(PackagePrice, 0) + Isnull(cardfee1, 0) +
			Isnull(uo.Price, 0) + Isnull(MatMoney, 0),@MatRewards=isnull(uo.MatRewards,0),@cardRewards=isnull(uo.CardRewards,0),
			@matDeductAmount=isnull(uo.matDeductAmount,0)
		FROM   Unicom_Orders uo  WITH(NOLOCK),oSDOrg os   WITH(NOLOCK)   
		WHERE  uo.DocCode = @doccode    
		AND os.SDOrgID=uo.sdorgid
		--单据金额=基础预存款+选号预存款+服务费+其他费用+明细单商品金额        
		Select @Totalmoney_D = Sum(Isnull(totalmoney, 0)),@Rewards_d= sum(isnull(userdigit2,0)),@deductAmount_D=sum(isnull(uod.DeductAmout,0))
		From   Unicom_OrderDetails uod With(Nolock)
		Where  uod.DocCode = @doccode
		       And Isnull(digit, 0) > 0
		Update Unicom_Orders
		Set    userdigit4 = Isnull(@totalmoney_H, 0) + Isnull(@Totalmoney_D, 0), 
		userdigit1 =  Isnull(@totalmoney_H, 0) + Isnull(@Totalmoney_D, 0)-Isnull(userdigit2, 0) -Isnull(YFKmoney, 0) -Isnull(summoney, 0) -Isnull(userdigit3, 0) -Isnull(userdigit5, 0),
		rewards = isnull(@Rewards_d,0)+isnull(@MatRewards,0)+isnull(@cardRewards,0),
		DeductAmout = isnull(@deductAmount_D,0)+isnull(@matDeductAmount,0)
		Where  DocCode = @doccode 
   end
     
     
 IF @formid IN (9128)    
 BEGIN    
     --检查是否有相同证件的不同客户,防止将客户资料改成其他客户的                                                
     IF EXISTS(    
            SELECT 1    
            FROM   Customers_H ch    
                   LEFT JOIN Customers c ON  ch.VoucherCode = c.VoucherCode    
            WHERE  ISNULL(ch.customercode, '') <> c.customercode    
                   AND doccode = @doccode    
        )    
     BEGIN    
         RAISERROR('您输入的证件已经登记，不需要重复登记该客户！', 16, 1)     
         RETURN    
     END    
     IF EXISTS(SELECT 1 FROM customers a,customers_h b    
               WHERE a.CustomerCode=b.CustomerCode    
               AND a.VoucherCode<>b.VoucherCode    
    AND b.DocCode=@doccode)    
              BEGIN    
               RAISERROR('该客户已登记,不允许修改证件编码!',16,1)    
               return    
              END       
 END    
END