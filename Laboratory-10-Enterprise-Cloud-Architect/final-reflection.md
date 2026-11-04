# Final Reflection — From Trainee to Architect

## The Solo Journey Through StratusForge

Ten missions ago, I treated the server as something other people ran. Today I built one, hardened it, automated it, and defended it alone. This reflection ties that arc together.

### Missions 1–3 — The Terminal Becomes a Workbench
The early labs stripped away the mystique. The cloud, up close, is just **Linux, networking, and consistent habits**. I learned to move around a filesystem, to pipe one tool into another, and to respect what a wrong `sudo` can do. Those lessons quietly carried the rest of the course.

### Missions 4–6 — Thinking in Isolation
Virtualization introduced the single most important mental model I use now: **isolation as a design primitive**. An operating system can live inside another; that boundary is where safety begins. Package management, services, and SSH took the terminal from obstacle to tool.

### Missions 7–9 — Declaring Infrastructure
This is where I stopped *installing* software and started *declaring* it. Docker turned a long README into a one-line `docker compose up`. Bash plus cron turned manual chores into reliable ones. UFW taught me that a firewall is not an add-on; it is a stance the server takes.

### Mission 10 — Owning the System
This final mission gave no instructions. There was a brief, a client, and a deadline. I chose the stack — **Nextcloud + MariaDB** — because file collaboration is a real Fortune 500 need and because MariaDB gives me the operational tooling I wanted. I split the services across two Docker networks so the database would never touch the internet. I wrote a backup script with health checks and rotation so the 2 AM run would not wake anyone. I wrote this manual so a new engineer could rebuild everything from the repository.

Every decision was mine to justify. That is the difference between following a tutorial and being the architect.

## Three Lessons I Will Carry Forward

1. **Infrastructure is code.** If it cannot be recreated from a git clone, I do not own it — I just happen to be standing near it.
2. **Deny by default.** Firewalls, user permissions, container networks — begin closed and open only what you can explain.
3. **Automation is empathy for your future self.** The backup script is not for the server; it is for the person who would otherwise have to remember.

## Closing Thought

StratusForge is a simulation of a production platform, but the discipline is real. I started this course trying to memorize commands; I am ending it trying to **design systems and justify choices**. The commands are tools. The architecture is the craft.

I did not just finish Mission 10. I signed my name to a system I built and can defend.

— *Agustin, Enterprise Cloud Architect*
