--Filter predicate for CUSTOMER & CREDITCARD TABLE
CREATE OR ALTER FUNCTION customer_filter_pred(@uID int)
RETURNS TABLE
WITH SCHEMABINDING
AS 
	RETURN
		SELECT 1 AS pred_result
		WHERE @uID in (SELECT UserID FROM dbo.Clearance 
						WHERE UserName = USER_NAME())

GO

--After trigger that allows CUSTOMER to insert\remove credit cards
CREATE OR ALTER TRIGGER credit_trigger
ON dbo.CREDITCARD
AFTER INSERT, DELETE
AS 
	--if the customer inserted/deleted a credit card with a different owner id then rollback
	DECLARE @uID int;
	SELECT @uID = UserID FROM dbo.Clearance WHERE UserName = USER_NAME();
	DECLARE @ownerID int;

	--for insert
	IF EXISTS (SELECT * FROM inserted)
		BEGIN
			SELECT @ownerID = Owner_id FROM inserted;
			IF @uID <> @ownerID
				ROLLBACK
		END
	--for delete
	IF EXISTS (SELECT * FROM deleted)
		BEGIN
			SELECT @ownerID = Owner_id FROM deleted
			IF @uID <> @ownerID
				ROLLBACK
		END
GO


--Block predicate for ORDERITEM table
--ensures that an order can be removed iff the status is 'in preparation'
--ensures that an order item quantity cannot be updated unless the status is 'in preparation'
--ensures that a new order item cannot be placed unless the order status is 'in preparation'
CREATE OR ALTER FUNCTION orderitem_block_pred(@ordID int)
RETURNS TABLE
WITH SCHEMABINDING
AS
	RETURN
		SELECT 1 as pred_result
		WHERE @ordID in (SELECT Order_id FROM dbo.[ORDER] WHERE [Status] = 'in preparation')
GO

--After DELETE trigger to ensure that an order gets removed if it doesn't contain any order items
CREATE OR ALTER TRIGGER orderitem_after_delete_trigger
ON dbo.ORDERITEM
AFTER DELETE
AS
	DECLARE @orID int;
	SELECT @orID = Order_id FROM deleted;
	IF NOT EXISTS (SELECT * FROM dbo.ORDERITEM WHERE Order_id = @orID)
		BEGIN
			DELETE FROM dbo.[ORDER]
			WHERE Order_id = @orID
		END
GO

--After trigger for Product table
--ensures that a product can be removed iff the quantity is 0
CREATE OR ALTER TRIGGER product_after_trigger
ON dbo.PRODUCT
AFTER DELETE 
AS
	IF 0 <> (SELECT Quantity FROM deleted)
		ROLLBACK
GO

--function that calculates the total paid price of an order item
CREATE OR ALTER FUNCTION dbo.getPaidPrice(@prdID int)
RETURNS INTEGER
AS
	BEGIN
		DECLARE @discnt DECIMAL(2,2);
		DECLARE @salesp DECIMAL(10,2);
		SELECT @discnt = Discount FROM dbo.PRODUCT WHERE Product_id = @prdID;
		SELECT @salesp = Sales_price FROM dbo.PRODUCT WHERE Product_id = @prdID;
		DECLARE @pdPrice DECIMAL(10,2);
		SET @pdPrice = ((1-@discnt)*@salesp);

		RETURN @pdPrice;

	END
GO

--After trigger for ORDERITEM table
--ensures that ORDERITEM.paidprice is always bigger than PRODUCT.cost_price
--ensures that ORDER.totalPrice gets updated with ORDERITEM.paidprice
CREATE OR ALTER TRIGGER orderitem_after_trigger
ON dbo.ORDERITEM
AFTER INSERT, DELETE, UPDATE 
AS
	DECLARE @pdprice DECIMAL(10,2);
	DECLARE @prdID int;
	DECLARE @cstprice DECIMAL(10,2);
	DECLARE @ordID int;
	DECLARE @ordquan int;
	SELECT @prdID = Product_id FROM inserted;
	SELECT @cstprice = Cost_price FROM dbo.PRODUCT WHERE Product_id = @prdID;
	SELECT @ordID = Order_id FROM inserted;
	SELECT @ordquan = Quantity FROM inserted;
	SET @pdprice = dbo.getPaidPrice(@prdID);

		IF EXISTS (SELECT * FROM deleted)
				BEGIN
					--adding back the quantity of the removed order to the product quantity  
					SELECT @ordquan = Quantity FROM deleted
					SELECT @prdID = Product_id FROM deleted
					SELECT @pdprice = Paid_price FROM deleted
					SELECT @ordID = Order_id FROM deleted

					IF EXISTS (SELECT * FROM inserted) --it was updated
						BEGIN
							DECLARE @newquan int;
							SELECT @newquan = Quantity FROM inserted --new value
							DECLARE @diff int = @newquan - @ordquan

							--update the quantity of the product if it's updated
							UPDATE dbo.PRODUCT
							SET Quantity -= @diff
							WHERE Product_id = @prdID;

							UPDATE dbo.[ORDER]
							SET Total_amount += (@pdprice * @diff)
							WHERE Order_id = @ordID;
						END
					ELSE -- deleted
						BEGIN
							UPDATE dbo.[ORDER]
							SET Total_amount -= (@pdprice * @ordquan)
							WHERE Order_id = @ordID;

							UPDATE dbo.PRODUCT
							SET Quantity += @ordquan
							WHERE Product_id = @prdID
						END
				END;
			ELSE --inserted
				BEGIN
					IF @pdprice > @cstprice
						BEGIN
							--if the paid price is higher, update the total amount paid in the ORDER table
							UPDATE dbo.[ORDER]
							SET Total_amount += (@pdprice * @ordquan)
							WHERE Order_id = @ordID;
							--update the quantity of the product as well
							UPDATE dbo.PRODUCT
							SET Quantity -= @ordquan
							WHERE Product_id = @prdID

							--insert the calculated paid price into the table
							UPDATE dbo.ORDERITEM
							SET Paid_price = @pdprice
							WHERE Order_id = @ordID AND Product_id = @prdID;
						END;
					ELSE
						ROLLBACK 
				END;
			
GO


--AFTER TRIGGER on ORDER table
--ensures that the credit card starts being charged when order status is changed to 'shipped'
--ensures that order_id cannot be modified
CREATE OR ALTER TRIGGER order_after_trigger
ON dbo.[ORDER]
AFTER UPDATE
AS
	IF UPDATE([Status])
		BEGIN
			DECLARE @stus varchar(255);
			DECLARE @credID int;
			DECLARE @credNum varchar(19);
			DECLARE @ordID int;
			DECLARE @total DECIMAL(10,2);
			SELECT @stus = [Status] FROM inserted;
			SELECT @credID = Credit_card_id FROM inserted;
			SELECT @credNum = Credit_card_number FROM dbo.CREDITCARD WHERE Credit_card_id = @credID;
			SELECT @ordID = Order_id FROM inserted;
			SELECT @total = Total_amount FROM inserted;
			
			IF @stus = 'shipped'
				BEGIN
					PRINT 'Credit Card ending with ' + SUBSTRING(@credNum,16,4) + ' is charged $' + CAST(@total as varchar) + ' for the order with order id '+ CAST(@ordID as varchar)
				END
		END
GO

--Create AFTER INSERT trigger that will update the dbo.Clearance 
--table everytime there is a new customer inserted
CREATE OR ALTER TRIGGER clearance_after_trigger
ON dbo.CUSTOMER
AFTER INSERT
AS
	INSERT INTO dbo.Clearance
	SELECT UserID, FirstName as UserName
	FROM inserted
GO


--Creating the security policy 
CREATE SECURITY POLICY dbo.db_security_pol
ADD FILTER PREDICATE dbo.customer_filter_pred(UserID) on dbo.CUSTOMER,
ADD FILTER PREDICATE dbo.customer_filter_pred(Owner_id) on dbo.CREDITCARD,
ADD BLOCK PREDICATE dbo.orderitem_block_pred(Order_id) on dbo.ORDERITEM BEFORE DELETE,
ADD BLOCK PREDICATE dbo.orderitem_block_pred(Order_id) on dbo.ORDERITEM BEFORE UPDATE,
ADD BLOCK PREDICATE dbo.orderitem_block_pred(Order_id) on dbo.ORDERITEM AFTER INSERT

/*
ALTER SECURITY POLICY dbo.db_security_pol WITH (state=off)
DROP SECURITY POLICY dbo.db_security_pol
DROP FUNCTION customer_filter_pred
DROP FUNCTION orderitem_block_pred
DROP TRIGGER credit_trigger 
DROP TRIGGER orderitem_after_trigger
DROP TRIGGER product_after_trigger
DROP TRIGGER clearance_after_trigger
DROP TRIGGER order_after_trigger
DROP TRIGGER orderitem_after_delete_trigger
*/