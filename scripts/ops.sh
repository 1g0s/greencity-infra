#!/bin/bash
# ops.sh - GreenCity Operations Script
# Unified operations for all deployment environments

set -e

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
${BOLD}GreenCity Operations Script${NC}

${CYAN}Usage:${NC}
  ./scripts/ops.sh <command> [environment] [options]

${CYAN}Commands:${NC}
  start <env>       Start services
  stop <env>        Stop services
  restart <env>     Restart services
  status <env>      Show container status
  logs <service>    View service logs (add -f to follow)
  health <env>      Run health checks
  deploy <env>      Pull images and start services
  cleanup           Remove stopped containers and dangling images

${CYAN}Environments:${NC}
  prod    Single instance (docker-compose.prod.yml)
  lb      Load balanced (docker-compose.lb.yml) - 3x backcore, 3x backuser
  vm      Vagrant VM at 192.168.10.20

${CYAN}Services (for logs):${NC}
  nginx, backcore1, backcore2, backcore3
  backuser1, backuser2, backuser3, postgres

${CYAN}Examples:${NC}
  ./scripts/ops.sh start lb          # Start load balanced environment
  ./scripts/ops.sh status prod       # Check prod container status
  ./scripts/ops.sh logs backcore1 -f # Follow backcore1 logs
  ./scripts/ops.sh health vm         # Health check VM environment
  ./scripts/ops.sh deploy lb         # Pull images and deploy
  ./scripts/ops.sh cleanup           # Clean up Docker resources

EOF
}

# ===========================================
# DOCKER OPERATIONS
# ===========================================

# Get docker compose command with env file
docker_compose() {
    local compose_file="$1"
    shift
    docker compose --env-file .env.prod -f "$compose_file" "$@"
}

cmd_start() {
    local env="$1"
    validate_env "$env" || exit 1

    if [[ "$env" == "vm" ]]; then
        header "Starting VM Environment"
        cd "$PROJECT_ROOT/$VM_DIR"
        vagrant up
        success "VM started at $VM_IP"
    else
        local compose_file
        compose_file=$(get_compose_file "$env")
        header "Starting $env Environment"
        info "Using: $compose_file"

        cd "$PROJECT_ROOT"
        docker_compose "$compose_file" up -d

        success "$env environment started"
        echo ""
        info "Services starting... Java backends take 2-3 minutes to initialize"
        info "Run: ./scripts/ops.sh health $env"
    fi
}

cmd_stop() {
    local env="$1"
    validate_env "$env" || exit 1

    if [[ "$env" == "vm" ]]; then
        header "Stopping VM Environment"
        cd "$PROJECT_ROOT/$VM_DIR"
        vagrant halt
        success "VM stopped"
    else
        local compose_file
        compose_file=$(get_compose_file "$env")
        header "Stopping $env Environment"

        cd "$PROJECT_ROOT"
        docker_compose "$compose_file" down

        success "$env environment stopped"
    fi
}

cmd_restart() {
    local env="$1"
    validate_env "$env" || exit 1

    if [[ "$env" == "vm" ]]; then
        header "Restarting VM Environment"
        cd "$PROJECT_ROOT/$VM_DIR"
        vagrant reload
        success "VM restarted"
    else
        local compose_file
        compose_file=$(get_compose_file "$env")
        header "Restarting $env Environment"

        cd "$PROJECT_ROOT"
        docker_compose "$compose_file" restart

        success "$env environment restarted"
    fi
}

cmd_status() {
    local env="$1"
    validate_env "$env" || exit 1

    header "Status: $env Environment"

    if [[ "$env" == "vm" ]]; then
        cd "$PROJECT_ROOT/$VM_DIR"
        echo -e "\n${BOLD}Vagrant VM Status:${NC}"
        vagrant status

        if vm_is_running "$PROJECT_ROOT"; then
            echo -e "\n${BOLD}Docker Containers in VM:${NC}"
            vagrant ssh -c "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'" 2>/dev/null || true
        fi
    else
        local compose_file
        compose_file=$(get_compose_file "$env")

        cd "$PROJECT_ROOT"
        docker_compose "$compose_file" ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
    fi
}

cmd_logs() {
    local service="$1"
    shift
    local follow_args="$*"

    if [[ -z "$service" ]]; then
        error "Service name required"
        echo "Available: nginx, backcore1, backcore2, backcore3, backuser1, backuser2, backuser3, postgres"
        exit 1
    fi

    # Map service names to container names
    local container
    case "$service" in
        nginx)     container="greencity-lb" ;;
        postgres)  container="greencity-postgres-lb" ;;
        backcore1) container="greencity-backcore-1" ;;
        backcore2) container="greencity-backcore-2" ;;
        backcore3) container="greencity-backcore-3" ;;
        backuser1) container="greencity-backuser-1" ;;
        backuser2) container="greencity-backuser-2" ;;
        backuser3) container="greencity-backuser-3" ;;
        *)         container="greencity-$service" ;;
    esac

    header "Logs: $container"
    # shellcheck disable=SC2086
    docker logs $follow_args "$container"
}

cmd_health() {
    local env="${1:-lb}"
    validate_env "$env" || exit 1

    # Run health check script
    "$SCRIPT_DIR/health-check.sh" "$env"
}

cmd_deploy() {
    local env="$1"
    validate_env "$env" || exit 1

    if [[ "$env" == "vm" ]]; then
        header "Deploying to VM Environment"
        cd "$PROJECT_ROOT/$VM_DIR"
        vagrant up --provision
        success "VM provisioned"
    else
        local compose_file
        compose_file=$(get_compose_file "$env")
        header "Deploying $env Environment"

        cd "$PROJECT_ROOT"
        info "Pulling latest images..."
        docker_compose "$compose_file" pull

        info "Starting services..."
        docker_compose "$compose_file" up -d

        success "Deployment complete"
        echo ""
        info "Services starting... Java backends take 2-3 minutes to initialize"
        info "Run: ./scripts/ops.sh health $env"
    fi
}

cmd_cleanup() {
    header "Docker Cleanup"

    info "Removing stopped containers..."
    docker container prune -f

    info "Removing dangling images..."
    docker image prune -f

    info "Removing unused networks..."
    docker network prune -f

    success "Cleanup complete"

    echo -e "\n${BOLD}Disk Usage:${NC}"
    docker system df
}

# ===========================================
# MAIN
# ===========================================
main() {
    # Check Docker is running (except for help)
    if [[ "${1:-}" != "--help" && "${1:-}" != "-h" && "${1:-}" != "help" ]]; then
        if ! is_docker_running; then
            error "Docker is not running"
            exit 1
        fi
    fi

    local command="${1:-}"
    shift || true

    case "$command" in
        start)   cmd_start "$@" ;;
        stop)    cmd_stop "$@" ;;
        restart) cmd_restart "$@" ;;
        status)  cmd_status "$@" ;;
        logs)    cmd_logs "$@" ;;
        health)  cmd_health "$@" ;;
        deploy)  cmd_deploy "$@" ;;
        cleanup) cmd_cleanup ;;
        help|--help|-h|"")
            show_help
            ;;
        *)
            error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
