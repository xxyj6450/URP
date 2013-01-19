/*
�������ƣ�sp_DistributedExecuteStrategy
�����������ֲ�ʽִ�в��ԡ�������Դ���䵽ָ�����������м��㣬����󷵻ؽ����
������������
��д�����ϵ�
ʱ�䣺2013-01-15
��ע:�������XML�ֱ�ת����������ʱ���ڲ���������������Դʱ������ֱ��ʹ�ô���ʱ��
ʾ����
*/
create proc sp_DistributedExecuteStrategy
	@FormID int,																--���ܺ�
	@Doccode int,															--����
	@DocDataXML XML,													--��������Դ����XML����,������For XML RAW��ʽ,��<root>Ϊ���ڵ�
	@DocDataDefinition nvarchar(max),								--��������Դ����
	@DataSourceXML XML,												--��������Դ����XML���룬������For XML RAW��ʽ,��<root>Ϊ���ڵ�
	@DataSourceDefinition nvarchar(max),							--��������Դ����
	@OptionID varchar(200)='',											--Ԥ��ѡ��ֵ����ѡ
	@Usercode varchar(50)='',											--�û�����
	@TermianlID varchar(50)='',										--�ն˱���
	@InstanceID varchar(50)='',										--������ʵ��ID
	@ResultXML xml=NULL output									--����������For XML RAW��ʽ���,��<root>Ϊ���ڵ�
as
	BEGIN
		set NOCOUNT on;
		declare @hDocData int,@hDataSource int
		exec sp_xml_preparedocument @hDocData output,@DocDataXML
		select * Into #Docdata From OpenXML(@hDocData,'Root'
	END
	