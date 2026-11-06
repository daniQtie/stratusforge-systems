#!/bin/bash
# StratusForge Systems — nightly MariaDB + Nextcloud backup with 7-day rotation
set -euo pipefail

STACK_DIR="${STACK_DIR:-/opt/stratusforge}"
BACKUP_DIR="/var/backups/stratusforge"
LOG_FILE="/var/log/stratusforge-backup.log"
RETENTION_DAYS=7
TIMESTAMP="$(date +%Y-%m-%d_%H-%M-%S)"
DB_CONTAINER="stratusforge_db"
WEB_CONTAINER="stratusforge_web"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }
die() { log "ERROR: $*"; exit 1; }

mkdir -p "$BACKUP_DIR"; touch "$LOG_FILE"
log "=== Starting StratusForge backup run ==="

command -v docker >/dev/null 2>&1 || die "Docker is not installed."
docker ps --format '{{.Names}}' | grep -q "^${DB_CONTAINER}$" || die "DB container not running."

# shellcheck disable=SC1091
[ -f "${STACK_DIR}/.env" ] && source "${STACK_DIR}/.env"
: "${MARIADB_ROOT_PASSWORD:=RootP@ss_2026}"

DB_FILE="${BACKUP_DIR}/db_${TIMESTAMP}.sql.gz"
log "Dumping MariaDB to ${DB_FILE}"
docker exec "$DB_CONTAINER" mariadb-dump -u root -p"$MARIADB_ROOT_PASSWORD" \
    --all-databases --single-transaction --quick | gzip > "$DB_FILE"
[[ -s "$DB_FILE" ]] || die "Database dump is empty."

NC_FILE="${BACKUP_DIR}/nc_${TIMESTAMP}.tar.gz"
log "Archiving Nextcloud config + data to ${NC_FILE}"
docker exec "$WEB_CONTAINER" tar -czf - -C /var/www/html config data 2>/dev/null > "$NC_FILE" || true

if curl -fsS -o /dev/null http://localhost:3000/status.php; then
    log "Health check: Nextcloud is responding on :3000 (OK)"
else
    log "WARNING: Nextcloud did not respond on :3000"
fi

log "Rotating backups older than ${RETENTION_DAYS} days"
find "$BACKUP_DIR" -type f -name "*.gz" -mtime +${RETENTION_DAYS} -print -delete \
    | sed 's/^/   deleted: /' | tee -a "$LOG_FILE" || true

log "Backup complete. DB=$(du -h "$DB_FILE" | cut -f1)  Nextcloud=$(du -h "$NC_FILE" | cut -f1)"
log "=== Finished StratusForge backup run ==="
