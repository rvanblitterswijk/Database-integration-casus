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

/*====== IMPLEMENTATION ==============================================================================================================================================================================================================*/

go
CREATE TRIGGER utr_deleteEmp
--DROP TRIGGER utr_deleteEmp
on emp
after delete
AS
	BEGIN TRY
		--If there is a deleted admin
		if (EXISTS (select 1 from deleted where job = 'ADMIN'))
		begin
		--If there is a dept with a deleted admin that has no more admins
			if (not exists (select 1 from emp where deptno in (select deptno from deleted where job = 'ADMIN') and job = 'ADMIN'))
			begin
				--If the dept from a deleted admin still has a president or manager
				if (exists (select 1 from emp where deptno in (select deptno from deleted where job = 'ADMIN') and (job = 'PRESIDENT' or job = 'MANAGER')))
				THROW 50002, 'You cant delete an admin from a department with no more admins and a president/manager', 1;
			end
		end
	END TRY
	BEGIN CATCH	
		;THROW
	END CATCH
go

/*====== TESTS ==============================================================================================================================================================================================================*/

EXEC tSQLt.NewTestClass 'Constraint2'; 
--EXEC tSQLt.DropClass 'Constraint2';

GO
CREATE PROCEDURE [Constraint2].[test = 1: Delete the last admin from a dept with a president/manager still there (multiple inserts in 1 statement)]  
AS
BEGIN	
	EXEC tSQLt.FakeTable 'dbo.emp'
	EXEC [tSQLt].[ApplyTrigger] @tablename = 'dbo.emp', @triggername = 'utr_deleteEmp'
	EXEC tSQLt.ExpectException 'You cant delete an admin from a department with no more admins and a president/manager'
	--Make an admin in dept 99
	insert into emp(empno,ename,job,born,hired,sgrade,msal,username,deptno)
	values(9999,'test','ADMIN','01-24-1969','01-05-1997',3,2900,'MONIQUE1',99);
	--Make an admin in dept 98
	insert into emp(empno,ename,job,born,hired,sgrade,msal,username,deptno)
	values(9997,'test','SALESREP','01-24-1969','01-05-1997',3,2900,'MONIQUE1',98);
	--Make a manager in dept 99
	insert into emp(empno,ename,job,born,hired,sgrade,msal,username,deptno)
	values(9998,'test','MANAGER','01-24-1969','01-05-1997',3,2900,'MONIQUE2',99);
	--Delete the admin from dept 99 with manager still there
	delete from emp where empno = 9999
	delete from emp where empno = 9997
END

GO
CREATE PROCEDURE [Constraint2].[test = 2: Delete the last admin from a dept without a president/manager (multiple inserts in 1 statement)]  
AS
BEGIN	
	EXEC tSQLt.FakeTable 'dbo.emp'
	EXEC [tSQLt].[ApplyTrigger] @tablename = 'dbo.emp', @triggername = 'utr_deleteEmp'
	EXEC tSQLt.ExpectNoException
	--Make an admin in dept 99
	insert into emp(empno,ename,job,born,hired,sgrade,msal,username,deptno)
	values(9999,'test','ADMIN','01-24-1969','01-05-1997',3,2900,'MONIQUE1',99);
	--Make an admin in dept 98
	insert into emp(empno,ename,job,born,hired,sgrade,msal,username,deptno)
	values(9998,'test','ADMIN','01-24-1969','01-05-1997',3,2900,'MONIQUE1',99);
	--Make an admin in dept 98
	insert into emp(empno,ename,job,born,hired,sgrade,msal,username,deptno)
	values(9997,'test','SALESREP','01-24-1969','01-05-1997',3,2900,'MONIQUE1',98);
	--Delete the admin from dept 99 (without a manager)
	delete from emp where empno = 9999
	delete from emp where empno = 9997
	
END

/* ====== EXECUTION ========================================================================================================================================================================================================================================*/

EXEC [tSQLt].[Run] 'Constraint2'