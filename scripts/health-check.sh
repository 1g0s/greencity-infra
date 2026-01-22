#!/bin/bash
# health-check.sh - GreenCity Health Monitoring
# Checks container status, endpoints, and load distribution

# Don't use set -e because we want to continue even if checks fail

# ===========================================
# SETUP
# ===========================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source common functions
source "$SCRIPT_DIR/lib/common.sh"

# ===========================================
# HELP
# ===========================================
show_help() {
    cat << EOF
${BOLD}GreenCity Health Check${NC}

${CYAN}Usage:${NC}
  ./scripts/health-check.sh [environment] [options]

${CYAN}Environments:${NC}
  prod    Single instance (default: localhost)
  lb      Load balanced (default: localhost)
  vm      Vagrant VM (192.168.10.20)

${CYAN}Options:${NC}
  --verbose, -v    Show detailed output

${CYAN}Examples:${NC}
  ./scripts/health-check.sh lb
  ./scripts/health-check.sh vm --verbose

EOF
}

# Handle help early
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" || "${1:-}" == "help" ]]; then
    show_help
    exit 0
fi

# ===========================================
# CONFIGURATION
# ===========================================
ENV="${1:-lb}"
VERBOSE=false
[[ "${2:-}" == "--verbose" || "${2:-}" == "-v" ]] && VERBOSE=true

# Counters
PASS=0
FAIL=0

# ===========================================
# CHECK FUNCTIONS
# ===========================================
check_container() {
    local container="$1"
    local status
    local health

    if ! container_exists "$container"; then
        fail "$container - not found"
        ((FAIL++))
        return 1
    fi

    if container_running "$container"; then
        # Get health status if available
        health=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "none")
        status=$(docker inspect --format='{{.State.Status}}' "$container")

        if [[ "$health" != "none" && "$health" != "" ]]; then
            ok "$container - $status ($health)"
        else
            ok "$container - $status"
        fi
        ((PASS++))
        return 0
    else
        fail "$container - not running"
        ((FAIL++))
        return 1
    fi
}

check_endpoint() {
    local name="$1"
    local path="$2"
    local base_url="$3"
    local url="${base_url}${path}"

    local result
    result=$(http_check_with_time "$url" 10)

    if [[ -z "$result" ]]; then
        fail "$name - connection failed"
        ((FAIL++))
        return 1
    fi

    local code time_ms
    code=$(echo "$result" | cut -d'|' -f1)
    time_ms=$(echo "$result" | cut -d'|' -f2 | awk '{printf "%.0f", $1 * 1000}')

    if [[ "$code" == "200" || "$code" == "302" || "$code" == "301" ]]; then
        ok "$name - $code OK (${time_ms}ms)"
        ((PASS++))
        return 0
    else
        fail "$name - HTTP $code (${time_ms}ms)"
        ((FAIL++))
        return 1
    fi
}

check_load_distribution() {
    local pool_name="$1"
    local endpoint="$2"
    local base_url="$3"
    local num_requests="${4:-10}"
    local url="${base_url}${endpoint}"

    echo -e "\n${BOLD}Load Distribution - $pool_name ($num_requests requests):${NC}"

    declare -A backend_counts

    for ((i=1; i<=num_requests; i++)); do
        local backend
        backend=$(get_backend_header "$url")

        if [[ -n "$backend" ]]; then
            local ip_port="$backend"
            backend_counts["$ip_port"]=$((${backend_counts["$ip_port"]:-0} + 1))
        fi
    done

    # Display results
    if [[ ${#backend_counts[@]} -eq 0 ]]; then
        warn "  No X-Backend-Server headers received (endpoint may not support load balancing)"
        return
    fi

    # Sort and display
    for backend in "${!backend_counts[@]}"; do
        local count=${backend_counts[$backend]}
        local pct=$((count * 100 / num_requests))
        echo "  $backend: $count ($pct%)"
    done
}

# ===========================================
# MAIN CHECKS
# ===========================================
run_checks() {
    local env="$1"
    local base_url

    # Set base URL based on environment
    case "$env" in
        prod|lb) base_url="http://localhost" ;;
        vm)      base_url="http://$VM_IP" ;;
    esac

    header "GreenCity Health Check ($env)"
    echo -e "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "Base URL: $base_url"

    # Container checks based on environment
    echo -e "\n${BOLD}Container Status:${NC}"

    if [[ "$env" == "vm" ]]; then
        # VM environment - check via SSH
        if ! vm_is_running "$PROJECT_ROOT"; then
            fail "VM is not running"
            echo -e "\nStart with: ./scripts/ops.sh start vm"
            exit 1
        fi
        ok "VM is running at $VM_IP"

        # Check containers via SSH
        local containers
        containers=$(cd "$PROJECT_ROOT/$VM_DIR" && vagrant ssh -c "docker ps --format '{{.Names}}'" 2>/dev/null | tr -d '\r')

        for container in greencity-lb greencity-postgres-lb \
            greencity-backcore-1 greencity-backcore-2 greencity-backcore-3 \
            greencity-backuser-1 greencity-backuser-2 greencity-backuser-3; do
            if echo "$containers" | grep -q "^${container}$"; then
                ok "$container - running"
                ((PASS++))
            else
                fail "$container - not found"
                ((FAIL++))
            fi
        done

    elif [[ "$env" == "lb" ]]; then
        # LB environment
        check_container "greencity-lb"
        check_container "greencity-postgres-lb"
        check_container "greencity-backcore-1"
        check_container "greencity-backcore-2"
        check_container "greencity-backcore-3"
        check_container "greencity-backuser-1"
        check_container "greencity-backuser-2"
        check_container "greencity-backuser-3"

    else
        # Prod environment
        check_container "greencity-frontend"
        check_container "greencity-postgres"
        check_container "greencity-backcore"
        check_container "greencity-backuser"
    fi

    # Endpoint checks
    echo -e "\n${BOLD}Endpoint Checks:${NC}"

    check_endpoint "Frontend (/)" "/" "$base_url"
    check_endpoint "BackCore API" "/api/core/" "$base_url"
    check_endpoint "BackUser API" "/api/user/" "$base_url"
    check_endpoint "Swagger UI" "/swagger-ui/" "$base_url"
    check_endpoint "Nginx Health" "/nginx-health" "$base_url"

    # Load distribution (only for lb and vm)
    if [[ "$env" == "lb" || "$env" == "vm" ]]; then
        check_load_distribution "BackCore" "/api/core/" "$base_url" 10
        check_load_distribution "BackUser" "/api/user/" "$base_url" 10
    fi

    # Summary
    echo ""
    header "Summary"

    local total=$((PASS + FAIL))
    echo -e "Passed: ${GREEN}$PASS${NC} / $total"
    echo -e "Failed: ${RED}$FAIL${NC} / $total"

    if [[ $FAIL -eq 0 ]]; then
        echo -e "\n${GREEN}${BOLD}Overall: All checks passed${NC}"
        return 0
    else
        echo -e "\n${RED}${BOLD}Overall: $FAIL check(s) failed${NC}"
        return 1
    fi
}

# ===========================================
# MAIN
# ===========================================
main() {
    validate_env "$ENV" || exit 1
    run_checks "$ENV"
}

main "$@"
