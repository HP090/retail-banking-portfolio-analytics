CREATE OR REPLACE TABLE core.dim_account AS

SELECT
    a.account_id AS account_key,
    a.account_id,
    a.district_id,
    d.district_name,
    d.region,
    a.opened_date,
    a.opened_month,
    a.statement_frequency,
    a.account_age_months_at_snapshot
FROM staging.stg_accounts a LEFT JOIN staging.stg_districts d
ON a.district_id = d.district_id;