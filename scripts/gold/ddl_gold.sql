/* ===============================================================
   GOLD LAYER DATA MART (STAR SCHEMA)
   ---------------------------------------------------------------
   PURPOSE:
   - Build analytical views for Sales reporting
   - Fact table in the center + Customer/Product dimensions

   =============================================================== */


/* ===============================================================
   FACT VIEW: gold.fact_sales
   ---------------------------------------------------------------
   Grain: One row per sales order line
   Contains:
   - Foreign keys to dimensions (product_key, customer_key)
   - Measures (sales_amount, quantity, price)
   - Dates (order, shipping, due)
   =============================================================== */
CREATE OR ALTER VIEW gold.fact_sales AS 
SELECT 
    sd.sls_ord_num    AS order_number,      -- Degenerate dimension (order reference)
    pr.product_key    AS product_key,       -- FK to dim_products
    cu.customer_key   AS customer_key,      -- FK to dim_customers
    sd.sls_order_dt   AS order_date,        -- Order date
    sd.sls_ship_dt    AS shipping_date,     -- Shipping date
    sd.sls_due_dt     AS due_date,          -- Due date
    sd.sls_sales      AS sales_amount,      -- Total sales amount
    sd.sls_quantity   AS quantity,          -- Quantity sold
    sd.sls_price      AS price              -- Unit price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
    ON sd.sls_prd_key = pr.product_number   -- Map source product key → product dimension
LEFT JOIN gold.dim_customers cu
    ON sd.sls_cust_id = cu.customer_id;     -- Map source customer id → customer dimension
GO


/* ===============================================================
   DIMENSION VIEW: gold.dim_customers
   ---------------------------------------------------------------
   Purpose:
   - Customer descriptive attributes for slicing sales data
   Key:
   - customer_key generated as surrogate key (ROW_NUMBER)
   =============================================================== */
CREATE OR ALTER VIEW gold.dim_customers AS   
SELECT       
    ROW_NUMBER() OVER(ORDER BY ci.cst_id) AS customer_key, 
    ci.cst_id          AS customer_id,        -- Business/customer id
    ci.cst_key         AS customer_number,    -- Customer reference number
    ci.cst_firstname   AS first_name,         -- First name
    ci.cst_lastname    AS last_name,          -- Last name
    ci.cst_marital_status AS marital_status,  -- Marital status
    la.cntry           AS country,            -- Country

    -- Gender cleanup: prefer CRM value, otherwise ERP value, else 'n/a'
    CASE 
        WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr         
        ELSE COALESCE(ca.gen,'n/a')   
    END AS gender,

    ca.bdate           AS birthday,           -- Birth date
    ci.cst_create_date AS create_date         -- Record creation date
FROM silver.crm_cust_info ci  
LEFT JOIN silver.erp_cust_az12 ca  
    ON ci.cst_key = ca.cid                    -- Enrich with ERP customer data
LEFT JOIN silver.erp_loc_a101 la  
    ON ci.cst_key = la.cid;                   -- Enrich with location data
GO


/* ===============================================================
   DIMENSION VIEW: gold.dim_products
   ---------------------------------------------------------------
   Purpose:
   - Product descriptive attributes for analysis
   Key:
   - product_key generated as surrogate key (ROW_NUMBER)
   Filter:
   - Only active products (exclude historical versions)
   =============================================================== */
CREATE OR ALTER VIEW gold.dim_products AS   
SELECT      
    ROW_NUMBER() OVER(ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key, 
    pn.prd_id        AS product_id,           -- Business product id
    pn.prd_key       AS product_number,       -- Product reference number
    pn.prd_nm        AS product_name,         -- Product name
    pn.cat_id        AS category_id,          -- Category id
    pc.cat           AS category,             -- Category name
    pc.subcat        AS subcategory,          -- Subcategory name
    pc.maintenance   AS maintenance,          -- Maintenance attribute
    pn.prd_cost      AS cost,                 -- Product cost
    pn.prd_line      AS product_line,         -- Product line
    pn.prd_start_dt  AS product_start_date    -- Start date (SCD)
FROM silver.crm_prd_info pn  
LEFT JOIN silver.erp_px_cat_g1v2 pc  
    ON pn.cat_id = pc.id                      -- Enrich with category details
WHERE pn.prd_end_dt IS NULL;                  -- Keep only current/active products
GO
