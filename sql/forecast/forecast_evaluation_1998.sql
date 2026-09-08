CREATE OR REPLACE TABLE forecast.forecast_evaluation_1998 AS

SELECT
    'moving_average_3m' AS method,
    COUNT(*) AS n_months,
    SUM(ABS(actual_external_credit_inflows - forecast_ma3)) * 1.0 / COUNT(*) AS mae,
    SUM(ABS(actual_external_credit_inflows - forecast_ma3))
        / SUM(ABS(actual_external_credit_inflows)) AS wape,
    SUM(forecast_ma3 - actual_external_credit_inflows) * 1.0 / COUNT(*) AS signed_bias
FROM mart.mart_monthly_inflow_forecast
WHERE month_end BETWEEN DATE '1998-01-31' AND DATE '1998-12-31'
  AND forecast_ma3 IS NOT NULL

UNION ALL

SELECT
    'seasonal_naive_12m',
    COUNT(*),
    SUM(ABS(actual_external_credit_inflows - forecast_seasonal_naive)) * 1.0 / COUNT(*),
    SUM(ABS(actual_external_credit_inflows - forecast_seasonal_naive))
        / SUM(ABS(actual_external_credit_inflows)),
    SUM(forecast_seasonal_naive - actual_external_credit_inflows) * 1.0 / COUNT(*)
FROM mart.mart_monthly_inflow_forecast
WHERE month_end BETWEEN DATE '1998-01-31' AND DATE '1998-12-31'
  AND forecast_seasonal_naive IS NOT NULL

UNION ALL

SELECT
    'exponential_smoothing_12m',
    COUNT(*),
    SUM(ABS(actual_external_credit_inflows - forecast_ets)) * 1.0 / COUNT(*),
    SUM(ABS(actual_external_credit_inflows - forecast_ets))
        / SUM(ABS(actual_external_credit_inflows)),
    SUM(forecast_ets - actual_external_credit_inflows) * 1.0 / COUNT(*)
FROM mart.mart_monthly_inflow_forecast
WHERE month_end BETWEEN DATE '1998-01-31' AND DATE '1998-12-31'
  AND forecast_ets IS NOT NULL


