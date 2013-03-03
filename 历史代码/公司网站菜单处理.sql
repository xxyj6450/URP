select * from cnk_channel

with cte_Channel as(
	select channelID,UpchannelID,ChannelName,
	convert(varbinary(max),convert(binary(4),row_number() over( partition by upchannelid order by paixu, ChannelID))) as path,
	convert(varchar(100),'.'+convert(varchar(4),channelid)+'.') as pathID,Paixu,0 as LEVEL--,0 AS isCycle
	from cnk_channel
	where upchannelid=0
	--order by paixu
	union all
	select b.channelid,b.upchannelid,b.channelname,
	a.path+convert(binary(4),row_number() over(partition by b.upchannelid order by b.paixu,b.channelid)),
	convert(varchar(100),a.pathid+convert(varchar(4),b.channelid)+'.'),b.paixu,a.level+1 
	--CASE '.'+CONVERT(VARCHAR(4),
	from cte_channel a join cnk_channel b
	
	on b.upchannelid=a.channelid
	)
	SELECT     * from cte_channel ORDER BY PATH
	
 
 alter FUNCTION fn_getMenu(@ChannelID int,@Lan INT)
 RETURNS @table TABLE(
 	ChannelID INT,
 	ChannelName VARCHAR(50),
 	UpchannelID INT DEFAULT 0,
 	PATH VARCHAR(200),
 	BinaryPath VARBINARY(MAX),
 	ChannelType INT DEFAULT 0,
 	ModuleType INT DEFAULT 1,
 	OpenType INT DEFAULT 0,
 	LEVEL INT)
 AS
	BEGIN
		DECLARE @level INT
		SELECT @level=0
		INSERT INTO @table
		SELECT ChannelId,CASE @Lan WHEN 0 THEN ChannelName WHEN 1 THEN ChannelName_en END,a.UpChannelID,
		'.'+CONVERT(VARCHAR(5),a.channelid)+'.' AS path,
		 CONVERT(VARBINARY(4),ROW_NUMBER() OVER (PARTITION BY upchannelid ORDER BY a.Paixu)) AS BinaryPath,
		ChannelType,ModuleType,OpenType,0
		FROM Cnk_Channel a
		WHERE ((@ChannelID=0 AND UpchannelID=0) OR a.ChannelID=@ChannelID)
		AND  IsStop=0 And IsShowNav=1 Order by Paixu
		WHILE @@ROWCOUNT>0
			BEGIN
				SELECT @level=@level+1
				INSERT INTO @table
				SELECT a.ChannelId,CASE @Lan WHEN 0 THEN a.ChannelName WHEN 1 THEN a.ChannelName_en END,a.UpChannelID,
				b.[PATH] +CONVERT(VARCHAR(5),a.channelid)+'.' AS path,
				 b.binarypath+CONVERT(VARBINARY(4),ROW_NUMBER() OVER (PARTITION BY a.upchannelid ORDER BY a.Paixu))  AS BinaryPath,
				a.ChannelType,a.ModuleType,a.OpenType,@level
					FROM Cnk_Channel a join @table b ON a.UpChannelID=b.ChannelID
					WHERE   b.[LEVEL]=@level-1
					 AND a.IsStop=0 And a.IsShowNav=1
					Order by Paixu																		
			END
		return
	END
 	
 	SELECT * FROM fn_getmenu(0,0) ORDER BY binarypath
 	