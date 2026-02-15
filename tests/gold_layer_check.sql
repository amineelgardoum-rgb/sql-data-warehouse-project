/* ===============================================================
   GOLD LAYER DATA QUALITY TESTS
   Returns rows ONLY when an issue exists
   =============================================================== */

---------------------------------------------------------------
-- 1. NULL FOREIGN KEYS IN FACT TABLE
---------------------------------------------------------------

-- Fact rows missing customer_key
SELECT *
FROM gold.fact_sales
WHERE customer_key IS NULL;

-- Fact rows missing product_key
SELECT *
FROM gold.fact_sales
WHERE product_key IS NULL;


---------------------------------------------------------------
-- 2. ORPHAN FACT RECORDS (NO MATCH IN DIMENSIONS)
---------------------------------------------------------------

-- Missing customer match
SELECT f.*
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON f.customer_key = c.customer_key
WHERE c.customer_key IS NULL;

-- Missing product match
SELECT f.*
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON f.product_key = p.product_key
WHERE p.product_key IS NULL;


---------------------------------------------------------------
-- 3. DUPLICATE SURROGATE KEYS IN DIMENSIONS
---------------------------------------------------------------

-- Duplicate customer_key
SELECT customer_key, COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;

-- Duplicate product_key
SELECT product_key, COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;


---------------------------------------------------------------
-- 4. DUPLICATE BUSINESS KEYS
---------------------------------------------------------------

-- Duplicate customer_id
SELECT customer_id, COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- Duplicate product_number
SELECT product_number, COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_number
HAVING COUNT(*) > 1;


---------------------------------------------------------------
-- 5. INVALID MEASURES IN FACT TABLE
---------------------------------------------------------------

-- Sales amount must be positive
SELECT *
FROM gold.fact_sales
WHERE sales_amount <= 0;

-- Quantity must not be negative
SELECT *
FROM gold.fact_sales
WHERE quantity < 0;


---------------------------------------------------------------
-- 6. INVALID DATES
---------------------------------------------------------------

-- Shipping date before order date
SELECT *
FROM gold.fact_sales
WHERE shipping_date < order_date;

-- Due date before order date
SELECT *
FROM gold.fact_sales
WHERE due_date < order_date;
