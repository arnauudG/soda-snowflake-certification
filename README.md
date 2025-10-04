# Soda Data Quality Certification Project

A comprehensive data quality pipeline demonstrating Soda Library integration with Airflow, dbt, and Snowflake for end-to-end data quality management.

## 🎯 Project Overview

This project showcases a complete data quality pipeline with:
- **Soda Library** for data quality checks and profiling
- **Apache Airflow** for workflow orchestration
- **dbt** for data transformations
- **Snowflake** as the data warehouse
- **Apache Superset** for data visualization and dashboards
- **Docker** for containerized deployment
- **Soda Cloud API** for metadata extraction and reporting

## 🏗️ Architecture

### Data Pipeline Layers
```
RAW Layer (Snowflake) → STAGING Layer (dbt) → MARTS Layer (dbt)
     ↓                        ↓                      ↓
Soda Quality Checks    Soda Quality Checks    Soda Quality Checks
```

### Technology Stack
- **Orchestration**: Apache Airflow 2.8+
- **Data Warehouse**: Snowflake
- **Transformations**: dbt Core 1.10.11
- **Data Quality**: Soda Library 1.0.5
- **Visualization**: Apache Superset
- **Containerization**: Docker & Docker Compose
- **Language**: Python 3.11

## 📁 Project Structure

```
├── airflow/                          # Airflow Docker configuration
│   ├── docker/                      # Docker configuration
│   │   ├── docker-compose.yml       # Multi-container setup
│   │   ├── Dockerfile               # Custom Airflow image
│   │   └── requirements.txt         # Python dependencies
│   ├── dags/                        # Airflow DAGs
│   │   ├── soda_initialization.py   # Data initialization DAG
│   │   └── soda_pipeline_run.py     # Main pipeline DAG
│   └── plugins/                     # Airflow plugins
├── dbt/                              # dbt project configuration
│   ├── models/
│   │   ├── raw/                      # Raw data sources
│   │   ├── staging/                  # Staging transformations
│   │   └── mart/                     # Business-ready models
│   ├── dbt_project.yml              # dbt project configuration
│   └── profiles.yml                 # dbt profiles for Snowflake
├── scripts/                          # Utility scripts
│   ├── organize_soda_data.py        # Organize Soda data in friendly structure
│   ├── upload_soda_data_docker.py   # Upload Soda data to Superset database
│   ├── soda_dump_api.py             # Soda Cloud API data extraction
│   ├── run_soda_dump.sh             # Soda Cloud data dump runner
│   ├── requirements_dump.txt         # API extraction dependencies
├── load_env.sh                       # Environment variables loader
│   └── setup/                       # Environment setup
│       ├── requirements.txt         # Python dependencies
│       ├── setup_snowflake.py       # Snowflake table creation
│       └── reset_snowflake.py       # Snowflake cleanup
├── soda/                             # Soda data quality configuration
│   ├── checks/                      # SodaCL check definitions
│   │   ├── raw/                     # RAW layer quality checks
│   │   ├── staging/                 # STAGING layer quality checks
│   │   ├── mart/                    # MART layer quality checks
│   │   ├── quality/                 # Quality check results
│   │   └── templates/               # Reusable check templates
│   ├── configuration/               # Soda connection configurations
│   ├── soda-agent/                  # Soda Agent AWS Infrastructure
│   │   ├── module/                  # Terraform modules
│   │   │   ├── helm-soda-agent/     # Soda Agent Helm deployment
│   │   │   └── ops-ec2-eks-access/ # EKS access configuration
│   │   ├── env/                     # Environment-specific configurations
│   │   │   ├── dev/eu-west-1/      # Development environment
│   │   │   └── prod/eu-west-1/     # Production environment
│   │   ├── bootstrap.sh             # One-time infrastructure bootstrap
│   │   ├── deploy.sh               # Infrastructure deployment
│   │   ├── destroy.sh              # Infrastructure destruction
│   │   └── README.md               # Infrastructure documentation
│   └── README.md                    # Soda configuration documentation
├── superset/                         # Superset visualization setup
│   ├── docker-compose.yml           # Superset services with dedicated database
│   ├── superset_config.py           # Superset configuration
│   ├── data/                        # Soda Cloud data and organized structure
│   │   ├── datasets_latest.csv      # Latest dataset metadata
│   │   ├── checks_latest.csv        # Latest check results metadata
│   │   ├── analysis_summary.csv     # Analysis summary
│   │   ├── organized/               # Organized data (user-friendly structure)
│   │   │   ├── latest/              # Most recent datasets and checks
│   │   │   ├── historical/          # Timestamped historical data
│   │   │   ├── reports/             # Summary reports and analysis
│   │   │   └── analysis/            # Analysis and summary files
│   │   └── upload_soda_data_docker.py # Upload script (copied during execution)
│   └── README.md                    # Superset documentation
├── Makefile                         # Project automation and commands
└── README.md                        # This file
```

## 🚀 Quick Start

### Prerequisites
- **Docker & Docker Compose** (latest version)
- **Snowflake account** with appropriate permissions
- **Soda Cloud account** (required for data extraction and visualization)
- **Python 3.11+** (for local script execution)

### 🏗️ Soda Agent Infrastructure

The project includes infrastructure as code for deploying Soda Agent on AWS using Terraform and Terragrunt:

### Infrastructure Components
- **VPC with private/public subnets** across 3 AZs
- **VPC Endpoints** for SSM, ECR, STS, CloudWatch Logs, and S3
- **EKS Cluster** with managed node groups
- **Ops Infrastructure** (EC2 instance, security groups, IAM roles)
- **Soda Agent** deployed via Helm on EKS

### Available Environments
- **Development** (`dev/eu-west-1/`) - For testing and development
- **Production** (`prod/eu-west-1/`) - For production workloads

### Infrastructure Commands
```bash
# Bootstrap infrastructure (one-time setup)
make soda-agent-bootstrap ENV=dev

# Deploy infrastructure
make soda-agent-deploy ENV=dev

# Destroy infrastructure
make soda-agent-destroy ENV=dev
```

## 🎯 What This Project Does
This project demonstrates a complete data quality pipeline with:
1. **Data Pipeline**: Raw → Staging → Marts (using dbt)
2. **Quality Monitoring**: Soda Library checks at each layer
3. **Orchestration**: Apache Airflow for workflow management
4. **Visualization**: Apache Superset for dashboards
5. **Cloud Integration**: Soda Cloud for centralized monitoring
6. **Data Extraction**: Automated Soda Cloud metadata extraction

### 1. Environment Setup
```bash
# Clone the repository
git clone <repository-url>
cd Soda-Certification

# Create .env file with your credentials
cp .env.example .env
# Edit .env with your actual credentials
```

**Required Environment Variables:**
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
SODA_CLOUD_API_KEY_ID=your_api_key_id
SODA_CLOUD_API_KEY_SECRET=your_api_key_secret
SODA_CLOUD_ORGANIZATION_ID=your_org_id
```

### **🔧 Environment Variables Loader**

The project includes an automated environment variable loader that:

- **Validates all required variables** before starting services
- **Masks sensitive information** for security
- **Provides clear feedback** on missing or invalid variables
- **Automatically loads** when starting Airflow or Superset

#### **Automatic Loading (Recommended)**
Environment variables are automatically loaded when you run:
```bash
make airflow-up      # Loads env vars before starting Airflow
make superset-up     # Loads env vars before starting Superset  
make all-up          # Loads env vars before starting all services
```

#### **Manual Loading**
You can also manually load environment variables:
```bash
# Load environment variables from .env file
source load_env.sh

# Or make it executable and run directly
chmod +x load_env.sh
./load_env.sh
```

**Features:**
- ✅ **Automatic validation** - Checks for required variables
- ✅ **Security** - Hides sensitive values in output
- ✅ **User-friendly** - Color-coded status messages
- ✅ **Error handling** - Clear guidance for missing variables

### 2. Start Services
```bash
# Start all services (Airflow + Superset)
make all-up

# Or start services separately
make airflow-up      # Start Airflow only
make superset-up     # Start Superset only

# Verify services are running
make airflow-status
make superset-status
```

### 3. Initialize Data
```bash
# Run initialization DAG to create tables and load data
make airflow-trigger-init
```

### 4. Run Data Quality Pipeline
```bash
# Execute the main pipeline
make airflow-trigger-pipeline
```

### 5. Extract and Visualize Soda Cloud Data
```bash
# Complete workflow: extract + organize + upload to Superset
make superset-upload-data

# Or run individual steps:
make soda-dump                 # Extract from Soda Cloud
make organize-soda-data        # Organize data structure
make superset-upload-data      # Upload to Superset (includes dump + organize)
```

### 6. Visualize Data Quality Results
```bash
# Access Superset UI at http://localhost:8089 (admin/admin)
# The data is automatically uploaded to PostgreSQL tables:
# - soda.datasets_latest (latest dataset information)
# - soda.checks_latest (latest check results)
# - soda.analysis_summary (analysis summary)

# Create dashboards and visualizations from the uploaded data
# Your dashboards and charts are automatically preserved!
```

### 7. Complete Workflow Example
```bash
# Complete end-to-end workflow
make all-up                    # Start all services
make airflow-trigger-init      # Initialize data
make airflow-trigger-pipeline  # Run quality checks
make superset-upload-data      # Extract + organize + upload to Superset
# Access Superset at http://localhost:8089
```

## 👋 First Time User Guide

### **Step-by-Step Setup for New Users**

#### **1. Prerequisites Check**
```bash
# Verify Docker is running
docker --version
docker-compose --version

# Verify Python is available
python3 --version
```

#### **2. Environment Configuration**
```bash
# Create your .env file
cp .env.example .env

# Edit .env with your actual credentials
nano .env  # or use your preferred editor
```

#### **3. First Run - Complete Setup**
```bash
# Start all services
make all-up

# Wait for services to be ready (about 2-3 minutes)
# Check status
make airflow-status
make superset-status

# Initialize the data pipeline
make airflow-trigger-init

# Run the complete data quality pipeline
make airflow-trigger-pipeline

# Extract and visualize Soda Cloud data (complete workflow)
make superset-upload-data
```

#### **4. Access Your Dashboards**
- **Airflow UI**: http://localhost:8080 (admin/admin)
- **Superset UI**: http://localhost:8089 (admin/admin)

#### **5. Verify Everything Works**
```bash
# Check all services are running
make airflow-status
make superset-status

# Check data was created
# - Airflow: Look for successful DAG runs
# - Superset: Check for uploaded Soda data tables
```

### **What You'll See**
1. **Airflow**: Two DAGs running successfully
2. **Snowflake**: Database with sample data and quality checks
3. **Soda Cloud**: Quality results uploaded to your organization
4. **Superset**: Data quality dashboards ready to create

### **Data Persistence**
Your work is automatically preserved:
- **Superset Dashboards**: Automatically saved using Docker volumes
- **Database Data**: PostgreSQL data persisted across restarts
- **Configuration**: All settings and connections preserved
- **No Data Loss**: Restart services without losing your work!

## 🔄 Soda Cloud Data Workflow

### Overview
The project includes a complete data extraction and visualization workflow that fetches data from your Soda Cloud platform and makes it available in Superset for analysis and dashboards.

### Data Flow
```
Soda Cloud Platform → CSV Files → Organized Data → Superset Database → Dashboards
```

### Step-by-Step Workflow

#### 1. **Extract from Soda Cloud** (`make soda-dump`)
- Connects to Soda Cloud API using your credentials
- Fetches **ALL** datasets and checks from your account
- Saves data as CSV files in `soda_dump_output/`
- Includes historical data and latest snapshots

#### 2. **Organize Data** (`make organize-soda-data`)
- Takes raw CSV files and organizes them into user-friendly structure
- Always updates `*_latest.csv` files with the most recent data
- Maintains historical data in separate folders
- Creates organized structure in `superset/data/organized/`
- **Automatically cleans up** temporary `soda_dump_output` folder

#### 3. **Upload to Superset** (`make superset-upload-data`)
- Uploads organized data to PostgreSQL database
- Creates dedicated tables: `soda.datasets_latest`, `soda.checks_latest`, and `soda.analysis_summary`
- Stores historical data in separate tables
- Refreshes latest tables with new data each time
- **Automatically cleans up** temporary `soda_dump_output` folder

#### 4. **Complete Workflow** (`make superset-upload-data`)
- Combines organize + upload in one command
- Perfect for regular data updates

### Required Configuration

Add these variables to your `.env` file:

```bash
# Soda Cloud API Credentials
SODA_CLOUD_API_KEY_ID=your_api_key_id
SODA_CLOUD_API_KEY_SECRET=your_api_key_secret
SODA_CLOUD_HOST=https://cloud.us.soda.io  # or https://cloud.soda.io for EU
```

### Available Commands

```bash
# Complete workflow (recommended)
make superset-upload-data

# Individual steps
make soda-dump           # Extract from Soda Cloud
make organize-soda-data  # Organize data
make superset-upload-data # Upload to Superset

# Clean restart options
make superset-clean-restart  # Complete clean restart
make superset-reset-data     # Reset only data

# Soda Agent Infrastructure
make soda-agent-bootstrap ENV=dev  # Bootstrap infrastructure (one-time)
make soda-agent-deploy ENV=dev     # Deploy infrastructure
make soda-agent-destroy ENV=dev    # Destroy infrastructure
```

### Data Organization Structure

```
superset/data/
├── datasets_latest.csv      # Latest dataset information
├── checks_latest.csv        # Latest check results
├── datasets_YYYY-MM-DD.csv # Daily dataset snapshots
├── checks_YYYY-MM-DD.csv    # Daily check snapshots
└── organized/               # Organized data structure
    ├── latest/              # Most recent data
    ├── historical/           # Timestamped historical data
    ├── reports/             # Summary reports
    └── analysis/            # Analysis files
```

### Database Tables Created

- **`soda.checks_latest`** - Latest check results (always refreshed)
- **`soda.dataset_latest`** - Latest dataset information (always refreshed)
- **`soda.*_historical`** - Historical data files
- **`soda.analysis_summary`** - Analysis and summary data

### Key Features

✅ **Complete Data Fetch**: Gets ALL data from Soda Cloud (not filtered)  
✅ **API Rate Limiting**: Respectful API usage with delays  
✅ **Historical Tracking**: Maintains all historical data  
✅ **Latest Updates**: Always updates to most recent data  
✅ **Clean Restart**: Can completely reset and re-upload data  
✅ **Error Handling**: Robust error handling and retry logic  

## 📊 Data Quality Features

### Comprehensive Quality Checks
- **Schema Validation**: Ensures table structure integrity
- **Completeness Checks**: Validates data completeness across layers
- **Uniqueness Checks**: Prevents duplicate records
- **Validity Checks**: Ensures data format compliance
- **Business Logic Checks**: Validates business rules
- **Freshness Checks**: Monitors data recency

### Advanced Soda Features
- **Dataset Discovery**: Automatic table and column discovery
- **Column Profiling**: Detailed statistical analysis
- **Sample Data Collection**: 100 sample rows per dataset
- **Failed Row Sampling**: Detailed failure analysis
- **Anomaly Detection**: Foundation for automated monitoring (2025)

### Layer-Specific Quality Standards
- **RAW Layer**: Relaxed thresholds for initial data assessment
- **STAGING Layer**: Stricter validation after transformation
- **MARTS Layer**: Business-ready data with strictest requirements

## 🔧 Configuration

### Soda Cloud Integration
All Soda check files include:
```yaml
# Dataset discovery
discover datasets:
  datasets:
    - include TABLE_NAME

# Column profiling
profile columns:
  columns:
    - TABLE_NAME.%
    - exclude TABLE_NAME.CREATED_AT
    - exclude TABLE_NAME.UPDATED_AT

# Sample data collection
sample datasets:
  datasets:
    - include TABLE_NAME
```

### dbt Configuration
- **Quote Identifiers**: `quote_identifiers: true` for case sensitivity
- **Uppercase Naming**: Consistent uppercase table and column names across all layers
- **Layer Separation**: Clear separation between RAW, STAGING, and MARTS
- **Standardized Schema**: All tables use uppercase column names (CUSTOMER_ID, FIRST_NAME, etc.)

### Smart Data Filtering
- **Complete Data Access**: Fetches ALL Soda Cloud data for maximum flexibility
- **Intelligent Filtering**: Notebook automatically filters for project-specific data
- **Flexible Analysis**: Can analyze different data sources by changing filter criteria
- **Dynamic File Discovery**: Always finds the latest data without hardcoding timestamps

### Airflow DAGs
- **Initialization DAG**: Sets up Snowflake tables and loads sample data
- **Pipeline DAG**: Executes data quality checks and transformations

## 📈 Monitoring & Observability

### Soda Cloud Dashboard
- Real-time data quality metrics
- Historical trend analysis
- Failed row samples for investigation
- Column profiling insights

### Soda Cloud API Integration
- **Complete Data Access**: Fetches ALL datasets and checks from Soda Cloud
- **Smart Filtering**: Intelligent filtering for project-specific data sources
- **Metadata Extraction**: Automated extraction of dataset and check metadata
- **CSV Export**: Structured data export for external reporting tools
- **Sigma Dashboard**: Ready-to-use data for Sigma dashboard creation
- **API Rate Limiting**: Optimized for efficient data extraction
- **Dynamic File Finding**: No hardcoded timestamps, always finds latest data

### Airflow UI
- DAG execution monitoring
- Task-level logging
- Pipeline performance metrics
- Error tracking and debugging

### Superset Visualization
- Interactive dashboards for data quality metrics
- Real-time visualization of Soda check results
- Custom charts and reports
- Data exploration and analysis tools

## 🛠️ Available Commands

```bash
# Service Management
make all-up                  # Start all services (Airflow + Superset)
make airflow-up             # Start Airflow services only
make superset-up            # Start Superset services only
make airflow-down           # Stop Airflow services
make superset-down          # Stop Superset services
make airflow-status         # Check Airflow status
make superset-status        # Check Superset status

# Pipeline Execution
make airflow-trigger-init   # Run initialization DAG
make airflow-trigger-pipeline # Run main pipeline DAG

# Soda Data Management
make superset-upload-data   # Complete workflow: extract + organize + upload to Superset
make soda-dump              # Extract Soda Cloud metadata to CSV
make organize-soda-data     # Organize Soda data in friendly structure (always updates to latest)
make soda-data              # Legacy: organize + upload to Superset
make superset-clean-restart # Clean restart Superset (removes all data)
make superset-reset-data    # Reset only Superset data (keep containers)
make superset-reset-schema  # Reset only soda schema (fixes table structure issues)

# Development
make airflow-logs           # View Airflow logs
make superset-logs          # View Superset logs
make dbt-debug              # Debug dbt configuration
make soda-scan              # Run Soda scans manually
```

## 📋 Data Quality Checks by Layer

### RAW Layer (4 tables)
- **CUSTOMERS**: 10,000+ customer records
- **PRODUCTS**: 1,000+ product catalog
- **ORDERS**: 20,000+ order transactions
- **ORDER_ITEMS**: 50,000+ order line items

### STAGING Layer (4 tables)
- **STG_CUSTOMERS**: Cleaned customer data with quality flags
- **STG_PRODUCTS**: Standardized product information
- **STG_ORDERS**: Validated order transactions
- **STG_ORDER_ITEMS**: Processed order line items

### MARTS Layer (2 tables)
- **DIM_CUSTOMERS**: Customer dimension with segmentation
- **FACT_ORDERS**: Order fact table with business metrics

## 🔍 Quality Metrics

### Check Categories
- **Schema Validation**: Table structure integrity
- **Row Count**: Volume validation
- **Completeness**: Missing value detection
- **Uniqueness**: Duplicate prevention
- **Validity**: Format and range validation
- **Business Logic**: Domain-specific rules
- **Freshness**: Data recency monitoring

### Sampling Strategy
- **Individual Checks**: 50-5,000 samples based on table size
- **Failed Rows**: Detailed failure analysis
- **Dataset Samples**: 100 rows per table for analysis

## 🚨 Troubleshooting

### Common Issues

#### **Soda Cloud Data Extraction**
1. **API Credentials**: Verify `SODA_CLOUD_API_KEY_ID` and `SODA_CLOUD_API_KEY_SECRET` in `.env`
2. **API Host**: Check `SODA_CLOUD_HOST` is correct (US: `https://cloud.us.soda.io`, EU: `https://cloud.soda.io`)
3. **Network**: Ensure internet connectivity to Soda Cloud
4. **Rate Limits**: If getting rate limit errors, the script includes built-in delays

#### **Data Organization & Upload**
1. **Missing Data**: Run `make soda-dump` first to extract data from Soda Cloud
2. **Upload Errors**: Check Superset container is running with `make superset-status`
3. **Database Connection**: Verify Superset database is healthy
4. **File Permissions**: Ensure `superset/data/` directory is writable

#### **General Issues**
1. **Snowflake Connection**: Verify credentials in `.env`
2. **Docker**: Check container logs with `make airflow-logs` or `make superset-logs`
3. **dbt**: Validate profiles with `make dbt-debug`

### Log Locations
- Airflow logs: `airflow/airflow-logs/`
- dbt logs: Available in Airflow UI
- Soda logs: Integrated with Airflow task logs
- Superset logs: `make superset-logs`

## 🎯 Complete Workflow Examples

### **Daily Data Quality Workflow**
```bash
# 1. Start all services
make all-up

# 2. Run data quality pipeline
make airflow-trigger-pipeline

# 3. Extract and visualize Soda Cloud data
make superset-upload-data

# 4. Access dashboards
# - Airflow: http://localhost:8080
# - Superset: http://localhost:8089
```

### **Fresh Start Workflow**
```bash
# 1. Clean restart everything
make superset-clean-restart
make airflow-down && make airflow-up

# 2. Initialize data
make airflow-trigger-init

# 3. Run pipeline
make airflow-trigger-pipeline

# 4. Extract and visualize data
make superset-upload-data
```

### **Data Update Workflow**
```bash
# 1. Extract fresh data from Soda Cloud
make soda-dump

# 2. Organize and upload to Superset
make superset-upload-data

# 3. Check results in Superset UI
```

### **Development Workflow**
```bash
# 1. Start services
make all-up

# 2. Check status
make airflow-status
make superset-status

# 3. View logs if needed
make airflow-logs
make superset-logs

# 4. Debug if needed
make dbt-debug
```

## 📚 Documentation

- [Soda Library Documentation](https://docs.soda.io/soda-library/)
- [dbt Documentation](https://docs.getdbt.com/)
- [Apache Airflow Documentation](https://airflow.apache.org/docs/)
- [Snowflake Documentation](https://docs.snowflake.com/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🎉 Success Metrics

✅ **End-to-End Pipeline**: Complete data flow from RAW to MARTS  
✅ **Data Quality**: Comprehensive checks across all layers  
✅ **Profiling & Sampling**: Advanced Soda Cloud integration  
✅ **Monitoring**: Real-time observability and alerting  
✅ **Scalability**: Production-ready architecture  
✅ **Documentation**: Complete setup and usage guides  
✅ **Uppercase Standardization**: Consistent naming across all layers  
✅ **API Integration**: Soda Cloud metadata extraction and reporting  
✅ **Fresh Reset**: Clean environment with standardized naming  

---

**Project Status**: ✅ Production Ready  
**Last Updated**: October 2025  
**Version**: 1.1.0