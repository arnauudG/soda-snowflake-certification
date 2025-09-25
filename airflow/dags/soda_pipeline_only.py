from datetime import datetime, timedelta
import os
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.dummy import DummyOperator

# Absolute project root (Docker container path)
PROJECT_ROOT = "/opt/airflow"

# Common bash prefix to run in project, load env
BASH_PREFIX = f"cd '{PROJECT_ROOT}' && source .env && "

# Default arguments
default_args = {
    'owner': 'data-team',
    'depends_on_past': False,
    'start_date': datetime(2025, 1, 1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

# Pipeline-only DAG
with DAG(
    dag_id="soda_pipeline_only",
    default_args=default_args,
    description="Soda Pipeline Only: dbt models and Soda data quality checks (no initialization)",
    schedule_interval=None,  # Manual trigger only
    catchup=False,
    tags=["soda", "dbt", "data-quality", "pipeline"],
    doc_md="""
    # Soda Pipeline Only
    
    This DAG runs only the pipeline tasks (dbt models and Soda checks).
    Use this DAG for regular pipeline execution after initialization is complete.
    
    ## Tasks
    - **dbt_run**: Execute dbt models for all layers
    - **soda_scan_raw**: Data quality checks on RAW layer
    - **soda_scan_staging**: Data quality checks on STAGING layer  
    - **soda_scan_mart**: Data quality checks on MART layer
    - **soda_scan_quality**: Data quality checks on QUALITY layer
    - **cleanup**: Clean up temporary artifacts
    
    ## Usage
    - Trigger this DAG manually whenever you want to run the pipeline
    - Results are automatically sent to Soda Cloud platform
    - Make sure Snowflake is already initialized before running
    """,
):

    pipeline_start = DummyOperator(
        task_id="pipeline_start",
        doc_md="Start of pipeline execution"
    )

    dbt_run = BashOperator(
        task_id="dbt_run",
        bash_command=BASH_PREFIX + "cd dbt && dbt run --profiles-dir . && dbt test --profiles-dir . || true",
        doc_md="Execute dbt models for all layers (RAW → STAGING → MART)",
    )

    # Soda scans for each layer
    soda_raw = BashOperator(
        task_id="soda_scan_raw",
        bash_command=BASH_PREFIX + "soda scan -d soda_certification_raw -c soda/configuration/configuration_raw.yml soda/checks/raw || true",
        doc_md="Data quality checks on RAW layer (lenient thresholds)",
    )

    soda_staging = BashOperator(
        task_id="soda_scan_staging",
        bash_command=BASH_PREFIX + "soda scan -d soda_certification_staging -c soda/configuration/configuration_staging.yml soda/checks/staging || true",
        doc_md="Data quality checks on STAGING layer (stricter thresholds)",
    )

    soda_mart = BashOperator(
        task_id="soda_scan_mart",
        bash_command=BASH_PREFIX + "soda scan -d soda_certification_mart -c soda/configuration/configuration_mart.yml soda/checks/mart || true",
        doc_md="Data quality checks on MART layer (strictest thresholds)",
    )

    soda_quality = BashOperator(
        task_id="soda_scan_quality",
        bash_command=BASH_PREFIX + "soda scan -d soda_certification_quality -c soda/configuration/configuration_quality.yml soda/checks/quality || true",
        doc_md="Data quality checks on QUALITY layer (monitoring)",
    )

    cleanup = BashOperator(
        task_id="cleanup_artifacts",
        bash_command=BASH_PREFIX + "rm -rf dbt/target dbt/logs snowflake_connection_test.log && true",
        doc_md="Clean up temporary artifacts and logs",
    )
    
    pipeline_end = DummyOperator(
        task_id="pipeline_end",
        doc_md="Pipeline execution completed"
    )

    # Task dependencies
    pipeline_start >> dbt_run >> [soda_raw, soda_staging, soda_mart, soda_quality] >> cleanup >> pipeline_end
