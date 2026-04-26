-- Time-of-day dimension shared by 311 service requests and motor vehicle collisions.
-- Grain: one row per distinct (hour, minute) observed across both fact streams.

WITH all_times AS (

    -- Time component from 311 created_date (timestamp → time)
    SELECT DISTINCT
        EXTRACT(HOUR   FROM created_date) AS hour,
        EXTRACT(MINUTE FROM created_date) AS minute
    FROM {{ ref('stg_nyc_311_dot') }}
    WHERE created_date IS NOT NULL

    UNION DISTINCT

    -- Time from collisions crash_time
    SELECT DISTINCT
        EXTRACT(HOUR   FROM crash_time) AS hour,
        EXTRACT(MINUTE FROM crash_time) AS minute
    FROM {{ ref('stg_motor_vehicle_collisions') }}
    WHERE crash_time IS NOT NULL

),

