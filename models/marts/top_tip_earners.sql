SELECT
    taxi_id,
    COUNT(*)                  AS total_trips,
    ROUND(SUM(tips), 2)       AS total_tips,
    ROUND(AVG(tips), 2)       AS avg_tip_per_trip,
    ROUND(SUM(trip_total), 2) AS total_revenue
FROM {{ ref('stg_taxi_trips') }}
WHERE trip_start >= TIMESTAMP_SUB(
    (SELECT MAX(trip_start) FROM {{ ref('stg_taxi_trips') }}),
    INTERVAL 90 DAY
)
GROUP BY taxi_id
ORDER BY total_tips DESC
LIMIT 100
