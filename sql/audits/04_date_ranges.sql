-- 04_date_ranges.sql
-- Raw dates already contain four-digit years.

WITH settings AS (
    SELECT
        DATE '1993-01-01' AS analysis_start_date,
        DATE '1998-12-31' AS analysis_end_date,
        DATE '1998-12-31' AS snapshot_date
),

parsed_dates AS (

    -- 1. Account opening dates
    SELECT
        'raw.accounts' AS table_name,
        'date' AS source_column,

        TRY_CAST(
            LEFT(
                REPLACE(TRIM("date"), '/', '-'),
                10
            ) AS DATE
        ) AS parsed_date,

        analysis_start_date AS expected_min_date,
        snapshot_date AS expected_max_date,

        'Account opening date must fall within the banking dataset period'
            AS audit_rule

    FROM raw.accounts
    CROSS JOIN settings

    UNION ALL

    -- 2. Transaction dates
    SELECT
        'raw.transactions',
        'date',

        TRY_CAST(
            LEFT(
                REPLACE(TRIM("date"), '/', '-'),
                10
            ) AS DATE
        ),

        analysis_start_date,
        analysis_end_date,

        'Transaction date must fall within the configured analysis period'

    FROM raw.transactions
    CROSS JOIN settings

    UNION ALL

    -- 3. Loan origination dates
    SELECT
        'raw.loans',
        'date',

        TRY_CAST(
            LEFT(
                REPLACE(TRIM("date"), '/', '-'),
                10
            ) AS DATE
        ),

        analysis_start_date,
        snapshot_date,

        'Loan origination date must not be after the snapshot date'

    FROM raw.loans
    CROSS JOIN settings

    UNION ALL

    -- 4. Card issue dates
    SELECT
        'raw.cards',
        'issued',

        TRY_CAST(
            LEFT(
                REPLACE(TRIM(issued), '/', '-'),
                10
            ) AS DATE
        ),

        analysis_start_date,
        snapshot_date,

        'Card issue date must not be after the snapshot date'

    FROM raw.cards
    CROSS JOIN settings

    UNION ALL

    -- 5. Client birth dates
    -- Birth dates are not tested against the transaction-history start.
    SELECT
        'raw.clients',
        'birth_date',

        TRY_CAST(
            LEFT(
                REPLACE(TRIM(birth_date), '/', '-'),
                10
            ) AS DATE
        ),

        CAST(NULL AS DATE),
        snapshot_date,

        'Birth date must be valid and not after the snapshot date'

    FROM raw.clients
    CROSS JOIN settings
)

SELECT
    table_name,
    source_column,
    COUNT(*) AS row_count,

    COUNT(parsed_date)
        AS successfully_parsed_count,

    COUNT(*) FILTER (
        WHERE parsed_date IS NULL
    ) AS unparseable_or_missing_count,

    MIN(parsed_date) AS minimum_date,
    MAX(parsed_date) AS maximum_date,

    MIN(expected_min_date)
        AS expected_min_date,

    MAX(expected_max_date)
        AS expected_max_date,

    COUNT(*) FILTER (
        WHERE parsed_date IS NOT NULL
          AND (
              (
                  expected_min_date IS NOT NULL
                  AND parsed_date < expected_min_date
              )
              OR
              (
                  expected_max_date IS NOT NULL
                  AND parsed_date > expected_max_date
              )
          )
    ) AS outside_expected_range_count,

    audit_rule

FROM parsed_dates

GROUP BY
    table_name,
    source_column,
    audit_rule

ORDER BY table_name;