# Gold Layer - Data Catalog
**Database:** DataWarehouse  
---

## Tables Overview

| Table Name | Type | Purpose | Rows (Grain) |
|------------|------|---------|--------------|
| gold.dim_customers | Dimension | Customer master data | One row per unique customer |
| gold.dim_products | Dimension | Product master data | One row per active product |
| gold.fact_sales | Fact | Sales transactions | One row per order line item |

---

## gold.dim_customers

**Description:** Customer dimension containing demographic and identification information

**Primary Key:** customer_key  
**Business Key:** customer_id

### Columns

| Column Name | Data Type | Description |
|------------|-----------|-------------|
| customer_key | INTEGER | Surrogate primary key |
| customer_id | VARCHAR | Customer ID from source system |
| customer_number | VARCHAR | Customer account number |
| first_name | VARCHAR | Customer's first name |
| last_name | VARCHAR | Customer's last name |
| marital_status | VARCHAR | Marital status (Single, Married, n/a) |
| country | VARCHAR | Country of residence |
| gender | VARCHAR | Gender (Male, Female, n/a) |
| birthday | DATE | Date of birth |
| create_date | DATE | Date customer record was created |

---

## gold.dim_products

**Description:** Product dimension containing product details and category information

**Primary Key:** product_key  
**Business Key:** product_number

### Columns

| Column Name | Data Type | Description |
|------------|-----------|-------------|
| product_key | INTEGER | Surrogate primary key |
| product_id | VARCHAR | Product identifier |
| product_number | VARCHAR | Product number/SKU (business key) |
| product_name | VARCHAR | Product name/description |
| category_id | VARCHAR | Category identifier |
| category | VARCHAR | Product category name |
| subcategory | VARCHAR | Product subcategory |
| maintenance | VARCHAR | Maintenance classification |
| cost | DECIMAL | Product cost |
| product_line | VARCHAR | Product line (Mountain, Road, Other Sales, Touring, n/a) |
| product_start_date | DATE | Date product became active |

**Note:** This table only includes active products (historical products are excluded)

---

## gold.fact_sales

**Description:** Sales transaction fact table

**Grain:** One row per sales order line item

### Columns

| Column Name | Data Type | Description | Column Type |
|------------|-----------|-------------|-------------|
| order_number | VARCHAR | Sales order number | Degenerate Dimension |
| product_key | INTEGER | Foreign key to dim_products | Foreign Key |
| customer_key | INTEGER | Foreign key to dim_customers | Foreign Key |
| order_date | DATE | Date order was placed | Date |
| shipping_date | DATE | Date order was shipped | Date |
| due_date | DATE | Expected delivery date | Date |
| sales_amount | DECIMAL | Total sales revenue | Measure (Additive) |
| quantity | INTEGER | Quantity of products sold | Measure (Additive) |
| price | DECIMAL | Unit price | Measure (Semi-Additive) |

### Foreign Key Relationships

- **product_key** → gold.dim_products (product_key)
- **customer_key** → gold.dim_customers (customer_key)

---

## Star Schema

```
       dim_customers                    dim_products
    ┌─────────────────┐              ┌─────────────────┐
    │ customer_key PK │              │ product_key  PK │
    │ customer_id     │              │ product_number  │
    │ first_name      │              │ product_name    │
    │ last_name       │              │ category        │
    │ country         │              │ subcategory     │
    │ gender          │              │ cost            │
    │ ...             │              │ ...             │
    └────────┬────────┘              └────────┬────────┘
             │                                │
             │ 1                          1   │
             │                                │
             │ *                          *   │
             └────────────┬───────────────────┘
                          │
                          ▼
                 ┌─────────────────┐
                 │   fact_sales    │
                 │ order_number    │
                 │ product_key  FK │
                 │ customer_key FK │
                 │ order_date      │
                 │ sales_amount    │
                 │ quantity        │
                 │ price           │
                 └─────────────────┘
```

---

## Metadata

| Property | Value |
|----------|-------|
| Schema Pattern | Star Schema |
| Number of Dimensions | 2 |
| Number of Facts | 1 |
| Layer Type | Analytics/Presentation |
