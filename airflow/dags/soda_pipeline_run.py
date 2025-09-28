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
    # Soda Pipeline Run DAG - Layered Approach
    
    This DAG handles **layered data processing** with quality checks at each stage.
    Use this DAG for daily/weekly pipeline runs after initialization is complete.
    
    ## What This DAG Does
    - **Layer 1**: RAW data quality checks
    - **Layer 2**: dbt staging models + staging quality checks
    - **Layer 3**: dbt mart models + mart quality checks  
    - **Layer 4**: Quality monitoring + dbt tests
    - **Sends results to Soda Cloud** for monitoring
    - **Cleans up artifacts** and temporary files
    
    ## Layered Processing Flow
    1. **RAW Layer**: Quality checks on source data
    2. **STAGING Layer**: Transform data + quality checks
    3. **MART Layer**: Business logic + quality checks
    4. **QUALITY Layer**: Final validation + dbt tests
    
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
    - **Layer 1**: `soda_scan_raw` - RAW data quality checks
    - **Layer 2**: `dbt_run_staging` + `soda_scan_staging` - Staging models + checks
    - **Layer 3**: `dbt_run_mart` + `soda_scan_mart` - Mart models + checks
    - **Layer 4**: `soda_scan_quality` + `dbt_test` - Quality monitoring + tests
    - **cleanup**: Clean up temporary artifacts
    """,
):

    # =============================================================================
    # PIPELINE TASKS - LAYERED APPROACH
    # =============================================================================
    
    pipeline_start = DummyOperator(
        task_id="pipeline_start",
        doc_md="🔄 Starting layered pipeline execution"
    )

    # =============================================================================
    # LAYER 1: RAW DATA + RAW CHECKS
    # =============================================================================
    
    raw_layer_start = DummyOperator(
        task_id="raw_layer_start",
        doc_md="📊 Starting RAW layer processing"
    )

    soda_scan_raw = BashOperator(
        task_id="soda_scan_raw",
        bash_command=BASH_PREFIX + "soda scan -d soda_certification_raw -c soda/configuration/configuration_raw.yml soda/checks/raw || true",
        doc_md="""
        **RAW Layer Quality Checks**
        
        - Lenient quality thresholds
        - Captures initial data issues
        - Expected: Some failures (demonstration purposes)
        """,
    )

    raw_layer_end = DummyOperator(
        task_id="raw_layer_end",
        doc_md="✅ RAW layer processing completed"
    )

    # =============================================================================
    # LAYER 2: STAGING MODELS + STAGING CHECKS
    # =============================================================================
    
    staging_layer_start = DummyOperator(
        task_id="staging_layer_start",
        doc_md="🔄 Starting STAGING layer processing"
    )

    dbt_run_staging = BashOperator(
        task_id="dbt_run_staging",
        bash_command=BASH_PREFIX + "cd dbt && dbt run --models staging --profiles-dir . || true",
        doc_md="""
        **Execute dbt Staging Models**
        
        - Runs dbt staging models (stg_customers, stg_orders, stg_products, stg_order_items)
        - Transforms raw data into cleaned, standardized format
        - Applies data quality improvements
        """,
    )

    soda_scan_staging = BashOperator(
        task_id="soda_scan_staging",
        bash_command=BASH_PREFIX + "soda scan -d soda_certification_staging -c soda/configuration/configuration_staging.yml soda/checks/staging || true",
        doc_md="""
        **STAGING Layer Quality Checks**
        
        - Stricter quality thresholds than RAW
        - Shows data improvement after transformation
        - Expected: Fewer failures than RAW layer
        """,
    )

    staging_layer_end = DummyOperator(
        task_id="staging_layer_end",
        doc_md="✅ STAGING layer processing completed"
    )

    # =============================================================================
    # LAYER 3: MART MODELS + MART CHECKS
    # =============================================================================
    
    mart_layer_start = DummyOperator(
        task_id="mart_layer_start",
        doc_md="🏆 Starting MART layer processing"
    )

    dbt_run_mart = BashOperator(
        task_id="dbt_run_mart",
        bash_command=BASH_PREFIX + "cd dbt && dbt run --models marts --profiles-dir . || true",
        doc_md="""
        **Execute dbt Mart Models**
        
        - Runs dbt mart models (dim_customers, fact_orders)
        - Creates business-ready analytics tables
        - Applies business logic and aggregations
        """,
    )

    soda_scan_mart = BashOperator(
        task_id="soda_scan_mart",
        bash_command=BASH_PREFIX + "soda scan -d soda_certification_mart -c soda/configuration/configuration_mart.yml soda/checks/mart || true",
        doc_md="""
        **MART Layer Quality Checks**
        
        - Strictest quality thresholds
        - Ensures business-ready data quality
        - Expected: Minimal failures (production-ready)
        """,
    )

    mart_layer_end = DummyOperator(
        task_id="mart_layer_end",
        doc_md="✅ MART layer processing completed"
    )

    # =============================================================================
    # LAYER 4: QUALITY CHECKS + DBT TESTS
    # =============================================================================
    
    quality_layer_start = DummyOperator(
        task_id="quality_layer_start",
        doc_md="🔍 Starting QUALITY layer processing"
    )

    soda_scan_quality = BashOperator(
        task_id="soda_scan_quality",
        bash_command=BASH_PREFIX + "soda scan -d soda_certification_quality -c soda/configuration/configuration_quality.yml soda/checks/quality || true",
        doc_md="""
        **QUALITY Layer Monitoring**
        
        - Monitors quality check execution
        - Tracks results and trends
        - Provides centralized quality monitoring
        """,
    )

    dbt_test = BashOperator(
        task_id="dbt_test",
        bash_command=BASH_PREFIX + "cd dbt && dbt test --profiles-dir . || true",
        doc_md="""
        **Execute dbt Tests**
        
        - Runs all dbt tests to validate data quality
        - Tests referential integrity, uniqueness, and business rules
        - Ensures data consistency across all layers
        """,
    )

    quality_layer_end = DummyOperator(
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
    
    pipeline_end = DummyOperator(
        task_id="pipeline_end",
        doc_md="✅ Layered pipeline execution completed successfully!"
    )

    # =============================================================================
    # TASK DEPENDENCIES - LAYERED APPROACH
    # =============================================================================
    
    # Layer 1: RAW
    pipeline_start >> raw_layer_start >> soda_scan_raw >> raw_layer_end
    
    # Layer 2: STAGING (depends on RAW completion)
    raw_layer_end >> staging_layer_start >> dbt_run_staging >> soda_scan_staging >> staging_layer_end
    
    # Layer 3: MART (depends on STAGING completion)
    staging_layer_end >> mart_layer_start >> dbt_run_mart >> soda_scan_mart >> mart_layer_end
    
    # Layer 4: QUALITY (depends on MART completion)
    mart_layer_end >> quality_layer_start >> [soda_scan_quality, dbt_test] >> quality_layer_end
    
    # Final cleanup
    quality_layer_end >> cleanup >> pipeline_end
