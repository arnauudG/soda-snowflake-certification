# 🎯 Soda Certification Project

**A comprehensive, production-ready data quality monitoring and CI/CD pipeline** that demonstrates modern data engineering best practices using Snowflake, dbt, Soda Core, Apache Airflow, and Soda Cloud integration.

## 🎯 What This Project Does

This project is a **complete data quality certification system** that:

### 🏗️ **Core Functionality**
- **Creates a realistic data pipeline** with intentional quality issues to demonstrate data quality monitoring
- **Implements a 4-layer data architecture** (RAW → STAGING → MART → QUALITY) with progressively stricter quality standards
- **Automates data quality monitoring** using Soda Core with 100+ quality checks across all layers
- **Orchestrates the entire pipeline** using Apache Airflow with Docker containerization
- **Provides comprehensive CI/CD** with GitHub Actions for automated testing and deployment

### 📊 **Data Quality Progression**
- **RAW Layer**: Lenient thresholds (28/33 checks pass) - captures initial data issues
- **STAGING Layer**: Stricter thresholds - shows data improvement after transformation
- **MART Layer**: Strictest thresholds - ensures business-ready data quality
- **QUALITY Layer**: Monitoring layer - tracks quality check execution and results

### 🚀 **Key Features**
- **End-to-End Pipeline**: Complete data flow from source to business-ready analytics
- **Automated Quality Monitoring**: 100+ Soda checks with progressive quality standards
- **CI/CD Integration**: Automated testing, quality gates, and deployment
- **Production-Ready**: Docker containerization, proper error handling, monitoring
- **Educational**: Demonstrates modern data engineering patterns and best practices

## 🏗️ System Architecture

### 📊 **Data Flow Architecture**
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   RAW Layer     │    │ STAGING Layer   │    │  MART Layer     │    │ QUALITY Layer   │
│                 │    │                 │    │                 │    │                 │
│ • Source Data   │───▶│ • dbt Models    │───▶│ • dbt Models    │───▶│ • Soda Results  │
│ • Quality Issues│    │ • Data Cleaning │    │ • Business Data │    │ • Monitoring    │
│ • Soda Checks   │    │ • Soda Checks   │    │ • Soda Checks   │    │ • Soda Checks   │
└─────────────────┘    └─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │                       │
         └───────────────────────┼───────────────────────┼───────────────────────┘
                                 │                       │
                                 ▼                       ▼
                    ┌─────────────────────────────────────────┐
                    │           Soda Cloud Platform          │
                    │                                         │
                    │ • Centralized Monitoring               │
                    │ • Automated Alerting                  │
                    │ • Historical Trends                   │
                    │ • Team Collaboration                  │
                    └─────────────────────────────────────────┘
```

### 🔄 **CI/CD Pipeline Architecture**
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GitHub PR     │    │  GitHub Actions │    │  Quality Gates  │    │  Production     │
│                 │    │                 │    │                 │    │                 │
│ • Code Changes  │───▶│ • Auto Testing  │───▶│ • Quality Checks│───▶│ • Auto Deploy   │
│ • Pull Request  │    │ • DAG Validation│    │ • Test Results  │    │ • Monitoring    │
│ • Code Review   │    │ • Docker Build  │    │ • Quality Gates │    │ • Alerts        │
└─────────────────┘    └─────────────────┘    └─────────────────┘    └─────────────────┘
```

### 🐳 **Docker Architecture**
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Airflow Web    │    │ Airflow Scheduler│   │  Airflow Init  │    │   PostgreSQL    │
│                 │    │                 │    │                 │    │                 │
│ • Web UI        │    │ • DAG Execution │    │ • DB Setup     │    │ • Metadata DB   │
│ • Task Monitor  │    │ • Task Scheduling│   │ • User Creation│    │ • State Storage│
│ • DAG Management│    │ • Retry Logic   │    │ • Permissions  │    │ • Log Storage   │
└─────────────────┘    └─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Quick Start Guide

### Prerequisites
- Docker Desktop running
- Snowflake account with credentials
- Soda Cloud account (optional, for centralized monitoring)

### 🎯 **Super Simple Setup (3 Commands)**

```bash
# 1. Setup environment (checks .env file exists)
make setup

# 2. Start Airflow services (includes all fixes)
make airflow-up

# 3. Run initialization (first time only)
make airflow-trigger-init
```

**That's it!** 🎉 Your pipeline is now running.

### 🔧 **What the Setup Does (All Fixes Included)**

The `make airflow-up` command now includes these critical fixes:

1. **Environment Variables**: Automatically loads `.env` file into all containers
2. **Service Initialization**: Waits 30 seconds for services to fully start
3. **DAG Auto-Unpause**: Automatically unpauses all Soda DAGs
4. **Logging Setup**: Creates necessary log directories
5. **Docker Integration**: All commands work with Docker containers

### 📝 **Step-by-Step Details**

#### 1. **Environment Setup**
```bash
make setup
```
This command:
- ✅ Creates virtual environment
- ✅ Installs dependencies
- ✅ Checks `.env` file exists
- ⚠️ **Ensure `.env` has your Snowflake credentials**

#### 2. **Start Services**
```bash
make airflow-up
```
This command:
- ✅ Starts all Airflow services with Docker
- ✅ Loads all DAGs automatically
- ✅ Unpauses all Soda DAGs
- ✅ Web UI available at http://localhost:8080 (admin/admin)

#### 3. **First-Time Initialization**
```bash
make airflow-trigger-init
```
This command:
- ✅ Resets Snowflake database
- ✅ Creates sample data with quality issues
- ✅ Prepares foundation for pipeline runs

## 📋 Complete Workflow Guide

### Phase 1: Initial Setup (Run Once)

#### Option A: Fresh Initialization Only
```bash
# Trigger initialization only (fresh setup)
make airflow-trigger-init
# or
docker exec soda-airflow-webserver airflow dags trigger soda_initialization
```

**What this does:**
- ✅ Resets Snowflake database
- ✅ Sets up schemas and tables
- ✅ Generates sample data with quality issues
- ✅ Prepares foundation for pipeline runs

#### Option B: Fresh Start + Pipeline
```bash
# First run initialization, then pipeline
make airflow-trigger-init
# Wait for completion, then run pipeline
make airflow-trigger-pipeline
```

**What this does:**
- ✅ Resets Snowflake database
- ✅ Sets up schemas and tables
- ✅ Generates sample data with quality issues
- ✅ **Layer 1**: RAW data quality checks
- ✅ **Layer 2**: dbt staging models + staging quality checks
- ✅ **Layer 3**: dbt mart models + mart quality checks
- ✅ **Layer 4**: Quality monitoring + dbt tests
- ✅ Sends results to Soda Cloud

#### Option C: Manual Setup
```bash
# 1. Reset Snowflake (if needed)
python3 scripts/setup/reset_snowflake.py --force

# 2. Setup Snowflake with sample data
python3 scripts/setup/setup_snowflake.py

# 3. Run pipeline manually
./scripts/run_pipeline.sh --fresh
```

### Phase 2: Regular Pipeline Execution

#### For Daily/Weekly Data Processing
```bash
# Trigger pipeline run DAG (recommended for regular runs)
make airflow-trigger-pipeline
# or
docker exec soda-airflow-webserver airflow dags trigger soda_pipeline_run
```

**What this does:**
- ✅ **Layer 1**: RAW data quality checks
- ✅ **Layer 2**: dbt staging models + staging quality checks
- ✅ **Layer 3**: dbt mart models + mart quality checks  
- ✅ **Layer 4**: Quality monitoring + dbt tests
- ✅ Sends results to Soda Cloud
- ✅ Cleans up temporary artifacts

#### For Manual Pipeline Execution
```bash
# Standard pipeline
./scripts/run_pipeline.sh

# Fresh pipeline (resets Snowflake first)
./scripts/run_pipeline.sh --fresh

# Smooth pipeline (layer-by-layer processing)
./scripts/run_pipeline.sh --smooth
```

## 🎯 Available DAGs

### 1. `soda_initialization` (Initialization Only)
- **Purpose**: Fresh Snowflake setup with sample data
- **When to use**: First-time setup, fresh start, testing
- **Tasks**: Snowflake reset → Snowflake setup
- **Trigger**: `make airflow-trigger-init`
- **Frequency**: Run once

### 2. `soda_pipeline_run` (Layered Pipeline)
- **Purpose**: Layered data processing with quality checks at each stage
- **When to use**: Daily/weekly runs, scheduled execution
- **Layered Tasks**: 
  - **Layer 1**: RAW data + RAW quality checks
  - **Layer 2**: dbt staging models + staging quality checks  
  - **Layer 3**: dbt mart models + mart quality checks
  - **Layer 4**: Quality monitoring + dbt tests
- **Trigger**: `make airflow-trigger-pipeline`
- **Frequency**: Regular runs


## 📊 Expected Results

### Data Quality Progression
- **RAW Layer**: 28/33 checks passed (some failures expected)
- **STAGING Layer**: Fewer failures (data improvement)
- **MART Layer**: Minimal failures (business-ready data)
- **QUALITY Layer**: Perfect monitoring

### Soda Cloud Integration
- ✅ Centralized monitoring dashboard
- ✅ Automated alerting for critical issues
- ✅ Historical trends and analytics
- ✅ Team collaboration features

## 🔧 Development Commands

### Airflow Management
```bash
# Start services
make airflow-up

# Stop services
make airflow-down

# Check status
make airflow-status

# View logs
make airflow-logs

# Rebuild containers
make airflow-rebuild

# List DAGs
make airflow-list
```

### Pipeline Execution
```bash
# Fresh pipeline (reset + run)
make fresh

# Standard pipeline
make pipeline

# Smooth pipeline (layer-by-layer)
make smooth

# Clean up artifacts
make clean
```

### Manual Soda Commands
```bash
# Test connection
soda test-connection -d soda_certification_raw -c soda/configuration/configuration_raw.yml

# Run specific checks
soda scan -d soda_certification_raw -c soda/configuration/configuration_raw.yml soda/checks/raw/customers.yml
soda scan -d soda_certification_staging -c soda/configuration/configuration_staging.yml soda/checks/staging/stg_customers.yml
soda scan -d soda_certification_mart -c soda/configuration/configuration_mart.yml soda/checks/mart/dim_customers.yml
```

## 📁 Complete Project Structure

```
Soda-Certification/
├── 🚀 AIRFLOW ORCHESTRATION
│   ├── airflow/
│   │   └── dags/
│   │       ├── soda_initialization.py      # Initialization DAG (fresh setup)
│   │       └── soda_pipeline_run.py        # Layered Pipeline DAG (layer-by-layer processing)
│   └── docker/
│       ├── docker-compose.yml              # Multi-service Docker setup
│       ├── Dockerfile                       # Custom Airflow image
│       └── airflow-logs/                    # Persistent log storage
│
├── 🔄 DATA TRANSFORMATION (dbt)
│   ├── dbt/
│   │   ├── dbt_project.yml                  # dbt project configuration
│   │   ├── profiles.yml                     # Snowflake connection profiles
│   │   ├── models/                          # dbt models organized by layer
│   │   │   ├── raw/                         # Source table definitions
│   │   │   │   └── sources.yml              # Snowflake source configuration
│   │   │   ├── staging/                     # Staging layer models
│   │   │   │   ├── stg_customers.sql        # Customer staging model
│   │   │   │   ├── stg_products.sql         # Product staging model
│   │   │   │   ├── stg_orders.sql          # Order staging model
│   │   │   │   └── stg_order_items.sql      # Order items staging model
│   │   │   └── marts/                       # Business-ready models
│   │   │       ├── dim_customers.sql        # Customer dimension
│   │   │       └── fact_orders.sql          # Order fact table
│   │   ├── tests/                           # dbt data quality tests
│   │   │   └── test_data_quality.sql        # Custom data quality tests
│   │   └── macros/                          # dbt macros
│   │       └── generate_schema_name.sql     # Schema naming macro
│
├── 🔍 DATA QUALITY MONITORING (Soda)
│   ├── soda/
│   │   ├── configuration/                   # Soda connection configs by layer
│   │   │   ├── configuration_raw.yml         # RAW layer Snowflake connection
│   │   │   ├── configuration_staging.yml    # STAGING layer connection
│   │   │   ├── configuration_mart.yml       # MART layer connection
│   │   │   └── configuration_quality.yml     # QUALITY layer connection
│   │   └── checks/                          # Data quality checks by layer
│   │       ├── raw/                         # RAW layer checks (lenient)
│   │       │   ├── customers.yml            # Customer data quality checks
│   │       │   ├── products.yml             # Product data quality checks
│   │       │   ├── orders.yml               # Order data quality checks
│   │       │   └── order_items.yml          # Order items quality checks
│   │       ├── staging/                     # STAGING layer checks (stricter)
│   │       │   ├── stg_customers.yml        # Staging customer checks
│   │       │   ├── stg_products.yml         # Staging product checks
│   │       │   ├── stg_orders.yml          # Staging order checks
│   │       │   └── stg_order_items.yml     # Staging order items checks
│   │       ├── mart/                        # MART layer checks (strictest)
│   │       │   ├── dim_customers.yml        # Customer dimension checks
│   │       │   └── fact_orders.yml         # Order fact table checks
│   │       └── quality/                     # QUALITY layer checks (monitoring)
│   │           └── check_results.yml        # Quality check execution monitoring
│
├── 🛠️ AUTOMATION & SETUP
│   ├── scripts/
│   │   ├── run_pipeline.sh                  # Main pipeline execution script
│   │   ├── setup/                           # Environment setup scripts
│   │   │   ├── requirements.txt             # Python dependencies
│   │   │   ├── load_env.sh                  # Environment variable loader
│   │   │   ├── reset_snowflake.py           # Snowflake database reset
│   │   │   ├── setup_snowflake.py           # Snowflake initialization
│   │   └── data-quality-tests/              # Custom quality test scripts
│   │       └── test_raw_checks.py          # Raw data quality validation
│   │
├── 🚀 CI/CD & DEPLOYMENT
│   ├── .github/
│   │   └── workflows/                       # GitHub Actions workflows
│   │       ├── complete-pipeline-test.yml  # End-to-end pipeline testing
│   │       ├── airflow-dag-test.yml         # Airflow DAG validation
│   │       ├── docker-test.yml              # Docker build and service testing
│   │       ├── soda-data-quality.yml        # Data quality CI/CD
│   │       ├── deploy.yml                   # Production deployment
│   │       └── test-docker.yml              # Docker integration testing
│   │
├── 📚 DOCUMENTATION
│   ├── README.md                            # This comprehensive guide
│   ├── SETUP_GUIDE.md                       # Complete setup guide with all fixes
│   ├── CI_CD_TESTING.md                     # CI/CD testing strategy and implementation
│   └── Makefile                             # Development commands
│
└── 🔧 CONFIGURATION
    ├── .env                                  # Environment variables (create this)
    ├── .gitignore                           # Git ignore patterns
    └── .venv/                               # Python virtual environment (auto-created)
```

### 🎯 **Key Components Explained**

| Component | Purpose | Technology | Key Files |
|-----------|---------|------------|-----------|
| **Airflow Orchestration** | Pipeline scheduling and execution | Apache Airflow + Docker | `airflow/dags/*.py`, `docker/docker-compose.yml` |
| **Data Transformation** | ETL/ELT data processing | dbt + Snowflake | `dbt/models/`, `dbt/dbt_project.yml` |
| **Data Quality** | Automated quality monitoring | Soda Core + Soda Cloud | `soda/checks/`, `soda/configuration/` |
| **CI/CD Pipeline** | Automated testing and deployment | GitHub Actions | `.github/workflows/*.yml` |
| **Infrastructure** | Containerized services | Docker + Docker Compose | `docker/`, `Dockerfile` |
| **Automation** | Setup and execution scripts | Bash + Python | `scripts/`, `Makefile` |

## 🎓 What This Project Demonstrates

### 🏗️ **Modern Data Engineering Patterns**
- **4-Layer Data Architecture**: RAW → STAGING → MART → QUALITY progression
- **Progressive Data Quality**: Lenient → Stricter → Strictest quality standards
- **Infrastructure as Code**: Docker containerization with proper service orchestration
- **CI/CD for Data**: Automated testing, quality gates, and deployment pipelines
- **Monitoring & Observability**: Centralized quality monitoring with Soda Cloud

### 🔧 **Technical Skills Demonstrated**
- **Data Orchestration**: Apache Airflow DAGs with proper task dependencies
- **Data Transformation**: dbt models with staging and mart layer patterns
- **Data Quality**: Soda Core with 100+ quality checks across all layers
- **Cloud Integration**: Snowflake data warehouse with Soda Cloud monitoring
- **Containerization**: Multi-service Docker setup with health checks
- **Automation**: GitHub Actions workflows for CI/CD
- **Scripting**: Bash and Python automation scripts

### 📊 **Real-World Data Quality Scenarios**
- **Intentional Quality Issues**: Sample data with realistic quality problems
- **Quality Progression**: Shows how data quality improves through transformation layers
- **Monitoring Dashboard**: Centralized view of all quality metrics and trends
- **Automated Alerting**: Quality gates that prevent bad data from reaching production
- **Historical Tracking**: Quality trends and analytics over time

### 🚀 **Production-Ready Features**
- **Error Handling**: Proper retry logic and failure management
- **Logging**: Comprehensive logging and monitoring
- **Security**: Environment variable management and secret handling
- **Scalability**: Configurable warehouse sizes and parallel processing
- **Documentation**: Comprehensive setup and troubleshooting guides

## 🎯 **Use Cases & Applications**

### 📚 **Educational & Training**
- **Data Engineering Bootcamps**: Complete end-to-end data pipeline example
- **Quality Certification**: Demonstrates Soda Core capabilities and best practices
- **CI/CD Learning**: Shows how to implement data quality in CI/CD pipelines
- **Architecture Patterns**: Modern data architecture with quality monitoring

### 🏢 **Enterprise Applications**
- **Data Quality Framework**: Template for implementing data quality monitoring
- **CI/CD Pipeline**: Production-ready CI/CD for data projects
- **Quality Gates**: Automated quality validation in data pipelines
- **Monitoring Dashboard**: Centralized data quality monitoring solution

### 🔬 **Research & Development**
- **Quality Metrics**: Study data quality progression through transformation layers
- **Automation Testing**: Test data quality automation strategies
- **Performance Analysis**: Monitor pipeline performance and optimization
- **Best Practices**: Document and share data engineering best practices

## 🚨 Troubleshooting

### 🔧 **Critical Fixes Applied**

#### **Fix 1: Environment Variables Not Loading**
**Problem**: Docker Compose not loading `.env` file, causing warnings like "SNOWFLAKE_ACCOUNT variable is not set"

**Solution Applied**:
```yaml
# In docker/docker-compose.yml - Added to all Airflow services:
env_file:
  - ../.env
```

#### **Fix 2: DAGs Stuck in "Queued" State**
**Problem**: DAGs triggered but never start executing

**Solution Applied**:
```bash
# In Makefile - airflow-up command now includes:
@sleep 30  # Wait for services to initialize
@docker exec soda-airflow-webserver airflow dags unpause soda_initialization || true
@docker exec soda-airflow-webserver airflow dags unpause soda_pipeline_run || true
```

#### **Fix 3: Logging Directory Issues**
**Problem**: Airflow scheduler fails with "No such file or directory: '/opt/airflow/logs/scheduler'"

**Solution Applied**:
```bash
# Create logs directory before starting services
mkdir -p docker/airflow-logs/scheduler/$(date +%Y-%m-%d)
```

#### **Fix 4: Local Airflow CLI vs Docker**
**Problem**: Local Airflow CLI cannot interact with Dockerized Airflow

**Solution Applied**:
```bash
# All Makefile commands now use docker exec:
docker exec soda-airflow-webserver airflow dags trigger <dag_id>
docker exec soda-airflow-webserver airflow dags list
```

### 🔧 **Quick Fixes**

#### **Services Not Starting**
```bash
# Stop and restart services
make airflow-down
make airflow-up
```

#### **DAGs Not Running**
```bash
# Unpause all DAGs
make airflow-unpause-all

# Check DAG status
make airflow-list
```

#### **Environment Issues**
```bash
# Check .env file exists and has correct values
cat .env

# Verify required variables are set
grep -E "SNOWFLAKE_ACCOUNT|SNOWFLAKE_USER|SNOWFLAKE_PASSWORD" .env
```

#### **Docker Issues**
```bash
# Rebuild containers (fixes most issues)
make airflow-rebuild

# Check service status
make airflow-status
```

#### **Logging Issues**
```bash
# Create missing logs directory
mkdir -p docker/airflow-logs/scheduler/$(date +%Y-%m-%d)

# Rebuild containers
make airflow-rebuild
```

### 🔍 **Debug Commands**

#### **Check Service Status**
```bash
make airflow-status          # Check if services are running
make airflow-list            # List available DAGs
```

#### **View Logs**
```bash
make airflow-logs            # View all service logs
docker logs soda-airflow-scheduler | tail -20  # Scheduler logs
```

#### **Test DAGs**
```bash
# Test initialization
make airflow-trigger-init

# Test pipeline run
make airflow-trigger-pipeline
```

### ⚠️ **Common Issues & Solutions**

| Issue | Solution | Root Cause |
|-------|----------|------------|
| **DAGs not loading** | Run `make airflow-unpause-all` | DAGs are paused by default |
| **Environment variables missing** | Check `.env` file exists and has correct values | Missing `env_file` in docker-compose.yml |
| **Docker services not starting** | Run `make airflow-rebuild` | Container build issues |
| **DAGs stuck in queued state** | Check if DAGs are paused, run `make airflow-unpause-all` | Services not fully initialized |
| **Snowflake connection failed** | Verify credentials in `.env` file | Incorrect credentials or missing variables |
| **Logging directory errors** | Run `make airflow-rebuild` | Missing logs directory structure |
| **Local Airflow CLI errors** | Use `make` commands instead | Local CLI can't access Docker containers |

### 🛠️ **Advanced Troubleshooting**

#### **Complete Reset (Nuclear Option)**
```bash
# Stop everything
make airflow-down

# Remove all containers and volumes
cd docker && docker-compose down -v
cd docker && docker system prune -f

# Rebuild from scratch
make airflow-rebuild
```

#### **Environment Variable Debugging**
```bash
# Check if variables are loaded in container
docker exec soda-airflow-webserver env | grep SNOWFLAKE

# Check .env file format
cat .env | grep -v "^#" | grep -v "^$"
```

#### **DAG Execution Debugging**
```bash
# Check DAG run history
docker exec soda-airflow-webserver airflow dags list-runs -d soda_initialization

# Check task logs
docker exec soda-airflow-webserver airflow tasks list soda_initialization
```

## 📈 Production Deployment

### Scheduling
1. **Initial Setup**: Run `soda_initialization` once
2. **Regular Processing**: Schedule `soda_pipeline_run` to run daily/weekly
3. **Monitoring**: Use Soda Cloud for centralized monitoring

### Monitoring
- **Airflow UI**: http://localhost:8080 for pipeline monitoring
- **Soda Cloud**: Centralized data quality monitoring
- **Logs**: Check Airflow logs for detailed execution information

### Scaling
- Increase warehouse size for larger datasets
- Adjust Soda check thresholds based on business requirements
- Set up automated alerting in Soda Cloud

## 🎯 Best Practices

1. **Layer Progression**: Start with RAW, progress to MART
2. **Threshold Strategy**: Lenient → Stricter → Strictest
3. **Check Organization**: Group by table and layer
4. **Performance**: Use appropriate warehouse sizes
5. **Monitoring**: Set up automated alerts in Soda Cloud
6. **Documentation**: Keep checks well-documented
7. **Testing**: Validate changes before deployment

## 🚀 CI/CD with GitHub Actions

### 🔄 **Focused CI/CD Testing Strategy**

This project includes **4 focused GitHub Actions workflows** for comprehensive CI/CD testing:

| Test Type | Workflow | Trigger | Purpose | Key Features |
|-----------|----------|---------|---------|--------------|
| **1. Airflow Instances** | `airflow-dag-test.yml` | Airflow/Docker changes | Test Airflow services and DAGs | Docker build → Airflow services → DAG validation → Integration testing |
| **2. dbt Models** | `soda-data-quality.yml` | dbt changes | Test dbt model execution | dbt models → Data transformation → Quality validation |
| **3. Soda Checks** | `soda-data-quality.yml` | Soda changes | Test data quality checks | Soda scans → Quality reports → Soda Cloud integration |
| **4. Pipeline Run** | `complete-pipeline-test.yml` | Any changes | Test complete pipeline execution | End-to-end pipeline → All components → Integration testing |

### 🎯 **CI/CD Test Details**

#### **Test 1: Airflow Instances** (`airflow-dag-test.yml`)
- **Triggers**: Changes to Airflow DAGs or Docker files
- **Purpose**: Test Airflow services and DAG functionality
- **Test Coverage**:
  - ✅ Docker container build and startup
  - ✅ Airflow webserver and scheduler health
  - ✅ DAG syntax validation and loading
  - ✅ DAG execution and task dependencies
  - ✅ Service integration and communication

#### **Test 2: dbt Models** (`soda-data-quality.yml`)
- **Triggers**: Changes to dbt models or data transformation logic
- **Purpose**: Test dbt model execution and data transformation
- **Test Coverage**:
  - ✅ dbt model compilation and syntax validation
  - ✅ Data transformation logic (RAW → STAGING → MART)
  - ✅ Model dependencies and execution order
  - ✅ Data quality and integrity checks
  - ✅ Snowflake connection and warehouse usage

#### **Test 3: Soda Checks** (`soda-data-quality.yml`)
- **Triggers**: Changes to Soda configuration or quality checks
- **Purpose**: Test data quality monitoring and validation
- **Test Coverage**:
  - ✅ Soda Core installation and configuration
  - ✅ Data quality checks on all layers (RAW, STAGING, MART, QUALITY)
  - ✅ Quality threshold validation and reporting
  - ✅ Soda Cloud integration and result transmission
  - ✅ Quality metrics and trend analysis

#### **Test 4: Pipeline Run** (`complete-pipeline-test.yml`)
- **Triggers**: Any changes to the repository
- **Purpose**: Test complete end-to-end pipeline execution
- **Test Coverage**:
  - ✅ Full pipeline orchestration (Airflow → dbt → Soda)
  - ✅ End-to-end data flow validation
  - ✅ Integration between all components
  - ✅ Error handling and recovery mechanisms
  - ✅ Performance and resource utilization

### 🔒 **Quality Gates & Security**

#### **Required Checks for Merging**
- ✅ All workflows must pass before merging
- ✅ Data quality checks are mandatory
- ✅ DAG syntax validation required
- ✅ Docker services must be healthy
- ✅ End-to-end pipeline must complete successfully

#### **Security Features**
- 🔐 GitHub secrets for sensitive data (Snowflake, Soda Cloud)
- 🔐 Environment variable management
- 🔐 Secure credential handling
- 🔐 No hardcoded secrets in code

### 📊 **Monitoring & Reporting**

#### **GitHub Actions Dashboard**
- Real-time workflow execution monitoring
- Detailed logs for troubleshooting
- Workflow success/failure tracking
- Performance metrics and timing

#### **Soda Cloud Integration**
- Centralized data quality monitoring
- Automated alerting for quality issues
- Historical quality trends
- Team collaboration features

#### **Pull Request Integration**
- Quality results in PR comments
- Status checks prevent bad merges
- Automated quality reports
- Team notifications for issues

### Required GitHub Secrets
Configure these in your GitHub repository settings:

```bash
# Snowflake Configuration
SNOWFLAKE_ACCOUNT=your_account_identifier
SNOWFLAKE_USER=your_username
SNOWFLAKE_PASSWORD=your_password_or_pat
SNOWFLAKE_ROLE=ACCOUNTADMIN
SNOWFLAKE_WAREHOUSE=SODA_WH
SNOWFLAKE_DATABASE=SODA_CERTIFICATION
SNOWFLAKE_SCHEMA=RAW

# Soda Cloud Configuration
SODA_CLOUD_API_KEY_ID=your_api_key_id
SODA_CLOUD_API_KEY_SECRET=your_api_key_secret
SODA_CLOUD_HOST=cloud.soda.io
```

### Workflow Features
- ✅ **Automated Quality Checks**: Soda scans on every PR
- ✅ **DAG Validation**: Airflow DAG syntax testing
- ✅ **Complete Testing**: End-to-end pipeline validation
- ✅ **Production Deployment**: Automated deployment
- ✅ **Quality Gates**: Required for merging
- ✅ **Team Notifications**: Automated alerts

## 📚 Additional Resources

- [Soda Core Documentation](https://docs.soda.io/)
- [dbt Documentation](https://docs.getdbt.com/)
- [Airflow Documentation](https://airflow.apache.org/docs/)
- [Snowflake Documentation](https://docs.snowflake.com/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

## 🤝 Support

For issues and questions:
1. Check the troubleshooting section above
2. Review Airflow logs for error details
3. Verify environment variables are correctly set
4. Ensure Docker services are running properly
5. Check GitHub Actions logs for CI/CD issues

---

**Happy Data Quality Monitoring with CI/CD!** 🎉✨# Trigger workflow
