/*=====    B    ===============================================================================================================================================================================================================*/

/* 
	Constraint 1. The president of the company earns more than $10.000 monthly. 
	Assumption: This constraint does not include Bonuses as this is about monthly earnings.
*/
go
CREATE PROCEDURE usp_updateMsal
(
	@empno numeric(4,0),
	@newMsal numeric(7,2)
)
AS
	BEGIN TRY

		--if empno corresponds to the president
		if((select e.job from emp e where e.empno = @empno) = 'PRESIDENT')
		begin
			--if msal is greater than 9999
			if(@newMsal >= 10000)
			begin
				update emp
				set msal = @newMsal
				where empno = @empno
			end
			--msal is too low
			else
				THROW 50001, 'President msal can not be less than 10000', 1;

		end
		--empno does not correspond to the president
		else
		begin
			update emp
			set msal = @newMsal
			where empno = @empno
		end
	END TRY
	BEGIN CATCH	
		;THROW
	END CATCH
go

-- Test 1: update mSal > 10000 on a president
-- expected result: succes
BEGIN TRAN
BEGIN TRY
	exec usp_updateMsal @empno = 1000, @newMsal = 11000
END TRY
BEGIN CATCH
	ROLLBACK TRAN
	;THROW
END CATCH
--succes
select * from emp where empno = 1000
ROLLBACK TRAN

-- Test 2: update mSal < 10000 on a president
-- expected result: fail
BEGIN TRAN
BEGIN TRY
	exec usp_updateMsal @empno = 1000, @newMsal = 9000
END TRY
BEGIN CATCH
	ROLLBACK TRAN
	;THROW
END CATCH
select * from emp where empno = 1000
ROLLBACK TRAN

-- Test 3: update msal < 10000 on a manager
-- expected result: succes
BEGIN TRAN
BEGIN TRY
	exec usp_updateMsal @empno = 1001, @newMsal = 9000
END TRY
BEGIN CATCH
	ROLLBACK TRAN
	;THROW
END CATCH
select * from emp where empno = 1001
ROLLBACK TRAN


/* 
	Constraint 2. A department that employs the president or a manager should also employ at least one administrator.
	On an insert in emp this constraint can be violated in this way:
		A manager/president is inserted in with a detpno that has no administrator.
	On an update in emp this constraint can be violated in multiple ways:
		The job of an ADMIN row is changed but the dept with the same deptno as the deptno in that row has a MANAGER/PRESIDENT.
		The job of a ADMIN/OTHER row is changed to MANAGER/PRESIDENT but after this update the dept with the same deptno has no ADMIN
	On a delete in emp this constraint can be violated in multiple ways:
		The only ADMIN from a certain dept gets deleted but this dept has a MANAGER/PRESIDENT 

	We will make a delete trigger to ensure this constraint is not violated
*/

go
CREATE TRIGGER utr_deleteEmp
on emp
after delete
AS
	BEGIN TRY
		--If the deleted emp is an admin
		if ((select job from deleted) = 'ADMIN')
		begin
			--If the dept from the deleted ADMIN has no more ADMINS
			if (not exists (select * from emp where deptno = (select deptno from deleted) and (job = 'ADMIN')))
			begin
				--If the dept from the deleted ADMIN has a president or manager
				if (exists (select * from emp where deptno = (select deptno from deleted) and (job = 'PRESIDENT' or job = 'MANAGER')))
				THROW 50002, 'You cant delete an admin from a department with no more admins and a president/manager', 1;
			end
		end
	END TRY
	BEGIN CATCH	
		;THROW
	END CATCH
go

-- Test 1: Delete the last admin from a dept with a manager
-- expected result: fail
BEGIN TRAN
BEGIN TRY
	--Make new dept
	insert into dept(deptno,dname,loc,mgr) values(99,'TEST','TEST', 1005);
	--Make an admin in that dept
	insert into emp(empno,ename,job,born,hired,sgrade,msal,username,deptno)
	values(9999,'test','ADMIN','01-24-1969','01-05-1997',3,2900,'MONIQUE1',99);
	--Make a manager in that dept
	insert into emp(empno,ename,job,born,hired,sgrade,msal,username,deptno)
	values(9998,'test','MANAGER','01-24-1969','01-05-1997',3,2900,'MONIQUE2',99);
	--Delete the admin from that dept with manager still there
	delete from emp where empno = 9999
	--Delete rolled back
	select * from emp
END TRY
BEGIN CATCH
	ROLLBACK TRAN
	;THROW
END CATCH
ROLLBACK TRAN

-- Test 2: Delete the last admin from a dept without a manager
-- expected result: succes
BEGIN TRAN
BEGIN TRY
	--Make new dept
	insert into dept(deptno,dname,loc,mgr) values(99,'TEST','TEST', 1005);
	--Make an admin in that dept
	insert into emp(empno,ename,job,born,hired,sgrade,msal,username,deptno)
	values(9999,'test','ADMIN','01-24-1969','01-05-1997',3,2900,'MONIQUE1',99);
	--Delete the admin from that dept with manager still there
	delete from emp where empno = 9999
	--Delete rolled back
	select * from emp
END TRY
BEGIN CATCH
	ROLLBACK TRAN
	;THROW
END CATCH
ROLLBACK TRAN


/* 
	Constraint 3. The company hires adult personnel only.
	This constraint can be protected with a declarative implementation.
*/
	alter table emp add constraint  emp_chk_born  check (DATEDIFF(year, born, GETDATE()) >= 18);

-- Test 1: Insert an emp who is a minor
-- expected result: failure
BEGIN TRAN
BEGIN TRY
	insert into emp(empno,ename,job,born,hired,sgrade,msal,username,deptno)
	values(9999,'test','ADMIN','01-24-2018','01-05-1997',3,2900,'MONIQUE1',10);
	select * from emp
END TRY
BEGIN CATCH
	ROLLBACK TRAN
	;THROW
END CATCH
ROLLBACK TRAN

-- Test 2: Insert an emp who is an adult
-- expected result: succes
BEGIN TRAN
BEGIN TRY
	insert into emp(empno,ename,job,born,hired,sgrade,msal,username,deptno)
	values(9999,'test','ADMIN','01-24-2000','01-05-1997',3,2900,'MONIQUE1',10);
	--succes
	select * from emp
END TRY
BEGIN CATCH
	ROLLBACK TRAN
	;THROW
END CATCH
ROLLBACK TRAN

/*  5.	The start date and known trainer uniquely identify course offerings. 
		Note: the use of a filtered index is not allowed.

		the current unique constraint prevents inserting duplicates on the columns trainer and starts.
		but it also prevents duplicates of null values in the trainer column with the same date.
		this is not the favourable solution as a null value means it can be updated in the future or the trainer of this set course hasnt been decided yet.
		therefore we will be dropping the current unique constraint and add a trigger which will check for duplicates (except null values in trainer) on every record.
		violating this constraint is still possible when a record is updated to be on the same date with the same trainer.
		But we chose a trigger after insert since inserts are more likely to happen.
*/
drop trigger utr_insertOffr
go
CREATE TRIGGER utr_insertOffr
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

-- Test 1: Insert record with already existing start date and trainer id combination.
-- expected result: failure
BEGIN TRAN
BEGIN TRY
	alter table offr
	drop constraint ofr_unq
	insert into offr(course,starts,[status],maxcap,trainer,loc)
	values('AM4DPM', '1997-09-06', 'CONF', 6, 1017, 'SAN FRANCISCO');
	select * from offr
END TRY
BEGIN CATCH
	ROLLBACK TRAN
	;THROW
END CATCH
ROLLBACK TRAN

-- Test 2: Insert 2 records on the same date but with null values for trainer (not possible with the previous unique constraint).
-- expected result: succes
BEGIN TRAN
BEGIN TRY
	alter table offr
	drop constraint ofr_unq
	insert into offr(course,starts,[status],maxcap,trainer,loc)
	values('APEX', '1997-09-06', 'CONF', 6, null, 'SAN FRANCISCO');
	insert into offr(course,starts,[status],maxcap,trainer,loc)
	values('AM4DPM', '1997-09-06', 'CONF', 6, null, 'SAN FRANCISCO');
	select * from offr
END TRY
BEGIN CATCH
	ROLLBACK TRAN
	;THROW
END CATCH
ROLLBACK TRAN

/* 6.	Trainers cannot teach different courses simultaneously.
		on an update or insert in offr table can violate this procedure:
		if a trainer is updated/inserted to be giving a course while also giving another course
		but the most logic thing to do in our opinion is to create a procedure for inserts as this will happen more frequently.
*/
drop procedure usp_insertTrainer
go
CREATE PROCEDURE usp_insertTrainer
(
	@course varchar(6),
	@starts date,
	@status varchar(4),
	@maxcap numeric(2),
	@trainer numeric(4),
	@loc varchar(14)
)
AS
	BEGIN TRY
		declare @startdate date
		set @startdate = (select top 1 starts from offr where trainer = @trainer and course = @course and @starts >= starts order by starts asc)
		-- this could also be done without variable, but this will 
		if(@starts >= @startdate and @starts <= DATEADD(day, (select dur from crs where code = @course), @startdate))
			THROW 50004, 'the inserted course starts before all courses of this trainer are over. Record cant be inserted.', 1;
		else
			insert into offr values(@course, @starts, @status, @maxcap, @trainer, @loc)
	END TRY
	BEGIN CATCH	
		;THROW
	END CATCH
go

-- Test 1: insert course when another course of the same trainer is not finished yet
-- expected result: failure
BEGIN TRAN
BEGIN TRY
	exec usp_insertTrainer @course = 'AM4DP', @starts = '1997-09-10', @status = 'CONF', @maxcap = 6, @trainer = 1017, @loc = 'SAN FRANCISCO' 
END TRY
BEGIN CATCH
	ROLLBACK TRAN
	;THROW
END CATCH
ROLLBACK TRAN

-- Test 2: insert course when all other courses of this trainer are finished
-- expected result: succes
BEGIN TRAN
BEGIN TRY
	exec usp_insertTrainer @course = 'AM4DP', @starts = '1997-09-17', @status = 'CONF', @maxcap = 6, @trainer = 1017, @loc = 'SAN FRANCISCO' 
END TRY
BEGIN CATCH
	ROLLBACK TRAN
	;THROW
END CATCH
-- succes
select * from offr where course = 'AM4DP' and trainer = 1017
ROLLBACK TRAN

/* 7.	An active employee cannot be managed by a terminated employee. 

	On an insert in term this constraint can be violated in this way:
		Employee is inserted in term but not deleted in memp. So employees managed by the terminated employee are still in the memp table.
	On an update in term this constraint can be violated in this way:
		Terminated employee in term is updated to another empno, then data in the memp table will not correspond.

	We have decided to create a trigger after an insert on the term table to ensure all employees managed by the inserted manager will be deleted from the memp table.
*/
go
CREATE TRIGGER utr_insertTerm
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

drop trigger utr_insertTerm

-- Test 1: insert a record in term will delete all records in memp which have that exact empno.
-- expected result: succes
BEGIN TRAN
BEGIN TRY
	insert into term(empno, leftcomp, comments)
	values(1003, '2019-04-05', '');
	select * from term where empno = 1003
	select * from memp where mgr = 1003
END TRY
BEGIN CATCH
	ROLLBACK TRAN
	;THROW
END CATCH
ROLLBACK TRAN

-- Test 2: insert a record in term will delete all records in memp which have that exact empno.
-- expected result: succes
BEGIN TRAN
BEGIN TRY
	insert into term(empno, leftcomp, comments)
	values(1001, '2019-04-05', '');
	select * from term where empno = 1001
	select * from memp where mgr = 1001
END TRY
BEGIN CATCH
	ROLLBACK TRAN
	;THROW
END CATCH
ROLLBACK TRAN

/* 8.	A trainer cannot register for a course offering taught by him- or herself.
	
	On an insert in reg this constraint can be violated in this way:
		The empno is from a teacher that also teaches this course
	On an update in reg this constraint can be violated in this way:
		The empno is from a teacher that also teaches this course

	We have chosen to create a stored procedure on the reg table to ensure new registrations do not allow to register for a course taught by the same employee.
*/
drop procedure usp_insertReg
go
CREATE PROCEDURE usp_insertReg
(
	@stud numeric(4),
	@course varchar(6),
	@starts date,
	@eval numeric(1)
)
AS
	BEGIN TRY
		if(exists(select 1 from offr where course = @course and trainer = @stud))
			THROW 50005, 'the inserted student also teaches this course, this is not allowed.', 1;
		else
			insert into reg values (@stud, @course, @starts, @eval)
	END TRY
	BEGIN CATCH	
		;THROW
	END CATCH
go

-- Test 1: insert student who also teaches the course
-- expected result: failure
BEGIN TRAN
BEGIN TRY
	exec usp_insertReg @stud = 1017, @course = 'AM4DP', @starts = '1997-09-06', @eval = 4 
END TRY
BEGIN CATCH
	ROLLBACK TRAN
	;THROW
END CATCH
ROLLBACK TRAN

-- Test 2: insert student does not teach this course
-- expected result: succes
BEGIN TRAN
BEGIN TRY
	exec usp_insertReg @stud = 1013, @course = 'AM4DP', @starts = '1997-09-06', @eval = 4
END TRY
BEGIN CATCH
	ROLLBACK TRAN
	;THROW
END CATCH
ROLLBACK TRAN

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
go
ALTER PROCEDURE usp_insertTrainer
(
	@course varchar(6),
	@starts date,
	@status varchar(4),
	@maxcap numeric(2),
	@trainer numeric(4),
	@loc varchar(14)
)
AS
	BEGIN TRY
		declare @trainerloc varchar(14)
		set @trainerloc = (select loc from dept where deptno in (select deptno from emp where empno = @trainer))
		if((select count(*) from offr where loc = @trainerloc and trainer = @trainer)+1 <= (select count(*) from offr where trainer = @trainer)/2)
			THROW 50006, 'the inserted course should be home-based (same location as the trainer). Else more than half of the courses taught by this trainer are not home-based, this is not allowed.', 1;
		else
		begin
			insert into offr values(@course, @starts, @status, @maxcap, @trainer, @loc)
		end
	END TRY
	BEGIN CATCH	
		;THROW
	END CATCH
go

-- Test 1: insert non home-based courses that exceed the max of the constraint (half of total courses)
-- expected result: failure
BEGIN TRAN
BEGIN TRY
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
	select * from offr where trainer = 1017
END TRY
BEGIN CATCH
	ROLLBACK TRAN
	;THROW
END CATCH
ROLLBACK TRAN

-- Test 2: insert non home-based course that does not exceed the max of the constraint
-- expected result: succes
BEGIN TRAN
BEGIN TRY
	exec usp_insertTrainer @course = 'AM4DP', @starts = '1998-09-17', @status = 'CONF', @maxcap = 6, @trainer = 1017, @loc = 'AMSTERDAM'
END TRY
BEGIN CATCH
	ROLLBACK TRAN
	;THROW
END CATCH
ROLLBACK TRAN

/* 10.	Offerings with 6 or more registrations must have status confirmed.
	
	On an insert in reg this constraint can be violated in this way:
		if a new student is registered and it now totals to 6 for this course the offr table is not updated to have the status CONF for this course
	On an update in reg this constraint can be violated in this way:
		if a student is updated to follow another course and it  now totals to 6 or more registrations the offr table is not updated to have the status CONF for this course
	On an update in offr this constraint can be violated in this way:
		if a course is updated to be scheduled even though there are 6 or more students registered for the course

		we have chosen to update the already existing stored procedure of inserting new registrations to also check for this constraint.
*/
go
ALTER PROCEDURE usp_insertReg
(
	@stud numeric(4),
	@course varchar(6),
	@starts date,
	@eval numeric(1)
)
AS
	BEGIN TRY
		if((select count(*) from reg where course = @course and starts = @starts) >= 6)
			update offr set status = 'CONF' where course = @course and starts = @starts
	END TRY
	BEGIN CATCH	
		;THROW
	END CATCH
go

-- Test 1: Insert enough students to fill a course (6 total)
-- expected result: updated to CONF
BEGIN TRAN
BEGIN TRY
	exec usp_insertReg @stud = 1029, @course = 'AM4DP', @starts = '2006-08-03', @eval = -1
	exec usp_insertReg @stud = 1030, @course = 'AM4DP', @starts = '2006-08-03', @eval = -1
	select * from offr where course = 'AM4DP' and starts = '2006-08-03'
END TRY
BEGIN CATCH
	;THROW
END CATCH
ROLLBACK TRAN

-- Test 2: Insert not enough students to fill a course (6 total)
-- expected result: nothing updated
BEGIN TRAN
BEGIN TRY
	exec usp_insertReg @stud = 1029, @course = 'AM4DP', @starts = '2006-08-03', @eval = -1
	exec usp_insertReg @stud = 1030, @course = 'AM4DP', @starts = '2006-08-03', @eval = -1
	select * from offr where course = 'AM4DP' and starts = '2006-08-03'
END TRY
BEGIN CATCH
	;THROW
END CATCH
ROLLBACK TRAN

/* 11.	You are allowed to teach a course only if:
		your job type is trainer and
			-      you have been employed for at least one year 
			-	or you have attended the course yourself (as participant) 


*/
drop trigger utr_checkNewTeacher
go
CREATE TRIGGER utr_checkNewTeacher
on offr
after insert
AS
	BEGIN TRY
		if(exists(select 1 from inserted i inner join emp e on i.trainer = e.empno where e.job = 'TRAINER'))
		begin
			if(exists(select 1 from inserted where starts in (select i.starts from inserted i inner join offr o on i.trainer = o.trainer where DATEDIFF(year, i.starts, o.starts) >= 1)))
			begin
				if(not exists(select 1 from inserted where trainer in (select stud from reg)))
					THROW 50007, 'the employee of this inserted course has not been an employee for at least one year or the course has not been followed by this employee', 1;	
			end
			else
				THROW 50008, 'the employee of this inserted course has not been an employee for at least one year', 1;	
		end
		else
			THROW 50009, 'the inserted course is not given by a trainer', 1;
	END TRY
	BEGIN CATCH	
		;THROW
	END CATCH
go

-- Test 1: Insert coure not given by a teacher
-- expected result: failure
BEGIN TRAN
BEGIN TRY
	alter table offr
	drop constraint ofr_unq
	insert into offr(course,starts,[status],maxcap,trainer,loc)
	values('AM4DPM', '2010-09-06', 'CONF', 6, 1015, 'SAN FRANCISCO');
	select * from offr
END TRY
BEGIN CATCH
	ROLLBACK TRAN
	;THROW
END CATCH
ROLLBACK TRAN

-- Test 2: Insert coure not given by a teacher
-- expected result: failure
BEGIN TRAN
BEGIN TRY
	alter table offr
	drop constraint ofr_unq
	insert into offr(course,starts,[status],maxcap,trainer,loc)
	values('AM4DPM', '2001-11-12', 'CONF', 6, 1018, 'SAN FRANCISCO');
	select * from offr
END TRY
BEGIN CATCH
	ROLLBACK TRAN
	;THROW
END CATCH
ROLLBACK TRAN

-- Test 3: Insert coure not given by a teacher
-- expected result: failure
BEGIN TRAN
BEGIN TRY
	alter table offr
	drop constraint ofr_unq
	insert into offr(course,starts,[status],maxcap,trainer,loc)
	values('AM4DPM', '2010-09-06', 'CONF', 6, 1018, 'SAN FRANCISCO');
	select * from offr
END TRY
BEGIN CATCH
	ROLLBACK TRAN
	;THROW
END CATCH
ROLLBACK TRAN

alter table emp add constraint  emp_chk_born  check (DATEDIFF(year, born, GETDATE()) >= 18);



select * from reg where stud in (select trainer from offr) and course in (select course from offr)

select * from reg where stud = 1031
select * from offr where trainer = 1018
select count(*), course, starts from reg group by course, starts
select * from reg
select * from emp