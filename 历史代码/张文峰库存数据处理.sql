SELECT * FROM tt
SELECT * FROM tt1

WITH ctea AS(
	SELECT row_number() over(order by ���) as ������,row_number() over(PARTITION by ��� order by ���) as �������,a.* FROM 
	tt a CROSS JOIN Nums n
	WHERE n.n<=a.����
) ,cte AS(
SELECT ROW_NUMBER() OVER (PARTITION BY b.��� ORDER BY NEWID() ) as ID ,b.��� as ���1,b.��Ʒ����,b.����,b.�ɹ���,
a.������,a.�������,a.���,a.�ֿ����,a.�ֿ�����,a.��Ʒ����,a.����,a.��Ӧ�̱���,a.��Ӧ��,a.���� as '�����',
a.�ɱ���,�ɹ����,����˰,�Ƿ��¹�˾,����,�ɷ�ת��,����Ʒ�����Ƿ�Ʊ,˰�����Ƿ���
FROM ctea a  full JOIN tt1 b ON a.��Ʒ����=b.��Ʒ���� AND a.�ɹ���=b.�ɹ���
)
SELECT *,CASE when id<=���� then '��' ELSE '��' end FROM cte
ORDER BY  ���1



SELECT * FROM tt2
SELECT * FROM tt3

WITH ctea AS(
	SELECT row_number() over(order by ���) as ������,row_number() over(PARTITION by ��� order by ���) as �������,a.* FROM 
	tt2 a CROSS JOIN Nums n
	WHERE n.n<=a.����
) ,cte AS(
SELECT ROW_NUMBER() OVER (PARTITION BY b.��� ORDER BY NEWID() ) as ID ,b.��� as ���1,b.��Ʒ����,b.����,b.��ͨʢ���ɹ�����,
a.������,a.�������,a.���,a.�ֿ����,a.�ֿ�����,a.��Ʒ����,a.����,a.��Ӧ�̱���,a.��Ӧ��,a.���� as '�����',
a.�ɱ���,�ɹ����,����˰,�Ƿ��¹�˾,����,�ɷ�ת��,����Ʒ�����Ƿ�Ʊ,˰�����Ƿ���
FROM ctea a  full JOIN tt3 b ON a.��Ʒ����=b.��Ʒ���� AND a.�ɹ���=b.��ͨʢ���ɹ�����
)
SELECT *,CASE when id<=���� then '��' ELSE '��' end FROM cte
ORDER BY  ���1