CREATE OR REPLACE TABLE staging.stg_accounts AS

WITH typed_accounts AS (
    SELECT
        CAST(TRIM(account_id) AS INTEGER) AS account_id,
        CAST(TRIM(district_id) AS INTEGER) AS district_id,
        CAST(TRIM("date")AS DATE) AS opened_date,

        CASE TRIM(frequency)
            WHEN 'POPLATEK MESICNE'
                THEN 'monthly'

            WHEN 'POPLATEK TYDNE'
                THEN 'weekly'

            WHEN 'POPLATEK PO OBRATU'
                THEN 'after_transaction'

            WHEN ''
                THEN NULL

            WHEN '?'
                THEN NULL

            WHEN 'unknown'
                THEN NULL

            WHEN 'NULL'
                THEN NULL

            ELSE 'unmapped'
        END AS statement_frequency

    FROM raw.accounts
)

SELECT
    account_id,
    district_id,
    opened_date,

    CAST(DATE_TRUNC('month', opened_date) AS DATE) AS opened_month,
    statement_frequency,
    DATE_DIFF('month',DATE_TRUNC('month', opened_date),DATE '1998-12-01') AS account_age_months_at_snapshot

FROM typed_accounts;