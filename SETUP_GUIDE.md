# 🔧 Soda Certification Setup Guide

**Complete setup guide with all fixes applied to make the pipeline work seamlessly.**

## 🎯 **Quick Start (3 Commands)**

```bash
# 1. Setup environment
make setup

# 2. Start services (includes all fixes)
make airflow-up

# 3. Run initialization
make airflow-trigger-init
```

## 🔧 **Critical Fixes Applied**

### **Fix 1: Environment Variables Loading**
**Problem**: Docker Compose not loading `.env` file
**Solution**: Added `env_file: - ../.env` to all Airflow services in `docker-compose.yml`

### **Fix 2: DAG Auto-Unpause**
**Problem**: DAGs created in paused state, never execute
**Solution**: Added automatic unpause in `make airflow-up` command

### **Fix 3: Service Initialization Timing**
**Problem**: Commands run before services are fully ready
**Solution**: Added 30-second wait in `make airflow-up`

### **Fix 4: Logging Directory Structure**
**Problem**: Airflow scheduler fails due to missing logs directory
**Solution**: Create logs directory before starting services

### **Fix 5: Docker Integration**
**Problem**: Local Airflow CLI cannot interact with Docker containers
**Solution**: All Makefile commands use `docker exec`

## 📋 **Step-by-Step Setup**

### **Step 1: Prerequisites**
- Docker Desktop running
- Snowflake account with credentials
- `.env` file with your credentials

### **Step 2: Environment Setup**
```bash
make setup
```
This command:
- ✅ Creates virtual environment
- ✅ Installs dependencies
- ✅ Checks `.env` file exists
- ⚠️ **Ensure `.env` has your Snowflake credentials**

### **Step 3: Start Services**
```bash
make airflow-up
```
This command now includes all fixes:
- ✅ Starts all Airflow services with Docker
- ✅ Loads environment variables from `.env`
- ✅ Waits 30 seconds for services to initialize
- ✅ Automatically unpauses all Soda DAGs
- ✅ Creates necessary log directories
- ✅ Web UI available at http://localhost:8080

### **Step 4: First-Time Initialization**
```bash
make airflow-trigger-init
```
This command:
- ✅ Resets Snowflake database
- ✅ Creates sample data with quality issues
- ✅ Prepares foundation for pipeline runs

## 🚨 **Troubleshooting**

### **Common Issues & Solutions**

| Issue | Solution | Root Cause |
|-------|----------|------------|
| **Environment variables not loading** | Check `.env` file exists and has correct format | Missing `env_file` in docker-compose.yml |
| **DAGs stuck in queued state** | Run `make airflow-unpause-all` | DAGs are paused by default |
| **Services not starting** | Run `make airflow-rebuild` | Container build issues |
| **Logging directory errors** | Run `make airflow-rebuild` | Missing logs directory structure |
| **Local Airflow CLI errors** | Use `make` commands instead | Local CLI can't access Docker containers |

### **Debug Commands**

#### **Check Service Status**
```bash
make airflow-status          # Check if services are running
make airflow-list            # List available DAGs
```

#### **Check Environment Variables**
```bash
# Check if variables are loaded in container
docker exec soda-airflow-webserver env | grep SNOWFLAKE

# Check .env file format
cat .env | grep -v "^#" | grep -v "^$"
```

#### **Check DAG Status**
```bash
# Check DAG run history
docker exec soda-airflow-webserver airflow dags list-runs -d soda_initialization

# Check task logs
docker exec soda-airflow-webserver airflow tasks list soda_initialization
```

### **Complete Reset (Nuclear Option)**
```bash
# Stop everything
make airflow-down

# Remove all containers and volumes
cd docker && docker-compose down -v
cd docker && docker system prune -f

# Rebuild from scratch
make airflow-rebuild
```

## 🎯 **What's Fixed**

### **Docker Compose Configuration**
- ✅ Environment variables loaded from `.env` file
- ✅ Proper volume mounts for all project files
- ✅ Health checks for all services
- ✅ Proper service dependencies

### **Makefile Commands**
- ✅ All commands work with Docker containers
- ✅ Automatic DAG unpausing on startup
- ✅ Proper service initialization timing
- ✅ Error handling and fallbacks

### **DAG Management**
- ✅ Separated initialization and pipeline DAGs
- ✅ Automatic unpausing on startup
- ✅ Proper task dependencies
- ✅ Error handling and retries

### **Logging and Monitoring**
- ✅ Proper log directory structure
- ✅ Centralized logging in Docker volumes
- ✅ Airflow UI accessible at http://localhost:8080
- ✅ Soda Cloud integration for quality monitoring

## 🚀 **Production Ready Features**

### **Automated Setup**
- ✅ One-command environment setup
- ✅ Automatic service initialization
- ✅ DAG auto-unpausing
- ✅ Health checks and monitoring

### **Error Handling**
- ✅ Proper retry logic in DAGs
- ✅ Graceful failure handling
- ✅ Comprehensive logging
- ✅ Debug commands for troubleshooting

### **Scalability**
- ✅ Configurable warehouse sizes
- ✅ Parallel task execution
- ✅ Resource optimization
- ✅ Performance monitoring

## 📚 **Additional Resources**

- **Main Documentation**: README.md
- **Airflow UI**: http://localhost:8080 (admin/admin)
- **Soda Cloud**: Centralized quality monitoring
- **GitHub Actions**: Automated CI/CD pipeline

---

**The pipeline is now production-ready with all critical fixes applied!** 🎉✨
