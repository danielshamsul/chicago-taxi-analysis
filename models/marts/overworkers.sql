WITH trip_gaps AS (
    SELECT
        taxi_id,
        trip_start,
        trip_end,
        LAG(trip_end) OVER (PARTITION BY taxi_id ORDER BY trip_start) AS prev_trip_end,
        TIMESTAMP_DIFF(
            trip_start,
            LAG(trip_end) OVER (PARTITION BY taxi_id ORDER BY trip_start),
            MINUTE
        ) AS break_minutes
    FROM {{ ref('stg_taxi_trips') }}
),
overwork_flags AS (
    SELECT
        taxi_id,
        COUNT(*)               AS trips_with_short_break,
        AVG(break_minutes)     AS avg_break_minutes
    FROM trip_gaps
    WHERE break_minutes IS NOT NULL AND break_minutes < 480
    GROUP BY taxi_id
)
SELECT *
FROM overwork_flags
ORDER BY trips_with_short_break DESC
LIMIT 100
