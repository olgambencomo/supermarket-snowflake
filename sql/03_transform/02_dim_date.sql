-- ============================================================
-- 03_transform / 02_dim_date.sql
-- Date dimension — full calendar spine Jul 2020 – Jun 2023
-- ============================================================

USE DATABASE SUPERMARKET_DB;
USE SCHEMA ANALYTICS;
USE WAREHOUSE SUPERMARKET_WH;

CREATE OR REPLACE TABLE DIM_DATE AS

WITH date_spine AS (
    -- Generate one row per calendar day for the dataset range
    SELECT
        DATEADD(DAY, SEQ4(), '2020-07-01'::DATE) AS date_day
    FROM TABLE(GENERATOR(ROWCOUNT => 1096))   -- 3 years × 365 + 1 leap day
    WHERE date_day <= '2023-06-30'
)

SELECT
    date_day                                                AS date_day,
    TO_CHAR(date_day, 'YYYYMMDD')::NUMBER                  AS date_key,        -- surrogate key

    -- Calendar attributes
    YEAR(date_day)                                          AS year,
    QUARTER(date_day)                                       AS quarter_num,
    'Q' || QUARTER(date_day)                                AS quarter_label,
    MONTH(date_day)                                         AS month_num,
    TO_CHAR(date_day, 'Mon YYYY')                           AS month_label,
    WEEK(date_day)                                          AS week_of_year,
    DAYOFMONTH(date_day)                                    AS day_of_month,
    DAYOFWEEK(date_day)                                     AS day_of_week,     -- 0=Sun … 6=Sat
    DAYNAME(date_day)                                       AS day_name,

    -- Boolean helpers
    IFF(DAYOFWEEK(date_day) IN (0, 6), TRUE, FALSE)         AS is_weekend,

    -- Fiscal year (Jul–Jun, common in Asian retail)
    CASE
        WHEN MONTH(date_day) >= 7
        THEN YEAR(date_day) || '-' || (YEAR(date_day)+1)
        ELSE (YEAR(date_day)-1) || '-' || YEAR(date_day)
    END                                                     AS fiscal_year,

    -- Fiscal quarter within fiscal year
    CASE
        WHEN MONTH(date_day) IN (7, 8, 9)   THEN 'FQ1'
        WHEN MONTH(date_day) IN (10,11,12)  THEN 'FQ2'
        WHEN MONTH(date_day) IN (1, 2, 3)   THEN 'FQ3'
        WHEN MONTH(date_day) IN (4, 5, 6)   THEN 'FQ4'
    END                                                     AS fiscal_quarter,

    -- Season (Northern Hemisphere)
    CASE
        WHEN MONTH(date_day) IN (12, 1, 2)  THEN 'Winter'
        WHEN MONTH(date_day) IN (3, 4, 5)   THEN 'Spring'
        WHEN MONTH(date_day) IN (6, 7, 8)   THEN 'Summer'
        WHEN MONTH(date_day) IN (9,10,11)   THEN 'Autumn'
    END                                                     AS season

FROM date_spine;


-- ── Validation ────────────────────────────────────────────
SELECT COUNT(*) AS total_days FROM DIM_DATE;  -- should be ~1096

SELECT fiscal_year, COUNT(*) AS days
FROM DIM_DATE
GROUP BY fiscal_year
ORDER BY fiscal_year;
