CREATE OR REPLACE TABLE mart.mart_monthly_forecast_input AS

SELECT
    month_end,
    external_credit_inflows AS total_external_credit_inflows,
    total_ledger_credits,
    total_ledger_debits,
    net_ledger_cash_flow,
    active_accounts,
    accounts_with_known_balance AS accounts_with_observed_balance,
    total_accounts AS accounts_observable_from_opening
FROM mart.mart_portfolio_monthly
ORDER BY month_end