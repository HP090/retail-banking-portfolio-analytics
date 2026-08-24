CREATE OR REPLACE TABLE staging.stg_districts AS

SELECT
    -- 1. Core identifiers
    CAST(TRIM(district_id) AS INTEGER) AS district_id,

    NULLIF(TRIM("A2"), '') AS district_name,

    NULLIF(TRIM("A3"), '') AS region,

    -- 2. Population measures
    TRY_CAST(NULLIF(TRIM("A4"), '?') AS INTEGER) AS population,

    TRY_CAST(NULLIF(TRIM("A5"), '?') AS INTEGER) AS municipalities_under_499,

    TRY_CAST(NULLIF(TRIM("A6"), '?') AS INTEGER) AS municipalities_500_to_1999,

    TRY_CAST(NULLIF(TRIM("A7"), '?') AS INTEGER) AS municipalities_2000_to_9999,

    TRY_CAST(NULLIF(TRIM("A8"), '?') AS INTEGER) AS municipalities_over_10000,

    TRY_CAST(NULLIF(TRIM("A9"), '?') AS INTEGER) AS number_of_cities,

    TRY_CAST(NULLIF(TRIM("A10"), '?') AS DECIMAL(6, 2)) AS urban_population_pct,

    -- 3. Economic indicators
    TRY_CAST(NULLIF(TRIM("A11"), '?') AS INTEGER) AS average_salary,

    TRY_CAST(NULLIF(TRIM("A12"), '?') AS DECIMAL(5, 2)) AS unemployment_rate_1995,

    TRY_CAST(NULLIF(TRIM("A13"), '?') AS DECIMAL(5, 2)) AS unemployment_rate_1996,

    TRY_CAST(NULLIF(TRIM("A14"), '?') AS INTEGER) AS entrepreneurs_per_1000,

    -- 4. Crime measures
    TRY_CAST(NULLIF(TRIM("A15"), '?') AS INTEGER) AS committed_crimes_1995,

    TRY_CAST(NULLIF(TRIM("A16"), '?')AS INTEGER) AS committed_crimes_1996

FROM raw.districts;