select
    pickup_date,
    pickup_borough,
    count(*) as trip_count,
    sum(passenger_count) as passenger_count,
    sum(trip_distance_miles) as trip_distance_miles,
    sum(total_amount) as total_amount,
    avg(fare_amount) as avg_fare_amount,
    avg(trip_duration_minutes) as avg_trip_duration_minutes,
    div0(sum(tip_amount), sum(fare_amount)) as tip_rate
from {{ ref('fct_trips') }}
group by pickup_date, pickup_borough
