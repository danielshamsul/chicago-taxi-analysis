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
        ) AS gap_minutes
    FROM {{ ref('stg_taxi_trips') }}
),
shift_boundaries AS (
    -- Only keep gaps that are long enough to represent end of a shift
    -- A gap >= 300 minutes (5 hours) means the driver likely stopped working
    SELECT
        taxi_id,
        prev_trip_end AS shift_end,
        trip_start    AS next_shift_start,
        gap_minutes   AS rest_minutes
    FROM trip_gaps
    WHERE gap_minutes >= 300  -- 5 hours = end of shift marker
),
insufficient_rest AS (
    SELECT
        taxi_id,
        COUNT(*)             AS shifts_with_short_rest,
        ROUND(AVG(rest_minutes), 2) AS avg_rest_minutes,
        ROUND(MIN(rest_minutes), 2) AS min_rest_minutes
    FROM shift_boundaries
    WHERE rest_minutes < 480  -- Less than 8 hours rest between shifts
    GROUP BY taxi_id
)
SELECT *
FROM insufficient_rest
ORDER BY shifts_with_short_rest DESC
LIMIT 100
