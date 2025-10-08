# Apache Airflow - Soda Certification

This directory contains the Apache Airflow configuration and DAGs for orchestrating the Soda Certification data quality pipeline.

## 🏗️ Directory Structure

```
airflow/
├── docker/                     # Docker configuration
│   ├── docker-compose.yml      # Multi-container setup
│   ├── Dockerfile              # Custom Airflow image
│   ├── requirements.txt        # Python dependencies
│   └── validate_env.sh         # Environment validation
├── dags/                       # Airflow DAGs
│   ├── soda_initialization.py  # Data initialization DAG
│   └── soda_pipeline_run.py    # Main pipeline DAG
├── plugins/                    # Airflow plugins
└── README.md                   # This file
```

## 🎯 DAGs Overview

### **1. Soda Initialization DAG (`soda_initialization.py`)**

**Purpose**: One-time setup and initialization of the data pipeline

**Tasks**:
- **`reset_snowflake`**: Clean up existing Snowflake database
- **`setup_snowflake`**: Create database, schemas, tables, and sample data

**When to Use**:
- ✅ First-time setup
- ✅ Fresh start with clean data
- ✅ Testing and demonstration
- ❌ Regular pipeline runs

### **2. Soda Pipeline Run DAG (`soda_pipeline_run.py`)**

**Purpose**: Regular data quality monitoring and processing

**Layered Approach**:
1. **RAW Layer**: Data quality checks on source data
2. **STAGING Layer**: dbt transformations + quality checks
3. **MART Layer**: dbt models + quality checks
4. **QUALITY Layer**: Final validation and monitoring

**Tasks**:
- **`soda_scan_raw`**: RAW layer quality checks
- **`dbt_run_staging`**: Execute staging models
- **`soda_scan_staging`**: STAGING layer quality checks
- **`dbt_run_mart`**: Execute mart models
- **`soda_scan_mart`**: MART layer quality checks
- **`soda_scan_quality`**: Quality monitoring
- **`dbt_test`**: Execute dbt tests
- **`cleanup_artifacts`**: Clean up temporary files

## 🚀 Usage

### **Start Airflow**
```bash
make airflow-up
```

### **Access Airflow UI**
- URL: http://localhost:8080
- Username: admin
- Password: admin

### **Trigger DAGs**
```bash
# Initialize data (one-time)
make airflow-trigger-init

# Run main pipeline
make airflow-trigger-pipeline
```

### **Check Status**
```bash
make airflow-status
```

### **View Logs**
```bash
make airflow-logs
```

## 🔧 Configuration

### **Environment Variables**
Airflow automatically loads environment variables from `.env` file:

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
```

### **Docker Configuration**
- **Multi-container setup**: Airflow webserver, scheduler, worker, and PostgreSQL
- **Custom image**: Includes dbt, Soda, and project dependencies
- **Volume mounts**: Persistent logs and configuration
- **Environment validation**: Automatic environment variable checking

## 📊 Pipeline Flow

### **Initialization Flow**
```
init_start → reset_snowflake → setup_snowflake → init_end
```

### **Main Pipeline Flow**
```
pipeline_start
    ↓
raw_layer_start → soda_scan_raw → raw_layer_end
    ↓
staging_layer_start → dbt_run_staging → soda_scan_staging → staging_layer_end
    ↓
mart_layer_start → dbt_run_mart → soda_scan_mart → mart_layer_end
    ↓
quality_layer_start → [soda_scan_quality, dbt_test] → quality_layer_end
    ↓
cleanup_artifacts → pipeline_end
```

## 🎯 Data Quality Layers

### **RAW Layer**
- **Purpose**: Initial data quality assessment
- **Thresholds**: Relaxed for source data
- **Checks**: Schema validation, completeness, basic quality

### **STAGING Layer**
- **Purpose**: Validation after transformation
- **Thresholds**: Stricter than RAW
- **Checks**: Data cleaning validation, business rules

### **MART Layer**
- **Purpose**: Business-ready data validation
- **Thresholds**: Strictest requirements
- **Checks**: Business logic, referential integrity

### **QUALITY Layer**
- **Purpose**: Overall quality monitoring
- **Thresholds**: Monitoring and alerting
- **Checks**: Cross-layer validation, trend analysis

## 🔍 Monitoring & Observability

### **Airflow UI Features**
- **DAG Execution**: Visual pipeline execution monitoring
- **Task Logs**: Detailed task-level logging and debugging
- **Performance Metrics**: Execution time and resource usage
- **Error Tracking**: Failed task identification and retry logic

### **Log Locations**
- **Airflow logs**: `airflow/docker/airflow-logs/`
- **DAG logs**: Available in Airflow UI
- **Task logs**: Individual task execution logs
- **Soda logs**: Integrated with Airflow task logs

### **Monitoring Commands**
```bash
# Check service status
make airflow-status

# View recent logs
make airflow-logs

# Check specific DAG
# Access Airflow UI → DAGs → Select DAG → View logs
```

## 🛠️ Troubleshooting

### **Common Issues**

#### **DAG Not Appearing**
- **Cause**: DAG parsing errors or missing dependencies
- **Solution**: Check Airflow logs for parsing errors

#### **Task Failures**
- **Cause**: Environment variables, connection issues, or logic errors
- **Solution**: Check task logs in Airflow UI

#### **Connection Issues**
- **Cause**: Incorrect Snowflake credentials or network issues
- **Solution**: Verify environment variables and network connectivity

#### **dbt Failures**
- **Cause**: Schema issues, model errors, or dependency problems
- **Solution**: Check dbt logs and model configurations

### **Debug Commands**
```bash
# Check Airflow status
make airflow-status

# View logs
make airflow-logs

# Restart services
make airflow-down && make airflow-up

# Check environment
make airflow-validate-env
```

## 📚 Best Practices

### **DAG Development**
1. **Idempotency**: Ensure tasks can be safely re-run
2. **Error Handling**: Include proper retry logic and error handling
3. **Documentation**: Document DAGs and tasks clearly
4. **Testing**: Test DAGs in development before production

### **Task Design**
1. **Atomicity**: Each task should perform one specific function
2. **Dependencies**: Define clear task dependencies
3. **Resource Management**: Use appropriate resource allocation
4. **Monitoring**: Include proper logging and monitoring

### **Environment Management**
1. **Configuration**: Use environment variables for configuration
2. **Secrets**: Store sensitive data securely
3. **Validation**: Validate environment before execution
4. **Documentation**: Document all configuration requirements

## 🔄 Integration Points

### **dbt Integration**
- **Staging Models**: Executed in STAGING layer
- **Mart Models**: Executed in MART layer
- **Tests**: Executed in QUALITY layer
- **Schema Management**: Uses custom schema configuration

### **Soda Integration**
- **Quality Checks**: Executed at each layer
- **Configuration**: Layer-specific Soda configurations
- **Cloud Integration**: Results sent to Soda Cloud
- **Monitoring**: Integrated with Airflow monitoring

### **Snowflake Integration**
- **Connection**: Uses environment-based connection
- **Schema Management**: Clean schema separation
- **Performance**: Optimized warehouse usage
- **Security**: Secure credential management

## 🎯 Success Metrics

✅ **Reliable Orchestration**: Consistent pipeline execution  
✅ **Layer Separation**: Clear data quality layer progression  
✅ **Error Handling**: Robust error handling and retry logic  
✅ **Monitoring**: Comprehensive logging and observability  
✅ **Integration**: Seamless dbt and Soda integration  
✅ **Documentation**: Clear DAG and task documentation  
✅ **Performance**: Optimized execution and resource usage  
✅ **Maintainability**: Clean, modular DAG design  

---

**Last Updated**: December 2024  
**Version**: 1.0.0  
**Airflow Version**: 2.8+
