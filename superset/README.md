# Superset Integration for Soda Certification

This directory contains the Apache Superset configuration and dashboard templates for the Soda certification project.

## Overview

Apache Superset provides powerful data visualization capabilities for your data quality insights. It integrates seamlessly with your existing Airflow and PostgreSQL setup.

## Quick Start

### Start Superset
```bash
make superset-up
```
**Note**: Environment variables are automatically loaded and validated before starting Superset.

### Start All Services (Airflow + Superset)
```bash
make all-up
```
**Note**: Environment variables are automatically loaded and validated before starting all services.

### Access Superset UI
- URL: http://localhost:8089
- Username: admin
- Password: admin

## Available Commands

- `make superset-up` - Start Superset services
- `make superset-down` - Stop Superset services
- `make superset-status` - Check Superset status
- `make superset-logs` - View Superset logs
- `make superset-reset` - Reset Superset database

## Configuration

### Environment Variables
Superset automatically loads and validates environment variables when started with `make superset-up`. The following variables are required:

**Required Variables:**
- `SNOWFLAKE_ACCOUNT`, `SNOWFLAKE_USER`, `SNOWFLAKE_PASSWORD`
- `SNOWFLAKE_WAREHOUSE`, `SNOWFLAKE_DATABASE`, `SNOWFLAKE_SCHEMA`
- `SODA_CLOUD_API_KEY_ID`, `SODA_CLOUD_API_KEY_SECRET`

**Optional Variables:**
- `SODA_CLOUD_HOST`, `SODA_CLOUD_REGION`
- `SODA_AGENT_API_KEY_ID`, `SODA_AGENT_API_KEY_SECRET`

For complete setup instructions, see the main project README.

### Database Connection
Superset uses its own PostgreSQL database. The Soda data is automatically uploaded to the following tables:

- **soda.datasets_latest** - Latest dataset information from Soda Cloud
- **soda.checks_latest** - Latest check results from Soda Cloud  
- **soda.analysis_summary** - Analysis summary data

To connect to additional data sources:

1. Access Superset UI at http://localhost:8089
2. Go to Settings > Database Connections
3. Add your connections (e.g., Snowflake, PostgreSQL, etc.)

### Data Persistence
Your Superset dashboards, charts, and configurations are automatically preserved using Docker volumes:

- **`superset-data`** - Preserves dashboards, charts, datasets, and user configurations
- **`superset-postgres-data`** - Preserves database data and metadata
- **`superset-logs`** - Preserves application logs

**Your work is automatically saved** - no need to recreate dashboards after restarts!

### Data Quality Dashboards

Create your own dashboards in Superset using the uploaded Soda data:

- **Data Quality Score Over Time** - Track overall data quality trends
- **Failed Checks by Table** - Identify tables with most quality issues
- **Check Results Distribution** - Overview of pass/fail rates
- **Quality Issues by Severity** - Categorize issues by severity level

## Integration with Soda

Superset can visualize data from:
- Soda Cloud check results
- Airflow DAG execution logs
- Custom data quality metrics
- Snowflake data warehouse tables

## Troubleshooting

### Superset Won't Start
```bash
make superset-reset
```

### Database Schema Issues (Duplicate Tables)
If you see errors like "column does not exist" or duplicate tables:
```bash
make superset-reset-schema  # Reset only the soda schema
make superset-upload-data  # Re-upload data with correct schema
```

### Check Logs
```bash
make superset-logs
```

### Verify Status
```bash
make superset-status
```

## Next Steps

1. **Connect Data Sources**: Add your Snowflake and PostgreSQL connections
2. **Create Dashboards**: Use the templates in `dashboards/` as starting points
3. **Set Up Alerts**: Configure notifications for data quality issues
4. **Schedule Reports**: Automate dashboard generation and sharing
