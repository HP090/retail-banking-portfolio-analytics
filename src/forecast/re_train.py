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

s = df.set_index("month_end")["actual_external_credit_inflows"].astype(float)
s.index = pd.to_datetime(s.index)
s = s.asfreq("ME")

train = s.loc[:'1998-12-31']

model = ExponentialSmoothing(
    train,
    trend="add",
    seasonal="add",
    seasonal_periods=12,
    damped_trend=False,
)
fitted = model.fit(optimized=True)
jan_1999 = float(fitted.forecast(1).iloc[0])

connection.execute("CREATE SCHEMA IF NOT EXISTS forecast")

connection.execute("""
    CREATE OR REPLACE TABLE forecast.forecast_jan_1999_planning_estimate AS
    SELECT
        DATE '1999-01-31' AS forecast_month,
        'exponential_smoothing_12m' AS method,
        ? AS forecast_external_credit_inflows,
        'Unevaluated January 1999 planning estimate' AS label
""", [jan_1999])

connection.close()


