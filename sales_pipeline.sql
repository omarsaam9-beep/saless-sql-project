

-- SECTION 1 │ RAW TABLE CREATION


CREATE TABLE SALES (
    Segment       TEXT,
    Country       TEXT,
    Product       TEXT,
    Discount_Band TEXT,
    Units_Sold    TEXT,
    bgjsadfghjdas TEXT,   
    Sale_Price    TEXT,
    Gross_Sales   TEXT,
    Discounts     TEXT,
    Sales         TEXT,
    COGS          TEXT,
    Profit        TEXT,
    Date          TEXT,
    Month_Number  TEXT,
    Month_Name    TEXT,
    Year          TEXT
);

-- Backup raw data before any transformation
CREATE TABLE SALES_BACKUP AS
SELECT * FROM SALES;


 
-- SECTION 2 │ DROP IRRELEVANT COLUMNS


ALTER TABLE SALES DROP COLUMN bgjsadfghjdas;  
ALTER TABLE SALES DROP COLUMN Month_Number;   
ALTER TABLE SALES DROP COLUMN Month_Name;     
ALTER TABLE SALES DROP COLUMN Year;           


-- SECTION 3 │ RENAME COLUMNS (STANDARDIZATION)

ALTER TABLE SALES RENAME COLUMN Units_Sold  TO Quantity;
ALTER TABLE SALES RENAME COLUMN Sale_Price  TO unit_price;
ALTER TABLE SALES RENAME COLUMN Gross_Sales TO Total_Sales;
ALTER TABLE SALES RENAME COLUMN Sales       TO Revenue;
ALTER TABLE SALES RENAME COLUMN COGS        TO Cost;


-- ============================================================
-- SECTION 4 │ FEATURE ENGINEERING (RECALCULATE METRICS)
-- ============================================================
-- NOTE: All numeric columns are stored as TEXT in the raw table.
--       We cast them on-the-fly and recalculate each metric
--       from its base components to ensure consistency.

UPDATE SALES SET Total_Sales = Quantity::NUMERIC    * unit_price::NUMERIC
WHERE Quantity IS NOT NULL AND unit_price IS NOT NULL;

UPDATE SALES SET Revenue    = Total_Sales::NUMERIC  - Discounts::NUMERIC
WHERE Total_Sales IS NOT NULL AND Discounts IS NOT NULL;

UPDATE SALES SET Profit     = Revenue::NUMERIC      - Cost::NUMERIC
WHERE Revenue IS NOT NULL AND Cost IS NOT NULL;

UPDATE SALES SET Quantity   = Total_Sales::NUMERIC  / unit_price::NUMERIC
WHERE Total_Sales IS NOT NULL AND unit_price IS NOT NULL;

UPDATE SALES SET unit_price = Total_Sales::NUMERIC  / Quantity::NUMERIC
WHERE Total_Sales IS NOT NULL AND Quantity IS NOT NULL;

UPDATE SALES SET Discounts  = Total_Sales::NUMERIC  - Revenue::NUMERIC
WHERE Total_Sales IS NOT NULL AND Revenue IS NOT NULL;

UPDATE SALES SET Total_Sales = Revenue::NUMERIC     + Discounts::NUMERIC
WHERE Revenue IS NOT NULL AND Discounts IS NOT NULL;

UPDATE SALES SET Cost       = Revenue::NUMERIC      - Profit::NUMERIC
WHERE Revenue IS NOT NULL AND Profit IS NOT NULL;


-- 
-- SECTION 5 │ HANDLE MISSING VALUES

-- Fill NULL text dimensions with 'unknown'
UPDATE SALES
SET
    Segment = COALESCE(Segment, 'unknown'),
    Country = COALESCE(Country, 'unknown'),
    Product = COALESCE(Product, 'unknown')
WHERE Segment IS NULL OR Country IS NULL OR Product IS NULL;

-- Fill NULL Quantity with column average
UPDATE SALES
SET Quantity = (SELECT AVG(Quantity::NUMERIC) FROM SALES)
WHERE Quantity IS NULL;


-- SECTION 6 │ DISCOUNT BAND SEGMENTATION


UPDATE SALES
SET Discount_Band =
    CASE
        WHEN Discounts::NUMERIC  = 0                              THEN 'None'
        WHEN Discounts::NUMERIC  > 0     AND
             Discounts::NUMERIC <= 48300                          THEN 'Low'
        WHEN Discounts::NUMERIC  > 48300 AND
             Discounts::NUMERIC <= 102667.5                       THEN 'Medium'
        WHEN Discounts::NUMERIC  > 102667.5                       THEN 'High'
        ELSE NULL
    END;


-- 
-- SECTION 7 │ DATE CLEANING — FORWARD FILL MISSING DATES
-- 
-- Strategy: carry forward the last known date using a window function.
-- Edge case: any NULLs at the very beginning use a backward fill (MIN OVER).

-- Step 1 — Forward fill
UPDATE sales
SET date = sub.filled_date
FROM (
    SELECT
        ctid,
        MAX(date) OVER (
            ORDER BY ctid
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS filled_date
    FROM sales
) sub
WHERE sales.ctid = sub.ctid;

-- Step 2 — Backward fill (handles leading NULLs)
UPDATE sales
SET date = sub.filled_date
FROM (
    SELECT
        ctid,
        MIN(date) OVER (
            ORDER BY ctid
            ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING
        ) AS filled_date
    FROM sales
) sub
WHERE sales.ctid = sub.ctid
  AND sales.date IS NULL;


-- SECTION 8 │ TEXT STANDARDIZATION & NOISE REMOVAL
-- Remove special characters, trim whitespace, apply title case
-- to all text columns; clean numeric columns of non-numeric chars.

UPDATE sales
SET
    Segment      = INITCAP(TRIM(REGEXP_REPLACE(COALESCE(Segment::TEXT,      ''), '[^a-zA-Z0-9 ]', '', 'g'))),
    Country      = INITCAP(TRIM(REGEXP_REPLACE(COALESCE(Country::TEXT,      ''), '[^a-zA-Z0-9 ]', '', 'g'))),
    Product      = INITCAP(TRIM(REGEXP_REPLACE(COALESCE(Product::TEXT,      ''), '[^a-zA-Z0-9 ]', '', 'g'))),
    Discount_Band= INITCAP(TRIM(REGEXP_REPLACE(COALESCE(Discount_Band::TEXT,''), '[^a-zA-Z0-9 ]', '', 'g'))),

    Quantity     = ROUND(NULLIF(REGEXP_REPLACE(COALESCE(Quantity::TEXT,    ''), '[^0-9.]', '', 'g'), '')::NUMERIC, 1),
    unit_price   = ROUND(NULLIF(REGEXP_REPLACE(COALESCE(unit_price::TEXT,  ''), '[^0-9.]', '', 'g'), '')::NUMERIC, 1),
    Total_Sales  = ROUND(NULLIF(REGEXP_REPLACE(COALESCE(Total_Sales::TEXT, ''), '[^0-9.]', '', 'g'), '')::NUMERIC, 1),
    Discounts    = ROUND(NULLIF(REGEXP_REPLACE(COALESCE(Discounts::TEXT,   ''), '[^0-9.]', '', 'g'), '')::NUMERIC, 1),
    Revenue      = ROUND(NULLIF(REGEXP_REPLACE(COALESCE(Revenue::TEXT,     ''), '[^0-9.]', '', 'g'), '')::NUMERIC, 1),
    Cost         = ROUND(NULLIF(REGEXP_REPLACE(COALESCE(Cost::TEXT,        ''), '[^0-9.]', '', 'g'), '')::NUMERIC, 1),
    Profit       = ROUND(NULLIF(REGEXP_REPLACE(COALESCE(Profit::TEXT,      ''), '[^0-9.]', '', 'g'), '')::NUMERIC, 1);



-- SECTION 9 │ DATA QUALITY CHECK

SELECT
    COUNT(*)                       AS total_rows,
    COUNT(*) - COUNT(Segment)      AS Segment_nulls,
    COUNT(*) - COUNT(Country)      AS Country_nulls,
    COUNT(*) - COUNT(Product)      AS Product_nulls,
    COUNT(*) - COUNT(Discount_Band)AS Discount_Band_nulls,
    COUNT(*) - COUNT(Quantity)     AS Quantity_nulls,
    COUNT(*) - COUNT(unit_price)   AS unit_price_nulls,
    COUNT(*) - COUNT(Total_Sales)  AS Total_Sales_nulls,
    COUNT(*) - COUNT(Discounts)    AS Discounts_nulls,
    COUNT(*) - COUNT(Revenue)      AS Revenue_nulls,
    COUNT(*) - COUNT(Cost)         AS Cost_nulls,
    COUNT(*) - COUNT(Profit)       AS Profit_nulls,
    COUNT(*) - COUNT(Date)         AS Date_nulls
FROM SALES;

-- SECTION 10 │ DESCRIPTIVE STATISTICS

SELECT
    ROUND(MIN(Quantity::NUMERIC))    AS MIN_Quantity,
    ROUND(MAX(Quantity::NUMERIC))    AS MAX_Quantity,
    ROUND(AVG(Quantity::NUMERIC))    AS AVG_Quantity,

    ROUND(MIN(unit_price::NUMERIC))  AS MIN_unit_price,
    ROUND(MAX(unit_price::NUMERIC))  AS MAX_unit_price,
    ROUND(AVG(unit_price::NUMERIC))  AS AVG_unit_price,

    ROUND(MIN(Total_Sales::NUMERIC)) AS MIN_Total_Sales,
    ROUND(MAX(Total_Sales::NUMERIC)) AS MAX_Total_Sales,
    ROUND(AVG(Total_Sales::NUMERIC)) AS AVG_Total_Sales,

    ROUND(MIN(Discounts::NUMERIC))   AS MIN_Discounts,
    ROUND(MAX(Discounts::NUMERIC))   AS MAX_Discounts,
    ROUND(AVG(Discounts::NUMERIC))   AS AVG_Discounts,

    ROUND(MIN(Revenue::NUMERIC))     AS MIN_Revenue,
    ROUND(MAX(Revenue::NUMERIC))     AS MAX_Revenue,
    ROUND(AVG(Revenue::NUMERIC))     AS AVG_Revenue,

    MIN(Date::DATE)                  AS MIN_Date,
    MAX(Date::DATE)                  AS MAX_Date,

    ROUND(MIN(Cost::NUMERIC))        AS MIN_Cost,
    ROUND(MAX(Cost::NUMERIC))        AS MAX_Cost,
    ROUND(AVG(Cost::NUMERIC))        AS AVG_Cost,

    ROUND(MIN(Profit::NUMERIC))      AS MIN_Profit,
    ROUND(MAX(Profit::NUMERIC))      AS MAX_Profit,
    ROUND(AVG(Profit::NUMERIC))      AS AVG_Profit
FROM SALES;



-- SECTION 11 │ CLEAN FINAL TABLE

CREATE TABLE sales_clean AS
SELECT
    Segment,
    Country,
    Product,
    Discount_Band,
    Quantity::NUMERIC(10,1)    AS Quantity,
    unit_price::NUMERIC(10,1)  AS unit_price,
    Total_Sales::NUMERIC(10,1) AS Total_Sales,
    Discounts::NUMERIC(10,1)   AS Discounts,
    Revenue::NUMERIC(10,1)     AS Revenue,
    Cost::NUMERIC(10,1)        AS Cost,
    Profit::NUMERIC(10,1)      AS Profit,
    CAST(Date AS DATE)         AS Date
FROM sales;

-- Sanity check on final table
SELECT DISTINCT Segment      FROM sales_clean;
SELECT DISTINCT Country      FROM sales_clean;
SELECT DISTINCT Product      FROM sales_clean;
SELECT DISTINCT Discount_Band FROM sales_clean;



-- SECTION 12 │ MAIN KPIs

SELECT
    SUM(Total_Sales)                                   AS Total_Sales,
    SUM(Revenue)                                       AS Revenue,
    SUM(Profit)                                        AS Profit,
    ROUND(SUM(Profit) / SUM(Total_Sales) * 100, 1)    AS Profit_Margin_Pct,
    SUM(Cost)                                          AS Cost,
    SUM(Discounts)                                     AS Discounts,
    SUM(Quantity::INT)                                 AS Total_Units_Sold,
    ROUND(AVG(Total_Sales))                            AS AVG_Order_Value,
    ROUND(AVG(Profit))                                 AS AVG_Profit_Per_Order
FROM sales_clean;



-- SECTION 13 │ COUNTRY ANALYSIS

-- Insight: USA leads in Total Sales & Revenue,
--          but Germany outperforms in Profit — lower discount pressure.

SELECT Country, SUM(Total_Sales) AS Total_Sales
FROM sales_clean GROUP BY Country ORDER BY Total_Sales DESC;

SELECT Country, SUM(Revenue)     AS Revenue
FROM sales_clean GROUP BY Country ORDER BY Revenue DESC;

SELECT Country, SUM(Profit)      AS Profit
FROM sales_clean GROUP BY Country ORDER BY Profit DESC;


-- Countries with negative profit (loss-making markets)
SELECT Country, ROUND(SUM(Profit), 1) AS Total_Profit
FROM sales_clean
GROUP BY Country
HAVING SUM(Profit) < 0
ORDER BY Total_Profit ASC;

SELECT Country, SUM(Discounts)   AS Discounts
FROM sales_clean GROUP BY Country ORDER BY Discounts DESC;

SELECT Country, SUM(Quantity)    AS Total_Units
FROM sales_clean GROUP BY Country ORDER BY Total_Units DESC;


-- Revenue share by country
SELECT
    Country,
    ROUND(SUM(Revenue) * 100.0 / SUM(SUM(Revenue)) OVER (), 2) AS Revenue_Share_Pct
FROM sales_clean
GROUP BY Country
ORDER BY Revenue_Share_Pct DESC;



-- SECTION 14 │ PRODUCT ANALYSIS

-- Insight: Montana drives high volume but thin margins —
--          a classic revenue-vs-profitability trade-off.

SELECT Product, SUM(Total_Sales) AS Total_Sales
FROM sales_clean GROUP BY Product ORDER BY Total_Sales DESC;

SELECT Product, SUM(Revenue)     AS Revenue
FROM sales_clean GROUP BY Product ORDER BY Revenue DESC;

SELECT Product, SUM(Profit)      AS Profit
FROM sales_clean GROUP BY Product ORDER BY Profit DESC;

SELECT Product, SUM(Discounts)   AS Discounts
FROM sales_clean GROUP BY Product ORDER BY Discounts DESC;

SELECT Product, SUM(Quantity)    AS Total_Units
FROM sales_clean GROUP BY Product ORDER BY Total_Units DESC;

-- Profit margin per product
SELECT
    Product,
    ROUND(SUM(Profit) / SUM(Revenue) * 100, 2) AS Profit_Margin_Pct
FROM sales_clean
GROUP BY Product
ORDER BY Profit_Margin_Pct DESC;

-- Revenue contribution share per product
SELECT
    Product,
    ROUND(SUM(Revenue) * 100.0 / SUM(SUM(Revenue)) OVER (), 2) AS Revenue_Share_Pct
FROM sales_clean
GROUP BY Product
ORDER BY Revenue_Share_Pct DESC;

-- Top 3 products by revenue
SELECT Product, SUM(Revenue) AS Revenue, SUM(Profit) AS Profit
FROM sales_clean
GROUP BY Product
ORDER BY Revenue DESC
LIMIT 3;



-- SECTION 15 │ SEGMENT ANALYSIS

SELECT
    Segment,
    SUM(Revenue)       AS Revenue,
    SUM(Profit)        AS Profit,
    ROUND(SUM(Profit) / SUM(Revenue) * 100, 2)    AS Profit_Margin_Pct
FROM sales_clean
GROUP BY Segment
ORDER BY Profit_Margin_Pct DESC;


-- SECTION 16 │ DISCOUNT BAND ANALYSIS

SELECT
    Discount_Band,
    SUM(Revenue)                                   AS Revenue,
    SUM(Profit)                                    AS Profit,
    ROUND(SUM(Profit) / SUM(Revenue) * 100, 2)    AS Profit_Margin_Pct
FROM sales_clean
GROUP BY Discount_Band
ORDER BY Profit_Margin_Pct DESC;

-- Overall discount leakage
SELECT
    SUM(Discounts)                                         AS Total_Discounts,
    ROUND(SUM(Discounts) / SUM(Revenue) * 100, 2)         AS Discount_Leakage_Pct
FROM sales_clean;

-- Overall discount rate
SELECT
    ROUND(SUM(Discounts) / SUM(Total_Sales) * 100, 2)     AS Discount_Rate_Pct
FROM sales_clean;

-- Discount ratio by Country × Product
SELECT
    Country,
    Product,
    SUM(Discounts)                                         AS Total_Discounts,
    SUM(Revenue)                                           AS Revenue,
    ROUND(SUM(Discounts) / SUM(Revenue) * 100, 2)         AS Discount_Ratio_Pct
FROM sales_clean
GROUP BY Country, Product
ORDER BY Discount_Ratio_Pct DESC;

-- SECTION 17 │ ADVANCED ANALYTICS

-- . Monthly Revenue Growth
-- NOTE: Dataset has missing months — growth % between distant
--       periods may appear inflated. Interpret with caution.

SELECT *
FROM (
    SELECT
        DATE_TRUNC('month', Date)                                          AS Month,
        SUM(Revenue)                                                       AS Revenue,
        LAG(SUM(Revenue)) OVER (ORDER BY DATE_TRUNC('month', Date))       AS Prev_Revenue,
        ROUND(
            (SUM(Revenue) - LAG(SUM(Revenue)) OVER (ORDER BY DATE_TRUNC('month', Date)))
            / LAG(SUM(Revenue)) OVER (ORDER BY DATE_TRUNC('month', Date)) * 100
        , 2)                                                               AS Growth_Pct
    FROM sales_clean
    GROUP BY Month
) t
WHERE Prev_Revenue IS NOT NULL;


-- ── 17B. Pareto Analysis — Cumulative Product Contribution ───

WITH product_revenue AS (
    SELECT Product, SUM(Revenue) AS Revenue
    FROM sales_clean
    GROUP BY Product
)
SELECT
    Product,
    Revenue,
    ROUND(
        SUM(Revenue) OVER (ORDER BY Revenue DESC)
        / SUM(Revenue) OVER () * 100
    , 2) AS Cumulative_Revenue_Pct
FROM product_revenue
ORDER BY Revenue DESC;


-- ── 17C. Low-Margin Countries ────────────────────────────────

SELECT
    Country,
    SUM(Revenue)                                   AS Revenue,
    SUM(Profit)                                    AS Profit,
    ROUND(SUM(Profit) / SUM(Revenue) * 100, 2)    AS Profit_Margin_Pct
FROM sales_clean
GROUP BY Country
ORDER BY Profit_Margin_Pct ASC;


-- ── 17D. Average Revenue per Country ─────────────────────────

SELECT
    Country,
    ROUND(AVG(Revenue), 2) AS AVG_Revenue_Per_Order
FROM sales_clean
GROUP BY Country
ORDER BY AVG_Revenue_Per_Order DESC;



-- END OF PIPELINE
