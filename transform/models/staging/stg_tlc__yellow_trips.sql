with source as (

    select * from {{ source('tlc', 'yellow_tripdata') }}

),

renamed as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'vendorid', 'tpep_pickup_datetime', 'tpep_dropoff_datetime',
            'pulocationid', 'dolocationid', 'passenger_count', 'trip_distance',
            'payment_type', 'fare_amount', 'tip_amount', 'total_amount'
        ]) }} as trip_id,

        vendorid::int as vendor_id,
        ratecodeid::int as rate_code_id,
        payment_type::int as payment_type_id,
        pulocationid::int as pickup_location_id,
        dolocationid::int as dropoff_location_id,

        tpep_pickup_datetime as pickup_at,
        tpep_dropoff_datetime as dropoff_at,

        passenger_count::int as passenger_count,
        trip_distance as trip_distance_miles,
        store_and_fwd_flag = 'Y' as is_store_and_forward,

        fare_amount,
        extra as extra_amount,
        mta_tax as mta_tax_amount,
        tip_amount,
        tolls_amount,
        improvement_surcharge as improvement_surcharge_amount,
        congestion_surcharge as congestion_surcharge_amount,
        airport_fee as airport_fee_amount,
        cbd_congestion_fee as cbd_congestion_fee_amount,
        total_amount,

        _source_file as source_file,
        _loaded_at as loaded_at

    from source

)

select * from renamed
-- The raw files contain a handful of exact duplicate rows
qualify row_number() over (partition by trip_id order by loaded_at desc) = 1
