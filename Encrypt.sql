--Create an INSTEAD OF INSERT trigger
--to ensure CUSTOMER.password is encrypted everytime a new data is inserted
CREATE OR ALTER TRIGGER password_trigger
ON dbo.CUSTOMER
INSTEAD OF INSERT
AS
	DECLARE @plain_password varchar(255);
	SELECT @plain_password = [Password] FROM inserted;
	--using Hashbytes as there will be no need to ever decrypt a password
	DECLARE @encry_password varbinary(4000) = hashbytes('SHA2_512', @plain_password);
	
	INSERT INTO dbo.CUSTOMER
		SELECT UserID, Email, [Password]=@encry_password, FirstName, LastName, [Address], Phone
		FROM inserted
GO

--To encrypt already exsisting passwords in the customer table
UPDATE dbo.CUSTOMER
SET [Password] = hashbytes('SHA2_512', [Password])

--Credit card numbers are encrypted using dynamic data masking (during table creation)

--encrypting the cost_price column of the product table using a passphrase
UPDATE dbo.PRODUCT
SET Cost_price = ENCRYPTBYPASSPHRASE('product cost phrase', CONVERT(VARBINARY,Cost_price))


--returing the decrypted version of the cost_price
SELECT Product_id, [Name] ,Cost_price = DECRYPTBYPASSPHRASE('product cost phrase', Cost_price)
FROM dbo.PRODUCT

/*
DROP TRIGGER password_trigger
*/