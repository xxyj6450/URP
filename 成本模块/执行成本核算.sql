print '---------------------------------------------����1���ֻ�------------------------------------------'
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
print '---------------------------------------------����1�����------------------------------------------'
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
print '---------------------------------------------����1������------------------------------------------'
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
print '---------------------------------------------����2���ֻ�------------------------------------------'
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
print '---------------------------------------------����2������------------------------------------------'
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
print '---------------------------------------------����3���ֻ�------------------------------------------'
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
print '---------------------------------------------����3������------------------------------------------'
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
print '---------------------------------------------����4,5���ֻ�------------------------------------------'
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
print '---------------------------------------------����4,5������------------------------------------------'
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

print '---------------------------------------------����6���ֻ�------------------------------------------'
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
print '---------------------------------------------����6������------------------------------------------'
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
print '---------------------------------------------����7,8���ֻ�------------------------------------------'
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
print '---------------------------------------------����7,8������------------------------------------------'
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
print '---------------------------------------------����9���ֻ�------------------------------------------'
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
print '---------------------------------------------����9������------------------------------------------'
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

print '---------------------------------------------����10���ֻ�------------------------------------------'
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
print '---------------------------------------------����10������------------------------------------------'
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


print '---------------------------------------------����11,12���ֻ�------------------------------------------'
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
print '---------------------------------------------����11,12������------------------------------------------'
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

print '---------------------------------------------����13���ֻ�------------------------------------------'
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

print '---------------------------------------------����13������------------------------------------------'
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

print '---------------------------------------------����14,15���ֻ�------------------------------------------'
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

print '---------------------------------------------����14,15������------------------------------------------'
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

print '---------------------------------------------����16,17���ֻ�------------------------------------------'
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

print '---------------------------------------------����16,17������------------------------------------------'
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

print '---------------------------------------------����18,19���ֻ�------------------------------------------'
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

print '---------------------------------------------����18,19������------------------------------------------'
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

print '---------------------------------------------����20,21���ֻ�------------------------------------------'
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

print '---------------------------------------------����20,21������------------------------------------------'
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

print '---------------------------------------------����22���ֻ�------------------------------------------'
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

print '---------------------------------------------����22������------------------------------------------'
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

print '---------------------------------------------����23���ֻ�------------------------------------------'
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

print '---------------------------------------------����23������------------------------------------------'
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

print '---------------------------------------------����24���ֻ�------------------------------------------'
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

print '---------------------------------------------����24������------------------------------------------'
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


print '---------------------------------------------����25���ֻ�------------------------------------------'
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

print '---------------------------------------------����25������------------------------------------------'
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


print '---------------------------------------------����26���ֻ�------------------------------------------'
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

print '---------------------------------------------����26������------------------------------------------'
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



print '---------------------------------------------����27���ֻ�------------------------------------------'
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

print '---------------------------------------------����27������------------------------------------------'
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


print '---------------------------------------------����28���ֻ�------------------------------------------'
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

print '---------------------------------------------����28������------------------------------------------'
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


print '---------------------------------------------����29���ֻ�------------------------------------------'
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

print '---------------------------------------------����29������------------------------------------------'
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



print '---------------------------------------------����30���ֻ�------------------------------------------'
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

print '---------------------------------------------����30������------------------------------------------'
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


print '---------------------------------------------����31���ֻ�------------------------------------------'
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

print '---------------------------------------------����31������------------------------------------------'
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