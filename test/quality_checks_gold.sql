/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs quality checks to validate the integrity, consistency, 
    and accuracy of the Gold Layer. These checks ensure:
    - Uniqueness of surrogate keys in dimension tables.
    - Referential integrity between fact and dimension tables.
    - Validation of relationships in the data model for analytical purposes.

Usage Notes:
    - Investigate and resolve any discrepancies found during the checks.
===============================================================================
*/

-- ====================================================================
-- Checking 'gold.dim_customers'
-- ====================================================================
-- Check for Uniqueness of Customer Key in gold.dim_customers
-- Expectation: No results 
SELECT 
    customer_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;

-- ====================================================================
-- Checking 'gold.product_key'
-- ====================================================================
-- Check for Uniqueness of Product Key in gold.dim_products
-- Expectation: No results 
SELECT 
    product_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;

-- ====================================================================
-- Checking 'gold.fact_sales'
-- ====================================================================
-- Check the data model connectivity between fact and dimensions
SELECT * 
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key
LEFT JOIN gold.dim_products p
ON p.product_key = f.product_key
WHERE p.product_key IS NULL OR c.customer_key IS NULL  
/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs quality checks to validate the integrity, consistency, 
    and accuracy of the Gold Layer. These checks ensure:
    - Uniqueness of surrogate keys in dimension tables.
    - Referential integrity between fact and dimension tables.
    - Validation of relationships in the data model for analytical purposes.

Usage Notes:
    - Investigate and resolve any discrepancies found during the checks.
===============================================================================
*/

-- ====================================================================
-- Checking 'gold.dim_customers'
-- ====================================================================
-- Check for Uniqueness of Customer Key in gold.dim_customers
-- Expectation: No results 
SELECT 
    customer_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;

-- ====================================================================
-- Checking 'gold.product_key'
-- ====================================================================
-- Check for Uniqueness of Product Key in gold.dim_products
-- Expectation: No results 
SELECT 
    product_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;

-- ====================================================================
-- Checking 'gold.fact_sales'
-- ====================================================================
-- Check the data model connectivity between fact and dimensions
SELECT * 
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key
LEFT JOIN gold.dim_products p
ON p.product_key = f.product_key
WHERE p.product_key IS NULL OR c.customer_key IS NULL  


-- Because i made an error in the previous step, I will drop the view and recreate it.
IF OBJECT_ID ('gold.dim_customer', 'V') IS NOT NULL
    DROP VIEW gold.dim_customer;
GO

SELECT cst_id, COUNT(*) FROM
(
SELECT 
      ci.cst_id,
      ci.cst_key,
      ci.cst_firstname,
      ci.cst_lastname,
      ci.cst_marital_status,
      ci.cst_gndr,
      ci.cst_create_date,
      ca.bdate,
      ca.gen,
      la.cntry
  FROM silver.crm_cust_info  AS ci

  -- JOIN TABLE A
  LEFT JOIN silver.erp_cust_az12 AS ca 
  ON ci.cst_key = ca.cid

  -- JOIN TABLE B
  LEFT JOIN silver.erp_loc_a101 AS la
  ON ci.cst_key = la.cid
)t GROUP BY cst_id
HAVING COUNT(*) > 1;

  --After joining check for duplicates. Now we have two gender columns, one from crm_cust_info and one from erp_cust_az12. We need to decide which one to keep. Let's assume we want to keep the gender from crm_cust_info and ignore the one from erp_cust_az12.
  -- DATA INTEGRATION

  SELECT DISTINCT
      ci.cst_gndr,
      ca.gen,
      CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the master for gender infos
        ELSE COALESCE(ca.gen, 'n/a')
      END AS gender
  FROM silver.crm_cust_info  AS ci

  -- JOIN TABLE A
  LEFT JOIN silver.erp_cust_az12 AS ca 
  ON ci.cst_key = ca.cid

  -- JOIN TABLE B
  LEFT JOIN silver.erp_loc_a101 AS la
  ON ci.cst_key = la.cid
  ORDER BY 1,2

  -- CREATE VIEW gold.dim_customer AS TO GET RECORDS AT GOLD LAYER LEVEL

  SELECT * FROM gold.dim_customer;

  -- DIM PRODUCT 
  SELECT 
      prd_id
      cat_id,
      prd_key,
      prd_nm,
      prd_cost,
      prd_line,
      prd_start_dt,
      prd_end_dt
  FROM silver.crm_prd_info

  -- NB: CHECK FOR DUPLICATES IN DIM PRODUCT
  SELECT prd_id, COUNT(*) FROM
  (
  SELECT 
      pn.prd_id,
      pn.cat_id,
      pn.prd_key,
      pn.prd_nm,
      pn.prd_cost,
      pn.prd_line,
      pn.prd_start_dt,
      pc.cat,
      pc.subcat,
      pc.maintenance
  FROM silver.crm_prd_info AS pn
  LEFT JOIN silver.erp_px_cat_g1v2 AS pc
  ON pn.cat_id = pc.id
  WHERE prd_end_dt IS NULL
  )t GROUP BY prd_id
  HAVING COUNT(*) > 1;

  -- Foriegn Key Integrity check (Dimensions)

  SELECT * FROM gold.fact_sales f
  LEFT JOIN gold.dim_customers c
  ON f.customer_key = c.customer_key
  LEFT JOIN gold.dim_products p
  ON f.product_key = p.product_key
  WHERE c.customer_key IS NULL OR p.product_key IS NULL;
  
  -- All Gooooooooooooooooooooooooood
