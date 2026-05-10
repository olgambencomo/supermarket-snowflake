
-- 04_analytics / 01_sales_kpis.sql
-- Revenue, volume and transaction KPIs


USE DATABASE SUPERMARKET_DB;
USE SCHEMA REPORTING;
USE WAREHOUSE SUPERMARKET_WH;

-- Overall summary
SELECT
    COUNT(*)                                                      AS total_transactions,
    COUNT(DISTINCT sale_date)                                     AS trading_days,
    COUNT(DISTINCT item_code)                                     AS active_skus,
    ROUND(SUM(quantity_sold_kg), 0)                               AS total_volume_kg,
    ROUND(SUM(gross_revenue_rmb), 0)                              AS total_gross_revenue_rmb,
    ROUND(AVG(unit_price_rmb_kg), 2)                              AS avg_selling_price,
    ROUND(SUM(gross_revenue_rmb) / COUNT(DISTINCT sale_date), 0)  AS avg_daily_revenue_rmb,
    ROUND(SUM(IFF(has_discount, 1, 0)) / COUNT(*) * 100, 2)       AS discount_rate_pct,
    ROUND(SUM(IFF(txn_type='return', 1, 0)) / COUNT(*) * 100, 2) AS return_rate_pct
FROM SUPERMARKET_DB.ANALYTICS.FACT_SALES
WHERE txn_type = 'sale';


-- Monthly revenue trend with month-over-month growth
CREATE OR REPLACE VIEW VW_MONTHLY_REVENUE AS
SELECT
    DATE_TRUNC('MONTH', f.sale_date)             AS month,
    ROUND(SUM(f.gross_revenue_rmb), 2)           AS revenue,
    ROUND(SUM(f.quantity_sold_kg), 2)            AS volume_kg,
    COUNT(*)                                     AS transactions,
    LAG(SUM(f.gross_revenue_rmb)) OVER (
        ORDER BY DATE_TRUNC('MONTH', f.sale_date)
    )                                            AS prev_month_revenue,
    ROUND(
        (SUM(f.gross_revenue_rmb)
         - LAG(SUM(f.gross_revenue_rmb)) OVER (ORDER BY DATE_TRUNC('MONTH', f.sale_date)))
        / NULLIF(LAG(SUM(f.gross_revenue_rmb)) OVER (ORDER BY DATE_TRUNC('MONTH', f.sale_date)), 0)
        * 100, 2
    )                                            AS mom_growth_pct
FROM SUPERMARKET_DB.ANALYTICS.FACT_SALES f
WHERE f.txn_type = 'sale'
GROUP BY month
ORDER BY month;

SELECT * FROM VW_MONTHLY_REVENUE;


-- Revenue by category
CREATE OR REPLACE VIEW VW_REVENUE_BY_CATEGORY AS
SELECT
    p.category_name,
    p.category_slug,
    ROUND(SUM(f.gross_revenue_rmb), 2)           AS revenue_total,
    ROUND(SUM(f.quantity_sold_kg), 2)            AS volume_kg,
    COUNT(*)                                     AS transactions,
    COUNT(DISTINCT f.item_code)                  AS sku_count,
    ROUND(AVG(f.unit_price_rmb_kg), 2)           AS avg_price_per_kg,
    ROUND(
        SUM(f.gross_revenue_rmb)
        / SUM(SUM(f.gross_revenue_rmb)) OVER () * 100, 2
    )                                            AS revenue_share_pct
FROM SUPERMARKET_DB.ANALYTICS.FACT_SALES f
JOIN SUPERMARKET_DB.ANALYTICS.DIM_PRODUCT p ON f.item_code = p.item_code
WHERE f.txn_type = 'sale'
GROUP BY p.category_name, p.category_slug
ORDER BY revenue_total DESC;

SELECT * FROM VW_REVENUE_BY_CATEGORY;


-- Sales by day of week
CREATE OR REPLACE VIEW VW_SALES_BY_WEEKDAY AS
SELECT
    DAYNAME(f.sale_date)                                          AS day_name,
    DAYOFWEEK(f.sale_date)                                        AS day_num,
    IFF(DAYOFWEEK(f.sale_date) IN (0,6), 'Weekend', 'Weekday')   AS day_type,
    COUNT(*)                                                      AS transactions,
    ROUND(SUM(f.gross_revenue_rmb), 2)                            AS revenue_total,
    ROUND(AVG(f.gross_revenue_rmb), 4)                            AS avg_ticket,
    ROUND(AVG(f.quantity_sold_kg), 4)                             AS avg_qty_kg,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER () * 100, 2)              AS pct_transactions
FROM SUPERMARKET_DB.ANALYTICS.FACT_SALES f
WHERE f.txn_type = 'sale'
GROUP BY day_name, day_num, day_type
ORDER BY day_num;

SELECT * FROM VW_SALES_BY_WEEKDAY;
