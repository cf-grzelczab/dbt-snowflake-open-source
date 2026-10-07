with trips as (

    select * from {{ ref('stg_tlc__yellow_trips') }}

),

zones as (

    select * from {{ ref('stg_tlc__taxi_zones') }}

),

enriched as (

    select
        trips.trip_id,
        trips.pickup_at,
        trips.dropoff_at,
        trips.pickup_at::date as pickup_date,
        hour(trips.pickup_at) as pickup_hour,
        dayname(trips.pickup_at) as pickup_day_of_week,
        dayofweekiso(trips.pickup_at) in (6, 7) as is_weekend_pickup,
        datediff('second', trips.pickup_at, trips.dropoff_at) / 60.0 as trip_duration_minutes,

        trips.vendor_id,
        coalesce(vendors.vendor_name, 'Unknown') as vendor_name,
        trips.rate_code_id,
        coalesce(rate_codes.rate_code, 'Unknown') as rate_code,
        trips.payment_type_id,
        coalesce(payment_types.payment_type, 'Unknown') as payment_type,

        trips.pickup_location_id,
        pickup_zones.borough as pickup_borough,
        pickup_zones.zone_name as pickup_zone,
        trips.dropoff_location_id,
        dropoff_zones.borough as dropoff_borough,
        dropoff_zones.zone_name as dropoff_zone,

        trips.passenger_count,
        trips.trip_distance_miles,
        trips.fare_amount,
        trips.extra_amount,
        trips.mta_tax_amount,
        trips.tip_amount,
        trips.tolls_amount,
        trips.improvement_surcharge_amount,
        trips.congestion_surcharge_amount,
        trips.airport_fee_amount,
        trips.cbd_congestion_fee_amount,
        trips.total_amount,

        -- Each monthly file also contains a few trips from other months
        date_trunc('month', trips.pickup_at)
            = to_date(regexp_substr(trips.source_file, '\\d{4}-\\d{2}'), 'YYYY-MM') as is_in_file_period,
        trips.dropoff_at > trips.pickup_at
            and datediff('hour', trips.pickup_at, trips.dropoff_at) < 24
            and trips.trip_distance_miles > 0
            and trips.trip_distance_miles < 500
            and trips.total_amount >= 0 as is_plausible_trip,

        trips.source_file,
        trips.loaded_at

    from trips
    left join zones as pickup_zones
        on trips.pickup_location_id = pickup_zones.location_id
    left join zones as dropoff_zones
        on trips.dropoff_location_id = dropoff_zones.location_id
    left join {{ ref('vendors') }} as vendors
        on trips.vendor_id = vendors.vendor_id
    left join {{ ref('rate_codes') }} as rate_codes
        on trips.rate_code_id = rate_codes.rate_code_id
    left join {{ ref('payment_types') }} as payment_types
        on trips.payment_type_id = payment_types.payment_type_id

)

select
    *,
    is_in_file_period and is_plausible_trip as is_valid_trip
from enriched
