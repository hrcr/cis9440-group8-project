-- Time-of-day dimension shared by 311 service requests and motor vehicle collisions.
-- Grain: one row per distinct (hour, minute) observed across both fact streams.
-- Covers: created_date, closed_date, due_date, resolution_action_date (311)
--         and crash_time (collisions).

WITH all_times AS (

    (
        -- Time from 311 created_date (timestamp → time)
        SELECT DISTINCT
            EXTRACT(HOUR   FROM created_date) AS hour,
            EXTRACT(MINUTE FROM created_date) AS minute
        FROM {{ ref('stg_nyc_311_dot') }}

        UNION DISTINCT

        -- Time from 311 closed_date (NULL when still open)
        SELECT DISTINCT
            EXTRACT(HOUR   FROM closed_date) AS hour,
            EXTRACT(MINUTE FROM closed_date) AS minute
        FROM {{ ref('stg_nyc_311_dot') }}
        WHERE closed_date IS NOT NULL

        UNION DISTINCT

        -- Time from 311 due_date (NULL when not set)
        SELECT DISTINCT
            EXTRACT(HOUR   FROM due_date) AS hour,
            EXTRACT(MINUTE FROM due_date) AS minute
        FROM {{ ref('stg_nyc_311_dot') }}
        WHERE due_date IS NOT NULL

        UNION DISTINCT

        -- Time from 311 resolution_action_date (NULL when not set)
        SELECT DISTINCT
            EXTRACT(HOUR   FROM resolution_action_date) AS hour,
            EXTRACT(MINUTE FROM resolution_action_date) AS minute
        FROM {{ ref('stg_nyc_311_dot') }}
        WHERE resolution_action_date IS NOT NULL

        UNION DISTINCT

        -- Time from collisions crash_time
        SELECT DISTINCT
            EXTRACT(HOUR   FROM crash_time) AS hour,
            EXTRACT(MINUTE FROM crash_time) AS minute
        FROM {{ ref('stg_motor_vehicle_collisions') }}
    )

    UNION DISTINCT

    -- Sentinel NULL row for any nullable time FK in fact tables.
    SELECT NULL AS hour, NULL AS minute

),

time_dimension AS (

    SELECT
        {{ dbt_utils.generate_surrogate_key(['hour', 'minute']) }} AS time_key,
        hour,
        minute,
        CASE
            WHEN hour BETWEEN 5  AND 11 THEN 'Morning'
            WHEN hour BETWEEN 12 AND 16 THEN 'Afternoon'
            WHEN hour BETWEEN 17 AND 20 THEN 'Evening'
            ELSE                             'Night'
        END AS time_period
    FROM all_times

)

SELECT *
FROM time_dimension