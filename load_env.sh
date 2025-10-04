#!/bin/bash

# Soda Certification Project - Environment Variables Loader
# This script loads environment variables from the .env file in the project root
# It dynamically loads all variables found in the .env file without predefined requirements

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
EMPTY_VARS=()

# Load variables from .env file
while IFS= read -r line || [ -n "$line" ]; do
    # Skip empty lines and comments
    if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
        continue
    fi
    
    # Check if line contains an assignment
    if [[ "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then
        # Extract variable name and value
        VAR_NAME=$(echo "$line" | cut -d'=' -f1)
        VAR_VALUE=$(echo "$line" | cut -d'=' -f2-)
        
        # Check if variable has a value
        if [[ -z "$VAR_VALUE" || "$VAR_VALUE" =~ ^[[:space:]]*$ ]]; then
            EMPTY_VARS+=("$VAR_NAME")
        else
            # Export the variable
            export "$line"
            LOADED_COUNT=$((LOADED_COUNT + 1))
        fi
    fi
done < "$ENV_FILE"

echo -e "${GREEN}✅ Loaded $LOADED_COUNT environment variables${NC}"

# Check for empty variables
if [ ${#EMPTY_VARS[@]} -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Warning: Some variables in .env file are empty:${NC}"
    for var in "${EMPTY_VARS[@]}"; do
        echo -e "   ${YELLOW}• $var${NC}"
    done
    echo -e "${YELLOW}💡 Please update your .env file with actual values for these variables${NC}"
fi

# Display loaded variables (without sensitive values)
echo -e "${BLUE}📋 Environment Variables Summary:${NC}"
echo "----------------------------------------"

# List of variables that should be shown with their values (non-sensitive)
NON_SENSITIVE_VARS=(
    "SNOWFLAKE_WAREHOUSE"
    "SNOWFLAKE_DATABASE" 
    "SNOWFLAKE_SCHEMA"
    "SODA_CLOUD_HOST"
    "SODA_CLOUD_REGION"
    "DBT_PROFILES_DIR"
)

# List of variables that should be hidden (sensitive)
SENSITIVE_VARS=(
    "SNOWFLAKE_ACCOUNT"
    "SNOWFLAKE_USER"
    "SNOWFLAKE_PASSWORD"
    "SNOWFLAKE_ROLE"
    "SODA_CLOUD_API_KEY_ID"
    "SODA_CLOUD_API_KEY_SECRET"
    "SODA_AGENT_API_KEY_ID"
    "SODA_AGENT_API_KEY_SECRET"
)

# Show all loaded variables
for var in $(env | grep -E '^[A-Z_]+=' | cut -d'=' -f1 | sort); do
    var_value=$(eval echo \$$var)
    if [ ! -z "$var_value" ]; then
        if [[ " ${NON_SENSITIVE_VARS[*]} " =~ " ${var} " ]]; then
            echo -e "   ${GREEN}✓${NC} $var = $var_value"
        elif [[ " ${SENSITIVE_VARS[*]} " =~ " ${var} " ]]; then
            echo -e "   ${GREEN}✓${NC} $var = [HIDDEN]"
        else
            # For any other variables, show them but hide if they look sensitive
            if [[ "$var" =~ (PASSWORD|SECRET|KEY|TOKEN|CREDENTIAL) ]]; then
                echo -e "   ${GREEN}✓${NC} $var = [HIDDEN]"
            else
                echo -e "   ${GREEN}✓${NC} $var = $var_value"
            fi
        fi
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