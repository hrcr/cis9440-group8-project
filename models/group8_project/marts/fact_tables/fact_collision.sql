-- Fact table for motor vehicle collisions.
-- Grain: one row per collision (collision_id).
-- Each collision carries up to 5 vehicle-slot FKs for contributing factor and
-- vehicle type, plus shared dimension FKs for date, time, and location.
--
-- FK lookup pattern (per Lec 10 / dim_contributing_factors.sql note):
--   LEFT JOIN each dim on the natural key so that NULL staging values
--   produce NULL FKs rather than broken joins.
WITH stg AS (
    SELECT * FROM {{ ref('stg_motor_vehicle_collisions') }}
),
-- ── Dimension lookups ────────────────────────────────────────────────────────
dim_date AS (
    SELECT date_key, full_date FROM {{ ref('dim_date') }}
),
dim_time AS (
    SELECT time_key, hour, minute FROM {{ ref('dim_time') }}
),
-- >>> CHANGED: pre-aggregate dim_location to one canonical location_key per
-- (borough, zip_code). Collisions don't have a city field, so we collapse
-- multiple city entries into a single location_key for each geographic area.
-- This lets fact_collision.location_key actually populate (the previous
-- "CAST(NULL AS STRING) = dl.city" condition was always FALSE, leaving
-- every location_key NULL). MIN() makes the picked key deterministic.
dim_location AS (
    SELECT
        MIN(location_key) AS location_key,
        borough,
        zip_code
    FROM {{ ref('dim_location') }}
    WHERE borough IS NOT NULL
      AND zip_code IS NOT NULL
    GROUP BY borough, zip_code
),
dim_cf AS (
    SELECT contributing_factor_vehicle_key, contributing_factor_for_vehicle
    FROM {{ ref('dim_contributing_factors') }}
),
dim_veh AS (
    SELECT vehicle_key, vehicle_type FROM {{ ref('dim_vehicle') }}
),
-- ── Join everything onto the staging grain ──────────────────────────────────
joined AS (
    SELECT
        -- Natural key (kept for auditability)
        stg.collision_id,
        -- Date FK
        dd.date_key AS crash_date_key,
        -- Time FK
        dt.time_key AS crash_time_key,
        -- Location FK (matched by borough + zip; collisions have no city)
        dl.location_key,
        -- Vehicle type FKs (one per vehicle slot)
        vt1.vehicle_key AS vehicle_key_v1,
        vt2.vehicle_key AS vehicle_key_v2,
        vt3.vehicle_key AS vehicle_key_v3,
        vt4.vehicle_key AS vehicle_key_v4,
        vt5.vehicle_key AS vehicle_key_v5,

        -- Contributing factor FKs (one per vehicle slot)
        cf1.contributing_factor_vehicle_key AS contributing_factor_key_v1,
        cf2.contributing_factor_vehicle_key AS contributing_factor_key_v2,
        cf3.contributing_factor_vehicle_key AS contributing_factor_key_v3,
        cf4.contributing_factor_vehicle_key AS contributing_factor_key_v4,
        cf5.contributing_factor_vehicle_key AS contributing_factor_key_v5,
        -- Measures
        stg.number_of_persons_injured,
        stg.number_of_persons_killed,
        stg.number_of_pedestrians_injured,
        stg.number_of_pedestrians_killed,
        stg.number_of_cyclist_injured,
        stg.number_of_cyclist_killed,
        stg.number_of_motorist_injured,
        stg.number_of_motorist_killed,
        -- Derived measure: total victims (injured + killed)
        COALESCE(stg.number_of_persons_injured, 0) +
        COALESCE(stg.number_of_persons_killed,  0) AS total_victims,
        -- Degenerate dimensions (street names kept on fact, not worth own dim)
        stg.on_street_name,
        stg.off_street_name,
        stg.cross_street_name,
        stg.latitude,
        stg.longitude,
    FROM stg
    -- Date
    LEFT JOIN dim_date  dd  ON stg.crash_date = dd.full_date
    -- Time (match on hour + minute extracted from crash_time)
    LEFT JOIN dim_time  dt  ON EXTRACT(HOUR   FROM stg.crash_time) = dt.hour
                           AND EXTRACT(MINUTE FROM stg.crash_time) = dt.minute
    -- >>> CHANGED: location join now matches on (borough, zip_code) using the
    -- same INITCAP/TRIM/NULLIF transformations dim_location applies internally,
    -- so 'BROOKLYN' in staging matches 'Brooklyn' in dim_location. The previous
    -- join used "CAST(NULL AS STRING) = dl.city" which is always FALSE in SQL
    -- (NULL never equals anything via =) and produced NULL location_keys for
    -- every row.
    LEFT JOIN dim_location dl
        ON NULLIF(INITCAP(TRIM(stg.borough)), '') = dl.borough
       AND NULLIF(TRIM(stg.zip_code), '')         = dl.zip_code

    -- Vehicle type slots (LEFT JOIN so NULL vehicle types → NULL FK)
    LEFT JOIN dim_veh vt1 ON stg.vehicle_type_1 = vt1.vehicle_type
    LEFT JOIN dim_veh vt2 ON stg.vehicle_type_2 = vt2.vehicle_type
    LEFT JOIN dim_veh vt3 ON stg.vehicle_type_3 = vt3.vehicle_type
    LEFT JOIN dim_veh vt4 ON stg.vehicle_type_4 = vt4.vehicle_type
    LEFT JOIN dim_veh vt5 ON stg.vehicle_type_5 = vt5.vehicle_type
    -- Contributing factor slots (LEFT JOIN so NULL factors → NULL FK)
    LEFT JOIN dim_cf cf1 ON stg.contributing_factor_vehicle_1 = cf1.contributing_factor_for_vehicle
    LEFT JOIN dim_cf cf2 ON stg.contributing_factor_vehicle_2 = cf2.contributing_factor_for_vehicle
    LEFT JOIN dim_cf cf3 ON stg.contributing_factor_vehicle_3 = cf3.contributing_factor_for_vehicle
    LEFT JOIN dim_cf cf4 ON stg.contributing_factor_vehicle_4 = cf4.contributing_factor_for_vehicle
    LEFT JOIN dim_cf cf5 ON stg.contributing_factor_vehicle_5 = cf5.contributing_factor_for_vehicle
)
SELECT
    -- Surrogate PK for the fact row
    {{ dbt_utils.generate_surrogate_key(['collision_id']) }} AS collision_fact_key,
    *
FROM joined
