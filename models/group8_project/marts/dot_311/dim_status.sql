-- Status dimension for 311 service requests
-- Grain: one row per distinct status value

WITH status_values AS (

    SELECT DISTINCT status
    FROM {{ ref('stg_group8_nyc_311_dot') }}

    UNION DISTINCT

    SELECT CAST(NULL AS STRING) AS status

)

SELECT
    {{ dbt_utils.generate_surrogate_key(['status']) }} AS status_key,
    status AS status_text,

    CASE
        WHEN status IN ('IN PROGRESS', 'STARTED', 'ASSIGNED') THEN TRUE
        ELSE FALSE
    END AS is_inprogress,

    CASE
        WHEN status IS NOT NULL AND status <> 'CLOSED' THEN TRUE
        ELSE FALSE
    END AS is_active,

    CASE
        WHEN status = 'CLOSED' THEN TRUE
        ELSE FALSE
    END AS is_closed

FROM status_values