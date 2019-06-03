/* 11.	You are allowed to teach a course only if:
		your job type is trainer and
			-   you have been employed for at least one year 
			-	or you have attended the course yourself (as participant) 
*/

/*======== IMPLEMENTATION =========================================================================================================================================================================================================================*/

go
CREATE TRIGGER utr_checkNewTeacher
--drop trigger utr_checkNewTeacher
on offr
after insert
AS
	BEGIN TRY

		-- If there is an inserted course that isnt given by a teacher
		if(exists(select 1 from inserted i inner join emp e on i.trainer = e.empno where e.job != 'TRAINER'))
			THROW 50007, 'the inserted course is not given by a trainer', 1;

		-- If there is an inserted course that is given by a teacher that doesnt have a course that started more than a year ago or this teacher hasnt taught any courses yet.
		if((not exists(select 1 from inserted where starts in (select i.starts from inserted i inner join offr o on i.trainer = o.trainer where DATEDIFF(year, i.starts, o.starts) >= 1))) 
		    or (not exists (select o.trainer from inserted i inner join offr o on i.trainer = o.trainer)))
		begin
			-- If that teacher has not attended this course himself
			if(not exists(select 1 from inserted i where i.trainer in (select stud from reg)
			and i.trainer = (select trainer from inserted where starts in (select i.starts from inserted i inner join offr o on i.trainer = o.trainer where DATEDIFF(year, i.starts, o.starts) < 1))))
				THROW 50008, 'the employee of this inserted course has not been an employee for at least one year or has not followed the course himself/herself', 1;	
		end

	END TRY
	BEGIN CATCH	
		;THROW
	END CATCH
go

/* =================== TESTS =====================================================================================================================================================================================================================*/

EXEC tSQLt.NewTestClass 'Constraint11'; 
--EXEC tSQLt.DropClass 'Constraint11';

GO
CREATE PROCEDURE [Constraint11].[test = 1: Insert course not given by a teacher]  
AS
BEGIN	
	EXEC tSQLt.FakeTable 'dbo.offr';
	EXEC [tSQLt].[ApplyTrigger] @tablename = 'dbo.offr', @triggername = 'utr_checkNewTeacher'
	EXEC tSQLt.FakeTable 'dbo.emp';
	EXEC tSQLt.ExpectException 'the inserted course is not given by a trainer'
	insert into emp values (1000, 'Hans', 'PRESIDENT', '1957-12-22', '1992-01-01', 11, 11000, 'HANS', 10)
	insert into offr values('AM4DPM', '1997-09-06', 'CONF', 6, 1000, 'SAN FRANCISCO');
END
GO

GO
CREATE PROCEDURE [Constraint11].[test = 2: Insert course not given by a trainer who has been working for more than a year]  
AS
BEGIN	
	EXEC tSQLt.FakeTable 'dbo.offr';
	EXEC [tSQLt].[ApplyTrigger] @tablename = 'dbo.offr', @triggername = 'utr_checkNewTeacher'
	EXEC tSQLt.FakeTable 'dbo.emp';
	EXEC tSQLt.ExpectException 'the employee of this inserted course has not been an employee for at least one year or has not followed the course himself/herself'
	insert into emp values (9999, 'Hans', 'TRAINER', '1957-12-22', '2019-02-02', 11, 11000, 'HANS', 10)
	insert into offr values('AM4DPM', '1997-09-06', 'CONF', 6, 9999, 'SAN FRANCISCO');
	insert into offr values('AM4DPM', '1997-09-06', 'CONF', 6, 1000, 'SAN FRANCISCO');
END
GO

GO
CREATE PROCEDURE [Constraint11].[test = 3: Insert course not given by a trainer who has attended the course himself]  
AS
BEGIN	
	EXEC tSQLt.FakeTable 'dbo.offr';
	EXEC [tSQLt].[ApplyTrigger] @tablename = 'dbo.offr', @triggername = 'utr_checkNewTeacher'
	EXEC tSQLt.FakeTable 'dbo.emp';
	EXEC tSQLt.FakeTable 'dbo.reg';
	EXEC tSQLt.ExpectException 'the employee of this inserted course has not been an employee for at least one year or has not followed the course himself/herself'
	insert into reg values (1001, 'AM4DPM','2005-04-03', 4)
	insert into emp values (1000, 'Hans', 'TRAINER', '1957-12-22', '2019-02-02', 11, 11000, 'HANS', 10)
	insert into offr values('AM4DPM', '1997-09-06', 'CONF', 6, 1000, 'SAN FRANCISCO');
END
GO

GO
CREATE PROCEDURE [Constraint11].[test = 4: Succesful insert]  
AS
BEGIN	
	EXEC tSQLt.FakeTable 'dbo.offr';
	EXEC [tSQLt].[ApplyTrigger] @tablename = 'dbo.offr', @triggername = 'utr_checkNewTeacher'
	EXEC tSQLt.FakeTable 'dbo.emp';
	EXEC tSQLt.FakeTable 'dbo.reg';
	EXEC tSQLt.ExpectNoException
	insert into reg values (1000, 'AM4DPM','1-04-03', 4)
	insert into emp values (1000, 'Hans', 'TRAINER', '1957-12-22', '1992-01-01', 11, 11000, 'HANS', 10)
	insert into offr values('AM4DPM', '1997-09-06', 'CONF', 6, 1000, 'SAN FRANCISCO');
END
GO

/* ====== EXECUTION ========================================================================================================================================================================================================================================*/

EXEC [tSQLt].[Run] 'Constraint11'

