# Supermarket Sales Analysis — SQL Project

A business-focused SQL analysis of 1,000 retail transactions across three supermarket branches, covering sales performance, product trends, and customer behavior.

---

## Key Business Findings

| Metric | Value |
|---|---|
| Total Revenue | ~$322,966 |
| Transactions Analyzed | 1,000 |
| Period | January – March 2019 |
| Branches | 3 (Yangon, Mandalay, Naypyitaw) |
| Average Transaction Value | ~$322 |
| Average Customer Rating | 6.97 / 10 |

**Top Insights:**
- **Branch C (Naypyitaw)** generates the highest revenue despite similar transaction volume across branches
- **Food & Beverages** and **Sports & Travel** are the top-performing product lines by revenue
- **Evening hours (6PM–10PM)** drive the most sales — a staffing and inventory consideration
- **Female customers** generate marginally higher total revenue; **Fashion Accessories** is their top purchase
- Revenue declined month-over-month from January to February but partially recovered in March — identified using `LAG()`
- **Ewallet, Cash, and Credit Card** payments are almost evenly distributed — no single method dominates

---

## Project Structure

```
supermarket_sales_analysis.sql
│
├── Section 0 — Data Quality Checks
├── Section 1 — General Data Exploration
├── Section 2 — Product Line Analysis
├── Section 3 — Sales Trend Analysis
├── Section 4 — Customer Analysis
└── Section 5 — Advanced Analysis (Window Functions)
```

---

## Database Schema

```sql
CREATE TABLE sales (
    invoice_id       VARCHAR(30),
    branch           VARCHAR(5),
    city             VARCHAR(30),
    customer_type    VARCHAR(30),
    gender           VARCHAR(10),
    product_line     VARCHAR(100),
    unit_price       DECIMAL(10,2),
    quantity         INT,
    VAT              FLOAT,
    total            DECIMAL(12,4),
    date             DATE,
    time             TIME,
    payment          VARCHAR(20),
    cogs             DECIMAL(10,2),
    gross_margin_pct FLOAT,
    gross_income     DECIMAL(12,4),
    rating           FLOAT
);
```

---

## Analysis Breakdown

### Section 0 — Data Quality Checks
Before any analysis, the data was validated for:
- NULL values across critical columns
- Duplicate invoice IDs
- Date range verification
- Negative or zero values in financial fields

*Real-world datasets are messy. Checking data quality first is standard practice in any analyst role.*

---

### Section 1 — General Data Exploration
Established baseline KPIs across the full dataset:
- Total transactions, revenue, and units sold
- Average transaction value and customer rating
- Branch-level revenue contribution and percentage share

---

### Section 2 — Product Line Analysis
Evaluated all six product lines across multiple dimensions:

- Revenue, quantity sold, and average rating per product line
- Top product line per city (using `RANK()` window function)
- Best-selling product line per branch (using `ROW_NUMBER()`)
- Above/below average performance label using a `CASE` expression vs dataset mean
- Price range (min, max, spread) per product line

---

### Section 3 — Sales Trend Analysis
Time-based analysis to uncover operational patterns:

- Monthly revenue trend with COGS comparison
- Day-of-week revenue and transaction volume
- Hourly transaction distribution for staffing insights
- Time-of-day sales segmentation (Morning / Afternoon / Evening)
- Cumulative revenue over time using `SUM() OVER (ORDER BY date)`
- Month-over-month revenue change using `LAG()`

---

### Section 4 — Customer Analysis
Behavioral analysis of customer segments:

- Member vs Normal customer spend, volume, and satisfaction
- Gender spending patterns and product preferences
- Payment method preferences overall and by gender
- Rating patterns by time of day and day of week
- Most purchased product line per gender using `ROW_NUMBER()`

---

### Section 5 — Advanced SQL (Window Functions)
Demonstrates proficiency in analytical SQL:

| Query | Function Used |
|---|---|
| Global product line revenue ranking | `RANK()` |
| Branch revenue ranking | `RANK()` |
| Product performance within each branch | `RANK() PARTITION BY branch` |
| Highest transaction per branch | `RANK() PARTITION BY branch` |
| Second highest sale per branch | `DENSE_RANK()` |
| Top product per branch | `DENSE_RANK() PARTITION BY branch` |
| Running cumulative revenue | `SUM() OVER (ORDER BY date)` |
| Month-over-month change | `LAG()` |
| Invoice ranking within branch | `RANK() PARTITION BY branch` |

---

## SQL Concepts Demonstrated

- `GROUP BY` with aggregation (`SUM`, `AVG`, `COUNT`, `MIN`, `MAX`)
- `CASE` expressions for conditional classification
- Subqueries (scalar and derived table)
- Common filtering with `HAVING` and `WHERE`
- Window functions: `RANK()`, `DENSE_RANK()`, `ROW_NUMBER()`, `LAG()`, `SUM() OVER()`
- `PARTITION BY` for group-level rankings
- Date/time functions: `MONTHNAME()`, `DAYNAME()`, `HOUR()`, `MONTH()`
- Data quality validation queries

---

## Sample Query — Month-over-Month Revenue Change

```sql
SELECT
    month_name,
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
```

**Why this matters:** Month-over-month tracking is a core KPI in retail analytics. Using `LAG()` avoids self-joins and is the standard professional approach.

---

## Tools Used

- **MySQL** — Query development and execution
- **GitHub** — Version control and portfolio documentation

---

## Dataset Source

[Supermarket Sales Dataset — Kaggle](https://www.kaggle.com/datasets/aungpyaeap/supermarket-sales)

---

## About

I'm Spandana Perni an aspiring business analyst with a background in recruitment coordination, transitioning into data analytics. This project demonstrates practical SQL skills applied to real-world retail data — the kind of analysis used in operations, sales, and business performance roles.

Open to entry-level to mid-level analyst opportunities.
