/* 6.	Trainers cannot teach different courses simultaneously.
		on an update or insert in offr table can violate this procedure:
		if a trainer is updated/inserted to be giving a course while also giving another course
		but the most logic thing to do in our opinion is to create a procedure for inserts as this will happen more frequently.
*/

/*====== IMPLEMENTATION ==============================================================================================================================================================================================================*/

go
CREATE PROCEDURE usp_insertTrainer
--drop procedure usp_insertTrainer
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

		declare @startdate date
		set @startdate = (select top 1 starts from offr where trainer = @trainer and course = @course and @starts >= starts order by starts asc)
		if(@starts >= @startdate and @starts <= DATEADD(day, (select dur from crs where code = @course), @startdate))
			THROW 50004, 'the inserted course starts before all courses of this trainer are over. Record cant be inserted.', 1;
		else
			insert into offr values(@course, @starts, @status, @maxcap, @trainer, @loc)

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

/*====== TESTS ==============================================================================================================================================================================================================*/
EXEC tSQLt.NewTestClass 'Constraint6'; 
--EXEC tSQLt.DropClass 'Constraint6';

GO
CREATE PROCEDURE [Constraint6].[test = 1: insert course when another course of the same trainer is not finished yet]  
AS
BEGIN	
	EXEC tSQLt.FakeTable 'dbo.emp';
	EXEC tSQLt.FakeTable 'dbo.offr';
	EXEC tSQLt.FakeTable 'dbo.crs';
	EXEC tSQLt.ExpectException 'the inserted course starts before all courses of this trainer are over. Record cant be inserted.'
	insert into crs values ('AM4DP', 'Applied Math for DB-Pros', 'DSG', 10)
	insert into offr values ('AM4DP', '2018-12-30', 'CONF', 6, 1017, 'SAN FRANCISCO')
	exec usp_insertTrainer @course = 'AM4DP', @starts = '2018-12-31', @status = 'CONF', @maxcap = 6, @trainer = 1017, @loc = 'SAN FRANCISCO' 
END
GO

GO
CREATE PROCEDURE [Constraint6].[test = 2: insert course when all other courses of this trainer are finished]  
AS
BEGIN	
	EXEC tSQLt.FakeTable 'dbo.emp';
	EXEC tSQLt.FakeTable 'dbo.offr';
	EXEC tSQLt.FakeTable 'dbo.crs';
	EXEC tSQLt.ExpectNoException
	insert into crs values ('AM4DP', 'Applied Math for DB-Pros', 'DSG', 1)
	insert into offr values ('AM4DP', '2000-12-30', 'CONF', 6, 1017, 'SAN FRANCISCO')
	exec usp_insertTrainer @course = 'AM4DP', @starts = '2018-12-31', @status = 'CONF', @maxcap = 6, @trainer = 1017, @loc = 'SAN FRANCISCO' 
END
GO

/* ====== EXECUTION ========================================================================================================================================================================================================================================*/

EXEC [tSQLt].[Run] 'Constraint6'
