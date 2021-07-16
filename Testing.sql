------------Testing-----------
--enabling the security policy
ALTER SECURITY POLICY dbo.db_security_pol WITH (state=on)

--Creating two users and adding them to the CUSTOMER role
CREATE USER Alice WITHOUT LOGIN 
ALTER ROLE CUSTOMER ADD MEMBER Alice

CREATE USER Bob WITHOUT LOGIN
ALTER ROLE CUSTOMER ADD MEMBER Bob

--expected result: successfully retreives the tuples as members of the CUSTOMER role can access
--PRODUCT information excluding Cost_price
EXECUTE AS USER='Alice'
SELECT Product_id, [Name], Quantity, [Description], Sales_price, Discount
FROM dbo.PRODUCT
REVERT

--expected result: fails to retreive the Cost_price as members of the CUSTOMER role don't have
--SELECT permissions on the Cost_price column
EXECUTE AS USER='Alice'
SELECT Cost_price
FROM dbo.PRODUCT
REVERT


--expected result: returns tubles in the CUSTOMER table that belong to Alice (FirstName = Alice)
--due to a filter predicate
--password should be encrypted
EXECUTE AS USER='Alice'
SELECT * FROM dbo.CUSTOMER
REVERT

--expected result: successfully updates the firstName of the User Bob as there is a block predicate preventing him
--from updating other users' firstnames
EXECUTE AS USER='Bob'
UPDATE dbo.CUSTOMER
SET Firstname = 'Bobby'
REVERT

--expected result: successfully returns all the credit cards (last four digit only) that belong to the user Alice
EXECUTE AS USER='Alice'
SELECT * FROM dbo.CREDITCARD
REVERT


--expected result: successfully deletes the credit card with id=1 as Alice is the owner (block predicate)
EXECUTE AS USER='Alice'
DELETE dbo.CREDITCARD
WHERE Credit_card_id = 1
REVERT

--expected result: fails to delete the credit card with id=5 as Alice is not the owner (block predicate)
--0 rows affected
EXECUTE AS USER='Alice'
DELETE dbo.CREDITCARD
WHERE Credit_card_id = 5
REVERT

--expected result: successfully updates the Holder_name that belongs to the user Bob
--as there is a block predicate preventing him from updating other users' information
EXECUTE AS USER='Bob'
UPDATE dbo.CREDITCARD
SET Holder_name = 'Bobby Michealson'
REVERT  

--expected result: fails to update the CVC code as members of the CUSTOMER role can only update
--the holders_name and the billing_address columns in the CREDITCARD table
EXECUTE AS USER='Bob'
UPDATE dbo.CREDITCARD
SET CVC_code = '555'
WHERE Credit_card_id = 4
REVERT  

--expected result: successful since members of the CUSTOMER role can insert/remove credit cards that belong to them
EXECUTE AS USER ='Alice'
INSERT INTO dbo.CREDITCARD(Credit_card_id, Credit_card_number, Holder_name, Expire_date, CVC_code, Billing_address,Owner_id) VALUES 
(8, '1111-1111-1111-9999', 'Alice Smith', '2021-11-01', '001', '123 peach street', 1); 
REVERT

--expected result: successful since members of the CUSTOMER role can insert/remove credit cards that belong to them
EXECUTE AS USER ='Alice'
DELETE FROM dbo.CREDITCARD
WHERE Credit_card_id = 8
REVERT

--disabling security policy
ALTER SECURITY POLICY dbo.db_security_pol WITH (state=off)


--expected result: successful. the Product.quantity and Order.Total_amount should be updated as the Status of the Order is 'in preparation'
--(should have three rows affected)
UPDATE dbo.ORDERITEM
SET Quantity = 2
WHERE Order_id = 1 AND Product_id = 3

--expected result: the Product.quantity; Order.Total_amount should be updated as an Orderitem is being deleted
--(should have three rows affected)
DELETE FROM dbo.ORDERITEM
WHERE Order_id = 1 AND Product_id = 3

--expected result: should successfully insert into the Orderitem table and 
--automatically calculate the Price_paid (due to trigger)
--4 rows affected
INSERT INTO dbo.ORDERITEM (Order_id, Product_id, Quantity) VALUES 
(4, 3, 3)

--expected result: should successfully delete this order as 
--the order status is 'in preparation'. Should also update the Product and Order table
--it will also delete the order from the Order table since it will no longer have associated 
--orderitems (3 rows affected)
DELETE FROM dbo.ORDERITEM
WHERE Order_id = 3

--expected result: successful.
--should print 'Credit Card ending with 8893 is charged $1489.44 for the order with order id 2'
UPDATE dbo.[ORDER]
SET [Status] = 'shipped'
WHERE Order_id = 2

--expected result: Encrypted passwords
select * from dbo.CUSTOMER


--Audit Testing 
--SL = SELECT
--IN = INSERT
--UP = UPDATE
--DL = DELETE
--expected result: to retrieve changes made to the PRODUCT table
SELECT event_time, action_id as [action], schema_name, object_name 
FROM fn_get_audit_file('C:\temp\Log\*', null, null)
WHERE action_id in ('SL', 'IN', 'UP', 'DL') AND object_name = 'PRODUCT'
GO

--expected result: to retrieve changes made to the ORDER table
SELECT event_time, database_principal_name,action_id as [action], schema_name, object_name 
FROM fn_get_audit_file('C:\temp\Log\*', null, null)
WHERE action_id in ('SL', 'IN', 'UP', 'DL') AND object_name = 'ORDER'


--expected result: to retrieve changes made to the ORDERITEM table
SELECT event_time, database_principal_name,action_id as [action], schema_name, object_name 
FROM fn_get_audit_file('C:\temp\Log\*', null, null)
WHERE action_id in ('SL', 'IN', 'UP', 'DL') AND object_name = 'ORDERITEM'


--expected result: to retrieve permission (GRANT, DENY, REVOKE) changes
SELECT event_time,database_principal_name AS granter, target_database_principal_name as grantee, action_id as permission 
FROM fn_get_audit_file('C:\temp\Log\*', null, null)
WHERE action_id in ('G', 'D', 'R')

--expected result: returns all the failed logins of the user Alice
SELECT * FROM getAllLoginFails('Alice')

--expected result: to retrieve the begin timestamp (login event) and end 
--timestamp (logout event) for the user Alice
SELECT * FROM getSessionInfo('Alice')


/*
DROP USER Alice
DROP USER Bob
*/
