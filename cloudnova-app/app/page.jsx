async function getStats() {
  try {
    const res = await fetch("http://localhost:3000/api/health", { cache: "no-store" });
    return await res.json();
  } catch {
    return { status: "offline", uptime: 0, containers: 0, backups: 0 };
  }
}

async function getArchitect() {
  try {
    const res = await fetch("http://localhost:3000/api/team", { cache: "no-store" });
    return (await res.json()).members[0];
  } catch {
    return null;
  }
}

export default async function Home() {
  const stats = await getStats();
  const architect = await getArchitect();

  return (
    <main className="container">
      <section className="hero">
        <div>
          <div className="mono">CCM101 · Mission 10 · BSIT Block 4 Section J</div>
          <h1>Stratus<span className="accent">Forge</span><br />Systems</h1>
          <p className="tagline">
            A hardened private-cloud platform. Containerized file storage on
            Ubuntu Server — firewall-enforced, backup-automated, operations-ready.
          </p>
          <div className="stack">
            <span className="tag">Nextcloud</span>
            <span className="tag">MariaDB 11</span>
            <span className="tag">Docker Compose</span>
            <span className="tag">Ubuntu Server</span>
            <span className="tag">UFW</span>
            <span className="tag">Cron</span>
          </div>
        </div>
      </section>

      <div className="section-title">System Telemetry</div>
      <section className="grid">
        <div className="panel">
          <div className="panel-header"><h3>Status</h3></div>
          <div className="metric">
            <div className="value">OK</div>
            <div className="indicator"><span className="dot"></span> all services nominal</div>
          </div>
        </div>
        <div className="panel">
          <div className="panel-header"><h3>Containers</h3></div>
          <div className="metric">
            <div className="value">{stats.containers ?? 2}<span className="unit">running</span></div>
            <div className="indicator"><span className="dot"></span> web + db healthy</div>
          </div>
        </div>
        <div className="panel">
          <div className="panel-header"><h3>Firewall</h3></div>
          <div className="metric">
            <div className="value">UFW</div>
            <div className="indicator"><span className="dot"></span> default deny enforced</div>
          </div>
        </div>
        <div className="panel">
          <div className="panel-header"><h3>Backup Window</h3></div>
          <div className="metric">
            <div className="value">02:00</div>
            <div className="indicator"><span className="dot"></span> nightly, {stats.backups ?? 7}d rotation</div>
          </div>
        </div>
      </section>

      <div className="section-title">Enterprise Cloud Architect</div>
      {architect && (
        <section className="architect-card">
          <div className="sigil">{architect.name.split(" ").map(n => n[0]).slice(0, 2).join("")}</div>
          <div>
            <div className="name">{architect.name}</div>
            <div className="title">{architect.role}</div>
            <div className="meta">
              Sole architect, deployer, and operator of the StratusForge platform.
              Delivered against CloudNova Technologies' Mission 10 brief under
              Instructor Jenkielyn C. Torres.
            </div>
          </div>
        </section>
      )}

      <footer className="footer">
        [stratusforge:runtime] &nbsp;·&nbsp; <code>GET /api/health</code> &nbsp; <code>GET /api/team</code> &nbsp;·&nbsp; November 2026
      </footer>
    </main>
  );
}
