# Soda Certification Project

Production-ready data quality monitoring pipeline with Snowflake, dbt, Soda Core, Airflow, and Soda Cloud integration.

## 🏗️ Architecture

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

## 🚀 Quick Start Guide

### Prerequisites
- Docker Desktop running
- Snowflake account with appropriate permissions
- Soda Cloud account (optional, for centralized monitoring)
- GitHub repository (for CI/CD workflows)

### 1. Environment Setup

#### Configure Environment Variables
Create a `.env` file in the project root with your credentials:

```bash
# Snowflake Configuration
SNOWFLAKE_ACCOUNT=your_account_identifier
SNOWFLAKE_USER=your_username
SNOWFLAKE_PASSWORD=your_password_or_pat
SNOWFLAKE_ROLE=ACCOUNTADMIN
SNOWFLAKE_WAREHOUSE=SODA_WH
SNOWFLAKE_DATABASE=SODA_CERTIFICATION
SNOWFLAKE_SCHEMA=RAW

# Soda Cloud Configuration (Optional)
SODA_CLOUD_API_KEY_ID=your_api_key_id
SODA_CLOUD_API_KEY_SECRET=your_api_key_secret
SODA_CLOUD_HOST=cloud.soda.io
```

#### Install Dependencies
```bash
# Create virtual environment
python3.11 -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r scripts/setup/requirements.txt
```

### 2. Start Airflow Services

```bash
# Start all Airflow services with Docker
make airflow-up

# Check status
make airflow-status

# Access Airflow UI: http://localhost:8080 (admin/admin)
```

## 📋 Complete Workflow Guide

### Phase 1: Initial Setup (Run Once)

#### Option A: Complete Fresh Start
```bash
# Trigger the complete pipeline (Snowflake setup + data processing)
make airflow-trigger
# or
docker exec soda-airflow-webserver airflow dags trigger soda_certification_pipeline
```

**What this does:**
- ✅ Resets Snowflake database
- ✅ Sets up schemas and tables
- ✅ Generates sample data with quality issues
- ✅ Runs dbt models (RAW → STAGING → MART)
- ✅ Executes Soda data quality checks
- ✅ Sends results to Soda Cloud

#### Option B: Manual Setup
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
# Trigger pipeline-only DAG (recommended for regular runs)
make airflow-trigger-pipeline
# or
docker exec soda-airflow-webserver airflow dags trigger soda_pipeline_only
```

**What this does:**
- ✅ Runs dbt models (RAW → STAGING → MART)
- ✅ Executes Soda data quality checks on all layers
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

### 1. `soda_certification_pipeline` (Complete Pipeline)
- **Purpose**: Complete setup and pipeline execution
- **When to use**: First-time setup, complete reset, full demonstration
- **Tasks**: Snowflake reset → Snowflake setup → dbt models → Soda checks
- **Trigger**: `make airflow-trigger`

### 2. `soda_pipeline_only` (Pipeline Only)
- **Purpose**: Regular data processing and quality monitoring
- **When to use**: Daily/weekly runs, scheduled execution
- **Tasks**: dbt models → Soda checks
- **Trigger**: `make airflow-trigger-pipeline`

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

## 📁 Project Structure

```
├── airflow/
│   └── dags/
│       ├── soda_certification_dag.py    # Complete pipeline DAG
│       └── soda_pipeline_only.py       # Pipeline-only DAG
├── dbt/
│   ├── dbt_project.yml                  # dbt configuration
│   ├── models/                          # dbt models by layer
│   │   ├── raw/                         # Source definitions
│   │   ├── staging/                     # Staging models
│   │   └── marts/                       # Mart models
│   └── tests/                           # dbt tests
├── scripts/
│   ├── run_pipeline.sh                  # Main pipeline script
│   └── setup/                           # Setup scripts
│       ├── load_env.sh
│       ├── reset_snowflake.py
│       ├── setup_airflow.sh
│       └── setup_snowflake.py
├── soda/
│   ├── configuration/                  # Soda configs by layer
│   │   ├── configuration_raw.yml
│   │   ├── configuration_staging.yml
│   │   ├── configuration_mart.yml
│   │   └── configuration_quality.yml
│   └── checks/                         # Data quality checks
│       ├── raw/                        # Raw layer checks
│       ├── staging/                    # Staging layer checks
│       ├── mart/                       # Mart layer checks
│       └── quality/                    # Quality layer checks
├── docker/
│   ├── docker-compose.yml              # Docker setup
│   └── Dockerfile
├── Makefile                            # Make commands
└── README.md                           # This file
```

## 🚨 Troubleshooting

### Common Issues

#### 1. Environment Variables Not Loading
```bash
# Check if .env file exists
ls -la .env

# Load environment manually
source scripts/setup/load_env.sh
```

#### 2. Docker Issues
```bash
# Stop all services
make airflow-down

# Rebuild containers
make airflow-rebuild

# Check Docker status
docker ps
```

#### 3. Snowflake Connection Issues
```bash
# Test connection
python3 scripts/setup/setup_snowflake.py

# Check credentials in .env file
cat .env
```

#### 4. DAG Not Triggering
```bash
# Check if DAG is paused
docker exec soda-airflow-webserver airflow dags list | grep soda

# Unpause DAG
docker exec soda-airflow-webserver airflow dags unpause soda_pipeline_only
```

### Debug Commands
```bash
# View DAG logs
docker logs soda-airflow-scheduler | tail -20

# Test DAG syntax
docker exec soda-airflow-webserver python -c "exec(open('/opt/airflow/dags/soda_pipeline_only.py').read())"

# Check task status
docker exec soda-airflow-webserver airflow tasks list soda_pipeline_only
```

## 📈 Production Deployment

### Scheduling
1. **Initial Setup**: Run `soda_certification_pipeline` once
2. **Regular Processing**: Schedule `soda_pipeline_only` to run daily/weekly
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

### Automated Workflows
- **Data Quality CI/CD**: Automated Soda scans on pull requests
- **Airflow DAG Testing**: DAG syntax and Docker validation
- **Complete Pipeline Testing**: End-to-end pipeline validation
- **Production Deployment**: Automated deployment to production

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

**Happy Data Quality Monitoring with CI/CD!** 🎉✨