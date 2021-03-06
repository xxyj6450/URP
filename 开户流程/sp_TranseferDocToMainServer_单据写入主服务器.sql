/*
过程名称:sp_TranseferDocToMainServer
功能描述:将子服务器单据转移至主服务器
编写:三断笛
时间:2012-08-22
备注:
示例:
begin tran
exec [sp_TranseferDocToMainServer] 9146,'PS20120914000242','','',''
rollback
				if exists(select 1 from openquery(URP11,'Select 1 From JTURP.dbo.unicom_orders where doccode=''PS20120914000242'')) 
					BEGIN 
						raiserror('单据已存在,请先删除主服务器单据后再重新执行.',16,1) 
						return 
					END
*/
ALTER proc [dbo].[sp_TranseferDocToMainServer]	
	@FormID int,
	@Doccode varchar(50),
	@OptionID varchar(100)='',
	@Usercode varchar(50)='',
	@TerminalID varchar(50)=''
as
	Begin
		declare @sql nvarchar(max),@Fields nVarchar(Max),@tips varchar(5000)
		declare @docdate DATETIME,@PeriodID varchar(7)
		set XACT_ABORT on;
		if @FormID in(9102,9146,9237,9244)
			Begin
					/*
					if exists(select 1 from openquery(URP11,'Select 1 From JTURP.dbo.unicom_orders where doccode='''+@Doccode+''))
						BEGIN
							raiserror('单据已存在,请先删除主服务器单据后再重新执行.',16,1)
							return
						END
						DECLARE @sql nvarchar(4000)*/
				begin try
					SET @sql = '				if exists(select 1 from openquery(URP11,''Select 1 From JTURP.dbo.unicom_orders where doccode='''''+@Doccode+''''''')) ' + char(10)
							 + '					BEGIN ' + char(10)
							 + '						raiserror(''单据已存在,请先删除主服务器单据后再重新执行.'',16,1) ' + char(10)
							 + '						return ' + char(10)
							 + '					END'
					
					EXEC sp_executesql @sql
				end try
				begin catch
					print @sql
					select @tips='单据写入主服务器失败.'+dbo.crlf()+isnull(error_message(),'')
					raiserror(@tips,16,1)
					return
				end catch
				BEGIN TRY
					select @Fields=''
					select @Fields=','+name+@Fields
					from syscolumns s where s.id=object_id('Unicom_Orders')
					Select @Fields=Right(@Fields,Len(@Fields)-1)
					Select @sql='Insert into OpenQuery(URP11,''Select '+@Fields+' From  JTURP.dbo.Unicom_Orders'')'+Char(10)+
					'SELECT '+@Fields +' From Unicom_Orders Where Doccode='''+@Doccode+''''
					Exec sp_executesql @sql
					--插入明细表
					select @Fields=''
					select @Fields=','+name+@Fields
					from syscolumns s where s.id=object_id('Unicom_Orderdetails')
					Select @Fields=Right(@Fields,Len(@Fields)-1)
					Select @sql='Insert into OpenQuery(URP11,''Select '+@Fields+' From  JTURP.dbo.Unicom_Orderdetails'')'+Char(10)+
					'SELECT '+@Fields +' From Unicom_Orderdetails Where Doccode='''+@Doccode+'''' +char(10)
					Exec sp_executesql @sql
					--插入积分明细表
					select @Fields=''
					select @Fields=','+name+@Fields
					from syscolumns s where s.id=object_id('ScoreLedgerLog')
					Select @Fields=Right(@Fields,Len(@Fields)-1)
					Select @sql='Insert into OpenQuery(URP11,''Select '+@Fields+' From  JTURP.dbo.ScoreLedgerLog'')'+Char(10)+
					'SELECT '+@Fields +' From ScoreLedgerLog Where Doccode='''+@Doccode+'''' +char(10)
					Exec sp_executesql @sql  
				END TRY
				BEGIN CATCH
						select @tips='单据写入主服务器失败.'+dbo.crlf()+isnull(error_message(),'')+dbo.crlf()+'请联系系统管理员.'
						raiserror(@tips,16,1)
						return
				END CATCH
			END
			if @FormID in(9153,9158,9159,9160,9165,9167,9180,9752,9755)
				BEGIN
					begin try
						SET @sql = 'if exists(select 1 from openquery(URP11,''Select 1 From JTURP.dbo.BusinessAcceptance_H where doccode='''''+@Doccode+''''''')) ' + char(10)
							 + '					BEGIN ' + char(10)
							 + '						raiserror(''单据已存在,请先删除主服务器单据后再重新执行.'',16,1) ' + char(10)
							 + '						return ' + char(10)
							 + '					END'
					
					EXEC sp_executesql @sql
					end try
					begin catch
						select @tips='单据写入主服务器失败.'+dbo.crlf()+isnull(error_message(),'')
						raiserror(@tips,16,1)
						return
					end catch
					BEGIN TRY
						select @Fields=''
						select @Fields=','+name+@Fields
						from syscolumns s where s.id=object_id('BusinessAcceptance_H')
						Select @Fields=Right(@Fields,Len(@Fields)-1)
						Select @sql='Insert into OpenQuery(URP11,''Select '+@Fields+' From  JTURP.dbo.BusinessAcceptance_H'')'+Char(10)+
						'SELECT '+@Fields +' From BusinessAcceptance_H Where Doccode='''+@Doccode+''''
						Exec sp_executesql @sql

						--插入明细表
						IF @formid=9752
						BEGIN 
							select @Fields=''
							select @Fields=','+name+@Fields
							from syscolumns s where s.id=object_id('spbusiness')
							Select @Fields=Right(@Fields,Len(@Fields)-1)
							Select @sql='Insert into OpenQuery(URP11,''Select '+@Fields+' From  JTURP.dbo.spbusiness'')'+Char(10)+
							'SELECT '+@Fields +' From spbusiness Where Doccode='''+@Doccode+''''
							Exec sp_executesql @sql
						 END
						--亲情业务受理，插入明细表
						IF @formid=9755
						BEGIN 
							select @Fields=''
							select @Fields=','+name+@Fields
							from syscolumns s where s.id=object_id('busi_family')
							Select @Fields=Right(@Fields,Len(@Fields)-1)
							Select @sql='Insert into OpenQuery(URP11,''Select '+@Fields+' From  JTURP.dbo.busi_family'')'+Char(10)+
							'SELECT '+@Fields +' From busi_family Where Doccode='''+@Doccode+''''
							Exec sp_executesql @sql
					    END  
					END TRY
					BEGIN CATCH
						select @tips='单据写入主服务器失败.'+dbo.crlf()+isnull(error_message(),'')+dbo.crlf()+'请联系系统管理员.'
						raiserror(@tips,16,1)
						return
					END CATCH
						
				END
				Insert Into URP11.JTURP.dbo. gtaskdocpost(FormID,Doccode,Usercode,Createtime,docmemo,TerminalId)
					select @FormID,@Doccode,@Usercode,getdate(),'系统自动确认单据.',@TerminalID
				--充值缴费写往来明细账
				if @FormID in(9167)
					BEGIN
						select @docdate=convert(varchar(10),getdate(),120),@PeriodID=convert(varchar(7),getdate(),120)
						exec URP11.JTURP.dbo.SetFsubLedger @Doccode,@FormID,'1001',@docdate,'',@PeriodID
					END
	END
	/*
declare @sql varchar(max)
select @sql=''
select @sql=','+name+@sql
from syscolumns s where s.id=object_id('BusinessAcceptance_H')
print @sql
*/
