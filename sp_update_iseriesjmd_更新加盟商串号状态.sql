/*
2012-11-02 �����������۴���ת�Ƶ����۴��ű�,ֱӪ��,��פ���ȴ��������۵�����ת��. ���ϵ�


*/
alter PROC [sp_update_iseriesjmd](@FormID INT = 9146, @doccode VARCHAR(50))    
AS    
BEGIN
	SET NOCOUNT ON    
	DECLARE @dpttype VARCHAR(50), @SeriesCode VARCHAR(50), @simseriescode VARCHAR(50),@refcode VARCHAR(50) ,@PackageID varchar(50),@tips varchar(5000)
	SELECT @dpttype = dpttype, @SeriesCode = seriescode, @simseriescode = 
	       CardNumber,@refcode=uo.refcode,@PackageID=uo.PackageID
	FROM   Unicom_Orders uo with(nolock)
	WHERE  uo.DocCode = @doccode
	declare @table table(
		Seriescode varchar(50)
		)
	IF @Formid IN (9102, 9146,9237) and @dptType = '���˵�'
	BEGIN
	    UPDATE c
	    SET    salemun = 1,
	    c.state = '����'
	    output inserted.seriescode into @table
	    FROM   iseries c with(nolock)
	    WHERE   seriescode in( isnull( @seriescode,''),isnull(@simseriescode,''))
	    --���д��Ÿ���,��ת�ƴ���
	    if @@ROWCOUNT>0
			BEGIN
				--�������κ��쳣�ͻع�
				set XACT_ABORT on;
				--��������
				begin tran
				BEGIN try
					--�Ȳ������۴��ű�
					insert into iSeriesSaled
					Select is2.* From iSeries is2 with(nolock) inner join @table b on is2.SeriesCode=b.Seriescode
					--ֻ�е�ȷʵ����������,��ɾ��ԭ���ű�����,�����׳��쳣.
					if @@ROWCOUNT>0
						BEGIN
							--�ٴӴ��ű���ɾ������
							delete a
							from iSeries a with(nolock),@table b
							where a.seriescode=b.Seriescode
						END
					else
					BEGIN
							rollback
							raiserror('����ת�������۴��ű�ʧ��,������!',16,1)
							return
					END
					if @@TRANCOUNT>0 commit
				END try
				begin catch
					if @@TRANCOUNT>0 rollback
					select @tips='ת�ƴ��ŷ����쳣.'+dbo.crlf()+isnull(error_message(),'')
					raiserror(@tips,16,1)
					return
				end catch
			END
			
	    
	END
	--�Ǽ��˵� �ڴ��ű����װ�
	IF @Formid IN (9102, 9146,9237) and @dptType != '���˵�'
	BEGIN
	    UPDATE c
	    SET c.PackageID =@PackageID
	    FROM   iseries c with(nolock)
	    WHERE   seriescode in( isnull( @seriescode,''),isnull(@simseriescode,''))
	END
	--����
	IF @Formid IN (9244) and @dptType = '���˵�'
	BEGIN
		SELECT @SeriesCode=seriescode,@simseriescode=simcode
		FROM NumberAllocation_Log a WITH(NOLOCK)
		WHERE a.Doccode=@refcode
	    UPDATE c
	    SET    salemun = 0,
	    c.[state] = 'Ӧ��',
	    isbg=0,
	    c.isava = 0,
	    c.Occupyed = 0,
	    c.OccupyedDoc = null
	    FROM   iseries c with(nolock)
	    WHERE    seriescode in( isnull( @seriescode,''),isnull(@simseriescode,''))
	END
END