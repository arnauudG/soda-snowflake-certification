# Soda Data Quality Monitoring

This directory contains the Soda data quality monitoring configuration for the Soda Certification project.

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
│   ├── mart/              # MART layer checks (strictest thresholds)
│   └── quality/           # QUALITY layer checks (monitoring)
└── README.md              # This file
```

## 🎯 Layer-Based Quality Strategy

### RAW Layer (Lenient)
- **Purpose**: Initial data quality assessment
- **Database**: `SODA_CERTIFICATION.RAW`
- **Focus**: Data completeness, basic validity

### STAGING Layer (Stricter)
- **Purpose**: Data quality after transformation
- **Database**: `SODA_CERTIFICATION.STAGING`
- **Focus**: Data consistency, business rules

### MART Layer (Strictest)
- **Purpose**: Business-ready data validation
- **Database**: `SODA_CERTIFICATION.MART`
- **Focus**: Perfect data quality, referential integrity

### QUALITY Layer (Monitoring)
- **Purpose**: Monitor data quality check execution
- **Database**: `SODA_CERTIFICATION.QUALITY`
- **Focus**: Check execution, result tracking

## 🚀 Usage

### Run Specific Layer Checks
```bash
# RAW layer
soda scan -d soda_certification_raw -c soda/configuration/configuration_raw.yml soda/checks/raw/

# STAGING layer
soda scan -d soda_certification_staging -c soda/configuration/configuration_staging.yml soda/checks/staging/

# MART layer
soda scan -d soda_certification_mart -c soda/configuration/configuration_mart.yml soda/checks/mart/

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
