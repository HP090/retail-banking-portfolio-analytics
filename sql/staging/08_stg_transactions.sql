CREATE OR REPLACE TABLE staging.stg_transactions AS

WITH categorised_transactions AS (
    SELECT
        -- 1. Keys
        CAST(TRIM(trans_id) AS INTEGER) AS transaction_id,

        CAST(TRIM(account_id) AS INTEGER) AS account_id,

        -- 2. Dates
        CAST(TRIM("date") AS DATE) AS transaction_date,

        CAST(DATE_TRUNC('month',CAST(TRIM("date") AS DATE)) AS DATE) AS transaction_month,

        -- 3. Financial measures
        CAST(TRIM(amount) AS DECIMAL(12, 2)) AS amount,

        CAST(TRIM(balance) AS DECIMAL(12, 2)) AS reported_balance,

        -- 4. Original codes retained for traceability
        type AS original_type,

        operation AS original_operation,

        k_symbol AS original_k_symbol,

        -- 5. Standardised direction
        CASE UPPER(TRIM(type))
            WHEN 'PRIJEM'
                THEN 'credit'

            WHEN 'VYDAJ'
                THEN 'debit'

            WHEN 'VYBER'
                THEN 'debit'

            ELSE 'unmapped'
        END AS direction,

        -- 6. Standardised operation
        CASE
            WHEN operation IS NULL OR UPPER(TRIM(operation)) IN ('', '?', 'UNKNOWN', 'NULL')
                THEN NULL

            WHEN UPPER(TRIM(operation)) = 'VKLAD'
                THEN 'cash_deposit'

            WHEN UPPER(TRIM(operation)) = 'PREVOD Z UCTU'
                THEN 'incoming_bank_transfer'

            WHEN UPPER(TRIM(operation)) = 'VYBER'
                THEN 'cash_withdrawal'

            WHEN UPPER(TRIM(operation)) = 'VYBER KARTOU'
                THEN 'card_withdrawal'

            WHEN UPPER(TRIM(operation)) = 'PREVOD NA UCET'
                THEN 'outgoing_bank_transfer'

            ELSE 'unmapped'
        END AS operation,

        -- 7. Standardised purpose
        CASE
            WHEN k_symbol IS NULL OR UPPER(TRIM(k_symbol)) IN ('', '?', 'UNKNOWN', 'NULL')
                THEN NULL

            WHEN UPPER(TRIM(k_symbol)) = 'POJISTNE'
                THEN 'insurance_payment'

            WHEN UPPER(TRIM(k_symbol)) = 'SLUZBY'
                THEN 'statement_fee'

            WHEN UPPER(TRIM(k_symbol)) = 'UROK'
                THEN 'interest_credited'

            WHEN UPPER(TRIM(k_symbol)) = 'SANKC. UROK'
                THEN 'sanction_interest'

            WHEN UPPER(TRIM(k_symbol)) = 'SIPO'
                THEN 'household_payment'

            WHEN UPPER(TRIM(k_symbol)) = 'DUCHOD'
                THEN 'pension_inflow'

            WHEN UPPER(TRIM(k_symbol)) = 'UVER'
                THEN 'loan_payment'

            ELSE 'unmapped'
        END AS purpose

    FROM raw.transactions
)

SELECT
    transaction_id,
    account_id,
    transaction_date,
    transaction_month,
    amount,
    reported_balance,

    original_type,
    original_operation,
    original_k_symbol,

    direction,
    operation,
    purpose,


    -- 8. Accounting values
    CASE
        WHEN direction = 'credit'
            THEN amount
        ELSE CAST(0 AS DECIMAL(12, 2))
    END AS credit_amount,

    CASE
        WHEN direction = 'debit'
            THEN amount
        ELSE CAST(0 AS DECIMAL(12, 2))
    END AS debit_amount,

    CASE
        WHEN direction = 'credit'
            THEN amount

        WHEN direction = 'debit'
            THEN -amount

        ELSE CAST(0 AS DECIMAL(12, 2))
    END AS signed_amount,

    -- 9. Qualifying account activity
    CASE
        WHEN direction IN ('credit', 'debit')

         AND operation IN (
             'cash_deposit',
             'incoming_bank_transfer',
             'cash_withdrawal',
             'card_withdrawal',
             'outgoing_bank_transfer'
         )

         AND COALESCE(purpose, '') NOT IN (
             'interest_credited',
             'sanction_interest',
             'statement_fee'
         )

        THEN TRUE
        ELSE FALSE
    END AS is_qualifying_account_activity,

    -- 10 . Credit inflow

   CASE
    WHEN direction = 'credit'
     AND amount > 0

     AND operation IN (
         'cash_deposit',
         'incoming_bank_transfer'
     )

     AND COALESCE(purpose, '') NOT IN (
         'statement_fee',
         'interest_credited',
         'sanction_interest'
     )

    THEN TRUE
    ELSE FALSE
END AS is_external_credit_inflow

FROM categorised_transactions;