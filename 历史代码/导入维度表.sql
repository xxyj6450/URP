
 /*
 过程名称:sp_ImportDIMData 'ostorage'
 功能描述:将维度数据从业务系统导入到中间处理系统,进行一些数据整理与转换
参数:表名称,可为空,为空时导入所有维度.表名称可以模糊匹配.
编写:三断笛
时间:2011-08-03
备注:

*/
ALTER PROC [dbo].[sp_ImportDIMData]
	@TableName VARCHAR(50)=''
AS
	BEGIN
		SET NOCOUNT ON
		SET XACT_ABORT ON
		BEGIN TRAN
		IF @TableName LIKE '%iMatGroup' OR @TableName=''
			BEGIN
				--
				DELETE FROM SOP_DIM_iMatGeneral
				DELETE FROM SOP_DIM_iMatGroup
				INSERT INTO SOP_DIM_iMatGroup(strmatgroup,STRmatgroupname,rowid,treeControl,parentrowid,strFullName,IMPORTDATE)
				SELECT matgroup,matgroupname,rowid,treecontrol,parentrowid,matgroupname,GETDATE()
				FROM iERPTest..imatgroup
				;WITH cte AS(
				SELECT 	rowid,parentrowid,convert(varchar(500),strmatgroupname) AS fullname
				FROM SOP_DIM_iMatGroup WHERE ISNULL(parentrowid,'')=''
				UNION ALL
				SELECT a.rowid,a.parentrowid,CONVERT(VARCHAR(500),b.fullname+'_'+a.strmatgroupname)
				FROM SOP_DIM_iMatGroup a join cte b ON a.parentrowid=b.rowid)
				UPDATE SOP_DIM_iMatGroup
					SET strFullName = a.fullname
				FROM cte a,SOP_DIM_iMatGroup b 
				WHERE a.rowid=b.rowid
				INSERT INTO _sysImportLog(DataSource,[Event],UserName) VALUES(@TableName,'导入商品大类维度数据','system')
				exec sp_ImportDIMData 'iMatgeneral'			
			END
			IF @TableName LIKE '%MatType' OR @TableName=''
			BEGIN
				DELETE FROM dbo.SOP_dim_MatType
				SET IDENTITY_INSERT  dbo.SOP_dim_MatType on
				INSERT INTO SOP_dim_MatType(intMatTypeCode,strMatTypeName,strmatgroup,IMPORTDATE)
				SELECT  MatTypeCode, MatTypeName, matgroup, GETDATE()
				FROM iERPTest..MatType
				INSERT INTO _sysImportLog(DataSource,[Event],UserName) VALUES(@TableName,'导入商品型号维度数据','system')			
			END
		IF @TableName LIKE '%iMatGeneral' OR @TableName=''
			BEGIN
				DELETE FROM SOP_DIM_iMatGeneral
				/*INSERT INTO sop_dim_imatgeneral( strMatCode, strMatName, 
				       strMatGroup, strpackagecode, strBaseUOM, strsalesUOM, 
				       baseuomrate, uomrate, mnyinprice, saleprice, strbrand, 
				       strratetxt, straccount, straccountno, dblcubage, 
				       intisActived, mnytransfeeRate,intmattype, strMatType, bitMatState, 
				       bitMatFlag, intMatImeiLong, strmatlife, bitsupplyflag, 
				       intstockxx, intstocksx, bitdeduct, strVNDCode, 
				       strmatstatus, intstockcycle, mnypurprice, bitprofit, iszh, 
				       bitchangesale, strUOM, bitOnlyForReserveCustomer, 
				       strsystem, strNetType, strSaleState, IMPORTDATE)*/
				INSERT INTO sop_dim_imatgeneral( strMatCode, strMatName, strMatGroup, 
				       matgroupRowID, strpackagecode, strBaseUOM, strsalesUOM, 
				       baseuomrate, uomrate, mnyinprice, saleprice, strbrand, 
				       strratetxt, straccount, straccountno, dblcubage, 
				       intisActived, mnytransfeeRate, intMatTypeCode, strMatTypeName, 
				       bitMatState, bitMatFlag, intMatImeiLong, strmatlife, 
				       bitsupplyflag, intstockxx, intstocksx, bitdeduct, 
				       strVNDCode, strmatstatus, intstockcycle, mnypurprice, 
				       bitprofit, iszh, bitchangesale, strUOM, 
				       bitOnlyForReserveCustomer, strsystem, strNetType, 
				       strSaleState, IMPORTDATE)
				SELECT MatCode, MatName, 
				       a.MatGroup,b.rowid AS matgroupRowID, packagecode, BaseUOM, salesUOM, 
				       baseuomrate, uomrate, inprice, saleprice, brand, 
				       ratetxt, account, accountno, cubage, 
				       isActived, transfeeRate,c.mattypecode, c.MatTypename, MatState, 
				       MatFlag, MatImeiLong, matlife, supplyflag, 
				       stockxx, stocksx, deduct, VNDCode, 
				       matstatus, stockcycle, purprice, profit, iszh, 
				       changesale, UOM, OnlyForReserveCustomer, 
				       system, NetType, SaleState, GETDATE()
				FROM iERPTest..imatgeneral a 
				left join ierptest..mattype c ON a.mattype=c.mattypename 
				,ierptest..imatgroup b
				WHERE a.matgroup=b.matgroup
				
				INSERT INTO _sysImportLog(DataSource,[Event],UserName) VALUES(@TableName,'导入商品维度数据','system')			
			END

		IF @TableName LIKE '%gArea' OR @TableName=''
			BEGIN
				DELETE FROM SOP_DIM_OStorage
				DELETE FROM SOP_DIM_gArea
				INSERT INTO SOP_DIM_gArea(strAreaID,strareaname,strFullName,RowID,ParentRowID,TreeControl,IMPORTDATE)
				SELECT AreaID,areaname,areaname,RowID,ParentRowID,TreeControl,GETDATE()
				FROM iERPTest..gArea
				;WITH cte AS(
				SELECT 	rowid,parentrowid,convert(varchar(500),strareaname) AS fullname
				FROM SOP_DIM_gArea WHERE ISNULL(parentrowid,'')=''
				UNION ALL
				SELECT a.rowid,a.parentrowid,CONVERT(VARCHAR(500),b.fullname+'_'+a.strareaname)
				FROM SOP_DIM_gArea a join cte b ON a.parentrowid=b.rowid)
				UPDATE SOP_DIM_gArea
					SET strFullName = a.fullname
				FROM cte a,SOP_DIM_gArea b 
				WHERE a.rowid=b.rowid
				INSERT INTO _sysImportLog(DataSource,[Event],UserName) VALUES(@TableName,'导入区域维度数据','system')
				EXEC sp_ImportDIMData 'oStorage'
			END
		IF @TableName LIKE '%oSDORG' OR @TableName=''
			BEGIN
				DELETE FROM SOP_DIM_oSDORG
				INSERT INTO SOP_DIM_oSDORG(strSDOrgID,strSDOrgName,strcurCode,rowid,TreeControl,parentrowid,strAreaID,strdptType,strmintype,bitLimitCredit,strcashno,bitisSaled,strFullName,IMPORTDATE)
				SELECT SDOrgID,SDOrgName,isnull(curCode,''),rowid,TreeControl,parentrowid,isnull(AreaID,''),isnull(dptType,''),isnull(mintype,''),
				isnull(LimitCredit,0),isnull(cashno,''),isnull(isSaled,0),isnull(sdorgname,''),GETDATE()
				FROM iERPTest..oSDORG
				;WITH cte AS(
				SELECT 	rowid,parentrowid,convert(varchar(500),strSDOrgName) AS fullname
				FROM SOP_DIM_oSDORG WHERE ISNULL(parentrowid,'')=''
				UNION ALL
				SELECT a.rowid,a.parentrowid,CONVERT(VARCHAR(500),b.fullname+'_'+a.strSDOrgName)
				FROM SOP_DIM_oSDORG a join cte b ON a.parentrowid=b.rowid)
				UPDATE SOP_DIM_oSDORG
					SET strFullName = a.fullname
				FROM cte a,SOP_DIM_oSDORG b 
				WHERE a.rowid=b.rowid
				INSERT INTO _sysImportLog(DataSource,[Event],UserName) VALUES(@TableName,'导入部门维度数据','system')			
			END
		IF @TableName LIKE '%OSDGROUP' OR @TableName=''
			BEGIN
				DELETE FROM SOP_DIM_OSDGroup
				INSERT INTO sop_dim_OSDGROUP( strSDGroup,strSDGroupName,rowid,blocked,sex,sdorgid,usercode, IMPORTDATE)
				SELECT SDGroup,SDGroupName,rowid,blocked,sex,sdorgid,usercode, GETDATE()
				FROM iERPTest..OSDGROUP
				INSERT INTO _sysImportLog(DataSource,[Event],UserName) VALUES(@TableName,'导入人员维度数据','system')			
			END
		IF @TableName LIKE '%oStorage' OR @TableName=''
			BEGIN
				DELETE FROM SOP_DIM_oStorage
				INSERT INTO SOP_DIM_oStorage(strPlantID,strstCode,strStName,strDeputy,strsdorgid,strareaid, IMPORTDATE)
				SELECT PlantID,stCode,name40,isnull(a.Deputy,''),a.sdorgid,a.areaid, GETDATE()
				FROM iERPTest..oStorage a
				INSERT INTO _sysImportLog(DataSource,[Event],UserName) VALUES(@TableName,'导入仓库维度数据','system')			
			END
		IF @TableName LIKE '%oCompany' OR @TableName=''
			BEGIN
				DELETE FROM SOP_DIM_oCompany
				INSERT INTO SOP_DIM_oCompany(companyid,companyName, IMPORTDATE)
				SELECT companyid,companyName, GETDATE()
				FROM iERPTest..oCompany
				INSERT INTO _sysImportLog(DataSource,[Event],UserName) VALUES(@TableName,'导入仓库维度数据','system')			
			END
		IF @TableName LIKE '%pVNDGeneral' OR @TableName=''
			BEGIN
				DELETE FROM SOP_DIM_pVNDGeneral
				INSERT INTO SOP_DIM_pVNDGeneral(strvndCode,strvndname,strvndGroup,strvndType,strBusinessType, IMPORTDATE)
				SELECT vndCode,isnull(vndname,''),isnull(vndGroup,''),isnull(vndType,''),isnull(BusinessType,''), GETDATE()
				FROM iERPTest..pVNDGeneral
				INSERT INTO _sysImportLog(DataSource,[Event],UserName) VALUES(@TableName,'导入仓库维度数据','system')			
			END
		IF @TableName LIKE '%policy_H' OR @TableName=''
			BEGIN
				DELETE FROM SOP_DIM_policy_H
				INSERT INTO SOP_DIM_policy_H( DocCode, PackageName, FormID, DocType, TotalMoney, 
				       DocDate, bitactived, dblRewards, bitForceCheckDoc, 
				       CreditPolicy, bitold, bitiself, bitNONeedAllocate, 
				       dblminPrice, bitOnlyReservedCustomer, IMPORTDATE)
				SELECT DocCode,ISNULL(PackageName,''),ISNULL(FormID,0),ISNULL(DocType,''),ISNULL(TotalMoney,0),DocDate,
				ISNULL(actived,0),ISNULL(Rewards,0),ISNULL(ForceCheckDoc,0),ISNULL(CreditPolicy,0),ISNULL(old,0),ISNULL(iself,0),
				ISNULL(NONeedAllocate,0),ISNULL(minPrice,0),ISNULL(OnlyReservedCustomer,0),GETDATE()
				FROM   iERPTest..policy_H where formid = 9110
				INSERT INTO _sysImportLog(DataSource,[Event],UserName) VALUES(@TableName,'导入政策维度数据','system')			
			END
			IF @TableName LIKE '%COMBO_H' OR @TableName=''
			BEGIN
				DELETE FROM SOP_dim_Combo
				INSERT INTO SOP_dim_Combo(intComboCode,strComboType,strComboName,mnyPrice,strComboPlan,bitActived,dtmValidDate,strComboType1,mnyminPrice, IMPORTDATE)
				SELECT isnull(ComboCode,0),isnull(ComboType,''),isnull(ComboName,''),isnull(Price,0),isnull(ComboPlan,''),isnull(Actived,0),ValidDate,isnull(ComboType1,''),isnull(minPrice,0), GETDATE()
				FROM iERPTest..COMBO_H
				INSERT INTO _sysImportLog(DataSource,[Event],UserName) VALUES(@TableName,'导入套餐维度数据','system')			
			END

			IF @@ERROR=0
				COMMIT
			ELSE
				ROLLBACK
	END
/*
DECLARE @sql VARCHAR(MAX)
SELECT @sql=''
SELECT @sql=@sql+NAME+',' FROM syscolumns s WHERE s.id=OBJECT_ID('SOP_DIM_iMatGeneral')
PRINT @sql

*/