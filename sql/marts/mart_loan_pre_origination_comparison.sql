CREATE OR REPLACE TABLE marts.mart_loan_pre_origination_comparison AS

SELECT
    'inflow' AS band_type,
    pre_origination_inflow_band AS band_value,
    COUNT(*) AS loan_count,
    SUM(loan_amount) AS original_principal_issued,
    COUNT(*) FILTER (WHERE status_code = 'A') AS completed_satisfactory_loans,
    COUNT(*) FILTER (WHERE status_code = 'B') AS completed_problem_loans,
    COUNT(*) FILTER (WHERE status_code = 'C') AS active_satisfactory_loans,
    COUNT(*) FILTER (WHERE status_code = 'D') AS active_loans_in_debt,
    COUNT(*) FILTER (WHERE status_code = 'B') * 1.0
        / NULLIF(COUNT(*) FILTER (WHERE status_code IN ('A', 'B')), 0)
        AS completed_problem_rate,
    COUNT(*) FILTER (WHERE status_code = 'D') * 1.0
        / NULLIF(COUNT(*) FILTER (WHERE status_code IN ('C', 'D')), 0)
        AS active_debt_rate,
    COUNT(payment_to_inflow_ratio) AS payment_to_inflow_eligible_loans
FROM marts.mart_loan_portfolio
GROUP BY pre_origination_inflow_band

UNION ALL

SELECT
    'balance',
    pre_origination_balance_band,
    COUNT(*),
    SUM(loan_amount),
    COUNT(*) FILTER (WHERE status_code = 'A'),
    COUNT(*) FILTER (WHERE status_code = 'B'),
    COUNT(*) FILTER (WHERE status_code = 'C'),
    COUNT(*) FILTER (WHERE status_code = 'D'),
    COUNT(*) FILTER (WHERE status_code = 'B') * 1.0
        / NULLIF(COUNT(*) FILTER (WHERE status_code IN ('A', 'B')), 0),
    COUNT(*) FILTER (WHERE status_code = 'D') * 1.0
        / NULLIF(COUNT(*) FILTER (WHERE status_code IN ('C', 'D')), 0),
    COUNT(payment_to_inflow_ratio)
FROM marts.mart_loan_portfolio
GROUP BY pre_origination_balance_band

UNION ALL

SELECT
    'payment_to_inflow',
    payment_to_inflow_band,
    COUNT(*),
    SUM(loan_amount),
    COUNT(*) FILTER (WHERE status_code = 'A'),
    COUNT(*) FILTER (WHERE status_code = 'B'),
    COUNT(*) FILTER (WHERE status_code = 'C'),
    COUNT(*) FILTER (WHERE status_code = 'D'),
    COUNT(*) FILTER (WHERE status_code = 'B') * 1.0
        / NULLIF(COUNT(*) FILTER (WHERE status_code IN ('A', 'B')), 0),
    COUNT(*) FILTER (WHERE status_code = 'D') * 1.0
        / NULLIF(COUNT(*) FILTER (WHERE status_code IN ('C', 'D')), 0),
    COUNT(payment_to_inflow_ratio)
FROM marts.mart_loan_portfolio
GROUP BY payment_to_inflow_band

