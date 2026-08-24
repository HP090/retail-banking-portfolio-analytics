-- 03_stg_date_ranges.sql
-- Date range and parseability checks on staging tables

WITH settings AS (
    SELECT
        DATE '1993-01-01' AS analysis_start_date,
        DATE '1998-12-31' AS analysis_end_date,
        DATE '1998-12-31' AS snapshot_date
),

parsed_dates AS (

    -- 1. Account opening dates
    SELECT
        'stg_accounts' AS table_name,
        'opened_date' AS source_column,
        TRY_CAST(opened_date AS DATE) AS parsed_date,
        analysis_start_date AS expected_min_date,
        snapshot_date AS expected_max_date,
        'Account opening date must fall within the banking dataset period' AS audit_rule
    FROM staging.stg_accounts
    CROSS JOIN settings

    UNION ALL

    -- 2. Transaction dates
    SELECT
        'stg_transactions',
        'transaction_date',
        TRY_CAST(transaction_date AS DATE),
        analysis_start_date,
        analysis_end_date,
        'Transaction date must fall within the configured analysis period'
    FROM staging.stg_transactions
    CROSS JOIN settings

    UNION ALL

    -- 3. Loan origination dates
    SELECT
        'stg_loans',
        'origination_date',
        TRY_CAST(origination_date AS DATE),
        analysis_start_date,
        snapshot_date,
        'Loan origination date must not be after the snapshot date'
    FROM staging.stg_loans
    CROSS JOIN settings

    UNION ALL

    -- 4. Card issue dates
    SELECT
        'stg_cards',
        'issued_date',
        TRY_CAST(issued_date AS DATE),
        analysis_start_date,
        snapshot_date,
        'Card issue date must not be after the snapshot date'
    FROM staging.stg_cards
    CROSS JOIN settings

    UNION ALL

    -- 5. Client birth dates
    SELECT
        'stg_clients',
        'birth_date',
        TRY_CAST(birth_date AS DATE),
        CAST(NULL AS DATE),               -- no strict lower bound for birth dates
        snapshot_date,
        'Birth date must be valid and must not be after the snapshot date'
    FROM staging.stg_clients
    CROSS JOIN settings
)

SELECT
    table_name,
    source_column,
    COUNT(*) AS total_rows,
    COUNT(parsed_date) AS successfully_parsed_count,
    COUNT(*) FILTER (WHERE parsed_date IS NULL) AS unparseable_or_missing_count,
    MIN(parsed_date) AS minimum_date,
    MAX(parsed_date) AS maximum_date,
    MIN(expected_min_date) AS expected_min_date,
    MAX(expected_max_date) AS expected_max_date,
    COUNT(*) FILTER (
        WHERE parsed_date IS NOT NULL
          AND (
                (expected_min_date IS NOT NULL AND parsed_date < expected_min_date)
             OR (expected_max_date IS NOT NULL AND parsed_date > expected_max_date)
          )
    ) AS outside_expected_range_count,
    audit_rule
FROM parsed_dates
GROUP BY
    table_name,
    source_column,
    audit_rule
ORDER BY table_name;