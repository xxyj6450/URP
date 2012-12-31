/*
过程名称:sp_CommonTransProcess
功能描述:为通用单据表 CommonDoc_HD提供通用过帐
参数:见声名
返回值:
编写:三断笛
时间:2012-12-24
备注:
*/
create proc sp_CommonTransProcess
	@FormID int,
	@Doccode varchar(50),
	@RefFormID int=0,
	@RefCode varchar(50)='',
	@SDorgID varchar(50)='',
	@stcode varchar(50)='',
	@OptionID varchar(200)='',
	@Usercode varchar(50)='',
	@TerminalID varchar(50)='',
	@InstanceID varchar(50)=''
as
	BEGIN
		set NOCOUNT ON
		declare @RowID varchar(50),@areaID varchar(50),@VndCode varchar(50)
		declare @table table(matcode varchar(50))
		--供应商报价单
		if @FormID in(2226)
			BEGIN
				select @areaID=cdh.areaid,@VndCode=cdh.Vndcode
				from CommonDoc_HD cdh with(nolock)
				where cdh.Doccode=@Doccode
				--先更新已有的数据
				update a
				set a.price=isnull(b.curSalePrice,0),
				a.stock=isnull(b.Expression,0),
				a.areaid=@areaID,
				a.modifydate=getdate(),
				a.modifyname=@Usercode,
				a.modifydoccode=@Doccode
				output deleted.matcode into @table
				from AdjustPrice_DT b with(nolock),sMatStorage_VND a with(nolock)
				where a.Matcode=b.MatCode
				and a.vndCode=@VndCode
				and b.Doccode=@Doccode
				--再插入未有的数据
				insert into sMatStorage_VND(Matcode,vndCode,AreaID,Stock,price,EnterName,EnterDate,EnterDoccode)
				select a.MatCode,@VndCode,@areaID,a.Expression,a.curSalePrice,@Usercode,getdate(),@Doccode
				from AdjustPrice_DT a with(nolock)
				where a.Doccode=@Doccode
				and not exists(select 1 from @table x where a.MatCode=x.matcode)
			END
		return
	END
 