CREATE OR REPLACE TABLE core.bridge_customer_account AS

SELECT
    d.client_id AS customer_key,
    d.account_id AS account_key,
    d.disposition_id,
    d.relationship_type,
    d.is_owner,
    CASE WHEN d.is_owner THEN 1 ELSE 0 END AS owner_flag
FROM staging.stg_dispositions d;