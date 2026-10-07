{{
    config(
        materialized='incremental',
        unique_key='trip_id',
        incremental_strategy='merge',
        on_schema_change='append_new_columns',
        cluster_by=['pickup_date']
    )
}}

select
    trip_id,
    pickup_at,
    dropoff_at,
    pickup_date,
    pickup_hour,
    pickup_day_of_week,
    is_weekend_pickup,
    trip_duration_minutes,
    vendor_name,
    rate_code,
    payment_type,
    pickup_location_id,
    dropoff_location_id,
    pickup_borough,
    dropoff_borough,
    passenger_count,
    trip_distance_miles,
    fare_amount,
    tip_amount,
    tolls_amount,
    total_amount,
    loaded_at
from {{ ref('int_trips__enriched') }}
where is_valid_trip

{% if is_incremental() %}
    -- Only process files loaded since the last run
    and loaded_at > (select max(loaded_at) from {{ this }})
{% endif %}
