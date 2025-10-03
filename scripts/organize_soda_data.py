#!/usr/bin/env python3
"""
Script to organize Soda dump data in a user-friendly way
This script reorganizes the soda_dump_output directory structure
"""

import os
import shutil
from pathlib import Path
from datetime import datetime

def organize_soda_data():
    """Organize Soda dump data into a friendly structure"""
    
    # Define paths
    soda_dump_dir = Path("superset/data")
    organized_dir = Path("superset/data/organized")
    
    if not soda_dump_dir.exists():
        print("❌ superset/data directory not found!")
        print("Please run 'make soda-dump' first to generate the data.")
        return False
    
    # Always refresh latest data by copying most recent files
    print("🔄 Updating to latest data...")
    update_latest_data(soda_dump_dir)
    
    # Create organized directory structure
    organized_dir.mkdir(exist_ok=True)
    
    # Create subdirectories
    (organized_dir / "latest").mkdir(exist_ok=True)
    (organized_dir / "historical").mkdir(exist_ok=True)
    (organized_dir / "reports").mkdir(exist_ok=True)
    (organized_dir / "analysis").mkdir(exist_ok=True)
    
    print("📁 Organizing Soda dump data...")
    
    # Copy latest files
    latest_files = [
        "datasets_latest.csv",
        "checks_latest.csv"
    ]
    
    for file in latest_files:
        src = soda_dump_dir / file
        if src.exists():
            dst = organized_dir / "latest" / file
            shutil.copy2(src, dst)
            print(f"✅ Copied {file} to latest/")
    
    # Copy historical files
    historical_files = [f for f in soda_dump_dir.glob("*_2025-*.csv") if "latest" not in f.name]
    for file in historical_files:
        dst = organized_dir / "historical" / file.name
        shutil.copy2(file, dst)
        print(f"✅ Copied {file.name} to historical/")
    
    # Copy reports
    report_files = [f for f in soda_dump_dir.glob("*.txt")]
    for file in report_files:
        dst = organized_dir / "reports" / file.name
        shutil.copy2(file, dst)
        print(f"✅ Copied {file.name} to reports/")
    
    # Copy analysis files
    analysis_files = [f for f in soda_dump_dir.glob("analysis_*.csv")]
    for file in analysis_files:
        dst = organized_dir / "analysis" / file.name
        shutil.copy2(file, dst)
        print(f"✅ Copied {file.name} to analysis/")
    
    # Create summary files
    create_summary_files(organized_dir)
    
    # Clean up original files to reduce noise
    print("\n🧹 Cleaning up original files...")
    cleanup_original_files(soda_dump_dir)
    
    # Clean up temporary soda_dump_output folder
    print("\n🧹 Cleaning up temporary soda_dump_output folder...")
    cleanup_temp_folder()
    
    print(f"\n🎉 Data organized successfully!")
    print(f"📁 Organized data location: {organized_dir}")
    print(f"\n📊 Directory structure:")
    print(f"  latest/     - Most recent datasets and checks")
    print(f"  historical/ - Timestamped historical data")
    print(f"  reports/    - Summary reports and analysis")
    print(f"  analysis/   - Analysis and summary files")
    
    return True

def update_latest_data(soda_dump_dir):
    """Update latest CSV files with the most recent data"""
    
    # Find the most recent datasets and checks files
    datasets_files = list(soda_dump_dir.glob("datasets_*.csv"))
    checks_files = list(soda_dump_dir.glob("checks_*.csv"))
    
    if not datasets_files:
        print("⚠️  No datasets files found")
        return
    
    if not checks_files:
        print("⚠️  No checks files found")
        return
    
    # Get the most recent files (by modification time)
    latest_datasets = max(datasets_files, key=lambda x: x.stat().st_mtime)
    latest_checks = max(checks_files, key=lambda x: x.stat().st_mtime)
    
    # Copy to latest files (overwrite existing) only if different
    latest_datasets_path = soda_dump_dir / "datasets_latest.csv"
    latest_checks_path = soda_dump_dir / "checks_latest.csv"
    
    if latest_datasets != latest_datasets_path:
        shutil.copy2(latest_datasets, latest_datasets_path)
        print(f"✅ Updated datasets_latest.csv from {latest_datasets.name}")
    else:
        print(f"✅ datasets_latest.csv is already the latest")
    
    if latest_checks != latest_checks_path:
        shutil.copy2(latest_checks, latest_checks_path)
        print(f"✅ Updated checks_latest.csv from {latest_checks.name}")
    else:
        print(f"✅ checks_latest.csv is already the latest")
    
    # Also update analysis_summary if it exists
    analysis_files = list(soda_dump_dir.glob("analysis_summary*.csv"))
    if analysis_files:
        latest_analysis = max(analysis_files, key=lambda x: x.stat().st_mtime)
        analysis_summary_path = soda_dump_dir / "analysis_summary.csv"
        if latest_analysis != analysis_summary_path:
            shutil.copy2(latest_analysis, analysis_summary_path)
            print(f"✅ Updated analysis_summary.csv from {latest_analysis.name}")
        else:
            print(f"✅ analysis_summary.csv is already the latest")

def cleanup_original_files(soda_dump_dir):
    """Remove original files after organizing to reduce noise"""
    
    # Files to keep (latest versions and essential files)
    files_to_keep = [
        "datasets_latest.csv",
        "checks_latest.csv", 
        "analysis_summary.csv",
        "README.md",
        "connection_guide.md"
    ]
    
    # Get all files in the directory
    all_files = list(soda_dump_dir.glob("*"))
    
    removed_count = 0
    for file_path in all_files:
        if file_path.is_file() and file_path.name not in files_to_keep:
            try:
                file_path.unlink()  # Remove the file
                print(f"🗑️  Removed {file_path.name}")
                removed_count += 1
            except Exception as e:
                print(f"⚠️  Could not remove {file_path.name}: {e}")
    
    if removed_count > 0:
        print(f"✅ Cleaned up {removed_count} original files")
    else:
        print("✅ No files to clean up")

def create_summary_files(organized_dir):
    """Create summary and overview files"""
    
    # Create README for the organized data
    readme_content = """# Soda Data Quality Data

This directory contains organized Soda Cloud data quality information.

## Directory Structure

- **latest/** - Most recent datasets and checks data
  - `datasets_latest.csv` - Latest dataset information
  - `checks_latest.csv` - Latest check results

- **historical/** - Timestamped historical data
  - Files with timestamps for trend analysis
  - Daily snapshots of data quality metrics

- **reports/** - Summary reports and analysis
  - Summary reports with statistics
  - Analysis files and insights

- **analysis/** - Analysis and summary files
  - Analysis summary data
  - Aggregated metrics

## Data Usage

### For Superset Visualization
1. Use files from `latest/` directory for current dashboards
2. Use files from `historical/` for trend analysis
3. Upload to Superset: `make superset-upload-data`

### For Analysis
- Check `reports/` for summary statistics
- Use `analysis/` files for detailed analysis
- Historical data in `historical/` for trend analysis

## File Descriptions

### Datasets Files
- Contains dataset metadata, health status, and quality metrics
- Columns: id, name, label, qualifiedName, lastUpdated, datasource, dataQualityStatus, healthStatus, checks, incidents, cloudUrl, owners, tags, attributes

### Checks Files  
- Contains check definitions, results, and evaluation status
- Columns: id, name, evaluationStatus, definition, datasets, attributes, incidents, cloudUrl, createdAt, group, lastCheckResultValue, lastCheckRunTime, lastUpdated, owner, agreements, column

## Next Steps
1. Upload to Superset: `make superset-upload-data`
2. Create visualizations in Superset UI
3. Build dashboards for data quality monitoring
"""
    
    with open(organized_dir / "README.md", "w") as f:
        f.write(readme_content)
    
    # Create data summary
    create_data_summary(organized_dir)

def create_data_summary(organized_dir):
    """Create a data summary file"""
    
    summary_content = f"""# Soda Data Quality Summary
Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

## Data Overview

### Latest Data
"""
    
    # Count files in each directory
    for subdir in ["latest", "historical", "reports", "analysis"]:
        subdir_path = organized_dir / subdir
        if subdir_path.exists():
            files = list(subdir_path.glob("*"))
            summary_content += f"\n**{subdir.title()}**: {len(files)} files\n"
            
            for file in files:
                if file.is_file():
                    size = file.stat().st_size
                    summary_content += f"  - {file.name} ({size:,} bytes)\n"
    
    summary_content += f"""
## Usage Instructions

1. **For Superset**: Use files from `latest/` directory
2. **For Analysis**: Check `reports/` and `analysis/` directories  
3. **For Trends**: Use `historical/` files for time-series analysis

## Data Quality Metrics

- **Datasets**: Latest dataset health and quality status
- **Checks**: Check results and evaluation status
- **Historical**: Trend data for analysis
- **Reports**: Summary statistics and insights
"""
    
    with open(organized_dir / "DATA_SUMMARY.md", "w") as f:
        f.write(summary_content)

def cleanup_temp_folder():
    """Clean up temporary soda_dump_output folder after organizing data"""
    import shutil
    
    # Path to the temporary folder (relative to project root)
    temp_folder = Path("soda_dump_output")
    
    if temp_folder.exists():
        try:
            shutil.rmtree(temp_folder)
            print(f"✅ Removed temporary folder: {temp_folder}")
        except Exception as e:
            print(f"⚠️  Could not remove temporary folder {temp_folder}: {e}")
    else:
        print(f"ℹ️  Temporary folder {temp_folder} not found (already cleaned up)")

if __name__ == "__main__":
    organize_soda_data()
