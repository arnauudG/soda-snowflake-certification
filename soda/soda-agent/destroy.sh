#!/bin/bash

# Soda Infrastructure Destruction Script
# This script destroys all infrastructure for an environment
# Usage: ./destroy.sh <environment> [--destroy-bootstrap]

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
    print_error "Usage: $0 <environment> [--destroy-bootstrap]"
    print_error "Environment: dev, prod"
    print_error "Options:"
    print_error "  --destroy-bootstrap  - Also destroy bootstrap resources (S3 bucket, DynamoDB table)"
    print_error "Example: $0 dev"
    print_error "Example: $0 dev --destroy-bootstrap"
    exit 1
fi

ENVIRONMENT=$1
DESTROY_BOOTSTRAP=false

# Parse additional arguments
shift 1
while [[ $# -gt 0 ]]; do
    case $1 in
        --destroy-bootstrap)
            DESTROY_BOOTSTRAP=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|prod)$ ]]; then
    print_error "Invalid environment: $ENVIRONMENT"
    print_error "Valid environments: dev, prod"
    exit 1
fi

print_status "Destroying environment: $ENVIRONMENT"

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

# Handle interruptions gracefully
trap 'print_error "Destruction interrupted. Exiting..."; exit 130' INT TERM

# Main destruction logic
print_warning "This will destroy ALL infrastructure in the $ENVIRONMENT environment!"
read -p "Are you sure you want to continue? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    print_status "Destruction cancelled"
    exit 0
fi

print_status "Destroying all infrastructure using Terragrunt destroy --all..."

# Use terragrunt destroy --all to handle dependencies automatically
# This is the newer recommended approach instead of run-all destroy
if terragrunt destroy --all --auto-approve; then
    print_success "All infrastructure destroyed successfully!"
else
    print_error "Failed to destroy infrastructure"
    exit 1
fi

# Handle bootstrap destruction if requested
if [ "$DESTROY_BOOTSTRAP" = true ]; then
    print_status "Checking bootstrap status..."
    
    if check_bootstrap_exists; then
        print_warning "Bootstrap exists and will be destroyed!"
        print_warning "This will destroy:"
        print_warning "  - S3 bucket: $BUCKET_NAME"
        print_warning "  - DynamoDB table: $TABLE_NAME"
        print_warning "  - All associated IAM policies and configurations"
        print_warning "This action is IRREVERSIBLE!"
        read -p "Are you absolutely sure you want to destroy the bootstrap? Type 'DESTROY_BOOTSTRAP' to confirm: " -r

        if [[ $REPLY =~ ^DESTROY_BOOTSTRAP$ ]]; then
            print_status "Destroying bootstrap..."
            
            # Navigate to soda-agent directory to run bootstrap script
            cd ../../.. || {
                print_error "Failed to navigate to soda-agent directory"
                exit 1
            }
            
            ./bootstrap.sh "$ENVIRONMENT" delete
            
            # Return to deployment directory
            cd "$BASE_DIR" || {
                print_error "Failed to return to deployment directory"
                exit 1
            }
            
            print_success "Bootstrap destroyed successfully!"
        else
            print_status "Bootstrap destruction cancelled"
        fi
    else
        print_warning "Bootstrap does not exist for this environment!"
        print_status "Nothing to destroy."
    fi
else
    print_status "Bootstrap destruction not requested. Use --destroy-bootstrap flag to also destroy bootstrap resources."
fi

print_success "Destruction completed successfully!"
print_status "Environment: $ENVIRONMENT"
print_status "Current directory: $(pwd)"