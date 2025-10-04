# Scripts Directory - Soda Certification Project

This directory contains utility scripts for environment setup, data management, and Soda Cloud API integration.

## 📁 Directory Structure

```
scripts/
├── setup/                          # Environment setup scripts
│   ├── requirements.txt            # Python dependencies for setup
│   ├── setup_snowflake.py         # Snowflake database and table creation
│   └── reset_snowflake.py         # Snowflake database cleanup
├── soda_dump_api.py               # Soda Cloud API data extraction
├── run_soda_dump.sh               # Soda Cloud data dump runner
├── requirements_dump.txt          # API extraction dependencies
├── organize_soda_data.py          # Organize Soda data in user-friendly structure
├── upload_soda_data_docker.py     # Upload Soda data to Superset database
└── README.md                      # This file
```

## 🚀 Soda Cloud API Integration

### **Automated Metadata Extraction**

The Soda Cloud API integration provides automated extraction of dataset and check metadata for external reporting and dashboard creation.

## 📊 Data Organization & Upload

### **Data Organization Script**
- **`organize_soda_data.py`**: Organizes raw Soda dump data into a user-friendly structure
- **Features**: 
  - Creates organized directory structure (`latest/`, `historical/`, `reports/`, `analysis/`)
  - Updates `*_latest.csv` files with most recent data
  - Cleans up temporary files automatically
  - Generates summary reports

### **Data Upload Script**
- **`upload_soda_data_docker.py`**: Uploads organized Soda data to Superset PostgreSQL database
- **Features**:
  - Creates dedicated `soda` schema in PostgreSQL
  - Uploads latest data to dedicated tables (`soda.datasets_latest`, `soda.checks_latest`, `soda.analysis_summary`)
  - Handles historical data upload
  - Cleans up temporary files after successful upload

### **Usage**
```bash
# Complete workflow (recommended)
make superset-upload-data

# Individual steps
make soda-dump           # Extract from Soda Cloud
make organize-soda-data  # Organize data
make superset-upload-data # Upload to Superset
```

#### **Features:**
- ✅ **Dataset Metadata**: Extract table information, health status, and statistics
- ✅ **Check Results**: Retrieve check outcomes, pass/fail rates, and detailed results
- ✅ **CSV Export**: Structured data export for external tools
- ✅ **Sigma Dashboard**: Ready-to-use data for Sigma dashboard creation
- ✅ **API Rate Limiting**: Optimized for efficient data extraction

#### **Usage:**
```bash
# Extract Soda Cloud metadata
make soda-dump

# Manual execution
./scripts/run_soda_dump.sh
```

#### **Output Files:**
- `soda_dump_output/datasets_latest.csv` - Dataset metadata
- `soda_dump_output/checks_latest.csv` - Check results metadata

## 🛠️ Environment Setup Scripts

### **Snowflake Setup (`setup_snowflake.py`)**

Creates the complete Snowflake infrastructure with:
- **Database**: `SODA_CERTIFICATION`
- **Schemas**: `RAW`, `STAGING`, `MART`, `QUALITY`
- **Tables**: 4 RAW tables with uppercase column names
- **Sample Data**: 10,000+ customers, 1,000+ products, 20,000+ orders, 50,000+ order items

#### **Table Schema (Uppercase Standardization):**
```sql
-- CUSTOMERS table
CUSTOMER_ID VARCHAR(50) PRIMARY KEY,
FIRST_NAME VARCHAR(100),
LAST_NAME VARCHAR(100),
EMAIL VARCHAR(255),
PHONE VARCHAR(50),
-- ... other columns

-- PRODUCTS table  
PRODUCT_ID VARCHAR(50) PRIMARY KEY,
PRODUCT_NAME VARCHAR(255),
CATEGORY VARCHAR(100),
-- ... other columns

-- ORDERS table
ORDER_ID VARCHAR(50) PRIMARY KEY,
CUSTOMER_ID VARCHAR(50),
ORDER_DATE DATE,
-- ... other columns

-- ORDER_ITEMS table
ORDER_ITEM_ID VARCHAR(50) PRIMARY KEY,
ORDER_ID VARCHAR(50),
PRODUCT_ID VARCHAR(50),
-- ... other columns
```

### **Snowflake Reset (`reset_snowflake.py`)**

Cleans up the Snowflake environment:
- Drops all tables and schemas
- Removes sample data
- Resets to clean state

## 🔧 Configuration

### **Environment Variables**

Required environment variables in `.env`:
```bash
# Snowflake Configuration
SNOWFLAKE_ACCOUNT=your_account
SNOWFLAKE_USER=your_user
SNOWFLAKE_PASSWORD=your_password
SNOWFLAKE_WAREHOUSE=your_warehouse
SNOWFLAKE_DATABASE=SODA_CERTIFICATION
SNOWFLAKE_SCHEMA=RAW

# Soda Cloud Configuration
SODA_CLOUD_HOST=https://cloud.soda.io
SODA_CLOUD_API_KEY=your_api_key
SODA_CLOUD_API_SECRET=your_api_secret
```

### **Dependencies**

#### **Setup Dependencies (`setup/requirements.txt`):**
```
snowflake-connector-python
faker
python-dotenv
pandas
numpy
```

#### **API Dependencies (`requirements_dump.txt`):**
```
pandas
requests
snowflake-connector-python
```

## 🚀 Usage Examples

### **Complete Environment Setup**
```bash
# 1. Start Airflow services
make airflow-up

# 2. Initialize Snowflake (creates tables with uppercase columns)
make airflow-trigger-init

# 3. Run data quality pipeline
make airflow-trigger-pipeline

# 4. Extract Soda Cloud metadata
make soda-dump
```

### **Manual Script Execution**
```bash
# Setup Snowflake manually
python3 scripts/setup/setup_snowflake.py

# Reset Snowflake manually  
python3 scripts/setup/reset_snowflake.py

# Extract Soda Cloud data manually
python3 scripts/soda_dump_api.py
```

## 📊 Data Quality Features

### **Sample Data Generation**
- **Realistic Data**: Faker-generated realistic customer and product data
- **Quality Issues**: Intentionally introduced data quality problems for testing
- **Volume**: Production-scale data volumes (10K+ customers, 50K+ order items)
- **Relationships**: Proper foreign key relationships between tables

### **Data Quality Issues Introduced**
- **Missing Values**: 10% of records have missing email/phone
- **Invalid Formats**: Invalid email formats and negative prices
- **Duplicate Data**: Intentional duplicates for uniqueness testing
- **Future Dates**: Invalid future timestamps for freshness testing

## 🔍 Troubleshooting

### **Common Issues**

1. **Snowflake Connection**
   - Verify credentials in `.env`
   - Check warehouse is running
   - Ensure proper permissions

2. **Soda Cloud API**
   - Verify API keys are correct
   - Check network connectivity
   - Monitor rate limits

3. **Data Generation**
   - Ensure sufficient warehouse compute
   - Check for memory issues with large datasets
   - Verify table creation permissions

### **Log Locations**
- Setup logs: Available in Airflow UI
- API logs: Console output and CSV files
- Error logs: Check Airflow task logs

## 📚 Best Practices

1. **Environment Setup**: Always use the initialization DAG for consistent setup
2. **Data Reset**: Use reset script for clean environment testing
3. **API Usage**: Monitor rate limits and implement appropriate delays
4. **Error Handling**: Check logs for detailed error information
5. **Testing**: Validate setup before running full pipeline

## 🔄 Dynamic File Finding & Smart Filtering

The `soda_dump_api.py` script fetches ALL data from Soda Cloud, and the `soda_dump_analysis.ipynb` notebook provides intelligent filtering:

### **API Script Features:**
- **Complete Data Fetch**: Retrieves ALL datasets and checks from Soda Cloud
- **Multiple File Formats**: Creates timestamped, daily, and `_latest.csv` files
- **Smart Timestamp Sorting**: Uses filename timestamps for accurate latest file detection
- **Enhanced Logging**: Better error messages and progress tracking

### **Notebook Filtering Features:**
- **Dynamic File Discovery**: Automatically finds latest files without hardcoding
- **Smart Data Source Filtering**: Filters for `soda_certification_*` data sources
- **Flexible Analysis**: Can analyze different subsets by changing filter criteria
- **Enhanced Error Handling**: Clear messages when files are missing

### **Usage Example:**
```python
import sys
sys.path.append('scripts')
from soda_dump_api import SodaCloudDump
import pandas as pd

# Find latest files dynamically
datasets_file = SodaCloudDump.get_latest_datasets_file()
checks_file = SodaCloudDump.get_latest_checks_file()

# Load all data
datasets_df = pd.read_csv(datasets_file)
checks_df = pd.read_csv(checks_file)

# Filter for your project (example)
soda_certification_sources = [
    'soda_certification_raw',
    'soda_certification_staging', 
    'soda_certification_mart',
    'soda_certification_quality'
]
filtered_datasets = datasets_df[datasets_df['datasource_name'].isin(soda_certification_sources)]
```

### **Benefits:**
- ✅ **Complete Data Access**: All Soda Cloud data available for analysis
- ✅ **Smart Filtering**: Notebook automatically filters for your project
- ✅ **Flexible Analysis**: Can analyze different data sources by changing filters
- ✅ **No Hardcoded Timestamps**: Always finds the most recent data
- ✅ **Production Ready**: Perfect for notebooks and automated scripts
- ✅ **Error Handling**: Gracefully handles missing files

### **Available Methods:**
- `SodaCloudDump.get_latest_datasets_file()` - Find latest datasets CSV
- `SodaCloudDump.get_latest_checks_file()` - Find latest checks CSV
- `SodaCloudDump.find_latest_file(pattern)` - Find latest file by pattern

## 🎯 Success Metrics

✅ **Complete Environment**: Snowflake database with all tables and data  
✅ **Uppercase Standardization**: Consistent naming across all layers  
✅ **API Integration**: Successful metadata extraction from Soda Cloud  
✅ **Complete Data Access**: All Soda Cloud data available for analysis  
✅ **Smart Filtering**: Intelligent filtering for project-specific data  
✅ **Dynamic File Finding**: No hardcoded timestamps, always finds latest data  
✅ **Data Quality**: Comprehensive test data with quality issues  
✅ **Automation**: One-command setup and execution  

---

**Last Updated**: October 2025  
**Version**: 1.3.0
