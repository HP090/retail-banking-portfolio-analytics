CREATE OR REPLACE TABLE mart.mart_relationship_segments AS

WITH accounts AS (
    SELECT
        account_id,
        district_id,
        opened_date,
        DATE '1998-12-31' AS snapshot_date
    FROM core.dim_account
),

last_activity AS (
    SELECT
        a.account_id,
        a.district_id,
        a.opened_date,
        a.snapshot_date,
        MAX(t.transaction_date) FILTER (
            WHERE t.is_qualifying_account_activity = TRUE
              AND t.transaction_date <= a.snapshot_date
        ) AS last_qualifying_activity_date
    FROM accounts a
    LEFT JOIN core.fct_transactions t
        ON a.account_id = t.account_key
    GROUP BY
        a.account_id,
        a.district_id,
        a.opened_date,
        a.snapshot_date
),

recency AS (
    SELECT
        account_id,
        district_id,
        opened_date,
        snapshot_date,
        last_qualifying_activity_date,
        DATE_DIFF('day', last_qualifying_activity_date, snapshot_date) AS recency_days,
        last_qualifying_activity_date IS NOT NULL AS has_qualifying_activity_history
    FROM last_activity
),

trailing_12m AS (
    SELECT
        account_id,
        COUNT(*) FILTER (WHERE had_qualifying_activity = TRUE) AS frequency,
        COUNT(*) FILTER (WHERE balance_known_as_of_month_end = TRUE) AS balance_observation_months,
        SUM(COALESCE(external_credit_inflows, 0)) AS total_external_credit_inflows_12m,
        SUM(COALESCE(total_ledger_debits, 0)) AS total_ledger_debits_12m,
        AVG(GREATEST(month_end_balance, 0))
            FILTER (WHERE balance_known_as_of_month_end = TRUE) AS monetary_value
    FROM core.fct_account_monthly_snapshot
    WHERE month_end > DATE '1998-12-31' - INTERVAL 12 MONTH
      AND month_end <= DATE '1998-12-31'
    GROUP BY account_id
),

latest_balance AS (
    SELECT
        account_id,
        ARG_MAX(month_end_balance, month_end)
            FILTER (WHERE balance_known_as_of_month_end = TRUE) AS latest_observed_balance
    FROM core.fct_account_monthly_snapshot
    WHERE month_end <= DATE '1998-12-31'
    GROUP BY account_id
),

balance_points AS (
    SELECT
        account_id,
        MAX(month_end_balance) FILTER (
            WHERE month_end = DATE '1998-12-31'
              AND balance_known_as_of_month_end = TRUE
        ) AS balance_snapshot,
        MAX(month_end_balance) FILTER (
            WHERE month_end = DATE '1998-09-30'
              AND balance_known_as_of_month_end = TRUE
        ) AS balance_3m_ago,
        MAX(month_end_balance) FILTER (
            WHERE month_end = DATE '1998-06-30'
              AND balance_known_as_of_month_end = TRUE
        ) AS balance_6m_ago
    FROM core.fct_account_monthly_snapshot
    GROUP BY account_id
),

balance_changes AS (
    SELECT
        account_id,
        balance_snapshot,
        balance_3m_ago,
        balance_6m_ago,
        balance_snapshot - balance_3m_ago AS balance_change_3m,
        balance_snapshot - balance_6m_ago AS balance_change_6m,
        CASE
            WHEN balance_3m_ago > 0
                THEN (balance_snapshot - balance_3m_ago) / balance_3m_ago
            ELSE NULL
        END AS balance_change_3m_pct,
        CASE
            WHEN balance_6m_ago > 0
                THEN (balance_snapshot - balance_6m_ago) / balance_6m_ago
            ELSE NULL
        END AS balance_change_6m_pct
    FROM balance_points
),

card_flag AS (
    SELECT
        a.account_id,
        COUNT(c.card_id) > 0 AS has_card_at_snapshot
    FROM accounts a
    LEFT JOIN core.fct_cards c
        ON  a.account_id = c.account_key
        AND c.issued_date <= a.snapshot_date
    GROUP BY a.account_id
),

loan_flag AS (
    SELECT
        a.account_id,
        COUNT(l.loan_id) > 0 AS has_loan_at_snapshot
    FROM accounts a
    LEFT JOIN core.fct_loans l
        ON  a.account_id = l.account_key
        AND l.origination_date <= a.snapshot_date
    GROUP BY a.account_id
),

product AS (
    SELECT
        a.account_id,
        1
        + CASE WHEN cf.has_card_at_snapshot THEN 1 ELSE 0 END
        + CASE WHEN lf.has_loan_at_snapshot THEN 1 ELSE 0 END AS product_category_count,
        cf.has_card_at_snapshot,
        lf.has_loan_at_snapshot
    FROM accounts a
    LEFT JOIN card_flag cf
        ON a.account_id = cf.account_id
    LEFT JOIN loan_flag lf
        ON a.account_id = lf.account_id
),

scored AS (
    SELECT
        r.account_id,
        r.district_id,
        r.opened_date,
        r.snapshot_date,
        r.last_qualifying_activity_date,
        r.recency_days,
        r.has_qualifying_activity_history,

        COALESCE(t.frequency, 0) AS frequency,
        COALESCE(t.balance_observation_months, 0) AS balance_observation_months,
        COALESCE(t.total_external_credit_inflows_12m, 0) AS total_external_credit_inflows_12m,
        COALESCE(t.total_ledger_debits_12m, 0) AS total_ledger_debits_12m,
        t.monetary_value,

        l.latest_observed_balance,
        b.balance_change_3m,
        b.balance_change_6m,
        b.balance_change_3m_pct,
        b.balance_change_6m_pct,

        p.product_category_count,
        p.has_card_at_snapshot,
        p.has_loan_at_snapshot,

        CASE
            WHEN r.has_qualifying_activity_history
                THEN NTILE(5) OVER (
                    PARTITION BY r.has_qualifying_activity_history
                    ORDER BY r.recency_days DESC, r.account_id
                )
            ELSE NULL
        END AS recency_score,

        NTILE(5) OVER (
            ORDER BY COALESCE(t.frequency, 0) ASC, r.account_id
        ) AS frequency_score,

        CASE
            WHEN t.monetary_value IS NOT NULL
                THEN NTILE(5) OVER (
                    PARTITION BY t.monetary_value IS NOT NULL
                    ORDER BY t.monetary_value ASC, r.account_id
                )
            ELSE NULL
        END AS monetary_score
    FROM recency r
    LEFT JOIN trailing_12m t
        ON r.account_id = t.account_id
    LEFT JOIN latest_balance l
        ON r.account_id = l.account_id
    LEFT JOIN balance_changes b
        ON r.account_id = b.account_id
    LEFT JOIN product p
        ON r.account_id = p.account_id
)

SELECT
    s.*,

    CASE
        WHEN s.latest_observed_balance < 0
            THEN 'overdrawn_review'

        WHEN s.has_qualifying_activity_history
         AND s.recency_days <= 90
         AND s.opened_date >= DATE '1998-07-01'
            THEN 'recently_acquired_first_active'

        WHEN s.monetary_score >= 4
         AND (s.recency_days > 180 OR s.recency_score IS NULL)
            THEN 'high_value_lapsed'

        WHEN s.monetary_score >= 4
         AND COALESCE(s.recency_score, 1) <= 2
            THEN 'high_value_dormant'

        WHEN s.recency_score >= 4
         AND s.frequency_score >= 4
         AND s.monetary_score >= 4
            THEN 'core_relationships'

        WHEN s.recency_score >= 4
         AND s.frequency_score >= 3
            THEN 'active_developing'

        WHEN s.frequency_score <= 2
         AND COALESCE(s.monetary_score, 1) <= 2
            THEN 'low_engagement'

        ELSE 'standard'
    END AS primary_segment,

    (s.latest_observed_balance < 0) AS flag_overdrawn,
    (s.monetary_score >= 4) AS flag_high_value,
    (NOT s.has_qualifying_activity_history) AS flag_no_activity_history,
    s.has_card_at_snapshot AS flag_has_card,
    s.has_loan_at_snapshot AS flag_has_loan,
    (s.balance_change_3m < 0 OR s.balance_change_6m < 0) AS flag_balance_declining
FROM scored s;
