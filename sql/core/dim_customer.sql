CREATE OR REPLACE TABLE core.dim_customer AS

SELECT
    c.client_id AS customer_key,
    c.client_id,
    c.gender,
    c.birth_date,
    c.age_at_snapshot,
    c.age_band,
    c.district_id,
    d.district_name,
    d.region
FROM staging.stg_clients c LEFT JOIN staging.stg_districts d
ON c.district_id = d.district_id;