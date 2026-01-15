# Soda Data Quality Certification Project

A comprehensive demonstration of enterprise-grade data quality monitoring using Soda Library, showcasing best practices for data quality management across a complete data pipeline.

## 🎯 What This Project Demonstrates

This project is a **complete data quality certification framework** that demonstrates how to:

- **Monitor data quality** across multiple layers of a data pipeline (RAW → STAGING → MARTS)
- **Standardize quality dimensions** using industry-standard data quality metrics
- **Automate quality checks** with comprehensive validation rules
- **Visualize quality metrics** through dashboards and reporting
- **Integrate quality monitoring** into existing data pipelines

### Core Value Proposition

**Data Quality Dimensions**: All quality checks are categorized using six standardized dimensions:
- **Accuracy**: Data correctness, schema validation, and business rule compliance
- **Completeness**: Missing value detection and data coverage
- **Consistency**: Referential integrity and cross-table validation
- **Uniqueness**: Duplicate detection and prevention
- **Validity**: Format validation and constraint checking
- **Timeliness**: Data freshness and recency monitoring

## 📊 Data Quality Approach

### Multi-Layer Quality Monitoring

The project implements a **layered quality strategy** where data quality standards become progressively stricter as data moves through the pipeline:

```
RAW Layer (Source Data)
  ↓ Quality Checks: Relaxed thresholds for initial assessment
  ↓ Focus: Identify data issues at source
  
STAGING Layer (Transformed Data)
  ↓ Quality Checks: Stricter validation after transformation
  ↓ Focus: Validate data cleaning and business rules
  
MARTS Layer (Business-Ready Data)
  ↓ Quality Checks: Strictest requirements for production use
  ↓ Focus: Ensure business-ready data quality
```

### Quality Check Coverage

**50+ automated quality checks** across all layers covering:
- Schema validation and structure integrity
- Completeness and missing value detection
- Uniqueness and duplicate prevention
- Format and constraint validation
- Referential integrity checks
- Business rule validation
- Data freshness monitoring

### Quality Metrics by Layer

| Layer | Tables | Quality Focus | Threshold Strategy |
|-------|--------|---------------|-------------------|
| **RAW** | 4 tables | Initial assessment | Relaxed (tolerate some issues) |
| **STAGING** | 4 tables | Transformation validation | Stricter (validate cleaning) |
| **MARTS** | 2 tables | Business readiness | Strictest (production quality) |

## 🏗️ Architecture Overview

### Data Pipeline Flow

```
RAW Layer (Snowflake) → STAGING Layer (dbt) → MARTS Layer (dbt)
     ↓                        ↓                      ↓
Soda Quality Checks    Soda Quality Checks    Soda Quality Checks
     ↓                        ↓                      ↓
Soda Cloud Dashboard   Soda Cloud Dashboard   Soda Cloud Dashboard
     ↓                        ↓                      ↓
Superset Visualization  Superset Visualization  Superset Visualization
```

### Technology Stack

- **Data Quality**: Soda Library 1.0.5 with Soda Cloud integration
- **Orchestration**: Apache Airflow 2.8+ for workflow management
- **Transformations**: dbt Core 1.10.11 for data modeling
- **Data Warehouse**: Snowflake
- **Visualization**: Apache Superset for dashboards
- **Containerization**: Docker & Docker Compose

## 📈 Key Features

### Comprehensive Quality Monitoring
- **Standardized Dimensions**: All checks use six data quality dimensions
- **Layer-Specific Standards**: Progressive quality requirements by layer
- **Automated Validation**: 50+ checks across schema, completeness, uniqueness, validity, consistency, and timeliness
- **Failed Row Sampling**: Detailed analysis of quality issues

### Soda Cloud Integration
- **Dataset Discovery**: Automatic table and column discovery
- **Column Profiling**: Comprehensive statistical analysis
- **Sample Data Collection**: 100 sample rows per dataset
- **Centralized Monitoring**: All results in Soda Cloud dashboard
- **API Integration**: Automated metadata extraction for reporting

### Visualization & Reporting
- **Superset Dashboards**: Interactive visualization of quality metrics
- **Historical Tracking**: Trend analysis over time
- **Custom Reports**: Flexible data extraction and analysis
- **Real-time Monitoring**: Live quality metrics and alerts

## 🚀 Quick Start

### Prerequisites
- **Docker & Docker Compose** (latest version)
- **Snowflake account** with appropriate permissions
- **Soda Cloud account** (required for data extraction and visualization)
- **Python 3.11+** (for local script execution)

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
SNOWFLAKE_WAREHOUSE=COMPUTE_WH
SNOWFLAKE_DATABASE=SODA_CERTIFICATION
SNOWFLAKE_SCHEMA=RAW

# Soda Cloud Configuration
SODA_CLOUD_HOST=https://cloud.soda.io
SODA_CLOUD_API_KEY_ID=your_api_key_id
SODA_CLOUD_API_KEY_SECRET=your_api_key_secret
SODA_CLOUD_ORGANIZATION_ID=your_org_id
```

### 2. Start Services

```bash
# Start all services (Airflow + Superset)
make all-up

# Verify services are running
make airflow-status
make superset-status
```

### 3. Initialize and Run Pipeline

```bash
# Initialize data (creates tables and loads sample data)
make airflow-trigger-init

# Run complete data quality pipeline
make airflow-trigger-pipeline

# Extract and visualize Soda Cloud data
make superset-upload-data
```

### 4. Access Dashboards

- **Airflow UI**: http://localhost:8080 (admin/admin) - Monitor pipeline execution
- **Superset UI**: http://localhost:8089 (admin/admin) - View quality dashboards
- **Soda Cloud**: Your organization dashboard - Centralized quality monitoring

## 📁 Project Structure

```
├── soda/                             # Soda data quality configuration
│   ├── checks/                      # Quality checks by layer
│   │   ├── raw/                     # RAW layer checks
│   │   ├── staging/                 # STAGING layer checks
│   │   ├── mart/                    # MART layer checks
│   │   └── quality/                 # Quality monitoring
│   └── configuration/               # Soda connection configs
├── dbt/                              # Data transformations
│   ├── models/
│   │   ├── raw/                      # Raw data sources
│   │   ├── staging/                  # Staging transformations
│   │   └── mart/                     # Business-ready models
├── airflow/                          # Workflow orchestration
│   └── dags/                        # Pipeline DAGs
├── superset/                         # Visualization
│   └── data/                        # Soda Cloud data exports
└── scripts/                          # Utility scripts
```

## 📊 Data Quality Dimensions

All Soda checks are standardized with six data quality dimensions:

| Dimension | Used For | Examples |
|-----------|----------|----------|
| **Accuracy** | Data correctness, schema validation, range checks | `schema`, `row_count`, `min()`, `max()`, `avg()` |
| **Completeness** | Missing value detection | `missing_count()` |
| **Consistency** | Referential integrity, cross-table validation | `invalid_count()` with referential checks |
| **Uniqueness** | Duplicate detection | `duplicate_count()` |
| **Validity** | Format and constraint validation | `invalid_count()` with regex/values |
| **Timeliness** | Data freshness monitoring | `freshness()` |

All checks include an `attributes` section with the appropriate `dimension` field for proper categorization in Soda Cloud and reporting tools.

## 🔍 Quality Checks by Layer

### RAW Layer (4 tables)
- **CUSTOMERS**: 10,000+ customer records
- **PRODUCTS**: 1,000+ product catalog
- **ORDERS**: 20,000+ order transactions
- **ORDER_ITEMS**: 50,000+ order line items

**Quality Focus**: Initial assessment with relaxed thresholds to identify source data issues.

### STAGING Layer (4 tables)
- **STG_CUSTOMERS**: Cleaned customer data with quality flags
- **STG_PRODUCTS**: Standardized product information
- **STG_ORDERS**: Validated order transactions
- **STG_ORDER_ITEMS**: Processed order line items

**Quality Focus**: Validation after transformation with stricter requirements.

### MARTS Layer (2 tables)
- **DIM_CUSTOMERS**: Customer dimension with segmentation
- **FACT_ORDERS**: Order fact table with business metrics

**Quality Focus**: Business-ready data with strictest quality requirements.

## 🛠️ Available Commands

### Service Management
```bash
make all-up                  # Start all services
make airflow-up             # Start Airflow only
make superset-up            # Start Superset only
make airflow-down           # Stop Airflow
make superset-down          # Stop Superset
make airflow-status         # Check Airflow status
make superset-status        # Check Superset status
```

### Pipeline Execution
```bash
make airflow-trigger-init   # Initialize data
make airflow-trigger-pipeline # Run quality pipeline
```

### Data Quality Management
```bash
make superset-upload-data   # Extract + organize + upload to Superset
make soda-dump              # Extract from Soda Cloud
make organize-soda-data       # Organize data structure
```

### Development
```bash
make airflow-logs           # View Airflow logs
make superset-logs          # View Superset logs
make clean                  # Clean up artifacts
```

## 📚 Documentation

- **[Soda Configuration](soda/README.md)** - Detailed Soda setup and quality checks
- **[Airflow Setup](airflow/README.md)** - Workflow orchestration details
- **[dbt Configuration](dbt/README.md)** - Data transformation setup
- **[Superset Setup](superset/README.md)** - Visualization configuration
- **[Scripts Documentation](scripts/README.md)** - Utility scripts guide

## 🎯 Use Cases

This project demonstrates:

1. **Enterprise Data Quality Framework**: Standardized approach to data quality monitoring
2. **Multi-Layer Quality Strategy**: Progressive quality standards across data pipeline
3. **Automated Quality Checks**: Comprehensive validation rules and monitoring
4. **Quality Dimension Standardization**: Industry-standard quality metrics
5. **Integration Best Practices**: Seamless integration with existing data tools
6. **Visualization & Reporting**: Quality metrics dashboards and analysis

## 🚨 Troubleshooting

### Common Issues

**Soda Cloud Connection**
- Verify API credentials in `.env`
- Check `SODA_CLOUD_HOST` is correct
- Ensure network connectivity

**Snowflake Connection**
- Verify credentials in `.env`
- Check warehouse is running
- Ensure proper permissions

**Service Issues**
- Check container logs: `make airflow-logs` or `make superset-logs`
- Verify Docker is running
- Check service status: `make airflow-status`

## 🎉 Success Metrics

✅ **Complete Quality Framework**: Standardized dimensions across all checks  
✅ **Multi-Layer Monitoring**: Quality checks at RAW, STAGING, and MARTS layers  
✅ **Automated Validation**: 50+ automated quality checks  
✅ **Cloud Integration**: Soda Cloud for centralized monitoring  
✅ **Visualization**: Superset dashboards for quality metrics  
✅ **Production Ready**: Enterprise-grade quality monitoring framework  

---

**Project Status**: ✅ Production Ready  
**Last Updated**: December 2024  
**Version**: 1.3.0
