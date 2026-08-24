CREATE OR REPLACE TABLE core.fct_cards AS

SELECT
    c.card_id,

    -- Keys
    CAST(strftime(c.issued_date, '%Y%m%d') AS INTEGER) AS issued_date_key,
    c.disposition_id,
    d.account_id AS account_key,
    d.client_id AS customer_key,

    -- Attributes
    c.card_type,
    c.issued_date

FROM staging.stg_cards c
LEFT JOIN staging.stg_dispositions d
    ON c.disposition_id = d.disposition_id;