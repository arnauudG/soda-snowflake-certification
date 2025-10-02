# Soda Data Quality Certification Project

A comprehensive data quality pipeline demonstrating Soda Library integration with Airflow, dbt, and Snowflake for end-to-end data quality management.

## 🎯 Project Overview

This project showcases a complete data quality pipeline with:
- **Soda Library** for data quality checks and profiling
- **Apache Airflow** for workflow orchestration
- **dbt** for data transformations
- **Snowflake** as the data warehouse
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
- **Data Quality**: Soda Library 1.12.24
- **Containerization**: Docker & Docker Compose
- **Language**: Python 3.11

## 📁 Project Structure

```
├── airflow/                          # Airflow DAGs and configuration
│   └── dags/
│       ├── soda_initialization.py    # Data initialization DAG
│       └── soda_pipeline_run.py     # Main pipeline DAG
├── dbt/                              # dbt project configuration
│   ├── models/
│   │   ├── raw/                      # Raw data sources
│   │   ├── staging/                  # Staging transformations
│   │   └── marts/                    # Business-ready models
│   ├── dbt_project.yml              # dbt project configuration
│   └── profiles.yml                 # dbt profiles for Snowflake
├── docker/                           # Docker configuration
│   ├── docker-compose.yml           # Multi-container setup
│   └── Dockerfile                   # Custom Airflow image
├── scripts/                          # Utility scripts
│   ├── setup/                       # Environment setup
│   │   ├── requirements.txt         # Python dependencies
│   │   ├── setup_snowflake.py       # Snowflake table creation
│   │   └── reset_snowflake.py       # Snowflake cleanup
│   ├── soda_dump_api.py             # Soda Cloud API data extraction
│   ├── run_soda_dump.sh             # Soda Cloud data dump runner
│   └── requirements_dump.txt         # API extraction dependencies
├── soda/                             # Soda data quality configuration
│   ├── checks/                      # SodaCL check definitions
│   │   ├── raw/                     # RAW layer quality checks
│   │   ├── staging/                 # STAGING layer quality checks
│   │   ├── marts/                   # MARTS layer quality checks
│   │   └── templates/               # Reusable check templates
│   └── configuration/               # Soda connection configurations
├── soda_dump_output/                # Soda Cloud API extracted data (latest files only)
│   ├── datasets_latest.csv         # Latest dataset metadata
│   ├── checks_latest.csv           # Latest check results metadata
│   ├── datasets_YYYY-MM-DD.csv     # Daily dataset snapshots
│   └── checks_YYYY-MM-DD.csv       # Daily check snapshots
└── Makefile                          # Project automation commands
```

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose
- Snowflake account with appropriate permissions
- Soda Cloud account (optional, for enhanced monitoring)

### 1. Environment Setup
```bash
# Clone the repository
git clone <repository-url>
cd Soda-Certification

# Set up environment variables
cp .env.example .env
# Edit .env with your Snowflake and Soda Cloud credentials
```

### 2. Start Services
```bash
# Start all services
make airflow-up

# Verify services are running
make airflow-status
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

## 🛠️ Available Commands

```bash
# Service Management
make airflow-up              # Start all services
make airflow-down            # Stop all services
make airflow-status          # Check service status

# Pipeline Execution
make airflow-trigger-init    # Run initialization DAG
make airflow-trigger-pipeline # Run main pipeline DAG

# Development
make airflow-logs            # View Airflow logs
make dbt-debug               # Debug dbt configuration
make soda-scan               # Run Soda scans manually

# Soda Cloud API
make soda-dump               # Extract Soda Cloud metadata to CSV
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
1. **Snowflake Connection**: Verify credentials in `.env`
2. **Soda Cloud**: Ensure API keys are configured
3. **Docker**: Check container logs with `make airflow-logs`
4. **dbt**: Validate profiles with `make dbt-debug`

### Log Locations
- Airflow logs: `docker/airflow-logs/`
- dbt logs: Available in Airflow UI
- Soda logs: Integrated with Airflow task logs

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