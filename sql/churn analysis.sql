CREATE DATABASE churn_retention_analytics;
SHOW DATABASES;

USE churn_retention_analytics;
CREATE TABLE customers (
    Customer_ID INT PRIMARY KEY,
    First_Purchase_Date DATETIME NOT NULL,
    Last_Purchase_Date DATETIME NOT NULL,
    Total_Orders INT NOT NULL,
    Total_Items INT NOT NULL,
    Total_Revenue DECIMAL(15,2) NOT NULL,
    Average_Order_Value DECIMAL(15,2) NOT NULL,
    Purchase_Frequency DECIMAL(10,4) NOT NULL,
    Recency_Days INT NOT NULL,
    Recency_Band VARCHAR(30) NOT NULL,
    Churn_Flag TINYINT NOT NULL,
    Churn_Status VARCHAR(20) NOT NULL,
    Customer_Lifetime_Days INT NOT NULL,
    Customer_Type VARCHAR(20) NOT NULL,
    Frequency_Segment VARCHAR(20) NOT NULL,
    Country VARCHAR(50) NOT NULL,
    Revenue_Segment VARCHAR(30) NOT NULL
);
DESCRIBE customers;

CREATE TABLE purchases (
    Purchase_ID BIGINT AUTO_INCREMENT PRIMARY KEY,
    Invoice VARCHAR(20) NOT NULL,
    StockCode VARCHAR(30) NOT NULL,
    Description VARCHAR(255) NOT NULL,
    Quantity INT NOT NULL,
    InvoiceDate DATETIME NOT NULL,
    Price DECIMAL(12,4) NOT NULL,
    Customer_ID INT NOT NULL,
    Country VARCHAR(50) NOT NULL,
    Is_Cancellation TINYINT NOT NULL,
    Is_Negative_Quantity TINYINT NOT NULL,
    Is_Zero_Price TINYINT NOT NULL,
    Is_Negative_Price TINYINT NOT NULL,
    Has_Customer_ID TINYINT NOT NULL,
    Transaction_Type VARCHAR(30) NOT NULL,
    Revenue DECIMAL(15,4) NOT NULL,

    CONSTRAINT fk_purchases_customer
        FOREIGN KEY (Customer_ID)
        REFERENCES customers(Customer_ID)
);
DESCRIBE purchases;

USE churn_retention_analytics;

SELECT COUNT(*) AS Customer_Count
FROM customers;

SHOW VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = 1;

USE churn_retention_analytics;

LOAD DATA LOCAL INFILE 'C:/Users/vikas/OneDrive/Desktop/customer-churn-retention-analytics/cleaned_data/customer_purchases_clean.csv'
INTO TABLE purchases
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
    @Invoice,
    @StockCode,
    @Description,
    @Quantity,
    @InvoiceDate,
    @Price,
    @Customer_ID,
    @Country,
    @Is_Cancellation,
    @Is_Negative_Quantity,
    @Is_Zero_Price,
    @Is_Negative_Price,
    @Has_Customer_ID,
    @Transaction_Type,
    @Revenue
)
SET
    Invoice = @Invoice,
    StockCode = @StockCode,
    Description = @Description,
    Quantity = @Quantity,
    InvoiceDate = @InvoiceDate,
    Price = @Price,
    Customer_ID = @Customer_ID,
    Country = @Country,
    Is_Cancellation = IF(@Is_Cancellation = 'True', 1, 0),
    Is_Negative_Quantity = IF(@Is_Negative_Quantity = 'True', 1, 0),
    Is_Zero_Price = IF(@Is_Zero_Price = 'True', 1, 0),
    Is_Negative_Price = IF(@Is_Negative_Price = 'True', 1, 0),
    Has_Customer_ID = IF(@Has_Customer_ID = 'True', 1, 0),
    Transaction_Type = @Transaction_Type,
    Revenue = @Revenue;

SELECT COUNT(*) AS Purchase_Count
FROM purchases;

SELECT
    MIN(Purchase_ID) AS First_ID,
    MAX(Purchase_ID) AS Last_ID,
    COUNT(DISTINCT Customer_ID) AS Unique_Customers,
    COUNT(DISTINCT Invoice) AS Unique_Invoices
FROM purchases;

-- 1. Total records
SELECT COUNT(*) AS Total_Purchases
FROM purchases;

-- 2. Missing customer IDs
SELECT COUNT(*) AS Missing_Customer_ID
FROM purchases
WHERE Customer_ID IS NULL;

-- 3. Negative quantities
SELECT COUNT(*) AS Negative_Quantity
FROM purchases
WHERE Quantity < 0;

-- 4. Non-positive prices
SELECT COUNT(*) AS Non_Positive_Price
FROM purchases
WHERE Price <= 0;

-- 5. Missing descriptions
SELECT COUNT(*) AS Missing_Description
FROM purchases
WHERE Description IS NULL OR TRIM(Description) = '';

-- 6. Revenue check
SELECT
    ROUND(SUM(Revenue), 2) AS Total_Revenue,
    ROUND(AVG(Revenue), 2) AS Average_Line_Revenue
FROM purchases;

-- 7. Transaction types
SELECT
    Transaction_Type,
    COUNT(*) AS Records
FROM purchases
GROUP BY Transaction_Type
ORDER BY Records DESC;

-- 8. Date range
SELECT
    MIN(InvoiceDate) AS First_Date,
    MAX(InvoiceDate) AS Last_Date
FROM purchases;


SELECT
    COUNT(*) AS Total_Rows,
    COUNT(DISTINCT Customer_ID) AS Unique_Customers,
    COUNT(DISTINCT Invoice) AS Unique_Invoices,
    SUM(CASE WHEN Customer_ID IS NULL THEN 1 ELSE 0 END) AS Missing_Customer_ID,
    SUM(CASE WHEN Quantity < 0 THEN 1 ELSE 0 END) AS Negative_Quantity,
    SUM(CASE WHEN Price <= 0 THEN 1 ELSE 0 END) AS Non_Positive_Price,
    SUM(CASE WHEN Description IS NULL OR TRIM(Description) = '' THEN 1 ELSE 0 END) AS Missing_Description,
    ROUND(SUM(Revenue), 2) AS Total_Revenue,
    ROUND(AVG(Revenue), 2) AS Avg_Line_Revenue
FROM purchases;

USE churn_retention_analytics;

CREATE TABLE cancellation_returns (
    Return_ID BIGINT AUTO_INCREMENT PRIMARY KEY,
    Invoice VARCHAR(20) NOT NULL,
    StockCode VARCHAR(30) NOT NULL,
    Description VARCHAR(255) NOT NULL,
    Quantity INT NOT NULL,
    InvoiceDate DATETIME NOT NULL,
    Price DECIMAL(12,4) NOT NULL,
    Customer_ID INT NOT NULL,
    Country VARCHAR(50) NOT NULL,
    Return_Revenue DECIMAL(15,4) NOT NULL,
    CONSTRAINT fk_returns_customer
        FOREIGN KEY (Customer_ID)
        REFERENCES customers(Customer_ID)
);

USE churn_retention_analytics;

LOAD DATA LOCAL INFILE 'C:/Users/vikas/OneDrive/Desktop/customer-churn-retention-analytics/cleaned_data/cancellation_returns_clean.csv'
INTO TABLE cancellation_returns_staging
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
    Invoice,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    Price,
    Customer_ID,
    Country,
    Return_Revenue
);

SELECT COUNT(*) AS Staging_Rows
FROM cancellation_returns_staging;

USE churn_retention_analytics;

SELECT
    COUNT(*) AS Return_Records,
    COUNT(DISTINCT Customer_ID) AS Customers_With_Returns,
    COUNT(DISTINCT Invoice) AS Cancellation_Invoices,
    ROUND(SUM(Return_Revenue), 2) AS Total_Return_Value
FROM cancellation_returns;

DROP TABLE cancellation_returns_staging;

SHOW TABLES;

USE churn_retention_analytics;

-- =========================================================
-- 1. OVERALL CHURN
-- =========================================================

SELECT
    COUNT(*) AS Total_Customers,
    SUM(Churn_Flag) AS Churned_Customers,
    COUNT(*) - SUM(Churn_Flag) AS Active_Customers,
    ROUND(SUM(Churn_Flag) * 100.0 / COUNT(*), 2) AS Churn_Rate_Percent
FROM customers;


-- =========================================================
-- 2. ACTIVE VS CHURNED CUSTOMERS
-- =========================================================

SELECT
    Churn_Status,
    COUNT(*) AS Customers,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customers), 2) AS Customer_Percentage,
    ROUND(AVG(Total_Revenue), 2) AS Avg_Revenue,
    ROUND(AVG(Total_Orders), 2) AS Avg_Orders,
    ROUND(AVG(Average_Order_Value), 2) AS Avg_Order_Value,
    ROUND(AVG(Recency_Days), 2) AS Avg_Recency_Days
FROM customers
GROUP BY Churn_Status
ORDER BY Customers DESC;


-- =========================================================
-- 3. CHURN BY CUSTOMER TYPE
-- =========================================================

SELECT
    Customer_Type,
    COUNT(*) AS Total_Customers,
    SUM(Churn_Flag) AS Churned_Customers,
    ROUND(SUM(Churn_Flag) * 100.0 / COUNT(*), 2) AS Churn_Rate_Percent,
    ROUND(AVG(Total_Revenue), 2) AS Avg_Revenue,
    ROUND(AVG(Total_Orders), 2) AS Avg_Orders
FROM customers
GROUP BY Customer_Type
ORDER BY Churn_Rate_Percent DESC;


-- =========================================================
-- 4. CHURN BY FREQUENCY SEGMENT
-- =========================================================

SELECT
    Frequency_Segment,
    COUNT(*) AS Total_Customers,
    SUM(Churn_Flag) AS Churned_Customers,
    ROUND(SUM(Churn_Flag) * 100.0 / COUNT(*), 2) AS Churn_Rate_Percent,
    ROUND(AVG(Total_Revenue), 2) AS Avg_Revenue,
    ROUND(AVG(Recency_Days), 2) AS Avg_Recency_Days
FROM customers
GROUP BY Frequency_Segment
ORDER BY
    CASE Frequency_Segment
        WHEN '1 Order' THEN 1
        WHEN '2 Orders' THEN 2
        WHEN '3-4' THEN 3
        WHEN '5-7' THEN 4
        WHEN '8-12' THEN 5
        WHEN '13+' THEN 6
    END;


-- =========================================================
-- 5. CHURN BY REVENUE SEGMENT
-- =========================================================

SELECT
    Revenue_Segment,
    COUNT(*) AS Total_Customers,
    SUM(Churn_Flag) AS Churned_Customers,
    ROUND(SUM(Churn_Flag) * 100.0 / COUNT(*), 2) AS Churn_Rate_Percent,
    ROUND(AVG(Total_Revenue), 2) AS Avg_Revenue
FROM customers
GROUP BY Revenue_Segment
ORDER BY
    CASE Revenue_Segment
        WHEN '£0-£500' THEN 1
        WHEN '£501-£1,000' THEN 2
        WHEN '£1,001-£5,000' THEN 3
        WHEN '£5,001-£10,000' THEN 4
        WHEN '£10,000+' THEN 5
    END;


-- =========================================================
-- 6. CUSTOMER REVENUE AT RISK
-- =========================================================

SELECT
    ROUND(SUM(CASE WHEN Churn_Flag = 1 THEN Total_Revenue ELSE 0 END), 2)
        AS Churned_Customer_Revenue,
    ROUND(SUM(Total_Revenue), 2)
        AS Total_Customer_Revenue,
    ROUND(
        SUM(CASE WHEN Churn_Flag = 1 THEN Total_Revenue ELSE 0 END)
        * 100.0 / SUM(Total_Revenue),
        2
    ) AS Revenue_At_Risk_Percent
FROM customers;


-- =========================================================
-- 7. TOP 20 HIGH-VALUE CHURNED CUSTOMERS
-- =========================================================

SELECT
    Customer_ID,
    Country,
    Total_Orders,
    Total_Items,
    ROUND(Total_Revenue, 2) AS Total_Revenue,
    ROUND(Average_Order_Value, 2) AS Average_Order_Value,
    Recency_Days,
    Customer_Type,
    Frequency_Segment
FROM customers
WHERE Churn_Flag = 1
ORDER BY Total_Revenue DESC
LIMIT 20;

SELECT
    COUNT(*) AS Total_Customers,
    SUM(Churn_Flag) AS Churned_Customers,
    COUNT(*) - SUM(Churn_Flag) AS Active_Customers,
    ROUND(SUM(Churn_Flag) * 100.0 / COUNT(*), 2) AS Churn_Rate_Percent
FROM customers;

SELECT
    Customer_Type,
    COUNT(*) AS Total_Customers,
    SUM(Churn_Flag) AS Churned_Customers,
    ROUND(SUM(Churn_Flag) * 100.0 / COUNT(*), 2) AS Churn_Rate_Percent,
    ROUND(AVG(Total_Revenue), 2) AS Avg_Revenue,
    ROUND(AVG(Total_Orders), 2) AS Avg_Orders
FROM customers
GROUP BY Customer_Type
ORDER BY Churn_Rate_Percent DESC;

SELECT
    Frequency_Segment,
    COUNT(*) AS Total_Customers,
    SUM(Churn_Flag) AS Churned_Customers,
    ROUND(SUM(Churn_Flag) * 100.0 / COUNT(*), 2) AS Churn_Rate_Percent,
    ROUND(AVG(Total_Revenue), 2) AS Avg_Revenue,
    ROUND(AVG(Recency_Days), 2) AS Avg_Recency_Days
FROM customers
GROUP BY Frequency_Segment
ORDER BY
    CASE Frequency_Segment
        WHEN '1 Order' THEN 1
        WHEN '2 Orders' THEN 2
        WHEN '3-4 Orders' THEN 3
        WHEN '5-7 Orders' THEN 4
        WHEN '8-12 Orders' THEN 5
        WHEN '13+ Orders' THEN 6
    END;
    
    SELECT
    ROUND(SUM(CASE
        WHEN Churn_Flag = 1 THEN Total_Revenue
        ELSE 0
    END), 2) AS Churned_Customer_Revenue,

    ROUND(SUM(Total_Revenue), 2) AS Total_Customer_Revenue,

    ROUND(
        SUM(CASE
            WHEN Churn_Flag = 1 THEN Total_Revenue
            ELSE 0
        END) * 100.0 / SUM(Total_Revenue),
        2
    ) AS Revenue_At_Risk_Percent
FROM customers;
-- Business Question 7:
-- How many new customers are acquired each month?
SELECT
    DATE_FORMAT(InvoiceDate, '%Y-%m') AS Month,
    COUNT(DISTINCT Customer_ID) AS Active_Customers,
    COUNT(DISTINCT Invoice) AS Orders,
    ROUND(SUM(Revenue), 2) AS Revenue
FROM purchases
GROUP BY DATE_FORMAT(InvoiceDate, '%Y-%m')
ORDER BY Month;
-- Business Question 7:
-- How many new customers are acquired each month?
SELECT
    DATE_FORMAT(First_Purchase_Date, '%Y-%m') AS Month,
    COUNT(*) AS New_Customers
FROM customers
GROUP BY DATE_FORMAT(First_Purchase_Date, '%Y-%m')
ORDER BY Month;
-- Business Question 8:
-- How many customers become churned each month?
SELECT
    DATE_FORMAT(Last_Purchase_Date, '%Y-%m') AS Month,
    COUNT(*) AS Churned_Customers
FROM customers
WHERE Churn_Flag = 1
GROUP BY DATE_FORMAT(Last_Purchase_Date, '%Y-%m')
ORDER BY Month;

-- Business Question 9:
-- Which countries have the highest customer churn rates?

SELECT
    Country,
    COUNT(*) AS Total_Customers,
    SUM(Churn_Flag) AS Churned_Customers,
    ROUND(
        SUM(Churn_Flag) * 100.0 / COUNT(*),
        2
    ) AS Churn_Rate_Percent
FROM customers
GROUP BY Country
HAVING COUNT(*) >= 20
ORDER BY Churn_Rate_Percent DESC;

-- Which customer revenue segments have the highest churn rates?
SELECT
    Revenue_Segment,
    COUNT(*) AS Total_Customers,
    SUM(Churn_Flag) AS Churned_Customers,
    ROUND(
        SUM(Churn_Flag) * 100.0 / COUNT(*),
        2
    ) AS Churn_Rate_Percent,
    ROUND(AVG(Total_Revenue), 2) AS Avg_Revenue
FROM customers
GROUP BY Revenue_Segment
ORDER BY Churn_Rate_Percent DESC;

-- Business Question 11:
-- Which high-value customers have already churned?

SELECT
    Customer_ID,
    Country,
    Total_Orders,
    Total_Items,
    ROUND(Total_Revenue, 2) AS Total_Revenue,
    ROUND(Average_Order_Value, 2) AS Average_Order_Value,
    Recency_Days,
    Customer_Type,
    Frequency_Segment
FROM customers
WHERE Churn_Flag = 1
ORDER BY Total_Revenue DESC
LIMIT 20;

-- Business Question 12:
-- Which countries have the highest revenue at risk from churned customers?

SELECT
    Country,
    COUNT(*) AS Total_Customers,
    SUM(Churn_Flag) AS Churned_Customers,
    ROUND(SUM(Total_Revenue), 2) AS Total_Revenue,
    ROUND(
        SUM(
            CASE
                WHEN Churn_Flag = 1 THEN Total_Revenue
                ELSE 0
            END
        ),
        2
    ) AS Churned_Customer_Revenue,
    ROUND(
        SUM(
            CASE
                WHEN Churn_Flag = 1 THEN Total_Revenue
                ELSE 0
            END
        ) * 100.0 / SUM(Total_Revenue),
        2
    ) AS Revenue_At_Risk_Percent
FROM customers
GROUP BY Country
HAVING COUNT(*) >= 20
ORDER BY Churned_Customer_Revenue DESC;

-- Business Question 13:
-- How does customer purchase frequency affect customer revenue?

SELECT
    Frequency_Segment,
    COUNT(*) AS Total_Customers,
    ROUND(SUM(Total_Revenue), 2) AS Total_Revenue,
    ROUND(AVG(Total_Revenue), 2) AS Avg_Customer_Revenue,
    ROUND(AVG(Total_Orders), 2) AS Avg_Orders,
    ROUND(
        SUM(Total_Revenue) * 100.0 /
        (SELECT SUM(Total_Revenue) FROM customers),
        2
    ) AS Revenue_Share_Percent
FROM customers
GROUP BY Frequency_Segment
ORDER BY Avg_Orders;

-- Business Question 14:
-- Which products generate the highest return or cancellation value?

SELECT
    StockCode,
    Description,
    COUNT(*) AS Return_Records,
    SUM(ABS(Quantity)) AS Returned_Quantity,
    ROUND(ABS(SUM(Return_Revenue)), 2) AS Return_Value
FROM cancellation_returns
GROUP BY StockCode, Description
ORDER BY Return_Value DESC
LIMIT 20;

-- Business Question 15:
-- Which customers have the highest return or cancellation value?

SELECT
    Customer_ID,
    COUNT(*) AS Return_Records,
    SUM(ABS(Quantity)) AS Returned_Items,
    ROUND(ABS(SUM(Return_Revenue)), 2) AS Return_Value
FROM cancellation_returns
GROUP BY Customer_ID
ORDER BY Return_Value DESC
LIMIT 20;

-- Business Question 16:
-- What is the financial impact of cancellations and returns on gross revenue?

SELECT
    ROUND(
        (SELECT SUM(Revenue) FROM purchases),
        2
    ) AS Gross_Purchase_Revenue,

    ROUND(
        ABS(SUM(Return_Revenue)),
        2
    ) AS Return_Value,

    ROUND(
        (SELECT SUM(Revenue) FROM purchases)
        - ABS(SUM(Return_Revenue)),
        2
    ) AS Net_Revenue,

    ROUND(
        ABS(SUM(Return_Revenue)) * 100.0 /
        (SELECT SUM(Revenue) FROM purchases),
        2
    ) AS Return_Impact_Percent

FROM cancellation_returns;