/* 7.	An active employee cannot be managed by a terminated employee. 

	On an insert in term this constraint can be violated in this way:
		Employee is inserted in term but not deleted in memp. So employees managed by the terminated employee are still in the memp table.
	On an update in term this constraint can be violated in this way:
		Terminated employee in term is updated to another empno, then data in the memp table will not correspond.

	We have decided to create a trigger after an insert on the term table to ensure all employees managed by the inserted manager will be deleted from the memp table.
*/

/*======== IMPLEMENTATION =========================================================================================================================================================================================================================*/

go
CREATE TRIGGER utr_insertTerm
--drop trigger utr_insertTerm
on term
after insert
AS
	BEGIN TRY
		delete from memp where mgr in (select empno from inserted)
	END TRY
	BEGIN CATCH	
		;THROW
	END CATCH
go

/* =================== TESTS =====================================================================================================================================================================================================================*/

EXEC tSQLt.NewTestClass 'Constraint7'; 
--EXEC tSQLt.DropClass 'Constraint7';

GO
CREATE PROCEDURE [Constraint7].[test = 1: insert a record in term will delete all records in memp which have that exact empno.]  
AS
BEGIN	
	EXEC tSQLt.FakeTable 'dbo.term';
	EXEC tSQLt.FakeTable 'dbo.memp';
	EXEC tSQLt.ExpectNoException
	insert into term(empno, leftcomp, comments)
	values(1003, '2019-04-05', '');
END
GO

/* ====== EXECUTION ========================================================================================================================================================================================================================================*/

EXEC [tSQLt].[Run] 'Constraint7'
