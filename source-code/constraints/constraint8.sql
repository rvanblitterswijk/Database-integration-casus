/* 8.	A trainer cannot register for a course offering taught by him- or herself.
	
	On an insert in reg this constraint can be violated in this way:
		The empno is from a teacher that also teaches this course
	On an update in reg this constraint can be violated in this way:
		The empno is from a teacher that also teaches this course

	We have chosen to create a stored procedure on the reg table to ensure new registrations do not allow to register for a course taught by the same employee.
*/

/*======== IMPLEMENTATION =========================================================================================================================================================================================================================*/

go
CREATE PROCEDURE usp_insertReg
--drop procedure usp_insertReg
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
	 
	 if(exists(select 1 from offr where course = @course and trainer = @stud))
			THROW 50005, 'the inserted student also teaches this course, this is not allowed.', 1;
		else
			insert into reg values (@stud, @course, @starts, @eval)

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

EXEC tSQLt.NewTestClass 'Constraint8'; 
--EXEC tSQLt.DropClass 'Constraint8';

GO
CREATE PROCEDURE [Constraint8].[test = 1: insert student who also teaches the course]  
AS
BEGIN	
	EXEC tSQLt.FakeTable 'dbo.reg';
	EXEC tSQLt.FakeTable 'dbo.offr';
	EXEC tSQLt.ExpectException 'the inserted student also teaches this course, this is not allowed.'
	insert into offr values('AM4DPM', '2005-04-03', 'CONF', 6, 1001, 'SAN FRANCISCO')
	exec usp_insertReg @stud = 1001, @course = 'AM4DPM', @starts = '2005-04-03', @eval = 4 
END
GO

GO
CREATE PROCEDURE [Constraint8].[test = 2: insert student who does not teach this course]  
AS
BEGIN	
	EXEC tSQLt.FakeTable 'dbo.reg';
	EXEC tSQLt.FakeTable 'dbo.offr';
	EXEC tSQLt.ExpectNoException
	insert into offr values('AM4DPM', '2005-04-03', 'CONF', 6, 1000, 'SAN FRANCISCO')
	exec usp_insertReg @stud = 1013, @course = 'AM4DP', @starts = '1997-09-06', @eval = 4
END
GO

/* ====== EXECUTION ========================================================================================================================================================================================================================================*/

EXEC [tSQLt].[Run] 'Constraint8'