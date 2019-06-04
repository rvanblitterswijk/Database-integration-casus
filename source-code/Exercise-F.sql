/****** EMPLOYEE **********************************************************************************************************************************************/
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

--Impersonate the employee1 login
EXECUTE AS LOGIN = 'employee1'

revert
SELECT user as [database user], system_user as [current login], original_login() as [originele login]


/******SERVICE ACCOUNT**********************************************************************************************************************************************/
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
ALTER ROLE employee ADD MEMBER employee1

--Impersonate the employee1 login
EXECUTE AS LOGIN = 'employee1'