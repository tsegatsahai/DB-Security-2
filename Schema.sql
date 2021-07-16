SELECT * FROM sys.tables

--Create CUSTOMER table
CREATE TABLE dbo.CUSTOMER
(
	UserID int PRIMARY KEY,
	Email varchar(255),
	[Password] varchar(255) NOT NULL,
	Firstname varchar(255) NOT NULL,
	Lastname varchar(255) NOT NULL,
	[Address] varchar(255),
	Phone varchar(15)
);


--Create CREDITCARD TABLE
CREATE TABLE dbo.CREDITCARD
(
	Credit_card_id int PRIMARY KEY,
	Credit_card_number char(19) MASKED WITH (FUNCTION = 'partial(0,"xxxx-xxxx-xxxx-",4)'),
	Holder_name varchar(255) NOT NULL,
	Expire_date DATE NOT NULL, --YYYY/MM/DD
	CVC_code char(3) NOT NULL,
	Billing_address varchar(255) NOT NULL,
	Owner_id int NOT NULL REFERENCES dbo.CUSTOMER(UserID),
	UNIQUE(Owner_id, Credit_card_id)
);

--CREATE PRODUCT TABLE
CREATE TABLE dbo.PRODUCT
(
	Product_id int PRIMARY KEY,
	[Name] varchar(255),
	Quantity int CHECK (Quantity >= 0),
	[Description] varchar(255),
	Cost_price DECIMAL(10, 2) MASKED WITH (FUNCTION = 'default()'),
	Sales_price DECIMAL(10,2),
	Discount DECIMAL(2,2)
);

--CREATE ORDER TABLE
CREATE TABLE dbo.[ORDER]
(
	Order_id int PRIMARY KEY,
	UserID int,
	Order_date DATE, --YYYY/MM/DD
	Total_amount DECIMAL(10,2),
	Credit_card_id int NOT NULL,
	Shipping_address varchar(255),
	[Status] varchar(255) CHECK (Status in ('placed', 'in preparation', 'ready to ship', 'shipped')),
	FOREIGN KEY(UserID, Credit_card_id) REFERENCES dbo.CREDITCARD(Owner_id,Credit_card_id)
);

--CREATE ORDERITEM TABLE
CREATE TABLE dbo.ORDERITEM
(
	Order_id INT REFERENCES dbo.[ORDER](Order_id),
	Product_id INT REFERENCES dbo.PRODUCT(Product_id),
	Paid_price DECIMAL(10,2),
	Quantity INT CHECK (Quantity >= 0),
	PRIMARY KEY(Order_id, Product_id)
);


select * from dbo.Clearance

--Test data for CUSTOMER
INSERT INTO  dbo.CUSTOMER (UserID, Email, [Password], Firstname, Lastname, [Address], Phone) VALUES
(1, 'alice@alice.com', 'password12', 'Alice', 'Smith', '123 peach street', '123-456-1574'),
(2, 'bob@bob.com', 'bobpassword', 'Bob', 'Michealson', '321 4th street', '999-098-8765'),
(3, 'billy@billy.com', 'billypassword', 'Billy', 'Davidson', '637 yahoo street', '878-986-8383'),
(4, 'charles@charles.com', 'charlespassword', 'Charles', 'Cooper', '983 brown drive', '975-334-9373'),
(5, 'david@david.com', 'davidpassword', 'David', 'Collins', '839 hanover street', '555-787-2637');

--Test data for CREDITCARD
INSERT INTO dbo.CREDITCARD(Credit_card_id, Credit_card_number, Holder_name, Expire_date, CVC_code, Billing_address, Owner_id) VALUES 
(1, '1111-1111-1111-1111', 'Alice Smith', '2021-11-01', '001', '123 peach street', 1),
(2, '2222-2222-2222-2222', 'Alice Smith', '2024-10-01', '234', '123 peach street', 1),
(3, '3333-3333-3333-3333', 'David Collins', '2030-02-01', '455', '839 hanover street', 5),
(4, '1234-5678-9012-3456', 'Bob Michealson', '2022-04-01', '499', '321 4th street', 2),
(5, '0987-8765-7654-6543', 'Charles Cooper', '2029-07-01', '778', '983 brown drive', 4),
(6, '7392-8532-0092-5382', 'Billy Davidson', '2025-08-01', '092','637 yahoo street', 3),
(7, '8930-0180-0554-8893', 'Charles Cooper', '2028-09-01', '493', '983 brown drive', 4);

--Test data for PRODUCT
INSERT INTO dbo.PRODUCT (Product_id, [Name], Quantity, [Description], Cost_price, Sales_price, Discount) VALUES 
(1, 'iPhone', 50, 'Apple iPhone X', 245, 599.99, 0.2),
(2, 'MacBook Air', 75, 'Apple 2018 MacBook Air', 850, 1020, 0.05),
(3, 'MacBook Pro', 50, 'Apple 2020 MacBook Pro', 900, 1149.99, 0.1),
(4, 'Samsung Phone', 110, 'Samsung Galaxy S7 Phone', 750, 999.99, 0.08),
(5, 'Dell Laptop', 200, '2021 Dell Laptop', 1100, 1799, 0.2);

--Test data for ORDER
INSERT INTO dbo.[ORDER] (Order_id, UserID, Order_date, Total_amount, Credit_card_id, Shipping_address,[Status]) VALUES
(1, 2, '2021-03-11', 3400.25, 4, '321 4th street', 'shipped'),
(2, 4, '2021-04-02', 1489.44, 7, '983 brown drive', 'ready to ship'),
(3, 1, '2020-12-30', 899.99, 1, '123 peach street', 'in preparation'),
(4, 1, '2021-02-20', 989.75, 1,'123 peach street', 'placed');

--Test data for ORDERITEM
INSERT INTO dbo.ORDERITEM (Order_id, Product_id, Paid_price, Quantity) VALUES 
(1, 2, 1200, 2),
(1, 3, 1300,1),
(2, 1,675, 2),
(3, 4, 1489.99,1);


GO

--Create a table that holds the usernames and their associated UserIDs 
--This assumes that the username for a user is their first name
SELECT DISTINCT(UserID), Firstname AS UserName
INTO dbo.Clearance
FROM dbo.CUSTOMER



/*
DROP TABLE dbo.CUSTOMER;
DROP TABLE dbo.CREDITCARD;
DROP TABLE dbo.PRODUCT;
DROP TABLE dbo.[ORDER];
DROP TABLE dbo.ORDERITEM;
DROP TABLE dbo.Clearance;

*/