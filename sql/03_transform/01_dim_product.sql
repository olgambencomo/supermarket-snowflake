-- ============================================================
-- 03_transform / 01_dim_product.sql
-- Product dimension — clean, typed, enriched with loss rates
-- ============================================================

USE DATABASE SUPERMARKET_DB;
USE SCHEMA ANALYTICS;
USE WAREHOUSE SUPERMARKET_WH;

CREATE OR REPLACE TABLE DIM_PRODUCT AS

SELECT
    p.item_code                                    AS item_code,
    TRIM(p.item_name)                              AS item_name,
    p.category_code                                AS category_code,
    TRIM(p.category_name)                          AS category_name,

    -- Friendly category slug for grouping/filtering
    CASE p.category_name
        WHEN 'Flower/Leaf Vegetables'       THEN 'leafy'
        WHEN 'Cabbage'                      THEN 'cabbage'
        WHEN 'Aquatic Tuberous Vegetables'  THEN 'aquatic'
        WHEN 'Solanum'                      THEN 'solanum'
        WHEN 'Capsicum'                     THEN 'capsicum'
        WHEN 'Edible Mushroom'              THEN 'mushroom'
        ELSE 'other'
    END                                            AS category_slug,

    -- Loss rate from annex4 (some items may not have it → NULL)
    lr.loss_rate_pct                               AS loss_rate_pct,

    -- Complement factor used in revenue calculations:
    -- effective_qty = quantity_sold * (1 - loss_rate_pct/100)
    ROUND(1 - COALESCE(lr.loss_rate_pct, 0) / 100, 6) AS retention_factor

FROM SUPERMARKET_DB.RAW.RAW_PRODUCTS p
LEFT JOIN SUPERMARKET_DB.RAW.RAW_LOSS_RATES lr
    ON p.item_code = lr.item_code

ORDER BY p.category_code, p.item_name;


-- ── Validation ────────────────────────────────────────────
-- Total products
SELECT COUNT(*) AS total_products FROM DIM_PRODUCT;

-- Products per category
SELECT category_name, COUNT(*) AS products
FROM DIM_PRODUCT
GROUP BY category_name
ORDER BY products DESC;

-- Products missing loss rate
SELECT COUNT(*) AS missing_loss_rate
FROM DIM_PRODUCT
WHERE loss_rate_pct IS NULL;
