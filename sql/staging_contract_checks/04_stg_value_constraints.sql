-- 04_stg_value_constraints.sql
-- Value constraint checks on staging tables

-- 1. Transaction amounts must be >= 0
SELECT
    'stg_transactions' AS table_name,
    'amount' AS column_name,
    'amount >= 0' AS rule,
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE amount < 0) AS violation_count,
    LIST(amount) FILTER (WHERE amount < 0 AND rn <= 5) AS example_violations
FROM (
    SELECT
        amount,
        ROW_NUMBER() OVER (PARTITION BY (amount < 0)) AS rn
    FROM staging.stg_transactions
) t

UNION ALL

-- 2. Loan amount must be > 0
SELECT
    'stg_loans',
    'loan_amount',
    'loan_amount > 0',
    COUNT(*),
    COUNT(*) FILTER (WHERE loan_amount <= 0),
    LIST(loan_amount) FILTER (WHERE loan_amount <= 0 AND rn <= 5)
FROM (
    SELECT
        loan_amount,
        ROW_NUMBER() OVER (PARTITION BY (loan_amount <= 0)) AS rn
    FROM staging.stg_loans
) t

UNION ALL

-- 3. Loan duration must be > 0
SELECT
    'stg_loans',
    'duration_months',
    'duration_months > 0',
    COUNT(*),
    COUNT(*) FILTER (WHERE duration_months <= 0),
    LIST(duration_months) FILTER (WHERE duration_months <= 0 AND rn <= 5)
FROM (
    SELECT
        duration_months,
        ROW_NUMBER() OVER (PARTITION BY (duration_months <= 0)) AS rn
    FROM staging.stg_loans
) t

UNION ALL

-- 4. Loan monthly payment must be > 0
SELECT
    'stg_loans',
    'monthly_payment',
    'monthly_payment > 0',
    COUNT(*),
    COUNT(*) FILTER (WHERE monthly_payment <= 0),
    LIST(monthly_payment) FILTER (WHERE monthly_payment <= 0 AND rn <= 5)
FROM (
    SELECT
        monthly_payment,
        ROW_NUMBER() OVER (PARTITION BY (monthly_payment <= 0)) AS rn
    FROM staging.stg_loans
) t

UNION ALL

-- 5. Loan status must be one of A, B, C, D
SELECT
    'stg_loans',
    'status_code',
    'status_code IN (A, B, C, D)',
    COUNT(*),
    COUNT(*) FILTER (WHERE status_code NOT IN ('A', 'B', 'C', 'D') OR status_code IS NULL),
    LIST(status_code) FILTER (
        WHERE (status_code NOT IN ('A', 'B', 'C', 'D') OR status_code IS NULL)
          AND rn <= 5
    )
FROM (
    SELECT
        status_code,
        ROW_NUMBER() OVER (
            PARTITION BY (status_code NOT IN ('A', 'B', 'C', 'D') OR status_code IS NULL)
        ) AS rn
    FROM staging.stg_loans
) t;