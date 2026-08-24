CREATE OR REPLACE TABLE marts.mart_portfolio_monthly AS

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
)

SELECT
    b.*,
    (b.accounts_with_known_balance * 1.0 / b.total_accounts) * 100
        AS pct_accounts_with_known_balance,
    COALESCE(n.newly_opened_accounts, 0) AS newly_opened_accounts,
    COALESCE(l.loan_principal_originated, 0) AS loan_principal_originated
FROM base b
LEFT JOIN new_accounts n ON b.month_end = n.month_end
LEFT JOIN new_loans l    ON b.month_end = l.month_end;

