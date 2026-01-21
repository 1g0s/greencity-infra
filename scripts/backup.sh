#!/bin/bash
# backup.sh - GreenCity PostgreSQL Backup
# Creates compressed SQL dumps of the database

set -e

# ===========================================
# SETUP
# ===========================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source common functions
source "$SCRIPT_DIR/lib/common.sh"

# ===========================================
# CONFIGURATION
# ===========================================
ENV="${1:-lb}"
BACKUP_DIR="$PROJECT_ROOT/backups"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
DB_NAME="greencity"
DB_USER="greencity"  # Default from docker-compose

# ===========================================
# HELP
# ===========================================
show_help() {
    cat << EOF
${BOLD}GreenCity PostgreSQL Backup${NC}

${CYAN}Usage:${NC}
  ./scripts/backup.sh [environment]

${CYAN}Environments:${NC}
  prod    Backup from greencity-postgres
  lb      Backup from greencity-postgres-lb (default)
  vm      Backup from VM's PostgreSQL container

${CYAN}Output:${NC}
  backups/greencity-YYYYMMDD-HHMMSS.sql.gz

${CYAN}Examples:${NC}
  ./scripts/backup.sh           # Backup from lb
  ./scripts/backup.sh prod      # Backup from prod
  ./scripts/backup.sh vm        # Backup from VM

EOF
}

# ===========================================
# BACKUP FUNCTION
# ===========================================
do_backup() {
    validate_env "$ENV" || exit 1

    header "PostgreSQL Backup ($ENV)"

    # Create backup directory if needed
    mkdir -p "$BACKUP_DIR"

    # Get container name
    local container
    container=$(get_postgres_container "$ENV")

    # Backup filename
    local backup_file="$BACKUP_DIR/greencity-${TIMESTAMP}.sql.gz"

    info "Container: $container"
    info "Database: $DB_NAME"
    info "Output: $backup_file"
    echo ""

    if [[ "$ENV" == "vm" ]]; then
        # VM backup via SSH
        if ! vm_is_running "$PROJECT_ROOT"; then
            error "VM is not running"
            exit 1
        fi

        info "Creating backup via VM SSH..."
        cd "$PROJECT_ROOT/$VM_DIR"
        vagrant ssh -c "docker exec $container pg_dump -U $DB_USER -d $DB_NAME" 2>/dev/null \
            | gzip > "$backup_file"
    else
        # Local Docker backup
        if ! container_running "$container"; then
            error "Container $container is not running"
            exit 1
        fi

        info "Creating backup..."
        docker exec "$container" pg_dump -U "$DB_USER" -d "$DB_NAME" \
            | gzip > "$backup_file"
    fi

    # Verify backup
    if [[ -f "$backup_file" ]]; then
        local size
        size=$(du -h "$backup_file" | cut -f1)
        success "Backup created: $backup_file ($size)"

        # Show backup count
        local count
        count=$(find "$BACKUP_DIR" -name "greencity-*.sql.gz" | wc -l)
        info "Total backups: $count"
    else
        error "Backup failed"
        exit 1
    fi
}

# ===========================================
# MAIN
# ===========================================
main() {
    case "${1:-}" in
        --help|-h|help)
            show_help
            exit 0
            ;;
    esac

    do_backup
}

main "$@"
