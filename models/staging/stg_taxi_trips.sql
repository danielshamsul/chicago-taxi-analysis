SELECT
    unique_key,
    taxi_id,
    TIMESTAMP_TRUNC(trip_start_timestamp, MINUTE) AS trip_start,
    TIMESTAMP_TRUNC(trip_end_timestamp, MINUTE)   AS trip_end,
    DATETIME_DIFF(
        DATETIME(trip_end_timestamp),
        DATETIME(trip_start_timestamp),
        MINUTE
    ) AS trip_duration_minutes,
    trip_miles,
    fare,
    tips,
    tolls,
    extras,
    trip_total,
    payment_type,
    pickup_community_area,
    dropoff_community_area
FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
WHERE
    trip_start_timestamp IS NOT NULL
    AND trip_end_timestamp IS NOT NULL
    AND trip_end_timestamp > trip_start_timestamp
    AND trip_total >= 0
    AND taxi_id IS NOT NULL
