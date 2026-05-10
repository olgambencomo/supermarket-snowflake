
-- 02_staging / 02_create_and_load_raw_tables.sql
-- Create raw tables and load data from internal stage
-- Run after uploading the 4 CSV files to SUPERMARKET_STAGE


USE DATABASE SUPERMARKET_DB;
USE SCHEMA RAW;
USE WAREHOUSE SUPERMARKET_WH;

-- Product catalog
CREATE OR REPLACE TABLE RAW_PRODUCTS (
    item_code      NUMBER,
    item_name      VARCHAR(200),
    category_code  NUMBER,
    category_name  VARCHAR(100)
);

COPY INTO RAW_PRODUCTS
FROM @SUPERMARKET_DB.RAW.SUPERMARKET_STAGE/annex1.csv
FILE_FORMAT = SUPERMARKET_DB.RAW.CSV_FORMAT;


-- Sales transactions
CREATE OR REPLACE TABLE RAW_SALES (
    sale_date           VARCHAR(10),
    sale_time           VARCHAR(30),
    item_code           NUMBER,
    quantity_sold_kg    FLOAT,
    unit_price_rmb_kg   FLOAT,
    sale_or_return      VARCHAR(20),
    discount_yn         VARCHAR(5)
);

COPY INTO RAW_SALES
FROM @SUPERMARKET_DB.RAW.SUPERMARKET_STAGE/annex2.csv
FILE_FORMAT = SUPERMARKET_DB.RAW.CSV_FORMAT;


-- Daily wholesale prices
CREATE OR REPLACE TABLE RAW_WHOLESALE_PRICES (
    price_date              VARCHAR(10),
    item_code               NUMBER,
    wholesale_price_rmb_kg  FLOAT
);

COPY INTO RAW_WHOLESALE_PRICES
FROM @SUPERMARKET_DB.RAW.SUPERMARKET_STAGE/annex3.csv
FILE_FORMAT = SUPERMARKET_DB.RAW.CSV_FORMAT;


-- Product loss/shrinkage rates
CREATE OR REPLACE TABLE RAW_LOSS_RATES (
    item_code       NUMBER,
    item_name       VARCHAR(200),
    loss_rate_pct   FLOAT
);

COPY INTO RAW_LOSS_RATES
FROM @SUPERMARKET_DB.RAW.SUPERMARKET_STAGE/annex4.csv
FILE_FORMAT = SUPERMARKET_DB.RAW.CSV_FORMAT;


-- Validation
SELECT 'RAW_PRODUCTS'         AS table_name, COUNT(*) AS rows FROM RAW_PRODUCTS         UNION ALL
SELECT 'RAW_SALES'            AS table_name, COUNT(*) AS rows FROM RAW_SALES             UNION ALL
SELECT 'RAW_WHOLESALE_PRICES' AS table_name, COUNT(*) AS rows FROM RAW_WHOLESALE_PRICES  UNION ALL
SELECT 'RAW_LOSS_RATES'       AS table_name, COUNT(*) AS rows FROM RAW_LOSS_RATES;

-- Expected results:
-- RAW_PRODUCTS            251
-- RAW_SALES           878,503
-- RAW_WHOLESALE_PRICES 55,982
-- RAW_LOSS_RATES          251

