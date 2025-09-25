#!/bin/bash
# Environment Variables Loader for Soda Certification Project
# This script loads environment variables from .env file and exports them

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to load environment variables
load_environment() {
    local env_file="$1"
    
    if [ ! -f "$env_file" ]; then
        print_error "Environment file not found: $env_file"
        print_error "Please create a .env file with your Snowflake credentials"
        return 1
    fi
    
    print_status "Loading environment variables from: $env_file"
    
    # Load environment variables, ignoring comments and empty lines
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip comments and empty lines
        if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "${line// }" ]]; then
            continue
        fi
        
        # Export the variable
        if [[ "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then
            export "$line"
        else
            print_warning "Skipping invalid line: $line"
        fi
    done < "$env_file"
    
    print_success "Environment variables loaded successfully"
    return 0
}

# Function to validate required environment variables
validate_environment() {
    local required_vars=(
        "SNOWFLAKE_ACCOUNT"
        "SNOWFLAKE_USER" 
        "SNOWFLAKE_PASSWORD"
    )
    
    local optional_vars=(
        "SNOWFLAKE_ROLE"
        "SNOWFLAKE_WAREHOUSE"
        "SNOWFLAKE_DATABASE"
        "SODA_CLOUD_API_KEY_ID"
        "SODA_CLOUD_API_KEY_SECRET"
        "SODA_CLOUD_HOST"
    )
    
    local missing_vars=()
    
    print_status "Validating required environment variables..."
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
        else
            print_success "$var is set"
        fi
    done
    
    # Check optional variables
    print_status "Checking optional environment variables..."
    for var in "${optional_vars[@]}"; do
        if [ -n "${!var}" ]; then
            print_success "$var is set"
        else
            print_warning "$var is not set (optional)"
        fi
    done
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        print_error "Missing required environment variables:"
        for var in "${missing_vars[@]}"; do
            print_error "  - $var"
        done
        return 1
    fi
    
    print_success "All required environment variables are set"
    return 0
}

# Function to display environment summary
show_environment_summary() {
    print_status "Environment Summary:"
    echo "  SNOWFLAKE_ACCOUNT: ${SNOWFLAKE_ACCOUNT:-'NOT SET'}"
    echo "  SNOWFLAKE_USER: ${SNOWFLAKE_USER:-'NOT SET'}"
    echo "  SNOWFLAKE_PASSWORD: ${SNOWFLAKE_PASSWORD:+[SET]}"
    echo "  SNOWFLAKE_WAREHOUSE: ${SNOWFLAKE_WAREHOUSE:-'SODA_WH'}"
    echo "  SNOWFLAKE_DATABASE: ${SNOWFLAKE_DATABASE:-'SODA_CERTIFICATION'}"
    echo "  SNOWFLAKE_ROLE: ${SNOWFLAKE_ROLE:-'ACCOUNTADMIN'}"
    echo "  SODA_CLOUD_API_KEY_ID: ${SODA_CLOUD_API_KEY_ID:-'NOT SET'}"
    echo "  SODA_CLOUD_API_KEY_SECRET: ${SODA_CLOUD_API_KEY_SECRET:+[SET]}"
    echo "  SODA_CLOUD_HOST: ${SODA_CLOUD_HOST:-'NOT SET'}"
}

# Main function
main() {
    local env_file="${1:-.env}"
    local project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    
    print_status "Soda Certification Environment Loader"
    print_status "Project root: $project_root"
    
    # Change to project root
    cd "$project_root"
    
    # Load environment variables
    if ! load_environment "$env_file"; then
        exit 1
    fi
    
    # Validate environment
    if ! validate_environment; then
        exit 1
    fi
    
    # Show summary
    show_environment_summary
    
    print_success "Environment setup complete!"
    print_status "Environment variables are now available for all subsequent commands"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
