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

# Initialization DAG - Run Once for Fresh Setup
with DAG(
    dag_id="soda_initialization",
    default_args=default_args,
    description="Soda Initialization: Fresh Snowflake setup with sample data (run once)",
    schedule_interval=None,  # Manual trigger only
    catchup=False,
    tags=["soda", "snowflake", "initialization", "setup"],
    doc_md="""
    # Soda Initialization DAG
    
    This DAG handles the **initial setup** of the Soda Certification project.
    Run this DAG **ONCE** when setting up the project for the first time or when you need a fresh start.
    
    ## What This DAG Does
    - **Resets Snowflake database** (removes all existing data)
    - **Creates schemas and tables** (RAW, STAGING, MART, QUALITY)
    - **Generates sample data** with intentional quality issues
    - **Sets up the foundation** for data quality monitoring
    
    ## When to Use
    - ✅ **First-time setup** of the project
    - ✅ **Fresh start** when you want to reset everything
    - ✅ **Testing** with clean data
    - ✅ **Demonstration** purposes
    
    ## When NOT to Use
    - ❌ **Regular pipeline runs** (use `soda_pipeline_run` instead)
    - ❌ **When you have existing data** you want to keep
    - ❌ **Production environments** with live data
    
    ## After Running This DAG
    Once initialization is complete, use `soda_pipeline_run` for regular data processing.
    """,
):

    # =============================================================================
    # INITIALIZATION TASKS
    # =============================================================================
    
    init_start = DummyOperator(
        task_id="init_start",
        doc_md="🚀 Starting Soda Certification initialization process"
    )
    
    reset_snowflake = BashOperator(
        task_id="reset_snowflake",
        bash_command=BASH_PREFIX + "python3 scripts/setup/reset_snowflake.py --force",
        doc_md="""
        **Reset Snowflake Database**
        
        - Drops existing database and schemas
        - Removes all existing data
        - Creates fresh database structure
        - ⚠️ **WARNING**: This will delete all existing data!
        """,
    )

    setup_snowflake = BashOperator(
        task_id="setup_snowflake", 
        bash_command=BASH_PREFIX + "python3 scripts/setup/setup_snowflake.py",
        doc_md="""
        **Initialize Snowflake with Sample Data**
        
        - Creates RAW, STAGING, MART, QUALITY schemas
        - Generates sample customer, product, order data
        - Introduces intentional quality issues for demonstration
        - Sets up the foundation for data quality monitoring
        """,
    )
    
    init_end = DummyOperator(
        task_id="init_end",
        doc_md="✅ Initialization complete! Ready for pipeline runs."
    )

    # =============================================================================
    # TASK DEPENDENCIES
    # =============================================================================
    
    # Initialization flow
    init_start >> reset_snowflake >> setup_snowflake >> init_end
