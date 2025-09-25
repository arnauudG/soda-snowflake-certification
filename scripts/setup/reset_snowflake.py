#!/usr/bin/env python3
"""
Reset Snowflake environment for Soda Certification project.

Drops and recreates the SODA_CERTIFICATION database to start from a clean state.

Usage:
  python3 scripts/setup/reset_snowflake.py [--force]

Requires Snowflake env vars to be loaded.
"""
import os
import sys
import argparse
import logging
import snowflake.connector


logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


def _normalize_account(acc: str) -> str:
    if not acc:
        return acc
    acc = acc.strip().lower()
    if acc.endswith(".snowflakecomputing.com"):
        acc = acc.split(".snowflakecomputing.com")[0]
    return acc


def connect_snowflake():
    account = _normalize_account(os.getenv("SNOWFLAKE_ACCOUNT"))
    user = os.getenv("SNOWFLAKE_USER")
    password = os.getenv("SNOWFLAKE_PASSWORD")
    warehouse = os.getenv("SNOWFLAKE_WAREHOUSE", "SODA_WH")
    role = os.getenv("SNOWFLAKE_ROLE")

    if not all([account, user, password]):
        raise RuntimeError("Missing Snowflake env vars: SNOWFLAKE_ACCOUNT, SNOWFLAKE_USER, SNOWFLAKE_PASSWORD")

    logger.info("Connecting to Snowflake (reset)...")
    conn = snowflake.connector.connect(
        account=account,
        user=user,
        password=password,
        warehouse=warehouse,
        role=role,
        insecure_mode=True,
    )
    return conn


def reset_database(conn):
    cur = conn.cursor()
    try:
        logger.info("Dropping database SODA_CERTIFICATION if exists (cascade)...")
        cur.execute("DROP DATABASE IF EXISTS SODA_CERTIFICATION CASCADE")
        logger.info("Creating database SODA_CERTIFICATION...")
        cur.execute("CREATE DATABASE SODA_CERTIFICATION")
        logger.info("Reset complete.")
    finally:
        cur.close()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--force", action="store_true", help="Do not prompt for confirmation")
    args = parser.parse_args()

    if not args.force:
        reply = input("This will DROP the SODA_CERTIFICATION database. Continue? [y/N]: ").strip().lower()
        if reply not in ("y", "yes"):
            print("Aborted.")
            sys.exit(0)

    conn = connect_snowflake()
    try:
        reset_database(conn)
    finally:
        conn.close()


if __name__ == "__main__":
    main()


