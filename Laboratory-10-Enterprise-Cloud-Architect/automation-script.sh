#!/bin/bash
# =============================================================================
# StratusForge Systems - Automated Disaster Recovery Script
# Purpose : Nightly backup of MariaDB database + Nextcloud data, with rotation
#           and basic health checks. Logs every run for audit trail.
# Author  : Enterprise Cloud Architect
# Schedule: Executed by cron (see operational-manual.md).
# =============================================================================

set -euo pipefail

# ---- CONFIGURATION ----------------------------------------------------------
STACK_DIR="/opt/stratusforge"
BACKUP_DIR="/var/backups/stratusforge"
LOG_FILE="/var/log/stratusforge-backup.log"
RETENTION_DAYS=7
TIMESTAMP="$(date +%Y-%m-%d_%H-%M-%S)"
DB_CONTAINER="stratusforge_db"
NC_VOLUME="laboratory-10-enterprise-cloud-architect_nc_data"

# ---- HELPERS ----------------------------------------------------------------
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }
die() { log "ERROR: $*"; exit 1; }

# ---- PRECHECKS --------------------------------------------------------------
mkdir -p "$BACKUP_DIR"
touch "$LOG_FILE"
log "=== Starting StratusForge backup run ==="

command -v docker >/dev/null 2>&1 || die "Docker is not installed."

if ! docker ps --format '{{.Names}}' | grep -q "^${DB_CONTAINER}$"; then
    die "Database container '${DB_CONTAINER}' is not running."
fi

# Load env (same file docker-compose uses)
# shellcheck disable=SC1091
source "${STACK_DIR}/.env"

# ---- 1. MARIADB DUMP --------------------------------------------------------
DB_FILE="${BACKUP_DIR}/db_${TIMESTAMP}.sql.gz"
log "Dumping MariaDB database to ${DB_FILE}"

docker exec "$DB_CONTAINER" \
    mariadb-dump -u root -p"$MARIADB_ROOT_PASSWORD" --all-databases --single-transaction --quick \
    | gzip > "$DB_FILE"

[[ -s "$DB_FILE" ]] || die "Database dump is empty."

# ---- 2. NEXTCLOUD DATA ARCHIVE ---------------------------------------------
NC_FILE="${BACKUP_DIR}/nc_${TIMESTAMP}.tar.gz"
log "Archiving Nextcloud data volume to ${NC_FILE}"

docker run --rm \
    -v "${NC_VOLUME}:/source:ro" \
    -v "${BACKUP_DIR}:/backup" \
    alpine:3.20 \
    tar -czf "/backup/nc_${TIMESTAMP}.tar.gz" -C /source .

[[ -s "$NC_FILE" ]] || die "Nextcloud archive is empty."

# ---- 3. HEALTH CHECK --------------------------------------------------------
if curl -fsS -o /dev/null http://localhost:3000; then
    log "Health check: Nextcloud is responding on :3000 (OK)"
else
    log "WARNING: Nextcloud did not respond on :3000"
fi

# ---- 4. ROTATION ------------------------------------------------------------
log "Rotating backups older than ${RETENTION_DAYS} days"
find "$BACKUP_DIR" -type f -name "*.gz" -mtime +${RETENTION_DAYS} -print -delete \
    | sed 's/^/   deleted: /' | tee -a "$LOG_FILE" || true

# ---- 5. SUMMARY -------------------------------------------------------------
DB_SIZE=$(du -h "$DB_FILE" | cut -f1)
NC_SIZE=$(du -h "$NC_FILE" | cut -f1)
log "Backup complete. DB=${DB_SIZE}  Nextcloud=${NC_SIZE}"
log "=== Finished StratusForge backup run ==="
exit 0
