SELECT * FROM FlowModelEx
SELECT * FROM ActivityInfoEx
SELECT * FROM TransConditionEx ORDER BY TransitionId

SELECT * FROM FlowInstance
SELECT * FROM TaskTicket ORDER BY FlowID,InstanceID, ActivityID
SELECT * FROM AssignTask
SELECT * FROM FInstStateData 
SELECT * FROM FlowTree ft
SELECT * FROM FlowBusiData fbd
SELECT * FROM ActivityInstData aid


SELECT * FROM TaskTicket tt WHERE tt.InstanceID='7850C63A-D2C7-446F-99EE-5F0C19B16932'

SELECT * FROM FlowModelEx fme WHERE fme.FlowModelExOID='0000281D-0000-0000-0000-000000000000'

SELECT * FROM ActivityInfoEx aie WHERE aie.FlowModelExOID='0000281D-0000-0000-0000-000000000000'
SELECT * FROM TransConditionDefine tcd WHERE 
SELECT * FROM TransConditionDefineEx tcde WHERE tcde.TransConditionEx2_FK='0000281D-0000-0000-0000-000000000000'
SELECT * FROM FlowInstance fi WHERE fi.FlowInstanceOID='7850C63A-D2C7-446F-99EE-5F0C19B16932'

SELECT * FROM FlowTree ft WHERE ft.NodeID='AC_10933'

SELECT * FROM FlowTree ft WHERE ft.FlowTreeOID='000000EB-0000-0000-0000-000000000000'

WITH cte AS(
	SELECT ft.NodeName,ft.NodeID,ft.FlowTreeOID FROM  
		FlowTree  ft WHERE ft.FlowTreeOID='000000EB-0000-0000-0000-000000000000'
	UNION ALL
	SELECT a.NodeName,a.NodeID,a.FlowTreeOID
	  FROM FlowTree a join cte b ON a.ParentOID=b.flowtreeoid)
	 SELECT * FROM cte