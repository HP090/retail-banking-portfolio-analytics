CREATE OR REPLACE TABLE staging.stg_loans AS

WITH typed_loans AS (
    SELECT
        CAST(TRIM(loan_id) AS INTEGER) AS loan_id,

        CAST(TRIM(account_id) AS INTEGER) AS account_id,

        CAST(TRIM("date") AS DATE) AS origination_date,

        CAST(TRIM(amount) AS DECIMAL(12, 2)) AS loan_amount,

        CAST(TRIM(duration) AS INTEGER) AS duration_months,

        CAST(TRIM(payments) AS DECIMAL(10, 2)) AS monthly_payment,

        UPPER(TRIM(status)) AS status_code

    FROM raw.loans
)

SELECT
    loan_id,
    account_id,
    origination_date,

    CAST(EXTRACT(YEAR FROM origination_date) AS INTEGER) AS origination_year,

    loan_amount,
    duration_months,
    monthly_payment,

    CAST(origination_date + (duration_months * INTERVAL '1 month') AS DATE) AS scheduled_maturity_date,

    status_code,

    CASE status_code
        WHEN 'A' THEN 'completed'
        WHEN 'B' THEN 'completed'
        WHEN 'C' THEN 'active'
        WHEN 'D' THEN 'active'
        ELSE 'unknown'
    END AS status_group,

    DATE '1998-12-31' AS status_as_of_date

FROM typed_loans;