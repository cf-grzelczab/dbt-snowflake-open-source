# dbt-snowflake-open-source

Sample dbt + Snowflake project built on public open data: NYC TLC yellow taxi trip records
([source and terms](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page)).

```
snowflake/   setup SQL: raw schema, parquet file format, stage, raw table
ingestion/   Python loader: download monthly parquet -> PUT to stage -> COPY INTO
transform/   dbt project: sources -> staging -> intermediate -> marts, seeds, snapshot, tests
```

## Setup

You need a Snowflake role that can create schemas, stages, tables and views in one database.

1. Copy `.env.example` to `.env` and fill in your account, user, role, warehouse, database and schemas.
   `.env` is git-ignored, so credentials and account details stay on your machine.
2. Create a virtual environment and install dependencies:

   ```powershell
   python -m venv .venv
   .\.venv\Scripts\Activate.ps1      # macOS/Linux: source .venv/bin/activate
   pip install -r requirements.txt
   ```

3. Create the raw objects and load one month of trips (SSO opens a browser once):

   ```powershell
   python ingestion/load_nyc_taxi.py setup
   python ingestion/load_nyc_taxi.py load 2024-01
   ```

4. Run dbt from `transform/`. `dotenv run` loads `.env` into the environment that `profiles.yml` reads from:

   ```powershell
   cd transform
   dotenv -f ../.env run -- dbt deps
   dotenv -f ../.env run -- dbt debug
   dotenv -f ../.env run -- dbt build
   dotenv -f ../.env run -- dbt source freshness
   dotenv -f ../.env run -- dbt docs generate
   ```

Load another month (`load 2024-02`) and run `dbt build` again to see the incremental `fct_trips` pick up only the new file.

## Models

| Layer | Model | Notes |
| --- | --- | --- |
| staging | `stg_tlc__yellow_trips` | renamed and typed, surrogate `trip_id`, exact duplicates removed |
| staging | `stg_tlc__taxi_zones` | from the `taxi_zone_lookup` seed |
| intermediate | `int_trips__enriched` | joins zones and code lookups, adds duration and data-quality flags |
| marts | `fct_trips` | incremental merge on `trip_id`, valid trips only |
| marts | `dim_zones` | zones with an airport flag |
| marts | `agg_daily_trips` | daily trips and revenue per pickup borough |
| snapshot | `snap_taxi_zones` | SCD type 2 history of the zone lookup |