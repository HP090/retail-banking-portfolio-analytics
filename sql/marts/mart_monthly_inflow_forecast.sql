CREATE OR REPLACE TABLE mart.mart_monthly_inflow_forecast AS

SELECT
    month_end,
    total_external_credit_inflows AS actual_external_credit_inflows,
    AVG(total_external_credit_inflows) OVER (ORDER BY month_end ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING)
        AS forecast_ma3,
    LAG(total_external_credit_inflows, 12) OVER (ORDER BY month_end) AS forecast_seasonal_naive
FROM mart.mart_monthly_forecast_input
ORDER BY month_end

