# 🚀 CI/CD Testing Guide

**Focused CI/CD testing strategy for the Soda Certification project with 4 specific test types.**

## 🎯 **CI/CD Testing Strategy**

This project implements a **4-tier CI/CD testing approach** to ensure comprehensive validation of all components:

### **Test Hierarchy**
```
┌─────────────────────────────────────────────────────────────┐
│                    Test 4: Pipeline Run                     │
│              (Complete End-to-End Testing)                  │
└─────────────────┬───────────────────────────────────────────┘
                  │
┌─────────────────┼───────────────────────────────────────────┐
│    Test 1: Airflow    │    Test 2: dbt    │  Test 3: Soda  │
│     Instances          │     Models        │    Checks      │
│  (Infrastructure)      │ (Data Transform)  │ (Data Quality) │
└─────────────────────────────────────────────────────────────┘
```

## 🧪 **Test 1: Airflow Instances**

### **Purpose**
Test Airflow services, DAGs, and Docker infrastructure.

### **Workflow**: `airflow-dag-test.yml`
### **Triggers**: Changes to Airflow DAGs or Docker files

### **Test Coverage**
- ✅ **Docker Container Build**
  - Container image creation
  - Dependency installation
  - Configuration validation

- ✅ **Airflow Services Health**
  - Webserver startup and health checks
  - Scheduler initialization
  - Database connectivity (PostgreSQL)

- ✅ **DAG Validation**
  - DAG syntax validation
  - DAG loading and parsing
  - Task dependency validation

- ✅ **DAG Execution**
  - Manual DAG triggering
  - Task execution and completion
  - Error handling and retries

### **Test Commands**
```bash
# Build and start services
docker-compose up -d

# Validate DAGs
airflow dags list
airflow dags state <dag_id>

# Test DAG execution
airflow dags trigger <dag_id>
```

## 🏗️ **Test 2: dbt Models**

### **Purpose**
Test data transformation logic and model execution.

### **Workflow**: `soda-data-quality.yml`
### **Triggers**: Changes to dbt models or data transformation logic

### **Test Coverage**
- ✅ **Model Compilation**
  - SQL syntax validation
  - Model dependency resolution
  - Configuration validation

- ✅ **Data Transformation**
  - RAW → STAGING layer transformation
  - STAGING → MART layer transformation
  - Data quality and integrity checks

- ✅ **Snowflake Integration**
  - Connection establishment
  - Warehouse usage optimization
  - Schema and table management

- ✅ **Model Testing**
  - Custom dbt tests execution
  - Data quality validation
  - Performance monitoring

### **Test Commands**
```bash
# Compile models
dbt compile --profiles-dir .

# Run models
dbt run --profiles-dir .

# Test models
dbt test --profiles-dir .

# Generate documentation
dbt docs generate --profiles-dir .
```

## 🔍 **Test 3: Soda Checks**

### **Purpose**
Test data quality monitoring and validation.

### **Workflow**: `soda-data-quality.yml`
### **Triggers**: Changes to Soda configuration or quality checks

### **Test Coverage**
- ✅ **Soda Core Installation**
  - Package installation and configuration
  - Connection to Snowflake
  - Configuration file validation

- ✅ **Quality Checks Execution**
  - RAW layer checks (lenient thresholds)
  - STAGING layer checks (stricter thresholds)
  - MART layer checks (strictest thresholds)
  - QUALITY layer checks (monitoring)

- ✅ **Soda Cloud Integration**
  - API connection and authentication
  - Result transmission and storage
  - Dashboard and reporting

- ✅ **Quality Metrics**
  - Check execution and results
  - Quality trend analysis
  - Alert and notification testing

### **Test Commands**
```bash
# Test connection
soda test-connection -d <data_source> -c <config_file>

# Run quality scans
soda scan -d <data_source> -c <config_file> <check_files>

# Check results
soda scan-results
```

## 🚀 **Test 4: Pipeline Run**

### **Purpose**
Test complete end-to-end pipeline execution.

### **Workflow**: `complete-pipeline-test.yml`
### **Triggers**: Any changes to the repository

### **Test Coverage**
- ✅ **Full Pipeline Orchestration**
  - Airflow DAG execution
  - dbt model execution
  - Soda quality checks
  - Component integration

- ✅ **End-to-End Data Flow**
  - Data ingestion and processing
  - Quality monitoring and validation
  - Result reporting and storage

- ✅ **Error Handling**
  - Failure detection and recovery
  - Retry mechanisms
  - Alert and notification systems

- ✅ **Performance Testing**
  - Execution time monitoring
  - Resource utilization
  - Scalability validation

### **Test Commands**
```bash
# Run complete pipeline
make airflow-trigger-init    # Initialization
make airflow-trigger-pipeline # Pipeline execution

# Monitor execution
make airflow-status
make airflow-list
```

## 🔧 **CI/CD Configuration**

### **GitHub Actions Workflows**

#### **1. Airflow DAG Test** (`airflow-dag-test.yml`)
```yaml
name: Airflow DAG Testing
on:
  push:
    paths: ['airflow/**', 'docker/**']
  pull_request:
    paths: ['airflow/**', 'docker/**']

jobs:
  test-airflow:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build and test Airflow
        run: |
          cd docker
          docker-compose up -d
          # Test DAGs and services
```

#### **2. dbt Models Test** (`soda-data-quality.yml`)
```yaml
name: dbt Models Testing
on:
  push:
    paths: ['dbt/**']
  pull_request:
    paths: ['dbt/**']

jobs:
  test-dbt:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Test dbt models
        run: |
          cd dbt
          dbt compile --profiles-dir .
          dbt run --profiles-dir .
          dbt test --profiles-dir .
```

#### **3. Soda Checks Test** (`soda-data-quality.yml`)
```yaml
name: Soda Quality Testing
on:
  push:
    paths: ['soda/**']
  pull_request:
    paths: ['soda/**']

jobs:
  test-soda:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Test Soda checks
        run: |
          # Install Soda Core
          pip install soda-core-snowflake
          # Run quality checks
          soda scan -d <data_source> -c <config> <checks>
```

#### **4. Complete Pipeline Test** (`complete-pipeline-test.yml`)
```yaml
name: Complete Pipeline Testing
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  test-pipeline:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Test complete pipeline
        run: |
          # Setup environment
          make setup
          # Start services
          make airflow-up
          # Run pipeline
          make airflow-trigger-init
          make airflow-trigger-pipeline
```

## 📊 **Test Results and Reporting**

### **Success Criteria**
- ✅ All tests must pass for merge approval
- ✅ No critical errors or failures
- ✅ Performance within acceptable limits
- ✅ Quality gates met

### **Failure Handling**
- 🔍 **Detailed Logging**: Comprehensive error reporting
- 🔄 **Retry Logic**: Automatic retry for transient failures
- 📧 **Notifications**: Team alerts for critical failures
- 📈 **Metrics**: Performance and quality trend analysis

## 🎯 **Best Practices**

### **Test Development**
1. **Incremental Testing**: Test changes in isolation
2. **Comprehensive Coverage**: All components and integrations
3. **Performance Monitoring**: Track execution times and resources
4. **Quality Gates**: Enforce quality standards

### **CI/CD Optimization**
1. **Parallel Execution**: Run independent tests in parallel
2. **Caching**: Cache dependencies and build artifacts
3. **Conditional Triggers**: Run tests only when relevant files change
4. **Resource Management**: Optimize resource usage and costs

---

**This CI/CD testing strategy ensures comprehensive validation of all pipeline components while maintaining efficiency and reliability.** 🚀✨
