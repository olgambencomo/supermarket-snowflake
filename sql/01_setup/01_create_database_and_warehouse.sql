-- ============================================================
-- 01_setup / 01_create_database_and_warehouse.sql
-- Run this script first using COMPUTE_WH (default trial warehouse)
-- ============================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;

-- Database
CREATE DATABASE SUPERMARKET_DB;

-- Schemas
USE DATABASE SUPERMARKET_DB;
CREATE SCHEMA RAW;
CREATE SCHEMA STAGING;
CREATE SCHEMA ANALYTICS;
CREATE SCHEMA REPORTING;

-- Dedicated warehouse
CREATE WAREHOUSE SUPERMARKET_WH
    WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND   = 60
    AUTO_RESUME    = TRUE;

-- Verify
SHOW SCHEMAS IN DATABASE SUPERMARKET_DB;
