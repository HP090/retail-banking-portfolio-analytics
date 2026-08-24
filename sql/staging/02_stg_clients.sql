CREATE OR REPLACE TABLE staging.stg_clients AS

WITH typed_clients AS (
    SELECT
        CAST(TRIM(client_id) AS INTEGER) AS client_id,

        CAST(TRIM(district_id) AS INTEGER) AS district_id,

        CAST(TRIM(birth_date) AS DATE) AS birth_date,

        CASE UPPER(TRIM(gender))
            WHEN 'F' THEN 'Female'
            WHEN 'M' THEN 'Male'
            ELSE 'Unknown'
        END AS gender

    FROM raw.clients
),

clients_with_age AS (
    SELECT
        client_id,
        district_id,
        birth_date,
        gender,
        DATE_DIFF('year', birth_date, DATE '1998-12-31') AS age_at_snapshot

    FROM typed_clients
)

SELECT
    client_id,
    district_id,
    birth_date,
    gender,
    age_at_snapshot,

    CASE
        WHEN age_at_snapshot IS NULL
            THEN 'Unknown'

        WHEN age_at_snapshot < 25
            THEN 'Under 25'

        WHEN age_at_snapshot BETWEEN 25 AND 35
            THEN '25-35'

        WHEN age_at_snapshot BETWEEN 36 AND 45
            THEN '36-45'

        WHEN age_at_snapshot BETWEEN 46 AND 55
            THEN '46-55'

        WHEN age_at_snapshot BETWEEN 56 AND 65
            THEN '56-65'

        ELSE 'Over 65'
    END AS age_band

FROM clients_with_age;