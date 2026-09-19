-- Before Loading data to Silver, Check for abnormalities.
-- Check For nulls or duplicates in primary key
-- Expectation: No Result
SELECT
cst_id,
COUNT(*)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- TEST THE SILVER AFTER ADDJUSTMENT
SELECT
cst_id,
COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- CHECK UNWANTED SPACES
-- Expectation: No Results

SELECT cst_firstname
FROM bronze.crm_cust_info
--WHERE cst_lastname != TRIM(cst_lastname)
WHERE cst_gndr != TRIM(cst_lastname)

-- Data Standardization & Consistency

SELECT DISTINCT cst_gndr
FROM bronze.crm_cust_info;
