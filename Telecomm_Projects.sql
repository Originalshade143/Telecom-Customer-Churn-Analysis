CREATE DATABASE TelecomChurnDB;
USE TelecomChurnDB;
GO

/*CREATE TABLE StagingTelco (
    customerID VARCHAR(20),
    gender VARCHAR(10),
    SeniorCitizen INT,
    Partner VARCHAR(5),
    Dependents VARCHAR(5),
    tenure INT,
    PhoneService VARCHAR(5),
    MultipleLines VARCHAR(20),
    InternetService VARCHAR(20),
    OnlineSecurity VARCHAR(20),
    OnlineBackup VARCHAR(20),
    DeviceProtection VARCHAR(20),
    TechSupport VARCHAR(20),
    StreamingTV VARCHAR(20),
    StreamingMovies VARCHAR(20),
    Contract VARCHAR(20),
    PaperlessBilling VARCHAR(5),
    PaymentMethod VARCHAR(30),
    MonthlyCharges DECIMAL(8,2),
    TotalCharges VARCHAR(20),
    Churn VARCHAR(5)
);
SELECT * FROM StagingTelco */

----------------------------Normlization process------------------------

SELECT * FROM Telco_Customer_Churn

--checking columns name and their data type

SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'Telco_Customer_Churn';

--checking churn customer

SELECT Churn, COUNT(*) as TotalRows
FROM Telco_Customer_Churn
GROUP BY Churn;

--checking column name and data type for specific column which has data type "bit"
SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'Telco_Customer_Churn' 
AND DATA_TYPE = 'bit';

--1st table,Starting normlization process with regards creating customer table

CREATE TABLE Customers(
				customerID nvarchar(20) PRIMARY KEY,
				gender varchar(20),
				SeniorCitizen bit,
				Dependents bit,
				Partner bit
				)
SELECT * FROM Customers

--DROP TABLE Customers 

--Checking stages in onlinesecurity column

SELECT DISTINCT onlinesecurity 
FROM Telco_Customer_Churn

----ceating services table table 

CREATE TABLE services(

			customerID nvarchar(20) FOREIGN KEY REFERENCES Customers(customerID),
			PhoneService bit,
			MultipleLines varchar(20),
			InternetService nvarchar(20),
			OnlineSecurity varchar(20),
			OnlineBackup varchar(20),
			DeviceProtection varchar(20),
			TechSupport varchar(20),
			StreamingTV varchar(20),
			StreamingMovies varchar(20)
			)
SELECT * FROM services
DROP TABLE services

--Creating Billing Table

CREATE TABLE Billing(
			customerID nvarchar(20) FOREIGN KEY REFERENCES Customers(customerID),
			tenure tinyint,
			Contract nvarchar(20),
			PaperlessBilling varchar(20),
			PaymentMethod nvarchar(20),
			MonthlyCharges float,
			TotalCharges float
			)

--Creating Churn Table
CREATE TABLE ChurnStatus(
			customerID nvarchar(20) FOREIGN KEY REFERENCES Customers(customerID),
			Churn bit
			
			)

--Inserting data from staging table to respective normlized tables
------------------------Customers Table Data Inserted--------------------------

INSERT INTO Customers (customerID, gender,SeniorCitizen,Dependents,Partner)

SELECT customerID, gender,SeniorCitizen,Dependents,Partner 
FROM Telco_Customer_Churn

--SELECT DB_NAME();

/*SELECT TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE';

EXEC sp_MSforeachdb 'USE [?]; SELECT DB_NAME() AS FoundInDB, TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME LIKE ''%Customer%''';*/

------------------------Services Table Data Inserted--------------------------
INSERT INTO services (
			customerID,
			PhoneService,
			MultipleLines,
			InternetService,
			OnlineSecurity,
			OnlineBackup,
			DeviceProtection,
			TechSupport,
			StreamingTV,
			StreamingMovies)

SELECT		customerID,
			PhoneService,
			MultipleLines,
			InternetService,
			OnlineSecurity,
			OnlineBackup,
			DeviceProtection,
			TechSupport,
			StreamingTV,
			StreamingMovies
FROM Telco_Customer_Churn

------------------------Billing Table Data Inserted--------------------------

INSERT INTO Billing(
			customerID,
			tenure,
			Contract,
			PaperlessBilling,
			PaymentMethod,
			MonthlyCharges,
			TotalCharges
			)

SELECT	
			customerID,
			tenure,
			Contract,
			PaperlessBilling,
			PaymentMethod,
			MonthlyCharges,
			TotalCharges
FROM Telco_Customer_Churn

--SELECT COUNT(*) FROM Billing;

SELECT MAX(LEN(PaymentMethod)) AS MaxPaymentMethodLength,
	   MAX(LEN(PaymentMethod)) AS MaxContractLength
FROM Telco_Customer_Churn

ALTER TABLE Billing
ALTER COLUMN PaymentMethod nvarchar(50);

------------------------Churn Status Table Data Inserted--------------------------

INSERT INTO ChurnStatus(
						customerID,
						Churn
						)
SELECT 	customerID,Churn	
FROM Telco_Customer_Churn


SELECT 'Customers' AS TableName, COUNT(*) AS Row_Count FROM Customers
UNION ALL
SELECT 'Services', COUNT(*) FROM Services
UNION ALL
SELECT 'Billing', COUNT(*) FROM Billing
UNION ALL
SELECT 'ChurnStatus', COUNT(*) FROM ChurnStatus
UNION ALL
SELECT 'Telco_Customer_Churn (Staging)', COUNT(*) FROM Telco_Customer_Churn;

------------Churn status calculation-------------------
SELECT * FROM ChurnStatus

SELECT SUM(CAST(Churn AS INT)) AS Total_Churn,
COUNT(*) AS Total_Customer,
ROUND((CAST(SUM(CAST(Churn AS INT)) AS FLOAT)/COUNT(*))*100,2) AS Churn_Percentage
FROM ChurnStatus
			
--------------------Revenue at Risk--Join the between churn and billing table (Revenue at Risk = SUM(MonthlyCharges)-------------

SELECT * FROM ChurnStatus
SELECT * FROM Billing

SELECT ROUND(SUM(MonthlyCharges),2) AS Revenue_at_risk FROM Billing B
JOIN 
ChurnStatus C ON C.customerID=B.customerID
WHERE C.Churn=1


---------this query helps to see how many tables are there in a database with tables name-----
/*SELECT 
    COUNT(*) OVER() AS total_tables,
    name AS table_name
FROM sys.tables;


----this query helps to see how many tables are there in a database-----
SELECT name
FROM sys.tables;

SELECT * FROM Billing
SELECT * FROM ChurnStatus*/
-----------------------Churn Percentage calulation------------------------------------
SELECT COUNT(*) AS Total_Customer,B.Contract, SUM(CAST(Churn AS INT)) AS Churn_Status,
ROUND((CAST(SUM(CAST(Churn AS INT)) AS FLOAT)/COUNT(*))*100,2) AS Churn_Rate_Perctg
FROM ChurnStatus C
JOIN
Billing B ON C.customerID=b.customerID
GROUP BY B.Contract

----ARPU Calculation------------
SELECT contract,ROUND(AVG(MonthlyCharges),2) AS Avg_revenue_per_user FROM Billing
GROUP BY contract

--------------------Top 5 highest-paying customers in each type of contract-------------------

SELECT * FROM Billing
SELECT * FROM ChurnStatus

SELECT Contract,MonthlyCharges,
		ROUND(RANK() OVER(PARTITION BY Contract ORDER BY  MonthlyCharges DESC),2) AS Rank_Number
		FROM Billing

--------------------Filtering Top 5 customer with CTE----------------
WITH Top5_Pct AS(
					SELECT Contract,MonthlyCharges,CustomerID,
		ROW_NUMBER() OVER(PARTITION BY Contract ORDER BY  MonthlyCharges DESC,CustomerID) AS Rank_Number
		FROM Billing
		)
SELECT * FROM Top5_Pct WHERE Rank_Number <=5;

--------------------Store procedure to make the tables empty--------------------
USE TelecomChurnDB;
GO
CREATE OR ALTER PROCEDURE usp_Load_TelecomChurn
AS
BEGIN
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRY
	BEGIN TRANSACTION;

-- Clean phase: child tables pehle, parent baad mein
DELETE FROM services
DELETE FROM Billing
DELETE FROM Churnstatus
DELETE FROM customers

-- Load phase: parent pehle, child tables baad mein

INSERT INTO Customers (customerID, gender,SeniorCitizen,Dependents,Partner)

SELECT customerID, gender,SeniorCitizen,Dependents,Partner 
FROM Telco_Customer_Churn
INSERT INTO services (customerID,PhoneService,MultipleLines,InternetService,OnlineSecurity,OnlineBackup,DeviceProtection,TechSupport,
StreamingTV,StreamingMovies)

SELECT		customerID,PhoneService,MultipleLines,InternetService,OnlineSecurity,OnlineBackup,DeviceProtection,
TechSupport,StreamingTV,StreamingMovies

FROM Telco_Customer_Churn

INSERT INTO Billing(customerID,tenure,Contract,PaperlessBilling,PaymentMethod,MonthlyCharges,TotalCharges)

SELECT	customerID,tenure,Contract,PaperlessBilling,PaymentMethod,MonthlyCharges,TotalCharges
FROM Telco_Customer_Churn

INSERT INTO ChurnStatus(customerID,Churn)
SELECT 	customerID,Churn	
FROM Telco_Customer_Churn

--SELECT 1/0;
COMMIT TRANSACTION
END TRY 
BEGIN CATCH
	IF @@TRANCOUNT>0
		ROLLBACK TRANSACTION;
		THROW;
END CATCH
END
GO

SELECT COUNT(*) FROM Telco_Customer_Churn;
EXEC usp_Load_TelecomChurn

SELECT 'Customers' AS TableName, COUNT(*) AS Row_Count FROM Customers
UNION ALL
SELECT 'Services', COUNT(*) FROM Services
UNION ALL
SELECT 'Billing', COUNT(*) FROM Billing
UNION ALL
SELECT 'ChurnStatus', COUNT(*) FROM ChurnStatus
UNION ALL
SELECT 'Telco_Customer_Churn (Staging)', COUNT(*) FROM Telco_Customer_Churn;
