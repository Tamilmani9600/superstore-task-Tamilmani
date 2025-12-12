create database tamil;
use tamil;

CREATE TABLE superstore_cleaned (
    Row_ID INT,
    Order_ID VARCHAR(50),
    Order_Date DATE,
    Ship_Date DATE,
    Ship_Mode VARCHAR(50),
    Customer_ID VARCHAR(50),
    Customer_Name VARCHAR(100),
    Segment VARCHAR(50),
    Country VARCHAR(50),
    City VARCHAR(100),
    State VARCHAR(100),
    Postal_Code VARCHAR(20),
    Region VARCHAR(50),
    Product_ID VARCHAR(50),
    Category VARCHAR(50),
    Sub_Category VARCHAR(50),
    Product_Name VARCHAR(255),
    Sales DECIMAL(10,2),
    Quantity INT,
    Discount DECIMAL(10,2),
    Profit DECIMAL(10,2)
);


LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\cleaned_superstore.csv'
INTO TABLE superstore_cleaned
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Total sales, profit, quantity
SELECT 
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    SUM(Quantity) AS Total_Quantity
FROM superstore_cleaned;

-- Monthly sales trend
SELECT 
    DATE_FORMAT(Order_Date, '%Y-%m') AS Month,
    SUM(Sales) AS Monthly_Sales
FROM superstore_cleaned
GROUP BY DATE_FORMAT(Order_Date, '%Y-%m')
ORDER BY Month;

-- YoY sales comparison
SELECT
    YEAR(Order_Date) AS Year,
    SUM(Sales) AS Total_Sales
FROM superstore_cleaned
GROUP BY YEAR(Order_Date)
ORDER BY Year;

-- Top 10 products by sales
SELECT 
    Product_Name,
    SUM(Sales) AS Total_Sales
FROM superstore_cleaned
GROUP BY Product_Name
ORDER BY Total_Sales DESC
LIMIT 10;

-- Top 10 customers by revenue
SELECT 
    Customer_Name,
    SUM(Sales) AS Total_Revenue
FROM superstore_cleaned
GROUP BY Customer_Name
ORDER BY Total_Revenue DESC
LIMIT 10;

-- Category-wise profit margin
SELECT 
    Category,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    (SUM(Profit) / SUM(Sales)) * 100 AS Profit_Margin_Percent
FROM superstore_cleaned
GROUP BY Category;

-- Region performance (sales + profit)
SELECT 
    Region,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit
FROM superstore_cleaned
GROUP BY Region
ORDER BY Total_Sales DESC;

-- Discount impact on profitability
SELECT 
    Discount,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit,
    AVG(Profit) AS Avg_Profit
FROM superstore_cleaned
GROUP BY Discount
ORDER BY Discount;

-- Profit loss analysis (items with negative profit)
SELECT 
    Order_ID,
    Product_Name,
    Sales,
    Profit
FROM superstore_cleaned
WHERE Profit < 0
ORDER BY Profit ASC;

-- Segment contribution %
SELECT 
    Segment,
    SUM(Sales) AS Segment_Sales,
    ROUND((SUM(Sales) / (SELECT SUM(Sales) FROM superstore_cleaned)) * 100, 2) AS Contribution_Percent
FROM superstore_cleaned
GROUP BY Segment;

-- Shipping time calculation (Ship Date – Order Date)
SELECT 
    Order_ID,
    DATEDIFF(Ship_Date, Order_Date) AS Shipping_Days
FROM superstore_cleaned;

-- Identify outlier orders (High sales or high loss)
-- Define high-sale outliers: > 90th percentile sales
-- Or high-loss: Profit < -200 (adjust if needed)
WITH sorted_sales AS (
    SELECT 
        Sales,
        ROW_NUMBER() OVER (ORDER BY Sales) AS rn,
        COUNT(*) OVER () AS total_rows
    FROM superstore_cleaned
),
threshold AS (
    SELECT Sales AS p90_sales
    FROM sorted_sales
    WHERE rn = FLOOR(total_rows * 0.90)
)
SELECT 
    s.Order_ID,
    s.Product_Name,
    s.Sales,
    s.Profit
FROM superstore_cleaned s
CROSS JOIN threshold t
WHERE s.Sales > t.p90_sales
   OR s.Profit < -200
ORDER BY s.Sales DESC, s.Profit ASC;


