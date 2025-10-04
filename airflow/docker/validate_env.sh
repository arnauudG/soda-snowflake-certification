#!/bin/bash

# Airflow Environment Validation Script
# This script validates environment variables before starting Airflow services

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Airflow Environment Validation${NC}"
echo "=================================="

# Check if .env file exists
if [ ! -f "/opt/airflow/.env" ]; then
    echo -e "${RED}❌ Error: .env file not found in /opt/airflow/.env${NC}"
    echo -e "${YELLOW}💡 Make sure the .env file is mounted in the container${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Found .env file${NC}"

# Load environment variables from .env file
echo -e "${BLUE}📥 Loading environment variables...${NC}"

# Counter for loaded variables
LOADED_COUNT=0
MISSING_VARS=()

# Required variables for Airflow
REQUIRED_VARS=(
    "SNOWFLAKE_ACCOUNT"
    "SNOWFLAKE_USER" 
    "SNOWFLAKE_PASSWORD"
    "SNOWFLAKE_WAREHOUSE"
    "SNOWFLAKE_DATABASE"
    "SNOWFLAKE_SCHEMA"
    "SODA_CLOUD_API_KEY_ID"
    "SODA_CLOUD_API_KEY_SECRET"
)

# Load variables from .env file
while IFS= read -r line || [ -n "$line" ]; do
    # Skip empty lines and comments
    if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
        continue
    fi
    
    # Check if line contains an assignment
    if [[ "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then
        # Export the variable
        export "$line"
        LOADED_COUNT=$((LOADED_COUNT + 1))
        
        # Extract variable name for checking
        VAR_NAME=$(echo "$line" | cut -d'=' -f1)
        
        # Check if it's a required variable and has a value
        if [[ " ${REQUIRED_VARS[*]} " =~ " ${VAR_NAME} " ]]; then
            VAR_VALUE=$(echo "$line" | cut -d'=' -f2-)
            if [[ -z "$VAR_VALUE" || "$VAR_VALUE" =~ ^[[:space:]]*$ ]]; then
                MISSING_VARS+=("$VAR_NAME")
            fi
        fi
    fi
done < "/opt/airflow/.env"

echo -e "${GREEN}✅ Loaded $LOADED_COUNT environment variables${NC}"

# Check for missing required variables
if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    echo -e "${RED}❌ Error: Required variables are missing or empty:${NC}"
    for var in "${MISSING_VARS[@]}"; do
        echo -e "   ${RED}• $var${NC}"
    done
    echo -e "${YELLOW}💡 Please update your .env file with actual values${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All required environment variables are set${NC}"

# Display non-sensitive variables
echo -e "${BLUE}📋 Environment Summary:${NC}"
echo "------------------------"
for var in SNOWFLAKE_WAREHOUSE SNOWFLAKE_DATABASE SNOWFLAKE_SCHEMA SODA_CLOUD_HOST; do
    var_value=$(eval echo \$$var)
    if [ ! -z "$var_value" ]; then
        echo -e "   ${GREEN}✓${NC} $var = $var_value"
    fi
done

echo -e "${GREEN}🎉 Environment validation successful!${NC}"
echo -e "${BLUE}💡 Airflow services can now start safely${NC}"
