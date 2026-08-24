CREATE OR REPLACE TABLE core.fct_account_monthly_snapshot AS

WITH
-- =========================================================
-- Step 1: Month ends + Account × Month spine
-- =========================================================
month_ends AS (
    SELECT last_day(d) AS month_end
    FROM (
        SELECT UNNEST(generate_series(
            DATE '1993-01-01',
            DATE '1998-12-31',
            INTERVAL '1 month'
        )) AS d
    )
),

spine AS (
    SELECT
        a.account_id,
        a.district_id,
        m.month_end,
        a.opened_date
    FROM core.dim_account a
    INNER JOIN month_ends m
        ON m.month_end >= DATE_TRUNC('month', a.opened_date)
),

-- =========================================================
-- Step 2: Monthly activity aggregates
-- =========================================================
activity AS (
    SELECT
        account_key,
        transaction_month,

        SUM(credit_amount) AS total_ledger_credits,
        SUM(CASE WHEN is_external_credit_inflow THEN credit_amount ELSE 0 END) AS external_credit_inflows,
        SUM(debit_amount) AS total_ledger_debits,
        SUM(credit_amount) - SUM(debit_amount) AS net_ledger_cash_flow,

        COUNT(*) AS transaction_count,
        COUNT(*) FILTER (WHERE is_qualifying_account_activity) AS qualifying_activity_count,

        MIN(reported_balance) AS min_reported_balance,

        BOOL_OR(is_qualifying_account_activity) AS had_qualifying_activity,
        BOOL_OR(reported_balance < 0) AS was_ever_negative
    FROM core.fct_transactions
    GROUP BY account_key, transaction_month
),

-- =========================================================
-- Steps 3 & 4: Latest balance on/before month-end (forward-fill)
-- =========================================================
latest AS (
    SELECT
        s.account_id,
        s.month_end,

        ARG_MAX(t.reported_balance,
            STRUCT_PACK(
                transaction_date := t.transaction_date,
                transaction_id := t.transaction_id
            )
        ) AS month_end_balance,

        MAX(t.transaction_date) AS latest_balance_date

    FROM spine s
    LEFT JOIN core.fct_transactions t
        ON t.account_key = s.account_id
       AND t.transaction_date <= s.month_end

    GROUP BY s.account_id, s.month_end
),

balances AS (
    SELECT
        account_id,
        month_end,
        month_end_balance,
        latest_balance_date,
        latest_balance_date BETWEEN DATE_TRUNC('month', month_end) AND month_end
            AS balance_observed_in_month,
        DATE_DIFF('day', latest_balance_date, month_end) AS balance_age_days_at_month_end,
       latest_balance_date IS NOT NULL AS balance_known_as_of_month_end
    FROM latest
),

-- =========================================================
-- Step 5: Previous balance + changes
-- =========================================================
with_changes AS (
    SELECT
        *,
        LAG(month_end_balance) OVER (
            PARTITION BY account_id
            ORDER BY month_end
        ) AS previous_month_end_balance,

        month_end_balance - LAG(month_end_balance) OVER (
            PARTITION BY account_id
            ORDER BY month_end
        ) AS absolute_balance_change,

        CASE
            WHEN LAG(month_end_balance) OVER (PARTITION BY account_id ORDER BY month_end) IS NULL
              OR LAG(month_end_balance) OVER (PARTITION BY account_id ORDER BY month_end) = 0
                THEN NULL
            ELSE
                (month_end_balance - LAG(month_end_balance) OVER (PARTITION BY account_id ORDER BY month_end))
                / LAG(month_end_balance) OVER (PARTITION BY account_id ORDER BY month_end)
        END AS percentage_balance_change
    FROM balances
)

-- =========================================================
-- Final assembly (Steps 1–6)
-- =========================================================
SELECT
    -- Identity
    s.account_id,
    s.district_id,
    s.month_end,

    -- Activity (Step 2)
    COALESCE(a.total_ledger_credits, 0)        AS total_ledger_credits,
    COALESCE(a.external_credit_inflows, 0)     AS external_credit_inflows,
    COALESCE(a.total_ledger_debits, 0)         AS total_ledger_debits,
    COALESCE(a.net_ledger_cash_flow, 0)        AS net_ledger_cash_flow,
    COALESCE(a.transaction_count, 0)           AS transaction_count,
    COALESCE(a.qualifying_activity_count, 0)   AS qualifying_activity_count,
    a.min_reported_balance,
    COALESCE(a.had_qualifying_activity, FALSE) AS had_qualifying_activity,
    COALESCE(a.was_ever_negative, FALSE)       AS was_ever_negative,

    -- Balance (Steps 3–4)
    b.month_end_balance,
    b.balance_known_as_of_month_end,
    b.balance_observed_in_month,
    b.latest_balance_date,
    b.balance_age_days_at_month_end,

    -- Changes (Step 5)
    b.previous_month_end_balance,
    b.absolute_balance_change,
    b.percentage_balance_change,

    -- Point-in-time flags (Step 6)
    EXISTS (
        SELECT 1
        FROM core.fct_cards c
        WHERE c.account_key = s.account_id
          AND c.issued_date <= s.month_end
    ) AS has_card_at_month_end,

    EXISTS (
        SELECT 1
        FROM core.fct_loans l
        WHERE l.account_key = s.account_id
          AND l.origination_date <= s.month_end
    ) AS has_loan_at_month_end

FROM spine s
LEFT JOIN activity a
    ON  a.account_key = s.account_id
    AND a.transaction_month = DATE_TRUNC('month', s.month_end)
LEFT JOIN with_changes b
    ON  b.account_id = s.account_id
    AND b.month_end = s.month_end;