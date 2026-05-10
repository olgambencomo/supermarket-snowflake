
-- 04_analytics / 02_margin_analysis.sql
-- Gross margin analysis by category and time


USE DATABASE SUPERMARKET_DB;
USE SCHEMA REPORTING;
USE WAREHOUSE SUPERMARKET_WH;

-- 1. Monthly Margin Trend by Category

CREATE OR REPLACE VIEW VW_MARGIN_TREND AS
SELECT
    DATE_TRUNC('MONTH', f.sale_date)             AS month_start,
    p.category_name,
    ROUND(AVG(f.margin_pct), 2)                  AS avg_margin_pct,
    ROUND(SUM(f.gross_revenue_rmb)
          - SUM(f.quantity_sold_kg * f.wholesale_price_rmb_kg), 2)
                                                 AS total_gross_profit,
    ROUND(SUM(f.gross_revenue_rmb), 2)           AS total_revenue
FROM ANALYTICS.FACT_SALES f
JOIN ANALYTICS.DIM_PRODUCT p ON f.item_code = p.item_code
WHERE f.txn_type = 'sale'
  AND f.wholesale_price_rmb_kg IS NOT NULL
GROUP BY month_start, p.category_name
ORDER BY month_start, p.category_name;

SELECT * FROM VW_MARGIN_TREND;



-- 2. Price vs Wholesale spread (price compression check)


SELECT
    DATE_TRUNC('MONTH', sale_date)               AS month_start,
    ROUND(AVG(unit_price_rmb_kg), 3)             AS avg_selling_price,
    ROUND(AVG(wholesale_price_rmb_kg), 3)        AS avg_wholesale_price,
    ROUND(AVG(unit_price_rmb_kg)
          - AVG(wholesale_price_rmb_kg), 3)      AS avg_spread,
    ROUND(
        (AVG(unit_price_rmb_kg) - AVG(wholesale_price_rmb_kg))
        / NULLIF(AVG(wholesale_price_rmb_kg), 0) * 100, 2
    )                                            AS spread_pct
FROM ANALYTICS.FACT_SALES
WHERE txn_type = 'sale'
  AND wholesale_price_rmb_kg IS NOT NULL
GROUP BY month_start
ORDER BY month_start;
