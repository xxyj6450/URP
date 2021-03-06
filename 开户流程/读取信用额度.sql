/*                                
* 函数名称：fn_getOSDCredit          
* 功能描述：取门店信贷额度          
* 参数:见声名部分                                
* 编写：三断笛                                
* 时间：2010/09/4          
* 备注：当@optional=0时取门店当前的信贷额度。当@optional=1时取门店当前未确认的金额（含套包销售单和入网单）          
* 示例： 按门店层级结构取最底层的信用额度          
* --------------------------------------------------------------------                                
* 修改：2012-08-22 修改取信用额度的方式 三断笛
* 时间：                                
* 备注：                                
*                                 
*/           
ALTER FUNCTION [dbo].[fn_getOSDCredit](@sdorgid VARCHAR(40),@optional int)          
 RETURNS MONEY          
AS          
 BEGIN          
  DECLARE @credit MONEY,@totalmoney3 money,@totalmoney2 money,@totalmoney1 money,@CreditSdorgID varchar(50)
  
    --取门店价格树中最低级别门店的价格 门店树已经是按级别从低到高排序，故只需取第一个能取到价格的门店价格即可（top 1)          
  IF @optional=0           
   BEGIN          
    --建立门店树          
/*    ;with  cte_sdorg(sdorgid,sdorgname,areaid,credit ,rowid,parentrowid,level)AS(        --门店树          
      SELECT sdorgid,sdorgname,areaid,credit, rowid,parentrowid,0           
       FROM osdorg a          
      WHERE a.SDOrgID=@sdorgid and isnull(LimitCredit,0)=1          
       UNION ALL          
      SELECT a.sdorgid,a.sdorgname,a.areaid,a.credit ,a.rowid,a.parentrowid,b.level+1          
      FROM   cte_sdorg b join osdorg a ON b.parentrowid=a.rowid          
    )          
    --取最低层的信用额度          
    SELECT top 1 @credit=isnull(credit,0)          
    FROM cte_sdorg a           
    WHERE isnull(credit,0)<>0-- IS NOT NULL 
*/
     select @CreditSdorgID=o.SDOrgID
       from osdorg g with(nolock) left join osdorg o with(nolock) on g.parentrowid=o.rowid where g.sdorgid=@sdorgid
      select @credit=osc.AvailableBalance
        from oSDOrgCredit osc where osc.SDOrgID=@CreditSdorgID
 
     RETURN isnull(@credit,0)          
   END          
  IF @optional=1          
   BEGIN          
         
    declare @prerowid varchar(50)        
    select @prerowid=g.parentrowid from osdorg g with(nolock) where g.sdorgid=@sdorgid       
    select @totalmoney3=osc.FrozenAmount
      from oSDOrgCredit osc where osc.SDOrgID=@sdorgid 
		--统计未确认的应收金额          
	   /* SELECT @totalmoney2=SUM(ISNULL(totalmoney2,0)) FROM Unicom_Orders uo          
		WHERE uo.FormID IN(9102,9146)          
		AND uo.sdorgid in (select sdorgid from osdorg where parentrowid=@prerowid)--=@sdorgid          
		AND uo.DocStatus=0          
		AND isnull(uo.checkState,'') in ('通过审核','待审核')      
		select @totalmoney1=sum(isnull(totalmoney,0)) from BusinessAcceptance_H    
	 where formid in (9167) and docstatus=0 and isnull(checkstate,'') in ('通过审核','待审核') and dpttype='加盟店'    
	 AND sdorgid in (select sdorgid from osdorg where parentrowid=@prerowid)    
	    
	 select @totalmoney3=isnull(@totalmoney2,0)+isnull(@totalmoney1,0)    */
    RETURN @totalmoney3          
   END          
  RETURN 0          
 END          
           
           
        
      
