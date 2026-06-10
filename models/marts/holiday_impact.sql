WITH daily_trips AS (
    SELECT
        DATE(trip_start)                                AS trip_date,
        COUNT(*)                                        AS total_trips,
        FORMAT_DATE('%A', DATE(trip_start))             AS day_of_week,
        EXTRACT(DAYOFWEEK FROM DATE(trip_start))        AS day_number
    FROM {{ ref('stg_taxi_trips') }}
    GROUP BY
        DATE(trip_start),
        FORMAT_DATE('%A', DATE(trip_start)),
        EXTRACT(DAYOFWEEK FROM DATE(trip_start))
),
holidays AS (
    SELECT DATE(holiday_date) AS holiday_date, holiday_name
    FROM UNNEST([
        -- 2022 Holidays
        STRUCT(DATE '2022-01-01' AS holiday_date, 'New Years Day' AS holiday_name),
        STRUCT(DATE '2022-07-04', 'Independence Day'),
        STRUCT(DATE '2022-11-24', 'Thanksgiving'),
        STRUCT(DATE '2022-12-25', 'Christmas'),
        -- 2023 Holidays
        STRUCT(DATE '2023-01-01', 'New Years Day'),
        STRUCT(DATE '2023-07-04', 'Independence Day'),
        STRUCT(DATE '2023-11-23', 'Thanksgiving'),
        STRUCT(DATE '2023-12-25', 'Christmas')
    ])
)
SELECT
    d.trip_date,
    d.day_of_week,
    d.day_number,
    d.total_trips,
    CASE
        WHEN h.holiday_date IS NOT NULL THEN 'Holiday'
        WHEN d.day_number IN (1, 7)     THEN 'Weekend'
        ELSE                                 'Weekday'
    END AS day_type,
    CASE
        WHEN h.holiday_date IS NOT NULL THEN TRUE
        ELSE FALSE
    END AS is_holiday,
    h.holiday_name
FROM daily_trips d
LEFT JOIN holidays h ON d.trip_date = h.holiday_date
ORDER BY trip_date
