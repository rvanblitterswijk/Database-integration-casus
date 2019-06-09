/* 10.	Offerings with 6 or more registrations must have status confirmed.
	
	On an insert in reg this constraint can be violated in this way:
		if a new student is registered and it now totals to 6 for this course the offr table is not updated to have the status CONF for this course
	On an update in reg this constraint can be violated in this way:
		if a student is updated to follow another course and it  now totals to 6 or more registrations the offr table is not updated to have the status CONF for this course
	On an update in offr this constraint can be violated in this way:
		if a course is updated to be scheduled even though there are 6 or more students registered for the course

		we have chosen to update the already existing stored procedure of inserting new registrations to also check for this constraint.
*/

/*======== IMPLEMENTATION =========================================================================================================================================================================================================================*/

go
CREATE PROCEDURE usp_insertOffr
--DROP PROCEDURE usp_insertOffr
(
	@stud numeric(4),
	@course varchar(6),
	@starts date,
	@eval numeric(1)
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
	 
	 INSERT INTO reg values (@stud, @course, @starts, @eval)
	 if((select count(*) from reg where course = @course and starts = @starts) >= 6)
			update offr set status = 'CONF' where course = @course and starts = @starts

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

EXEC tSQLt.NewTestClass 'Constraint10'; 
--EXEC tSQLt.DropClass 'Constraint10';

GO
CREATE PROCEDURE [Constraint10].[test = 1: Insert enough students to fill a course (6 total)]  
AS
BEGIN	
	EXEC tSQLt.FakeTable 'dbo.reg';
	EXEC tSQLt.FakeTable 'dbo.offr';
	insert into offr values('AM4DP', '2006-08-03', 'SCHD', 6, 1001, 'SAN FRANCISCO')

	exec usp_insertOffr @stud = 1029, @course = 'AM4DP', @starts = '2006-08-03', @eval = -1
	exec usp_insertOffr @stud = 1030, @course = 'AM4DP', @starts = '2006-08-03', @eval = -1
	exec usp_insertOffr @stud = 1031, @course = 'AM4DP', @starts = '2006-08-03', @eval = -1
	exec usp_insertOffr @stud = 1032, @course = 'AM4DP', @starts = '2006-08-03', @eval = -1
	exec usp_insertOffr @stud = 1033, @course = 'AM4DP', @starts = '2006-08-03', @eval = -1
	exec usp_insertOffr @stud = 1034, @course = 'AM4DP', @starts = '2006-08-03', @eval = -1
	exec usp_insertOffr @stud = 1035, @course = 'AM4DP', @starts = '2006-08-03', @eval = -1

    Declare @actual varchar(40)
	set @actual = (select status from offr where course = 'AM4DP')
	Declare @expected varchar(40)
	set @expected = 'CONF'

    EXEC tSQLt.assertEquals @expected, @actual;
END
GO

GO
CREATE PROCEDURE [Constraint10].[test = 2: Insert not enough students to fill a course (2 total)]  
AS
BEGIN	
	EXEC tSQLt.FakeTable 'dbo.reg';
	EXEC tSQLt.FakeTable 'dbo.offr';
	insert into offr values('AM4DP', '2005-04-03', 'SCHD', 6, 1001, 'SAN FRANCISCO')
	exec usp_insertOffr @stud = 1029, @course = 'AM4DP', @starts = '2006-08-03', @eval = -1
	exec usp_insertOffr @stud = 1030, @course = 'AM4DP', @starts = '2006-08-03', @eval = -1

    Declare @actual varchar(40)
	set @actual = (select status from offr where course = 'AM4DP')
	Declare @expected varchar(40)
	set @expected = 'SCHD'

    EXEC tSQLt.assertEquals @expected, @actual;
END
GO

/* ====== EXECUTION ========================================================================================================================================================================================================================================*/

EXEC [tSQLt].[Run] 'Constraint10'