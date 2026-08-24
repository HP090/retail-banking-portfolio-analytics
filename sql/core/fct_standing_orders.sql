CREATE OR REPLACE TABLE core.fct_standing_orders AS

SELECT
    o.order_id,

    -- Keys
    o.account_id AS account_key,

    -- Measures
    o.amount,

    -- Attributes
    o.recipient_bank,
    o.recipient_account,
    o.order_purpose

FROM staging.stg_orders o;