# 🚀 GitHub Actions CI/CD for Soda Certification

This directory contains GitHub Actions workflows for automated testing, data quality checks, and deployment of the Soda Certification project.

## 📋 Available Workflows

### 1. **soda-data-quality.yml** - Data Quality CI/CD
- **Trigger**: Pull requests and pushes to main/develop branches
- **Purpose**: Automated data quality testing with Soda
- **Jobs**:
  - `dbt-setup`: Setup environment and run dbt models
  - `soda-quality-checks`: Run Soda scans on all layers (RAW, STAGING, MART, QUALITY)
  - `soda-comprehensive-scan`: Comprehensive data quality validation
  - `quality-report`: Generate quality report

### 2. **airflow-dag-test.yml** - Airflow DAG Testing
- **Trigger**: Pull requests and pushes to main/develop branches
- **Purpose**: Test Airflow DAGs and Docker configuration
- **Jobs**:
  - `dag-syntax-test`: Validate DAG syntax
  - `docker-build-test`: Test Docker build and configuration
  - `airflow-dag-test`: Test DAG loading in Airflow
  - `test-report`: Generate test report

### 3. **complete-pipeline-test.yml** - Complete Pipeline Testing
- **Trigger**: Pull requests and pushes to main/develop branches
- **Purpose**: End-to-end pipeline testing
- **Jobs**:
  - `environment-setup`: Setup complete environment
  - `complete-pipeline-test`: Test Snowflake, dbt, and Soda integration
  - `airflow-integration-test`: Test Airflow integration
  - `comprehensive-report`: Generate comprehensive report

### 4. **docker-test.yml** - Docker Testing
- **Trigger**: Changes to Docker files
- **Purpose**: Test Docker build and Compose configuration
- **Jobs**:
  - `docker-build-test`: Test Docker build
  - `docker-compose-test`: Test Docker Compose services
  - `airflow-services-test`: Test Airflow services
  - `docker-test-report`: Generate Docker test report

### 5. **test-docker.yml** - Simple Docker Test
- **Trigger**: Manual trigger or changes to Docker files
- **Purpose**: Simple Docker setup verification
- **Features**:
  - Docker version check
  - Docker Compose compatibility test
  - Service startup test
  - Configuration validation

### 6. **deploy.yml** - Production Deployment
- **Trigger**: Pushes to main branch
- **Purpose**: Deploy to production environment
- **Jobs**:
  - `pre-deployment-checks`: Validate before deployment
  - `deploy-production`: Deploy to production
  - `post-deployment-verification`: Verify deployment
  - `deployment-report`: Generate deployment report

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
SNOWFLAKE_SCHEMA=RAW
```

### Soda Cloud Configuration
```
SODA_CLOUD_API_KEY_ID=your_api_key_id
SODA_CLOUD_API_KEY_SECRET=your_api_key_secret
SODA_CLOUD_HOST=cloud.soda.io
```

## 🚀 Workflow Execution

### Automatic Triggers
- **Pull Requests**: All workflows run automatically on PR creation/updates
- **Main Branch**: All workflows run on pushes to main branch
- **Develop Branch**: All workflows run on pushes to develop branch

### Manual Triggers
- Go to Actions tab in GitHub
- Select the workflow you want to run
- Click "Run workflow"

## 📊 Workflow Results

### Data Quality Workflow
- ✅ **dbt Setup**: Environment and models executed
- ✅ **Soda Scans**: Data quality checks on all layers
- ✅ **Quality Report**: Comprehensive quality assessment
- ✅ **Soda Cloud**: Results sent to centralized monitoring

### Airflow DAG Workflow
- ✅ **DAG Syntax**: All DAGs validated
- ✅ **Docker Build**: Container configuration tested
- ✅ **Airflow Integration**: DAGs loaded successfully
- ✅ **Test Report**: Complete test results

### Complete Pipeline Workflow
- ✅ **Environment**: Complete setup validated
- ✅ **Snowflake**: Database and data setup
- ✅ **dbt Models**: All transformations executed
- ✅ **Soda Quality**: Data quality checks completed
- ✅ **Airflow**: DAGs and integration tested

### Deployment Workflow
- ✅ **Pre-deployment**: All checks passed
- ✅ **Production**: Successful deployment
- ✅ **Verification**: Post-deployment validation
- ✅ **Monitoring**: Active quality monitoring

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

#### 2. **Soda Cloud Connection Issues**
- Verify API keys in GitHub secrets
- Check Soda Cloud account status
- Validate host configuration

#### 3. **DAG Syntax Errors**
- Check Python syntax in DAG files
- Validate Airflow imports and dependencies
- Test DAG loading locally

#### 4. **Docker Build Issues**
- Check Dockerfile syntax
- Validate docker-compose configuration
- Test Docker build locally
- **Docker Compose Issue**: GitHub Actions uses `docker compose` (newer) instead of `docker-compose` (legacy)
- **Solution**: Workflows now handle both `docker-compose` and `docker compose` automatically

### Debug Commands
```bash
# Test locally
make setup
make airflow-up
make airflow-trigger

# Check DAG syntax
python -c "exec(open('airflow/dags/soda_certification_dag.py').read())"

# Test Docker
cd docker && docker build -t test .
```

## 📚 Best Practices

### 1. **Quality Gates**
- All workflows must pass before merging
- Data quality checks are mandatory
- DAG syntax validation required

### 2. **Security**
- Use GitHub secrets for sensitive data
- Never commit credentials to repository
- Regular secret rotation recommended

### 3. **Monitoring**
- Check Soda Cloud dashboard regularly
- Monitor GitHub Actions status
- Set up team notifications

### 4. **Documentation**
- Keep workflows documented
- Update secrets when changed
- Maintain troubleshooting guides

## 🎯 Success Metrics

### Quality Metrics
- **Data Quality**: >95% check pass rate
- **Pipeline Success**: >98% workflow success rate
- **Deployment**: Zero failed deployments

### Team Metrics
- **Faster Development**: Automated quality checks
- **Reduced Issues**: Early problem detection
- **Better Collaboration**: Shared quality insights

---

**Ready for production CI/CD!** 🎉✨

For questions or issues, check the troubleshooting section or contact the team.
