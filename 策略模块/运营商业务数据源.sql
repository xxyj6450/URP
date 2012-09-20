ALTER VIEW [dbo].[v_UnicomOrders]  
AS  
SELECT     dbo.Unicom_Orders.DocCode, dbo.Unicom_Orders.FormID, dbo.Unicom_Orders.DocType, dbo.Unicom_Orders.DocDate, dbo.Unicom_Orders.periodid,   
                      dbo.Unicom_Orders.refformid, dbo.Unicom_Orders.refcode, dbo.Unicom_Orders.Companyid, dbo.Unicom_Orders.sdorgid, dbo.Unicom_Orders.cltCode,   
                      dbo.Unicom_Orders.stcode, dbo.Unicom_Orders.sdgroup, dbo.Unicom_Orders.sumnetmoney, dbo.Unicom_Orders.userdigit1,   
                      dbo.Unicom_Orders.userdigit2, dbo.Unicom_Orders.userdigit3, dbo.Unicom_Orders.userdigit4, dbo.Unicom_Orders.usertxt3,   
                      dbo.Unicom_Orders.usertxt2, dbo.Unicom_Orders.usertxt1, dbo.Unicom_Orders.PayType, dbo.Unicom_Orders.checkState, 
                      --开户信息
                      dbo.Unicom_Orders.PackageID, dbo.Unicom_Orders.SeriesNumber, dbo.Unicom_Orders.NetType, dbo.Unicom_Orders.ComboCode, 
                      dbo.Unicom_Orders.ComboName, dbo.Unicom_Orders.comboFEEType, 
                      --费用信息
                      dbo.Unicom_Orders.summoney,   
                      dbo.Unicom_Orders.RulesFEE, dbo.Unicom_Orders.ServiceFEE, dbo.Unicom_Orders.PhoneRate,   
                      dbo.Unicom_Orders.CardFEE, dbo.Unicom_Orders.OtherFEE, Unicom_Orders.cardfee1,
                       dbo.Unicom_Orders.ComboFEE,   dbo.Unicom_Orders.rewards, dbo.Unicom_Orders.totalmoney2, dbo.Unicom_Orders.DeductAmout, 
                       dbo.Unicom_Orders.totalmoney3, dbo.Unicom_Orders.totalmoney4, dbo.Unicom_Orders.Credit, dbo.Unicom_Orders.commission, 
                       --预存款项
                       dbo.Unicom_Orders.Price, uo.Deposits,uo.BasicDeposits,uo.minDeposits,uo.DepositsMatcode,uo.DepositsMatName,
                      --手机信息,空白卡
                      dbo.Unicom_Orders.CardNumber,dbo.Unicom_Orders.MatCode, case when isnull(dbo.Unicom_Orders.seriescode,'')='' then 0 else 1 end as Digit, --dbo.Unicom_OrderDetails.price AS SalePrice, dbo.Unicom_OrderDetails.netprice,   
                      dbo.Unicom_Orders.matmoney , dbo.Unicom_Orders.Matscore  as price2, dbo.Unicom_Orders.seriesCode,   
                      --dbo.Unicom_OrderDetails.selfprice, dbo.Unicom_OrderDetails.selfprice1, dbo.Unicom_OrderDetails.salesprice1, dbo.Unicom_OrderDetails.end4,   
                      dbo.iMatgeneral.mattype,     dbo.iMatGeneral.MatGroup,   
                      dbo.iMatGeneral.matname, dbo.iMatGeneral.isActived, dbo.iMatGeneral.MatState, dbo.iMatGeneral.MatFlag, dbo.iMatGeneral.MatImeiLong,   
                      dbo.iMatGroup.matgroupname, dbo.iMatGroup.PATH AS matgroupPath, dbo.iSeries.vndcode, dbo.iSeries.purGRdate, dbo.iSeries.purGRDocCode, dbo.iSeries.state,   
                      --号码信息
                      dbo.Unicom_Orders.preAllocation,   
                     dbo.Unicom_Orders.inPool, dbo.Unicom_Orders.intype,   
                       dbo.Unicom_Orders.ReservedDoccode, dbo.Unicom_Orders.bitReturnd,   
                     
                    --门店信息
                      dbo.oSDOrg.SDOrgName, dbo.oSDOrg.AreaID, dbo.oSDOrg.dptType, dbo.oSDOrg.PATH AS SDorgPath,  
                      dbo.iSeries.AreaCode,ga.[PATH] AS areaPath,osdorg.mintype,dbo.iSeries.salesprice AS PickupPrice,
                      --政策信息
                      Unicom_Orders.packagename,dbo.Unicom_Orders.PackageCode, --dbo.Unicom_OrderDetails.DocItem, dbo.Unicom_OrderDetails.rowid,   
                      pg.PolicygroupID AS packageTypeID,pg.PolicyGroupName AS PackageType,dbo.Unicom_Orders.node,
                     pg.path as PolicyGroupPath,pg.OpenAccount, pg.oldCustomerBusi as old,pg.hasPhone,pg.StockState
FROM         dbo.Unicom_Orders WITH(NOLOCK)
					inner JOIN policy_h ph ON dbo.Unicom_Orders.PackageID=ph.DocCode 
                    inner Join T_PolicyGroup pg On ph.PolicygroupID=pg.PolicyGroupID
					 INNER JOIN dbo.oSDOrg WITH(NOLOCK) ON dbo.Unicom_Orders.sdorgid = dbo.oSDOrg.SDOrgID   
					 INNER JOIN   gArea ga ON dbo.oSDOrg.AreaID=ga.areaid  
					left JOIN iMatgeneral WITH(NOLOCK) ON Unicom_Orders.MatCode=iMatgeneral.MatCode  
                    left Join  dbo.iMatGroup ON dbo.iMatGeneral.MatGroup = dbo.iMatGroup.matgroup   
                    left JOIN  dbo.iSeries   WITH(NOLOCK) ON dbo.Unicom_Orders.seriesCode = dbo.iSeries.SeriesCode, unicom_orders uo
                    
 



GO


