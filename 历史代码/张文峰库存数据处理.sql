SELECT * FROM tt
SELECT * FROM tt1

WITH ctea AS(
	SELECT row_number() over(order by 序号) as 拆分序号,row_number() over(PARTITION by 序号 order by 序号) as 分组序号,a.* FROM 
	tt a CROSS JOIN Nums n
	WHERE n.n<=a.数量
) ,cte AS(
SELECT ROW_NUMBER() OVER (PARTITION BY b.序号 ORDER BY NEWID() ) as ID ,b.序号 as 序号1,b.商品名称,b.数量,b.采购价,
a.拆分序号,a.分组序号,a.序号,a.仓库编码,a.仓库名称,a.商品编码,a.串号,a.供应商编码,a.供应商,a.数量 as '库存量',
a.成本价,采购金额,不含税,是否新公司,区域,可否转让,按产品分类是否开票,税务账是否有
FROM ctea a  full JOIN tt1 b ON a.商品名称=b.商品名称 AND a.采购价=b.采购价
)
SELECT *,CASE when id<=数量 then '是' ELSE '否' end FROM cte
ORDER BY  序号1



SELECT * FROM tt2
SELECT * FROM tt3

WITH ctea AS(
	SELECT row_number() over(order by 序号) as 拆分序号,row_number() over(PARTITION by 序号 order by 序号) as 分组序号,a.* FROM 
	tt2 a CROSS JOIN Nums n
	WHERE n.n<=a.数量
) ,cte AS(
SELECT ROW_NUMBER() OVER (PARTITION BY b.序号 ORDER BY NEWID() ) as ID ,b.序号 as 序号1,b.商品名称,b.数量,b.捷通盛宝采购单价,
a.拆分序号,a.分组序号,a.序号,a.仓库编码,a.仓库名称,a.商品编码,a.串号,a.供应商编码,a.供应商,a.数量 as '库存量',
a.成本价,采购金额,不含税,是否新公司,区域,可否转让,按产品分类是否开票,税务账是否有
FROM ctea a  full JOIN tt3 b ON a.商品名称=b.商品名称 AND a.采购价=b.捷通盛宝采购单价
)
SELECT *,CASE when id<=数量 then '是' ELSE '否' end FROM cte
ORDER BY  序号1