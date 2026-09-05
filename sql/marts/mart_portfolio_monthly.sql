CREATE OR REPLACE TABLE mart.mart_portfolio_monthly AS

WITH
base AS (
    SELECT
        month_end,
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
    GROUP BY month_end
),

new_accounts AS (
    SELECT
        last_day(DATE_TRUNC('month', opened_date)) AS month_end,
        COUNT(*) AS newly_opened_accounts
    FROM core.dim_account
    GROUP BY last_day(DATE_TRUNC('month', opened_date))
),

new_loans AS (
    SELECT
        last_day(DATE_TRUNC('month', origination_date)) AS month_end,
        SUM(loan_amount) AS loan_principal_originated
    FROM core.fct_loans
    GROUP BY last_day(DATE_TRUNC('month', origination_date))
),

growth AS (
    SELECT
        month_end,
        CASE
            WHEN LAG(positive_account_balances) OVER (ORDER BY month_end) IS NULL
            OR LAG(positive_account_balances) OVER (ORDER BY month_end) = 0
                THEN NULL
            ELSE
                (positive_account_balances - LAG(positive_account_balances) OVER (ORDER BY month_end))
                / LAG(positive_account_balances) OVER (ORDER BY month_end)
        END AS positive_balance_mom_growth_pct
    FROM base
),


-- The top 10 percent
-- Eligible accounts only (known + positive balance)
eligible AS (
    SELECT
        month_end,
        account_id,
        month_end_balance AS positive_balance
    FROM core.fct_account_monthly_snapshot
    WHERE balance_known_as_of_month_end = TRUE
      AND month_end_balance > 0
),

--  Rank them inside each month
ranked AS (
    SELECT
        month_end,
        account_id,
        positive_balance,
        ROW_NUMBER() OVER (
            PARTITION BY month_end
            ORDER BY positive_balance DESC, account_id
        ) AS rn,
        COUNT(*) OVER (PARTITION BY month_end) AS eligible_count
    FROM eligible
),

--  Keep only the top 10% and calculate concentration
concentration AS (
    SELECT
        month_end,
        SUM(positive_balance)
            FILTER (WHERE rn <= CEIL(eligible_count * 0.10))   -- top 10%
            / SUM(positive_balance)                            -- all eligible
            AS top_10pct_positive_balance_concentration
    FROM ranked
    GROUP BY month_end
)

SELECT
    b.*,
    (b.accounts_with_known_balance * 1.0 / b.total_accounts) * 100
        AS pct_accounts_with_known_balance,
    COALESCE(n.newly_opened_accounts, 0) AS newly_opened_accounts,
    COALESCE(l.loan_principal_originated, 0) AS loan_principal_originated,
    g.positive_balance_mom_growth_pct,
    c.top_10pct_positive_balance_concentration
FROM base b
LEFT JOIN new_accounts n ON b.month_end = n.month_end
LEFT JOIN new_loans l    ON b.month_end = l.month_end
LEFT JOIN growth g ON b.month_end = g.month_end
LEFT JOIN concentration c on b.month_end = c.month_end;