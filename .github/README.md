# 🚀 GitHub Actions CI/CD for Soda Certification

This directory contains a comprehensive GitHub Actions workflow for automated data quality testing and monitoring of the Soda Certification project.

## 📋 Available Workflows

### **soda-scan-all.yml** - Sequential Data Quality Pipeline
- **Trigger**: Pull requests and pushes to main branch
- **Purpose**: Automated sequential data quality testing across all data layers
- **Architecture**: Sequential pipeline (raw → staging → mart → quality)
- **Concurrency**: Sequential execution with no parallel runs
- **Permissions**: `contents: read`, `pull-requests: write`
- **Jobs**:
  - `raw`: Data quality scans on raw data layer
  - `staging`: Data quality scans on staging layer (depends on raw)
  - `mart`: Data quality scans on mart layer (depends on staging)
  - `quality`: Data quality scans on quality/results layer (depends on mart)

### **dbt-run-all.yml** - dbt Model Execution Pipeline
- **Trigger**: Pull requests, pushes to main branch, and manual dispatch
- **Purpose**: Automated dbt model execution in correct dependency order
- **Architecture**: Sequential pipeline (setup → staging → marts → complete)
- **Concurrency**: Sequential execution with dependency management
- **Permissions**: `contents: read`, `pull-requests: write`
- **Jobs**:
  - `dbt-setup`: Environment setup and connection testing
  - `dbt-staging`: Run staging models (stg_customers, stg_orders, stg_products, stg_order_items)
  - `dbt-marts`: Run mart models (dim_customers, fact_orders)
  - `dbt-complete`: Complete pipeline execution and testing

## 🔄 Workflow Features

### Soda Data Quality Pipeline
- **Sequential Processing**: Each layer depends on the previous one completing successfully
- **Fail-Fast**: If any layer fails, subsequent layers are skipped
- **Dependency Chain**: `raw` → `staging` → `mart` → `quality`

### dbt Model Execution Pipeline
- **Dependency-Aware**: Models run in correct dependency order
- **Layer-Based Execution**: Staging models → Mart models → Complete pipeline
- **Comprehensive Testing**: Data quality tests run after each layer
- **Documentation Generation**: Automatic dbt docs generation
- **Artifact Management**: Logs, compiled SQL, and documentation artifacts

### Smart Error Handling
- **Execution vs. Quality Failures**: Workflow only fails on execution errors, not quality check failures
- **Continue on Error**: Quality check failures don't stop the pipeline
- **Exit Code Logic**: 
  - Exit code 0 or 2: Quality checks executed (pass/warn/fail) → Job succeeds
  - Exit code 1: Execution/config error → Job fails

### Artifact Management
- **Scan Results**: JSON artifacts for each layer with detailed results
- **Cloud Links**: Direct links to Soda Cloud dashboards
- **Artifact Structure**: Each artifact contains:
  - `soda_scan_results_[layer].json`: Detailed scan results in JSON format
  - `soda_scan_results_[layer].link.txt`: Direct link to Soda Cloud dashboard
- **Artifact Names**:
  - `soda-scan-results-raw`
  - `soda-scan-results-staging`
  - `soda-scan-results-mart`
  - `soda-scan-results-quality`

### PR Integration
- **Automatic Comments**: Detailed scan results posted to pull requests
- **Comment Format**: Each layer gets a separate comment with:
  - **Header**: "Soda scan ([layer]) completed"
  - **Soda Cloud Link**: Direct access to dashboard
  - **Summary**: Pass/Warn/Fail counts in code block
  - **Artifact Reference**: Downloadable scan results
- **Comment Action**: Uses `thollander/actions-comment-pull-request@8c77f42bbcc27c832a3a5962c8f9a60e34b594f3`
- **Error Handling**: Comments continue on error to avoid blocking workflow

## 🔧 Required GitHub Secrets

Configure these secrets in your GitHub repository settings:

### Snowflake Configuration
```
SNOWFLAKE_ACCOUNT=your_account_identifier
SNOWFLAKE_USER=your_username
SNOWFLAKE_PASSWORD=your_password_or_pat
SNOWFLAKE_ROLE=ACCOUNTADMIN
SNOWFLAKE_WAREHOUSE=SODA_WH
SNOWFLAKE_DATABASE=SODA_CERTIFICATION
```

### Soda Cloud Configuration
```
SODA_CLOUD_API_KEY_ID=your_api_key_id
SODA_CLOUD_API_KEY_SECRET=your_api_key_secret
SODA_CLOUD_HOST=https://cloud.soda.io
```

### Environment Variables Used
The workflow uses these environment variables in each job:
- **Soda Cloud**: `SODA_CLOUD_API_KEY_ID`, `SODA_CLOUD_API_KEY_SECRET`, `SODA_CLOUD_HOST`
- **Snowflake**: `SNOWFLAKE_ACCOUNT`, `SNOWFLAKE_USER`, `SNOWFLAKE_PASSWORD`, `SNOWFLAKE_ROLE`, `SNOWFLAKE_WAREHOUSE`, `SNOWFLAKE_DATABASE`
- **Generated**: `SCAN_RESULTS`, `SCAN_CLOUD_LINK`, `SCAN_EXIT_CODE` (automatically set by Soda action)

## 🚀 Workflow Execution

### Automatic Triggers
- **Pull Requests**: Workflow runs automatically on PR creation/updates
- **Main Branch**: Workflow runs on pushes to main branch

### Manual Triggers
- Go to Actions tab in GitHub
- Select "Soda Data Quality Scans (raw → staging → mart → quality)" or "dbt Model Execution (staging → marts)"
- Click "Run workflow"

## 📊 Workflow Results

### Sequential Data Quality Pipeline
- ✅ **Raw Layer**: Data quality scans on source data
- ✅ **Staging Layer**: Data quality scans on transformed staging data
- ✅ **Mart Layer**: Data quality scans on business-ready mart data
- ✅ **Quality Layer**: Data quality scans on quality metrics and results
- ✅ **Soda Cloud**: All results sent to centralized monitoring dashboard
- ✅ **Artifacts**: JSON results and cloud links for each layer
- ✅ **PR Comments**: Automatic detailed reports in pull requests

### dbt Model Execution Pipeline
- ✅ **Setup**: Environment configuration and connection testing
- ✅ **Staging Models**: 4 models (customers, orders, products, order_items)
- ✅ **Mart Models**: 2 models (dim_customers, fact_orders)
- ✅ **Complete Pipeline**: Full execution with all dependencies
- ✅ **Testing**: Data quality tests run after each layer
- ✅ **Documentation**: Automatic dbt docs generation
- ✅ **Artifacts**: Logs, compiled SQL, and documentation for each layer
- ✅ **PR Comments**: Detailed execution reports in pull requests

## 🔍 Monitoring and Alerts

### Soda Cloud Integration
- **Centralized Monitoring**: All quality results in Soda Cloud
- **Automated Alerting**: Notifications for quality issues
- **Historical Trends**: Track quality over time
- **Team Collaboration**: Shared quality insights

### GitHub Actions Integration
- **PR Comments**: Quality results in pull requests
- **Status Checks**: Required for merging
- **Deployment Gates**: Quality gates for production
- **Team Notifications**: Automated team alerts

## 🛠️ Troubleshooting

### Common Issues

#### 1. **Snowflake Connection Issues**
- Verify credentials in GitHub secrets
- Check network access and permissions
- Validate warehouse and database settings
- Ensure data source configurations match your Snowflake setup

#### 2. **Soda Cloud Connection Issues**
- Verify API keys in GitHub secrets
- Check Soda Cloud account status
- Validate host configuration (should be `https://cloud.soda.io`)
- Ensure API keys have proper permissions

#### 3. **Workflow Execution Failures**
- **Exit Code 1**: Execution or configuration error - check logs for specific issues
- **Exit Code 0/2**: Quality checks executed successfully (even if some checks failed)
- Check Soda configuration files in `soda/configuration/` directory
- Verify check files in `soda/checks/` directory

#### 4. **Sequential Job Failures**
- If `raw` job fails, all subsequent jobs are skipped
- Check the specific layer that failed in the workflow logs
- Verify data exists in the corresponding Snowflake schema
- Check Soda check definitions for syntax errors

#### 5. **dbt Model Execution Issues**
- **Connection Issues**: Verify Snowflake credentials and permissions
- **Model Dependencies**: Check that staging models exist before running marts
- **SQL Syntax Errors**: Review model SQL for syntax issues
- **Test Failures**: Check data quality test definitions and thresholds
- **Schema Issues**: Ensure proper schema permissions and naming conventions

### Debug Commands
```bash
# Test Soda configuration locally
soda scan -d soda_certification_raw -c soda/configuration/configuration_raw.yml soda/checks/raw/*.yml

# Check Soda Cloud connection
soda scan -d soda_certification_raw -c soda/configuration/configuration_raw.yml --cloud

# Test individual layers
soda scan -d soda_certification_staging -c soda/configuration/configuration_staging.yml soda/checks/staging/*.yml
soda scan -d soda_certification_mart -c soda/configuration/configuration_mart.yml soda/checks/mart/*.yml
soda scan -d soda_certification_quality -c soda/configuration/configuration_quality.yml soda/checks/quality/*.yml

# Test dbt configuration locally
cd dbt
dbt debug
dbt deps

# Run dbt models locally
dbt run --models staging
dbt run --models marts
dbt test --models staging
dbt test --models marts

# Generate dbt documentation
dbt docs generate
dbt docs serve
```

## 📚 Best Practices

### 1. **Quality Gates**
- Workflow execution must complete successfully
- Data quality checks run on all layers sequentially
- Execution errors (not quality failures) block the pipeline

### 2. **Security**
- Use GitHub secrets for sensitive data
- Never commit credentials to repository
- Regular secret rotation recommended
- Validate Soda Cloud API key permissions

### 3. **Monitoring**
- Check Soda Cloud dashboard regularly for quality trends
- Monitor GitHub Actions status for execution issues
- Review PR comments for detailed quality reports
- Set up team notifications for critical failures

### 4. **Sequential Processing**
- Understand that each layer depends on the previous one
- Raw data must be available before staging scans
- Staging transformations must complete before mart scans
- Mart data must be ready before quality scans

### 5. **dbt Model Management**
- Keep model dependencies clear and documented
- Use proper materialization strategies (table vs view)
- Implement comprehensive data quality tests
- Maintain up-to-date model documentation
- Follow consistent naming conventions

### 6. **Documentation**
- Keep Soda check definitions updated
- Document data source configurations
- Maintain troubleshooting guides
- Update secrets when changed

## 🎯 Success Metrics

### Quality Metrics
- **Data Quality**: Monitor pass/warn/fail rates in Soda Cloud
- **Pipeline Success**: >98% workflow execution success rate
- **Sequential Processing**: All layers complete in order
- **Artifact Generation**: All scan results properly captured
- **dbt Model Success**: >95% model execution success rate
- **Test Coverage**: All models have comprehensive data quality tests

### Team Metrics
- **Faster Development**: Automated quality checks across all layers
- **Reduced Issues**: Early problem detection in data pipeline
- **Better Collaboration**: Shared quality insights via Soda Cloud
- **Transparency**: Clear PR comments with quality summaries

## ⚙️ Workflow Configuration Details

### Data Sources
The workflow uses four distinct data sources configured in Soda:
- `soda_certification_raw`: Raw data layer
- `soda_certification_staging`: Staging/transformed data layer  
- `soda_certification_mart`: Business-ready mart layer
- `soda_certification_quality`: Quality metrics and results layer

### Configuration Files
Each layer has its own configuration and checks:
- **Raw**: `soda/configuration/configuration_raw.yml` + `soda/checks/raw/*.yml`
- **Staging**: `soda/configuration/configuration_staging.yml` + `soda/checks/staging/*.yml`
- **Mart**: `soda/configuration/configuration_mart.yml` + `soda/checks/mart/*.yml`
- **Quality**: `soda/configuration/configuration_quality.yml` + `soda/checks/quality/*.yml`

### Concurrency Control
- **Sequential Execution**: Jobs run in strict order (raw → staging → mart → quality)
- **No Parallel Execution**: Each job waits for the previous one to complete
- **Fail-Fast**: If any job fails, subsequent jobs are skipped
- **Concurrency Group**: `soda-scan-seq-${{ github.workflow }}-${{ github.ref }}`
- **Cancel Policy**: `cancel-in-progress: false` (allows multiple runs to complete)

### Soda Library Version
- **Version**: v1.0.4 (consistent across all jobs)
- **Action**: `sodadata/soda-github-action@v1.0.2`

### dbt Configuration
- **dbt Version**: 1.7.0
- **dbt Package**: dbt-snowflake
- **Python Version**: 3.9
- **Threads**: 4 (optimized for Snowflake)
- **Query Tag**: dbt_github_actions

### Job Execution Steps
Each job follows the same pattern:
1. **Checkout**: `actions/checkout@v4`
2. **Soda Scan**: Run data quality checks with `continue-on-error: true`
3. **Persist Results**: Save scan results and cloud links to files
4. **Decide Outcome**: Smart exit code logic (fail only on execution errors)
5. **Upload Artifacts**: `actions/upload-artifact@v4` with scan results
6. **PR Comment**: Post results to pull request (if applicable)

### Smart Exit Code Logic
Each job includes a "Decide job outcome" step that:
- **Exit Code 0/2**: Quality checks executed successfully → Job passes
- **Exit Code 1**: Execution/config error → Job fails
- **Empty Code**: Treated as execution error → Job fails

---

**Ready for production data quality monitoring!** 🎉✨

For questions or issues, check the troubleshooting section or contact the team.
