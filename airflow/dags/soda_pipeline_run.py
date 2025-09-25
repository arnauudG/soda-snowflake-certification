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

# Pipeline Run DAG - Regular Data Processing
with DAG(
    dag_id="soda_pipeline_run",
    default_args=default_args,
    description="Soda Pipeline Run: Regular data processing and quality monitoring",
    schedule_interval=None,  # Manual trigger only
    catchup=False,
    tags=["soda", "dbt", "data-quality", "pipeline", "regular"],
    doc_md="""
    # Soda Pipeline Run DAG
    
    This DAG handles **regular data processing** and quality monitoring.
    Use this DAG for daily/weekly pipeline runs after initialization is complete.
    
    ## What This DAG Does
    - **Runs dbt models** (RAW → STAGING → MART transformations)
    - **Executes Soda quality checks** on all layers
    - **Sends results to Soda Cloud** for monitoring
    - **Cleans up artifacts** and temporary files
    
    ## When to Use
    - ✅ **Daily/weekly pipeline runs**
    - ✅ **Regular data processing**
    - ✅ **Scheduled execution**
    - ✅ **After initialization is complete**
    
    ## Prerequisites
    - ⚠️ **Must run `soda_initialization` first** (one-time setup)
    - ⚠️ **Snowflake must be initialized** with sample data
    - ⚠️ **Environment variables must be configured**
    
    ## Tasks
    - **dbt_run**: Execute dbt models for all layers
    - **soda_scan_raw**: Data quality checks on RAW layer
    - **soda_scan_staging**: Data quality checks on STAGING layer  
    - **soda_scan_mart**: Data quality checks on MART layer
    - **soda_scan_quality**: Data quality checks on QUALITY layer
    - **cleanup**: Clean up temporary artifacts
    """,
):

    # =============================================================================
    # PIPELINE TASKS
    # =============================================================================
    
    pipeline_start = DummyOperator(
        task_id="pipeline_start",
        doc_md="🔄 Starting regular pipeline execution"
    )

    dbt_run = BashOperator(
        task_id="dbt_run",
        bash_command=BASH_PREFIX + "cd dbt && dbt run --profiles-dir . && dbt test --profiles-dir . || true",
        doc_md="""
        **Execute dbt Models**
        
        - Runs dbt models for all layers (RAW → STAGING → MART)
        - Executes dbt tests to validate data quality
        - Transforms raw data into business-ready analytics
        """,
    )

    # Soda scans for each layer
    soda_raw = BashOperator(
        task_id="soda_scan_raw",
        bash_command=BASH_PREFIX + "soda scan -d soda_certification_raw -c soda/configuration/configuration_raw.yml soda/checks/raw || true",
        doc_md="""
        **RAW Layer Quality Checks**
        
        - Lenient quality thresholds
        - Captures initial data issues
        - Expected: Some failures (demonstration purposes)
        """,
    )

    soda_staging = BashOperator(
        task_id="soda_scan_staging",
        bash_command=BASH_PREFIX + "soda scan -d soda_certification_staging -c soda/configuration/configuration_staging.yml soda/checks/staging || true",
        doc_md="""
        **STAGING Layer Quality Checks**
        
        - Stricter quality thresholds
        - Shows data improvement after transformation
        - Expected: Fewer failures than RAW layer
        """,
    )

    soda_mart = BashOperator(
        task_id="soda_scan_mart",
        bash_command=BASH_PREFIX + "soda scan -d soda_certification_mart -c soda/configuration/configuration_mart.yml soda/checks/mart || true",
        doc_md="""
        **MART Layer Quality Checks**
        
        - Strictest quality thresholds
        - Ensures business-ready data quality
        - Expected: Minimal failures (production-ready)
        """,
    )

    soda_quality = BashOperator(
        task_id="soda_scan_quality",
        bash_command=BASH_PREFIX + "soda scan -d soda_certification_quality -c soda/configuration/configuration_quality.yml soda/checks/quality || true",
        doc_md="""
        **QUALITY Layer Monitoring**
        
        - Monitors quality check execution
        - Tracks results and trends
        - Provides centralized quality monitoring
        """,
    )

    cleanup = BashOperator(
        task_id="cleanup_artifacts",
        bash_command=BASH_PREFIX + "rm -rf dbt/target dbt/logs snowflake_connection_test.log && true",
        doc_md="""
        **Clean Up Artifacts**
        
        - Removes temporary files and logs
        - Cleans up dbt artifacts
        - Prepares for next run
        """,
    )
    
    pipeline_end = DummyOperator(
        task_id="pipeline_end",
        doc_md="✅ Pipeline execution completed successfully!"
    )

    # =============================================================================
    # TASK DEPENDENCIES
    # =============================================================================
    
    # Pipeline flow
    pipeline_start >> dbt_run >> [soda_raw, soda_staging, soda_mart, soda_quality] >> cleanup >> pipeline_end
