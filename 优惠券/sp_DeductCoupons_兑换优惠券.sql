alter proc sp_DeductCoupons
	@FormID int,
	@Doccode varchar(50),
	@Refformid int=0,
	@Refcode varchar(50)='',
	@Stcode varchar(50)='',
	@Customercode varchar(50)='',
	@OptionID varchar(50)='',						--������#Skipcheck#�򲻼��
	@Usercode varchar(50)='',
	@TerminalID varchar(50)=''
as
	BEGIN
		set NOCOUNT ON
		DECLARE @deductAmout money,@LinkDocInfo varchar(50),@linkDoc varchar(20),  @tips varchar(5000),	@msg VARCHAR(5000)
		DECLARE @TranCount INT,@DocStatus INT,@PackageId varchar(50),@ComboCode int
		DECLARE @SourceMode VARCHAR(20),				--��Դģʽ
				@CodeMode VARCHAR(20),						--����ģʽ
				@CodeLength INT,										--���볤��
				@PresentCount VARCHAR(20),						--�����������ʽ
				@PresentMode VARCHAR(500),					--��������ģʽ
				@PresentMoney VARCHAR(500),					--���ͽ����ʽ
				@ExchangeCount VARCHAR(20),					--�һ��������ʽ
				@ExchangeMode VARCHAR(500),				--�һ�����ģʽ
				@ExchangeMoney VARCHAR(500),				--�һ������ʽ
				@SdorgID VARCHAR(50),
				@sql VARCHAR(8000)
				if @Refformid in(9146,9237,9102)
					BEGIN
						select @PackageId=uo.PackageID,@ComboCode=uo.ComboCode
						from Unicom_Orders uo with(nolock)
						where uo.DocCode=@Refcode
					END
				if @OptionID<>'#SkipCheck#'
					BEGIN
						--У��һ�����
						BEGIN TRY
							exec sp_checkDeductCoupons @formid,@doccode,@Refformid,@Refcode,@Stcode,@Customercode,@PackageId,@ComboCode,@optionID,@userCode
						END TRY
						BEGIN CATCH
							select @tips=dbo.getLastError('�Ż�ȯ�һ�����У��ʧ�ܡ�')
							raiserror(@tips,16,1)
							return
						END CATCH
					END
				
				/************************************************************************�����Ż�ȯ״̬******************************************************/
				--������ΪURP��������,������Լ�,�������URP��������
				
				UPDATE iCoupons
				SET
					[State] = '�Ѷһ�',						--�����Ż�ȯ״̬,�������״̬��Ϊ��,��ʹ�ô����״̬,����ʹ��Ĭ�ϵ�״̬.
					DeductAmout =b.DeductAmout ,
					Remark = b.Remark ,
					DeducedDoccode = a.Doccode ,
					DeducedDate = GETDATE(),
					DeducedFormID = a.FormID ,
					DeducedStcode = a.Stcode ,
					DeducedStName = a.stName ,
					DeducedMatcode = b.Matcode ,
					DeducedMatName = b.MatName ,
					DeducedSeriescode = b.SeriesCode,
					DeducedMoney = b.Amount ,
					DeducedDigit =b.Digit
				FROM Coupons_H a  with(nolock),Coupons_D b  with(nolock),iCoupons c  with(nolock)
				WHERE a.Doccode=b.Doccode
				AND b.CouponsBarCode=c.CouponsBarcode
				AND a.Doccode= @doccode
				AND c.[State] IN('����','ʹ����')
				IF @@ROWCOUNT=0
					BEGIN
						select @tips='�޷��һ����Ż�ȯ,��Ϊ���Ż�ȯ��δ���ͻ򲻴���'
						RAISERROR(@tips,16,1)
						return
					END
				;WITH ctea AS(SELECT SUM(isnull(deductamout,0)) AS totalmoney FROM Coupons_D cd WHERE cd.Doccode=@doccode)
				UPDATE coupons_h 
					SET TotalDeductAmout = a.totalmoney 
				FROM ctea a 
				WHERE coupons_h.Doccode=@doccode
				SELECT @refFormid=refformid,@refcode=refcode,@deductAmout=ch.TotalDeductAmout
				  FROM Coupons_H ch   with(nolock) WHERE ch.Doccode=@doccode
				  /**********************************************************����ҵ�񵥾�********************************************************************/
				--�Żݽ�����ҵ�񵥾�
				IF @refFormid IN(2419)
					BEGIN
						UPDATE sPickorderHD
						SET DeductAmout = @deductAmout
						WHERE DocCode=@refcode
						AND FormID=@refFormid              

						UPDATE spickorderitem SET done=1 WHERE doccode=@doccode
						--�޸���ϸ��
						update a
						set a.DeductAmout=b.DeductAmout,a.CouponsBarCode=b.CouponsBarCode,
						done=0
						from spickorderitem a WITH(NOLOCK) LEFT JOIN coupons_d b
						on a.doccode=@refcode
							and b.doccode=@doccode
							and a.matcode=b.matcode
							and a.rowid=b.RefRowID
					END
				IF @refFormid IN(9102,9146)
					BEGIN
						UPDATE Unicom_Orders
						SET DeductAmout = @deductAmout
						WHERE DocCode=@doccode
						AND FormID=@formid
						AND FormID=@refFormid
						--�޸���ϸ��
						update a
						set a.DeductAmout=b.DeductAmout,a.CouponsBarCode=b.CouponsBarCode
						from unicom_orderdetails a   with(nolock) LEFT join coupons_d b   with(nolock)			--��LEFT JOIN���ܽ��ͣ���������Ż�ȯ�һ�����û�У����ڵ����л��е��Ż�ȯ,��������һ�¡�
						on a.doccode=@refcode
							and b.doccode=@doccode
							and a.matcode=b.matcode
							and a.rowid=b.RefRowID
					END
				return
	END