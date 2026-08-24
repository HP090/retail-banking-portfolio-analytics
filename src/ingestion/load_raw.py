import csv
from pathlib import Path

import duckdb
import yaml

ROOT = Path(__file__).resolve().parents[2]
base_yaml = ROOT/"conf"/ "base.yaml"


RAW_NULL_SENTINEL = "__RAW_NULL_SENTINEL__"

def escape_sql_string(value):
    return str(value).replace("'","''")


def main():
    with open(base_yaml, "r") as file:
        config = yaml.safe_load(file)

    raw_dir = ROOT / config["paths"]["raw_data_dir"]
    db_path = ROOT /config["paths"]["full_duckdb_path"]

    db_path.parent.mkdir(parents=True, exist_ok=True)

    # ---------------------------------------------------------
    # 2. Map source filenames to DuckDB table names
    # ---------------------------------------------------------

    table_mapping = {
        "account": "accounts",
        "client": "clients",
        "disp": "dispositions",
        "trans": "transactions",
        "loan": "loans",
        "card": "cards",
        "order": "orders",
        "district": "districts",
    }

    # ---------------------------------------------------------
    # 3. Find all eight source files
    # ---------------------------------------------------------

    source_files = {}

    for source_name in table_mapping:
        csv_path = raw_dir / f"{source_name}.csv"

        if csv_path.exists():
            source_files[source_name] = csv_path

        else:
            raise FileNotFoundError(
                f"Could not find {source_name}.csv in {raw_dir}")

    print("All eight source files were found.")

    # ---------------------------------------------------------
    # 4. Connect to DuckDB
    # ---------------------------------------------------------

    print(f"Connecting to DuckDB at {db_path}...")

    connection = duckdb.connect(str(db_path))
    load_summary = []

    try:
        connection.execute("CREATE SCHEMA IF NOT EXISTS raw;")

        # -----------------------------------------------------
        # 5. Load each source file
        # -----------------------------------------------------

        for source_name, target_table in table_mapping.items():
            file_to_load = source_files[source_name]

            safe_path = escape_sql_string(file_to_load)
            safe_filename = escape_sql_string(file_to_load.name)

            # Ask DuckDB to inspect the file format.
            detected_delimiter, has_header = connection.execute(
                f"""
                SELECT
                    Delimiter,
                    HasHeader
                FROM sniff_csv('{safe_path}');
                """
            ).fetchone()

            if not has_header:
                raise ValueError(
                    f"{file_to_load.name} does not appear to have a header."
                )

            safe_delimiter = escape_sql_string(detected_delimiter)

            print(
                f"Loading {file_to_load.name} into raw.{target_table} "
                f"using delimiter {detected_delimiter!r}..."
            )

            connection.execute(
                f"""
                CREATE OR REPLACE TABLE raw.{target_table} AS
                SELECT
                    *,
                    CURRENT_TIMESTAMP AS loaded_at,
                    '{safe_filename}' AS source_file
                FROM read_csv(
                    '{safe_path}',
                    all_varchar = TRUE,
                    auto_detect = TRUE,
                    header = TRUE,
                    delim = '{safe_delimiter}',
                    nullstr = '{RAW_NULL_SENTINEL}',
                    strict_mode = TRUE
                );
                """
            )

            row_count = connection.execute(
                f"""
                SELECT COUNT(*)
                FROM raw.{target_table};
                """
            ).fetchone()[0]

            print(f"Loaded {row_count:,} rows.")

            load_summary.append(
                {
                    "source_relation": source_name,
                    "source_file": file_to_load.name,
                    "raw_table": f"raw.{target_table}",
                    "detected_delimiter": repr(detected_delimiter),
                    "row_count": row_count,
                }
            )

    finally:
        connection.close()

    # ---------------------------------------------------------
    # 6. Save a simple ingestion manifest
    # ---------------------------------------------------------

    manifest_path = Path(
        ROOT / "artifacts" / "profiling" / "source_manifest.csv"
    )

    manifest_path.parent.mkdir(parents=True, exist_ok=True)

    with open(manifest_path,"w",newline="") as file:
        writer = csv.DictWriter(
            file,
            fieldnames=[
                "source_relation",
                "source_file",
                "raw_table",
                "detected_delimiter",
                "row_count",
            ],
        )

        writer.writeheader()
        writer.writerows(load_summary)

    print()
    print("All eight source tables were successfully ingested.")
    print(f"DuckDB database: {db_path}")
    print(f"Source manifest: {manifest_path}")


if __name__ == "__main__":
    main()












