/* 9.	At least half of the course offerings (measured by duration) taught by a trainer must be ‘home based’. 
		Note: ‘Home based’ means the course is offered at the same location where the employee is employed.

	On an insert in offr this constraint can be violated in this way:
		if half of the courses offered by the trainer are not home based after the insert
	On an update in offr this constraint can be violated in this way:
		if half of the courses offered by the trainer are not home based after an update on a course
	On a delete in offr this constraint can be violated in this way:
		if half of the courses offered by the trainer are not home based after the delete

		we have chosen to update the already existing stored procedure of inserting new offerings to also check for this constraint.
*/

/*======== IMPLEMENTATION =========================================================================================================================================================================================================================*/

go
CREATE PROCEDURE usp_insertTrainer
--drop proc usp_insertTrainer
(
	@course varchar(6),
	@starts date,
	@status varchar(4),
	@maxcap numeric(2),
	@trainer numeric(4),
	@loc varchar(14)
)
AS
BEGIN
 declare @tr_name varchar(10) = 'none'
 BEGIN TRY
   if @@trancount > 0
     begin
       set @tr_name = 'yep'
       save tran @tr_name
     end
   else
     begin
       begin tran
     end

	 declare @trainerloc varchar(14)
		set @trainerloc = (select loc from dept where deptno in (select deptno from emp where empno = @trainer))
		if((select count(*) from offr where loc = @trainerloc and trainer = @trainer)+1 <= (select count(*) from offr where trainer = @trainer)/2)
			THROW 50006, 'the inserted course should be home-based (same location as the trainer). Else more than half of the courses taught by this trainer are not home-based, this is not allowed.', 1;
		else
		begin
			insert into offr values(@course, @starts, @status, @maxcap, @trainer, @loc)
		end

   if @tr_name = 'none'
     COMMIT TRAN
 END TRY
 BEGIN CATCH
   if @tr_name = 'none'
     ROLLBACK TRAN
   else
     rollback tran @tr_name
   DECLARE @Message nvarchar(2048) = ERROR_MESSAGE()
   raiserror (@Message, 16, 1)
 END CATCH
END
go

/* =================== TESTS =====================================================================================================================================================================================================================*/

EXEC tSQLt.NewTestClass 'Constraint9'; 
--EXEC tSQLt.DropClass 'Constraint9';

GO
CREATE PROCEDURE [Constraint9].[test = 1: insert non home-based courses that exceed the max of the constraint (half of total courses)]  
AS
BEGIN	
	EXEC tSQLt.FakeTable 'dbo.offr';
	EXEC tSQLt.FakeTable 'dbo.dept';
	EXEC tSQLt.FakeTable 'dbo.emp';
	EXEC tSQLt.ExpectException 'the inserted course should be home-based (same location as the trainer). Else more than half of the courses taught by this trainer are not home-based, this is not allowed.'
	insert into emp values (1017, 'Hans', 'PRESIDENT', '1957-12-22', '1992-01-01', 11, 11000, 'HANS', 10)
	insert into dept values (10, 'HEAD OFFICE', 'DALLAS', 1001)
	exec usp_insertTrainer @course = 'AM4DP', @starts = '1998-09-17', @status = 'CONF', @maxcap = 6, @trainer = 1017, @loc = 'AMSTERDAM'
	exec usp_insertTrainer @course = 'AM4DP', @starts = '1999-09-17', @status = 'CONF', @maxcap = 6, @trainer = 1017, @loc = 'AMSTERDAM'
	exec usp_insertTrainer @course = 'AM4DP', @starts = '2000-09-17', @status = 'CONF', @maxcap = 6, @trainer = 1017, @loc = 'AMSTERDAM'
	exec usp_insertTrainer @course = 'AM4DP', @starts = '2001-09-17', @status = 'CONF', @maxcap = 6, @trainer = 1017, @loc = 'AMSTERDAM'
	exec usp_insertTrainer @course = 'AM4DP', @starts = '2003-09-17', @status = 'CONF', @maxcap = 6, @trainer = 1017, @loc = 'AMSTERDAM'
	exec usp_insertTrainer @course = 'AM4DP', @starts = '2005-09-17', @status = 'CONF', @maxcap = 6, @trainer = 1017, @loc = 'AMSTERDAM'
	exec usp_insertTrainer @course = 'AM4DP', @starts = '2006-09-17', @status = 'CONF', @maxcap = 6, @trainer = 1017, @loc = 'AMSTERDAM'
	exec usp_insertTrainer @course = 'AM4DP', @starts = '2007-09-17', @status = 'CONF', @maxcap = 6, @trainer = 1017, @loc = 'AMSTERDAM'
	exec usp_insertTrainer @course = 'AM4DP', @starts = '2008-09-17', @status = 'CONF', @maxcap = 6, @trainer = 1017, @loc = 'AMSTERDAM'
	exec usp_insertTrainer @course = 'AM4DP', @starts = '2007-09-17', @status = 'CONF', @maxcap = 6, @trainer = 1017, @loc = 'AMSTERDAM'
END
GO

GO
CREATE PROCEDURE [Constraint9].[test = 2: insert non home-based course that does not exceed the max of the constraint]  
AS
BEGIN	
	EXEC tSQLt.FakeTable 'dbo.offr';
	EXEC tSQLt.FakeTable 'dbo.dept';
	EXEC tSQLt.FakeTable 'dbo.emp';
	EXEC tSQLt.ExpectNoException
	insert into emp values (1017, 'Hans', 'PRESIDENT', '1957-12-22', '1992-01-01', 11, 11000, 'HANS', 10)
	insert into dept values (10, 'HEAD OFFICE', 'DALLAS', 1001)
	exec usp_insertTrainer @course = 'AM4DP', @starts = '2007-09-17', @status = 'CONF', @maxcap = 6, @trainer = 1017, @loc = 'AMSTERDAM'
END
GO

/* ====== EXECUTION ========================================================================================================================================================================================================================================*/

EXEC [tSQLt].[Run] 'Constraint9'
