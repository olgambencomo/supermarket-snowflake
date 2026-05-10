-- ABC Product Segmentation by Revenue Contribution
--
-- A = top 70% of cumulative revenue  (vital few)
-- B = next 20%                       (important)
-- C = remaining 10%                  (trivial many)


USE DATABASE SUPERMARKET_DB;
USE SCHEMA REPORTING;
USE WAREHOUSE SUPERMARKET_WH;

CREATE OR REPLACE VIEW VW_ABC_CLASSIFICATION AS

WITH product_revenue AS (
    -- Total revenue per product (sales only, 3-year period)
    SELECT
        f.item_code,
        p.item_name,
        p.category_name,
        p.category_slug,
        p.loss_rate_pct,
        ROUND(SUM(f.gross_revenue_rmb), 2)      AS total_revenue,
        ROUND(SUM(f.quantity_sold_kg), 2)       AS total_volume_kg,
        COUNT(*)                                AS transactions,
        COUNT(DISTINCT f.sale_date)             AS active_days
    FROM ANALYTICS.FACT_SALES f
    JOIN ANALYTICS.DIM_PRODUCT p ON f.item_code = p.item_code
    WHERE f.txn_type = 'sale'
    GROUP BY f.item_code, p.item_name, p.category_name, p.category_slug, p.loss_rate_pct
),

ranked AS (
    SELECT
        *,
        -- Running cumulative revenue share
        SUM(total_revenue) OVER (ORDER BY total_revenue DESC
                                  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
                                                AS cumulative_revenue,
        SUM(total_revenue) OVER ()              AS grand_total_revenue,
        ROUND(total_revenue
              / SUM(total_revenue) OVER () * 100, 4)
                                                AS revenue_share_pct,
        ROW_NUMBER() OVER (ORDER BY total_revenue DESC)
                                                AS revenue_rank
    FROM product_revenue
)

SELECT
    revenue_rank,
    item_code,
    item_name,
    category_name,
    category_slug,
    total_revenue,
    total_volume_kg,
    transactions,
    active_days,
    loss_rate_pct,
    revenue_share_pct,
    ROUND(cumulative_revenue / grand_total_revenue * 100, 2) AS cumulative_share_pct,

    -- ABC classification
    CASE
        WHEN cumulative_revenue / grand_total_revenue <= 0.70 THEN 'A'
        WHEN cumulative_revenue / grand_total_revenue <= 0.90 THEN 'B'
        ELSE 'C'
    END                                         AS abc_class,

    -- Velocity class (daily sales rate)
    CASE
        WHEN total_volume_kg / NULLIF(active_days, 0) >= 5   THEN 'Fast'
        WHEN total_volume_kg / NULLIF(active_days, 0) >= 1   THEN 'Medium'
        ELSE 'Slow'
    END                                         AS velocity_class

FROM ranked;


--Summary: how many SKUs per class? 
SELECT
    abc_class,
    COUNT(*)                                    AS sku_count,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER () * 100, 1)
                                                AS sku_pct,
    ROUND(SUM(revenue_share_pct), 1)            AS revenue_pct
FROM VW_ABC_CLASSIFICATION
GROUP BY abc_class
ORDER BY abc_class;

--Cross-tab: ABC × Category 
SELECT
    category_name,
    SUM(IFF(abc_class='A', 1, 0))              AS class_A,
    SUM(IFF(abc_class='B', 1, 0))              AS class_B,
    SUM(IFF(abc_class='C', 1, 0))              AS class_C
FROM VW_ABC_CLASSIFICATION
GROUP BY category_name
ORDER BY category_name;
