CREATE OR REPLACE TABLE mart.mart_portfolio_flow_composition AS

SELECT
    last_day(DATE_TRUNC('month', t.transaction_date)) AS month_end,
    a.district_id,
    t.direction,
    t.operation,
    t.purpose,
    SUM(t.amount) AS total_amount,
    COUNT(*)      AS transaction_count
FROM core.fct_transactions t JOIN core.dim_account a
ON t.account_key = a.account_id
GROUP BY
    last_day(DATE_TRUNC('month', t.transaction_date)),
    a.district_id,
    t.direction,
    t.operation,
    t.purpose;