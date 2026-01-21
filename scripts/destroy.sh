#!/bin/bash
#
# GreenCity AWS Teardown Script
# Destroys all AWS infrastructure
#
# Usage: ./destroy.sh [options]
#   --skip-k8s         Skip Kubernetes resource deletion
#   --skip-ecr         Skip ECR image deletion
#   --force            Skip confirmation prompts
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_DIR/terraform"
K8S_DIR="$PROJECT_DIR/k8s"

AWS_REGION="eu-west-1"
AWS_ACCOUNT_ID="731818487147"
CLUSTER_NAME="greencity-cluster"
NAMESPACE="greencity"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

# Parse arguments
SKIP_K8S=false
SKIP_ECR=false
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-k8s) SKIP_K8S=true; shift ;;
        --skip-ecr) SKIP_ECR=true; shift ;;
        --force) FORCE=true; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Confirmation
confirm_destroy() {
    if [[ "$FORCE" == "true" ]]; then
        return
    fi

    echo ""
    log_warn "This will DESTROY all GreenCity AWS infrastructure!"
    log_warn "Including: EKS cluster, RDS database, ECR images, VPC, etc."
    echo ""
    read -p "Are you sure? Type 'yes' to confirm: " confirm

    if [[ "$confirm" != "yes" ]]; then
        log_info "Aborted."
        exit 0
    fi
}

# Delete Kubernetes resources
delete_k8s_resources() {
    if [[ "$SKIP_K8S" == "true" ]]; then
        log_info "Skipping Kubernetes cleanup (--skip-k8s)"
        return
    fi

    log_step "Deleting Kubernetes resources..."

    # Check if cluster is accessible
    if ! kubectl cluster-info &>/dev/null; then
        log_warn "Cannot connect to Kubernetes cluster. Skipping K8s cleanup."
        return
    fi

    # Delete ingress first (removes ALB)
    log_info "Deleting Ingress (ALB)..."
    kubectl delete -f "$K8S_DIR/ingress.yaml" --ignore-not-found 2>/dev/null || true

    # Wait for ALB to be deleted
    log_info "Waiting for ALB to be deleted..."
    sleep 30

    # Delete deployments
    log_info "Deleting deployments..."
    kubectl delete -f "$K8S_DIR/frontend/" --ignore-not-found 2>/dev/null || true
    kubectl delete -f "$K8S_DIR/backuser/" --ignore-not-found 2>/dev/null || true
    kubectl delete -f "$K8S_DIR/backcore/" --ignore-not-found 2>/dev/null || true

    # Delete secrets and configmap
    log_info "Deleting secrets and configmap..."
    kubectl delete -f "$K8S_DIR/secrets.yaml" --ignore-not-found 2>/dev/null || true
    kubectl delete -f "$K8S_DIR/configmap.yaml" --ignore-not-found 2>/dev/null || true

    # Delete namespace
    log_info "Deleting namespace..."
    kubectl delete -f "$K8S_DIR/namespace.yaml" --ignore-not-found 2>/dev/null || true

    log_info "Kubernetes resources deleted"
}

# Delete ECR images
delete_ecr_images() {
    if [[ "$SKIP_ECR" == "true" ]]; then
        log_info "Skipping ECR cleanup (--skip-ecr)"
        return
    fi

    log_step "Deleting ECR images..."

    for repo in greencity/backcore greencity/backuser greencity/frontend; do
        log_info "Deleting images from $repo..."

        # Get all image IDs
        local image_ids
        image_ids=$(aws ecr list-images \
            --repository-name "$repo" \
            --region "$AWS_REGION" \
            --query 'imageIds[*]' \
            --output json 2>/dev/null || echo "[]")

        if [[ "$image_ids" != "[]" ]] && [[ -n "$image_ids" ]]; then
            aws ecr batch-delete-image \
                --repository-name "$repo" \
                --region "$AWS_REGION" \
                --image-ids "$image_ids" 2>/dev/null || true
        fi
    done

    log_info "ECR images deleted"
}

# Run Terraform destroy
run_terraform_destroy() {
    log_step "Running Terraform destroy..."

    cd "$TERRAFORM_DIR"

    if [[ ! -d ".terraform" ]]; then
        log_warn "Terraform not initialized. Running init first..."
        terraform init
    fi

    log_info "Destroying infrastructure..."
    terraform destroy -auto-approve

    log_info "Terraform destroy complete!"
    cd "$PROJECT_DIR"
}

# Cleanup local files
cleanup_local_files() {
    log_step "Cleaning up local files..."

    # Remove generated secrets.yaml
    if [[ -f "$K8S_DIR/secrets.yaml" ]]; then
        rm -f "$K8S_DIR/secrets.yaml"
        log_info "Removed k8s/secrets.yaml"
    fi

    # Remove terraform plan file
    if [[ -f "$TERRAFORM_DIR/tfplan" ]]; then
        rm -f "$TERRAFORM_DIR/tfplan"
        log_info "Removed terraform/tfplan"
    fi

    log_info "Local cleanup complete"
}

# Main
main() {
    echo "=========================================="
    echo " GreenCity AWS Teardown"
    echo "=========================================="
    echo ""

    confirm_destroy

    delete_k8s_resources
    delete_ecr_images
    run_terraform_destroy
    cleanup_local_files

    echo ""
    echo "=========================================="
    echo " Teardown Complete"
    echo "=========================================="
    echo ""
    log_info "All AWS resources have been destroyed."
    echo ""
    log_warn "Note: The Terraform state backend (S3 bucket and DynamoDB table)"
    log_warn "was NOT deleted. To remove it, run:"
    echo "  ./scripts/bootstrap-terraform.sh --destroy"
    echo ""
}

main "$@"
