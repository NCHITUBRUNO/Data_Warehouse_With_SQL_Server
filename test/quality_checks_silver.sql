/* Check for Nulls or Duplicates in Primary key
Expectation: No Results should be returned if the data is clean.
Quality Check: A Pimary key must be unique and not null.

*/
-- ROW_NUMBER: Assign a Unique number to each row in a result set, based on the defined order
SELECT
cst_id,
COUNT(*) AS cnt
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL

--Quality Check:  Check for unwanted spaces in string values
-- Expectation: No Results

SELECT cst_firstname
FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname) 

-- Data Standardization & Consistency
SELECT DISTINCT cst_gndr
FROM bronze.crm_cust_info

-- Data Standardization & Consistency
SELECT DISTINCT cst_marital_status
FROM bronze.crm_cust_info

-- DO A DATA CHECK IN THE SILVER LAYER
-- QUALITY CHECK SILVER
SELECT
cst_id,
COUNT(*) AS cnt
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL

SELECT cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname) 

-- BRONZE crm_prd_info
-- EXPECTION: NO RESULTS
SELECT
prd_id,
COUNT(*) AS cnt
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL

-- Check for unwanted spaces in string values
-- Expectation: No Results......OK
	SELECT prd_nm
	FROM bronze.crm_prd_info
	WHERE prd_nm != TRIM(prd_nm)

-- Check for NULLS or Negative Numbers
-- Expectations: No Results
SELECT prd_cost
FROM bronze.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL

-- Data Standardization & Consistency
SELECT DISTINCT prd_line
FROM bronze.crm_prd_info

-- Check for invalid Date Orders
-- End date must not be earlier thatn the start date
SELECT *
FROM bronze.crm_prd_info
WHERE prd_end_dt < prd_start_dt
-- Solution: End Date = Start Date of the 'NEXT' Record -1
SELECT
prd_id,
prd_key,
prd_start_dt,
prd_end_dt,
LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1 AS prd_start_dt_test
FROM bronze.crm_prd_info
WHERE prd_key IN ('AC-HE-HL-U509-R', 'AC-HE-HL-U509')

-- crm_sales_details
-- Check for Invalid Dates: Negative numbers or zeros cant be cast to a date.
SELECT 
NULLIF(sls_order_dt, 0) AS sls_order_dt
FROM bronze.crm_sales_details
--WHERE sls_order_dt <= 0  OR LEN(sls_order_dt) != 8
-- Chek for outliers by validating the boundaries of the date range
WHERE sls_order_dt <= 0  
	  OR LEN(sls_order_dt) != 8 
	  OR sls_order_dt > 20500101 
	  OR sls_order_dt < 19000101

-- CHECK SHIP DATE
SELECT 
NULLIF(sls_ship_dt, 0) AS sls_order_dt
FROM bronze.crm_sales_details
--WHERE sls_order_dt <= 0  OR LEN(sls_order_dt) != 8
-- Chek for outliers by validating the boundaries of the date range
WHERE sls_ship_dt <= 0  
	  OR LEN(sls_ship_dt) != 8 
	  OR sls_ship_dt > 20500101 
	  OR sls_ship_dt < 19000101

-- Order Date must always be earlier than the shipping date or due date

-- Business Rule
-- Sales = Qty *  Price
-- No : Negative, Zeros, Nulls are not Allowed. Check Date Consistency

SELECT DISTINCT
sls_sales AS old_sls_sales,
sls_quantity AS old_sls_quantity,
sls_price AS old_sls_price,
CASE WHEN sls_sales IS NULL OR sls_sales <=0 OR sls_sales != sls_quantity * ABS(sls_price)
	THEN sls_quantity * ABS(sls_price)
ELSE sls_sales
END AS sls_sales,	

CASE WHEN sls_price IS NULL OR sls_price <=0
	THEN sls_sales /NULLIF(sls_quantity, 0)
ELSE sls_price
END AS sls_price

FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price
-- SOLUTION
-- Talk to someone from the source system
--1) Data Issues will be fixed direct in source system.
--2) Data issues has to be fixed in data warehouse.
/*
RULES
If sales is negative , zero, or null, derive it using quantity and price.
if price is zero, or null, calculate it using sales and quantity
if price is negative , convert it to a positive value.
*/

-- BRONZE ERP TABLES.... CUST_AZ12
SELECT * FROM bronze.erp_cust_az12
-- Some old data starts with NAS, and the old one does not. Clean that up.

SELECT
cid,
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
	 ELSE cid
END AS cid,
bdate,
gen
FROM bronze.erp_cust_az12
WHERE CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) ELSE cid END NOT IN
(SELECT DISTINCT cst_key FROM silver.crm_cust_info);


-- Check for very Old customers

SELECT DISTINCT
bdate
FROM bronze.erp_cust_az12
WHERE bdate < '1924-01-01' OR bdate > GETDATE()

-- Standardization & Consistency
SELECT DISTINCT
gen,
CASE WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
		 WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
		 ELSE 'n/a'
	END AS gen
FROM bronze.erp_cust_az12


-- Clean & Load erp_loc_a101

SELECT
REPLACE (cid, '-', '') cid,
CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
	 WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
	 WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
	 ELSE TRIM(cntry)
END AS cntry,
cid,
cntry
FROM bronze.erp_loc_a101
WHERE REPLACE (cid, '-', '') NOT IN
(SELECT cst_key FROM silver.crm_cust_info);

-- Data Standardization & Consistency

SELECT DISTINCT cntry
FROM bronze.erp_loc_a101
ORDER BY cntry;

-- BRONZE Clean erp px cat g1v2

SELECT
id,
cat,
subcat,
maintenance
FROM bronze.erp_px_cat_g1v2;

-- check unwanted spaces
SELECT * FROM bronze.erp_px_cat_g1v2
WHERE cat != TRIM(cat) OR subcat != TRIM(subcat) OR maintenance != TRIM(maintenance)

-- Data Standardization & Consistency
SELECT DISTINCT
maintenance -- subcat, cat
FROM bronze.erp_px_cat_g1v2;





