select
    locationid::int as location_id,
    coalesce(nullif(borough, 'N/A'), 'Unknown') as borough,
    coalesce(nullif(zone, 'N/A'), 'Unknown') as zone_name,
    coalesce(nullif(service_zone, 'N/A'), 'Unknown') as service_zone
from {{ ref('taxi_zone_lookup') }}
