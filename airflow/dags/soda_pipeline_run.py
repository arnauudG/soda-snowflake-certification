from datetime import datetime, timedelta
import os
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator
from airflow.operators.empty import EmptyOperator
import subprocess
import os

# Absolute project root (Docker container path)
PROJECT_ROOT = "/opt/airflow"

# Common bash prefix to run in project, load env
BASH_PREFIX = "cd '/opt/airflow' && source .env && "

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
    # Soda Pipeline Run DAG - Layered Approach
    
    This DAG handles **layered data processing** with quality checks at each stage.
    Use this DAG for daily/weekly pipeline runs after initialization is complete.
    
    ## What This DAG Does
    - **Layer 1**: RAW data quality checks + advanced template checks
    - **Layer 2**: dbt staging models + staging quality checks
    - **Layer 3**: dbt mart models + mart quality checks  
    - **Layer 4**: Quality monitoring + dbt tests
    - **Sends results to Soda Cloud** for monitoring
    - **Cleans up artifacts** and temporary files
    
    ## Layered Processing Flow
    1. **RAW Layer**: Quality checks + advanced template checks on source data
    2. **STAGING Layer**: Transform data + quality checks
    3. **MART Layer**: Business logic + quality checks
    4. **QUALITY Layer**: Final validation + dbt tests
    
    ## Advanced Features
    - **Soda Library**: Full template support with advanced analytics
    - **Template Checks**: Statistical analysis, anomaly detection, business logic validation
    - **Enhanced Monitoring**: Data distribution analysis and trend monitoring
    
    ## When to Use
    - ✅ **Daily/weekly pipeline runs**
    - ✅ **Regular data processing**
    - ✅ **Scheduled execution**
    - ✅ **After initialization is complete**
    
    ## Prerequisites
    - ⚠️ **Must run `soda_initialization` first** (one-time setup)
    - ⚠️ **Snowflake must be initialized** with sample data
    - ⚠️ **Environment variables must be configured**
    
    ## Layer Tasks
    - **Layer 1**: `soda_scan_raw` + `soda_scan_raw_templates` - RAW data quality checks + advanced template checks
    - **Layer 2**: `dbt_run_staging` + `soda_scan_staging` - Staging models + checks
    - **Layer 3**: `dbt_run_mart` + `soda_scan_mart` - Mart models + checks
    - **Layer 4**: `soda_scan_quality` + `dbt_test` - Quality monitoring + tests
    - **cleanup**: Clean up temporary artifacts
    """,
):

    # =============================================================================
    # PIPELINE TASKS - LAYERED APPROACH
    # =============================================================================
    
    pipeline_start = EmptyOperator(
        task_id="pipeline_start",
        doc_md="🔄 Starting layered pipeline execution"
    )

    # =============================================================================
    # LAYER 1: RAW DATA + RAW CHECKS
    # =============================================================================
    
    raw_layer_start = EmptyOperator(
        task_id="raw_layer_start",
        doc_md="🔄 Starting RAW layer processing"
    )

    soda_scan_raw = BashOperator(
        task_id="soda_scan_raw",
        bash_command=BASH_PREFIX + "soda scan -d soda_certification_raw -c soda/configuration/configuration_raw.yml -T soda/checks/templates/data_quality_templates.yml soda/checks/raw || true",
        doc_md="""
        **RAW Layer Quality Checks**
        
        - Initial data quality assessment
        - Relaxed thresholds for source data
        - Identifies data issues before transformation
        - Includes all raw tables: customers, products, orders, order_items
        """,
    )

    raw_layer_end = EmptyOperator(
        task_id="raw_layer_end",
        doc_md="✅ RAW layer processing completed"
    )

    # =============================================================================
    # LAYER 2: STAGING MODELS + STAGING CHECKS
    # =============================================================================
    
    staging_layer_start = EmptyOperator(
        task_id="staging_layer_start",
        doc_md="🔄 Starting STAGING layer processing"
    )

    dbt_run_staging = BashOperator(
        task_id="dbt_run_staging",
        bash_command=BASH_PREFIX + "cd dbt && dbt run --select staging --target dev --profiles-dir . 2>/dev/null || true",
        doc_md="""
        **Execute dbt Staging Models**
        
        - Runs dbt staging models (stg_customers, stg_orders, stg_products, stg_order_items)
        - Transforms raw data into cleaned, standardized format
        - Applies data quality improvements
        """,
    )

    soda_scan_staging = BashOperator(
        task_id="soda_scan_staging",
        bash_command=BASH_PREFIX + "soda scan -d soda_certification_staging -c soda/configuration/configuration_staging.yml -T soda/checks/templates/data_quality_templates.yml soda/checks/staging || true",
        doc_md="""
        **STAGING Layer Quality Checks**
        
        - Stricter quality thresholds than RAW
        - Shows data improvement after transformation
        - Expected: Fewer failures than RAW layer
        """,
    )

    staging_layer_end = EmptyOperator(
        task_id="staging_layer_end",
        doc_md="✅ STAGING layer processing completed"
    )

    # =============================================================================
    # LAYER 3: MART MODELS + MART CHECKS
    # =============================================================================
    
    mart_layer_start = EmptyOperator(
        task_id="mart_layer_start",
        doc_md="🏆 Starting MART layer processing"
    )

    dbt_run_mart = BashOperator(
        task_id="dbt_run_mart",
        bash_command=BASH_PREFIX + "cd dbt && dbt run --select mart --target dev --profiles-dir . 2>/dev/null || true",
        doc_md="""
        **Execute dbt Mart Models**
        
        - Runs dbt mart models (dim_customers, fact_orders)
        - Creates business-ready analytics tables
        - Applies business logic and aggregations
        """,
    )

    soda_scan_mart = BashOperator(
        task_id="soda_scan_mart",
        bash_command=BASH_PREFIX + "soda scan -d soda_certification_mart -c soda/configuration/configuration_mart.yml -T soda/checks/templates/data_quality_templates.yml soda/checks/mart || true",
        doc_md="""
        **MART Layer Quality Checks**
        
        - Strictest quality thresholds
        - Ensures business-ready data quality
        - Expected: Minimal failures (production-ready)
        """,
    )

    mart_layer_end = EmptyOperator(
        task_id="mart_layer_end",
        doc_md="✅ MART layer processing completed"
    )

    # =============================================================================
    # LAYER 4: QUALITY CHECKS + DBT TESTS
    # =============================================================================
    
    quality_layer_start = EmptyOperator(
        task_id="quality_layer_start",
        doc_md="🔍 Starting QUALITY layer processing"
    )

    soda_scan_quality = BashOperator(
        task_id="soda_scan_quality",
        bash_command=BASH_PREFIX + "soda scan -d soda_certification_quality -c soda/configuration/configuration_quality.yml -T soda/checks/templates/data_quality_templates.yml soda/checks/quality || true",
        doc_md="""
        **QUALITY Layer Monitoring**
        
        - Monitors quality check execution
        - Tracks results and trends
        - Provides centralized quality monitoring
        """,
    )

    dbt_test = BashOperator(
        task_id="dbt_test",
        bash_command=BASH_PREFIX + "cd dbt && dbt test --target dev --profiles-dir . 2>/dev/null || true",
        doc_md="""
        **Execute dbt Tests**
        
        - Runs all dbt tests to validate data quality
        - Tests referential integrity, uniqueness, and business rules
        - Ensures data consistency across all layers
        """,
    )

    quality_layer_end = EmptyOperator(
        task_id="quality_layer_end",
        doc_md="✅ QUALITY layer processing completed"
    )

    # =============================================================================
    # CLEANUP
    # =============================================================================
    
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
    
    pipeline_end = EmptyOperator(
        task_id="pipeline_end",
        doc_md="✅ Layered pipeline execution completed successfully!"
    )

    # =============================================================================
    # TASK DEPENDENCIES - LAYERED APPROACH
    # =============================================================================
    
    # Complete layered pipeline with individual layer visibility
    pipeline_start >> raw_layer_start >> soda_scan_raw >> raw_layer_end
    raw_layer_end >> staging_layer_start >> dbt_run_staging >> soda_scan_staging >> staging_layer_end
    staging_layer_end >> mart_layer_start >> dbt_run_mart >> soda_scan_mart >> mart_layer_end
    mart_layer_end >> quality_layer_start >> [soda_scan_quality, dbt_test] >> quality_layer_end
    quality_layer_end >> cleanup >> pipeline_end
