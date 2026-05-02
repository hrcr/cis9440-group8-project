-- Complaint dimension for 311 service requests.
-- Grain: one row per distinct (complaint_type, location_type) pair.

WITH complaints AS (

    SELECT DISTINCT
        complaint_type,
        location_type
    FROM {{ ref('stg_nyc_311_dot') }}

    UNION DISTINCT

    -- Sentinel NULL row for fact-table FK safety
    SELECT
        CAST(NULL AS STRING) AS complaint_type,
        CAST(NULL AS STRING) AS location_type

)

SELECT
    {{ dbt_utils.generate_surrogate_key(['complaint_type', 'location_type']) }} AS complaint_key,
    complaint_type,
    location_type
FROM complaints