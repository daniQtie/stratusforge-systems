# StratusForge Systems

Private-cloud platform for CCM101 Mission 10 — Enterprise Cloud Architect.

**Architect:** Agustin · BSIT Block 4 Section J
**Stack:** Nextcloud + MariaDB on Ubuntu Server, hardened with UFW, automated via Bash + Cron.

## Folders
- `Laboratory-10-Enterprise-Cloud-Architect/` — submission files
- `cloudnova-app/` — web application source + Docker setup
- `VIDEO-SCRIPT.md` — presentation rehearsal script

## Quick Deploy
```bash
git clone https://github.com/daniQtie/stratusforge-systems.git
cd stratusforge-systems/cloudnova-app
chmod +x deploy.sh backup.sh
./deploy.sh
```
