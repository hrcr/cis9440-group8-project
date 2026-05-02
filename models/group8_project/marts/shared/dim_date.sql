-- Date dimension shared by 311 service requests and motor vehicle collisions.
-- Builds one row per distinct calendar date observed across both fact streams.

WITH all_dates AS (

    (
        -- Dates from 311 service requests (timestamp → date)
        SELECT DISTINCT CAST(created_date AS DATE) AS full_date
        FROM {{ ref('stg_nyc_311_dot') }}

        UNION DISTINCT

        -- Dates from motor vehicle collisions (already a date)
        SELECT DISTINCT crash_date AS full_date
        FROM {{ ref('stg_motor_vehicle_collisions') }}
    )

    UNION DISTINCT

    -- Sentinel NULL row for nullable date FKs in fact tables.
    SELECT CAST(NULL AS DATE) AS full_date

),

date_dimension AS (

    SELECT
        {{ dbt_utils.generate_surrogate_key(['full_date']) }} AS date_key,

        full_date,
        EXTRACT(DAY FROM full_date) AS day,
        EXTRACT(MONTH FROM full_date) AS month,
        FORMAT_DATE('%B', full_date) AS month_name,
        EXTRACT(QUARTER FROM full_date) AS quarter,
        EXTRACT(YEAR FROM full_date) AS year,

        EXTRACT(DAYOFWEEK FROM full_date) AS day_of_week,    -- 1 = Sunday
        FORMAT_DATE('%A', full_date)      AS day_name,

        CASE
            WHEN EXTRACT(DAYOFWEEK FROM full_date) IN (1, 7) THEN TRUE
            ELSE FALSE
        END AS is_weekend

    FROM all_dates

)

SELECT *
FROM date_dimension