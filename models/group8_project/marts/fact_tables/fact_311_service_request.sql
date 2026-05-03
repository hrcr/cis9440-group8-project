-- Fact table for 311 DOT/NYPD service requests.
-- Grain: one row per service request (unique_key).
-- FKs reference shared dims (date, time, location) and 311-specific dims
-- (agency, complaint, status).
--
-- Four date FKs are included:
--   created_date_key          – when the request was opened  (always populated)
--   closed_date_key           – when the request was closed  (NULL if still open)
--   due_date_key              – target resolution date        (NULL if not set)
--   resolution_action_date_key– last action update date       (NULL if not set)
--
-- Three time FKs are included:
--   created_time_key          – time of creation
--   due_time_key              – time component of due_date    (NULL if not set)
--   resolution_action_time_key– time component of resolution_action_date (NULL if not set)
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
        dd_created.date_key            AS created_date_key,
        dd_closed.date_key             AS closed_date_key,            -- NULL if still open
        dd_due.date_key                AS due_date_key,               -- NULL if not set
        dd_resolution.date_key         AS resolution_action_date_key, -- NULL if not set

        -- Time FKs
        dt_created.time_key            AS created_time_key,
        dt_due.time_key                AS due_time_key,               -- NULL if not set
        dt_resolution.time_key         AS resolution_action_time_key, -- NULL if not set

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
        stg.vehicle_type AS vehicle_in_complaint,
        stg.resolution_description,
        stg.latitude,
        stg.longitude,


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


    FROM stg

    -- Created date
    LEFT JOIN dim_date dd_created    ON CAST(stg.created_date          AS DATE) = dd_created.full_date

    -- Closed date (may be NULL)
    LEFT JOIN dim_date dd_closed     ON CAST(stg.closed_date           AS DATE) = dd_closed.full_date

    -- Due date (may be NULL)
    LEFT JOIN dim_date dd_due        ON CAST(stg.due_date              AS DATE) = dd_due.full_date

    -- Resolution action date (may be NULL)
    LEFT JOIN dim_date dd_resolution ON CAST(stg.resolution_action_date AS DATE) = dd_resolution.full_date

    -- Time of creation
    LEFT JOIN dim_time dt_created    ON EXTRACT(HOUR   FROM stg.created_date)          = dt_created.hour
                                    AND EXTRACT(MINUTE FROM stg.created_date)          = dt_created.minute

    -- Time of due date (may be NULL)
    LEFT JOIN dim_time dt_due        ON EXTRACT(HOUR   FROM stg.due_date)              = dt_due.hour
                                    AND EXTRACT(MINUTE FROM stg.due_date)              = dt_due.minute

    -- Time of resolution action (may be NULL)
    LEFT JOIN dim_time dt_resolution ON EXTRACT(HOUR   FROM stg.resolution_action_date) = dt_resolution.hour
                                    AND EXTRACT(MINUTE FROM stg.resolution_action_date) = dt_resolution.minute

    -- Location (311 has city; join on city + borough + zip)
    LEFT JOIN dim_location dl        ON stg.city        = dl.city
                                    AND stg.borough     = dl.borough
                                    AND stg.incident_zip = dl.zip_code

    -- Agency
    LEFT JOIN dim_agency da          ON stg.agency      = da.agency_code
                                    AND stg.agency_name = da.agency_name

    -- Complaint type + location type pair
    LEFT JOIN dim_complaint dc       ON stg.complaint_type = dc.complaint_type
                                    AND stg.location_type  = dc.location_type

    -- Status
    LEFT JOIN dim_status ds          ON stg.status = ds.status_text

)

SELECT
    -- Surrogate PK for the fact row
    {{ dbt_utils.generate_surrogate_key(['unique_key']) }} AS request_fact_key,
    *
FROM joined