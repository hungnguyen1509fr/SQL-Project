

/*
Executives's question:
1. What is Total Revenue 
2, What is Total Revenue ( Profit after disount)
3, Top 10 Product with highest Revenue
4, Top 5 Category with highest REVENUE
5, TOp 5 category with highest NUMBER OF ORDER
6, Fastest Delivery Time 
7, Slowest Delivery TIME
8, Calculate the fastest, average and slowest delivery time for each order
9. Calculate Average Sold Price of each productid. Get top 10 productid with highest sold price.
10. Analyze the impact of different discount levels on sales performance across product categories, 
specifically looking at the number of orders and total profit generated for each discount classification.
11. Write a query to create a report that displays each employee's performance across different product categories,
12. Create a report that displays the average discount per category for each product, showing not only the average discount on category level but also the number of products in each category.
The results should be ordered by the number of products in descending order for each category showing not only the total profit per category but also what percentage of their total profit each category represents,
with the results ordered by the percentage in descending order for each employee
(Formula to apply: ASP (Average Selling Price) = Total GS productid / Sum of count product sold).
13. Give 5 suppliers who had the highest number of orders in 2022.
14. Create a report to compare revenue for the last 3 months. 
15, create a report to compare revenue for each employee for each year
16. Create a product report that demonstrate each product revenue during the last 13 months.
------ 
Since I receive the list of question by the executives that need to pull data from multiple tables, to optimize query speed and readability, I created
a temporary table with all neccessary information which is #Comprehensive_Data.
*/
;
IF OBJECT_ID ('TEMPDB..[#Comprehensive_Data]','U') IS NOT NULL DROP TABLE [#Comprehensive_Data]

SELECT  
	    [YEAR]							= YEAR(X1.orderdate)
	   ,[ORDER_ID]							= X1.orderid
	   ,[EMPLOYEES_ID]						= X5.EmployeeID
	   ,[FULL_NAME_EMP]						= CONCAT( X5.Firstname, ' ', X5.Lastname)
	   ,[REVENUE]							= SUM(X2.unitprice * X2.qty)
	   ,[PROFIT]                            			= CAST(SUM(X2.unitprice * X2.qty * (1 - X2.discount)) AS INT)
	   ,[CATEGORY_NAME]						= X4.CategoryName
	   ,[PRODUCT_NAME]                     				= X3.PRODUCTNAME
	   ,[SHIPPED_DATE]						= X1.shippeddate
	   ,[ORDER_DATE]						= X1.orderdate
	   ,[SHIPPED_CITY]						= X1.shipcity
	   ,[SHIPPED_COUNTRY]						= X1.shipcountry
INTO    #Comprehensive_Data
FROM Sales.Orders X1 
LEFT JOIN Sales.OrderDetails X2 ON X1.orderid = X2.orderid
LEFT JOIN Production.Products X3 ON X2.productid = X3.PRODUCTID
LEFT JOIN Production.Categories X4 ON X3.CATEGORYID = X4.CategoryID
LEFT JOIN HR.Employees X5 ON X1.empid = X5.EmployeeID
GROUP BY X1.orderid, X5.EmployeeID, CONCAT( X5.Firstname, ' ', X5.Lastname), X1.orderdate, X1.shippeddate, X4.CategoryName, X3.PRODUCTNAME, shipcity,shipcountry;

SELECT * FROM #Comprehensive_Data;
/*1. What is Total Revenue and Total Profit (Revenue after discount)*/

SELECT 
    SUM(REVENUE) AS TOTAL_REVENUE_OVERALL,
    SUM(PROFIT) AS TOTAL_PROFIT_OVERALL
FROM #Comprehensive_Data;
/*We have the Total revenue for 3 years are 1.35 million and the profit after discount is 1.26 million in total.
--2. What is the break-down of Total Revenue and Profit by year and by category?*/

SELECT 
    YEAR,
    SUM(REVENUE) AS TOTAL_REVENUE,
    SUM(PROFIT) AS TOTAL_PROFIT,
    CATEGORY_NAME AS CATEGORY
FROM #Comprehensive_Data
GROUP BY CATEGORY_NAME, YEAR
ORDER BY YEAR, TOTAL_PROFIT DESC;
/*We can see clearly that Beverages and Dairy's products are the top 2 categories that generated the most revenue during the span of 3 years.*/

/*3. TOP 5 EMPLOYEES by revenue*/

SELECT TOP 5
    EMPLOYEES_ID,
    FULL_NAME_EMP,
    SUM(REVENUE) AS TOTAL_REVENUE
FROM #Comprehensive_Data 
GROUP BY EMPLOYEES_ID, FULL_NAME_EMP
ORDER BY TOTAL_REVENUE DESC;
/*  Margaret Peacock    250187.45
    Janet Leverling     213051.30
    Nancy Davolio       202143.71
    Andrew Fuller       177749.26
    Robert King         141295.99
*/

/*4. TOP EMPLOYEES by revenue in each category*/

WITH EMP_REVE AS (
    SELECT 
        EMPLOYEES_ID,
        FULL_NAME_EMP,
        SUM(REVENUE) AS TOTAL_REVENUE,
        CATEGORY_NAME,
        ROW_NUMBER() OVER (PARTITION BY CATEGORY_NAME ORDER BY SUM(REVENUE) DESC) AS RANK
    FROM #Comprehensive_Data
    GROUP BY EMPLOYEES_ID, FULL_NAME_EMP, CATEGORY_NAME
)
SELECT 
    FULL_NAME_EMP,
    EMPLOYEES_ID,
    CATEGORY_NAME,
    TOTAL_REVENUE
FROM EMP_REVE
WHERE RANK <= 3;
/* With this query, we can calculate the top 3 employees ranking by total revenue in each category.*/

/*4. TOP 3 employees by number of orders*/

SELECT TOP 3
    EMPLOYEES_ID,
    FULL_NAME_EMP,
    COUNT(DISTINCT ORDER_ID) AS TOTAL_ORDER
FROM #Comprehensive_Data
GROUP BY EMPLOYEES_ID, FULL_NAME_EMP
ORDER BY TOTAL_ORDER DESC;
/*  Margaret Peacock    156
    Janet Leverling     127
    Nancy Davolio       123
We can have the list of top 3 employees calculated by number of orders, no surprise here as the top 3 employees generating the most revenue also have the highest number of orders.*/

/*5. TOP 3 Employees with number of orders by category*/

WITH EMP_ORDERS AS (
    SELECT 
        EMPLOYEES_ID,
        FULL_NAME_EMP,
        COUNT(DISTINCT ORDER_ID) AS TOTAL_ORDER,
        ROW_NUMBER() OVER (PARTITION BY CATEGORY_NAME ORDER BY COUNT(DISTINCT ORDER_ID) DESC) AS RANK,
        CATEGORY_NAME
    FROM #Comprehensive_Data
    GROUP BY EMPLOYEES_ID, FULL_NAME_EMP, CATEGORY_NAME
)
SELECT 
    EMPLOYEES_ID,
    FULL_NAME_EMP,
    TOTAL_ORDER,
    CATEGORY_NAME
FROM EMP_ORDERS
WHERE RANK <= 3;

/*6. TOP 5 products with highest revenue and their category*/

SELECT TOP 5
    CATEGORY_NAME AS CATEGORY,
    PRODUCT_NAME,
    SUM(REVENUE) AS TOTAL_REVENUE
FROM #Comprehensive_Data 
GROUP BY PRODUCT_NAME, CATEGORY_NAME
ORDER BY TOTAL_REVENUE DESC;

/* 7. TOP 5 products with highest revenue in each category in each country */
WITH PRODUCT_RANK AS (
    SELECT  
        CATEGORY_NAME,
        PRODUCT_NAME,
        SUM(REVENUE) AS TOTAL_REVENUE,
        SHIPPED_COUNTRY,
        ROW_NUMBER() OVER(PARTITION BY CATEGORY_NAME ORDER BY SUM(REVENUE) DESC) AS RANK
    FROM #Comprehensive_Data
    GROUP BY PRODUCT_NAME, CATEGORY_NAME, SHIPPED_COUNTRY
)
SELECT 
    CATEGORY_NAME,
    PRODUCT_NAME,
    TOTAL_REVENUE,
    SHIPPED_COUNTRY
FROM PRODUCT_RANK
WHERE RANK <= 5;

/* 7b. What are the top 5 products in the last 6 months based on revenue */

WITH PRODUCT_RANK AS (
    SELECT  
        ORDER_DATE,
        CATEGORY_NAME,
        PRODUCT_NAME,
        SUM(REVENUE) AS TOTAL_REVENUE,
        ROW_NUMBER() OVER(PARTITION BY CATEGORY_NAME ORDER BY SUM(REVENUE) DESC) AS RANK
    FROM #Comprehensive_Data
    WHERE CONVERT(NVARCHAR(7), ORDER_DATE, 23) >= '2021-11'
    GROUP BY PRODUCT_NAME, CATEGORY_NAME, ORDER_DATE
)
SELECT  
    CONVERT(NVARCHAR(7), ORDER_DATE, 23) AS ORDER_DATE,
    CATEGORY_NAME,
    PRODUCT_NAME,
    TOTAL_REVENUE
FROM PRODUCT_RANK
WHERE RANK <= 5;

/* 8. Calculate the fastest, average, and slowest delivery time for each order */
SELECT 
    MIN(DATEDIFF(DAY, ORDER_DATE, SHIPPED_DATE)) AS MIN_SHIPPING_DURATION,
    AVG(DATEDIFF(DAY, ORDER_DATE, SHIPPED_DATE)) AS AVERAGE_SHIPPING_DURATION,
    MAX(DATEDIFF(DAY, ORDER_DATE, SHIPPED_DATE)) AS MAX_SHIPPING_DURATION
FROM #Comprehensive_Data;
/* We have fastest shipping is 1 day while the average is 8 days and slowest is 37 days. */

SELECT  
    CATEGORY_NAME AS CATEGORY,
    MIN(DATEDIFF(DAY, ORDER_DATE, SHIPPED_DATE)) AS FASTEST_SHIPPING_DURATION,
    AVG(DATEDIFF(DAY, ORDER_DATE, SHIPPED_DATE)) AS AVERAGE_SHIPPING_DURATION,
    MAX(DATEDIFF(DAY, ORDER_DATE, SHIPPED_DATE)) AS SLOWEST_SHIPPING_DURATION
FROM #Comprehensive_Data
GROUP BY CATEGORY_NAME;
/* When we analyze it category-wise, we can see that all categories experienced similar shipping periods.
Only Confections and Grains/Cereals categories have the slowest shipping date, which is 37 days. */

/* What are the top countries and cities by the number of orders? */
SELECT TOP 10
    SHIPPED_CITY,
    SHIPPED_COUNTRY,
    COUNT(DISTINCT ORDER_ID) AS TOTAL_ORDERS,
    ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT ORDER_ID) DESC) AS RANK
FROM #Comprehensive_Data
GROUP BY SHIPPED_CITY, SHIPPED_COUNTRY
ORDER BY RANK;

/* 9. Calculate Average Sold Price of each orderid. Get top 10 orderid with highest sold price. 
(Formula to apply: ASP (Average Selling Price) = Total GS orderid / Sum of count orderid sold) */

SELECT TOP 10
    od.orderid AS ORDER_ID,
    SUM(od.unitprice * od.qty) AS Gross_Sale,
    CAST(SUM(od.unitprice * od.qty * (1 - od.discount)) AS INT) AS Gross_Merchandise_Value,
    SUM(od.unitprice * od.qty) / COUNT(DISTINCT od.orderid) AS Average_Order_Value,
    SUM(od.unitprice * od.qty) / SUM(od.qty) AS Average_Selling_Price
FROM Sales.OrderDetails od
LEFT JOIN Production.Products P ON od.productid = P.PRODUCTID
LEFT JOIN Production.Categories PCA ON P.CATEGORYID = PCA.CategoryID
GROUP BY od.orderid
ORDER BY Gross_Sale DESC;

/* 9. Calculate Average Sold Price of each productid. Get top 10 productid with highest sold price. 
(Formula to apply: ASP (Average Selling Price) = Total GS productid / Sum of count product sold) */

SELECT TOP 10
    P.PRODUCTID AS PRODUCTID,
    P.PRODUCTNAME AS PRODUCTNAME,
    C.CategoryName AS CATEGORY_NAME,
    SUM(O.unitprice * O.qty) AS GS,
    CAST(SUM(O.unitprice * O.qty * (1 - O.discount)) AS INT) AS GMV,
    SUM(O.unitprice * O.qty) / COUNT(DISTINCT O.orderid) AS AOV,
    SUM(O.unitprice * O.qty) / SUM(O.qty) AS ASP
FROM Sales.OrderDetails O
LEFT JOIN Production.Products P ON O.productid = P.PRODUCTID
LEFT JOIN Production.Categories C ON P.CATEGORYID = C.CategoryID
GROUP BY P.ProductID, P.PRODUCTNAME, C.CategoryName
ORDER BY GS DESC;
/* We can see that Cote De Blaye in the Beverage Category performed much higher than the second product in terms of GS and AOV,
which is Thüringer Rostbratwurst in Meat/Poultry. Notably, Cote de Blaye's GS is nearly double that of Thüringer Rostbratwurst while AOV is more than double. */

/* 10. Analyze the impact of different discount levels on sales performance across product categories, 
specifically looking at the number of orders and total profit generated for each discount classification. 
- Discount level condition:
- No Discount = 0
- 0 < Low Discount <= 0.2
- 0.2 < Medium Discount <= 0.5
- High Discount > 0.5 */

DROP TABLE   [Discount.report];
CREATE TABLE [Discount.report] 
( 
    CATEGORY NVARCHAR(100),
    DISCOUNT_LEVEL NVARCHAR(50),
    TOTAL_ORDERS INT,
    TOTAL_PROFIT DECIMAL(18, 2)
);

WITH CTE_Products AS (
    SELECT 
        X3.CategoryName AS CATEGORY,
        CASE 
            WHEN X2.discount = 0 THEN 'No Discount'
            WHEN X2.discount > 0 AND X2.discount <= 0.2 THEN 'Low Discount'
            WHEN X2.discount > 0.2 AND X2.discount <= 0.5 THEN 'Medium Discount'
            WHEN X2.discount > 0.5 THEN 'High Discount'
        END AS DISCOUNT_LEVEL,
        X2.orderid,
        (X2.unitprice * X2.qty * (1 - X2.discount)) AS TOTAL_PROFIT
    FROM Production.Products X1 
    LEFT JOIN Sales.OrderDetails X2 ON X1.PRODUCTID = X2.productid
    LEFT JOIN Production.Categories X3 ON X1.CATEGORYID = X3.CategoryID
)

-- Insert the results into Discount.report
INSERT INTO [Discount.report] (CATEGORY, DISCOUNT_LEVEL, TOTAL_ORDERS, TOTAL_PROFIT)
SELECT 
    CATEGORY, 
    DISCOUNT_LEVEL, 
    COUNT(orderid) AS TOTAL_ORDERS, 
    SUM(TOTAL_PROFIT) AS TOTAL_PROFIT
FROM CTE_Products
GROUP BY CATEGORY, DISCOUNT_LEVEL
ORDER BY CATEGORY;

-- Select from Discount.report
SELECT * FROM [Discount.report]
ORDER BY CATEGORY DESC; 
/* With the above query, we can clearly analyze the discount based on level, total number of orders, and 
total profit across all categories */


/* 11. Write a query to create a report that displays each employee's performance across different product categories,
showing not only the total profit per category but also what percentage of their total profit each category represents,
with the results ordered by the percentage in descending order for each employee */

WITH L1 AS (
    SELECT 
        X2.EmployeeID AS ID,
        SUM(X3.qty * X3.unitprice) AS TOTAL_PROFIT,
        X5.CategoryName AS CATEGORY
    FROM Sales.Orders X1 
    LEFT JOIN HR.Employees X2 ON X1.empid = X2.EmployeeID
    LEFT JOIN Sales.OrderDetails X3 ON X1.orderid = X3.orderid
    LEFT JOIN Production.Products X4 ON X3.productid = X4.PRODUCTID
    LEFT JOIN Production.Categories X5 ON X4.CATEGORYID = X5.CategoryID
    GROUP BY X2.EmployeeID, X5.CategoryName
)
SELECT 
    L1.ID AS EMPLOYEED_ID,
    L1.CATEGORY AS CATEGORY,
    L1.TOTAL_PROFIT AS TOTAL_PROFIT_EACH_CATEGORY,
    SUM(L1.TOTAL_PROFIT) OVER (PARTITION BY L1.ID) AS TOTAL_PROFIT_OVERALL,
    ROUND((L1.TOTAL_PROFIT / SUM(L1.TOTAL_PROFIT) OVER (PARTITION BY L1.ID)) * 100, 2) AS TOTAL_PROFIT_RATIO
FROM L1
ORDER BY TOTAL_PROFIT_EACH_CATEGORY DESC;

/* 12. Create a report that displays the average discount per category for each product, showing not only the average discount on category level but also the number of products in each category.
The results should be ordered by the number of products in descending order for each category */

WITH CTE_CATEGORYSUMMARY AS (
    SELECT 
        CategoryName AS CATEGORY_NAME,
        AVG(X2.discount * X2.qty * X2.unitprice) AS AVG_CATEGORY_DISCOUNT,
        AVG(X2.discount * X2.qty * X2.unitprice) AS AVERAGE_DISCOUNT_PRODUCT,
        COUNT(DISTINCT X3.PRODUCTNAME) AS NUMBER_OF_PRODUCT
    FROM Sales.Orders X1
    LEFT JOIN Sales.OrderDetails X2 ON X1.orderid = X2.orderid
    LEFT JOIN Production.Products X3 ON X2.productid = X3.PRODUCTID
    LEFT JOIN Production.Categories X4 ON X3.CATEGORYID = X4.CategoryID
    GROUP BY CategoryName
)
SELECT 
    CATEGORY_NAME,
    NUMBER_OF_PRODUCT,
    AVG(AVG_CATEGORY_DISCOUNT) AS AVG_CATEGORY_DISCOUNT
FROM CTE_CATEGORYSUMMARY
GROUP BY CATEGORY_NAME, NUMBER_OF_PRODUCT
ORDER BY AVG_CATEGORY_DISCOUNT DESC;

/* Top discount category would be Meat/Poultry at around 87.66 with only 6 different products followed by Beverages with
12 distinct products and the amount of discount is 46.18 in total */

/* 13. Give 5 suppliers who had the highest number of orders in 2022 */

WITH CTE_SUPPLIER AS (
    SELECT 
        X4.SUPPLIERNAME AS SUPPLIER_NAME,
        X1.orderid AS ORDER_ID,
        COUNT(X1.orderid) OVER (PARTITION BY X4.SUPPLIERNAME) AS TOTAL_NUMBER_ORDER,
        ROW_NUMBER() OVER (ORDER BY COUNT(X1.orderid) DESC) AS RANK
    FROM Sales.Orders X1
    LEFT JOIN Sales.OrderDetails X2 ON X1.orderid = X2.orderid
    LEFT JOIN Production.Products X3 ON X2.productid = X3.PRODUCTID
    LEFT JOIN Production.Suppliers X4 ON X3.SUPPLIERID = X4.SUPPLIERID
    WHERE YEAR(X1.orderdate) = 2022
    GROUP BY X4.SUPPLIERNAME, X1.orderid
)
SELECT 
    SUPPLIER_NAME,
    SUM(TOTAL_NUMBER_ORDER) AS TOTAL_NUMBER
FROM CTE_SUPPLIER
WHERE RANK <= 11
GROUP BY SUPPLIER_NAME
ORDER BY TOTAL_NUMBER DESC;


-- We create a temporary table (#TEMPDB_1) with all necessary information to calculate reports below
IF OBJECT_ID('TEMPDB..[#TEMPDB_1]', 'U') IS NOT NULL DROP TABLE [#TEMPDB_1];

SELECT
    X1.EmployeeID AS ID,
    CONCAT(X1.FirstName, ' ', X1.LastName) AS FULL_NAME,
    X4.PRODUCTNAME AS PRODUCT_NAME,
    X4.PRODUCTID AS PRODUCT_ID,
    X2.custid AS TOTAL_CUSTOMERS, 
    X3.orderid AS TOTAL_ORDERS,
    X3.unitprice * X3.qty AS TOTAL_REVENUE,
    CONVERT(NVARCHAR(7), X2.orderdate, 23) AS ORDERMONTH,
    X2.orderdate AS ORDERDATE,
    X2.shippeddate AS SHIPPEDDATE
INTO [#TEMPDB_1]
FROM [HR].[Employees] X1 
LEFT JOIN [Sales].[Orders] X2 ON X1.EmployeeID = X2.empid
LEFT JOIN [Sales].[OrderDetails] X3 ON X2.orderid = X3.orderid
LEFT JOIN [Production].[Products] X4 ON X3.productid = X4.PRODUCTID;


/*14. Create a report to compare revenue for the last 3 months*/

-- Step 1: Aggregate the revenue by ORDER_MONTH
WITH CTE_AGGREGATED AS (
    SELECT
        X.ORDERMONTH,
        SUM(X.TOTAL_REVENUE) AS CUR_REVENUE
    FROM 
        [#TEMPDB_1] X
    GROUP BY
        X.ORDERMONTH
),

-- Step 2: Apply the LAG function to the aggregated results
CTE_LAGGED AS (
    SELECT
        ORDERMONTH,
        CUR_REVENUE,
        LAG(CUR_REVENUE, 1) OVER (ORDER BY ORDERMONTH) AS PREV_1M_REVENUE,
        LAG(CUR_REVENUE, 2) OVER (ORDER BY ORDERMONTH) AS PREV_2M_REVENUE,
        LAG(CUR_REVENUE, 3) OVER (ORDER BY ORDERMONTH) AS PREV_3M_REVENUE
    FROM
        CTE_AGGREGATED
)

-- Step 3: Calculate the differences and insert the result into the final table
SELECT 
    ORDERMONTH,
    CUR_REVENUE,
    PREV_1M_REVENUE,
    CONCAT(100 * (CUR_REVENUE - PREV_1M_REVENUE) / PREV_1M_REVENUE, ' ', '%') AS [%_CURR_VS_1M],
    PREV_2M_REVENUE,
    CONCAT(100 * (CUR_REVENUE - PREV_2M_REVENUE) / PREV_2M_REVENUE, ' ', '%') AS [%_CURR_VS_2M],
    PREV_3M_REVENUE,
    CONCAT(100 * (CUR_REVENUE - PREV_3M_REVENUE) / PREV_3M_REVENUE, ' ', '%') AS [%_CURR_VS_3M],
    CASE 
        WHEN CUR_REVENUE > PREV_1M_REVENUE THEN 'UP'
        WHEN CUR_REVENUE = PREV_1M_REVENUE THEN 'BREAKEVEN'
        WHEN CUR_REVENUE < PREV_1M_REVENUE THEN 'DOWN'
    END AS DIFF_CUR_VS_1M,
    CASE 
        WHEN CUR_REVENUE > PREV_2M_REVENUE THEN 'UP'
        WHEN CUR_REVENUE = PREV_2M_REVENUE THEN 'BREAKEVEN'
        WHEN CUR_REVENUE < PREV_2M_REVENUE THEN 'DOWN'
    END AS DIFF_CUR_VS_2M,
    CASE 
        WHEN CUR_REVENUE > PREV_3M_REVENUE THEN 'UP'
        WHEN CUR_REVENUE = PREV_3M_REVENUE THEN 'BREAKEVEN'
        WHEN CUR_REVENUE < PREV_3M_REVENUE THEN 'DOWN'
    END AS DIFF_CUR_VS_3M
INTO [#TEMPDB_LAG_1]
FROM CTE_LAGGED;

-- Check the contents of the final table
SELECT * FROM [#TEMPDB_LAG_1];

/*15, create a report to compare revenue for each employee for each year*/
-- Define the stored procedure
CREATE PROCEDURE kpi_employee_report 
AS
BEGIN
    DECLARE @YEAR_REPORT_DATE INT = (SELECT MAX(YEAR(orderdate)) FROM [Sales].[Orders]);
    DECLARE @ONE_YEAR_AGO INT = @YEAR_REPORT_DATE - 1;
    DECLARE @TWO_YEAR_AGO INT = @YEAR_REPORT_DATE - 2;

    IF OBJECT_ID('[dbo].[kpi_employee]', 'U') IS NOT NULL 
        DROP TABLE [dbo].[kpi_employee];

    SELECT
        FULL_NAME,
        ID,
        TOTAL_CUSTOMERS,
        TOTAL_ORDERS,
        TOTAL_REVENUE,
        REVENUE_CUR_YEAR,
        REVENUE_1_YEAR_AGO,
        REVENUE_2_YEAR_AGO,
        REVENUE_CUR_YEAR / SUM(REVENUE_CUR_YEAR_OVERALL) OVER () AS CUR_REVENUE_CUR_YEAR,
        REVENUE_CUR_YEAR / SUM(REVENUE_1_YEAR_AGO_OVERALL) OVER () AS CUR_REVENUE_1_YEAR_AGO,
        REVENUE_CUR_YEAR / SUM(REVENUE_2_YEAR_AGO_OVERALL) OVER () AS CUR_REVENUE_2_YEAR_AGO
    INTO [dbo].[kpi_employee]
    FROM (
        SELECT
            FULL_NAME,
            ID,
            COUNT(X.TOTAL_CUSTOMERS) AS TOTAL_CUSTOMERS,
            COUNT(X.TOTAL_ORDERS) AS TOTAL_ORDERS,
            CAST(ISNULL(SUM(CASE WHEN X.SHIPPEDDATE IS NOT NULL THEN X.TOTAL_REVENUE ELSE 0 END), 0) AS FLOAT) AS TOTAL_REVENUE,
            SUM(CASE WHEN X.SHIPPEDDATE IS NOT NULL THEN X.TOTAL_REVENUE ELSE 0 END) AS REVENUE_CUR_YEAR,
            SUM(CASE WHEN X.SHIPPEDDATE IS NOT NULL AND YEAR(X.ORDERDATE) = @ONE_YEAR_AGO THEN X.TOTAL_REVENUE ELSE 0 END) AS REVENUE_1_YEAR_AGO,
            SUM(CASE WHEN X.SHIPPEDDATE IS NOT NULL AND YEAR(X.ORDERDATE) = @TWO_YEAR_AGO THEN X.TOTAL_REVENUE ELSE 0 END) AS REVENUE_2_YEAR_AGO,
            SUM(CASE WHEN X.SHIPPEDDATE IS NOT NULL AND YEAR(X.ORDERDATE) = @YEAR_REPORT_DATE THEN TOTAL_REVENUE ELSE 0 END) AS REVENUE_CUR_YEAR_OVERALL,
            SUM(CASE WHEN X.SHIPPEDDATE IS NOT NULL AND YEAR(X.ORDERDATE) = @ONE_YEAR_AGO THEN TOTAL_REVENUE ELSE 0 END) AS REVENUE_1_YEAR_AGO_OVERALL,
            SUM(CASE WHEN X.SHIPPEDDATE IS NOT NULL AND YEAR(X.ORDERDATE) = @TWO_YEAR_AGO THEN TOTAL_REVENUE ELSE 0 END) AS REVENUE_2_YEAR_AGO_OVERALL
        FROM [#TEMPDB_1] X
        GROUP BY FULL_NAME, ID
    ) X;
END;
GO

-- Execute the stored procedure
EXEC kpi_employee_report;

SELECT * FROM dbo.kpi_employee;
--16. Create a product report that demonstrate each product revenue during the last 13 months.
CREATE PROCEDURE product_report 
AS
BEGIN
IF OBJECT_ID ('[dbo].[product_performance]','U') IS NOT NULL DROP TABLE [dbo].[product_performance]
	
DECLARE @REPORT_DATE DATE    = (SELECT MAX(orderdate) FROM [Sales].[Orders])
DECLARE @CUR_MONTH DATE = DATEADD(MONTH,-1,DATEADD(DAY,1,EOMONTH(@REPORT_DATE)))
DECLARE @1M_AGO DATE    = DATEADD(MONTH,-2,DATEADD(DAY,1,EOMONTH(@REPORT_DATE)))
DECLARE @2M_AGO DATE    = DATEADD(MONTH,-3,DATEADD(DAY,1,EOMONTH(@REPORT_DATE)))
DECLARE @3M_AGO DATE    = DATEADD(MONTH,-4,DATEADD(DAY,1,EOMONTH(@REPORT_DATE)))
DECLARE @4M_AGO DATE    = DATEADD(MONTH,-5,DATEADD(DAY,1,EOMONTH(@REPORT_DATE)))
DECLARE @5M_AGO DATE    = DATEADD(MONTH,-6,DATEADD(DAY,1,EOMONTH(@REPORT_DATE)))
DECLARE @6M_AGO DATE    = DATEADD(MONTH,-7,DATEADD(DAY,1,EOMONTH(@REPORT_DATE)))
DECLARE @7M_AGO DATE    = DATEADD(MONTH,-8,DATEADD(DAY,1,EOMONTH(@REPORT_DATE)))
DECLARE @8M_AGO DATE    = DATEADD(MONTH,-9,DATEADD(DAY,1,EOMONTH(@REPORT_DATE)))
DECLARE @9M_AGO DATE    = DATEADD(MONTH,-10,DATEADD(DAY,1,EOMONTH(@REPORT_DATE)))
DECLARE @10M_AGO DATE   = DATEADD(MONTH,-11,DATEADD(DAY,1,EOMONTH(@REPORT_DATE)))
DECLARE @11M_AGO DATE   = DATEADD(MONTH,-12,DATEADD(DAY,1,EOMONTH(@REPORT_DATE)))
DECLARE @12M_AGO DATE   = DATEADD(MONTH,-13,DATEADD(DAY,1,EOMONTH(@REPORT_DATE)))
DECLARE @13M_AGO DATE   = DATEADD(MONTH,-14,DATEADD(DAY,1,EOMONTH(@REPORT_DATE)))
DECLARE @14M_AGO DATE   = DATEADD(MONTH,-15,DATEADD(DAY,1,EOMONTH(@REPORT_DATE)))

-------
SELECT
       PRODUCT_NAME
	  ,PRODUCT_ID
	  ,TOTAL_REVENUE          = SUM(TOTAL_REVENUE)
	  ,REVENUE_1_MONTH_AGO  = SUM(CASE WHEN @CUR_MONTH > ORDERDATE AND @1M_AGO  <= ORDERDATE THEN TOTAL_REVENUE ELSE 0 END)	
	  ,REVENUE_2_MONTH_AGO    = SUM(CASE WHEN @1M_AGO  > ORDERDATE AND @2M_AGO  <= ORDERDATE  THEN TOTAL_REVENUE ELSE 0 END)	
	  ,REVENUE_3_MONTH_AGO    = SUM(CASE WHEN @2M_AGO  > ORDERDATE AND @3M_AGO  <= ORDERDATE  THEN TOTAL_REVENUE ELSE 0 END)	
	  ,REVENUE_4_MONTH_AGO    = SUM(CASE WHEN @3M_AGO  > ORDERDATE AND @4M_AGO  <= ORDERDATE  THEN TOTAL_REVENUE ELSE 0 END)	
	  ,REVENUE_5_MONTH_AGO    = SUM(CASE WHEN @4M_AGO  > ORDERDATE AND @5M_AGO  <= ORDERDATE  THEN TOTAL_REVENUE ELSE 0 END)	
	  ,REVENUE_6_MONTH_AGO    = SUM(CASE WHEN @5M_AGO  > ORDERDATE AND @6M_AGO  <= ORDERDATE  THEN TOTAL_REVENUE ELSE 0 END)	
	  ,REVENUE_7_MONTH_AGO    = SUM(CASE WHEN @6M_AGO  > ORDERDATE AND @7M_AGO  <= ORDERDATE  THEN TOTAL_REVENUE ELSE 0 END)	
	  ,REVENUE_8_MONTH_AGO    = SUM(CASE WHEN @7M_AGO  > ORDERDATE AND @8M_AGO  <= ORDERDATE  THEN TOTAL_REVENUE ELSE 0 END)	
	  ,REVENUE_9_MONTH_AGO    = SUM(CASE WHEN @8M_AGO  > ORDERDATE AND @9M_AGO  <= ORDERDATE  THEN TOTAL_REVENUE ELSE 0 END)	
	  ,REVENUE_10_MONTH_AGO   = SUM(CASE WHEN @9M_AGO  > ORDERDATE AND @10M_AGO <= ORDERDATE THEN TOTAL_REVENUE ELSE 0 END)	
	  ,REVENUE_11_MONTH_AGO   = SUM(CASE WHEN @10M_AGO > ORDERDATE AND @11M_AGO <= ORDERDATE THEN TOTAL_REVENUE ELSE 0 END)	
	  ,REVENUE_12_MONTH_AGO   = SUM(CASE WHEN @11M_AGO > ORDERDATE AND @12M_AGO <= ORDERDATE THEN TOTAL_REVENUE ELSE 0 END)	
	  ,REVENUE_13_MONTH_AGO   = SUM(CASE WHEN @12M_AGO > ORDERDATE AND @13M_AGO <= ORDERDATE THEN TOTAL_REVENUE ELSE 0 END)	
INTO [dbo].[product_performance]
FROM [#TEMPDB_1]
WHERE PRODUCT_ID IS NOT NULL 
GROUP BY PRODUCT_NAME,PRODUCT_ID;
END;
-- Execute the stored procedure 
EXEC product_report;

