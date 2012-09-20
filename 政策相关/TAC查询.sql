/*
��������:fn_QueryTacInfo
����:��ѯTAC��Ϣ
��д:���ϵ�
ʱ��:2012-09-15
��ע:
ʾ��:
------------------------------------------------------------
�޸�:
*/
alter FUNCTION fn_QueryTacInfo(
	@Seriescode varchar(30),								--TAC��
	@Matcode varchar(50),									--��Ʒ����
	@Matgroup varchar(50),									--��Ʒ����
	@Accuratequery varchar(10),							--��ȷ��ѯ.����1,��'��',��ֻ���رȴ���TAC�����ȷ����Ϣ.
	@IMEIPriority varchar(50)								--ѡ��,����1��'��',�����ȴӴ��ű�ȡ����.
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
		select '�������ѯ����.'
	END
	--�ȴӴ��ű�ȡ����
	if @IMEIPriority in ('��','1')
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
		--����ȵ�ǰTAC����ȷ����Ϣ
		insert into @table(Seriescode,State,Matgroup,matgroupName,Matcode,MatName)
			select is1.TACCode,NULL,img2.matgroup,img2.matgroupname,img.MatCode,img.matname
			from T_TACCode  is1,iMatGeneral img,iMatGroup img2
			where is1.MatCode=img.MatCode
			and img.MatGroup=img2.matgroup
			and (@Seriescode='' or  is1.taccode like @Seriescode+'%')
			and (@Matcode='' or is1.MatCode=@Matcode)
			and (@Matgroup='' or img2.PATH like '/%'+@Matgroup+'%/')
			--���Ǿ�ȷ��ѯ,�򻹲��������TAC����Ʒ��Ϣ
			if @Accuratequery in('��','0')
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