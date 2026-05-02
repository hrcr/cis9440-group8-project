-- Contributing factor dimension for motor vehicle collisions.
-- Grain: one row per distinct contributing-factor value (NULL included).
--
-- NOTE: NULL is intentionally retained as a dim row. Most collisions involve
-- fewer than 5 vehicles, so contributing_factor_vehicle_3/4/5 are NULL in
-- staging. Keeping the NULL row makes those "Unknown" cases visible in
-- dimension-level analysis even though, with the lookup-join pattern in the
-- fact table, NULL staging values produce NULL FKs via LEFT JOIN.

-- Fact-table join: in fact_collision, look up the surrogate key by LEFT JOINing 
-- this dim on the natural key column (contributing_factor_for_vehicle), once per vehicle slot. 
-- Per Lec 10, the dimension is the single authority for the surrogate key.

WITH factors AS (

    SELECT contributing_factor_vehicle_1 AS contributing_factor_for_vehicle FROM {{ ref('stg_motor_vehicle_collisions') }}
    UNION DISTINCT
    SELECT contributing_factor_vehicle_2 FROM {{ ref('stg_motor_vehicle_collisions') }}
    UNION DISTINCT
    SELECT contributing_factor_vehicle_3 FROM {{ ref('stg_motor_vehicle_collisions') }}
    UNION DISTINCT
    SELECT contributing_factor_vehicle_4 FROM {{ ref('stg_motor_vehicle_collisions') }}
    UNION DISTINCT
    SELECT contributing_factor_vehicle_5 FROM {{ ref('stg_motor_vehicle_collisions') }}

),

distinct_factors AS (

    SELECT DISTINCT contributing_factor_for_vehicle
    FROM factors

)

SELECT
    {{ dbt_utils.generate_surrogate_key(['contributing_factor_for_vehicle']) }} AS contributing_factor_vehicle_key,
    contributing_factor_for_vehicle
FROM distinct_factors