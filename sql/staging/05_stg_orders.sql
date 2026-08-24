CREATE OR REPLACE TABLE staging.stg_orders AS

SELECT
    CAST(TRIM(order_id) AS INTEGER) AS order_id,

    CAST(TRIM(account_id) AS INTEGER) AS account_id,

    -- Keep these as text to preserve possible leading zeros.
    NULLIF(TRIM(bank_to), '') AS recipient_bank,

    NULLIF(TRIM(account_to), '') AS recipient_account,

    CAST(TRIM(amount) AS DECIMAL(10, 2)) AS amount,

    CASE UPPER(TRIM(k_symbol))
        WHEN 'POJISTNE'
            THEN 'insurance_payment'

        WHEN 'SIPO'
            THEN 'household_payment'

        WHEN 'LEASING'
            THEN 'leasing_payment'

        WHEN 'UVER'
            THEN 'loan_payment'

        WHEN ''
            THEN NULL

        WHEN '?'
            THEN NULL

        WHEN 'UNKNOWN'
            THEN NULL

        WHEN 'NULL'
            THEN NULL

        ELSE 'unmapped'
    END AS order_purpose

FROM raw.orders;