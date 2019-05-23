CREATE PROCEDURE usp_create_table_with_triggers 
	@table varchar(255)
AS
	SET NOCOUNT ON 
	SET XACT_ABORT OFF
	DECLARE @TranCounter INT;
	SET @TranCounter = @@TRANCOUNT;
	IF @TranCounter > 0 
		SAVE TRANSACTION ProcedureSave;
	ELSE 
		BEGIN TRANSACTION;
	BEGIN TRY

		--create an exact copy of the table without the constraints
		declare @sql nvarchar(MAX) = ''
		set @sql = 'SELECT top 0 * INTO HIST_'+@table+' FROM '+@table
		exec sp_sqlexec @sql

		--add the timestamp column
		set @sql = 'ALTER TABLE HIST_'+@table+' ADD [timestamp] datetime default getdate() not null'
		exec sp_sqlexec @sql
		
		--get the primary key columns
		declare @columns nvarchar(max) = ''
		SELECT @columns = @columns + COLUMN_NAME+','
		FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
		WHERE OBJECTPROPERTY(OBJECT_ID(CONSTRAINT_SCHEMA + '.' + QUOTENAME(CONSTRAINT_NAME)), 'IsPrimaryKey') = 1
		AND TABLE_NAME = @table
		
		--Make the timestamp column the primary key
		set @columns = @columns + 'timestamp'
		set @sql = 'ALTER TABLE HIST_'+@table+' ADD  PRIMARY KEY ('+@columns+');'
		exec sp_sqlexec @sql
	
		--see columns to transfer
		declare @Histcolumns nvarchar(max) =''
		SELECT @Histcolumns = @Histcolumns+ COLUMN_NAME+', ' 
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = @table
		set @Histcolumns = SUBSTRING(@Histcolumns,0,LEN(@Histcolumns))

		--Create update trigger on the table
		set @sql ='create trigger update_hist_'+@table+' on '+@table+' for update as 
					set nocount on 
					insert into HIST_'+@table+' ('+@Histcolumns+') select '+@Histcolumns+' from deleted;'
		exec sp_sqlexec @sql
		set @sql = 'exec sp_settriggerorder @triggername = '''+concat('update_hist_',@table)+''', @order = ''last'', @stmttype = ''update'''
		exec sp_sqlexec @sql

		--Create the delete trigger on the 
		set @sql ='create trigger delete_hist_'+@table+' on '+@table+' for delete as 
					set nocount on 
					insert into HIST_'+@table+' ('+@Histcolumns+') select '+@Histcolumns+' from deleted;'
		exec sp_sqlexec @sql	
		set @sql = 'exec sp_settriggerorder @triggername = '''+concat('delete_hist_',@table)+''', @order = ''last'', @stmttype = ''delete'''
		exec sp_sqlexec @sql

		IF @TranCounter = 0 AND XACT_STATE() = 1
			COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @TranCounter = 0 
			BEGIN
				IF XACT_STATE() = 1 ROLLBACK TRANSACTION;
			END;
		ELSE
			BEGIN
				IF XACT_STATE() <> -1 ROLLBACK TRANSACTION ProcedureSave;
			END;	
		THROW
	END CATCH
GO

CREATE PROCEDURE usp_create_the_hist_tables
AS
	SET NOCOUNT ON 
	SET XACT_ABORT OFF
	DECLARE @TranCounter INT;
	SET @TranCounter = @@TRANCOUNT;
	IF @TranCounter > 0 
		SAVE TRANSACTION ProcedureSave;
	ELSE 
		BEGIN TRANSACTION;
	BEGIN TRY		
		declare @sql nvarchar(max) = ''

		select @sql = @sql +'exec usp_createe_table_with_triggers ' +i.[TABLE_NAME]+';' from INFORMATION_SCHEMA.TABLES i
		where 'HIST_'+i.TABLE_NAME not in (select TABLE_NAME from INFORMATION_SCHEMA.TABLES)
		and i.[TABLE_NAME] not like 'HIST_%';
		
		exec sp_sqlexec @sql
		
		IF @TranCounter = 0 AND XACT_STATE() = 1
			COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @TranCounter = 0 
			BEGIN
				IF XACT_STATE() = 1 ROLLBACK TRANSACTION;
			END;
		ELSE
			BEGIN
				IF XACT_STATE() <> -1 ROLLBACK TRANSACTION ProcedureSave;
			END;	
		THROW
	END CATCH
GO

exec usp_create_the_hist_tables
