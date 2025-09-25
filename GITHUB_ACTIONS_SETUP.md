# 🚀 GitHub Actions CI/CD Setup Guide

This guide will help you set up automated CI/CD workflows for your Soda Certification project using GitHub Actions.

## 📋 Prerequisites

### 1. GitHub Repository
- Create a new GitHub repository or use an existing one
- Ensure you have admin access to configure secrets

### 2. Soda Cloud Account
- Sign up at [cloud.soda.io](https://cloud.soda.io/signup) (free 45-day trial)
- Navigate to your avatar > Profile > API keys
- Generate new API keys and copy them

### 3. Snowflake Account
- Ensure you have a Snowflake account with appropriate permissions
- Note down your connection details

## 🔧 Setup Steps

### Step 1: Configure GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions → New repository secret

Add these secrets:

#### Snowflake Configuration
```
SNOWFLAKE_ACCOUNT=your_account_identifier
SNOWFLAKE_USER=your_username
SNOWFLAKE_PASSWORD=your_password_or_pat
SNOWFLAKE_ROLE=ACCOUNTADMIN
SNOWFLAKE_WAREHOUSE=SODA_WH
SNOWFLAKE_DATABASE=SODA_CERTIFICATION
SNOWFLAKE_SCHEMA=RAW
```

#### Soda Cloud Configuration
```
SODA_CLOUD_API_KEY_ID=your_api_key_id
SODA_CLOUD_API_KEY_SECRET=your_api_key_secret
SODA_CLOUD_HOST=cloud.soda.io
```

### Step 2: Upload Project Files

Upload your project files to the GitHub repository:

```bash
# Initialize git repository
git init
git add .
git commit -m "Initial commit: Soda Certification project with CI/CD"

# Add remote repository
git remote add origin https://github.com/yourusername/your-repo-name.git
git push -u origin main
```

### Step 3: Verify Workflows

1. Go to your GitHub repository
2. Click on the "Actions" tab
3. You should see 4 workflows:
   - **Soda Data Quality CI/CD**
   - **Airflow DAG Testing**
   - **Complete Pipeline Test**
   - **Deploy to Production**

### Step 4: Test Workflows

#### Test Data Quality Workflow
1. Create a new branch: `git checkout -b test-ci-cd`
2. Make a small change to any file
3. Commit and push: `git commit -m "Test CI/CD" && git push origin test-ci-cd`
4. Create a pull request
5. Check the Actions tab to see the workflow running

#### Test Airflow DAG Workflow
1. Make a change to any file in the `airflow/` directory
2. Commit and push
3. Check the Actions tab for the Airflow DAG workflow

#### Test Complete Pipeline Workflow
1. Make a change to any file in the `dbt/` or `soda/` directory
2. Commit and push
3. Check the Actions tab for the complete pipeline workflow

## 🚀 Workflow Features

### 1. **Data Quality CI/CD** (`soda-data-quality.yml`)
- **Triggers**: Pull requests and pushes to main/develop
- **Features**:
  - Automated dbt model execution
  - Soda data quality scans on all layers
  - Quality reports in pull requests
  - Results sent to Soda Cloud

### 2. **Airflow DAG Testing** (`airflow-dag-test.yml`)
- **Triggers**: Changes to Airflow or Docker files
- **Features**:
  - DAG syntax validation
  - Docker build testing
  - Airflow integration testing
  - Test reports

### 3. **Complete Pipeline Testing** (`complete-pipeline-test.yml`)
- **Triggers**: Any changes to the project
- **Features**:
  - End-to-end pipeline testing
  - Snowflake setup validation
  - dbt and Soda integration testing
  - Comprehensive reports

### 4. **Production Deployment** (`deploy.yml`)
- **Triggers**: Pushes to main branch
- **Features**:
  - Pre-deployment validation
  - Production deployment
  - Post-deployment verification
  - Deployment reports

## 📊 Monitoring and Results

### GitHub Actions Dashboard
- Go to your repository → Actions tab
- View workflow runs and results
- Check logs for any issues
- Monitor build status

### Soda Cloud Dashboard
- Log in to [cloud.soda.io](https://cloud.soda.io)
- View data quality results
- Set up alerts and notifications
- Monitor quality trends

### Pull Request Integration
- Quality results appear in PR comments
- Status checks prevent merging if quality fails
- Team notifications for quality issues
- Historical quality tracking

## 🔍 Troubleshooting

### Common Issues

#### 1. **Workflow Not Triggering**
- Check file paths in workflow triggers
- Ensure files are in the correct directories
- Verify branch names match workflow configuration

#### 2. **Secrets Not Found**
- Verify secrets are configured in repository settings
- Check secret names match workflow configuration
- Ensure secrets are not empty

#### 3. **Snowflake Connection Issues**
- Verify Snowflake credentials
- Check network access and permissions
- Validate warehouse and database settings

#### 4. **Soda Cloud Connection Issues**
- Verify API keys are correct
- Check Soda Cloud account status
- Validate host configuration

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

## 🎯 Best Practices

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

## 📈 Success Metrics

### Quality Metrics
- **Data Quality**: >95% check pass rate
- **Pipeline Success**: >98% workflow success rate
- **Deployment**: Zero failed deployments

### Team Metrics
- **Faster Development**: Automated quality checks
- **Reduced Issues**: Early problem detection
- **Better Collaboration**: Shared quality insights

## 🎉 Next Steps

1. **Set up alerts**: Configure Soda Cloud notifications
2. **Team training**: Share workflows with your team
3. **Customize checks**: Add your own data quality checks
4. **Scale up**: Add more data sources and checks
5. **Monitor**: Regular review of quality metrics

---

**Your CI/CD setup is complete!** 🎉✨

For questions or issues, check the troubleshooting section or contact the team.
