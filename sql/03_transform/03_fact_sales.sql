-- ============================================================
-- 03_transform / 03_fact_sales.sql
-- Sales fact table — cleaned, typed, enriched
-- ============================================================

USE DATABASE SUPERMARKET_DB;
USE SCHEMA ANALYTICS;
USE WAREHOUSE SUPERMARKET_WH;

CREATE OR REPLACE TABLE FACT_SALES AS

WITH raw AS (
    SELECT
        TO_DATE(sale_date, 'YYYY-MM-DD')                          AS sale_date,
        TO_TIME(sale_time)                                         AS sale_time,
        HOUR(TO_TIME(sale_time))                                   AS sale_hour,
        item_code,
        quantity_sold_kg,
        unit_price_rmb_kg,

        -- Revenue = quantity × unit price
        ROUND(quantity_sold_kg * unit_price_rmb_kg, 4)             AS gross_revenue_rmb,

        -- Transaction type flags
        LOWER(TRIM(sale_or_return))                                AS txn_type,   -- 'sale' | 'return'
        IFF(LOWER(TRIM(sale_or_return)) = 'return', -1, 1)         AS txn_sign,   -- multiplier for aggregation

        IFF(UPPER(TRIM(discount_yn)) = 'YES', TRUE, FALSE)         AS has_discount

    FROM SUPERMARKET_DB.RAW.RAW_SALES
    WHERE sale_date IS NOT NULL
      AND quantity_sold_kg > 0           -- exclude zero-quantity noise
      AND unit_price_rmb_kg > 0
),

enriched AS (
    SELECT
        r.*,

        -- Date key for joining to DIM_DATE
        TO_CHAR(r.sale_date, 'YYYYMMDD')::NUMBER                   AS date_key,

        -- Join wholesale price for the same date (for margin calculation)
        wp.wholesale_price_rmb_kg,

        -- Gross margin per kg
        ROUND(r.unit_price_rmb_kg - COALESCE(wp.wholesale_price_rmb_kg, 0), 4)
                                                                   AS margin_per_kg,

        -- Gross margin %
        CASE
            WHEN COALESCE(wp.wholesale_price_rmb_kg, 0) > 0
            THEN ROUND(
                    (r.unit_price_rmb_kg - wp.wholesale_price_rmb_kg)
                    / wp.wholesale_price_rmb_kg * 100, 2)
            ELSE NULL
        END                                                        AS margin_pct,

        -- Loss-adjusted effective quantity
        ROUND(r.quantity_sold_kg * COALESCE(p.retention_factor, 1), 4)
                                                                   AS effective_qty_kg,

        -- Loss-adjusted revenue
        ROUND(r.quantity_sold_kg * COALESCE(p.retention_factor, 1)
              * r.unit_price_rmb_kg, 4)                            AS net_revenue_rmb

    FROM raw r

    LEFT JOIN SUPERMARKET_DB.RAW.RAW_WHOLESALE_PRICES wp
        ON  r.item_code = wp.item_code
        AND wp.price_date = TO_CHAR(r.sale_date, 'YYYY-MM-DD')

    LEFT JOIN DIM_PRODUCT p
        ON r.item_code = p.item_code
)

SELECT * FROM enriched;


-- ── Indexes / Clustering ──────────────────────────────────
-- Snowflake uses micro-partitioning; clustering key speeds time-range queries
ALTER TABLE FACT_SALES CLUSTER BY (sale_date, item_code);


-- ── Validation ────────────────────────────────────────────
-- Row count
SELECT COUNT(*) AS total_rows FROM FACT_SALES;

-- Date range
SELECT MIN(sale_date), MAX(sale_date) FROM FACT_SALES;

-- Revenue sanity check
SELECT
    SUM(gross_revenue_rmb)     AS total_gross_revenue,
    SUM(net_revenue_rmb)       AS total_net_revenue,
    COUNT(DISTINCT item_code)  AS unique_products,
    COUNT(DISTINCT sale_date)  AS trading_days
FROM FACT_SALES
WHERE txn_type = 'sale';
