/* 
	Constraint 3. The company hires adult personnel only.
	This constraint can be protected with a declarative implementation.
*/

/*======== IMPLEMENTATION =========================================================================================================================================================================================================================*/

alter table emp add constraint  emp_chk_born  check (DATEDIFF(year, born, GETDATE()) >= 18);

/*====== TESTS ==============================================================================================================================================================================================================*/

EXEC tSQLt.NewTestClass 'Constraint3'; 
--EXEC tSQLt.DropClass 'Constraint3';
GO
CREATE PROCEDURE [Constraint3].[test = 1: Insert an emp who is a minor]  
AS
BEGIN	
	EXEC tSQLt.FakeTable 'dbo.emp';
	
	alter table emp
	add constraint  test_emp_chk_born  check (DATEDIFF(year, born, GETDATE()) >= 18);

	EXEC tSQLt.ExpectException 'The INSERT statement conflicted with the CHECK constraint "test_emp_chk_born". The conflict occurred in database "COURSE", table "dbo.emp", column ''born''.'

	insert into emp(empno,ename,job,born,hired,sgrade,msal,username,deptno)
	values(9999,'test','ADMIN','01-24-2018','01-05-1997',3,2900,'MONIQUE1',10);

END
GO

GO
CREATE PROCEDURE [Constraint3].[test = 2: Insert an emp who is an adult]  
AS
BEGIN	
	EXEC tSQLt.FakeTable 'dbo.emp';
	
	alter table emp
	add constraint  test_emp_chk_born  check (DATEDIFF(year, born, GETDATE()) >= 18);

	EXEC tSQLt.ExpectNoException

	insert into emp(empno,ename,job,born,hired,sgrade,msal,username,deptno)
	values(9999,'test','ADMIN','01-24-2000','01-05-1997',3,2900,'MONIQUE1',10);

END
GO

/* ====== EXECUTION ========================================================================================================================================================================================================================================*/

EXEC [tSQLt].[Run] 'Constraint3'