# Soda Data Quality Data

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
