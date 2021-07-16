USE master
GO
--Create SQL server audit to track changes made to the PRODUCT table
CREATE SERVER AUDIT sql_product_audit
TO FILE (FILEPATH = N'C:\temp\Log')

--Enable the sql_product_audit
ALTER SERVER AUDIT sql_product_audit
WITH (STATE=ON)

USE c1591716db;
GO
--Create audit specification to track every change made
--on the PRODUCT table
CREATE DATABASE AUDIT SPECIFICATION spl_prod_specif
FOR SERVER AUDIT sql_product_audit
ADD(SELECT, INSERT, UPDATE, DELETE ON dbo.PRODUCT BY PUBLIC) --since every user is a member of Public
WITH (STATE = ON);
GO


USE master;
GO

--SQL server audit for the ORDER table
CREATE SERVER AUDIT sql_order_audit
TO FILE (FILEPATH = N'C:\temp\Log')

--Enable the sql_product_audit
ALTER SERVER AUDIT sql_order_audit
WITH (STATE=ON)

USE c1591716db;
GO
--Create audit specification to track every change made
--on the ORDER table
CREATE DATABASE AUDIT SPECIFICATION spl_ord_specif
FOR SERVER AUDIT sql_order_audit
ADD(SELECT, INSERT, UPDATE, DELETE ON dbo.[ORDER] BY PUBLIC) 
WITH (STATE = ON);
GO


USE master;
GO

--SQL server audit for the ORDERITEM table
CREATE SERVER AUDIT sql_orderitem_audit
TO FILE (FILEPATH = N'C:\temp\Log')

--Enable the sql_product_audit
ALTER SERVER AUDIT sql_orderitem_audit
WITH (STATE=ON)

USE c1591716db;
GO
--Create audit specification to track every change made
--on the ORDER table
CREATE DATABASE AUDIT SPECIFICATION spl_orditem_specif
FOR SERVER AUDIT sql_orderitem_audit
ADD(SELECT, INSERT, UPDATE, DELETE ON dbo.ORDERITEM BY PUBLIC) 
WITH (STATE = ON);
GO


USE master;
GO
--Create SQL server audit to track permission changes
CREATE SERVER AUDIT sql_perm_audit
TO FILE (FILEPATH=N'C:\temp\Log')
GO
--Enable SQL server audit
ALTER SERVER AUDIT sql_perm_audit
WITH (STATE=ON)
GO

--Create audit specification to track permissions
CREATE DATABASE AUDIT SPECIFICATION permissions_audit_specification
FOR SERVER AUDIT sql_perm_audit
ADD (SCHEMA_OBJECT_PERMISSION_CHANGE_GROUP)
WITH (STATE = ON)

--Create SQL server audit to track failed and successful logins
CREATE SERVER AUDIT sql_server_audit
TO FILE (FILEPATH=N'C:\temp\Log')

--Enable SQL server audit
ALTER SERVER AUDIT sql_server_audit
WITH (STATE = ON)
GO


--create SQL server audit specification to track the logins
CREATE SERVER AUDIT SPECIFICATION login_audit_specification
FOR SERVER AUDIT sql_server_audit
ADD (FAILED_LOGIN_GROUP),
ADD (SUCCESSFUL_LOGIN_GROUP)
WITH (STATE = ON);
GO



ALTER SERVER AUDIT SPECIFICATION permissions_audit_specification
WITH (STATE = OFF)
GO


--Function that retrieves all the failed logins of a given user
CREATE OR ALTER FUNCTION getAllLoginFails(@usrName varchar(255))
RETURNS TABLE
AS
	RETURN(SELECT event_time, action_id, session_server_principal_name 
			FROM fn_get_audit_file('C:\temp\Log\*', null, null)
			WHERE action_id = 'LGIF' AND session_server_principal_name = @usrName)
GO



--Function to retrieve the begin timestamp (login event) and end 
--timestamp (logout event) for a given user 
CREATE OR ALTER FUNCTION getSessionInfo(@usrName varchar(255))
RETURNS TABLE
AS
	RETURN(SELECT event_time
		   FROM fn_get_audit_file('C:\temp\Log\*', null, null)
		   WHERE action_id = 'LGIS' AND session_server_principal_name = @usrName
				UNION
		   SELECT event_time
		   FROM fn_get_audit_file('C:\temp\Log\*', null, null)
		   WHERE action_id = 'LGO' AND session_server_principal_name = @usrName)

/*
DROP FUNCTION getSessionInfo
DROP FUNCTION getAllLoginFails
DROP SERVER AUDIT SPECIFICATION permissions_audit_specification
DROP SERVER AUDIT SPECIFICATION spl_prod_specif
DROP SERVER AUDIT SPECIFICATION spl_ord_specif
DROP SERVER AUDIT SPECIFICATION login_audit_specification
DROP SERVER AUDIT SPECIFICATION spl_orditem_specif
*/