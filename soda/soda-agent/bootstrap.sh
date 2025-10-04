#!/bin/bash

# Soda Infrastructure Bootstrap Script
# This script can bootstrap or destroy infrastructure for an environment
# Usage: ./bootstrap.sh <environment> [create|destroy]

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
    print_error "Usage: $0 <environment> [create|delete|status|unlock]"
    print_error "Environment: dev, prod"
    print_error "Actions:"
    print_error "  create  - Create bootstrap infrastructure"
    print_error "  delete  - Delete bootstrap infrastructure"
    print_error "  status  - Check bootstrap status"
    print_error "  unlock  - Force unlock bootstrap state"
    print_error "Example: $0 dev create"
    print_error "Example: $0 dev delete"
    print_error "Example: $0 dev status"
    print_error "Example: $0 dev unlock"
    exit 1
fi

ENVIRONMENT=$1
ACTION=${2:-create}  # Default to create if not specified

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|prod)$ ]]; then
    print_error "Invalid environment: $ENVIRONMENT"
    print_error "Valid environments: dev, prod"
    exit 1
fi

# Validate action
if [[ "$ACTION" != "create" && "$ACTION" != "delete" && "$ACTION" != "status" && "$ACTION" != "unlock" ]]; then
    print_error "Invalid action: $ACTION"
    print_error "Valid actions: create, delete, status, unlock"
    exit 1
fi

print_status "Bootstrap $ACTION for environment: $ENVIRONMENT"

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

# Function to create bootstrap
create_bootstrap() {
    print_status "Creating bootstrap for environment: $ENVIRONMENT"
    
    # Check if bootstrap already exists
    if check_bootstrap_exists; then
        print_warning "Bootstrap already exists for this environment!"
        print_warning "S3 bucket: $BUCKET_NAME"
        print_warning "DynamoDB table: $TABLE_NAME"
        read -p "Do you want to recreate it? (yes/no): " -r
        if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
            print_status "Bootstrap creation cancelled"
            return 0
        fi
    fi
    
    # Check current bootstrap skip status
    if grep -q "skip = false" bootstrap/terragrunt.hcl; then
        print_warning "Bootstrap is already enabled for this environment!"
        print_warning "Current status: skip = false (bootstrap enabled)"
        read -p "Do you want to recreate the bootstrap? (yes/no): " -r
        if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
            print_status "Bootstrap creation cancelled"
            return 0
        fi
    else
        print_status "Bootstrap is currently disabled (skip = true)"
        print_status "Enabling bootstrap for creation..."
    fi
    
    # Final confirmation
    print_warning "You are about to create bootstrap for the $ENVIRONMENT environment!"
    print_warning "This will create:"
    print_warning "  - S3 bucket: $BUCKET_NAME"
    print_warning "  - DynamoDB table: $TABLE_NAME"
    print_warning "  - All necessary IAM policies and configurations"
    read -p "Are you absolutely sure? Type 'CREATE' to confirm: " -r

    if [[ ! $REPLY =~ ^CREATE$ ]]; then
        print_status "Bootstrap creation cancelled"
        return 0
    fi

    # Enable bootstrap
    print_status "Enabling bootstrap..."
    cd bootstrap || {
        print_error "Bootstrap directory not found"
        exit 1
    }

    # Check current skip status and enable bootstrap
    if grep -q "skip = true" terragrunt.hcl; then
        print_status "Bootstrap is currently disabled, enabling for creation..."
        sed -i.bak 's/skip = true/skip = false/' terragrunt.hcl
    elif grep -q "skip = false" terragrunt.hcl; then
        print_status "Bootstrap is already enabled for creation..."
    else
        print_error "Unable to determine bootstrap skip status in terragrunt.hcl"
        print_error "Expected to find 'skip = true' or 'skip = false'"
        exit 1
    fi

    # Run bootstrap
    print_status "Running bootstrap..."
    if timeout 1800 terragrunt apply --auto-approve; then
        print_success "Bootstrap apply completed successfully"
    else
        local exit_code=$?
        if [ $exit_code -eq 124 ]; then
            print_error "Bootstrap apply timed out after 30 minutes"
        else
            print_error "Bootstrap apply failed (exit code: $exit_code)"
        fi
        exit 1
    fi

    # Disable bootstrap again
    print_status "Disabling bootstrap..."
    sed -i.bak 's/skip = false/skip = true/' terragrunt.hcl

    # Clean up backup files
    rm -f terragrunt.hcl.bak

    print_success "Bootstrap created successfully!"
    print_success "Environment: $ENVIRONMENT"
    print_success "S3 bucket: $BUCKET_NAME"
    print_success "DynamoDB table: $TABLE_NAME"
    print_status "Bootstrap is now disabled. You can proceed with normal deployment."
}

# Function to clean up S3 bucket with versioning
cleanup_s3_bucket() {
    local bucket_name=$1
    print_status "Cleaning up S3 bucket with versioning: $bucket_name"
    
    # Check if bucket exists
    if ! aws s3api head-bucket --bucket "$bucket_name" 2>/dev/null; then
        print_status "S3 bucket does not exist, skipping cleanup"
        return 0
    fi
    
    # Delete all object versions
    print_status "Deleting all object versions..."
    local versions_output
    versions_output=$(aws s3api list-object-versions --bucket "$bucket_name" --query 'Versions[*].[Key,VersionId]' --output text 2>/dev/null)
    
    if [[ -n "$versions_output" && "$versions_output" != "None" ]]; then
        aws s3api delete-objects --bucket "$bucket_name" --delete "$(aws s3api list-object-versions --bucket "$bucket_name" --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}')" >/dev/null 2>&1
        print_status "Deleted object versions"
    fi
    
    # Delete all delete markers
    print_status "Deleting all delete markers..."
    local delete_markers_output
    delete_markers_output=$(aws s3api list-object-versions --bucket "$bucket_name" --query 'DeleteMarkers[*].[Key,VersionId]' --output text 2>/dev/null)
    
    if [[ -n "$delete_markers_output" && "$delete_markers_output" != "None" ]]; then
        aws s3api delete-objects --bucket "$bucket_name" --delete "$(aws s3api list-object-versions --bucket "$bucket_name" --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}')" >/dev/null 2>&1
        print_status "Deleted delete markers"
    fi
    
    # Now delete the bucket
    print_status "Deleting S3 bucket..."
    if aws s3api delete-bucket --bucket "$bucket_name" 2>/dev/null; then
        print_success "S3 bucket deleted successfully"
    else
        print_warning "Failed to delete S3 bucket, may need manual cleanup"
    fi
}

# Function to delete bootstrap
delete_bootstrap() {
    print_status "Deleting bootstrap for environment: $ENVIRONMENT"
    
    # Check if bootstrap exists
    if ! check_bootstrap_exists; then
        print_warning "Bootstrap does not exist for this environment!"
        print_status "Nothing to destroy."
        return 0
    fi
    
    print_warning "You are about to delete bootstrap for the $ENVIRONMENT environment!"
    print_warning "This will delete:"
    print_warning "  - S3 bucket: $BUCKET_NAME"
    print_warning "  - DynamoDB table: $TABLE_NAME"
    print_warning "  - All associated IAM policies and configurations"
    print_warning "This action is IRREVERSIBLE!"
    read -p "Are you absolutely sure? Type 'DELETE' to confirm: " -r

    if [[ ! $REPLY =~ ^DELETE$ ]]; then
        print_status "Bootstrap deletion cancelled"
        return 0
    fi

    # Enable bootstrap for deletion
    print_status "Enabling bootstrap for deletion..."
    cd bootstrap || {
        print_error "Bootstrap directory not found"
        exit 1
    }

    # Check current skip status and enable bootstrap
    if grep -q "skip = true" terragrunt.hcl; then
        print_status "Bootstrap is currently disabled, enabling for deletion..."
        sed -i.bak 's/skip = true/skip = false/' terragrunt.hcl
    elif grep -q "skip = false" terragrunt.hcl; then
        print_status "Bootstrap is already enabled for deletion..."
    else
        print_error "Unable to determine bootstrap skip status"
        exit 1
    fi

    # Always use direct cleanup for bootstrap destruction
    # Terragrunt consistently gets stuck on bootstrap destruction, even with clean S3 buckets
    print_status "Using direct cleanup for reliable bootstrap destruction..."
    print_status "This approach is faster and more reliable than terragrunt for bootstrap resources"
    
    # Perform direct manual cleanup
    print_status "Performing direct manual cleanup..."
    cleanup_s3_bucket "$BUCKET_NAME"
    
    # Also delete DynamoDB table manually
    print_status "Deleting DynamoDB table manually..."
    if aws dynamodb describe-table --table-name "$TABLE_NAME" --region "$AWS_REGION" >/dev/null 2>&1; then
        aws dynamodb delete-table --table-name "$TABLE_NAME" --region "$AWS_REGION" >/dev/null 2>&1
        print_success "DynamoDB table deletion initiated"
    fi

    # Disable bootstrap again
    print_status "Disabling bootstrap..."
    sed -i.bak 's/skip = false/skip = true/' terragrunt.hcl

    # Clean up backup files
    rm -f terragrunt.hcl.bak

    print_success "Bootstrap deleted successfully!"
    print_success "Environment: $ENVIRONMENT"
    print_status "Bootstrap is now disabled."
}

# Function to check bootstrap status
check_bootstrap_status() {
    print_status "Checking bootstrap status for environment: $ENVIRONMENT"
    
    # Get AWS account ID and region
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    AWS_REGION="eu-west-1"
    
    # Define resource names
    BUCKET_NAME="datashift-$ENVIRONMENT-tfstate-$AWS_ACCOUNT_ID-$AWS_REGION"
    TABLE_NAME="datashift-$ENVIRONMENT-tf-locks"
    
    print_status "Checking resources:"
    print_status "  S3 bucket: $BUCKET_NAME"
    print_status "  DynamoDB table: $TABLE_NAME"
    
    local bucket_exists=false
    local table_exists=false
    local bucket_status="❌ Not found"
    local table_status="❌ Not found"
    
    # Check S3 bucket
    if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
        bucket_exists=true
        bucket_status="✅ Exists"
        
        # Get bucket details
        local bucket_region=$(aws s3api get-bucket-location --bucket "$BUCKET_NAME" --query LocationConstraint --output text)
        if [[ "$bucket_region" == "null" ]]; then
            bucket_region="us-east-1"
        fi
        print_status "    Region: $bucket_region"
        
        # Check versioning
        local versioning=$(aws s3api get-bucket-versioning --bucket "$BUCKET_NAME" --query Status --output text)
        if [[ "$versioning" == "Enabled" ]]; then
            print_status "    Versioning: ✅ Enabled"
        else
            print_status "    Versioning: ❌ Disabled"
        fi
    fi
    
    # Check DynamoDB table
    if aws dynamodb describe-table --table-name "$TABLE_NAME" --region "$AWS_REGION" 2>/dev/null; then
        table_exists=true
        table_status="✅ Exists"
        
        # Get table details
        local table_status_aws=$(aws dynamodb describe-table --table-name "$TABLE_NAME" --region "$AWS_REGION" --query Table.TableStatus --output text)
        print_status "    Status: $table_status_aws"
        
        local billing_mode=$(aws dynamodb describe-table --table-name "$TABLE_NAME" --region "$AWS_REGION" --query Table.BillingModeSummary.BillingMode --output text)
        print_status "    Billing Mode: $billing_mode"
    fi
    
    # Check terragrunt skip status
    local skip_status="❓ Unknown"
    if [ -f "bootstrap/terragrunt.hcl" ]; then
        if grep -q "skip = false" bootstrap/terragrunt.hcl; then
            skip_status="✅ Enabled (skip = false)"
        elif grep -q "skip = true" bootstrap/terragrunt.hcl; then
            skip_status="❌ Disabled (skip = true)"
        fi
    fi
    
    print_status "Bootstrap Status Summary:"
    print_status "  Terragrunt skip: $skip_status"
    print_status "  S3 bucket: $bucket_status"
    print_status "  DynamoDB table: $table_status"
    
    if [[ "$bucket_exists" == true && "$table_exists" == true ]]; then
        if grep -q "skip = false" bootstrap/terragrunt.hcl; then
            print_success "Bootstrap is COMPLETE and ENABLED for environment: $ENVIRONMENT"
        else
            print_success "Bootstrap is COMPLETE but DISABLED for environment: $ENVIRONMENT"
            print_status "Resources exist but terragrunt skip is enabled. This is normal after bootstrap completion."
        fi
        return 0
    elif [[ "$bucket_exists" == true || "$table_exists" == true ]]; then
        print_warning "Bootstrap is PARTIAL for environment: $ENVIRONMENT"
        print_warning "Some resources exist but not all. This may indicate a failed bootstrap or manual cleanup."
        return 1
    else
        print_warning "Bootstrap is MISSING for environment: $ENVIRONMENT"
        print_status "No bootstrap resources found. Run 'create' action to bootstrap the environment."
        return 1
    fi
}

# Function to force unlock bootstrap state
unlock_bootstrap() {
    print_status "Force unlocking bootstrap state for environment: $ENVIRONMENT"
    
    cd bootstrap || {
        print_error "Bootstrap directory not found"
        exit 1
    }
    
    print_warning "Attempting to force unlock bootstrap state..."
    if terragrunt force-unlock -force "$(terragrunt show-lock-id 2>/dev/null || echo 'unknown')" 2>/dev/null; then
        print_success "Bootstrap state unlocked successfully!"
    else
        print_warning "No state lock found or unable to unlock"
        print_status "This may be normal if no lock exists"
    fi
    
    print_success "Bootstrap unlock completed for environment: $ENVIRONMENT"
}

# Main logic based on action
case "$ACTION" in
    "create")
        create_bootstrap
        ;;
    "delete")
        delete_bootstrap
        ;;
    "status")
        check_bootstrap_status
        ;;
    "unlock")
        unlock_bootstrap
        ;;
    *)
        print_error "Invalid action: $ACTION"
        exit 1
        ;;
esac

if [[ "$ACTION" != "status" ]]; then
    print_status "Bootstrap $ACTION completed for environment: $ENVIRONMENT"
fi
print_status "Current directory: $(pwd)"
