 
/*
过程名称:sp_ImportSeriescode
参数:见声名
功能描述:将串号导入表的中串号导入串号表中
编写:三断笛
时间:2012-07-10
*/
ALTER PROC [dbo].[sp_ImportSeriescode]
	@FormID INT,
	@Doccode VARCHAR(50),
	@OptionID VARCHAR(50)=''
AS
	BEGIN
		SET NOCOUNT ON;
		DECLARE @table TABLE(
			seriescode VARCHAR(30),
			doccode VARCHAR(20)
		)
		if @FormID in(1152)
			BEGIN
				INSERT INTO iSeries(SeriesCode,[state],matcode,stcode,Remark,createdoccode,createformid)
				OUTPUT INSERTED.seriescode,@doccode INTO @table
				SELECT SeriesCode,'应收',i.matcode,i.stcode,i.HDMemo,@doccode,@Formid
				FROM iserieslogitem i
				WHERE i.doccode=@Doccode
				UPDATE a
				set isok=1
				FROM iserieslogitem a,@table b
				WHERE a.seriescode=b.seriescode
				AND a.doccode=b.doccode
				AND a.doccode=@Doccode
			END
		if @FormID in(9246)
			BEGIN
				--删除勾选"删除"的TAC
				delete a
				from T_TACCode a,iserieslogitem i
				where i.doccode=@Doccode
				and i.seriescode=a.TACCode
				--更新已存在的TAC
				update a
					set a.Matgroup=i.Matgroup,
					a.MatgroupName=i.MatgroupName,
					a.Remark=i.HDMemo,
					ModifyDate = getdate()
				output i.seriescode,i.doccode into @table
				from T_TACCode a,iserieslogitem i
				where a.TACCode=i.seriescode
				and i.doccode=@Doccode
				insert into T_TACCode(TACCode,Matgroup,MatgroupName,Remark,EnterDate)
				select SeriesCode,i.Matgroup,i.MatgroupName,i.HDMemo,getdate()
				from iserieslogitem i
				where i.doccode=@Doccode
				and i.seriescode not in(select seriescode from @table)
			END
		return
	END
	
