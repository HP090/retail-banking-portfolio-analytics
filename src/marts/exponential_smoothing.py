from pathlib import Path
import duckdb
import pandas as pd
import yaml
from statsmodels.tsa.holtwinters import ExponentialSmoothing

ROOT = Path(__file__).resolve().parents[2]
BASE_CONFIG_PATH = ROOT / "conf" / "base.yaml"

with open(BASE_CONFIG_PATH, "r") as file:
    config = yaml.safe_load(file)

database_path = ROOT / config["paths"]["full_duckdb_path"]

if not database_path.exists():
    raise FileNotFoundError(f"DuckDB database was not found: {database_path}")

connection = duckdb.connect(str(database_path))

df = connection.execute("""
    SELECT month_end, actual_external_credit_inflows
    FROM mart.mart_monthly_inflow_forecast
    ORDER BY month_end
""").fetchdf()

df = df.set_index("month_end").sort_index()
s = df["actual_external_credit_inflows"].astype(float)

forecasts = []

for pred_month in s.index:
    train = s[s.index < pred_month]

    if len(train) < 24:
        forecasts.append((pred_month, None))
        continue

    model = ExponentialSmoothing(
        train,
        trend="add",
        seasonal="add",
        seasonal_periods=12,
        damped_trend=False,
    )
    fitted = model.fit(optimized=True)
    yhat = float(fitted.forecast(1).iloc[0])
    forecasts.append((pred_month, yhat))

ets = pd.DataFrame(forecasts, columns=["month_end", "forecast_ets"])

connection.execute("""
    CREATE OR REPLACE TABLE mart.mart_monthly_inflow_forecast AS
    SELECT
        f.month_end,
        f.actual_external_credit_inflows,
        f.forecast_ma3,
        f.forecast_seasonal_naive,
        e.forecast_ets
    FROM mart.mart_monthly_inflow_forecast f
    LEFT JOIN ets e
        ON f.month_end = e.month_end
    ORDER BY f.month_end
""")

connection.close()


