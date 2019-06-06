/****** EMPLOYEE **********************************************************************************************************************************************/

/* ================ IMPLEMENTATION ================ */
go
use master
go

--Create an employee login
CREATE LOGIN employee1 WITH PASSWORD = 'employee1'
--drop login employee1

--Create the user employee1 on login employee1
go
use COURSE
go
CREATE USER employee1 FROM LOGIN employee1
--drop user employee1

CREATE ROLE employee
--drop role employee

-- Grant the permissions to the employee role
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.reg to employee
GRANT SELECT on dbo.emp TO employee
GRANT SELECT on dbo.offr TO employee

--Make the user employee1 member of the employee role
ALTER ROLE employee ADD MEMBER employee1

/* ================ TESTS ================ */

--Impersonate the employee1 login
EXECUTE AS LOGIN = 'employee1'
--Check which user and loggin you are impersonating
SELECT user as [database user], system_user as [current login], original_login() as [originele login]

--The employee user has full acces to the reg table so it can insert, update delete and select data as long as no constraints are violated
begin tran
--Insert a new record
insert into reg values(1000, 'AM4DP', '2001-11-03', 4)
--New record is inserted
select * from reg
--update the record
update reg
set eval = 3
where course = 'AM4DP' and starts = '2001-11-03' and stud = 1000
--New record updated
select * from reg
--Delete the record
Delete from reg 
where course = 'AM4DP' and starts = '2001-11-03' and stud = 1000
--New record deleted
select * from reg
rollback tran

--The employee can read data from the EMP and OFFR tables
select * from emp
select * from offr

--CRUD actions on other tables are not allowed
select * from grd
insert into crs values('ADP', 'Applied Math for DB-Pros', 'DSG', 9)

revert

/******SERVICE ACCOUNT**********************************************************************************************************************************************/

/* ================ IMPLEMENTATION ================ */

go
use master
go

--Create an employee login
CREATE LOGIN serviceaccount WITH PASSWORD = 'serviceaccount'
--drop login serviceaccount

--Create the user employee1 on login employee1
go
use COURSE
go
CREATE USER serviceaccount FROM LOGIN serviceaccount
--drop user serviceaccount

CREATE ROLE serviceaccountrole
--drop role serviceaccountrole

-- Grant the permissions to the employee role
grant select on schema::dbo to serviceaccountrole

--Make the user employee1 member of the employee role
ALTER ROLE serviceaccountrole ADD MEMBER serviceaccount


/* ================ TESTS ================ */

--Impersonate the employee1 login
EXECUTE AS LOGIN = 'serviceaccount'
--Check which user and loggin you are impersonating
SELECT user as [database user], system_user as [current login], original_login() as [originele login]

--The Serviceaccount can read from all tables
select * from crs
select * from dept
select * from emp
select * from grd
select * from memp
select * from offr
select * from reg
select * from srep
select * from term

--Inserts, updates and deletes are not allowed
insert into srep values(1011, 10, 100)
delete from crs where code = 'AM4DP'
update grd
set llimit = 10
where grade = 1

revert