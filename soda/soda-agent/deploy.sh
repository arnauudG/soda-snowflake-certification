#!/bin/bash

# Soda Infrastructure Deployment Script
# This script deploys all infrastructure for an environment
# Usage: ./deploy.sh <environment>

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

# Check if environment is provided
if [ $# -eq 0 ]; then
    print_error "Usage: $0 <environment>"
    print_error "Environment: dev, prod"
    print_error "Example: $0 dev"
    exit 1
fi

ENVIRONMENT=$1

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|prod)$ ]]; then
    print_error "Invalid environment: $ENVIRONMENT"
    print_error "Valid environments: dev, prod"
    exit 1
fi

print_status "Deploying to environment: $ENVIRONMENT"

# Set base directory
BASE_DIR="env/$ENVIRONMENT/eu-west-1"
cd "$BASE_DIR" || {
    print_error "Environment directory not found: $BASE_DIR"
    exit 1
}

print_status "Working directory: $(pwd)"

# Get AWS account ID and region
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION="eu-west-1"

# Define resource names
BUCKET_NAME="datashift-$ENVIRONMENT-tfstate-$AWS_ACCOUNT_ID-$AWS_REGION"
TABLE_NAME="datashift-$ENVIRONMENT-tf-locks"

# Function to check if bootstrap resources exist
check_bootstrap_exists() {
    local bucket_exists=false
    local table_exists=false
    
    # Check S3 bucket
    if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
        bucket_exists=true
    fi
    
    # Check DynamoDB table
    if aws dynamodb describe-table --table-name "$TABLE_NAME" --region "$AWS_REGION" 2>/dev/null; then
        table_exists=true
    fi
    
    if [[ "$bucket_exists" == true && "$table_exists" == true ]]; then
        return 0  # Bootstrap exists
    else
        return 1  # Bootstrap does not exist
    fi
}

# Function to handle state locks
handle_state_lock() {
    local module_path=$1
    local module_name=$2
    
    print_warning "State lock detected for $module_name. Attempting to force unlock..."
    if timeout 60 terragrunt force-unlock -force "$(terragrunt show-lock-id 2>/dev/null || echo 'unknown')" 2>/dev/null; then
        print_success "State lock released for $module_name"
        return 0
    else
        print_error "Failed to release state lock for $module_name"
        print_error "You may need to manually release the lock or wait for it to expire"
        return 1
    fi
}

# Function to deploy a module
deploy_module() {
    local module_path=$1
    local module_name=$2
    
    print_status "Deploying $module_name..."
    cd "$module_path" || {
        print_error "Module directory not found: $module_path"
        exit 1
    }
    
    # Run terragrunt apply with full output
    if terragrunt apply --auto-approve; then
        print_success "$module_name deployed successfully"
    else
        local exit_code=$?
        # Check if it's a state lock error
        if terragrunt apply --auto-approve 2>&1 | grep -q "Error acquiring the state lock"; then
            print_warning "State lock detected. Attempting to resolve..."
            if handle_state_lock "$module_path" "$module_name"; then
                print_status "Retrying deployment after lock release..."
                if terragrunt apply --auto-approve; then
                    print_success "$module_name deployed successfully"
                else
                    print_error "Failed to deploy $module_name after lock release"
                    exit 1
                fi
            else
                print_error "Failed to resolve state lock for $module_name"
                exit 1
            fi
        else
            print_error "Failed to deploy $module_name (exit code: $exit_code)"
            exit 1
        fi
    fi
    
    cd - > /dev/null
}

# Handle interruptions gracefully
trap 'print_error "Deployment interrupted. Exiting..."; exit 130' INT TERM

# Check if bootstrap exists
print_status "Checking bootstrap status..."
if check_bootstrap_exists; then
    print_success "Bootstrap exists for environment: $ENVIRONMENT"
    print_status "Proceeding with deployment..."
else
    print_warning "Bootstrap does not exist for environment: $ENVIRONMENT"
    print_status "Creating bootstrap first..."
    
    # Navigate to soda-agent directory to run bootstrap script
    cd ../../.. || {
        print_error "Failed to navigate to soda-agent directory"
        exit 1
    }
    
    ./bootstrap.sh "$ENVIRONMENT" create
    
    # Return to deployment directory
    cd "$BASE_DIR" || {
        print_error "Failed to return to deployment directory"
        exit 1
    }
    
    print_success "Bootstrap created successfully!"
fi

# Deploy all infrastructure using terragrunt run-all
print_status "Deploying all infrastructure..."
if terragrunt run-all apply --auto-approve; then
    print_success "All infrastructure deployed successfully!"
else
    exit_code=$?
    print_error "Failed to deploy infrastructure (exit code: $exit_code)"
    exit 1
fi

print_success "Deployment completed successfully!"
print_status "Environment: $ENVIRONMENT"
print_status "Current directory: $(pwd)"