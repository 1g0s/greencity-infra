#!/bin/bash
# common.sh - GreenCity Shared Functions
# Source this file: source "$(dirname "$0")/lib/common.sh"

# ===========================================
# COLORS
# ===========================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ===========================================
# OUTPUT FUNCTIONS
# ===========================================
info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }
header()  { echo -e "\n${BOLD}${CYAN}=== $* ===${NC}"; }

# Status indicators
ok()   { echo -e "  ${GREEN}✅${NC} $*"; }
fail() { echo -e "  ${RED}❌${NC} $*"; }
wait_icon() { echo -e "  ${YELLOW}⏳${NC} $*"; }

# ===========================================
# ENVIRONMENT CONFIGURATION
# ===========================================
# Get project root (parent of scripts directory)
get_project_root() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
    dirname "$script_dir"
}

# Valid environments
VALID_ENVS=("prod" "lb" "vm")

# Environment to compose file mapping
declare -A COMPOSE_FILES=(
    ["prod"]="docker-compose.prod.yml"
    ["lb"]="docker-compose.lb.yml"
)

# Container name prefixes by environment
declare -A POSTGRES_CONTAINERS=(
    ["prod"]="greencity-postgres"
    ["lb"]="greencity-postgres-lb"
    ["vm"]="greencity-postgres-lb"
)

# VM configuration
VM_IP="192.168.10.20"
VM_DIR="vagrant"

# ===========================================
# VALIDATION FUNCTIONS
# ===========================================
validate_env() {
    local env="$1"
    local valid=false

    for valid_env in "${VALID_ENVS[@]}"; do
        if [[ "$env" == "$valid_env" ]]; then
            valid=true
            break
        fi
    done

    if [[ "$valid" != "true" ]]; then
        error "Invalid environment: $env"
        echo "Valid environments: ${VALID_ENVS[*]}"
        return 1
    fi
    return 0
}

get_compose_file() {
    local env="$1"
    echo "${COMPOSE_FILES[$env]}"
}

get_postgres_container() {
    local env="$1"
    echo "${POSTGRES_CONTAINERS[$env]}"
}

# ===========================================
# DOCKER HELPERS
# ===========================================
is_docker_running() {
    docker info >/dev/null 2>&1
}

container_exists() {
    local container="$1"
    docker ps -a --format '{{.Names}}' | grep -q "^${container}$"
}

container_running() {
    local container="$1"
    docker ps --format '{{.Names}}' | grep -q "^${container}$"
}

# Get compose command for environment
compose_cmd() {
    local env="$1"
    local compose_file
    compose_file=$(get_compose_file "$env")
    echo "docker compose -f $compose_file"
}

# ===========================================
# VM HELPERS
# ===========================================
vm_is_running() {
    local project_root="$1"
    cd "$project_root/$VM_DIR" 2>/dev/null || return 1
    vagrant status 2>/dev/null | grep -q "running"
}

vm_ssh() {
    local project_root="$1"
    shift
    cd "$project_root/$VM_DIR" || return 1
    vagrant ssh -c "$*"
}

# ===========================================
# HTTP HELPERS
# ===========================================
http_check() {
    local url="$1"
    local timeout="${2:-5}"
    curl -sf -o /dev/null -w "%{http_code}" --connect-timeout "$timeout" "$url" 2>/dev/null
}

http_check_with_time() {
    local url="$1"
    local timeout="${2:-5}"
    curl -sf -o /dev/null -w "%{http_code}|%{time_total}" --connect-timeout "$timeout" "$url" 2>/dev/null
}

get_backend_header() {
    local url="$1"
    curl -sf -I --connect-timeout 5 "$url" 2>/dev/null | grep -i "X-Backend-Server" | awk '{print $2}' | tr -d '\r'
}
