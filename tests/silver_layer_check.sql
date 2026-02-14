/*==============================================================
   SILVER LAYER DATA QUALITY & VALIDATION CHECKS
  ==============================================================
   Purpose:
   --------
   This script validates the quality of transformed data
   inside the Silver Layer after loading from the Bronze Layer.

   It focuses on detecting common ETL issues such as:

     ✔ Duplicate Primary Keys
     ✔ Incorrect "fresh record" selection
     ✔ String values with unwanted whitespace
     ✔ Invalid or inconsistent sales calculations
     ✔ Null or negative numeric values

   Expected Result:
   ----------------
   Most validation queries should return ZERO rows.
   Any returned records represent data quality issues
   that must be fixed in the transformation logic.

   Layer:
   ------
   Silver (Clean + Standardized Data)

==============================================================*/


/*==============================================================
   1. CHECK FOR FRESH DATA (LATEST RECORD PER CUSTOMER)
  ==============================================================
   Business Rule:
   --------------
   Each customer (cst_id) should have only ONE valid latest record.

   Technique:
   ----------
   - Use ROW_NUMBER() to rank records by creation date.
   - Rank = 1 represents the most recent ("fresh") record.

   Use Case:
   ---------
   Helps prevent duplicate primary key issues in downstream layers.
==============================================================*/

WITH Check_for_fresh_data AS (
    SELECT
        *,
        ROW_NUMBER() OVER(
            PARTITION BY cst_id
            ORDER BY cst_create_date DESC
        ) AS the_rank_of_the_record_based_on_date
    FROM silver.crm_cust_info
)
SELECT *
FROM Check_for_fresh_data
WHERE the_rank_of_the_record_based_on_date = 1
  AND cst_id = 29466;

-- Note:
-- Rank = 1 indicates the most recent valid customer record.



/*==============================================================
   2. STRING QUALITY CHECK (WHITESPACE DETECTION)
  ==============================================================
   Goal:
   -----
   Ensure that string attributes are clean and standardized.

   Problem Detected:
   -----------------
   Values with leading or trailing spaces.

   Expected Output:
   ----------------
   No rows returned.
==============================================================*/

-- Check customer first names for unwanted spaces
SELECT
    cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);


-- Count total whitespace issues in firstname column
SELECT 
    COUNT(*) AS count_of_issues
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);



/*==============================================================
   3. STRING VALIDATION PATTERN (GENDER COLUMN)
  ==============================================================
   Goal:
   -----
   Validate that gender values are properly trimmed
   and contain no hidden whitespace.

   Expected Output:
   ----------------
   Count should be zero.
==============================================================*/

-- Count whitespace issues in gender column
SELECT 
    COUNT(*) AS count_of_issues
FROM silver.crm_cust_info
WHERE cst_gndr != TRIM(cst_gndr);


-- Display problematic gender values
SELECT 
    cst_gndr
FROM silver.crm_cust_info
WHERE cst_gndr != TRIM(cst_gndr);



/*==============================================================
   4. SALES DATA CONSISTENCY CHECK
  ==============================================================
   Table:
   ------
   silver.crm_sales_details

   Business Rule:
   --------------
   Sales amount must match:

        sls_sales = sls_quantity * sls_price

   Data Quality Issues Detected:
   ----------------------------
   - Incorrect calculations
   - NULL values
   - Negative or zero values

   Expected Output:
   ----------------
   No invalid rows should remain in Silver Layer.
==============================================================*/

SELECT DISTINCT
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales IS NULL
   OR sls_quantity IS NULL
   OR sls_price IS NULL
   OR sls_sales <= 0
   OR sls_quantity <= 0
   OR sls_price <= 0;



/*==============================================================
   5. QUICK DATA SAMPLING (TOP 100 ROWS)
  ==============================================================
   Purpose:
   --------
   Manual inspection of Silver Layer outputs.

   This helps confirm:
   - Transformation success
   - Data formatting
   - No unexpected NULLs or anomalies
==============================================================*/

-- Sales Details sample
SELECT TOP 100 *
FROM silver.crm_sales_details;

-- Product Categories sample
SELECT TOP 100 *
FROM silver.erp_px_cat_g1v2;

-- Customer Info sample
SELECT TOP 100 *
FROM silver.crm_cust_info;

-- Product Info sample
SELECT TOP 100 *
FROM silver.crm_prd_info;

-- Location Info sample
SELECT TOP 100 *
FROM silver.erp_loc_a101;

-- ERP Customer sample
SELECT TOP 100 *
FROM silver.erp_cust_az12;



/*==============================================================
   END OF SILVER LAYER VALIDATION SCRIPT
  ==============================================================
   Next Step:
   ----------
   If all checks return clean results,
   the Silver Layer is ready for Gold Layer modeling.

==============================================================*/
