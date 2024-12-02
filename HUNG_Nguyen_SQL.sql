
/*

------ 
Since I receive the list of question by the executives that need to pull data from multiple tables, to optimize query speed and readability, I created
a temporary table with all neccessary information which is #Comprehensive_Data.
*/
;
IF OBJECT_ID('TEMPDB..[#Comprehensive_Data]', 'U') IS NOT NULL DROP TABLE [#Comprehensive_Data];

SELECT  
    YEAR(X1.orderdate)											AS [YEAR],
    X1.orderid													AS [ORDER_ID],
    X5.EmployeeID												AS [EMPLOYEES_ID],
    CONCAT(X5.Firstname, ' ', X5.Lastname)						AS [FULL_NAME_EMP],
    SUM(X2.unitprice * X2.qty)									AS [REVENUE],
    CAST(SUM(X2.unitprice * X2.qty * (1 - X2.discount)) AS INT) AS [PROFIT],
    X2.discount													AS [DISCOUNT],
    X4.CategoryName												AS [CATEGORY_NAME],
    X3.PRODUCTNAME												AS [PRODUCT_NAME],
    X7.SUPPLIERNAME												AS [SUPPLIER_NAME],
    X1.shippeddate												AS [SHIPPED_DATE],
    X1.orderdate												AS [ORDER_DATE],
    X1.shipcity													AS [SHIPPED_CITY],
    X1.shipcountry												AS [SHIPPED_COUNTRY],
    X6.region													AS [REGION],
    X2.unitprice												AS [PRICE],
    X2.qty														AS [QUANTITY],
	X2.productid												AS [PRODUCT_ID]
INTO #Comprehensive_Data
FROM Sales.Orders X1 
LEFT JOIN Sales.OrderDetails X2 ON X1.orderid = X2.orderid
LEFT JOIN Production.Products X3 ON X2.productid = X3.PRODUCTID
LEFT JOIN Production.Categories X4 ON X3.CATEGORYID = X4.CategoryID
LEFT JOIN HR.Employees X5 ON X1.empid = X5.EmployeeID
LEFT JOIN Continent X6 ON X1.shipcountry = X6.country
LEFT JOIN Production.Suppliers X7 ON X1.shipperid = X7.SUPPLIERID
GROUP BY X1.orderid, X5.EmployeeID, CONCAT(X5.Firstname, ' ', X5.Lastname), X1.orderdate, X1.shippeddate, X2.productid,
X4.CategoryName, X3.PRODUCTNAME, X1.shipcity, X1.shipcountry, X2.unitprice, X2.qty, X6.region, X7.SUPPLIERNAME, X2.discount;


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
    SUM(PROFIT) AS TOTAL_PROFIT
FROM #Comprehensive_Data
GROUP BY  YEAR
ORDER BY YEAR, TOTAL_PROFIT DESC;
/*We can see clearly that Beverages and Dairy's products are the top 2 categories that generated the most revenue during the span of 3 years.*/
SELECT 
    CATEGORY_NAME,
    SUM(REVENUE) AS TOTAL_REVENUE,
    SUM(PROFIT) AS TOTAL_PROFIT
FROM #Comprehensive_Data
GROUP BY  CATEGORY_NAME
ORDER BY TOTAL_PROFIT DESC
-- TOtal number of order, revenue and profit by Region
SELECT 
    ISNULL(REGION, 'Other') AS Region,
	COUNT(ORDER_ID)         AS Total_number_order,
    SUM(REVENUE) AS TOTAL_REVENUE,
    SUM(PROFIT) AS TOTAL_PROFIT
FROM #Comprehensive_Data
GROUP BY  REGION
ORDER BY TOTAL_PROFIT DESC;

/*3. TOP 3 EMPLOYEES by revenue*/
		
SELECT TOP 5
    EMPLOYEES_ID									 AS [ID],
    FULL_NAME_EMP									 AS [NAME],
    SUM(REVENUE)									 AS [TOTAL_REVENUE],
	COUNT(DISTINCT ORDER_ID)						 AS [TOTAL_ORDER],
	SUM(PRICE * QUANTITY) / COUNT(DISTINCT ORDER_ID) AS [AVERAGE_ORDER_VALUE]
FROM #Comprehensive_Data 
GROUP BY EMPLOYEES_ID, FULL_NAME_EMP
ORDER BY TOTAL_REVENUE DESC;


/*4. TOP EMPLOYEES by revenue in each category*/

WITH EMP_REVE AS (
    SELECT 
		FULL_NAME_EMP AS [FULL_NAME],
        EMPLOYEES_ID AS ID,
        
        SUM(REVENUE) AS TOTAL_REVENUE,
        CATEGORY_NAME,
        ROW_NUMBER() OVER (PARTITION BY CATEGORY_NAME ORDER BY SUM(REVENUE) DESC) AS RANK
    FROM #Comprehensive_Data
    GROUP BY EMPLOYEES_ID, FULL_NAME_EMP, CATEGORY_NAME
)
SELECT 
    [FULL_NAME],
    CATEGORY_NAME,
    TOTAL_REVENUE
FROM EMP_REVE
WHERE RANK <= 3
ORDER BY FULL_NAME;
/* With this query, we can calculate the top 3 employees ranking by total revenue in each category.*/

/*4. TOP 3 employees by number of orders*/
WITH EMP_REVE AS (
    SELECT 
        FULL_NAME_EMP AS [FULL_NAME],
        EMPLOYEES_ID AS ID,
        CATEGORY_NAME,
        SUM(REVENUE) AS TOTAL_REVENUE,
        SUM(SUM(REVENUE)) OVER (PARTITION BY CATEGORY_NAME) AS TOTAL_CAT_REV,
        ROW_NUMBER() OVER (PARTITION BY CATEGORY_NAME ORDER BY SUM(REVENUE) DESC) AS RANK
    FROM #Comprehensive_Data
    GROUP BY EMPLOYEES_ID, FULL_NAME_EMP, CATEGORY_NAME
)
SELECT 
    [FULL_NAME],
    TOTAL_CAT_REV,
    CATEGORY_NAME,
    TOTAL_REVENUE,
    (TOTAL_REVENUE / TOTAL_CAT_REV) * 100 AS REVENUE_RATIO
FROM EMP_REVE
WHERE RANK <= 3
ORDER BY CATEGORY_NAME DESC;



/*5. TOP 3 Employees with number of orders by category*/

WITH EMP_ORDERS AS (
    SELECT 
        EMPLOYEES_ID,
        FULL_NAME_EMP,
        COUNT(DISTINCT ORDER_ID) 	 AS TOTAL_ORDER,
        ROW_NUMBER() OVER (PARTITION BY CATEGORY_NAME ORDER BY COUNT(DISTINCT ORDER_ID) DESC) 
        							 AS RANK,
        CATEGORY_NAME
    FROM #Comprehensive_Data
    GROUP BY EMPLOYEES_ID, FULL_NAME_EMP, CATEGORY_NAME
					)
SELECT 
    EMPLOYEES_ID  AS ID,
    FULL_NAME_EMP AS FULL_NAME,
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

/* 7. TOP 2 products with highest revenue in each category */
WITH PRODUCT_RANK AS (
    SELECT  
        CATEGORY_NAME,
        PRODUCT_NAME,
        SUM(REVENUE) AS TOTAL_REVENUE,
		COUNT(ORDER_ID) AS NUMBER_OF_ORDER,
        ROW_NUMBER() OVER(PARTITION BY CATEGORY_NAME ORDER BY SUM(REVENUE) DESC) AS RANK
    FROM #Comprehensive_Data
    GROUP BY PRODUCT_NAME, CATEGORY_NAME
)
SELECT 
    CATEGORY_NAME,
    PRODUCT_NAME,
	NUMBER_OF_ORDER,
    TOTAL_REVENUE
FROM PRODUCT_RANK
WHERE RANK <= 2;

/* 7b. What are the top 3 products in each categories in the last 6 months based on revenue */

WITH PRODUCT_RANK AS (
    SELECT  
        CATEGORY_NAME,
        PRODUCT_NAME,
        SUM(REVENUE) AS TOTAL_REVENUE,
        ROW_NUMBER() OVER(PARTITION BY CATEGORY_NAME ORDER BY SUM(REVENUE) DESC) AS RANK
    FROM #Comprehensive_Data
    WHERE ORDER_DATE >= DATEADD(MONTH, -6, (SELECT MAX(ORDER_DATE) FROM #Comprehensive_Data))
    GROUP BY CATEGORY_NAME, PRODUCT_NAME
)
SELECT  
    CATEGORY_NAME,
    PRODUCT_NAME,
    TOTAL_REVENUE
FROM PRODUCT_RANK
WHERE RANK <= 3;



/* 8. Calculate the fastest, average, and slowest delivery time for each order */
SELECT 
	SHIPPED_COUNTRY,
	SUM(PRICE * QUANTITY) / COUNT(DISTINCT ORDER_ID) AS Average_Order_Value,
    MIN(DATEDIFF(DAY, ORDER_DATE, SHIPPED_DATE)) AS MIN_SHIPPING_DURATION,
    AVG(DATEDIFF(DAY, ORDER_DATE, SHIPPED_DATE)) AS AVERAGE_SHIPPING_DURATION,
    MAX(DATEDIFF(DAY, ORDER_DATE, SHIPPED_DATE)) AS MAX_SHIPPING_DURATION
FROM #Comprehensive_Data
GROUP BY SHIPPED_COUNTRY;
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


/*9. What are the top countries and cities by the number of orders? */
SELECT TOP 10
    SHIPPED_CITY,
    SHIPPED_COUNTRY,	
	ISNULL(REGION, 'Other')								AS REGION,
    COUNT(DISTINCT ORDER_ID)							AS TOTAL_ORDERS,
    SUM(PRICE * QUANTITY) / COUNT(DISTINCT ORDER_ID)	AS Average_Order_Value
FROM #Comprehensive_Data
GROUP BY SHIPPED_CITY, SHIPPED_COUNTRY, REGION
ORDER BY TOTAL_ORDERS DESC;
---------------
SELECT 	
	ISNULL(REGION, 'Other')								AS REGION,
    COUNT(DISTINCT ORDER_ID)							AS TOTAL_ORDERS,
    SUM(PRICE * QUANTITY)								AS TOTAL_REVENUE
FROM #Comprehensive_Data
GROUP BY  REGION
ORDER BY TOTAL_ORDERS DESC;

/* 10. Calculate Average Sold Price of each orderid. Get top 10 orderid with highest sold price. 
(Formula to apply: ASP (Average Selling Price) = Total GS orderid / Sum of count orderid sold) */

SELECT TOP 10		
    ORDER_ID ,
    SUM(PRICE * QUANTITY) / COUNT(DISTINCT ORDER_ID) AS Average_Order_Value,
    SUM(PRICE * QUANTITY) / SUM(QUANTITY) AS Average_Selling_Price
FROM #Comprehensive_Data
GROUP BY ORDER_ID
ORDER BY Average_Order_Value DESC;

/* 11. Calculate Average Sold Price of each productid. Get top 10 productid with highest sold price. 
(Formula to apply: ASP (Average Selling Price) = Total GS productid / Sum of count product sold) */

SELECT TOP 10
    PRODUCT_ID AS PROD_ID,
    PRODUCT_NAME AS PROD_Name,
    CATEGORY_NAME AS CAT_Name,
    SUM(O.PRICE * O.QUANTITY) AS Revenue,
    CAST(SUM(O.PRICE * O.QUANTITY * (1 - O.DISCOUNT)) AS INT) AS Profit,
    SUM(O.PRICE * O.QUANTITY) / COUNT(DISTINCT O.ORDER_ID) AS Avg_Order_Value,
    SUM(O.PRICE * O.QUANTITY) / SUM(O.QUANTITY) AS Avg_Selling_Price
FROM #Comprehensive_Data O
GROUP BY PRODUCT_ID, PRODUCT_NAME, CATEGORY_NAME
ORDER BY Profit DESC;
/* We can see that Cote De Blaye in the Beverage Category performed much higher than the second product in terms of GS and AOV,
which is Thüringer Rostbratwurst in Meat/Poultry. Notably, Cote de Blaye's GS is nearly double that of Thüringer Rostbratwurst while AOV is more than double. */

/* 12. Analyze the impact of different discount levels on sales performance across product categories, 
specifically looking at the number of orders and total profit generated for each discount classification. 
- Discount level condition:
- No Discount = 0
- 0 < Low Discount <= 0.2
- 0.2 < Medium Discount <= 0.5
- High Discount > 0.5 */
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


-- Select from Discount.report
SELECT * FROM [Discount.report]
ORDER BY CATEGORY DESC; 
/* With the above query, we can clearly analyze the discount based on level, total number of orders, and 
total profit across all categories */


/* 13. Write a query to create a report that displays each employee's performance across different product categories,
showing not only the total profit per category but also what percentage of their total profit each category represents,
with the results ordered by the percentage in descending order for each employee */

CREATE TABLE [Employees_Profit_CAT]
		(EMP_ID INT,
		NAME NVARCHAR(30),
		CAT NVARCHAR(30),
		PROFIT_CAT INT,
		PROFIT_ALL INT,
		PROFIT_RATIO DECIMAL(5,2)
		);
WITH L1 AS (
    SELECT 
        EMPLOYEES_ID AS EID,
        FULL_NAME_EMP AS NAME,
        SUM(QUANTITY * PRICE) AS T_PROFIT,
        CATEGORY_NAME AS CAT
    FROM #Comprehensive_Data
    GROUP BY EMPLOYEES_ID, CATEGORY_NAME, FULL_NAME_EMP
)

-- Select and insert into the target table
INSERT INTO [Employees_Profit_CAT] (EMP_ID, NAME, CAT, PROFIT_CAT, PROFIT_ALL, PROFIT_RATIO)
SELECT 
    L1.EID AS EMP_ID,
    L1.NAME,
    L1.CAT AS CAT,
    L1.T_PROFIT AS PROFIT_CAT,
    SUM(L1.T_PROFIT) OVER (PARTITION BY L1.EID) AS PROFIT_ALL,
    (L1.T_PROFIT / SUM(L1.T_PROFIT) OVER (PARTITION BY L1.EID)) AS PROFIT_RATIO
FROM L1
ORDER BY L1.EID, PROFIT_RATIO DESC;

SELECT * FROM Employees_Profit_CAT;
------



/* 14. Create a report that displays the average discount per category for each product, showing not only the average discount on category level but also the number of products in each category.
The results should be ordered by the number of products in descending order for each category */

WITH CTE_CATEGORYSUMMARY AS (
    SELECT 
        CATEGORY_NAME AS CAT_NAME,
        AVG(DISCOUNT * QUANTITY * PRICE) AS AVG_DISCOUNT,
        COUNT(DISTINCT PRODUCT_NAME) AS NUM_PRODUCTS
    FROM #Comprehensive_Data
    GROUP BY CATEGORY_NAME
)
SELECT 
    CAT_NAME,
    NUM_PRODUCTS,
    AVG_DISCOUNT
FROM CTE_CATEGORYSUMMARY
ORDER BY AVG_DISCOUNT DESC;


/* Top discount category would be Meat/Poultry at around 87.66 with only 6 different products followed by Beverages with
12 distinct products and the amount of discount is 46.18 in total */

/* 15. Give 5 suppliers who had the highest number of orders in 2022 */

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

/* 16. Monthly Revenue Analysis */
-- Ensure the target table exists

CREATE TABLE dbo.TEMPDB_LAG_1 (
    ORDERMONTH NVARCHAR(7),
    CUR_REV FLOAT,
    PREV_1M_REV FLOAT,
    [%_CURR_VS_1M] FLOAT,
    PREV_2M_REV FLOAT,
    [%_CURR_VS_2M] FLOAT,
    PREV_3M_REV FLOAT,
    [%_CURR_VS_3M] FLOAT,
    DIFF_CURR_1M NVARCHAR(5),
    DIFF_CURR_2M NVARCHAR(5),
    DIFF_CURR_3M NVARCHAR(5)
);
WITH CTE_AGG AS (
    SELECT
        CONVERT(NVARCHAR(7), ORDER_DATE, 23) AS ORDERMONTH,
        SUM(CAST(REVENUE AS FLOAT)) AS CUR_REV
    FROM 
        #Comprehensive_Data
    GROUP BY
        CONVERT(NVARCHAR(7), ORDER_DATE, 23)
),

--Calculate lagged values for previous months
CTE_LAG AS (
    SELECT
        ORDERMONTH,
        CUR_REV,
        LAG(CUR_REV, 1) OVER (ORDER BY ORDERMONTH) AS PREV_1M_REV,
        LAG(CUR_REV, 2) OVER (ORDER BY ORDERMONTH) AS PREV_2M_REV,
        LAG(CUR_REV, 3) OVER (ORDER BY ORDERMONTH) AS PREV_3M_REV
    FROM
        CTE_AGG
)

-- Insert the results into the target table
INSERT INTO dbo.TEMPDB_LAG_1 (ORDERMONTH, CUR_REV, PREV_1M_REV, [%_CURR_VS_1M], PREV_2M_REV, [%_CURR_VS_2M], PREV_3M_REV, [%_CURR_VS_3M], DIFF_CURR_1M, DIFF_CURR_2M, DIFF_CURR_3M)
SELECT 
    ORDERMONTH,
    CUR_REV,
    PREV_1M_REV,
    CASE 
        WHEN PREV_1M_REV <> 0 THEN ROUND((CUR_REV - PREV_1M_REV) / PREV_1M_REV, 2)
        ELSE NULL
    END AS [%_CURR_VS_1M],
    PREV_2M_REV,
    CASE 
        WHEN PREV_2M_REV <> 0 THEN ROUND((CUR_REV - PREV_2M_REV) / PREV_2M_REV, 2)
        ELSE NULL
    END AS [%_CURR_VS_2M],
    PREV_3M_REV,
    CASE 
        WHEN PREV_3M_REV <> 0 THEN ROUND((CUR_REV - PREV_3M_REV) / PREV_3M_REV, 2)
        ELSE NULL
    END AS [%_CURR_VS_3M],
    CASE 
        WHEN CUR_REV > PREV_1M_REV THEN 'UP'
        WHEN CUR_REV = PREV_1M_REV THEN 'EVEN'
        WHEN CUR_REV < PREV_1M_REV THEN 'DOWN'
    END AS DIFF_CURR_1M,
    CASE 
        WHEN CUR_REV > PREV_2M_REV THEN 'UP'
        WHEN CUR_REV = PREV_2M_REV THEN 'EVEN'
        WHEN CUR_REV < PREV_2M_REV THEN 'DOWN'
    END AS DIFF_CURR_2M,
    CASE 
        WHEN CUR_REV > PREV_3M_REV THEN 'UP'
        WHEN CUR_REV = PREV_3M_REV THEN 'EVEN'
        WHEN CUR_REV < PREV_3M_REV THEN 'DOWN'
    END AS DIFF_CURR_3M
FROM CTE_LAG;
SELECT * FROM TEMPDB_LAG_1

/*17, create a report to compare revenue for each employee for each year*/
-- Define the stored procedure
CREATE PROCEDURE kpi_employee_report 

AS DECLARE @YEAR_REPORT_DATE INT = (SELECT MAX(YEAR(orderdate)) FROM [Sales].[Orders])
DECLARE @ONE_YEAR_AGO     INT = (SELECT @YEAR_REPORT_DATE - 1) 
DECLARE @TWO_YEAR_AGO     INT = (SELECT @YEAR_REPORT_DATE - 2)

IF OBJECT_ID ('[dbo].[kpi_employee]','U') IS NOT NULL DROP TABLE [dbo].[kpi_employee]

SELECT
    EMP_NAME,
    TOTAL_REV,
    REV_CURR_YEAR,
    REV_1YR_AGO,
    REV_2YR_AGO,
    CURR_YR_RATIO = REV_CURR_YEAR / SUM(CURR_YR_TOTAL) OVER (),
    RATIO_1YR_AGO = REV_CURR_YEAR / SUM(YR1_TOTAL) OVER (),
    RATIO_2YR_AGO = REV_CURR_YEAR / SUM(YR2_TOTAL) OVER ()
INTO [dbo].[kpi_employee]
FROM (
    SELECT
        FULL_NAME_EMP AS EMP_NAME,
        CAST(ISNULL(SUM(CASE WHEN SHIPPED_DATE IS NOT NULL THEN REVENUE ELSE 0 END), 0) AS FLOAT) AS TOTAL_REV,
        SUM(CASE WHEN SHIPPED_DATE IS NOT NULL THEN REVENUE ELSE 0 END) AS REV_CURR_YEAR,
        SUM(CASE WHEN SHIPPED_DATE IS NOT NULL AND YEAR(ORDER_DATE) = @ONE_YEAR_AGO THEN REVENUE ELSE 0 END) AS REV_1YR_AGO,
        SUM(CASE WHEN SHIPPED_DATE IS NOT NULL AND YEAR(ORDER_DATE) = @TWO_YEAR_AGO THEN REVENUE ELSE 0 END) AS REV_2YR_AGO,
        SUM(CASE WHEN SHIPPED_DATE IS NOT NULL THEN REVENUE ELSE 0 END) AS CURR_YR_TOTAL,
        SUM(CASE WHEN SHIPPED_DATE IS NOT NULL AND YEAR(ORDER_DATE) = @ONE_YEAR_AGO THEN REVENUE ELSE 0 END) AS YR1_TOTAL,
        SUM(CASE WHEN SHIPPED_DATE IS NOT NULL AND YEAR(ORDER_DATE) = @TWO_YEAR_AGO THEN REVENUE ELSE 0 END) AS YR2_TOTAL
    FROM [#Comprehensive_Data] 
    GROUP BY FULL_NAME_EMP, EMPLOYEES_ID
) X
ORDER BY TOTAL_REV DESC;
;
	EXEC kpi_employee_report;

GO ;
SELECT * FROM kpi_employee
--18. Create a product report that demonstrate each product revenue during the last 13 months.
CREATE PROCEDURE product_report 
AS
BEGIN
IF OBJECT_ID ('[dbo].[product_performance]','U') IS NOT NULL DROP TABLE [dbo].[product_performance]

DECLARE @REPORT_DATE DATE = (SELECT MAX(orderdate) FROM [Sales].[Orders])
DECLARE @CUR_MONTH DATE = DATEADD(MONTH, -1, DATEADD(DAY, 1, EOMONTH(@REPORT_DATE)))
DECLARE @1M_AGO DATE = DATEADD(MONTH, -2, DATEADD(DAY, 1, EOMONTH(@REPORT_DATE)))
DECLARE @2M_AGO DATE = DATEADD(MONTH, -3, DATEADD(DAY, 1, EOMONTH(@REPORT_DATE)))
DECLARE @3M_AGO DATE = DATEADD(MONTH, -4, DATEADD(DAY, 1, EOMONTH(@REPORT_DATE)))
DECLARE @4M_AGO DATE = DATEADD(MONTH, -5, DATEADD(DAY, 1, EOMONTH(@REPORT_DATE)))
DECLARE @5M_AGO DATE = DATEADD(MONTH, -6, DATEADD(DAY, 1, EOMONTH(@REPORT_DATE)))
DECLARE @6M_AGO DATE = DATEADD(MONTH, -7, DATEADD(DAY, 1, EOMONTH(@REPORT_DATE)))
DECLARE @7M_AGO DATE = DATEADD(MONTH, -8, DATEADD(DAY, 1, EOMONTH(@REPORT_DATE)))
DECLARE @8M_AGO DATE = DATEADD(MONTH, -9, DATEADD(DAY, 1, EOMONTH(@REPORT_DATE)))
DECLARE @9M_AGO DATE = DATEADD(MONTH, -10, DATEADD(DAY, 1, EOMONTH(@REPORT_DATE)))
DECLARE @10M_AGO DATE = DATEADD(MONTH, -11, DATEADD(DAY, 1, EOMONTH(@REPORT_DATE)))
DECLARE @11M_AGO DATE = DATEADD(MONTH, -12, DATEADD(DAY, 1, EOMONTH(@REPORT_DATE)))
DECLARE @12M_AGO DATE = DATEADD(MONTH, -13, DATEADD(DAY, 1, EOMONTH(@REPORT_DATE)))
DECLARE @13M_AGO DATE = DATEADD(MONTH, -14, DATEADD(DAY, 1, EOMONTH(@REPORT_DATE)))
DECLARE @14M_AGO DATE = DATEADD(MONTH, -15, DATEADD(DAY, 1, EOMONTH(@REPORT_DATE)))

SELECT
    PRODUCT_NAME,
    SUM(REVENUE) AS TOTAL_REVENUE,
    SUM(CASE WHEN @CUR_MONTH > ORDER_DATE AND @1M_AGO <= ORDER_DATE THEN REVENUE ELSE 0 END) AS [1_MONTH_AGO],
    SUM(CASE WHEN @1M_AGO > ORDER_DATE AND @2M_AGO <= ORDER_DATE THEN REVENUE ELSE 0 END) AS [2_MONTH_AGO],
    SUM(CASE WHEN @2M_AGO > ORDER_DATE AND @3M_AGO <= ORDER_DATE THEN REVENUE ELSE 0 END) AS [3_MONTH_AGO],
    SUM(CASE WHEN @3M_AGO > ORDER_DATE AND @4M_AGO <= ORDER_DATE THEN REVENUE ELSE 0 END) AS [4_MONTH_AGO],
    SUM(CASE WHEN @4M_AGO > ORDER_DATE AND @5M_AGO <= ORDER_DATE THEN REVENUE ELSE 0 END) AS [5_MONTH_AGO],
    SUM(CASE WHEN @5M_AGO > ORDER_DATE AND @6M_AGO <= ORDER_DATE THEN REVENUE ELSE 0 END) AS [6_MONTH_AGO],
    SUM(CASE WHEN @6M_AGO > ORDER_DATE AND @7M_AGO <= ORDER_DATE THEN REVENUE ELSE 0 END) AS [7_MONTH_AGO],
    SUM(CASE WHEN @7M_AGO > ORDER_DATE AND @8M_AGO <= ORDER_DATE THEN REVENUE ELSE 0 END) AS [8_MONTH_AGO],
    SUM(CASE WHEN @8M_AGO > ORDER_DATE AND @9M_AGO <= ORDER_DATE THEN REVENUE ELSE 0 END) AS [9_MONTH_AGO],
    SUM(CASE WHEN @9M_AGO > ORDER_DATE AND @10M_AGO <= ORDER_DATE THEN REVENUE ELSE 0 END) AS [10_MONTH_AGO],
    SUM(CASE WHEN @10M_AGO > ORDER_DATE AND @11M_AGO <= ORDER_DATE THEN REVENUE ELSE 0 END) AS [11_MONTH_AGO],
    SUM(CASE WHEN @11M_AGO > ORDER_DATE AND @12M_AGO <= ORDER_DATE THEN REVENUE ELSE 0 END) AS [12_MONTH_AGO],
    SUM(CASE WHEN @12M_AGO > ORDER_DATE AND @13M_AGO <= ORDER_DATE THEN REVENUE ELSE 0 END) AS [13_MONTH_AGO]
INTO [dbo].[product_performance]
FROM [#Comprehensive_Data]
WHERE PRODUCT_ID IS NOT NULL 
GROUP BY PRODUCT_NAME, PRODUCT_ID;

-- After creating the table, you can use a separate query to order the data
SELECT *
FROM [dbo].[product_performance]
ORDER BY TOTAL_REVENUE DESC;
;
END;
-- Execute the stored procedure 
EXEC product_report;
----




