#!/bin/bash

# Soda Certification Project - Environment Variables Loader
# This script loads environment variables from the .env file in the project root

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

# Path to the .env file
ENV_FILE="$PROJECT_ROOT/.env"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Soda Certification Project - Environment Loader${NC}"
echo "=================================================="

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}❌ Error: .env file not found at $ENV_FILE${NC}"
    echo -e "${YELLOW}💡 To fix this:${NC}"
    echo "   1. Copy .env.example to .env:"
    echo "      cp .env.example .env"
    echo "   2. Edit .env with your actual values"
    echo "   3. Run this script again"
    exit 1
fi

echo -e "${GREEN}✅ Found .env file at: $ENV_FILE${NC}"

# Load environment variables
echo -e "${BLUE}📥 Loading environment variables...${NC}"

# Counter for loaded variables
LOADED_COUNT=0
MISSING_VARS=()
MISSING_OPTIONAL_VARS=()

# Required variables to check
REQUIRED_VARS=(
    "SNOWFLAKE_ACCOUNT"
    "SNOWFLAKE_USER" 
    "SNOWFLAKE_PASSWORD"
    "SNOWFLAKE_WAREHOUSE"
    "SNOWFLAKE_DATABASE"
    "SNOWFLAKE_SCHEMA"
    "SODA_CLOUD_API_KEY_ID"
    "SODA_CLOUD_API_KEY_SECRET"
    "SODA_AGENT_API_KEY_ID"
    "SODA_AGENT_API_KEY_SECRET"
)

# Optional variables to check (will show warnings if missing but won't fail)
OPTIONAL_VARS=(
    "SNOWFLAKE_ROLE"
    "SODA_CLOUD_HOST"
    "SODA_CLOUD_REGION"
    "SODA_LOG_FORMAT"
    "SODA_LOG_LEVEL"
    "DBT_PROFILES_DIR"
    "AWS_ACCESS_KEY_ID"
    "AWS_SECRET_ACCESS_KEY"
    "AWS_DEFAULT_REGION"
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
        
        # Check if it's an optional variable and has a value
        if [[ " ${OPTIONAL_VARS[*]} " =~ " ${VAR_NAME} " ]]; then
            VAR_VALUE=$(echo "$line" | cut -d'=' -f2-)
            if [[ -z "$VAR_VALUE" || "$VAR_VALUE" =~ ^[[:space:]]*$ ]]; then
                MISSING_OPTIONAL_VARS+=("$VAR_NAME")
            fi
        fi
    fi
done < "$ENV_FILE"

echo -e "${GREEN}✅ Loaded $LOADED_COUNT environment variables${NC}"

# Check for missing required variables
if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Warning: Some required variables are empty or missing:${NC}"
    for var in "${MISSING_VARS[@]}"; do
        echo -e "   ${YELLOW}• $var${NC}"
    done
    echo -e "${YELLOW}💡 Please update your .env file with actual values${NC}"
fi

# Check for missing optional variables
if [ ${#MISSING_OPTIONAL_VARS[@]} -gt 0 ]; then
    echo -e "${BLUE}ℹ️  Info: Some optional variables are not set (this is OK):${NC}"
    for var in "${MISSING_OPTIONAL_VARS[@]}"; do
        echo -e "   ${BLUE}• $var${NC}"
    done
    echo -e "${BLUE}💡 These variables have defaults or are optional for certain features${NC}"
fi

# Display loaded variables (without sensitive values)
echo -e "${BLUE}📋 Environment Variables Summary:${NC}"
echo "----------------------------------------"

# Show non-sensitive variables (public configuration)
for var in SNOWFLAKE_WAREHOUSE SNOWFLAKE_DATABASE SNOWFLAKE_SCHEMA SODA_CLOUD_HOST SODA_CLOUD_REGION DBT_PROFILES_DIR AWS_DEFAULT_REGION; do
    var_value=$(eval echo \$$var)
    if [ ! -z "$var_value" ]; then
        echo -e "   ${GREEN}✓${NC} $var = $var_value"
    fi
done

# Show that sensitive variables are loaded (but not their values)
for var in SNOWFLAKE_ACCOUNT SNOWFLAKE_USER SNOWFLAKE_PASSWORD SNOWFLAKE_ROLE SODA_CLOUD_API_KEY_ID SODA_CLOUD_API_KEY_SECRET SODA_CLOUD_ORGANIZATION_ID SODA_AGENT_API_KEY_ID SODA_AGENT_API_KEY_SECRET AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY; do
    var_value=$(eval echo \$$var)
    if [ ! -z "$var_value" ]; then
        echo -e "   ${GREEN}✓${NC} $var = [HIDDEN]"
    fi
done

echo ""
echo -e "${GREEN}🎉 Environment variables loaded successfully!${NC}"
echo -e "${BLUE}💡 You can now run:${NC}"
echo "   • make airflow-up"
echo "   • make superset-up" 
echo "   • make superset-upload-data"
echo "   • make soda-agent-bootstrap ENV=dev"
echo "   • make soda-agent-deploy ENV=dev"
echo ""
echo -e "${YELLOW}Note: Environment variables are loaded in this shell session only.${NC}"
echo -e "${YELLOW}To make them permanent, add 'source load_env.sh' to your ~/.bashrc or ~/.zshrc${NC}"
