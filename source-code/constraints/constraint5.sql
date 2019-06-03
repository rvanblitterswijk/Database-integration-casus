/*  5.	The start date and known trainer uniquely identify course offerings. 
		Note: the use of a filtered index is not allowed.

		the current unique constraint prevents inserting duplicates on the columns trainer and starts.
		but it also prevents duplicates of null values in the trainer column with the same date.
		this is not the favourable solution as a null value means it can be updated in the future or the trainer of this set course hasnt been decided yet.
		therefore we will be dropping the current unique constraint and add a trigger which will check for duplicates (except null values in trainer) on every record.
		violating this constraint is still possible when a record is updated to be on the same date with the same trainer.
		But we chose a trigger after insert since inserts are more likely to happen.
*/

/*====== IMPLEMENTATION ==============================================================================================================================================================================================================*/

go
CREATE TRIGGER utr_insertOffr
--DROP TRIGGER utr_insertOffr
on offr
after insert
AS
	BEGIN TRY
	if ((select count(*) from offr o, inserted i where o.starts = i.starts and o.trainer = i.trainer) > 1)
		THROW 50003, 'One of the inserted records has the same start date and trainer id as an already existing record. These values must be unique', 1;
	END TRY
	BEGIN CATCH	
		;THROW
	END CATCH
go

/*====== TESTS ==============================================================================================================================================================================================================*/

EXEC tSQLt.NewTestClass 'Constraint5'; 
--EXEC tSQLt.DropClass 'Constraint5';
GO
CREATE PROCEDURE [Constraint5].[test = 1: Insert record with already existing start date and trainer id combination.]  
AS
BEGIN	
	EXEC tSQLt.FakeTable 'dbo.offr';
	EXEC [tSQLt].[ApplyTrigger] @tablename = 'dbo.offr', @triggername = 'utr_insertOffr'
	EXEC tSQLt.ExpectException 'One of the inserted records has the same start date and trainer id as an already existing record. These values must be unique'
	insert into offr(course,starts,[status],maxcap,trainer,loc)
	values('AM4DPM', '1997-09-06', 'CONF', 6, 1017, 'SAN FRANCISCO');
	insert into offr(course,starts,[status],maxcap,trainer,loc)
	values('AM5DPM', '1997-09-06', 'CONF', 6, 1017, 'SAN FRANCISCO');

END
GO

GO
CREATE PROCEDURE [Constraint5].[test = 2 records on the same date but with null values for trainer (not possible with the previous unique constraint).]  
AS
BEGIN	
	EXEC tSQLt.FakeTable 'dbo.offr';
	EXEC [tSQLt].[ApplyTrigger] @tablename = 'dbo.offr', @triggername = 'utr_insertOffr'
	EXEC tSQLt.ExpectNoException
	insert into offr(course,starts,[status],maxcap,trainer,loc)
	values('APEX', '1997-09-06', 'CONF', 6, null, 'SAN FRANCISCO');
	insert into offr(course,starts,[status],maxcap,trainer,loc)
	values('AM4DPM', '1997-09-06', 'CONF', 6, null, 'SAN FRANCISCO');

END
GO

/* ====== EXECUTION ========================================================================================================================================================================================================================================*/

EXEC [tSQLt].[Run] 'Constraint5'
