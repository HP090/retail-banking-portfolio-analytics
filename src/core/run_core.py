from pathlib import Path

import duckdb
import yaml


ROOT = Path(__file__).resolve().parents[2]

BASE_CONFIG_PATH = ROOT / "conf" / "base.yaml"
SQL_DIRECTORY = ROOT / "sql" / "core"


SQL_FILES = [
    "bridge_customer_account.sql",
    "dim_account.sql",
    "dim_customer.sql",
    "dim_date.sql",
    "dim_district.sql",
    "dim_transaction_type.sql",
    "fct_loans.sql",
    "fct_cards.sql",
    "fct_standing_orders.sql",
    "fct_transactions.sql",
    "fct_account_monthly_snapshot.sql"
]


def main():
    # Read  DuckDB path.
    with open(BASE_CONFIG_PATH,"r") as file:
        config = yaml.safe_load(file)

    database_path = (ROOT / config["paths"]["full_duckdb_path"])

    if not database_path.exists():
        raise FileNotFoundError(f"DuckDB database was not found: {database_path}")

    connection = duckdb.connect(str(database_path))

    try:
        connection.execute("CREATE SCHEMA IF NOT EXISTS core;")

        for sql_filename in SQL_FILES:
            sql_path = SQL_DIRECTORY / sql_filename

            if not sql_path.exists():
                raise FileNotFoundError(f"Core SQL file was not found: {sql_path}")

            sql = sql_path.read_text()

            connection.execute(sql)

            print(f"Completed {sql_filename}")



    finally:
        connection.close()
        print("DuckDB connection closed.")


if __name__ == "__main__":
    main()
