print '---------------------------------------------重算1号手机------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-01','2013-01-01','','','1','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch
print '---------------------------------------------重算1号配件------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-01','2013-01-01','','','2','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch
print '---------------------------------------------重算1号其他------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-01','2013-01-01','','','3,6,7,8,9,19','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch
print '---------------------------------------------重算2号手机------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-02','2013-01-02','','','1','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch
print '---------------------------------------------重算2号其他------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-02','2013-01-02','','','2,3,6,7,8,9,19','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch
print '---------------------------------------------重算3号手机------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-03','2013-01-03','','','1','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch
print '---------------------------------------------重算3号其他------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-03','2013-01-03','','','2,3,6,7,8,9,19','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch
print '---------------------------------------------重算4,5号手机------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-04','2013-01-05','','','1','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch
print '---------------------------------------------重算4,5号其他------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-04','2013-01-05','','','2,3,6,7,8,9,19','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch

print '---------------------------------------------重算6号手机------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-06','2013-01-06','','','1','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch
print '---------------------------------------------重算6号其他------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-06','2013-01-06','','','2,3,6,7,8,9,19','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch
print '---------------------------------------------重算7,8号手机------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-07','2013-01-08','','','1','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch
print '---------------------------------------------重算7,8号其他------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-07','2013-01-08','','','2,3,6,7,8,9,19','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch
print '---------------------------------------------重算9号手机------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-09','2013-01-9','','','1','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch
print '---------------------------------------------重算9号其他------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-09','2013-01-9','','','2,3,6,7,8,9,19','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch

print '---------------------------------------------重算10号手机------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-10','2013-01-10','','','1','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch
print '---------------------------------------------重算10号其他------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-10','2013-01-10','','','2,3,6,7,8,9,19','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch


print '---------------------------------------------重算11,12号手机------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-11','2013-01-12','','','1','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch
print '---------------------------------------------重算11,12号其他------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-11','2013-01-12','','','2,3,6,7,8,9,19','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch

print '---------------------------------------------重算13号手机------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-13','2013-01-13','','','1','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch

print '---------------------------------------------重算13号其他------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-13','2013-01-13','','','2,3,6,7,8,9,19','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch

print '---------------------------------------------重算14,15号手机------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-14','2013-01-15','','','1','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch

print '---------------------------------------------重算14,15号其他------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-14','2013-01-15','','','2,3,6,7,8,9,19','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch

print '---------------------------------------------重算16,17号手机------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-16','2013-01-17','','','1','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch

print '---------------------------------------------重算16,17号其他------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-16','2013-01-17','','','2,3,6,7,8,9,19','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch

print '---------------------------------------------重算18,19号手机------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-18','2013-01-19','','','1','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch

print '---------------------------------------------重算18,19号其他------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-18','2013-01-19','','','2,3,6,7,8,9,19','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch

print '---------------------------------------------重算20,21号手机------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-20','2013-01-21','','','1','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch

print '---------------------------------------------重算20,21号其他------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-20','2013-01-21','','','2,3,6,7,8,9,19','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch

print '---------------------------------------------重算22号手机------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-22','2013-01-22','','','1','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch

print '---------------------------------------------重算22号其他------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-22','2013-01-22','','','2,3,6,7,8,9,19','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch

print '---------------------------------------------重算23号手机------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-23','2013-01-23','','','1','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch

print '---------------------------------------------重算23号其他------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-23','2013-01-23','','','2,3,6,7,8,9,19','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch

print '---------------------------------------------重算24号手机------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-24','2013-01-24','','','1','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch

print '---------------------------------------------重算24号其他------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-24','2013-01-24','','','2,3,6,7,8,9,19','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch


print '---------------------------------------------重算25号手机------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-25','2013-01-25','','','1','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch

print '---------------------------------------------重算25号其他------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-25','2013-01-25','','','2,3,6,7,8,9,19','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch


print '---------------------------------------------重算26号手机------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-26','2013-01-26','','','1','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch

print '---------------------------------------------重算26号其他------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-26','2013-01-26','','','2,3,6,7,8,9,19','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch



print '---------------------------------------------重算27号手机------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-27','2013-01-27','','','1','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch

print '---------------------------------------------重算27号其他------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-27','2013-01-27','','','2,3,6,7,8,9,19','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch


print '---------------------------------------------重算28号手机------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-28','2013-01-28','','','1','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch

print '---------------------------------------------重算28号其他------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-28','2013-01-28','','','2,3,6,7,8,9,19','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch


print '---------------------------------------------重算29号手机------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-29','2013-01-29','','','1','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch

print '---------------------------------------------重算29号其他------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-29','2013-01-29','','','2,3,6,7,8,9,19','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch



print '---------------------------------------------重算30号手机------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-30','2013-01-30','','','1','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch

print '---------------------------------------------重算30号其他------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-30','2013-01-30','','','2,3,6,7,8,9,19','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch


print '---------------------------------------------重算31号手机------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-31','2013-01-31','','','1','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch

print '---------------------------------------------重算31号其他------------------------------------------'
begin tran
begin try
	exec sp_ExecuteRecomputeSDorgMatLedger '2013-01-31','2013-01-31','','','2,3,6,7,8,9,19','','','','',''
	commit
end try
begin catch
	print dbo.getLastError('')
	rollback
	return
end catch