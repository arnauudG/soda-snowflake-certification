# 🚀 Quick Start Guide

## Prerequisites
- Docker Desktop running
- Snowflake account with credentials
- `.env` file configured

## 📋 Step-by-Step Instructions

### 1. First-Time Setup

```bash
# 1. Start Airflow services
make airflow-up

# 2. Wait for services to be ready (check status)
make airflow-status

# 3. Run complete setup (Snowflake + Pipeline)
make airflow-trigger
```

**Access Airflow UI**: http://localhost:8080 (admin/admin)

### 2. Regular Pipeline Runs

```bash
# For daily/weekly data processing
make airflow-trigger-pipeline
```

### 3. Manual Pipeline Execution

```bash
# Fresh start (reset Snowflake first)
make fresh

# Standard pipeline
make pipeline

# Layer-by-layer processing
make smooth
```

## 🎯 What Each Command Does

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `make airflow-up` | Start Airflow services | First time, after restart |
| `make airflow-trigger` | Complete setup + pipeline | First time, complete reset |
| `make airflow-trigger-pipeline` | Pipeline only | Daily/weekly runs |
| `make fresh` | Reset + run pipeline | Manual fresh start |
| `make pipeline` | Standard pipeline | Manual execution |
| `make smooth` | Layer-by-layer | Debugging, testing |

## 🔧 Troubleshooting

### Services Not Starting
```bash
make airflow-down
make airflow-up
```

### DAG Not Triggering
```bash
# Check if DAG is paused
docker exec soda-airflow-webserver airflow dags list | grep soda

# Unpause if needed
docker exec soda-airflow-webserver airflow dags unpause soda_pipeline_only
```

### Environment Issues
```bash
# Load environment
source scripts/setup/load_env.sh

# Check .env file
cat .env
```

## 📊 Expected Results

- **RAW Layer**: Some data quality failures (expected)
- **STAGING Layer**: Fewer failures (data improvement)
- **MART Layer**: Minimal failures (business-ready data)
- **Soda Cloud**: Centralized monitoring and alerting

## 🎉 Success Indicators

✅ Airflow UI accessible at http://localhost:8080  
✅ DAGs visible and unpaused  
✅ Pipeline runs without retry issues  
✅ Results sent to Soda Cloud  
✅ Data quality progression through layers  

---

**Need help?** Check the full README.md for detailed documentation.
