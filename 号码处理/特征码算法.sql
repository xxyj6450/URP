SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/************************************************************
 函数名称：fn_getconditioncode
功能描述：获取号码特征码及等级
参数说明：见声名部分
编写:三断笛
时间：2010/06
备注：
示例：
-------------------------------------------------------------
修改：
时间：
备注：
 ************************************************************/

--SELECT * FROM fn_getconditioncode('18612345678')
ALTER FUNCTION [dbo].[fn_getConditionCode]
(
	@SeriesNumber VARCHAR(20)
)
RETURNS @table TABLE(SeriesNumber VARCHAR(20),Condition_Code VARCHAR(10),grade 
         VARCHAR(5))
AS


  
-- select * from fn_getConditionCode('15967896789')  
BEGIN
	DECLARE @grade                                                              VARCHAR(5) 
	--取末8位  
	DECLARE @s1 INT, @s2 INT, @s3 INT, @s4 INT, @s5 INT, @s6 INT, @s7 INT, @s8  INT
	
	IF LEN(ISNULL(@SeriesNumber,'')) <> 11 --非法号码
	BEGIN
	    INSERT INTO @table
	    VALUES('','','')
	    RETURN
	END
	
	SELECT @s1 = SUBSTRING(@seriesnumber,4,1),@s2 = SUBSTRING(@seriesnumber,5,1),
	       @s3 = SUBSTRING(@seriesnumber,6,1),@s4 = SUBSTRING(@seriesnumber,7,1),
	       @s5 = SUBSTRING(@seriesnumber,8,1),@s6 = SUBSTRING(@seriesnumber,9,1),
	       @s7 = SUBSTRING(@seriesnumber,10,1),@s8 = SUBSTRING(@seriesnumber,11, 1)
	
	IF ((@s1 = @s2 AND @s2 = @s3 AND @s3 = @s4)
	       AND (@s5 = @s6 AND @s6 = @s7 AND @s7 = @s8))
	BEGIN
	    INSERT INTO @table
	    VALUES(@SeriesNumber,'AAAABBBB','S') 
	    RETURN
	END
	ELSE 
	IF (@s3 = @s4
	       AND @s4 = @s5
	       AND @s6 = @s7
	       AND @s7 = @s8
	       AND @s5 <> @s6)
	BEGIN
	    INSERT INTO @table
	    VALUES(@SeriesNumber,'AAABBB','S') 
	    RETURN
	END
	ELSE 
	IF (@s4 = @s5 AND @s5 = @s6 AND @s6 = @s7 AND @s7 = @s8) --AAAAA
	BEGIN
	    IF @s4 = '8'
	        SET @grade = 'A'
	    
	    IF @s4 IN ('3', '6', '9')
	        SET @grade = 'B'
	    
	    IF @s4 IN ('0', '1', '2', '5', '7')
	        SET @grade = 'C'
	    
	    IF @s4 IN ('4')
	        SET @grade = 'D'
	    
	    INSERT INTO @table
	    VALUES(@SeriesNumber,'AAAAA',@grade) 
	    RETURN
	END
	ELSE 
	IF (@s5 = @s6 AND @S6 = @s7 AND @s7 = @s8) --AAAA
	BEGIN
	    IF @s4 = '8'
	        SET @grade = 'A'
	    
	    IF @s4 IN ('3', '6', '9')
	        SET @grade = 'B'
	    
	    IF @s4 IN ('0', '1', '2', '5', '7')
	        SET @grade = 'C'
	    
	    IF @s4 IN ('4')
	        SET @grade = 'D'
	    
	    INSERT INTO @table
	    VALUES(@SeriesNumber,'AAAA',@grade) 
	    RETURN
	END
	ELSE 
	IF (@s5 -@s4 = @s6 -@s5
	       AND @s7 -@S6 = @s6 -@s5
	       AND @s8 -@s7 = @s7 -@S6) and abs(@s5-@s4)=1 --ABCDE
	BEGIN
	    INSERT INTO @table
	    VALUES(@SeriesNumber,'ABCDE','E') 
	    RETURN
	END
	ELSE 
	IF ((@s6 -@S5 = @s7 -@s6 AND @s7 -@s6 = @s8 -@S7)
	       AND (@s1 = @s5 AND @s2 = @s6 AND @s3 = @s7 AND @s4 = @s8)) --ABCDABCD
	BEGIN
	    INSERT INTO @table
	    VALUES(@SeriesNumber,'ABCDABCD','E') 
	    RETURN
	END
	ELSE 
	IF (@s6 = @s7 AND @s7 = @s8) --AAA
	BEGIN
	    IF @s6 = '8'
	        SET @grade = 'A'
	    
	    IF @s6 IN ('3', '6', '9')
	        SET @grade = 'B'
	    
	    IF @s6 IN ('0', '1', '2', '5', '7')
	        SET @grade = 'C'
	    
	    IF @s6 IN ('4')
	        SET @grade = 'D'
	    
	    INSERT INTO @table
	    VALUES(@SeriesNumber,'AAA',@grade) 
	    RETURN
	END
	ELSE 
	IF (@s3 = @s4 AND @s5 = @s6 AND @s7 = @s8)
	BEGIN
	    INSERT INTO @table
	    VALUES(@SeriesNumber,'AABBCC','E') --AABBCC  
	    RETURN
	END
	ELSE 
	IF ((@s4 -@s3 = @s5 -@s4)
	       AND (@s6 = @s3 AND @s7 = @s4 AND @s8 = @s5)) --ABCABC
	BEGIN
	    INSERT INTO @table
	    VALUES(@SeriesNumber,'ABCABC','E') 
	    RETURN
	END
	ELSE 
	IF (@s6 = @s5 + 1 AND @s7 = @s6 + 1 AND @s8 = @s7 + 1) --ABCD
	BEGIN
	    INSERT INTO @table
	    VALUES(@SeriesNumber,'ABCD','F') 
	    RETURN
	END
	ELSE 
	IF ((@s5 = @s6 AND @s7 = @s8)) --AABB
	BEGIN
	    IF @s8 = '8'
	        SET @grade = 'A'
	    
	    IF @s8 IN ('3', '6', '9')
	        SET @grade = 'B'
	    
	    IF @s8 IN ('0', '1', '2', '5', '7')
	        SET @grade = 'C'
	    
	    IF @s8 IN ('4')
	        SET @grade = 'D'
	    
	    INSERT INTO @table
	    VALUES(@SeriesNumber,'AABB',@grade) 
	    RETURN
	END
	ELSE 
	IF ((@s7 = @s5 AND @s8 = @s6)) --ABAB
	BEGIN
	    IF @s8 = '8'
	        SET @grade = 'A'
	    
	    IF @s8 IN ('3', '6', '9')
	        SET @grade = 'B'
	    
	    IF @s8 IN ('0', '1', '2', '5', '7')
	        SET @grade = 'C'
	    
	    IF @s8 IN ('4')
	        SET @grade = 'D'
	    
	    INSERT INTO @table
	    VALUES(@SeriesNumber,'ABAB',@grade) 
	    RETURN
	END
	ELSE 
	IF (@s4 = @s5 AND @s5 = @s6 AND @s6 = @s7) --AAAAB
	BEGIN
	    INSERT INTO @table
	    VALUES(@SeriesNumber,'AAAAB','E') 
	    RETURN
	END
	ELSE 
	IF (@s5 = @s6 AND @s6 = @s7) --AAAB
	BEGIN
	    INSERT INTO @table
	    VALUES(@SeriesNumber,'AAAB','F') 
	    RETURN
	END
	ELSE 
	IF (@S7 = @s8) --AA
	BEGIN
	    IF @s8 = '8'
	        SET @grade = 'A'
	    
	    IF @s8 IN ('3', '6', '9')
	        SET @grade = 'B'
	    
	    IF @s8 IN ('0', '1', '2', '5', '7')
	        SET @grade = 'C'
	    
	    IF @s8 IN ('4')
	        SET @grade = 'D'
	    
	    INSERT INTO @table
	    VALUES(@SeriesNumber,'AA',@grade) 
	    RETURN
	END
	ELSE 
	IF (@S7 -@s6 = @s8 -@s7)  and abs(@s7-@s6)=1--ABC
	BEGIN
	    INSERT INTO @table
	    VALUES(@SeriesNumber,'ABC','E') 
	    RETURN
	END
	ELSE
	BEGIN
	    INSERT INTO @table
	    VALUES(@SeriesNumber,'NORMAL','N') 
	    RETURN
	END 
	RETURN
END  