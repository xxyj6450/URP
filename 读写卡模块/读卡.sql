 
 
 /*
过程名称：[getSIMInfo]
参数：见声名
返回值：
功能描述：从ESS读出SIM卡信息，并进行解密
编写：三断笛
时间：2012-02-08
备注：
示例：select * from [getSIMInfo] ('PS20120215000342','18603078261','89860112851001387234')
*/
 ALTER FUNCTION [dbo].[getSIMInfo](
	@Doccode VARCHAR(20),
	@SeriesNumber VARCHAR(20),
	@USIM VARCHAR(50)
)
RETURNS  @table  TABLE (
	SeriesNumber VARCHAR(20),
	ICCID VARCHAR(30),
	IMSI VARCHAR(30),
	OptionId VARCHAR(4000),
	Inrecords VARCHAR(4000),
	STATUS INT,
	isLocked BIT,
	isWriteen BIT,
	isActived BIT,
	ERRORTEXT VARCHAR(500)
	)
as
 
	 BEGIN
	 	DECLARE @charSet VARCHAR(50),@Algorithm VARCHAR(50),@Key VARCHAR(500),@IV VARCHAR(500)
 		SELECT @charSet='UTF-8',@Algorithm='Rijndael' 
		select @key=dbo.HashAlgorithm('/+rd5,hd+xt;szpzc,lljxk.','MD5',@charSet) ,@IV=dbo.HashAlgorithm('cmbj<,ccwtn,ylfys,hlz+-','MD5',@charSet)
	 	INSERT INTO @table
		SELECT seriesnumber,ICCID,ltrim(rtrim(COALESCE(NULLIF(imsi,''),	dbo.SymmetricDecrypt(IMSI_SAFE,@Key,left(@IV,16),@Algorithm,@charSet)))), 
		OptionID,Inrecords,[Status],isLocked,isWriteen,isActived,NULL
		  FROM isiminfo WHERE     iccid=@USIM
		IF @@ROWCOUNT=0
			BEGIN
				UPDATE @table SET ERRORTEXT = 'ICCID不存在,或已更换,请换卡!'
			END
		IF NOT EXISTS(SELECT 1 FROM @table WHERE SeriesNumber=@SeriesNumber)
			BEGIN
				UPDATE @table SET ERRORTEXT = 'SIM卡未与此号码绑定!'
			END
		IF NOT EXISTS(SELECT 1 FROM @table WHERE isLocked=1)
			BEGIN
				UPDATE @table SET ERRORTEXT = 'SIM卡尚未提交ESS系统,不能写卡!'
			END
		IF NOT EXISTS(SELECT 1 FROM @table WHERE isActived=1)
			BEGIN
				UPDATE @table SET ERRORTEXT = 'SIM卡尚未激活,不允许写卡!'
			END
		IF   EXISTS(SELECT 1 FROM @table WHERE ISNULL(IMSI,'')='' or isnumeric(isnull(imsi,''))=0)
			BEGIN
				UPDATE @table
				SET ERRORTEXT = '未读取到SIM卡数据，请联系系统管理员！'
			END
		 return
	 END

 