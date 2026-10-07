{% docs __overview__ %}
# NYC taxi course project

Yellow taxi trips published by the NYC Taxi & Limousine Commission (TLC),
loaded into Snowflake and modelled with dbt:

- **staging**: one model per source table, renamed and typed
- **intermediate**: trips joined to zones and lookups, with data-quality flags
- **marts**: `fct_trips` (incremental), `dim_zones`, `agg_daily_trips`
{% enddocs %}
