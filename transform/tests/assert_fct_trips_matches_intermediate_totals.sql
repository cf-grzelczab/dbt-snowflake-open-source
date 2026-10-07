-- Totals-match check: every valid trip and dollar in the intermediate layer must reach fct_trips.
with expected as (
    select count(*) as trip_count, sum(total_amount::number(38, 2)) as total_amount
    from {{ ref('int_trips__enriched') }}
    where is_valid_trip
),

actual as (
    select count(*) as trip_count, sum(total_amount::number(38, 2)) as total_amount
    from {{ ref('fct_trips') }}
)

select
    expected.trip_count as expected_trip_count,
    actual.trip_count as actual_trip_count,
    expected.total_amount as expected_total_amount,
    actual.total_amount as actual_total_amount
from expected
cross join actual
where expected.trip_count != actual.trip_count
    or expected.total_amount != actual.total_amount
