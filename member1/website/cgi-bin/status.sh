#!/bin/bash
# =============================================================
# Member 1 — cgi-bin/status.sh
# Live server status page served via Apache CGI
# Auto-refreshes every 30 seconds
# =============================================================

echo "Content-type: text/html"
echo ""

cat <<HTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="refresh" content="30">
  <title>Live Status — Banking Branch Server</title>
  <style>
    *{margin:0;padding:0;box-sizing:border-box}
    body{font-family:Arial,sans-serif;background:#f0f4f8;color:#333}
    header{background:#1a3c5e;color:white;padding:20px 40px}
    header h1{font-size:22px}
    header p{font-size:12px;opacity:.8;margin-top:4px}
    nav{background:#2c5f8a;display:flex;flex-wrap:wrap;padding:0 40px}
    nav a{color:white;text-decoration:none;padding:12px 18px;font-size:13px;display:block}
    nav a:hover,nav a.active{background:#1a3c5e}
    .content{padding:30px 40px}
    .grid{display:grid;grid-template-columns:repeat(2,1fr);gap:20px}
    .block{background:white;border-radius:8px;padding:20px;box-shadow:0 2px 6px rgba(0,0,0,.08)}
    .block h3{color:#1a3c5e;margin-bottom:10px;font-size:14px}
    pre{font-size:12px;line-height:1.6;white-space:pre-wrap;word-break:break-all;background:#f9f9f9;padding:10px;border-radius:4px}
    .refresh{font-size:11px;color:#999;margin-top:16px;text-align:right}
    .svc{display:inline-block;padding:3px 10px;border-radius:10px;font-size:12px;font-weight:bold;margin:2px}
    .active{background:#e8f5e9;color:#2e7d32}
    .inactive{background:#ffebee;color:#c62828}
  </style>
</head>
<body>
  <header>
    <h1>🖥️ Live Server Status — bank-branch01</h1>
    <p>Auto-refreshes every 30 seconds · $(date)</p>
  </header>
  <nav>
    <a href="/index.html">Home</a>
    <a href="/employees.html">Employees</a>
    <a href="/audit.html">Audit Logs</a>
    <a href="/reports.html">Reports</a>
    <a href="/backup.html">Backup</a>
    <a href="/security.html">Security</a>
    <a href="/cgi-bin/status.sh" class="active">Live Status</a>
  </nav>
  <div class="content">
    <div class="grid">
      <div class="block">
        <h3>🏷️ Hostname &amp; Uptime</h3>
        <pre>$(hostname && uptime)</pre>
      </div>
      <div class="block">
        <h3>⚙️ Services</h3>
        <p>
HTML

for svc in apache2 ssh cron; do
  status=$(systemctl is-active "$svc" 2>/dev/null)
  cls="inactive"
  [ "$status" = "active" ] && cls="active"
  echo "          <span class=\"svc $cls\">$svc: $status</span>"
done

cat <<HTML
        </p>
      </div>
      <div class="block">
        <h3>💾 Memory Usage</h3>
        <pre>$(free -h)</pre>
      </div>
      <div class="block">
        <h3>💿 Disk Usage</h3>
        <pre>$(df -h | grep -E 'Filesystem|/data|/var/logs/branch|/backup|^/dev')</pre>
      </div>
      <div class="block">
        <h3>👤 Active Sessions</h3>
        <pre>$(who || echo "No active sessions")</pre>
      </div>
      <div class="block">
        <h3>📋 Recent Audit Logs</h3>
        <pre>$(ls -lt /data/audit/AUDIT_*.log 2>/dev/null | head -5 || echo "No audit logs yet")</pre>
      </div>
      <div class="block">
        <h3>🩺 Latest Health Entry</h3>
        <pre>$(tail -8 /var/logs/branch/health_$(date +%Y%m%d).log 2>/dev/null || echo "No health log yet today")</pre>
      </div>
      <div class="block">
        <h3>🔐 Failed Logins (last hour)</h3>
        <pre>$(grep 'Failed password' /var/log/auth.log 2>/dev/null | grep "$(date +'%b %d %H')" || echo "None detected")</pre>
      </div>
    </div>
    <p class="refresh">Page auto-refreshes every 30 seconds</p>
  </div>
</body>
</html>
HTML
