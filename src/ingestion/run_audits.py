from pathlib import Path
import duckdb
import yaml
import numpy
import pandas

file_names = [
   "01_structure.sql",
   "02_primary_keys.sql",
   "03_missingness_and_codes.sql",
   "04_date_ranges.sql",
   "05_foreign_keys.sql",
   "06_financial_ranges.sql"
]


ROOT = Path(__file__).resolve().parents[2]
base_yaml = ROOT/"conf"/"base.yaml"
sql_files = ROOT/"sql"/"audits"
csv_file_path = ROOT / "artifacts" / "profiling"

with open(base_yaml, "r") as file:
   config = yaml.safe_load(file)


db_path = ROOT / config["paths"]["full_duckdb_path"]

csv_file_path.mkdir(parents=True, exist_ok=True)

connection = duckdb.connect(str(db_path))

for file in file_names:
    with open(sql_files / file, "r") as f:
        sql = f.read()

    result = connection.execute(sql)
    out_path = csv_file_path / Path(file).with_suffix(".csv")
    result.fetchdf().to_csv(out_path, index=False)


connection.close()










