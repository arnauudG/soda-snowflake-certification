# Soda Data Quality Monitoring - Complete Integration

This directory contains the comprehensive Soda data quality monitoring configuration for the Soda Certification project, featuring **complete Soda Cloud integration** with dataset discovery, column profiling, and sample data collection.

## ✅ **Complete Soda Cloud Integration**

### 🚀 **Advanced Features Implemented**
- ✅ **Dataset Discovery**: Automatic table and column discovery across all layers
- ✅ **Column Profiling**: Comprehensive statistical analysis with smart exclusions
- ✅ **Sample Data Collection**: 100 sample rows per dataset for analysis
- ✅ **Failed Row Sampling**: Detailed failure analysis with custom SQL queries
- ✅ **Anomaly Detection**: Foundation for automated monitoring (2025)

### 📊 **Quality Coverage**
- **RAW Layer**: 4 tables with initial data quality assessment
- **STAGING Layer**: 4 tables with transformation validation
- **MARTS Layer**: 2 business-ready tables with strict quality standards
- **Total Checks**: 50+ data quality checks across all layers

## 📁 Directory Structure

```
soda/
├── configuration/           # Soda configuration files by layer
│   ├── configuration_raw.yml      # RAW layer configuration
│   ├── configuration_staging.yml  # STAGING layer configuration
│   ├── configuration_mart.yml     # MART layer configuration
│   └── configuration_quality.yml  # QUALITY layer configuration
├── checks/                 # Data quality checks organized by layer
│   ├── raw/               # RAW layer checks (lenient thresholds)
│   ├── staging/           # STAGING layer checks (stricter thresholds)
│   ├── marts/             # MARTS layer checks (strictest thresholds)
│   └── quality/           # QUALITY layer checks (monitoring)
└── README.md              # This file
```

## 🎯 Complete Soda Cloud Configuration

### **Dataset Discovery**
```yaml
discover datasets:
  datasets:
    - include TABLE_NAME
```

### **Column Profiling**
```yaml
profile columns:
  columns:
    - TABLE_NAME.%
    - exclude TABLE_NAME.CREATED_AT
    - exclude TABLE_NAME.UPDATED_AT
```

### **Sample Data Collection**
```yaml
sample datasets:
  datasets:
    - include TABLE_NAME
```

### **Layer-Specific Quality Standards**
- **RAW Layer**: Relaxed thresholds for initial assessment
- **STAGING Layer**: Stricter validation after transformation
- **MARTS Layer**: Business-ready data with strictest requirements

## 🚀 Usage

### **Complete Pipeline Execution**
The pipeline runs with full Soda Cloud integration:

```bash
# Trigger the complete pipeline with profiling and sampling
make airflow-trigger-pipeline
```

**This executes:**
1. **RAW Layer**: Data initialization + quality checks + profiling + sampling
2. **STAGING Layer**: dbt transformations + quality checks + profiling + sampling
3. **MARTS Layer**: dbt models + quality checks + profiling + sampling
4. **Soda Cloud**: All results sent to cloud dashboard

### Run Individual Layer Checks
```bash
# RAW layer
soda scan -d soda_certification_raw -c soda/configuration/configuration_raw.yml soda/checks/raw/

# STAGING layer
soda scan -d soda_certification_staging -c soda/configuration/configuration_staging.yml soda/checks/staging/

# MARTS layer
soda scan -d soda_certification_mart -c soda/configuration/configuration_mart.yml soda/checks/marts/

# QUALITY layer
soda scan -d soda_certification_quality -c soda/configuration/configuration_quality.yml soda/checks/quality/
```

### Test Individual Tables
```bash
# Test specific table
soda scan -d soda_certification_raw -c soda/configuration/configuration_raw.yml soda/checks/raw/customers.yml

# Test connection
soda test-connection -d soda_certification_raw -c soda/configuration/configuration_raw.yml
```

## ☁️ Soda Cloud Integration

All configuration files include Soda Cloud integration:
- **Centralized Monitoring**: Results sent to Soda Cloud platform
- **Automated Alerting**: Get notified when issues occur
- **Historical Trends**: Track data quality over time
- **Team Collaboration**: Share insights with stakeholders

## 🔧 Configuration

Each layer configuration includes:
- **Data source connection** (database, schema, warehouse)
- **Performance settings** (timeouts, parallel execution)
- **Soda Cloud integration** (API keys, monitoring)

## 🛠️ Maintenance

### Adding New Checks
1. Create check file in appropriate layer directory
2. Follow naming convention: `{table_name}.yml`
3. Use layer-appropriate thresholds
4. Test with `soda scan` command

### Troubleshooting
1. Check connection with `soda test-connection`
2. Validate YAML syntax
3. Review check logic and thresholds
4. Check Snowflake permissions
5. Monitor Soda Cloud connectivity

## 📚 Best Practices

1. **Layer Progression**: Start with RAW, progress to MART
2. **Threshold Strategy**: Lenient → Stricter → Strictest
3. **Check Organization**: Group by table and layer
4. **Performance**: Use appropriate warehouse sizes
5. **Monitoring**: Set up automated alerts in Soda Cloud
6. **Documentation**: Keep checks well-documented
7. **Testing**: Validate changes before deployment
