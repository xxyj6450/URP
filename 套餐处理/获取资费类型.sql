SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION [dbo].[fn_getComboFeeType]()
	RETURNS VARCHAR(20)
AS
	BEGIN
		DECLARE @now INT,@ret VARCHAR(20)
		SELECT @now=day(GETDATE())
		IF @now<15  SET @ret='全月套餐'
		IF @now>=15 AND @now<26 SET @ret='套餐减半'
		IF @now>=26 SET @ret='套外资费'
		RETURN @ret
	end