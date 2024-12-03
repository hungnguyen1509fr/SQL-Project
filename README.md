# SQL and Excel PROJECT
**Comprehensive SQL Analytics Project**
Overview
-This project delivers actionable business insights through advanced SQL queries, addressing executive-driven questions across sales, revenue, employee 
 performance, product trends, and operational efficiency. A robust temporary table architecture optimizes query speed and readability.

**Key Highlights**
__Revenue and Profit Analysis__:
-Total revenue and profit (after discounts) for 3 years.
-Breakdown by year, category, and employee.

__Employee and Product Performance__:
-Top employees by revenue and orders (overall and by category).
-Top products by revenue and Average Selling Price (ASP).

__Discount Impact__:
-Sales performance by discount levels across categories.

__Delivery Analytics__:
-Fastest, slowest, and average delivery times (overall and category-specific).

__Trend Analysis__:
-Revenue comparison over the last 3 months.
-Product revenue over the past 13 months.

**Key Techniques**
__Data Preparation__:
-Created #Comprehensive_Data and other temp tables to consolidate multi-table data for efficient querying.
-Used CTEs for modular, reusable query logic.
-Advanced SQL Features:

__Window Functions__:
-ROW_NUMBER() for rankings (e.g., top employees/products by revenue).
-LAG() for month-over-month revenue comparison.
-Aggregate Functions: SUM, AVG, COUNT for calculating KPIs.
            
__Dynamic Reporting__:
-Automated stored procedures for employee and product performance tracking.

__Categorical Analysis__:
-Grouped revenue, profit, and orders by categories and discount levels.

__Time-Based Analysis__:
-Analyzed trends over specific periods (e.g., month-over-month revenue).
__Output Highlights__:
-Delivered insights like top-performing employees/products, revenue trends, and discount impact analysis.
-Created reusable reporting tables (kpi_employee, product_performance, Discount.report) for visualization tools.
