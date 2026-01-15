# Superset Integration for Data Quality Visualization

This directory contains the Apache Superset configuration and dashboard templates for visualizing data quality metrics and governance information.

## Overview

Apache Superset provides powerful data visualization capabilities for your integrated data engineering, governance, and quality insights. It integrates seamlessly with your existing Airflow and PostgreSQL setup, enabling visualization of quality metrics alongside governance information.

## Quick Start

### Start Superset
```bash
make superset-up
```
**Note**: Environment variables are automatically loaded with dynamic validation. The enhanced loader supports any variables in your .env file with intelligent sensitivity detection.

### Start All Services (Airflow + Superset)
```bash
make all-up
```
**Note**: Environment variables are automatically loaded with dynamic validation. The enhanced loader supports any variables in your .env file with intelligent sensitivity detection.

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
- `make superset-clean-restart` - Clean restart Superset (removes all data)
- `make superset-reset-data` - Reset only Superset data (keep containers)
- `make superset-reset-schema` - Reset only soda schema (fixes table structure issues)
- `make superset-upload-data` - Complete Soda workflow: dump + organize + upload to Superset

## Configuration

### Environment Variables
Superset automatically loads and validates environment variables when started with `make superset-up`. The following variables are required:

**Required Variables:**
- `SNOWFLAKE_ACCOUNT`, `SNOWFLAKE_USER`, `SNOWFLAKE_PASSWORD`
- `SNOWFLAKE_WAREHOUSE`, `SNOWFLAKE_DATABASE`, `SNOWFLAKE_SCHEMA`
- `SODA_CLOUD_API_KEY_ID`, `SODA_CLOUD_API_KEY_SECRET`

**Optional Variables:**
- `SODA_CLOUD_HOST`, `SODA_CLOUD_REGION`
- `COLLIBRA_BASE_URL`, `COLLIBRA_USERNAME`, `COLLIBRA_PASSWORD` (for governance integration)

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
- **Quality by Dimension** - Analyze quality across Accuracy, Completeness, Consistency, Uniqueness, Validity, Timeliness
- **Layer Comparison** - Compare quality metrics across RAW, STAGING, and MART layers

## Integration with Data Quality and Governance

Superset can visualize data from:
- Soda Cloud check results
- Airflow DAG execution logs
- Custom data quality metrics
- Snowflake data warehouse tables
- Collibra governance metadata (if integrated)

### Quality-Gated Metadata Sync

The pipeline implements quality-gated metadata synchronization:
- **Build Phase**: dbt models materialize data in Snowflake
- **Validation Phase**: Soda quality checks validate the data
- **Governance Phase**: Collibra metadata sync (only after quality validation)

This ensures Superset visualizations reflect validated, committed data that has passed quality gates, not just data that exists in Snowflake.

### Quality Metrics Visualization

The uploaded Soda data includes:
- Dataset health status and quality metrics
- Check evaluation results (pass/fail)
- Quality dimensions (Accuracy, Completeness, Consistency, Uniqueness, Validity, Timeliness)
- Diagnostic metrics (rows tested, passed, failed, passing fraction)
- Historical trends and patterns

### Governance Integration

If Collibra integration is configured, you can visualize:
- Quality metrics linked to data assets
- Governance metadata alongside quality metrics
- Asset ownership and responsibility
- Domain-based quality analysis

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
5. **Integrate Governance Views**: Create dashboards that combine quality and governance information

---

**Last Updated**: December 2024  
**Version**: 2.0.0
