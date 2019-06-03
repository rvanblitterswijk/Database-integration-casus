/* 
	Constraint 1. The president of the company earns more than $10.000 monthly. 
	Assumption: This constraint does not include Bonuses as this is about monthly earnings.
*/

/*======== IMPLEMENTATION =========================================================================================================================================================================================================================*/

go
CREATE PROCEDURE usp_updateMsal
--DROP PROCEDURE usp_updateMsal
(
	@empno numeric(4,0),
	@newMsal numeric(7,2)
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

EXEC tSQLt.NewTestClass 'Constraint1'; 
--EXEC tSQLt.DropClass 'Constraint1';

GO
CREATE PROCEDURE [Constraint1].[test = 1: update mSal > 10000 on a president]  
AS
BEGIN	
	EXEC tSQLt.FakeTable 'dbo.emp';
	EXEC tSQLt.ExpectNoException
	insert into emp values (1000, 'Hans', 'PRESIDENT', '1957-12-22', '1992-01-01', 11, 11000, 'HANS', 10)
	EXEC usp_updateMsal @empno = 1000, @newMsal = 12000
END
GO

GO
CREATE PROCEDURE [Constraint1].[test = 2: update mSal < 10000 on a president]  
AS
BEGIN	
	EXEC tSQLt.FakeTable 'dbo.emp';
	EXEC tSQLt.ExpectException 'President msal can not be less than 10000'
	insert into emp values (1000, 'Hans', 'PRESIDENT', '1957-12-22', '1992-01-01', 11, 11000, 'HANS', 10)
	EXEC usp_updateMsal @empno = 1000, @newMsal = 9000
END
GO

GO
CREATE PROCEDURE [Constraint1].[test = 3: update msal < 10000 on a manager]  
AS
BEGIN	
	EXEC tSQLt.FakeTable 'dbo.emp';
	EXEC tSQLt.ExpectNoException
	insert into emp values (1000, 'Hans', 'MANAGER', '1957-12-22', '1992-01-01', 11, 11000, 'HANS', 10)
	EXEC usp_updateMsal @empno = 1000, @newMsal = 9000
END
GO

/* ====== EXECUTION ========================================================================================================================================================================================================================================*/

EXEC [tSQLt].[Run] 'Constraint1'