-- Creates the raw landing area for the NYC taxi data.
-- The dollar-brace placeholders are filled from .env by ingestion/load_nyc_taxi.py.

USE ROLE ${SNOWFLAKE_ROLE};
USE WAREHOUSE ${SNOWFLAKE_WAREHOUSE};
USE DATABASE ${SNOWFLAKE_DATABASE};

CREATE SCHEMA IF NOT EXISTS ${SNOWFLAKE_RAW_SCHEMA}
    COMMENT = 'Raw NYC TLC trip record files, loaded as-is';
CREATE SCHEMA IF NOT EXISTS ${SNOWFLAKE_SCHEMA}
    COMMENT = 'dbt models for the NYC taxi course project';

USE SCHEMA ${SNOWFLAKE_RAW_SCHEMA};

CREATE FILE FORMAT IF NOT EXISTS FF_PARQUET
    TYPE = PARQUET
    USE_LOGICAL_TYPE = TRUE;

CREATE STAGE IF NOT EXISTS STG_NYC_TAXI
    FILE_FORMAT = FF_PARQUET
    COMMENT = 'Internal stage for TLC parquet files downloaded from the public CDN';

-- Column names follow the TLC parquet files; loaded with MATCH_BY_COLUMN_NAME.
CREATE TABLE IF NOT EXISTS YELLOW_TRIPDATA (
    VENDORID                NUMBER,
    TPEP_PICKUP_DATETIME    TIMESTAMP_NTZ,
    TPEP_DROPOFF_DATETIME   TIMESTAMP_NTZ,
    PASSENGER_COUNT         NUMBER,
    TRIP_DISTANCE           FLOAT,
    RATECODEID              NUMBER,
    STORE_AND_FWD_FLAG      VARCHAR,
    PULOCATIONID            NUMBER,
    DOLOCATIONID            NUMBER,
    PAYMENT_TYPE            NUMBER,
    FARE_AMOUNT             FLOAT,
    EXTRA                   FLOAT,
    MTA_TAX                 FLOAT,
    TIP_AMOUNT              FLOAT,
    TOLLS_AMOUNT            FLOAT,
    IMPROVEMENT_SURCHARGE   FLOAT,
    TOTAL_AMOUNT            FLOAT,
    CONGESTION_SURCHARGE    FLOAT,
    AIRPORT_FEE             FLOAT,
    CBD_CONGESTION_FEE      FLOAT,
    _SOURCE_FILE            VARCHAR,
    _LOADED_AT              TIMESTAMP_LTZ
);
