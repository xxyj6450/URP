/*
过程名称：[sp_WriteCard]
参数：见声名
返回值：
功能描述：将ESS卡号信息写入系统，并进行加密处理
编写：三断笛
时间：2012-02-08
备注：
示例：
*/
ALTER PROC [dbo].[sp_WriteCard]
	@SeriesNumber VARCHAR(20),
	@SeriesCode VARCHAR(30),
	@Doccode VARCHAR(20),
	@FormID INT,
	@ICCID VARCHAR(4000),
	@IMSI VARCHAR(4000),
	@USIM VARCHAR(50),
	@OptionID VARCHAR(4000),
	@Inrecords VARCHAR(4000)='',
	@isWriteen BIT=0,
	@City VARCHAR(50)='',
	@Brand VARCHAR(50)='',
	@BipCode VARCHAR(50)='',
	@ProcID VARCHAR(50)='',
	@CardType VARCHAR(50)='',
	@BusiType VARCHAR(50)=''
with ENCRYPTION 
AS
	BEGIN
		SET NOCOUNT ON;
		DECLARE @charSet VARCHAR(50),@Algorithm VARCHAR(50),@Key VARCHAR(500),@IV VARCHAR(500)
		declare @msg varchar(4000),@RowCount int
		select @msg='读卡失败！'
		SELECT @charSet='UTF-8',@Algorithm='Rijndael' 
		select @key=dbo.HashAlgorithm('/+rd5,hd+xt;szpzc,lljxk.','MD5',@charSet) ,@IV=dbo.HashAlgorithm('cmbj<,ccwtn,ylfys,hlz+-','MD5',@charSet)
		begin try
			--写入SIM卡信息
			UPDATE isiminfo
				SET 
				--IMSI=@IMSI,
				imsi_safe=dbo.SymmetricEncrypt(@IMSI, @Key ,left(@IV,16),@Algorithm,@charSet),
				OptionID=@OptionID,
				Inrecords=@Inrecords,
				isWriteen=0,
				usim=@USIM,
				Brand = @Brand,
				BipCode = @BipCode,
				ProcID = @ProcID,
				CardType = @CardType,
				BusiType = @BusiType,
				City = @City,
				--若是有传入参数,则更新之,否则不更新
				doccode=isnull(nullif(@doccode,''),doccode),
				Formid=isnull(nullif(@formid,''),formid),
				Seriesnumber=isnull(nullif(@SeriesNumber,''),seriesnumber)
			WHERE /*doccode=@Doccode
			AND formid=@FormID
			AND seriesnumber=@SeriesNumber
			AND */ ICCID=isnull(nullif(@USIM,''),@ICCID)
			select @Rowcount=@@ROWCOUNT
			IF @ROWCOUNT=0
				BEGIN
					--RAISERROR('SIM卡不存在,或不在可写状态,请先联系系统管理员再写卡!',16,1)
					--return
					insert into iSIMInfo(ICCID,SeriesNumber,SeriesCode,FormID,Doccode,IMSI_SAFE,
					OptionID,Inrecords,isWriteen,USIM,Brand,ProcID,CardType,BusiType,City,isLocked,isActived,isValid)
					select @ICCID,@SeriesNumber,left(@ICCID ,19),@FormID,@Doccode,dbo.SymmetricEncrypt(@IMSI, @Key ,left(@IV,16),@Algorithm,@charSet),
					@OptionID,@Inrecords,0,@usim,@Brand,@ProcID,@CardType,@BusiType,@City,0,0,1
					select @Rowcount=@@ROWCOUNT
				END
			--校验数据
			if not exists(select 1 from isiminfo where iccid=isnull(nullif(@usim,''),@ICCID) and isnull(imsi_safe,'')<>'' and isnull(optionid,'')<>'' )
				begin
					raiserror('SIM卡数据不完整，请重试!',16,1)
					return
				end
			/*UPDATE iSIMInfo
				SET imsi_safe=dbo.SymmetricEncrypt(@IMSI, @Key ,left(@IV,16),@Algorithm,@charSet)
			WHERE ICCID=@USIM*/
		END TRY
		BEGIN CATCH
			select @msg=@msg+Error_message()
			raiserror(@msg,16,1)
			return
		END CATCH
	END