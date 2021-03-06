 drop FUNCTION dbo.ExecuteTable
 drop FUNCTION dbo.ExecuteScalar
 drop PROCEDURE dbo.ExecuteNoQuery
 drop ASSEMBLY [SOP.ScriptEngine]
 go
CREATE ASSEMBLY [SOP.ScriptEngine]
    AUTHORIZATION [dbo]
    FROM 'E:\SOP.ScriptEngine.dll'
    WITH PERMISSION_SET = UNSAFE;
	go
 CREATE PROCEDURE [dbo].[ExecuteNoQuery]
@Language SMALLINT, @Expression NVARCHAR (4000), @DataSource NVARCHAR (4000), @Filter NVARCHAR (4000), @MaxRows INT, @Fields NVARCHAR (4000), @AutoAddQuotes BIT
AS EXTERNAL NAME [SOP.ScriptEngine].[SOP.ScriptEngine.ScriptEngine].[ExecuteNoQuery]
go
CREATE FUNCTION [dbo].[ExecuteScalar]
(@Language SMALLINT, @Expression NVARCHAR (4000), @DataSource NVARCHAR (4000), @Filter NVARCHAR (4000), @MaxRows INT, @Fields NVARCHAR (4000), @AutoAddQuotes BIT)
RETURNS SQL_VARIANT
AS
 EXTERNAL NAME [SOP.ScriptEngine].[SOP.ScriptEngine.ScriptEngine].[ExecuteScalar]
 go
 
CREATE FUNCTION [dbo].[ExecuteTable]
(@Language SMALLINT, @Expression NVARCHAR (4000), @DataSource NVARCHAR (4000), @Filter NVARCHAR (4000), @MaxRows INT, @Fields NVARCHAR (4000), @AutoAddQuotes BIT)
RETURNS 
     TABLE (
        [data1]  SQL_VARIANT NULL,
        [data2]  SQL_VARIANT NULL,
        [data3]  SQL_VARIANT NULL,
        [data4]  SQL_VARIANT NULL,
        [data5]  SQL_VARIANT NULL,
        [data6]  SQL_VARIANT NULL,
        [data7]  SQL_VARIANT NULL,
        [data8]  SQL_VARIANT NULL,
        [data9]  SQL_VARIANT NULL,
        [data10] SQL_VARIANT NULL,
        [data11] SQL_VARIANT NULL,
        [data12] SQL_VARIANT NULL,
        [data13] SQL_VARIANT NULL,
        [data14] SQL_VARIANT NULL,
        [data15] SQL_VARIANT NULL,
        [data16] SQL_VARIANT NULL,
        [data17] SQL_VARIANT NULL,
        [data18] SQL_VARIANT NULL,
        [data19] SQL_VARIANT NULL,
        [data20] SQL_VARIANT NULL)
AS
 EXTERNAL NAME [SOP.ScriptEngine].[SOP.ScriptEngine.ScriptEngine].[ExecuteTable]
go