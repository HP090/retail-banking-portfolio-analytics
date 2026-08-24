from pathlib import Path

import duckdb
import yaml


ROOT = Path(__file__).resolve().parents[2]

BASE_CONFIG_PATH = ROOT / "conf" / "base.yaml"
SQL_DIRECTORY = ROOT / "sql" / "staging"


SQL_FILES = [
    "01_stg_accounts.sql",
    "02_stg_clients.sql",
    "03_stg_dispositions.sql",
    "04_stg_cards.sql",
    "05_stg_orders.sql",
    "06_stg_districts.sql",
    "07_stg_loans.sql",
    "08_stg_transactions.sql",
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
        connection.execute("CREATE SCHEMA IF NOT EXISTS staging;")

        for sql_filename in SQL_FILES:
            sql_path = SQL_DIRECTORY / sql_filename

            if not sql_path.exists():
                raise FileNotFoundError(f"Staging SQL file was not found: {sql_path}")

            sql = sql_path.read_text()

            connection.execute(sql)

            print(f"Completed {sql_filename}")



    finally:
        connection.close()
        print("DuckDB connection closed.")


if __name__ == "__main__":
    main()
















