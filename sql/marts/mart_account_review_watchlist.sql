CREATE OR REPLACE TABLE mart.mart_account_review_watchlist AS

WITH base_data AS (
    SELECT
        account_id,
        district_id,
        snapshot_date,
        latest_observed_balance,
        last_qualifying_activity_date,
        recency_days,
        monetary_score,
        (monetary_score >= 4) AS flag_high_value
    FROM mart.mart_relationship_segments
),

cashflow_3m AS (
    SELECT
        a.account_id,
        COUNT(*) FILTER (WHERE b.net_ledger_cash_flow < 0) = 3
            AS flag_three_months_negative_cashflow
    FROM base_data a
    LEFT JOIN core.fct_account_monthly_snapshot b
        ON  a.account_id = b.account_id
        AND b.month_end IN (
            DATE '1998-10-31',
            DATE '1998-11-30',
            DATE '1998-12-31'
        )
    GROUP BY a.account_id
),

balance_flags AS (
    SELECT
        a.account_id,
        MAX(CASE
            WHEN b.month_end = DATE '1998-12-31'
             AND b.balance_known_as_of_month_end
                THEN b.month_end_balance
        END) AS current_balance,
        MAX(CASE
            WHEN b.month_end = DATE '1998-06-30'
             AND b.balance_known_as_of_month_end
                THEN b.month_end_balance
        END) AS balance_6m_ago,
        MAX(CASE
            WHEN b.month_end = DATE '1998-12-31'
             AND b.balance_known_as_of_month_end
                THEN b.month_end
        END) AS latest_balance_date
    FROM base_data a
    LEFT JOIN core.fct_account_monthly_snapshot b
        ON  a.account_id = b.account_id
        AND b.month_end IN (DATE '1998-06-30', DATE '1998-12-31')
    GROUP BY a.account_id
),

inactivity_flags AS (
    SELECT
        account_id,
        CASE
            WHEN flag_high_value
             AND recency_days >= 90
             AND recency_days < 180
                THEN TRUE
            ELSE FALSE
        END AS flag_high_value_dormant,
        CASE
            WHEN flag_high_value
             AND recency_days >= 180
                THEN TRUE
            ELSE FALSE
        END AS flag_high_value_lapsed
    FROM base_data
),

loan_d_flag AS (
    SELECT
        account_key AS account_id,
        TRUE AS flag_active_loan_status_d
    FROM core.fct_loans
    WHERE status_code = 'D'
    GROUP BY account_key
),

combined AS (
    SELECT
        a.account_id,
        a.district_id,
        a.snapshot_date,
        a.last_qualifying_activity_date,
        a.recency_days,
        bf.current_balance AS latest_observed_balance,
        bf.latest_balance_date,
        DATE_DIFF('day', bf.latest_balance_date, a.snapshot_date) AS balance_age_days,

        COALESCE(c.flag_three_months_negative_cashflow, FALSE) AS flag_three_months_negative_cashflow,
        CASE
            WHEN bf.balance_6m_ago > 0
             AND bf.current_balance <= 0.50 * bf.balance_6m_ago
                THEN TRUE
            ELSE FALSE
        END AS flag_balance_drop_50pct_6m,
        COALESCE(bf.current_balance < 0, FALSE) AS flag_negative_balance,
        COALESCE(i.flag_high_value_dormant, FALSE) AS flag_high_value_dormant,
        COALESCE(i.flag_high_value_lapsed, FALSE) AS flag_high_value_lapsed,
        COALESCE(d.flag_active_loan_status_d, FALSE) AS flag_active_loan_status_d
    FROM base_data a
    LEFT JOIN cashflow_3m c
        ON a.account_id = c.account_id
    LEFT JOIN balance_flags bf
        ON a.account_id = bf.account_id
    LEFT JOIN inactivity_flags i
        ON a.account_id = i.account_id
    LEFT JOIN loan_d_flag d
        ON a.account_id = d.account_id
)

SELECT
    account_id,
    district_id,
    snapshot_date,
    latest_observed_balance,
    latest_balance_date,
    balance_age_days,
    last_qualifying_activity_date,
    recency_days,

    flag_three_months_negative_cashflow,
    flag_balance_drop_50pct_6m,
    flag_negative_balance,
    flag_high_value_dormant,
    flag_high_value_lapsed,
    flag_active_loan_status_d,

    CASE
        WHEN flag_active_loan_status_d THEN 1
        WHEN flag_negative_balance THEN 2
        WHEN flag_balance_drop_50pct_6m THEN 3
        WHEN flag_three_months_negative_cashflow THEN 4
        WHEN flag_high_value_lapsed THEN 5
        WHEN flag_high_value_dormant THEN 6
        ELSE NULL
    END AS review_priority,

    CASE
        WHEN flag_active_loan_status_d THEN 'critical'
        WHEN flag_negative_balance OR flag_balance_drop_50pct_6m THEN 'high'
        WHEN flag_three_months_negative_cashflow OR flag_high_value_lapsed THEN 'medium'
        WHEN flag_high_value_dormant THEN 'watch'
        ELSE NULL
    END AS review_severity,

    NULLIF(
        TRIM(BOTH '; ' FROM
            CASE WHEN flag_active_loan_status_d
                THEN 'Active loan has status D at dataset end; ' ELSE '' END ||
            CASE WHEN flag_negative_balance
                THEN 'Latest observed balance is negative; ' ELSE '' END ||
            CASE WHEN flag_balance_drop_50pct_6m
                THEN 'Latest balance declined by at least 50% versus six months earlier; ' ELSE '' END ||
            CASE WHEN flag_three_months_negative_cashflow
                THEN 'Three consecutive months of negative net cash flow; ' ELSE '' END ||
            CASE WHEN flag_high_value_lapsed
                THEN 'High-value relationship inactive for at least 180 days; ' ELSE '' END ||
            CASE WHEN flag_high_value_dormant
                THEN 'High-value relationship inactive for 90 to 179 days; ' ELSE '' END
        ),
        ''
    ) AS review_reason

FROM combined
WHERE flag_three_months_negative_cashflow
   OR flag_balance_drop_50pct_6m
   OR flag_negative_balance
   OR flag_high_value_dormant
   OR flag_high_value_lapsed
   OR flag_active_loan_status_d

