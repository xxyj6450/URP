return
EXEC sp_configure 'show advanced options' , '1';
GO
reconfigure;
GO
EXEC sp_configure 'clr enabled' , '1'
reconfigure;
GO
sp_configure 'Ole Automation Procedures',1
RECONFIGURE
go

GO
DECLARE @Sql AS NVARCHAR(4000)
SELECT @Sql = 'ALTER DATABASE [' + DB_NAME() + '] SET TRUSTWORTHY ON' 
EXEC(@Sql)
GO
exec sp_changedbowner sa
go
DECLARE @Parameter AS NVARCHAR(MAX)
SELECT @Parameter =  CAST(database_identity AS NVARCHAR(MAX)) FROM dbo.tbl_MBS_Profile
EXEC [dbo].[usp_MBS_CMD] 'delete_configuration', @Parameter
GO
DROP TRIGGER [MoebiusTrigger_Root] ON DATABASE
GO
EXEC [dbo].[usp_MBS_CMD] 'uninstall', ''
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_MBS_CMD]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[usp_MBS_CMD]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_MBS_Rename]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[usp_MBS_Rename]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_MBS_InnerTruncateTable]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[usp_MBS_InnerTruncateTable]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_MBS_TruncateTable]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[usp_MBS_TruncateTable]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[udf_MBS_CheckSyncFromPartner]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[udf_MBS_CheckSyncFromPartner]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[udf_MBS_DecompressToBinary]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[udf_MBS_DecompressToBinary]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[udf_MBS_DecompressToLongBinary]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[udf_MBS_DecompressToLongBinary]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[udf_MBS_DecompressToLongString]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[udf_MBS_DecompressToLongString]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[udf_MBS_DecompressToString]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[udf_MBS_DecompressToString]
GO
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[udf_MBS_InnerCheckSyncFromPartner]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[udf_MBS_InnerCheckSyncFromPartner]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[udf_MBS_RegexMatch]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[udf_MBS_RegexMatch]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[udf_MBS_RegexReplace]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[udf_MBS_RegexReplace]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[udf_MBS_GenerateSyncLogId]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [dbo].[udf_MBS_GenerateSyncLogId]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tbl_MBS_Profile]') AND type in (N'U'))
	DROP TABLE [dbo].[tbl_MBS_Profile]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tbl_MBS_SystemObject]') AND type in (N'U'))
	DROP TABLE [dbo].[tbl_MBS_SystemObject]
GO
IF  EXISTS (SELECT * FROM sys.assemblies asms WHERE asms.name = N'GRQSH.Moebius.Core6')
	DROP ASSEMBLY [GRQSH.Moebius.Core6]
GO
IF  EXISTS (SELECT * FROM sys.assemblies asms WHERE asms.name = N'GRQSH.Moebius.Common6')
	DROP ASSEMBLY [GRQSH.Moebius.Common6]
GO
IF  EXISTS (SELECT * FROM sys.assemblies asms WHERE asms.name = N'GRQSH.Moebius.Core7')
	DROP ASSEMBLY [GRQSH.Moebius.Core7]
GO
IF  EXISTS (SELECT * FROM sys.assemblies asms WHERE asms.name = N'GRQSH.Moebius.Common7')
	DROP ASSEMBLY [GRQSH.Moebius.Common7]
GO

begin tran
declare @sql varchar(max),@name varchar(200)
declare cur CURSOR READ_ONLY fast_forward forward_only for 
select name from sysobjects s where s.xtype='TA'
and s.name like 'MoebiusTrigger_%'
open cur
fetch next FROM cur into @name
while @@FETCH_STATUS=0
	BEGIN
		select @sql='Drop TRIGGER '+@name
		exec(@sql)
		fetch next FROM cur into @name
	END
	close cur
	deallocate cur

rollback
commit