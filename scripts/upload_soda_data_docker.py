#!/usr/bin/env python3
"""
Script to upload Soda dump CSV data to Superset database
This version runs inside the Superset container with direct database access
"""

import pandas as pd
import psycopg2
import os
import sys
import shutil
from pathlib import Path

# Database connection settings (running inside container)
DB_CONFIG = {
    'host': 'superset-db',
    'port': 5432,
    'database': 'superset',
    'user': 'superset',
    'password': 'superset'
}

def connect_to_db():
    """Connect to Superset PostgreSQL database"""
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        print(f"✅ Connected to Superset database")
        return conn
    except psycopg2.Error as e:
        print(f"❌ Error connecting to database: {e}")
        sys.exit(1)

def upload_csv_to_table(csv_file, table_name, conn, is_latest=False):
    """Upload CSV data to PostgreSQL table"""
    try:
        # Read CSV file
        df = pd.read_csv(csv_file)
        print(f"📊 Reading {csv_file.name}: {len(df)} rows")
        
        # Create table if it doesn't exist
        cursor = conn.cursor()
        
        # Generate CREATE TABLE statement
        columns = []
        for col, dtype in df.dtypes.items():
            if dtype == 'object':
                col_type = 'TEXT'
            elif dtype == 'int64':
                col_type = 'INTEGER'
            elif dtype == 'float64':
                col_type = 'FLOAT'
            elif dtype == 'bool':
                col_type = 'BOOLEAN'
            else:
                col_type = 'TEXT'
            
            columns.append(f'"{col}" {col_type}')
        
        # Add metadata columns for tracking
        if is_latest:
            columns.append('upload_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP')
            columns.append('data_source TEXT DEFAULT \'soda_latest\'')
        
        create_table_sql = f"""
        CREATE TABLE IF NOT EXISTS {table_name} (
            {', '.join(columns)}
        );
        """
        
        cursor.execute(create_table_sql)
        conn.commit()
        
        # For latest tables, clear existing data and insert fresh
        if is_latest:
            cursor.execute(f"DELETE FROM {table_name}")
            conn.commit()
            print(f"🔄 Cleared existing data from {table_name}")
        
        # Insert data
        for _, row in df.iterrows():
            placeholders = ', '.join(['%s'] * len(row))
            columns_str = ', '.join([f'"{col}"' for col in df.columns])
            insert_sql = f"INSERT INTO {table_name} ({columns_str}) VALUES ({placeholders})"
            cursor.execute(insert_sql, tuple(row))
        
        conn.commit()
        cursor.close()
        
        print(f"✅ Uploaded {len(df)} rows to table '{table_name}'")
        
    except Exception as e:
        print(f"❌ Error uploading {csv_file}: {e}")
        conn.rollback()

def refresh_latest_data(soda_data_dir):
    """Refresh latest CSV files with most recent data"""
    print("🔄 Refreshing latest data files...")
    
    # Find the most recent datasets and checks files
    datasets_files = list(soda_data_dir.glob("datasets_*.csv"))
    checks_files = list(soda_data_dir.glob("checks_*.csv"))
    
    if datasets_files:
        latest_datasets = max(datasets_files, key=lambda x: x.stat().st_mtime)
        latest_datasets_path = soda_data_dir / "datasets_latest.csv"
        if latest_datasets != latest_datasets_path:
            shutil.copy2(latest_datasets, latest_datasets_path)
            print(f"✅ Updated datasets_latest.csv from {latest_datasets.name}")
        else:
            print(f"✅ datasets_latest.csv is already the latest")
    
    if checks_files:
        latest_checks = max(checks_files, key=lambda x: x.stat().st_mtime)
        latest_checks_path = soda_data_dir / "checks_latest.csv"
        if latest_checks != latest_checks_path:
            shutil.copy2(latest_checks, latest_checks_path)
            print(f"✅ Updated checks_latest.csv from {latest_checks.name}")
        else:
            print(f"✅ checks_latest.csv is already the latest")
    
    # Also update analysis_summary if it exists
    analysis_files = list(soda_data_dir.glob("analysis_summary*.csv"))
    if analysis_files:
        latest_analysis = max(analysis_files, key=lambda x: x.stat().st_mtime)
        analysis_summary_path = soda_data_dir / "analysis_summary.csv"
        if latest_analysis != analysis_summary_path:
            shutil.copy2(latest_analysis, analysis_summary_path)
            print(f"✅ Updated analysis_summary.csv from {latest_analysis.name}")
        else:
            print(f"✅ analysis_summary.csv is already the latest")

def cleanup_temp_folder():
    """Clean up temporary soda_dump_output folder after successful upload"""
    import shutil
    
    # Path to the temporary folder (relative to project root)
    temp_folder = Path("../soda_dump_output")
    
    if temp_folder.exists():
        try:
            shutil.rmtree(temp_folder)
            print(f"✅ Removed temporary folder: {temp_folder}")
        except Exception as e:
            print(f"⚠️  Could not remove temporary folder {temp_folder}: {e}")
    else:
        print(f"ℹ️  Temporary folder {temp_folder} not found (already cleaned up)")

def main():
    """Main function to upload all Soda dump data"""
    # Check if superset/data directory exists
    soda_data_dir = Path("/app/soda_data")
    if not soda_data_dir.exists():
        print("❌ superset/data directory not found!")
        print("Please ensure the directory is mounted in the container")
        sys.exit(1)
    
    # Refresh latest data files
    refresh_latest_data(soda_data_dir)
    
    # Connect to database
    print("\n🔌 Connecting to Superset database...")
    conn = connect_to_db()
    
    # Create soda schema if it doesn't exist
    cursor = conn.cursor()
    cursor.execute("CREATE SCHEMA IF NOT EXISTS soda;")
    conn.commit()
    cursor.close()
    print("✅ Created/verified 'soda' schema")
    
    # Upload latest files to dedicated tables
    latest_files = {
        "datasets_latest.csv": "soda.checks_latest",
        "checks_latest.csv": "soda.dataset_latest"
    }
    
    print("\n📤 Uploading latest data to dedicated tables...")
    for csv_file, table_name in latest_files.items():
        file_path = soda_data_dir / csv_file
        if file_path.exists():
            print(f"\n📤 Uploading {csv_file} to table '{table_name}'...")
            upload_csv_to_table(file_path, table_name, conn, is_latest=True)
        else:
            print(f"⚠️  {csv_file} not found, skipping...")
    
    # Upload historical data to general tables
    print("\n📤 Uploading historical data...")
    historical_files = [f for f in soda_data_dir.glob("*.csv") if "latest" not in f.name]
    
    for csv_file in historical_files:
        table_name = f"soda.{csv_file.stem}"
        print(f"\n📤 Uploading {csv_file.name} to table '{table_name}'...")
        upload_csv_to_table(csv_file, table_name, conn, is_latest=False)
    
    conn.close()
    
    # Clean up temporary soda_dump_output folder
    print("\n🧹 Cleaning up temporary files...")
    cleanup_temp_folder()
    
    print("\n🎉 All Soda dump data uploaded successfully!")
    print("\n📊 Database Tables Created:")
    print("  - soda.checks_latest    - Latest check results")
    print("  - soda.dataset_latest    - Latest dataset information")
    print("  - soda.*_historical      - Historical data files")
    print("\nNext steps:")
    print("1. Access Superset UI: http://localhost:8089")
    print("2. Go to Data > Databases and add your PostgreSQL connection")
    print("3. Create datasets from the uploaded tables")
    print("4. Build dashboards with your data quality insights")

if __name__ == "__main__":
    main()
