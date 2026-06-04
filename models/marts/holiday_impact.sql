WITH daily_trips AS (
    SELECT
        DATE(trip_start) AS trip_date,
        COUNT(*)         AS total_trips
    FROM {{ ref('stg_taxi_trips') }}
    GROUP BY trip_date
),
holidays AS (
    SELECT DATE(holiday_date) AS holiday_date, holiday_name
    FROM UNNEST([
        STRUCT(DATE '2023-01-01' AS holiday_date, 'New Years Day' AS holiday_name),
        STRUCT(DATE '2023-07-04', 'Independence Day'),
        STRUCT(DATE '2023-11-23', 'Thanksgiving'),
        STRUCT(DATE '2023-12-25', 'Christmas'),
        STRUCT(DATE '2024-01-01', 'New Years Day'),
        STRUCT(DATE '2024-07-04', 'Independence Day'),
        STRUCT(DATE '2024-11-28', 'Thanksgiving'),
        STRUCT(DATE '2024-12-25', 'Christmas')
    ])
)
SELECT
    d.trip_date,
    d.total_trips,
    CASE WHEN h.holiday_date IS NOT NULL THEN TRUE ELSE FALSE END AS is_holiday,
    h.holiday_name
FROM daily_trips d
LEFT JOIN holidays h ON d.trip_date = h.holiday_date
ORDER BY trip_date
