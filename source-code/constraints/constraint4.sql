/* 
	4.	A salary grade overlaps with at most one lower salary grade. The llimit of a salary grade must be higher than the llimit of the next lower salary grade. 
	The ulimit of the salary grade must be higher than the ulimit of the next lower salary grade.

	We will make an insert trigger to ensure this constraint is not violated
*/

/*====== IMPLEMENTATION ==============================================================================================================================================================================================================*/

go
CREATE TRIGGER utr_insertGrd
--DROP TRIGGER utr_insertGrd
on grd
after insert
AS
	BEGIN TRY
		--If the llimit of the next lower salary grade is higher than the llimit of the inserted grd
		if (exists (select 1 from grd g inner join inserted i on g.grade+2 = i.grade where i.llimit < g.llimit))
			THROW 50009, 'You cant insert a grade with a llimit lower than that of the next lower grade', 1;

		--If the ulimit of the next lower salary grade is higher than the ulimit of the inserted grd
		if (exists (select 1 from grd g inner join inserted i on g.grade+2 = i.grade where i.ulimit < g.ulimit))
			THROW 50010, 'You cant insert a grade with a ulimit lower than that of the next lower grade', 1;

		--If the llimit of the inserted grd is higher than that of the next higher grade
		if (exists (select 1 from grd g inner join inserted i on g.grade = i.grade+2 where g.llimit < i.llimit))
			THROW 50011, 'You cant insert a grade with a llimit higher than the next higher grade', 1;

		--If the ulimit of the inserted grd is higher than that of the next higher grade
		if (exists (select 1 from grd g inner join inserted i on g.grade = i.grade+2 where g.ulimit < i.ulimit))
			THROW 50012, 'You cant insert a grade with a ulimit higher than the next higher grade', 1;
			
	END TRY
	BEGIN CATCH	
		;THROW
	END CATCH
go

/*====== TESTS ==============================================================================================================================================================================================================*/

EXEC tSQLt.NewTestClass 'Constraint4'; 
--EXEC tSQLt.DropClass 'Constraint4';

GO
CREATE PROCEDURE [Constraint4].[test = 1: Insert a grade with a llimit lower than that of the next lower grade]  
AS
BEGIN	
	EXEC tSQLt.FakeTable 'dbo.grd'
	EXEC [tSQLt].[ApplyTrigger] @tablename = 'dbo.grd', @triggername = 'utr_insertGrd'
	EXEC tSQLt.ExpectException 'You cant insert a grade with a llimit lower than that of the next lower grade'
	--Insert first 2 grades
	begin tran
	insert into grd values(1, 10, 20, 0)
	insert into grd values(2, 20, 30, 0)
	commit tran

	--Insert 3rd grade that will violate the constraint
	insert into grd values(3, 5, 40, 0)
END
GO

GO
CREATE PROCEDURE [Constraint4].[test = 2: Insert a grade with a ulimit lower than that of the next lower grade]  
AS
BEGIN	
	EXEC tSQLt.FakeTable 'dbo.grd'
	EXEC [tSQLt].[ApplyTrigger] @tablename = 'dbo.grd', @triggername = 'utr_insertGrd'
	EXEC tSQLt.ExpectException 'You cant insert a grade with a ulimit lower than that of the next lower grade'
	--Insert first 2 grades
	begin tran
	insert into grd values(1, 10, 20, 0)
	insert into grd values(2, 20, 30, 0)
	commit tran

	--Insert 3rd grade that will violate the constraint
	insert into grd values(3, 40, 10, 0)
END
GO

GO
CREATE PROCEDURE [Constraint4].[test = 3: Insert a grade with a llimit higher than the next higher grade]  
AS
BEGIN	
	EXEC tSQLt.FakeTable 'dbo.grd'
	EXEC [tSQLt].[ApplyTrigger] @tablename = 'dbo.grd', @triggername = 'utr_insertGrd'
	EXEC tSQLt.ExpectException 'You cant insert a grade with a llimit higher than the next higher grade'
	--Insert first 2 grades
	begin tran
	insert into grd values(5, 10, 20, 0)
	insert into grd values(6, 20, 30, 0)
	commit tran

	--Insert 3rd grade that will violate the constraint
	insert into grd values(4, 30, 10, 0)
END
GO

GO
CREATE PROCEDURE [Constraint4].[test = 4: Insert a grade with a ulimit higher than the next higher grade]  
AS
BEGIN	
	EXEC tSQLt.FakeTable 'dbo.grd'
	EXEC [tSQLt].[ApplyTrigger] @tablename = 'dbo.grd', @triggername = 'utr_insertGrd'
	EXEC tSQLt.ExpectException 'You cant insert a grade with a ulimit higher than the next higher grade'
	--Insert first 2 grades
	begin tran
	insert into grd values(5, 10, 20, 0)
	insert into grd values(6, 20, 30, 0)
	commit tran

	--Insert 3rd grade that will violate the constraint
	insert into grd values(4, 5, 60, 0)
END
GO

GO
CREATE PROCEDURE [Constraint4].[test = 5: Succesful insert]  
AS
BEGIN	
	EXEC tSQLt.FakeTable 'dbo.grd'
	EXEC [tSQLt].[ApplyTrigger] @tablename = 'dbo.grd', @triggername = 'utr_insertGrd'
	EXEC tSQLt.ExpectNoException
	--Insert first 2 grades
	begin tran
	insert into grd values(1, 10, 20, 0)
	insert into grd values(2, 20, 30, 0)
	insert into grd values(4, 40, 50, 0)
	insert into grd values(5, 50, 60, 0)
	commit tran

	--Insert 3rd grade that will violate the constraint
	insert into grd values(3, 30, 40, 0)
END
GO


/* ====== EXECUTION ========================================================================================================================================================================================================================================*/

EXEC [tSQLt].[Run] 'Constraint4'