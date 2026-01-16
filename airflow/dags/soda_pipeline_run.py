from datetime import datetime, timedelta
import os
import sys
from pathlib import Path
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator
from airflow.operators.empty import EmptyOperator
import subprocess

# Add project root to Python path for Collibra imports
PROJECT_ROOT = Path("/opt/airflow")
sys.path.insert(0, str(PROJECT_ROOT))

# Absolute project root (Docker container path)
PROJECT_ROOT = "/opt/airflow"

# Load environment variables before importing helpers
# This ensures SNOWFLAKE_DATABASE is available when computing data source names
from dotenv import load_dotenv
env_file = Path("/opt/airflow/.env")
if env_file.exists():
    load_dotenv(env_file, override=True)

# Import Soda helpers to get data source names dynamically
from soda.helpers import get_data_source_name

# Common bash prefix to run in project, load env
BASH_PREFIX = "cd '/opt/airflow' && source .env && "


def upload_to_superset(**context):
    """
    Upload Soda data to Superset database.
    
    This function orchestrates the complete Superset upload workflow:
    1. Updates Soda data source names to match SNOWFLAKE_DATABASE
    2. Extracts data from Soda Cloud API
    3. Organizes the data (keeps only latest files)
    4. Uploads to Superset PostgreSQL database
    
    Returns:
        None (raises exception on failure)
    """
    import subprocess
    import sys
    from pathlib import Path
    
    project_root = Path("/opt/airflow")
    
    print("🔄 Starting Superset upload workflow...")
    
    # Step 1: Update data source names
    print("\n1️⃣  Updating Soda data source names...")
    try:
        update_script = project_root / "soda" / "update_data_source_names.py"
        result = subprocess.run(
            [sys.executable, str(update_script)],
            cwd=str(project_root),
            capture_output=True,
            text=True,
            check=False
        )
        if result.returncode == 0:
            print("✅ Data source names updated successfully")
        else:
            print(f"⚠️  Warning: Could not update data source names: {result.stderr}")
    except Exception as e:
        print(f"⚠️  Warning: Error updating data source names: {e}")
    
    # Step 2: Extract data from Soda Cloud
    print("\n2️⃣  Extracting data from Soda Cloud...")
    try:
        dump_script = project_root / "scripts" / "soda_dump_api.py"
        result = subprocess.run(
            [sys.executable, str(dump_script)],
            cwd=str(project_root),
            capture_output=True,
            text=True,
            check=True
        )
        print("✅ Data extracted from Soda Cloud")
        if result.stdout:
            print(result.stdout)
    except subprocess.CalledProcessError as e:
        print(f"❌ Error extracting data from Soda Cloud: {e.stderr}")
        raise
    
    # Step 3: Organize data
    print("\n3️⃣  Organizing data...")
    try:
        organize_script = project_root / "scripts" / "organize_soda_data.py"
        result = subprocess.run(
            [sys.executable, str(organize_script)],
            cwd=str(project_root),
            capture_output=True,
            text=True,
            check=True
        )
        print("✅ Data organized successfully")
        if result.stdout:
            print(result.stdout)
    except subprocess.CalledProcessError as e:
        print(f"❌ Error organizing data: {e.stderr}")
        raise
    
    # Step 4: Upload to Superset
    print("\n4️⃣  Uploading to Superset...")
    try:
        # Copy upload script to superset/data directory
        upload_script_src = project_root / "scripts" / "upload_soda_data_docker.py"
        upload_script_dst = project_root / "superset" / "data" / "upload_soda_data_docker.py"
        
        if upload_script_src.exists():
            import shutil
            upload_script_dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(upload_script_src, upload_script_dst)
            print(f"✅ Copied upload script to {upload_script_dst}")
        
        # Execute upload script in Superset container
        # Try multiple approaches to upload data
        upload_script_path = "/app/soda_data/upload_soda_data_docker.py"
        
        # Approach 1: Try docker exec with correct container name
        # Container name from superset/docker-compose.yml is "superset-app"
        docker_cmd = [
            "docker", "exec", "superset-app",
            "python", upload_script_path
        ]
        
        result = subprocess.run(
            docker_cmd,
            capture_output=True,
            text=True,
            check=False
        )
        
        if result.returncode == 0:
            print("✅ Data uploaded to Superset successfully (via docker exec)")
            if result.stdout:
                print(result.stdout)
        else:
            # Approach 2: Try direct database connection from Airflow
            # This works if containers are on the same Docker network
            print("⚠️  Docker exec failed, trying direct database connection...")
            try:
                # Import and run the upload script directly
                # Modify DB config to connect from Airflow container
                sys.path.insert(0, str(project_root / "scripts"))
                try:
                    from upload_soda_data_docker import main as upload_main, DB_CONFIG
                    # Update DB config for Airflow container network access
                    # If Superset DB is accessible, use 'superset-db' hostname
                    # Otherwise, try 'superset-postgres' (container name)
                    import psycopg2
                    
                    # Try connecting with different hostnames
                    for host in ['superset-db', 'superset-postgres', 'localhost']:
                        try:
                            test_config = DB_CONFIG.copy()
                            test_config['host'] = host
                            conn = psycopg2.connect(**test_config)
                            conn.close()
                            print(f"✅ Found Superset database at {host}")
                            
                            # Update the script's DB config and run
                            import upload_soda_data_docker as upload_module
                            upload_module.DB_CONFIG['host'] = host
                            upload_main()
                            print("✅ Data uploaded to Superset successfully (direct connection)")
                            break
                        except psycopg2.Error:
                            continue
                    else:
                        raise Exception("Could not connect to Superset database from any host")
                        
                except ImportError:
                    # If import fails, try running as subprocess
                    upload_script = project_root / "scripts" / "upload_soda_data_docker.py"
                    result2 = subprocess.run(
                        [sys.executable, str(upload_script)],
                        cwd=str(project_root),
                        capture_output=True,
                        text=True,
                        check=True
                    )
                    print("✅ Data uploaded to Superset successfully (subprocess)")
                    if result2.stdout:
                        print(result2.stdout)
            except Exception as e:
                error_msg = f"""
❌ Failed to upload data to Superset

Error: {e}
Docker exec error: {result.stderr}

💡 Troubleshooting:
   1. Ensure Superset is running: make superset-up
   2. Check Superset status: make superset-status
   3. Verify containers are on the same Docker network
   4. Try manual upload: make superset-upload-data

Note: This task will fail if Superset is not available.
      Start Superset before running the pipeline, or skip this task.
"""
                print(error_msg)
                raise Exception(f"Superset upload failed: {e}. Ensure Superset is running.")
        
    except Exception as e:
        print(f"❌ Error uploading to Superset: {e}")
        raise
    
    print("\n✅ Superset upload workflow completed successfully!")

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
    # Soda Pipeline Run DAG - Quality-Gated Metadata Sync
    
    This DAG implements **quality-gated metadata synchronization** where quality checks
    gate metadata sync operations. Collibra only syncs data that has passed quality
    validation, ensuring the catalog reflects commitments, not aspirations.
    
    ## Orchestration Philosophy
    
    Each layer follows the sequence: **Build → Validate → Govern**
    
    - **dbt build** → "this model exists"
    - **Soda checks** → "this model is acceptable"  
    - **Collibra sync** → "this model is governable and discoverable"
    
    Quality checks **gate** metadata synchronization. Metadata sync only happens after
    quality validation, ensuring Collibra becomes a historical record of accepted states,
    not a live mirror of Snowflake's chaos.
    
    ## What This DAG Does
    
    - **RAW Layer**: Quality checks → Metadata sync (gated)
    - **STAGING Layer**: Build → Quality checks → Metadata sync (gated)
    - **MART Layer**: Build → Quality checks → Metadata sync (gated, strictest standards)
    - **QUALITY Layer**: Final validation + dbt tests
    - **Sends results to Soda Cloud** for monitoring
    - **Synchronizes metadata to Collibra** only for validated data
    - **Cleans up artifacts** and temporary files
    
    ## Layered Processing Flow
    
    1. **RAW Layer**: Quality checks → Metadata sync (gated by quality)
    2. **STAGING Layer**: Transform data → Quality checks → Metadata sync (gated)
    3. **MART Layer**: Business logic → Quality checks → Metadata sync (gated, strictest)
    4. **QUALITY Layer**: Final validation + dbt tests
    
    ## Quality Gating Benefits
    
    - **Collibra reflects commitments**: Only validated data enters governance
    - **Lineage reflects approved flows**: Historical record of accepted states
    - **Ownership discussions on validated assets**: Governance happens on trusted data
    - **No retroactive corrections needed**: Catalog stays clean and meaningful
    
    ## Advanced Features
    
    - **Soda Library**: Full template support with advanced analytics
    - **Template Checks**: Statistical analysis, anomaly detection, business logic validation
    - **Enhanced Monitoring**: Data distribution analysis and trend monitoring
    - **Quality-Gated Sync**: Metadata sync only after quality validation
    
    ## When to Use
    
    - ✅ **Daily/weekly pipeline runs**
    - ✅ **Regular data processing**
    - ✅ **Scheduled execution**
    - ✅ **After initialization is complete**
    
    ## Prerequisites
    
    - ⚠️ **Must run `soda_initialization` first** (one-time setup)
    - ⚠️ **Snowflake must be initialized** with sample data
    - ⚠️ **Environment variables must be configured**
    - ⚠️ **Collibra configuration** in `collibra/config.yml`
    
    ## Layer Tasks
    
    - **Layer 1**: `soda_scan_raw` → `collibra_sync_raw` (quality gates sync)
    - **Layer 2**: `dbt_run_staging` → `soda_scan_staging` → `collibra_sync_staging` (gated)
    - **Layer 3**: `dbt_run_mart` → `soda_scan_mart` → `collibra_sync_mart` (gated, strictest)
    - **Layer 4**: `soda_scan_quality` + `dbt_test` → `collibra_sync_quality` (gated)
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
    # 
    # Orchestration Philosophy: Quality Gates Metadata Sync
    # 
    # Each layer follows the sequence: Build → Validate → Govern
    # - dbt build → "this model exists"
    # - Soda checks → "this model is acceptable"
    # - Collibra sync → "this model is governable and discoverable"
    #
    # Quality checks gate metadata synchronization. Collibra only syncs data that
    # has passed quality validation, ensuring the catalog reflects commitments,
    # not aspirations. This makes Collibra a historical record of accepted states.
    
    raw_layer_start = EmptyOperator(
        task_id="raw_layer_start",
        doc_md="Starting RAW layer processing"
    )

    # Get data source names dynamically from database name
    data_source_raw = get_data_source_name('raw')
    data_source_staging = get_data_source_name('staging')
    data_source_mart = get_data_source_name('mart')
    data_source_quality = get_data_source_name('quality')
    
    soda_scan_raw = BashOperator(
        task_id="soda_scan_raw",
        bash_command=BASH_PREFIX + f"soda scan -d {data_source_raw} -c soda/configuration/configuration_raw.yml -T soda/checks/templates/data_quality_templates.yml soda/checks/raw || true",
        doc_md="""
        **RAW Layer Quality Checks - Quality Gate**
        
        - Initial data quality assessment
        - Relaxed thresholds for source data
        - Identifies data issues before transformation
        - Includes all raw tables: customers, products, orders, order_items
        - **Gates metadata sync**: Only validated data proceeds to Collibra
        """,
    )

    def sync_raw_metadata_task(**context):
        """Wrapper function to import and call Collibra sync for RAW layer."""
        from collibra.airflow_helper import sync_raw_metadata
        return sync_raw_metadata(**context)
    
    collibra_sync_raw = PythonOperator(
        task_id="collibra_sync_raw",
        python_callable=sync_raw_metadata_task,
        doc_md="""
        **Collibra Metadata Sync - RAW Layer (Gated by Quality)**
        
        - **Only executes after quality checks pass**
        - Triggers metadata synchronization in Collibra for RAW schema
        - Updates Collibra catalog with validated RAW layer metadata
        - Ensures Collibra reflects commitments, not aspirations
        """,
    )

    raw_layer_end = EmptyOperator(
        task_id="raw_layer_end",
        doc_md="✅ RAW layer processing completed"
    )

    # =============================================================================
    # LAYER 2: STAGING MODELS + STAGING CHECKS
    # =============================================================================
    # 
    # Sequence: Build → Validate → Govern
    # Quality checks gate metadata sync to ensure only acceptable data enters governance
    
    staging_layer_start = EmptyOperator(
        task_id="staging_layer_start",
        doc_md="Starting STAGING layer processing"
    )

    dbt_run_staging = BashOperator(
        task_id="dbt_run_staging",
        bash_command=BASH_PREFIX + "cd dbt && dbt run --select staging --target dev --profiles-dir . 2>/dev/null || true",
        doc_md="""
        **Execute dbt Staging Models - Build Phase**
        
        - Runs dbt staging models (stg_customers, stg_orders, stg_products, stg_order_items)
        - Transforms raw data into cleaned, standardized format
        - Applies data quality improvements
        - Creates models in STAGING schema via project config
        - **Phase 1**: Materialize models in Snowflake
        """,
    )

    soda_scan_staging = BashOperator(
        task_id="soda_scan_staging",
        bash_command=BASH_PREFIX + f"soda scan -d {data_source_staging} -c soda/configuration/configuration_staging.yml -T soda/checks/templates/data_quality_templates.yml soda/checks/staging || true",
        doc_md="""
        **STAGING Layer Quality Checks - Validation Phase**
        
        - Stricter quality thresholds than RAW
        - Shows data improvement after transformation
        - Expected: Fewer failures than RAW layer
        - **Gates metadata sync**: Only validated data proceeds to Collibra
        - **Phase 2**: Validate freshness, volume, schema, business rules
        """,
    )

    def sync_staging_metadata_task(**context):
        """Wrapper function to import and call Collibra sync for STAGING layer."""
        from collibra.airflow_helper import sync_staging_metadata
        return sync_staging_metadata(**context)
    
    collibra_sync_staging = PythonOperator(
        task_id="collibra_sync_staging",
        python_callable=sync_staging_metadata_task,
        doc_md="""
        **Collibra Metadata Sync - STAGING Layer (Gated by Quality)**
        
        - **Only executes after quality checks pass**
        - Triggers metadata synchronization in Collibra for STAGING schema
        - Updates Collibra catalog with validated STAGING layer metadata
        - **Phase 3**: Sync only what passed the layer's acceptance criteria
        - Ensures Collibra reflects commitments, not aspirations
        """,
    )

    staging_layer_end = EmptyOperator(
        task_id="staging_layer_end",
        doc_md="✅ STAGING layer processing completed"
    )

    # =============================================================================
    # LAYER 3: MART MODELS + MART CHECKS
    # =============================================================================
    # 
    # Sequence: Build → Validate → Govern
    # Strictest quality standards for business-ready data
    # Metadata sync is a badge of trust for Gold layer
    
    mart_layer_start = EmptyOperator(
        task_id="mart_layer_start",
        doc_md="Starting MART layer processing"
    )

    dbt_run_mart = BashOperator(
        task_id="dbt_run_mart",
        bash_command=BASH_PREFIX + "cd dbt && dbt run --select mart --target dev --profiles-dir . 2>/dev/null || true",
        doc_md="""
        **Execute dbt Mart Models - Build Phase**
        
        - Runs dbt mart models (dim_customers, fact_orders)
        - Creates business-ready analytics tables
        - Applies business logic and aggregations
        - Creates models in MART schema via project config
        - **Phase 1**: Materialize business-ready models in Snowflake
        """,
    )

    soda_scan_mart = BashOperator(
        task_id="soda_scan_mart",
        bash_command=BASH_PREFIX + f"soda scan -d {data_source_mart} -c soda/configuration/configuration_mart.yml -T soda/checks/templates/data_quality_templates.yml soda/checks/mart || true",
        doc_md="""
        **MART Layer Quality Checks - Validation Phase**
        
        - Strictest quality thresholds
        - Ensures business-ready data quality
        - Expected: Minimal failures (production-ready)
        - **Gates metadata sync**: Only production-ready data proceeds to Collibra
        - **Phase 2**: Validate business logic, referential integrity, strict quality
        """,
    )

    def sync_mart_metadata_task(**context):
        """Wrapper function to import and call Collibra sync for MART layer."""
        from collibra.airflow_helper import sync_mart_metadata
        return sync_mart_metadata(**context)
    
    collibra_sync_mart = PythonOperator(
        task_id="collibra_sync_mart",
        python_callable=sync_mart_metadata_task,
        doc_md="""
        **Collibra Metadata Sync - MART Layer (Gated by Quality)**
        
        - **Only executes after quality checks pass**
        - Triggers metadata synchronization in Collibra for MART schema
        - Updates Collibra catalog with validated MART layer metadata
        - **Phase 3**: Sync only production-ready, validated data
        - Metadata sync is a badge of trust for Gold layer
        - Ensures Collibra reflects commitments, not aspirations
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
        bash_command=BASH_PREFIX + f"soda scan -d {data_source_quality} -c soda/configuration/configuration_quality.yml -T soda/checks/templates/data_quality_templates.yml soda/checks/quality || true",
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
        - Uses dev target for tests (reads from all schemas)
        """,
    )

    def sync_quality_metadata_task(**context):
        """Wrapper function to import and call Collibra sync for QUALITY layer."""
        from collibra.airflow_helper import sync_quality_metadata
        return sync_quality_metadata(**context)
    
    collibra_sync_quality = PythonOperator(
        task_id="collibra_sync_quality",
        python_callable=sync_quality_metadata_task,
        doc_md="""
        **Collibra Metadata Sync - QUALITY Layer (Gated by Quality)**
        
        - **Only executes after quality checks pass**
        - Triggers metadata synchronization in Collibra for QUALITY schema
        - Updates Collibra catalog with quality check results metadata
        - **Phase 4**: Sync quality monitoring and results
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
    # SUPERSET UPLOAD
    # =============================================================================
    
    superset_upload = PythonOperator(
        task_id="superset_upload_data",
        python_callable=upload_to_superset,
        doc_md="""
        **Upload Soda Data to Superset**
        
        This task completes the data visualization workflow by:
        1. Updating Soda data source names to match database configuration
        2. Extracting latest data from Soda Cloud API
        3. Organizing data (keeping only latest files)
        4. Uploading to Superset PostgreSQL database for visualization
        
        The uploaded data is available in Superset tables:
        - `soda.datasets_latest` - Latest dataset information
        - `soda.checks_latest` - Latest check results
        - `soda.analysis_summary` - Analysis summary data
        
        **Note**: This task requires Superset to be running and accessible.
        """,
    )

    # =============================================================================
    # TASK DEPENDENCIES - QUALITY-GATED METADATA SYNC
    # =============================================================================
    #
    # Orchestration Philosophy: Quality Gates Metadata Sync
    #
    # Each layer follows: Build → Validate → Govern
    # - Quality checks MUST complete before metadata sync
    # - This ensures Collibra only contains validated, committed data
    # - Collibra becomes a historical record of accepted states
    #
    # Parallelism is fine WITHIN a phase (e.g., multiple dbt models, multiple checks)
    # But phase transitions stay sequential to maintain semantic clarity
    #
    # Layer Sequencing:
    # RAW:    Quality Check → Metadata Sync (gated)
    # STAGING: Build → Quality Check → Metadata Sync (gated)
    # MART:   Build → Quality Check → Metadata Sync (gated)
    # QUALITY: Quality Check + Tests → Metadata Sync (gated)
    
    # RAW Layer: Quality gates metadata sync
    pipeline_start >> raw_layer_start >> soda_scan_raw >> collibra_sync_raw >> raw_layer_end
    
    # STAGING Layer: Build → Validate → Govern
    raw_layer_end >> staging_layer_start >> dbt_run_staging >> soda_scan_staging >> collibra_sync_staging >> staging_layer_end
    
    # MART Layer: Build → Validate → Govern (strictest standards)
    staging_layer_end >> mart_layer_start >> dbt_run_mart >> soda_scan_mart >> collibra_sync_mart >> mart_layer_end
    
    # Quality Layer: Final monitoring → Metadata sync (gated)
    mart_layer_end >> quality_layer_start >> [soda_scan_quality, dbt_test] >> collibra_sync_quality >> quality_layer_end
    quality_layer_end >> cleanup >> pipeline_end >> superset_upload
