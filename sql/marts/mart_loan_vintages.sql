CREATE OR REPLACE TABLE mart.mart_loan_vintages AS

SELECT
    origination_year,

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

    MEDIAN(payment_to_inflow_ratio) AS median_payment_to_inflow_ratio,
    COUNT(payment_to_inflow_ratio) AS payment_to_inflow_eligible_loans

FROM mart.mart_loan_portfolio
GROUP BY origination_year
ORDER BY origination_year

