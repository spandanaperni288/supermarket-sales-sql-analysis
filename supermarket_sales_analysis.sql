-- SUPERMARKET SALES ANALYSIS
-- Dataset: 1,000 transactions across 3 branches (A, B, C)
-- Period: January 2019 – March 2019
-- Tool: MySQL
-- Author: [Spandana Perni]

-- Check for NULL values in critical columns
SELECT
    SUM(CASE WHEN invoice_id IS NULL THEN 1 ELSE 0 END)    AS null_invoice,
    SUM(CASE WHEN branch IS NULL THEN 1 ELSE 0 END)        AS null_branch,
    SUM(CASE WHEN total IS NULL THEN 1 ELSE 0 END)         AS null_total,
    SUM(CASE WHEN date IS NULL THEN 1 ELSE 0 END)          AS null_date,
    SUM(CASE WHEN product_line IS NULL THEN 1 ELSE 0 END)  AS null_product_line
FROM sales;

-- Check for duplicate invoice IDs
SELECT invoice_id, COUNT(*) AS occurrence
FROM sales
GROUP BY invoice_id
HAVING COUNT(*) > 1;

-- Verify date range of the dataset
SELECT MIN(date) AS earliest_date, MAX(date) AS latest_date
FROM sales;

-- Check for negative or zero values in financial columns
SELECT COUNT(*) AS suspicious_transactions
FROM sales
WHERE total <= 0 OR unit_price <= 0 OR quantity <= 0;



-- SECTION 1: GENERAL DATA EXPLORATION


-- Total transactions in the dataset
-- Result: 1,000 transactions
SELECT COUNT(*) AS total_transactions
FROM sales;

-- Unique branches and cities
SELECT DISTINCT branch, city
FROM sales
ORDER BY branch;

-- Summary statistics: revenue overview
SELECT
    COUNT(*)                        AS total_transactions,
    ROUND(SUM(total), 2)            AS total_revenue,
    ROUND(AVG(total), 2)            AS avg_transaction_value,
    ROUND(MIN(total), 2)            AS min_transaction,
    ROUND(MAX(total), 2)            AS max_transaction,
    ROUND(AVG(quantity), 2)         AS avg_quantity_per_txn,
    ROUND(SUM(quantity), 0)         AS total_units_sold,
    ROUND(AVG(rating), 2)           AS avg_customer_rating
FROM sales;
-- Insight: Average transaction ~$322. Total revenue just over $322K across 3 months.

-- Revenue and transaction count by branch
SELECT
    branch,
    city,
    COUNT(*)                                         AS transactions,
    ROUND(SUM(total), 2)                             AS total_revenue,
    ROUND(AVG(total), 2)                             AS avg_transaction,
    ROUND((SUM(total) / (SELECT SUM(total) FROM sales)) * 100, 1) AS revenue_pct
FROM sales
GROUP BY branch, city
ORDER BY total_revenue DESC;
-- Insight: Branch C (Naypyitaw) leads slightly in revenue despite similar transaction counts.



-- SECTION 2: PRODUCT LINE ANALYSIS


-- Overall product line performance: revenue, quantity, avg rating, avg margin
SELECT
    product_line,
    COUNT(*)                            AS transactions,
    ROUND(SUM(total), 2)                AS total_revenue,
    SUM(quantity)                       AS total_units_sold,
    ROUND(AVG(unit_price), 2)           AS avg_unit_price,
    ROUND(AVG(gross_income), 2)         AS avg_gross_income,
    ROUND(AVG(rating), 2)               AS avg_rating
FROM sales
GROUP BY product_line
ORDER BY total_revenue DESC;
-- Insight: Food & Beverages and Sports & Travel lead in revenue.
-- Health & Beauty has strong margins but lower transaction volume.

-- Which product line generates the highest revenue in each city?
-- Uses window function to rank per city cleanly
SELECT city, product_line, total_revenue
FROM (
    SELECT
        city,
        product_line,
        ROUND(SUM(total), 2) AS total_revenue,
        RANK() OVER (PARTITION BY city ORDER BY SUM(total) DESC) AS revenue_rank
    FROM sales
    GROUP BY city, product_line
) ranked
WHERE revenue_rank = 1;
-- Insight: Different cities have different top product lines — useful for localised stocking decisions.

-- Which product line sells most per branch?
SELECT branch, product_line, total_qty
FROM (
    SELECT
        branch,
        product_line,
        SUM(quantity) AS total_qty,
        ROW_NUMBER() OVER (PARTITION BY branch ORDER BY SUM(quantity) DESC) AS rn
    FROM sales
    GROUP BY branch, product_line
) t
WHERE rn = 1;

-- Product line performance label: Good vs Needs Attention
-- Based on whether revenue is above or below the dataset average per transaction
SELECT
    product_line,
    ROUND(AVG(total), 2) AS avg_revenue_per_txn,
    CASE
        WHEN AVG(total) >= (SELECT AVG(total) FROM sales) THEN 'Above Average'
        ELSE 'Below Average'
    END AS performance_label
FROM sales
GROUP BY product_line
ORDER BY avg_revenue_per_txn DESC;

-- Price range (min/max unit price) per product line
SELECT
    product_line,
    MIN(unit_price) AS min_price,
    MAX(unit_price) AS max_price,
    ROUND(MAX(unit_price) - MIN(unit_price), 2) AS price_range
FROM sales
GROUP BY product_line
ORDER BY price_range DESC;



-- SECTION 3: SALES TREND ANALYSIS


-- Monthly revenue trend
SELECT
    MONTHNAME(date)     AS month,
    MONTH(date)         AS month_num,
    COUNT(*)            AS transactions,
    ROUND(SUM(total), 2) AS total_revenue,
    ROUND(SUM(cogs), 2)  AS total_cogs
FROM sales
GROUP BY month, month_num
ORDER BY month_num;
-- Insight: January recorded the highest COGS. March had fewer transactions but strong revenue.

-- Revenue and transaction count by day of week
SELECT
    DAYNAME(date)           AS day_of_week,
    DAYOFWEEK(date)         AS day_num,
    COUNT(*)                AS transactions,
    ROUND(SUM(total), 2)    AS total_revenue,
    ROUND(AVG(total), 2)    AS avg_revenue
FROM sales
GROUP BY day_of_week, day_num
ORDER BY day_num;
-- Insight: Saturday tends to be the busiest day by transaction count.

-- Hourly transaction distribution — useful for staffing decisions
SELECT
    HOUR(time)          AS hour_of_day,
    COUNT(*)            AS transactions,
    ROUND(SUM(total), 2) AS revenue
FROM sales
GROUP BY hour_of_day
ORDER BY transactions DESC;
-- Insight: Peak hours are 19:00 (7PM), 13:00 and 10:00 — evening rush is the busiest.

-- Sales volume by time of day
SELECT
    CASE
        WHEN HOUR(time) BETWEEN 6 AND 11  THEN 'Morning (6AM–12PM)'
        WHEN HOUR(time) BETWEEN 12 AND 17 THEN 'Afternoon (12PM–6PM)'
        ELSE 'Evening (6PM–10PM)'
    END AS time_of_day,
    COUNT(*) AS transactions,
    ROUND(SUM(total), 2) AS total_revenue,
    ROUND(AVG(total), 2) AS avg_revenue
FROM sales
GROUP BY time_of_day
ORDER BY total_revenue DESC;

-- Top 5 highest value transactions
SELECT
    invoice_id,
    branch,
    city,
    product_line,
    quantity,
    ROUND(total, 2) AS total
FROM sales
ORDER BY total DESC
LIMIT 5;

-- Average daily revenue (useful as a KPI baseline)
SELECT ROUND(AVG(daily_revenue), 2) AS avg_daily_revenue
FROM (
    SELECT date, SUM(total) AS daily_revenue
    FROM sales
    GROUP BY date
) daily;



-- SECTION 4: CUSTOMER ANALYSIS


-- Customer type breakdown: revenue, quantity, rating, VAT paid
SELECT
    customer_type,
    COUNT(*)                        AS transactions,
    ROUND(SUM(total), 2)            AS total_revenue,
    SUM(quantity)                   AS total_units_bought,
    ROUND(AVG(total), 2)            AS avg_spend_per_visit,
    ROUND(SUM(VAT), 2)              AS total_vat_paid,
    ROUND(AVG(rating), 2)           AS avg_rating
FROM sales
GROUP BY customer_type
ORDER BY total_revenue DESC;
-- Insight: Members generate slightly more revenue. Both types are critical customer segments.

-- Gender distribution and spending behavior
SELECT
    gender,
    COUNT(*)                        AS transactions,
    ROUND(SUM(total), 2)            AS total_revenue,
    ROUND(AVG(total), 2)            AS avg_spend_per_txn,
    SUM(quantity)                   AS total_units_bought,
    ROUND(AVG(rating), 2)           AS avg_rating
FROM sales
GROUP BY gender
ORDER BY total_revenue DESC;
-- Insight: Female customers generate marginally higher total revenue.

-- Gender distribution per branch
SELECT
    branch,
    gender,
    COUNT(*) AS transactions,
    ROUND(SUM(total), 2) AS revenue
FROM sales
GROUP BY branch, gender
ORDER BY branch, transactions DESC;

-- Payment method preferences: overall and by gender
SELECT
    payment,
    COUNT(*)                        AS transactions,
    ROUND(SUM(total), 2)            AS total_revenue,
    ROUND(AVG(total), 2)            AS avg_transaction
FROM sales
GROUP BY payment
ORDER BY transactions DESC;
-- Insight: Ewallet, Cash, and Credit Card are almost evenly split — no single dominant method.

-- Payment preference by gender
SELECT
    gender,
    payment,
    COUNT(*) AS frequency
FROM sales
GROUP BY gender, payment
ORDER BY gender, frequency DESC;

-- Most purchased product line per gender (using window function)
SELECT gender, product_line, frequency
FROM (
    SELECT
        gender,
        product_line,
        COUNT(*) AS frequency,
        ROW_NUMBER() OVER (PARTITION BY gender ORDER BY COUNT(*) DESC) AS rn
    FROM sales
    GROUP BY gender, product_line
) t
WHERE rn = 1;
-- Insight: Fashion Accessories is top for Female customers; Health & Beauty for Male customers.

-- Customer rating patterns by time of day
SELECT
    CASE
        WHEN HOUR(time) BETWEEN 6 AND 11  THEN 'Morning'
        WHEN HOUR(time) BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS time_of_day,
    ROUND(AVG(rating), 2)   AS avg_rating,
    COUNT(*)                AS total_ratings
FROM sales
GROUP BY time_of_day
ORDER BY avg_rating DESC;
-- Insight: Afternoon ratings tend to be slightly higher — customers more satisfied mid-day.

-- Best rated day of the week per branch
SELECT DAYNAME(date) AS day, branch, ROUND(AVG(rating), 2) AS avg_rating
FROM sales
GROUP BY day, branch
ORDER BY avg_rating DESC;



-- SECTION 5: ADVANCED ANALYSIS — WINDOW FUNCTIONS


-- Rank product lines by revenue (global)
SELECT
    product_line,
    ROUND(SUM(total), 2) AS total_revenue,
    RANK() OVER (ORDER BY SUM(total) DESC) AS revenue_rank
FROM sales
GROUP BY product_line;

-- Rank branches by total sales
SELECT
    branch,
    ROUND(SUM(total), 2) AS total_sales,
    RANK() OVER (ORDER BY SUM(total) DESC) AS sales_rank
FROM sales
GROUP BY branch;

-- Rank products within each branch (to identify local bestsellers)
SELECT
    branch,
    product_line,
    ROUND(SUM(total), 0) AS total_revenue,
    RANK() OVER (PARTITION BY branch ORDER BY SUM(total) DESC) AS product_rank
FROM sales
GROUP BY product_line, branch
ORDER BY branch, product_rank;

-- Top 3 product lines by revenue
SELECT product_line, revenue, revenue_rank
FROM (
    SELECT
        product_line,
        ROUND(SUM(total), 2) AS revenue,
        RANK() OVER (ORDER BY SUM(total) DESC) AS revenue_rank
    FROM sales
    GROUP BY product_line
) t
WHERE revenue_rank <= 3;

-- Highest single-transaction value per branch
SELECT branch, invoice_id, total
FROM (
    SELECT
        branch,
        invoice_id,
        total,
        RANK() OVER (PARTITION BY branch ORDER BY total DESC) AS sales_rank
    FROM sales
) s
WHERE sales_rank = 1;

-- Second highest sale in each branch (useful for outlier exclusion analysis)
SELECT branch, ROUND(total, 2) AS second_highest_sale
FROM (
    SELECT
        branch,
        total,
        DENSE_RANK() OVER (PARTITION BY branch ORDER BY total DESC) AS sales_rank
    FROM sales
) s
WHERE sales_rank = 2;

-- Top product line per branch by revenue
SELECT branch, product_line, total_revenue
FROM (
    SELECT
        branch,
        product_line,
        ROUND(SUM(total), 2) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY branch ORDER BY SUM(total) DESC) AS revenue_rank
    FROM sales
    GROUP BY product_line, branch
) s
WHERE revenue_rank = 1;

-- Running total of revenue by date (useful for spotting growth/decline periods)
SELECT
    date,
    ROUND(SUM(total), 2) AS daily_revenue,
    ROUND(SUM(SUM(total)) OVER (ORDER BY date), 2) AS cumulative_revenue
FROM sales
GROUP BY date
ORDER BY date;
-- Insight: Cumulative revenue chart can confirm if revenue is growing or flat over the period.

-- Month-over-month revenue change using LAG()
SELECT
    month_name,
    month_num,
    monthly_revenue,
    LAG(monthly_revenue) OVER (ORDER BY month_num) AS prev_month_revenue,
    ROUND(
        monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY month_num),
    2) AS revenue_change
FROM (
    SELECT
        MONTHNAME(date)         AS month_name,
        MONTH(date)             AS month_num,
        ROUND(SUM(total), 2)    AS monthly_revenue
    FROM sales
    GROUP BY month_name, month_num
) monthly
ORDER BY month_num;
-- Insight: Identifies if February was weaker than January, and if March recovered.

-- Customer type performance ranked within each branch
SELECT
    branch,
    customer_type,
    ROUND(SUM(total), 2) AS total_purchases,
    RANK() OVER (PARTITION BY branch ORDER BY SUM(total) DESC) AS purchases_rank
FROM sales
GROUP BY branch, customer_type;

-- Rank invoices by purchase amount within each branch
SELECT
    branch,
    invoice_id,
    ROUND(SUM(total), 2) AS total_purchases,
    RANK() OVER (PARTITION BY branch ORDER BY SUM(total) DESC) AS purchases_rank
FROM sales
GROUP BY branch, invoice_id
ORDER BY branch, purchases_rank
LIMIT 20;