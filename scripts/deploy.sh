#!/bin/bash
#
# GreenCity AWS Deployment Script
# Deploys infrastructure and application to AWS
#
# Usage: ./deploy.sh [options]
#   --skip-terraform    Skip Terraform apply (use existing infra)
#   --skip-images       Skip pushing images to ECR
#   --skip-k8s          Skip Kubernetes deployment
#   --terraform-only    Only run Terraform (no images/k8s)
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

# Source images from GHCR
GHCR_REGISTRY="ghcr.io/1g0s"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

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
SKIP_TERRAFORM=false
SKIP_IMAGES=false
SKIP_K8S=false
TERRAFORM_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-terraform) SKIP_TERRAFORM=true; shift ;;
        --skip-images) SKIP_IMAGES=true; shift ;;
        --skip-k8s) SKIP_K8S=true; shift ;;
        --terraform-only) TERRAFORM_ONLY=true; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Check prerequisites
check_prerequisites() {
    log_step "Checking prerequisites..."

    local missing=()

    command -v aws &>/dev/null || missing+=("aws")
    command -v terraform &>/dev/null || missing+=("terraform")
    command -v kubectl &>/dev/null || missing+=("kubectl")
    command -v docker &>/dev/null || missing+=("docker")
    command -v helm &>/dev/null || missing+=("helm")

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing[*]}"
        exit 1
    fi

    if ! aws sts get-caller-identity &>/dev/null; then
        log_error "AWS CLI not configured. Run 'aws configure' first."
        exit 1
    fi

    log_info "All prerequisites met"
}

# Run Terraform
run_terraform() {
    if [[ "$SKIP_TERRAFORM" == "true" ]]; then
        log_info "Skipping Terraform (--skip-terraform)"
        return
    fi

    log_step "Running Terraform..."

    cd "$TERRAFORM_DIR"

    if [[ ! -f "terraform.tfvars" ]]; then
        log_error "terraform.tfvars not found. Copy from terraform.tfvars and fill in values."
        exit 1
    fi

    log_info "Initializing Terraform..."
    terraform init

    log_info "Planning Terraform changes..."
    terraform plan -out=tfplan

    log_info "Applying Terraform changes..."
    terraform apply tfplan

    rm -f tfplan

    log_info "Terraform apply complete!"
    cd "$PROJECT_DIR"
}

# Configure kubectl
configure_kubectl() {
    log_step "Configuring kubectl..."

    aws eks update-kubeconfig \
        --name "$CLUSTER_NAME" \
        --region "$AWS_REGION"

    log_info "kubectl configured for cluster: $CLUSTER_NAME"
}

# Push images to ECR
push_images_to_ecr() {
    if [[ "$SKIP_IMAGES" == "true" ]] || [[ "$TERRAFORM_ONLY" == "true" ]]; then
        log_info "Skipping image push"
        return
    fi

    log_step "Pushing images to ECR..."

    # Login to GHCR
    log_info "Logging into GHCR..."
    echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$GITHUB_USER" --password-stdin 2>/dev/null || \
        log_warn "GHCR login skipped (set GITHUB_TOKEN and GITHUB_USER)"

    # Login to ECR
    log_info "Logging into ECR..."
    aws ecr get-login-password --region "$AWS_REGION" | \
        docker login --username AWS --password-stdin "$ECR_REGISTRY"

    # Pull, tag, and push each image
    for component in backcore backuser frontend; do
        log_info "Processing $component..."

        local src_image="${GHCR_REGISTRY}/greencity-${component}:latest"
        local dst_image="${ECR_REGISTRY}/greencity/${component}:latest"

        log_info "  Pulling from GHCR: $src_image"
        docker pull "$src_image" || {
            log_warn "  Failed to pull from GHCR, trying local image..."
            src_image="greencity-${component}:prod"
        }

        log_info "  Tagging for ECR: $dst_image"
        docker tag "$src_image" "$dst_image"

        log_info "  Pushing to ECR..."
        docker push "$dst_image"

        log_info "  $component pushed successfully!"
    done

    log_info "All images pushed to ECR"
}

# Generate Kubernetes secrets from AWS Secrets Manager
generate_k8s_secrets() {
    log_step "Generating Kubernetes secrets..."

    # Get secrets from AWS Secrets Manager
    log_info "Fetching secrets from AWS Secrets Manager..."

    local db_secret
    db_secret=$(aws secretsmanager get-secret-value \
        --secret-id "greencity/db-credentials" \
        --region "$AWS_REGION" \
        --query 'SecretString' \
        --output text)

    local app_secret
    app_secret=$(aws secretsmanager get-secret-value \
        --secret-id "greencity/app-secrets" \
        --region "$AWS_REGION" \
        --query 'SecretString' \
        --output text)

    # Extract values
    local jdbc_url username password
    jdbc_url=$(echo "$db_secret" | jq -r '.jdbc_url' | base64 -w0)
    username=$(echo "$db_secret" | jq -r '.username' | base64 -w0)
    password=$(echo "$db_secret" | jq -r '.password' | base64 -w0)

    local email_address email_password google_client_id google_api_key azure_connection_string
    email_address=$(echo "$app_secret" | jq -r '.email_address' | base64 -w0)
    email_password=$(echo "$app_secret" | jq -r '.email_password' | base64 -w0)
    google_client_id=$(echo "$app_secret" | jq -r '.google_client_id' | base64 -w0)
    google_api_key=$(echo "$app_secret" | jq -r '.google_api_key' | base64 -w0)
    azure_connection_string=$(echo "$app_secret" | jq -r '.azure_connection_string' | base64 -w0)

    # Generate secrets.yaml
    cat > "$K8S_DIR/secrets.yaml" <<EOF
#
# GreenCity Secrets - Auto-generated from AWS Secrets Manager
# Generated: $(date -Iseconds)
#
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
  namespace: greencity
  labels:
    app: greencity
type: Opaque
data:
  jdbc_url: $jdbc_url
  username: $username
  password: $password
---
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: greencity
  labels:
    app: greencity
type: Opaque
data:
  email_address: $email_address
  email_password: $email_password
  google_client_id: $google_client_id
  google_api_key: $google_api_key
  azure_connection_string: $azure_connection_string
EOF

    log_info "Secrets generated at $K8S_DIR/secrets.yaml"
}

# Deploy to Kubernetes
deploy_to_k8s() {
    if [[ "$SKIP_K8S" == "true" ]] || [[ "$TERRAFORM_ONLY" == "true" ]]; then
        log_info "Skipping Kubernetes deployment"
        return
    fi

    log_step "Deploying to Kubernetes..."

    # Create namespace
    log_info "Creating namespace..."
    kubectl apply -f "$K8S_DIR/namespace.yaml"

    # Apply ConfigMap
    log_info "Applying ConfigMap..."
    kubectl apply -f "$K8S_DIR/configmap.yaml"

    # Apply Secrets
    log_info "Applying Secrets..."
    if [[ -f "$K8S_DIR/secrets.yaml" ]]; then
        kubectl apply -f "$K8S_DIR/secrets.yaml"
    else
        log_warn "secrets.yaml not found. Run generate_k8s_secrets first or create manually."
    fi

    # Deploy components
    log_info "Deploying BackCore..."
    kubectl apply -f "$K8S_DIR/backcore/"

    log_info "Deploying BackUser..."
    kubectl apply -f "$K8S_DIR/backuser/"

    log_info "Deploying Frontend..."
    kubectl apply -f "$K8S_DIR/frontend/"

    # Apply Ingress
    log_info "Applying Ingress..."
    kubectl apply -f "$K8S_DIR/ingress.yaml"

    log_info "Kubernetes deployment complete!"
}

# Wait for pods to be ready
wait_for_pods() {
    if [[ "$SKIP_K8S" == "true" ]] || [[ "$TERRAFORM_ONLY" == "true" ]]; then
        return
    fi

    log_step "Waiting for pods to be ready..."

    log_info "Waiting for BackCore pods (timeout: 10m)..."
    kubectl rollout status deployment/backcore -n "$NAMESPACE" --timeout=600s || true

    log_info "Waiting for BackUser pods (timeout: 10m)..."
    kubectl rollout status deployment/backuser -n "$NAMESPACE" --timeout=600s || true

    log_info "Waiting for Frontend pods (timeout: 2m)..."
    kubectl rollout status deployment/frontend -n "$NAMESPACE" --timeout=120s || true

    echo ""
    log_info "Current pod status:"
    kubectl get pods -n "$NAMESPACE" -o wide
}

# Get ALB URL
get_alb_url() {
    if [[ "$SKIP_K8S" == "true" ]] || [[ "$TERRAFORM_ONLY" == "true" ]]; then
        return
    fi

    log_step "Getting ALB URL..."

    local alb_url
    alb_url=$(kubectl get ingress greencity-ingress -n "$NAMESPACE" \
        -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")

    if [[ -n "$alb_url" ]]; then
        echo ""
        echo "=========================================="
        echo " Deployment Complete!"
        echo "=========================================="
        echo ""
        echo " ALB URL: http://$alb_url"
        echo ""
        echo " Test endpoints:"
        echo "   curl http://$alb_url/"
        echo "   curl http://$alb_url/swagger-ui/"
        echo "   curl http://$alb_url/api/core/v3/api-docs"
        echo "   curl http://$alb_url/api/user/v3/api-docs"
        echo ""
    else
        log_warn "ALB URL not available yet. Check ingress status:"
        echo "  kubectl get ingress -n $NAMESPACE"
    fi
}

# Main
main() {
    echo "=========================================="
    echo " GreenCity AWS Deployment"
    echo "=========================================="
    echo ""
    echo " Region:  $AWS_REGION"
    echo " Cluster: $CLUSTER_NAME"
    echo ""

    check_prerequisites

    run_terraform

    if [[ "$TERRAFORM_ONLY" == "true" ]]; then
        log_info "Terraform-only mode. Exiting."
        exit 0
    fi

    configure_kubectl
    push_images_to_ecr
    generate_k8s_secrets
    deploy_to_k8s
    wait_for_pods
    get_alb_url

    echo ""
    log_info "Deployment complete!"
}

main "$@"
