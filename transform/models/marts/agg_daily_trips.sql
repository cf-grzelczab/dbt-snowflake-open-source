with trips as (

    select * from {{ ref('fct_trips') }}

),

zones as (

    select * from {{ ref('dim_zones') }}

)

select
    trips.pickup_date,
    trips.pickup_borough,
    count(*) as trip_count,
    count_if(pickup_zones.is_airport or dropoff_zones.is_airport) as airport_trip_count,
    sum(trips.passenger_count) as passenger_count,
    sum(trips.trip_distance_miles) as trip_distance_miles,
    sum(trips.total_amount) as total_amount,
    avg(trips.fare_amount) as avg_fare_amount,
    avg(trips.trip_duration_minutes) as avg_trip_duration_minutes,
    div0(sum(trips.tip_amount), sum(trips.fare_amount)) as tip_rate
from trips
left join zones as pickup_zones
    on trips.pickup_location_id = pickup_zones.location_id
left join zones as dropoff_zones
    on trips.dropoff_location_id = dropoff_zones.location_id
group by trips.pickup_date, trips.pickup_borough
