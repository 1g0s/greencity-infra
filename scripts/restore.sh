#!/bin/bash
# restore.sh - GreenCity PostgreSQL Restore
# Restores database from backup file

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
BACKUP_FILE="${1:-}"
ENV="${2:-lb}"
DB_NAME="greencity"
DB_USER="greencity"  # Default from docker-compose

# ===========================================
# HELP
# ===========================================
show_help() {
    cat << EOF
${BOLD}GreenCity PostgreSQL Restore${NC}

${CYAN}Usage:${NC}
  ./scripts/restore.sh <backup-file> [environment]

${CYAN}Arguments:${NC}
  backup-file    Path to backup file (.sql.gz)
  environment    Target environment (prod|lb|vm), default: lb

${CYAN}Examples:${NC}
  ./scripts/restore.sh backups/greencity-20260114-153000.sql.gz
  ./scripts/restore.sh backups/greencity-20260114-153000.sql.gz prod

${CYAN}Available Backups:${NC}
$(ls -1 "$PROJECT_ROOT/backups/"*.sql.gz 2>/dev/null | head -10 || echo "  No backups found")

${YELLOW}Warning:${NC}
  This will overwrite existing data in the target database!
  Liquibase will apply any pending migrations on backend restart.

EOF
}

# ===========================================
# RESTORE FUNCTION
# ===========================================
do_restore() {
    # Validate backup file
    if [[ -z "$BACKUP_FILE" ]]; then
        error "Backup file required"
        show_help
        exit 1
    fi

    # Handle relative paths
    if [[ ! "$BACKUP_FILE" = /* ]]; then
        BACKUP_FILE="$PROJECT_ROOT/$BACKUP_FILE"
    fi

    if [[ ! -f "$BACKUP_FILE" ]]; then
        error "Backup file not found: $BACKUP_FILE"
        exit 1
    fi

    validate_env "$ENV" || exit 1

    header "PostgreSQL Restore ($ENV)"

    # Get container name
    local container
    container=$(get_postgres_container "$ENV")

    info "Backup file: $BACKUP_FILE"
    info "Container: $container"
    info "Database: $DB_NAME"
    echo ""

    # Confirmation
    warn "This will OVERWRITE existing data in $DB_NAME database!"
    echo -n "Continue? [y/N] "
    read -r confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        info "Restore cancelled"
        exit 0
    fi

    echo ""

    if [[ "$ENV" == "vm" ]]; then
        # VM restore via SSH
        if ! vm_is_running "$PROJECT_ROOT"; then
            error "VM is not running"
            exit 1
        fi

        info "Restoring via VM SSH..."
        cd "$PROJECT_ROOT/$VM_DIR"

        # Copy backup to VM and restore
        gunzip -c "$BACKUP_FILE" | vagrant ssh -c "docker exec -i $container psql -U $DB_USER -d $DB_NAME" 2>/dev/null
    else
        # Local Docker restore
        if ! container_running "$container"; then
            error "Container $container is not running"
            exit 1
        fi

        info "Restoring database..."
        gunzip -c "$BACKUP_FILE" | docker exec -i "$container" psql -U "$DB_USER" -d "$DB_NAME"
    fi

    if [[ $? -eq 0 ]]; then
        success "Restore completed"
        echo ""
        info "Note: Restart backends to apply Liquibase migrations"
        info "Run: ./scripts/ops.sh restart $ENV"
    else
        error "Restore failed"
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

    do_restore
}

main "$@"
