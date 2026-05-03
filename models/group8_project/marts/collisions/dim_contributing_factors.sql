-- Contributing factor dimension for motor vehicle collisions
-- Grain: one row per distinct contributing-factor value

WITH factors AS (

    SELECT contributing_factor_vehicle_1 AS contributing_factor_for_vehicle
    FROM {{ ref('stg_group8_motor_vehicle_collisions') }}

    UNION DISTINCT

    SELECT contributing_factor_vehicle_2
    FROM {{ ref('stg_group8_motor_vehicle_collisions') }}

    UNION DISTINCT

    SELECT contributing_factor_vehicle_3
    FROM {{ ref('stg_group8_motor_vehicle_collisions') }}

    UNION DISTINCT

    SELECT contributing_factor_vehicle_4
    FROM {{ ref('stg_group8_motor_vehicle_collisions') }}

    UNION DISTINCT

    SELECT contributing_factor_vehicle_5
    FROM {{ ref('stg_group8_motor_vehicle_collisions') }}

),

distinct_factors AS (

    SELECT DISTINCT
        CASE
            WHEN contributing_factor_for_vehicle IS NULL THEN NULL
            WHEN TRIM(contributing_factor_for_vehicle) = '' THEN NULL
            WHEN UPPER(TRIM(contributing_factor_for_vehicle)) IN ('1', '80') THEN NULL
            WHEN UPPER(TRIM(contributing_factor_for_vehicle)) = 'ILLNES' THEN 'Illness'
            WHEN UPPER(TRIM(contributing_factor_for_vehicle)) = 'REACTION TO OTHER UNINVOLVED VEHICLE' THEN 'Reaction to Uninvolved Vehicle'
            WHEN UPPER(TRIM(contributing_factor_for_vehicle)) = 'DRUGS (ILLEGAL)' THEN 'Drugs (illegal)'
            WHEN UPPER(TRIM(contributing_factor_for_vehicle)) = 'CELL PHONE (HAND-HELD)' THEN 'Cell Phone (hand-held)'
            ELSE TRIM(contributing_factor_for_vehicle)
        END AS contributing_factor_for_vehicle
    FROM factors

)

SELECT
    {{ dbt_utils.generate_surrogate_key(['contributing_factor_for_vehicle']) }} AS contributing_factor_vehicle_key,
    contributing_factor_for_vehicle
FROM distinct_factors