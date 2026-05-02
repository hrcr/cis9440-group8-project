-- Status dimension for 311 service requests.
-- Grain: one row per distinct status value.

-- DESIGN NOTE (deviation from M3 model): we retain status_text as the natural key
-- alongside the surrogate. M3 omitted it; in standard dimensional modeling the
-- natural key belongs in the dim. Keeping it here makes fact-table joins
-- transparent (JOIN on status_text) and avoids losing information when
-- multiple raw statuses share the same boolean pattern.
-- Booleans are non-exclusive (e.g. "IN PROGRESS" -> is_inprogress=TRUE AND is_active=TRUE).

WITH status_values AS (

    SELECT DISTINCT status
    FROM {{ ref('stg_nyc_311_dot') }}

    UNION DISTINCT

    -- Sentinel NULL row for fact-table FK safety
    SELECT CAST(NULL AS STRING) AS status

)

SELECT
    {{ dbt_utils.generate_surrogate_key(['status']) }} AS status_key,
    status                                              AS status_text,

    CASE WHEN status IN ('IN PROGRESS', 'STARTED', 'ASSIGNED') THEN TRUE ELSE FALSE END AS is_inprogress,
    CASE WHEN status NOT IN ('CLOSED')                          THEN TRUE ELSE FALSE END AS is_active,
    CASE WHEN status = 'CLOSED'                                  THEN TRUE ELSE FALSE END AS is_closed

FROM status_values