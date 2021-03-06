
/*
过程名称:sp_CreateAndOpenDoc
功能描述:生成(如果没有的话)并打开单据
参数:见声名
编写:三断笛
时间:2011-10-21
备注:该函数用于从源单据的功能链接打开新单据.可以用一个存储过程返回单据号.这样就不必为每打开一个新单据而创建一个功能号.节省功能号资源.适合于在单据中关联其他单据.
sp_goBack也可用于打开单据,但适合于与源单据无关的打开单据,适合于在报表中打开单据
示例:
begin tran
declare @doccode varchar(20),@LinkDoccode varchar(50)
exec sp_CreateAndOpenDoc 9146,'PS20121018002701','SYSTEM','SYSTEM',9244,16,'','',@Doccode out,@Linkdoccode out
print @doccode
print @Linkdoccode

rollback
*/
ALTER PROC [sp_CreateAndOpenDoc]
	@FormID INT,														--源功能号
	@doccode VARCHAR(20),										--源单号
	@userCode VARCHAR(20),										--用户编码
	@userName VARCHAR(50),										--用户名
	@NewFormID INT=0,												--新功能号
	@NewFormType INT=5,											--新功能窗体类型
	@OptionID VARCHAR(100)='',									--选项值
	@TerminalID VARCHAR(40)='',								--终端编码
	@NewDoccode VARCHAR(20)='' OUTPUT,				--新单号(输出)
	@LinkDocInfo VARCHAR(50)='' OUTPUT					--单据信息(输出)
AS
	BEGIN
		SET NOCOUNT ON;
 
		DECLARE @tips VARCHAR(MAX)
		declare @DocStatus INT,@refcode VARCHAR(50)
		--异常捕获
		BEGIN try
			IF @FormID IN(2419)
				BEGIN
					EXEC sp_createSeriescodeDoc @FormID,@doccode,@userCode,@userName,@NewFormID,0,@NewDoccode OUTPUT,@LinkDocInfo output
				END
			IF @FormID IN(9146,9102,9237)
				begin
					
					--延保单
					if @newFormID in(2445)
						begin
							--先取出单据信息
							select @DocStatus=docstatus,@refcode=uo.refcode
							  from Unicom_Orders uo WITH (nolock) where uo.DocCode=@doccode
							EXEC sp_createSeriescodeDoc @FormID,@doccode,@userCode,@userName,@NewFormID,0,@NewDoccode OUTPUT,@LinkDocInfo output
						end
					--返销单
					if @NewFormID in(9244)
						begin
							--先取出单据信息
							select @DocStatus=docstatus,@refcode=uo.refcode
							  from URP11.JTURP.dbo.Unicom_Orders uo WITH (nolock) where uo.DocCode=@doccode
							if ISNULL(@DocStatus,0)=0 
								BEGIN
									raiserror('开户单据尚未确认,不允许返销!',16,1)
									return
								END
								--检查是否有退过单
								if exists(select 1 from URP11.JTURP.dbo.spickorderHD with(nolock) where refrefcode=@refcode and Formid=2420)
									BEGIN
										raiserror('本单已退单,不允许返销.',16,1)
										return
									END
							--判断是否已存在返销单.
							select @NewDoccode=doccode from Unicom_Orders uo with(nolock) where uo.FormID=@NewFormID and uo.refcode=@doccode
							if isnull(@NewDoccode,'')=''
								BEGIN
									/*IF EXISTS(SELECT 1 FROM URP11.JTURP.dbo.Unicom_Orders uo WITH(NOLOCK) WHERE uo.DocCode=@refcode AND uo.bitReturnd=1)
										BEGIN
											RAISERROR('此单已返销,不允许再次操作!',16,1)
											return
										END*/
									--生成单号
									exec sp_newdoccode 9244,'',@NewDoccode output
									insert into Unicom_Orders(DocCode,FormID,DocType,DocDate,DocStatus,refformid,refcode,
									Companyid,sdorgid,sdorgname,stcode,stname,sdgroup,sdgroupname,sdgroup1,sdgroupname1,instcode,instname,dpttype,
									SeriesNumber,ComboCode,ComboName,PackageID,PackageName,comboFEEType,
									Price,ServiceFEE,PhoneRate,OtherFEE,ICCID,CardNumber,CardMatCode,CardMatName,CardFEE1,
									SeriesCode,matcode,MatName,MatMoney,
									BasicDeposits,Deposits,DepositsMatcode,DepositsMatName,
									cltcode,cltname,customerid,userid,ReservedDoccode,
									totalmoney2,commission,rewards,userdigit4,score,score1,TotalScore,MatRewards)
									select @NewDoccode,@NewFormID,'开户返销单',convert(varchar(10),getdate(),120),0,@formid,@doccode,
									companyid,sdorgid,sdorgname,stcode,stname,sdgroup,sdgroupname,sdgroup,sdgroupname,uo.instcode,uo.instname,dpttype,
									uo.SeriesNumber,uo.ComboCode,uo.ComboName,uo.PackageID,uo.PackageName,comboFEEType,
									price,uo.ServiceFEE,uo.PhoneRate,uo.OtherFEE,uo.ICCID,CardNumber,CardMatCode,CardMatName,CardFEE1,
									SeriesCode,matcode,MatName,MatMoney,
									BasicDeposits,Deposits,DepositsMatcode,DepositsMatName,
									uo.cltCode,uo.cltName,uo.CustomerID,uo.UserID,uo.ReservedDoccode,
									uo.totalmoney2,uo.commission,uo.rewards,uo.userdigit4,
									uo.Score,uo.Score1,uo.TotalScore,matrewards
									from URP11.JTURP.dbo.Unicom_Orders uo with(nolock) where uo.DocCode=@doccode
								end
						END
				END
		END TRY
		--处理异常
		BEGIN CATCH
			SELECT @tips=char(10)+'发生异常:'+ERROR_MESSAGE()+'.'+CHAR(10)+'错误源:'+error_procedure()+'.'+char(10)+'发生于第'+convert(VARCHAR(4),error_line())+'行.'
			RAISERROR(@tips,16,1)
			return
		END catch
		SELECT @LinkDocInfo=CONVERT(varchar(8),@NewFormID)+';'+CONVERT(VARCHAR(3),@NewFormType)+';'+@NewDoccode
		return
	END