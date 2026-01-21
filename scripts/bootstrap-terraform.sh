#!/bin/bash
#
# Bootstrap Terraform State Backend for GreenCity AWS Infrastructure
# Creates S3 bucket and DynamoDB table for Terraform state management
#
# Usage: ./bootstrap-terraform.sh [--destroy]
#
# This script should be run ONCE before the first terraform init.
# The --destroy flag removes the state backend (use with caution).
#

set -e

# Configuration
AWS_REGION="eu-west-1"
ACCOUNT_ID="731818487147"
PROJECT_NAME="greencity"
BUCKET_NAME="${PROJECT_NAME}-terraform-state-${ACCOUNT_ID}"
TABLE_NAME="${PROJECT_NAME}-terraform-lock"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check AWS CLI is configured
check_aws() {
    log_info "Checking AWS credentials..."
    if ! aws sts get-caller-identity &>/dev/null; then
        log_error "AWS CLI not configured. Run 'aws configure' first."
        exit 1
    fi

    local current_account
    current_account=$(aws sts get-caller-identity --query Account --output text)
    if [[ "$current_account" != "$ACCOUNT_ID" ]]; then
        log_error "Wrong AWS account. Expected: $ACCOUNT_ID, Got: $current_account"
        exit 1
    fi
    log_info "AWS credentials valid for account: $current_account"
}

# Create S3 bucket for Terraform state
create_s3_bucket() {
    log_info "Creating S3 bucket: $BUCKET_NAME"

    # Check if bucket exists
    if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
        log_warn "S3 bucket already exists: $BUCKET_NAME"
        return 0
    fi

    # Create bucket (eu-west-1 requires LocationConstraint)
    aws s3api create-bucket \
        --bucket "$BUCKET_NAME" \
        --region "$AWS_REGION" \
        --create-bucket-configuration LocationConstraint="$AWS_REGION"

    log_info "Enabling bucket versioning..."
    aws s3api put-bucket-versioning \
        --bucket "$BUCKET_NAME" \
        --versioning-configuration Status=Enabled

    log_info "Enabling bucket encryption..."
    aws s3api put-bucket-encryption \
        --bucket "$BUCKET_NAME" \
        --server-side-encryption-configuration '{
            "Rules": [
                {
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    }
                }
            ]
        }'

    log_info "Blocking public access..."
    aws s3api put-public-access-block \
        --bucket "$BUCKET_NAME" \
        --public-access-block-configuration '{
            "BlockPublicAcls": true,
            "IgnorePublicAcls": true,
            "BlockPublicPolicy": true,
            "RestrictPublicBuckets": true
        }'

    log_info "S3 bucket created successfully: $BUCKET_NAME"
}

# Create DynamoDB table for state locking
create_dynamodb_table() {
    log_info "Creating DynamoDB table: $TABLE_NAME"

    # Check if table exists
    if aws dynamodb describe-table --table-name "$TABLE_NAME" --region "$AWS_REGION" 2>/dev/null; then
        log_warn "DynamoDB table already exists: $TABLE_NAME"
        return 0
    fi

    aws dynamodb create-table \
        --table-name "$TABLE_NAME" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "$AWS_REGION"

    log_info "Waiting for table to be active..."
    aws dynamodb wait table-exists --table-name "$TABLE_NAME" --region "$AWS_REGION"

    log_info "DynamoDB table created successfully: $TABLE_NAME"
}

# Destroy state backend (use with caution)
destroy_backend() {
    log_warn "This will PERMANENTLY DELETE the Terraform state backend!"
    log_warn "All Terraform state will be LOST!"
    read -p "Are you sure? Type 'yes' to confirm: " confirm

    if [[ "$confirm" != "yes" ]]; then
        log_info "Aborted."
        exit 0
    fi

    log_info "Deleting DynamoDB table: $TABLE_NAME"
    aws dynamodb delete-table --table-name "$TABLE_NAME" --region "$AWS_REGION" 2>/dev/null || true

    log_info "Emptying and deleting S3 bucket: $BUCKET_NAME"
    aws s3 rm "s3://$BUCKET_NAME" --recursive 2>/dev/null || true
    aws s3api delete-bucket --bucket "$BUCKET_NAME" --region "$AWS_REGION" 2>/dev/null || true

    log_info "State backend destroyed."
}

# Print backend configuration for main.tf
print_backend_config() {
    echo ""
    log_info "Add this backend configuration to terraform/main.tf:"
    echo ""
    cat <<EOF
  backend "s3" {
    bucket         = "$BUCKET_NAME"
    key            = "greencity/terraform.tfstate"
    region         = "$AWS_REGION"
    dynamodb_table = "$TABLE_NAME"
    encrypt        = true
  }
EOF
    echo ""
}

# Main
main() {
    echo "=========================================="
    echo " GreenCity Terraform Backend Bootstrap"
    echo "=========================================="
    echo ""
    echo "Region:    $AWS_REGION"
    echo "Account:   $ACCOUNT_ID"
    echo "S3 Bucket: $BUCKET_NAME"
    echo "DynamoDB:  $TABLE_NAME"
    echo ""

    if [[ "${1:-}" == "--destroy" ]]; then
        check_aws
        destroy_backend
        exit 0
    fi

    check_aws
    create_s3_bucket
    create_dynamodb_table
    print_backend_config

    echo ""
    log_info "Bootstrap complete! You can now run:"
    echo "  cd terraform && terraform init"
    echo ""
}

main "$@"
