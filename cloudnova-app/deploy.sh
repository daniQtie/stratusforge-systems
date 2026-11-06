#!/bin/bash
# =============================================================================
# StratusForge Systems — One-Command Deployment Script
# Target: Fresh Ubuntu instance (KillerCoda, Ubuntu Server, WSL)
# Does: install Docker + Compose + UFW if missing, start Nextcloud + MariaDB,
#       configure firewall, install backup script + cron job.
# =============================================================================

set -e

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'
step() { echo -e "\n${CYAN}==>${NC} ${GREEN}$*${NC}"; }
warn() { echo -e "${YELLOW}!! $*${NC}"; }
STACK_DIR="$(pwd)"

step "Checking Docker"
if ! command -v docker >/dev/null 2>&1; then
    curl -fsSL https://get.docker.com | sh
fi
docker --version

if ! docker compose version >/dev/null 2>&1; then
    step "Installing docker-compose-plugin"
    sudo apt-get update -y
    sudo apt-get install -y docker-compose-plugin || {
        warn "apt install failed; trying standalone binary"
        sudo mkdir -p /usr/local/lib/docker/cli-plugins
        sudo curl -SL \
          https://github.com/docker/compose/releases/download/v2.29.7/docker-compose-linux-x86_64 \
          -o /usr/local/lib/docker/cli-plugins/docker-compose
        sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
    }
fi
docker compose version

if ! command -v ufw >/dev/null 2>&1; then
    step "Installing UFW"
    sudo apt-get update -y
    sudo apt-get install -y ufw
fi

step "Preparing environment"
[ -f .env ] || { cp .env.example .env; warn "Created .env from example — edit passwords before production!"; }

step "Pulling images and starting Nextcloud + MariaDB"
sudo docker compose up -d

step "Waiting for Nextcloud to finish first-time install (1-3 min)"
for i in $(seq 1 60); do
    if curl -fsS http://localhost:3000/status.php 2>/dev/null | grep -q '"installed":true'; then
        echo "Nextcloud is ready."; break
    fi
    sleep 5
done
sudo docker compose ps

step "Configuring UFW firewall"
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp     comment 'SSH'
sudo ufw allow 3000/tcp   comment 'StratusForge Nextcloud'
sudo ufw --force enable
sudo ufw status verbose

step "Installing backup automation"
sudo cp backup.sh /usr/local/bin/stratusforge-backup.sh
sudo chmod +x /usr/local/bin/stratusforge-backup.sh
sudo mkdir -p /var/backups/stratusforge
sudo touch /var/log/stratusforge-backup.log

CRON_LINE="0 2 * * *  STACK_DIR=${STACK_DIR} /usr/local/bin/stratusforge-backup.sh >> /var/log/stratusforge-backup.log 2>&1"
( sudo crontab -l 2>/dev/null | grep -v stratusforge-backup; echo "$CRON_LINE" ) | sudo crontab -
echo "Installed cron entry:"
sudo crontab -l | grep stratusforge

step "Deployment complete"
echo "Nextcloud: http://$(hostname -I | awk '{print $1}'):3000  (login: admin / see .env)"
echo "Logs:      sudo docker compose logs -f"
echo "Backup:    sudo STACK_DIR=${STACK_DIR} /usr/local/bin/stratusforge-backup.sh"
