# SQL Data Warehouse Project

A comprehensive data warehouse implementation using a medallion architecture (Bronze → Silver → Gold) for sales analytics.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Data Layers](#data-layers)
- [Database Schema](#database-schema)
- [Setup Instructions](#setup-instructions)
- [ETL Process](#etl-process)
- [Usage Examples](#usage-examples)
- [Project Structure](#project-structure)

---

## 🎯 Overview

This data warehouse project consolidates sales data from multiple source systems (CRM and ERP) into a unified analytics platform. The warehouse uses a **Star Schema** in the Gold layer to enable efficient business intelligence and reporting.

**Key Features:**
- Multi-source data integration (CRM + ERP systems)
- Three-layer medallion architecture (Bronze, Silver, Gold)
- Star schema data mart for analytics
- Automated ETL pipelines
- Data quality and validation rules

---

## 🏗️ Architecture

### Medallion Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        SOURCE SYSTEMS                            │
│  ┌──────────────┐              ┌──────────────┐                 │
│  │  CRM System  │              │  ERP System  │                 │
│  │  - Customers │              │  - Customer  │                 │
│  │  - Products  │              │    Demographics                │
│  │  - Sales     │              │  - Locations │                 │
│  └──────┬───────┘              │  - Categories│                 │
│         │                      └──────┬───────┘                 │
└─────────┼─────────────────────────────┼─────────────────────────┘
          │                             │
          │        BULK INSERT          │
          ▼                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                       BRONZE LAYER                               │
│                     (Raw Data Storage)                           │
│  ┌─────────────────┐          ┌─────────────────┐               │
│  │ crm_cust_info   │          │ erp_cust_az12   │               │
│  │ crm_prd_info    │          │ erp_loc_a101    │               │
│  │ crm_sales_details│         │ erp_px_cat_g1v2 │               │
│  └────────┬────────┘          └────────┬────────┘               │
└───────────┼──────────────────────────────┼──────────────────────┘
            │                              │
            │    CLEANSE & TRANSFORM       │
            ▼                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       SILVER LAYER                               │
│              (Cleansed & Standardized Data)                      │
│  ┌─────────────────┐          ┌─────────────────┐               │
│  │ crm_cust_info   │          │ erp_cust_az12   │               │
│  │ crm_prd_info    │          │ erp_loc_a101    │               │
│  │ crm_sales_details│         │ erp_px_cat_g1v2 │               │
│  └────────┬────────┘          └────────┬────────┘               │
└───────────┼──────────────────────────────┼──────────────────────┘
            │                              │
            │    AGGREGATE & DENORMALIZE   │
            ▼                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        GOLD LAYER                                │
│                   (Analytics Star Schema)                        │
│                                                                  │
│         ┌────────────────┐       ┌────────────────┐             │
│         │ dim_customers  │       │ dim_products   │             │
│         └────────┬───────┘       └───────┬────────┘             │
│                  │                       │                      │
│                  └──────┬────────────────┘                      │
│                         │                                       │
│                         ▼                                       │
│                  ┌─────────────┐                                │
│                  │ fact_sales  │                                │
│                  └─────────────┘                                │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📊 Data Layers

### Bronze Layer (Raw Data)
- **Purpose:** Exact copy of source data
- **Load Strategy:** TRUNCATE and BULK INSERT (Full Load)
- **Transformations:** None
- **Tables:**
  - `bronze.crm_cust_info` - Customer information from CRM
  - `bronze.crm_prd_info` - Product information from CRM
  - `bronze.crm_sales_details` - Sales transactions from CRM
  - `bronze.erp_cust_az12` - Customer demographics from ERP
  - `bronze.erp_loc_a101` - Customer locations from ERP
  - `bronze.erp_px_cat_g1v2` - Product categories from ERP

### Silver Layer (Cleansed Data)
- **Purpose:** Clean, validated, and standardized data
- **Load Strategy:** TRUNCATE and INSERT (Full Load)
- **Transformations:**
  - Data type conversions
  - NULL handling
  - Code standardization (e.g., 'M' → 'Male', 'S' → 'Single')
  - Data validation and quality checks
  - Deduplication
  - Date format standardization
  - SCD Type 2 implementation for products
- **Tables:** Same structure as Bronze but with cleansed data

### Gold Layer (Analytics)
- **Purpose:** Business-ready star schema for reporting
- **Object Type:** Views (real-time queries on Silver layer)
- **Schema Pattern:** Star Schema
- **Objects:**
  - `gold.dim_customers` - Customer dimension
  - `gold.dim_products` - Product dimension  
  - `gold.fact_sales` - Sales fact table

---

## 🗄️ Database Schema

### Star Schema (Gold Layer)

```
       dim_customers                    dim_products
    ┌─────────────────┐              ┌─────────────────┐
    │ customer_key PK │              │ product_key  PK │
    │ customer_id     │              │ product_number  │
    │ customer_number │              │ product_name    │
    │ first_name      │              │ category        │
    │ last_name       │              │ subcategory     │
    │ marital_status  │              │ cost            │
    │ country         │              │ product_line    │
    │ gender          │              │ ...             │
    │ birthday        │              └────────┬────────┘
    │ create_date     │                       │
    └────────┬────────┘                       │
             │ 1                          1   │
             │                                │
             │ *                          *   │
             └────────────┬───────────────────┘
                          │
                          ▼
                 ┌─────────────────┐
                 │   fact_sales    │
                 ├─────────────────┤
                 │ order_number    │
                 │ product_key  FK │
                 │ customer_key FK │
                 │ order_date      │
                 │ shipping_date   │
                 │ due_date        │
                 │ sales_amount    │
                 │ quantity        │
                 │ price           │
                 └─────────────────┘
```

### Table Details

**gold.dim_customers** (10 columns)
- Surrogate key: `customer_key`
- Business key: `customer_id`
- Demographics: name, marital status, gender, country, birthday

**gold.dim_products** (11 columns)
- Surrogate key: `product_key`
- Business key: `product_number`
- Attributes: name, category, subcategory, cost, product line
- Filter: Active products only (`prd_end_dt IS NULL`)

**gold.fact_sales** (9 columns)
- Grain: One row per sales order line item
- Foreign keys: `product_key`, `customer_key`
- Measures: `sales_amount`, `quantity`, `price`
- Dates: `order_date`, `shipping_date`, `due_date`

---

## 🚀 Setup Instructions

### Prerequisites
- SQL Server 2016 or later
- SQL Server Management Studio (SSMS)
- Access to source CSV files

### Installation Steps

1. **Create Database**
   ```sql
   CREATE DATABASE DataWarehouse;
   GO
   USE DataWarehouse;
   GO
   ```

2. **Create Schemas**
   ```sql
   CREATE SCHEMA bronze;
   CREATE SCHEMA silver;
   CREATE SCHEMA gold;
   GO
   ```

3. **Create Bronze Tables**
   - Run table creation scripts for all bronze layer tables

4. **Create Silver Tables**
   - Run table creation scripts for all silver layer tables

5. **Deploy Stored Procedures**
   - Deploy `bronze.load_bronze` stored procedure
   - Deploy `silver.load_silver` stored procedure

6. **Create Gold Views**
   - Create `gold.dim_customers` view
   - Create `gold.dim_products` view
   - Create `gold.fact_sales` view

7. **Configure Data Source**
   - Update file paths in `bronze.load_bronze` to point to your CSV files
   - Default path: `C:\Users\lenovo\Desktop\sql-data-warehouse-project\datasets\`

---

## ⚙️ ETL Process

### Execution Order

```
1. EXEC bronze.load_bronze;   -- Load raw data from CSV files
2. EXEC silver.load_silver;   -- Transform and cleanse data
3. SELECT * FROM gold.*;      -- Query analytics views (auto-updated)
```

### Bronze Layer ETL

**Stored Procedure:** `bronze.load_bronze`

**Process:**
1. Truncate all bronze tables
2. Bulk insert from CSV files
3. Log execution time for each table

**Source Files:**
- `source_crm/cust_info.csv`
- `source_crm/prd_info.csv`
- `source_crm/sales_details.csv`
- `source_erp/CUST_AZ12.csv`
- `source_erp/LOC_A101.csv`
- `source_erp/PX_CAT_G1V2.csv`

### Silver Layer ETL

**Stored Procedure:** `silver.load_silver`

**Key Transformations:**

**Customer Data:**
- Deduplication (keep most recent record per customer)
- Trim whitespace from names
- Standardize marital status: 'S' → 'Single', 'M' → 'Married'
- Standardize gender: 'F' → 'Female', 'M' → 'Male'
- Remove 'NAS' prefix from ERP customer IDs
- Standardize country codes: 'DE' → 'Germany', 'US'/'USA' → 'United States'

**Product Data:**
- Extract category ID from composite product key
- Split product key (first 5 chars = category, rest = product key)
- Expand product line codes: 'M' → 'Mountain', 'R' → 'Road', etc.
- Calculate end dates using LEAD window function (SCD Type 2)
- Default NULL costs to 0

**Sales Data:**
- Convert integer dates (YYYYMMDD) to DATE type
- Validate and recalculate sales amounts (quantity × price)
- Derive missing prices from sales/quantity
- Handle invalid or zero values

### Gold Layer

**Type:** Views (no ETL required)
- Views query silver layer in real-time
- Surrogate keys generated via ROW_NUMBER()
- Dimension enrichment through JOINs

---

## 💡 Usage Examples

### Basic Queries

**Total Sales by Customer:**
```sql
SELECT 
    c.customer_id,
    c.first_name + ' ' + c.last_name AS customer_name,
    c.country,
    SUM(f.sales_amount) AS total_sales,
    COUNT(DISTINCT f.order_number) AS order_count
FROM gold.fact_sales f
JOIN gold.dim_customers c ON f.customer_key = c.customer_key
GROUP BY c.customer_id, c.first_name, c.last_name, c.country
ORDER BY total_sales DESC;
```

**Sales by Product Category:**
```sql
SELECT 
    p.category,
    p.subcategory,
    SUM(f.sales_amount) AS total_sales,
    SUM(f.quantity) AS units_sold,
    COUNT(DISTINCT f.order_number) AS order_count
FROM gold.fact_sales f
JOIN gold.dim_products p ON f.product_key = p.product_key
GROUP BY p.category, p.subcategory
ORDER BY total_sales DESC;
```

**Monthly Sales Trend:**
```sql
SELECT 
    YEAR(order_date) AS year,
    MONTH(order_date) AS month,
    SUM(sales_amount) AS monthly_sales,
    AVG(sales_amount) AS avg_order_value,
    COUNT(DISTINCT order_number) AS order_count
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY year, month;
```

**Product Performance:**
```sql
SELECT 
    p.product_name,
    p.product_line,
    p.category,
    SUM(f.quantity) AS units_sold,
    SUM(f.sales_amount) AS revenue,
    SUM(f.sales_amount) - (SUM(f.quantity) * p.cost) AS gross_profit
FROM gold.fact_sales f
JOIN gold.dim_products p ON f.product_key = p.product_key
GROUP BY p.product_name, p.product_line, p.category, p.cost
ORDER BY revenue DESC;
```

---

## 📁 Project Structure

```
sql-data-warehouse-project/
│
├── datasets/
│   ├── source_crm/
│   │   ├── cust_info.csv
│   │   ├── prd_info.csv
│   │   └── sales_details.csv
│   │
│   └── source_erp/
│       ├── CUST_AZ12.csv
│       ├── LOC_A101.csv
│       └── PX_CAT_G1V2.csv
│
├── scripts/
│   ├── 01_create_database.sql
│   ├── 02_create_schemas.sql
│   ├── 03_create_bronze_tables.sql
│   ├── 04_create_silver_tables.sql
│   ├── 05_sp_load_bronze.sql
│   ├── 06_sp_load_silver.sql
│   └── 07_create_gold_views.sql
│
└── docs/
    ├── README.md
    ├── data_catalog.md
    └── architecture_diagram.png
```

---

## 🎯 Key Features

### Data Quality
- ✅ Deduplication of customer records
- ✅ Data type standardization
- ✅ NULL value handling
- ✅ Invalid data correction
- ✅ Code normalization
- ✅ Date validation

### Performance
- ✅ Indexed surrogate keys
- ✅ Star schema optimization
- ✅ Materialized views (can be implemented)
- ✅ Partitioning ready

### Flexibility
- ✅ View-based gold layer (real-time)
- ✅ Modular ETL procedures
- ✅ Easily extensible schema
- ✅ SCD Type 2 for products

---

## 📈 Data Integration Flow

**CRM System:**
- Customer master data → `crm_cust_info`
- Product catalog → `crm_prd_info`
- Sales transactions → `crm_sales_details`

**ERP System:**
- Customer demographics → `erp_cust_az12`
- Location data → `erp_loc_a101`
- Product categories → `erp_px_cat_g1v2`

**Integration Points:**
- Customers: `cst_id/cst_key` = `cid`
- Products: `cat_id` = `id`
- Sales: `sls_prd_key` = `product_number`, `sls_cust_id` = `customer_id`

---

## 🔧 Maintenance

### Regular Tasks
1. **Daily:** Run ETL procedures
   ```sql
   EXEC bronze.load_bronze;
   EXEC silver.load_silver;
   ```

2. **Weekly:** Monitor data quality
   - Check for NULL foreign keys in fact_sales
   - Validate row counts across layers
   - Review orphaned records

3. **Monthly:** Performance tuning
   - Update statistics
   - Review execution plans
   - Optimize indexes

---

## 📝 Notes

- All Bronze → Silver ETL uses **full load** strategy (TRUNCATE and INSERT)
- Gold layer views provide **real-time** analytics
- Product dimension excludes historical products (active only)
- Foreign keys in fact_sales may be NULL if dimension records missing
- Surrogate keys are deterministic (ROW_NUMBER with consistent ordering)

---

## 🤝 Contributing

To extend this data warehouse:
1. Add new source tables to Bronze layer
2. Create corresponding transformations in Silver layer
3. Update Gold views or add new dimensions/facts as needed

---

## 📄 License

This project is for educational and demonstration purposes.

---

## 📧 Contact

For questions or issues, please refer to the project documentation or contact the data team.

---

**Last Updated:** February 15, 2026  
**Version:** 1.0
