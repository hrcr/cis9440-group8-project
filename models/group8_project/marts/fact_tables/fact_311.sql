-- Fact table for 311 DOT/NYPD service requests.
-- Grain: one row per service request (unique_key).
-- FKs reference shared dims (date, time, location) and 311-specific dims
-- (agency, complaint, status).
--
-- Two date FKs are included:
--   created_date_key  – when the request was opened  (always populated)
--   closed_date_key   – when the request was closed  (NULL if still open)
--
-- Elapsed-time measure: resolution_hours is the difference in hours between
-- created_date and closed_date. NULL when the request is still open.

WITH stg AS (

    SELECT * FROM {{ ref('stg_nyc_311_dot') }}

),

-- ── Dimension lookups ────────────────────────────────────────────────────────

dim_date AS (
    SELECT date_key, full_date FROM {{ ref('dim_date') }}
),

dim_time AS (
    SELECT time_key, hour, minute FROM {{ ref('dim_time') }}
),

dim_location AS (
    SELECT location_key, city, borough, zip_code FROM {{ ref('dim_location') }}
),

dim_agency AS (
    SELECT agency_key, agency_code, agency_name FROM {{ ref('dim_agency') }}
),

dim_complaint AS (
    SELECT complaint_key, complaint_type, location_type FROM {{ ref('dim_complaint') }}
),

dim_status AS (
    SELECT status_key, status_text FROM {{ ref('dim_status') }}
),

-- ── Join everything onto the staging grain ──────────────────────────────────

joined AS (

    SELECT
        -- Natural key
        stg.unique_key,

        -- Date FKs
        dd_created.date_key  AS created_date_key,
        dd_closed.date_key   AS closed_date_key,   -- NULL if still open

        -- Time FK (hour + minute of created_date)
        dt.time_key          AS created_time_key,

        -- Location FK
        dl.location_key,

        -- 311-specific dimension FKs
        da.agency_key,
        dc.complaint_key,
        ds.status_key,

        -- Degenerate dimensions (high-cardinality; not worth own dim table)
        stg.incident_address,
        stg.street_name,
        stg.cross_street_1,
        stg.cross_street_2,
        stg.address_type,
        stg.community_board,
        stg.police_precinct,
        stg.opendata_channel_type,
        stg.problem_detail,
        stg.additional_details,
        stg.resolution_description,
        stg.latitude,
        stg.longitude,

        -- Raw timestamps (useful for interval calculations in BI tools)
        stg.created_date,
        stg.closed_date,
        stg.due_date,
        stg.resolution_action_date,

        -- Measures
        CASE
            WHEN stg.closed_date IS NOT NULL
            THEN TIMESTAMP_DIFF(stg.closed_date, stg.created_date, HOUR)
            ELSE NULL
        END AS resolution_hours,

        -- Boolean flags (convenience measures)
        CASE WHEN stg.closed_date IS NOT NULL THEN TRUE ELSE FALSE END AS is_resolved,
        CASE
            WHEN stg.due_date IS NOT NULL AND stg.closed_date > stg.due_date THEN TRUE
            ELSE FALSE
        END AS is_overdue,

        stg._stg_loaded_at

    FROM stg

    -- Created date
    LEFT JOIN dim_date dd_created ON CAST(stg.created_date AS DATE) = dd_created.full_date

    -- Closed date (may be NULL)
    LEFT JOIN dim_date dd_closed  ON CAST(stg.closed_date  AS DATE) = dd_closed.full_date

    -- Time of creation
    LEFT JOIN dim_time dt ON EXTRACT(HOUR   FROM stg.created_date) = dt.hour
                         AND EXTRACT(MINUTE FROM stg.created_date) = dt.minute

    -- Location (311 has city; join on city + borough + zip)
    LEFT JOIN dim_location dl ON stg.city        = dl.city
                              AND stg.borough     = dl.borough
                              AND stg.incident_zip = dl.zip_code

    -- Agency
    LEFT JOIN dim_agency da ON stg.agency      = da.agency_code
                           AND stg.agency_name = da.agency_name

    -- Complaint type + location type pair
    LEFT JOIN dim_complaint dc ON stg.complaint_type = dc.complaint_type
                              AND stg.location_type  = dc.location_type

    -- Status
    LEFT JOIN dim_status ds ON stg.status = ds.status_text

)

SELECT
    -- Surrogate PK for the fact row
    {{ dbt_utils.generate_surrogate_key(['unique_key']) }} AS request_fact_key,
    *
FROM joined