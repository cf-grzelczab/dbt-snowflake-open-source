select
    pickup_day_of_week,
    pickup_hour,
    is_weekend_pickup,
    count(*) as trip_count,
    count(distinct pickup_date) as day_count,
    trip_count / day_count as avg_trips_per_day,
    avg(trip_duration_minutes) as avg_trip_duration_minutes,
    avg(trip_distance_miles) as avg_trip_distance_miles,
    avg(total_amount) as avg_total_amount
from {{ ref('fct_trips') }}
group by pickup_day_of_week, pickup_hour, is_weekend_pickup
