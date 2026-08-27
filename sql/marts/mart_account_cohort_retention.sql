CREATE OR REPLACE TABLE mart.mart_account_cohort_retention AS

WITH
-- Step 1: first-activity month
first_activity AS (
    SELECT
        account_id,
        MIN(month_end) AS cohort_month
    FROM core.fct_account_monthly_snapshot
    WHERE had_qualifying_activity = TRUE
    GROUP BY account_id
),

-- Observable month list
month_ends AS (
    SELECT last_day(d) AS activity_month
    FROM (
        SELECT UNNEST(generate_series(
            DATE '1993-01-01',
            DATE '1998-12-31',
            INTERVAL '1 month'
        )) AS d
    )
),

-- Step 2: observable account × later-month grid
df2 AS (
    SELECT
        f.account_id,
        f.cohort_month,
        m.activity_month,
        DATE_DIFF('month', f.cohort_month, m.activity_month) AS months_since_first_activity
    FROM first_activity f INNER JOIN month_ends m
    ON m.activity_month >= f.cohort_month
),

-- Step 3: active / not active in each later month
df3 AS (
    SELECT
        d.account_id,
        d.cohort_month,
        d.activity_month,
        d.months_since_first_activity,
        COALESCE(s.had_qualifying_activity, FALSE) AS is_active
    FROM df2 d LEFT JOIN core.fct_account_monthly_snapshot s
    ON  d.account_id = s.account_id AND d.activity_month = s.month_end
),

-- Step 4: retention
retention AS (
    SELECT
        cohort_month,
        activity_month,
        months_since_first_activity,
        COUNT(*) AS cohort_size,
        COUNT(*) FILTER (WHERE is_active = TRUE) AS active_accounts,
        COUNT(*) FILTER (WHERE is_active = TRUE) * 1.0 / COUNT(*) AS activity_retention_rate
    FROM df3
    GROUP BY
        cohort_month,
        activity_month,
        months_since_first_activity
),

-- Step 5a: attach balances and inflows to the account-level grid
join_df AS (
    SELECT
        d.*,
        s.month_end_balance,
        s.balance_known_as_of_month_end,
        s.external_credit_inflows
    FROM df3 d LEFT JOIN core.fct_account_monthly_snapshot s
    ON  d.account_id = s.account_id AND d.activity_month = s.month_end
),

-- Step 5b: full-cohort averages and coverage
cohort_economics AS (
    SELECT
        cohort_month,
        activity_month,
        months_since_first_activity,
        AVG(month_end_balance)
            FILTER (WHERE balance_known_as_of_month_end) AS avg_month_end_balance,
        AVG(COALESCE(external_credit_inflows, 0)) AS avg_external_credit_inflow,
        COUNT(*) FILTER (WHERE balance_known_as_of_month_end) * 1.0 / COUNT(*)
            AS balance_observation_coverage
    FROM join_df
    GROUP BY
        cohort_month,
        activity_month,
        months_since_first_activity
)

-- Step 6: final assembly
SELECT
    r.cohort_month,
    r.activity_month,
    r.months_since_first_activity,
    r.cohort_size,
    r.active_accounts,
    r.activity_retention_rate,
    e.avg_month_end_balance,
    e.avg_external_credit_inflow,
    e.balance_observation_coverage
FROM retention r LEFT JOIN cohort_economics e
ON  r.cohort_month = e.cohort_month AND r.activity_month = e.activity_month
        AND r.months_since_first_activity = e.months_since_first_activity


