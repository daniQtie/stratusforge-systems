# CCM101 – Cloud Computing
## Enterprise Cloud Architect – Operational Manual

**Project:** StratusForge Systems — Private Cloud Platform
**Application Stack:** Nextcloud + MariaDB
**Prepared by:** Agustin
**Section:** BSIT Block 4 Section J
**Instructor:** Jenkielyn C. Torres
**Date:** November 2026

---

## 1. Executive Summary

This manual documents the design, deployment, hardening, and day-two operations of **StratusForge Systems** — a private-cloud file-collaboration platform delivered for the Fortune 500 client. The platform runs a **two-tier containerized Nextcloud stack** (Nextcloud 29 + MariaDB 11) on a hardened **Ubuntu Server** virtual machine. Data persistence is guaranteed through named Docker volumes, perimeter security through **UFW** with a default-deny policy, and operational resilience through a scheduled **Bash + Cron** backup pipeline with 7-day rotation.

The design satisfies every requirement laid down in Mission 10: planned architecture, multi-tier deployment, persistent storage, firewall hardening, autonomous automation, and executive-grade documentation.

---

## 2. Architecture Overview

See `architecture-diagram.svg` in this folder.

| Layer | Component | Purpose |
|---|---|---|
| Host | Admin Workstation | Developer workstation (browser, SSH) |
| Hypervisor | VirtualBox / VMware (Type-2) | Isolates the server from the host |
| Guest OS | Ubuntu Server 24.04 LTS | Minimal headless Linux |
| Firewall | UFW (host-based) | Default DENY; allows only 22, 3000 |
| Runtime | Docker Engine + Compose v2 | Container orchestration |
| App Tier | `nextcloud:29-apache` | File sync + collaboration platform |
| Data Tier | `mariadb:11` | Relational database |
| Storage | Docker named volumes `nc_data`, `mariadb_data` | Survives reboots |
| Automation | Bash + cron | Nightly backup, log, rotate |

### Network Flow
`Browser :3000` → `UFW` → `Host port 3000` → `Nextcloud container :80` → `MariaDB container :3306` (internal only).
Port 3306 is **never** exposed to the host.

---

## 3. Pre-Deployment Checklist

- [ ] Hypervisor installed (VirtualBox 7+ or VMware Workstation) — or a browser-based Ubuntu playground such as KillerCoda
- [ ] Ubuntu Server 24.04 LTS ISO available (or already provisioned)
- [ ] 2 vCPU, 4 GB RAM, 20 GB disk provisioned
- [ ] Network adapter: **Bridged** or **Host-Only** (static IP `192.168.56.10` recommended)
- [ ] SSH enabled
- [ ] Non-root admin user created (`admin`)
- [ ] GitHub repository cloned on the VM

---

## 4. Deployment Procedure

### 4.1 Prepare the VM
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git ufw ca-certificates gnupg
```

### 4.2 Install Docker Engine + Compose
```bash
# Install using the official convenience script
curl -fsSL https://get.docker.com | sudo sh

# Verify
docker --version
docker compose version
```

### 4.3 Deploy the Stack
```bash
sudo mkdir -p /opt/stratusforge
sudo chown $USER:$USER /opt/stratusforge
cd /opt/stratusforge

# Copy docker-compose.yml and .env.example from the GitHub repo
cp .env.example .env
nano .env                      # set strong passwords

sudo docker compose up -d
sudo docker compose ps         # both containers should show "Up (healthy)"
```

Open a browser on the host: `http://192.168.56.10:3000` to access Nextcloud's login page.

### 4.4 Verify Persistent Storage
```bash
sudo docker volume ls | grep -E "nc_data|mariadb_data"
sudo docker compose down       # containers stop
sudo docker compose up -d      # bring back — data must still be present
```

---

## 5. Security Hardening (UFW)

```bash
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp          # SSH
sudo ufw allow 3000/tcp        # Nextcloud
sudo ufw --force enable
sudo ufw status verbose
```

Expected output:
```
Status: active
Default: deny (incoming), allow (outgoing)
22/tcp                     ALLOW IN    Anywhere
3000/tcp                   ALLOW IN    Anywhere
```

Additional hardening performed:
- `PermitRootLogin no` and `PasswordAuthentication no` in `/etc/ssh/sshd_config`
- Automatic security updates: `sudo apt install -y unattended-upgrades`
- `.env` file is `chmod 600` and excluded from git via `.gitignore`
- MariaDB port `3306` is **not** published to the host — only reachable inside the `backend` Docker network.

---

## 6. Automation & Disaster Recovery

### 6.1 Install the Backup Script
```bash
sudo cp automation-script.sh /usr/local/bin/stratusforge-backup.sh
sudo chmod +x /usr/local/bin/stratusforge-backup.sh
sudo mkdir -p /var/backups/stratusforge
sudo touch /var/log/stratusforge-backup.log
```

### 6.2 Schedule with Cron
Edit root's crontab:
```bash
sudo crontab -e
```
Add:
```
# StratusForge nightly backup at 02:00
0 2 * * *  /usr/local/bin/stratusforge-backup.sh >> /var/log/stratusforge-backup.log 2>&1
```

### 6.3 Verify
```bash
sudo /usr/local/bin/stratusforge-backup.sh    # manual trigger
ls -lh /var/backups/stratusforge/
tail -n 20 /var/log/stratusforge-backup.log
```

What the script does, step by step:
1. Confirms Docker and the MariaDB container are up.
2. Runs `mariadb-dump --all-databases --single-transaction`, gzips the output.
3. `tar`s the `nc_data` volume (user files, apps, config).
4. Hits `http://localhost:3000` for a health check.
5. Deletes any backup older than **7 days**.
6. Logs size + timestamp of every run.

### 6.4 Restore Procedure (should disaster strike)
```bash
# 1. Stop the stack
cd /opt/stratusforge && sudo docker compose down

# 2. Restore DB
gunzip < /var/backups/stratusforge/db_<timestamp>.sql.gz \
  | sudo docker exec -i stratusforge_db mariadb -u root -p"$MARIADB_ROOT_PASSWORD"

# 3. Restore Nextcloud data
sudo docker run --rm \
  -v laboratory-10-enterprise-cloud-architect_nc_data:/target \
  -v /var/backups/stratusforge:/backup alpine:3.20 \
  sh -c "cd /target && tar -xzf /backup/nc_<timestamp>.tar.gz"

# 4. Start again
sudo docker compose up -d
```

---

## 7. Day-Two Operations Cheat Sheet

| Task | Command |
|---|---|
| View running containers | `sudo docker compose ps` |
| Tail Nextcloud logs | `sudo docker compose logs -f web` |
| Tail DB logs | `sudo docker compose logs -f db` |
| Restart stack | `sudo docker compose restart` |
| Update images | `sudo docker compose pull && sudo docker compose up -d` |
| Enter Nextcloud OCC CLI | `sudo docker exec -u www-data -it stratusforge_web php occ status` |
| Disk use | `df -h && sudo docker system df` |
| Firewall status | `sudo ufw status numbered` |
| List backups | `ls -lh /var/backups/stratusforge/` |
| Last backup log | `tail -n 50 /var/log/stratusforge-backup.log` |

---

## 8. Troubleshooting Playbook

| Symptom | Likely Cause | Remedy |
|---|---|---|
| Browser can't reach `:3000` | UFW blocking / wrong IP | `sudo ufw status`, check VM IP with `ip a` |
| "Untrusted domain" page | Hostname not whitelisted | Add to `NEXTCLOUD_TRUSTED_DOMAINS` env var |
| DB connection error | DB container not healthy | `sudo docker compose logs db` — usually wrong `.env` password |
| Disk filling up | Old backups not rotated | Check `RETENTION_DAYS`, cron timing |
| Cron job never ran | Not in root's crontab | `sudo crontab -l`, check `/var/log/syslog` |
| Lost admin password | — | `sudo docker exec -u www-data -it stratusforge_web php occ user:resetpassword admin` |

---

## 9. Live Defense Deployment (KillerCoda / Fresh Instance)

In a brand-new Ubuntu shell, the entire stack can be rebuilt in under 5 minutes:
```bash
git clone https://github.com/<your-user>/CCM101-jentorres.git
cd CCM101-jentorres/Laboratory-10-Enterprise-Cloud-Architect
cp .env.example .env
sudo docker compose up -d
```
That single sequence — plus the UFW block and the cron entry — reproduces production.

---

## 10. Sign-off

Prepared and defended by the **Enterprise Cloud Architect**.
_"An Architect does not follow a manual; they write it."_
