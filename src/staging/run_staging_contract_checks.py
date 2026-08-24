from pathlib import Path
import duckdb
import yaml
import numpy
import pandas

SQL_FILES = [
    "01_stg_primary_keys.sql",
    "02_stg_foreign_keys.sql",
    "03_stg_date_ranges.sql",
    "04_stg_value_constraints.sql",
    "05_stg_ownership.sql",
    "06_stg_card_and_code_checks.sql",
]


ROOT = Path(__file__).resolve().parents[2]
base_yaml = ROOT/"conf"/"base.yaml"
sql_files = ROOT/"sql"/"staging_contract_checks"
csv_file_path = ROOT / "artifacts" / "staging_profiling"

with open(base_yaml, "r") as file:
   config = yaml.safe_load(file)


db_path = ROOT / config["paths"]["full_duckdb_path"]

csv_file_path.mkdir(parents=True, exist_ok=True)

connection = duckdb.connect(str(db_path))

for file in SQL_FILES:
    with open(sql_files / file, "r") as f:
        sql = f.read()

    result = connection.execute(sql)
    out_path = csv_file_path / Path(file).with_suffix(".csv")
    result.fetchdf().to_csv(out_path, index=False)


connection.close()
