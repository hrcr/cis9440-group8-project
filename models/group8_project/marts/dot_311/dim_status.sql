-- Status dimension for 311 service requests.
-- Grain: one row per distinct status value.
-- Booleans are non-exclusive (e.g. "IN PROGRESS" -> is_inprogress = TRUE AND is_active = TRUE).
-- JOIN CONTRACT FOR FACT TABLE: fact_311 must compute status_key as
--   {{ dbt_utils.generate_surrogate_key(['status']) }}
-- using the staging.status column, so the hashes match this dimension.

WITH status_values AS (

    SELECT DISTINCT status
    FROM {{ ref('stg_nyc_311_dot') }}
    WHERE status IS NOT NULL

)

SELECT
    {{ dbt_utils.generate_surrogate_key(['status']) }} AS status_key,

    CASE WHEN status IN ('IN PROGRESS', 'STARTED', 'ASSIGNED') THEN TRUE ELSE FALSE END AS is_inprogress,
    CASE WHEN status NOT IN ('CLOSED')                          THEN TRUE ELSE FALSE END AS is_active,
    CASE WHEN status = 'CLOSED'                                  THEN TRUE ELSE FALSE END AS is_closed

FROM status_values