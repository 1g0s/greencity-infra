#!/bin/bash
#
# Configure kubectl for GreenCity EKS cluster
#
# Usage: ./kubeconfig.sh
#

set -e

AWS_REGION="eu-west-1"
CLUSTER_NAME="greencity-cluster"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    if ! command -v aws &> /dev/null; then
        echo "Error: AWS CLI not found. Install it first."
        exit 1
    fi

    if ! command -v kubectl &> /dev/null; then
        echo "Error: kubectl not found. Install it first."
        exit 1
    fi

    if ! aws sts get-caller-identity &>/dev/null; then
        echo "Error: AWS CLI not configured. Run 'aws configure' first."
        exit 1
    fi
}

# Update kubeconfig
update_kubeconfig() {
    log_info "Updating kubeconfig for cluster: $CLUSTER_NAME"

    aws eks update-kubeconfig \
        --name "$CLUSTER_NAME" \
        --region "$AWS_REGION"

    log_info "Kubeconfig updated successfully!"
}

# Verify connection
verify_connection() {
    log_info "Verifying connection to cluster..."

    if kubectl cluster-info &>/dev/null; then
        echo ""
        kubectl cluster-info
        echo ""
        log_info "Connected to EKS cluster!"
        echo ""
        log_info "Nodes:"
        kubectl get nodes
        echo ""
    else
        log_warn "Could not connect to cluster. The cluster may not be ready yet."
    fi
}

# Main
main() {
    echo "=========================================="
    echo " GreenCity EKS Kubeconfig Setup"
    echo "=========================================="
    echo ""

    check_prerequisites
    update_kubeconfig
    verify_connection

    echo ""
    log_info "You can now use kubectl commands:"
    echo "  kubectl get pods -n greencity"
    echo "  kubectl get svc -n greencity"
    echo "  kubectl logs -f deployment/backcore -n greencity"
    echo ""
}

main "$@"
