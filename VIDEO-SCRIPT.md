# StratusForge Systems — Video Presentation Script

**Project:** CCM101 Mission 10 — Enterprise Cloud Architect
**Architect:** Agustin (solo) — BSIT Block 4 Section J
**Application Stack:** Nextcloud + MariaDB
**Target length:** 3 minutes
**Format:** Screen recording + voiceover

---

---

## 🎬 Pre-Recording Setup

Buksan **https://killercoda.com/playgrounds/scenario/ubuntu**, click START, tapos:

```bash
git clone https://github.com/daniQtie/stratusforge-systems.git
cd stratusforge-systems/stratusforge-app
chmod +x deploy.sh backup.sh
./deploy.sh
```

Hintayin "Deployment complete" (1–3 min kasi nag-i-install pa si Nextcloud) bago mag-record.

---

## 🎬 SCENE 1 — Intro + Architecture (30 sec)

**Ipakita:** `architecture-diagram.svg` (from GitHub)

### Script
> "Good day po, Ma'am Torres. I'm Agustin from BSIT Block 4 Section J, and this is my
> submission for Mission 10 — StratusForge Systems.
>
> Nag-design ako ng secure, multi-tier private-cloud platform using **Nextcloud + MariaDB**,
> running on Ubuntu Server, containerized with Docker, protected by UFW firewall, at
> automated via Bash plus Cron."

---

## 🎬 SCENE 2 — Deployment Proof (50 sec)

**Ipakita:** KillerCoda terminal

### Commands
```bash
sudo docker compose ps
sudo docker volume ls | grep -E "nc_data|mariadb_data"
```

### Expected output
```
NAME               IMAGE                 STATUS            PORTS
stratusforge_db    mariadb:11            Up (healthy)      3306/tcp
stratusforge_web   nextcloud:29-apache   Up                0.0.0.0:3000->80/tcp

local   stratusforge-app_mariadb_data
local   stratusforge-app_nc_data
```

Tapos buksan ang port 3000 sa KillerCoda ("+" → Select port → `3000`) para ipakita ang **Nextcloud login page**. Pwede pang mag-login (`admin` / password sa `.env`) para makita ang Files dashboard.

### Script
> "Dito sa `docker compose ps`, nakikita niyo dalawang containers na tumatakbo —
> ang `stratusforge_db` na database, at `stratusforge_web` na application. Pareho silang healthy.
>
> Only port 3000 ang exposed externally. Yung database port 3306 hindi na-publish —
> internal lang sa Docker network for security.
>
> At sa baba, nakikita ang persistent volume na `nc_data` — dito nakatago ang user files,
> at nabubuhay kahit i-reboot ang server. At eto ang live Nextcloud login page namin."

---

## 🎬 SCENE 3 — Security (UFW) (30 sec)

**Ipakita:** KillerCoda terminal

### Command
```bash
sudo ufw status verbose
```

### Expected output
```
Status: active
Default: deny (incoming), allow (outgoing)

22/tcp         ALLOW IN    Anywhere        # SSH
3000/tcp       ALLOW IN    Anywhere        # web
```

### Script
> "Para sa security, gumamit ako ng UFW — host-based firewall. **Default deny incoming** —
> bawal lahat ng traffic by default. Dalawang ports lang ang bukas: port 22 for SSH remote
> administration, at port 3000 for the Nextcloud web interface. Lahat ng iba — blocked."

---

## 🎬 SCENE 4 — Automation (40 sec)

**Ipakita:** KillerCoda terminal

### Commands
```bash
sudo crontab -l
sudo STACK_DIR=$(pwd) /usr/local/bin/stratusforge-backup.sh
ls -lh /var/backups/stratusforge/
```

### Expected output
```
0 2 * * *  STACK_DIR=... /usr/local/bin/stratusforge-backup.sh >> /var/log/stratusforge-backup.log 2>&1

[... ] === Starting StratusForge backup run ===
[... ] Dumping MariaDB to /var/backups/stratusforge/db_....sql.gz
[... ] Health check: Nextcloud is responding on :3000 (OK)
[... ] Backup complete. DB=...  Nextcloud=...
[... ] === Finished StratusForge backup run ===

-rw-r--r-- 1 root root ...  db_....sql.gz
-rw-r--r-- 1 root root ...  nc_....tar.gz
```

### Script
> "Para hindi na manu-manong i-backup, gumawa ako ng Bash script na nag-dump ng database,
> nag-archive ng Nextcloud data, nag-health check, at nag-r-rotate ng backups na lampas 7 days.
>
> Nasa cron schedule — tumatakbo automatically araw-araw ng alas-dos ng umaga. Dito sa
> `/var/backups/` nakikita niyo yung mga existing backup files. Lahat ng runs naka-log."

---

## 🎬 SCENE 5 — Closing (20 sec)

**Ipakita:** GitHub repo page

### Script
> "Lahat ng code, scripts, diagram, at operational manual na-commit sa GitHub.
> Nakatugon ako sa lahat ng 5 requirements — architecture, multi-tier deployment with
> persistent storage, UFW firewall, Bash plus Cron automation, at complete documentation.
>
> Salamat po, Ma'am Torres. This is StratusForge Systems."

---

## 📝 Post-Recording
- [ ] Trim ng dead spaces
- [ ] Add intro title: "StratusForge Systems — Agustin — BSIT Block 4 Section J"
- [ ] Export MP4 1080p
- [ ] Upload / submit

---

## 💡 Tips
- Terminal zoom (Ctrl + +) sa KillerCoda browser for readable text
- Mag-rehearse muna nang hindi nag-rere-record

---

## 🎯 Rubric Coverage

| Requirement | Scene |
|---|---|
| 1. Architecture + VM | Scene 1 + 2 |
| 2. Multi-tier + persistent volume | Scene 2 |
| 3. UFW default deny | Scene 3 |
| 4. Bash + Cron | Scene 4 |
| 5. Documentation | Scene 5 |

**~3 minutes total. Pasado sa rubric. Good luck, Agustin! 🚀**
