"""Set up the raw schema and load NYC TLC yellow taxi trips into Snowflake.

Connection settings come from the git-ignored .env file in the repo root.

    python ingestion/load_nyc_taxi.py setup
    python ingestion/load_nyc_taxi.py load 2024-01 2024-02
"""

import argparse
import os
import re
from pathlib import Path
from string import Template

import requests
import snowflake.connector
from dotenv import load_dotenv

REPO_ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = REPO_ROOT / "data"
SETUP_SQL = REPO_ROOT / "snowflake" / "setup.sql"
TRIP_DATA_URL = "https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_{month}.parquet"


def connect() -> snowflake.connector.SnowflakeConnection:
    params = {
        "account": os.environ["SNOWFLAKE_ACCOUNT"],
        "user": os.environ["SNOWFLAKE_USER"],
        "authenticator": os.getenv("SNOWFLAKE_AUTHENTICATOR", "externalbrowser"),
        "role": os.environ["SNOWFLAKE_ROLE"],
        "warehouse": os.environ["SNOWFLAKE_WAREHOUSE"],
        "database": os.environ["SNOWFLAKE_DATABASE"],
        # Cache the SSO token so the browser only opens once
        "client_store_temporary_credential": True,
    }
    if os.getenv("SNOWFLAKE_PASSWORD"):
        params["password"] = os.environ["SNOWFLAKE_PASSWORD"]
    return snowflake.connector.connect(**params)


def setup() -> None:
    sql = Template(SETUP_SQL.read_text(encoding="utf-8")).substitute(os.environ)
    with connect() as conn:
        for cursor in conn.execute_string(sql):
            print(cursor.fetchone())


def download(month: str) -> Path:
    DATA_DIR.mkdir(exist_ok=True)
    target = DATA_DIR / f"yellow_tripdata_{month}.parquet"
    if target.exists():
        print(f"Already downloaded: {target.name}")
        return target
    url = TRIP_DATA_URL.format(month=month)
    print(f"Downloading {url}")
    with requests.get(url, stream=True, timeout=60) as response:
        response.raise_for_status()
        with open(target, "wb") as f:
            for chunk in response.iter_content(chunk_size=1 << 20):
                f.write(chunk)
    return target


def load(months: list[str]) -> None:
    for month in months:
        if not re.fullmatch(r"\d{4}-(0[1-9]|1[0-2])", month):
            raise SystemExit(f"Invalid month '{month}', expected YYYY-MM")

    files = [download(month) for month in months]
    with connect() as conn, conn.cursor() as cur:
        cur.execute(f"USE SCHEMA {os.environ['SNOWFLAKE_RAW_SCHEMA']}")
        for path in files:
            print(f"Uploading {path.name} to stage")
            cur.execute(
                f"PUT 'file://{path.as_posix()}' @STG_NYC_TAXI/yellow/ "
                "AUTO_COMPRESS = FALSE OVERWRITE = TRUE"
            )
            # COPY skips files it has already loaded, so re-running is safe
            cur.execute(
                f"""
                COPY INTO YELLOW_TRIPDATA
                FROM @STG_NYC_TAXI/yellow/
                FILES = ('{path.name}')
                FILE_FORMAT = (FORMAT_NAME = FF_PARQUET)
                MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
                INCLUDE_METADATA = (_SOURCE_FILE = METADATA$FILENAME, _LOADED_AT = METADATA$START_SCAN_TIME)
                ON_ERROR = ABORT_STATEMENT
                """
            )
            for row in cur.fetchall():
                print(row)


def main() -> None:
    load_dotenv(REPO_ROOT / ".env")
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("setup", help="create raw schema, file format, stage and table")
    load_parser = sub.add_parser("load", help="download and load one or more months")
    load_parser.add_argument("months", nargs="+", help="months as YYYY-MM, e.g. 2024-01")
    args = parser.parse_args()

    if args.command == "setup":
        setup()
    else:
        load(args.months)


if __name__ == "__main__":
    main()
