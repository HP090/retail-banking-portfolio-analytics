CREATE OR REPLACE TABLE core.dim_district AS

SELECT
    district_id AS district_key,
    district_id,
    district_name,
    region,
    population,
    municipalities_under_499,
    municipalities_500_to_1999,
    municipalities_2000_to_9999,
    municipalities_over_10000,
    number_of_cities,
    urban_population_pct,
    average_salary,
    unemployment_rate_1995,
    unemployment_rate_1996,
    entrepreneurs_per_1000,
    committed_crimes_1995,
    committed_crimes_1996
FROM staging.stg_districts;