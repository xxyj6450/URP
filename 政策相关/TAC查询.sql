/*
函数名称:fn_QueryTacInfo
功能:查询TAC信息
编写:三断笛
时间:2012-09-15
备注:
示例:
------------------------------------------------------------
修改:
*/
alter FUNCTION fn_QueryTacInfo(
	@Seriescode varchar(30),								--TAC码
	@Matcode varchar(50),									--商品编码
	@Matgroup varchar(50),									--商品大类
	@Accuratequery varchar(10),							--精确查询.若传1,或'是',则只返回比传入TAC码更精确的信息.
	@IMEIPriority varchar(50)								--选项,若传1或'是',则优先从串号表取数据.
)
returns @table table(
	Seriescode varchar(50),
	State varchar(20),
	Matgroup varchar(50),
	matgroupName varchar(200),
	Matcode varchar(50),
	MatName varchar(200)
)
BEGIN
	if @Seriescode='' and @matcode='' and @Matgroup=''
	BEGIN
		insert into @table(Seriescode)
		select '请输入查询条件.'
	END
	--先从串号表取数据
	if @IMEIPriority in ('是','1')
		BEGIN
			insert into @table(Seriescode,State,Matgroup,matgroupName,Matcode,MatName)
			select TOP 100 seriescode,is1.state,img2.matgroup,img2.matgroupname,img.MatCode,img.matname
			from iSeries is1,iMatGeneral img,iMatGroup img2
			where is1.MatCode=img.MatCode
			and img.MatGroup=img2.matgroup
			and (@Seriescode='' or  is1.SeriesCode like @Seriescode+'%')
			and (@Matcode='' or is1.MatCode=@Matcode)
			and (@Matgroup='' or img2.PATH like '/%'+@Matgroup+'%/')
		END
		--插入比当前TAC更精确的信息
		insert into @table(Seriescode,State,Matgroup,matgroupName,Matcode,MatName)
			select is1.TACCode,NULL,img2.matgroup,img2.matgroupname,img.MatCode,img.matname
			from T_TACCode  is1,iMatGeneral img,iMatGroup img2
			where is1.MatCode=img.MatCode
			and img.MatGroup=img2.matgroup
			and (@Seriescode='' or  is1.taccode like @Seriescode+'%')
			and (@Matcode='' or is1.MatCode=@Matcode)
			and (@Matgroup='' or img2.PATH like '/%'+@Matgroup+'%/')
			--若非精确查询,则还插入包含该TAC的商品信息
			if @Accuratequery in('否','0')
				BEGIN
					insert into @table(Seriescode,State,Matgroup,matgroupName,Matcode,MatName)
					select is1.TACCode,NULL,img2.matgroup,img2.matgroupname,img.MatCode,img.matname
					from T_TACCode  is1,iMatGeneral img,iMatGroup img2
					where is1.MatCode=img.MatCode
					and img.MatGroup=img2.matgroup
					and @seriescode like is1.TACCode+'%' 
					and (@Matcode='' or is1.MatCode=@Matcode)
					and (@Matgroup='' or img2.PATH like '/%'+@Matgroup+'%/')
				END
		return
END