DECLARE @myDoc xml
DECLARE @ProdID int
SET @myDoc = '<Root>
<ProductDescription ProductID="1" ProductName="Road Bike">
<Features ID="1" Title="test">
  <Warranty>1 year parts and labor</Warranty>
  <Maintenance>3 year parts and labor extended maintenance is available</Maintenance>
</Features>
<Features ID="2" Title="test2">
  <Warranty>2 year parts and labor</Warranty>
  <Maintenance>3 year parts and labor extended maintenance is available</Maintenance>
</Features>
</ProductDescription>
</Root>'

select @myDoc.value('(//Features[@ID="2"]/Warranty/text())[1]', 'varchar(50)' )
 

 DECLARE @x xml
SET @x = ''
-- Expression returns a sequence of 1 text node (singleton).
SELECT @x.query('1')
-- Expression returns a sequence of 2 text nodes
SELECT @x.query('"abc", "xyz"')
-- Expression returns a sequence of one atomic value. data() returns
-- typed value of the node.
SELECT @x.query('data(1)')
-- Expression returns a sequence of one element node. 
-- In the expression XML construction is used to construct an element.
SELECT @x.query('<x> {1*2} </x>')
