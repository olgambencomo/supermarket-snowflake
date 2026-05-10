
-- 02_staging / 01_create_stage_and_file_formats.sql
-- Creates the CSV file format and internal stage


USE DATABASE SUPERMARKET_DB;
USE SCHEMA RAW;
USE WAREHOUSE SUPERMARKET_WH;

CREATE OR REPLACE FILE FORMAT CSV_FORMAT
    TYPE             = 'CSV'
    FIELD_DELIMITER  = ','
    SKIP_HEADER      = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    NULL_IF          = ('NULL', 'null', 'N/A', '')
    EMPTY_FIELD_AS_NULL = TRUE
    TRIM_SPACE       = TRUE;

CREATE OR REPLACE STAGE SUPERMARKET_STAGE
    FILE_FORMAT = SUPERMARKET_DB.RAW.CSV_FORMAT;

-- After running this script:
-- 1. Go to Data → Databases → SUPERMARKET_DB → RAW → Stages
-- 2. Click SUPERMARKET_STAGE
-- 3. Click + Files and upload the 4 CSV files from Kaggle

-- Verify files were uploaded
-- LIST @SUPERMARKET_DB.RAW.SUPERMARKET_STAGE;
