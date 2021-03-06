 
-- EXEC [SP_SYSPROCESSLEDGER] 9146,'PS20110606000802','101','2011-09','system','system'
alter PROC [dbo].[SP_SYSPROCESSLEDGER]
	@FormID INT,
	@Doccode VARCHAR(20)='',
	@CompanyId VARCHAR(20),
	@Period VARCHAR(10),
	@UserCode VARCHAR(20)='',
	@userName VARCHAR(50)='',
	@OptionID VARCHAR(50)=''
AS
	BEGIN
		DECLARE @sql nVARCHAR(MAX) 
		DECLARE @glType VARCHAR(50),@glCode VARCHAR(10),@dcFlag CHAR(2),@dataView VARCHAR(50),@DataFileter VARCHAR(500),
		@AmountFiled VARCHAR(50),@natAmountFiled VARCHAR(50),@glCompanyID VARCHAR(50),@subledgerlogfields VARCHAR(50),@subledgerdatafields VARCHAR(50)
		DECLARE @glCodeReal VARCHAR(20),@CV1 VARCHAR(200),@cv1Name VARCHAR(200),@AmountFiledReal MONEY,@natAmountFiledReal money
		DECLARE @docType VARCHAR(20),@docDate DATETIME
		--DECLARE @table(
		SET NOCOUNT ON;
		SET XACT_ABORT ON;
		--SELECT TOP 10 * FROM fsubledgerlog f
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED
		BEGIN TRAN
		DECLARE abc  CURSOR  FAST_FORWARD READ_ONLY FOR
		select gltype,glcode,dcflag,busi2fidataview,viewfilter,amountfield,natamountfield,glcompanyfield,subledgerlogfields,subledgerdatafields
		  from dbo.fnsysbusi2fi(@formid,@CompanyID) order by groupid,sequence
		 OPEN abc
		  FETCH NEXT FROM abc INTO @gltype,@glCode,@dcFlag,@dataView,@DataFileter,@AmountFiled,@natAmountFiled,@glCompanyID,@subledgerlogfields,@subledgerdatafields
		  WHILE @@FETCH_STATUS=0
			BEGIN
				--update fsubbalance set debit=isnull(debit,0)+100.00,     natdebit=isnull(natdebit,0)+100.00,     Credit=isnull(Credit,0)+0.00,     natCredit=isnull(natcredit,0)+0.00 where companyid=''101'' and periodid=''2011-09'' and account=''113107'' and currency = ''RMB''and isnull(cv1,'''')=''2.1.769.266'' and isnull(cv2,'''')='''' and isnull(cv3,'''')='''' and isnull(cv4,'''')='''' and isnull(cv5,'''')=''''
				--SELECT @sql='Declare @glCode varchar(50),@amountfield money,@natamountfield money,@cv1 varchar(50),@cv1Name varchar(200)'
				--取出变量
				SELECT @sql=';with CTE AS('+CHAR(10)
				SELECT @sql=@sql+' Select CV1,CV1Name,'+CASE WHEN isnumeric(@glCode)=0 THEN REPLACE(@glCode,'@','') +' as glCode ,' ELSE '' end  +
				CASE WHEN ISNULL(@subledgerdatafields,'')='' THEN '' ELSE ','+@subledgerdatafields +',' END+
				'sum(isnull('+@AmountFiled+',0)) as Amountfield,sum(isnull('+@natAmountFiled+',0)) as natAmountfield'+CHAR(10)
				SELECT @sql=@sql+' From '+@dataView+CHAR(10)
				SELECT @sql=@sql+' Where Doccode='''+@Doccode+''''+CHAR(10)
				SELECT @sql=@sql+CASE when isnull(@DataFileter,'')='' THEN '' ELSE ' And '+@DataFileter END +CHAR(10)
				SELECT @sql=@sql+' Group By CV1,CV1Name'+CASE WHEN isnumeric(@glCode)=0 THEN ','+REPLACE(@glCode,'@','') ELSE '' end+')'+
				CASE WHEN ISNULL(@subledgerdatafields,'')='' THEN '' ELSE ','+@subledgerdatafields END + CHAR(10)
				SELECT @sql=@sql+' Select @glCode='+CASE WHEN ISNUMERIC(@glCode)=0 THEN 'glcode' ELSE @glCode END+',@cv1=cv1,@cv1name=cv1name,@amountfield=amountfield,@natamountfield=natamountfield'+CHAR(10)
				SELECT @sql=@sql+' From CTE'
				--EXEC sp_executesql @sql,N'@glCode varchar(50) out,@amountfield money out,@natamountfield money  out,@cv1 varchar(50)  out,@cv1Name varchar(200) out',
				--@glCodereal OUT,@AmountFiledReal OUT,@natAmountFiledReal OUT,@cv1 OUT,@cv1Name out
				PRINT @sql
				--更新数据

				/*IF @dcFlag='借'
					BEGIN
						SELECT * FROM Fsubinstbalance
						--更新即时帐
						--UPDATE Fsubinstbalance
							--SET balance = 
					END
				ELSE
					BEGIN
						UPDATE Fsubinstbalance
							SET balance =ISNULL(balance,0) -@AmountFiledReal,
							natbalance=ISNULL(natbalance,0)-@natAmountFiledReal
							where companyid=@companyid
							and account=@glcodereal
							and currency ='RMB'
							and isnull(cv1,'')=@cv1
	
							
					END*/
				FETCH NEXT FROM abc INTO @gltype,@glCode,@dcFlag,@dataView,@DataFileter,@AmountFiled,@natAmountFiled,@glCompanyID,@subledgerlogfields,@subledgerdatafields
			END
		 CLOSE abc
		 DEALLOCATE abc
		 COMMIT
	END

 