CREATE OR REPLACE TABLE marts.mart_portfolio_monthly_district AS

WITH
base AS (
    SELECT
        month_end,
        district_id,

        SUM(total_ledger_credits)        AS total_ledger_credits,
        SUM(external_credit_inflows)     AS external_credit_inflows,
        SUM(total_ledger_debits)         AS total_ledger_debits,
        SUM(net_ledger_cash_flow)        AS net_ledger_cash_flow,

        COUNT(*) FILTER (WHERE had_qualifying_activity)       AS active_accounts,
        COUNT(*) FILTER (WHERE balance_known_as_of_month_end) AS accounts_with_known_balance,
        COUNT(*) FILTER (WHERE month_end_balance < 0)         AS accounts_currently_overdrawn,
        COUNT(*) FILTER (WHERE has_card_at_month_end)         AS accounts_with_card,
        COUNT(*) FILTER (WHERE has_loan_at_month_end)         AS accounts_with_loan,
        COUNT(*)                                              AS total_accounts,

        SUM(GREATEST(month_end_balance, 0))
            FILTER (WHERE balance_known_as_of_month_end) AS positive_account_balances,
        SUM(ABS(LEAST(month_end_balance, 0)))
            FILTER (WHERE balance_known_as_of_month_end) AS overdrawn_exposure,

        MEDIAN(month_end_balance)
            FILTER (WHERE balance_known_as_of_month_end) AS median_observed_month_end_balance
    FROM core.fct_account_monthly_snapshot
    GROUP BY month_end, district_id
),

new_accounts AS (
    SELECT
        last_day(DATE_TRUNC('month', opened_date)) AS month_end,
        district_id,
        COUNT(*) AS newly_opened_accounts
    FROM core.dim_account
    GROUP BY last_day(DATE_TRUNC('month', opened_date)), district_id
),

new_loans AS (
    SELECT
        last_day(DATE_TRUNC('month', l.origination_date)) AS month_end,
        a.district_id,
        SUM(l.loan_amount) AS loan_principal_originated
    FROM core.fct_loans l
    JOIN core.dim_account a
        ON l.account_key = a.account_id
    GROUP BY last_day(DATE_TRUNC('month', l.origination_date)), a.district_id
),

growth AS (
    SELECT
        month_end,
        district_id,
        CASE
            WHEN LAG(positive_account_balances) OVER (
                     PARTITION BY district_id ORDER BY month_end
                 ) IS NULL
              OR LAG(positive_account_balances) OVER (
                     PARTITION BY district_id ORDER BY month_end
                 ) = 0
                THEN NULL
            ELSE
                (positive_account_balances
                 - LAG(positive_account_balances) OVER (
                       PARTITION BY district_id ORDER BY month_end
                   ))
                / LAG(positive_account_balances) OVER (
                      PARTITION BY district_id ORDER BY month_end
                  )
        END AS positive_balance_mom_growth_pct
    FROM base
),

-- Top 10% concentration within each district-month
eligible AS (
    SELECT
        month_end,
        district_id,
        account_id,
        month_end_balance AS positive_balance
    FROM core.fct_account_monthly_snapshot
    WHERE balance_known_as_of_month_end = TRUE
      AND month_end_balance > 0
),

ranked AS (
    SELECT
        month_end,
        district_id,
        account_id,
        positive_balance,
        ROW_NUMBER() OVER (
            PARTITION BY month_end, district_id
            ORDER BY positive_balance DESC, account_id
        ) AS rn,
        COUNT(*) OVER (PARTITION BY month_end, district_id) AS eligible_count
    FROM eligible
),

concentration AS (
    SELECT
        month_end,
        district_id,
        SUM(positive_balance)
            FILTER (WHERE rn <= CEIL(eligible_count * 0.10))
            / SUM(positive_balance)
            AS top_10pct_positive_balance_concentration
    FROM ranked
    GROUP BY month_end, district_id
)

SELECT
    b.*,
    (b.accounts_with_known_balance * 1.0 / b.total_accounts) * 100
        AS pct_accounts_with_known_balance,
    COALESCE(n.newly_opened_accounts, 0)              AS newly_opened_accounts,
    COALESCE(l.loan_principal_originated, 0)          AS loan_principal_originated,
    g.positive_balance_mom_growth_pct,
    c.top_10pct_positive_balance_concentration
FROM base b
LEFT JOIN new_accounts n
    ON  b.month_end = n.month_end
    AND b.district_id = n.district_id
LEFT JOIN new_loans l
    ON  b.month_end = l.month_end
    AND b.district_id = l.district_id
LEFT JOIN growth g
    ON  b.month_end = g.month_end
    AND b.district_id = g.district_id
LEFT JOIN concentration c
    ON  b.month_end = c.month_end
    AND b.district_id = c.district_id;