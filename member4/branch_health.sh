#!/bin/bash
# =============================================================
# Member 4 — branch_health.sh
# Hourly system health monitor
# Scheduled via cron: 0 * * * *
# =============================================================

LOG="/var/logs/branch/health_$(date +%Y%m%d).log"
ALERT_DISK=75
ALERT_LOGINS=3
mkdir -p /var/logs/branch

{
  echo "=================================================="
  echo " BANKING BRANCH HEALTH REPORT"
  echo " Time   : $(date)"
  echo " Server : $(hostname)"
  echo "=================================================="

  echo ""
  echo "--- UPTIME & LOAD ---"
  uptime

  echo ""
  echo "--- MEMORY USAGE ---"
  free -h

  echo ""
  echo "--- DISK USAGE ---"
  df -h | grep -E 'Filesystem|/data|/var/logs/branch|/backup|/$'

  echo ""
  echo "--- ACTIVE SESSIONS ---"
  who

  echo ""
  echo "--- RUNNING SERVICES ---"
  for svc in apache2 ssh cron; do
    printf "  %-12s : %s\n" "$svc" "$(systemctl is-active $svc)"
  done

  echo ""
  echo "--- FAILED LOGIN ATTEMPTS (last hour) ---"
  FAILED=$(grep 'Failed password' /var/log/auth.log 2>/dev/null \
    | grep "$(date +'%b %d %H')" | wc -l)
  echo "  Count: $FAILED"

  echo ""
  echo "--- RECENT AUDIT EVENTS ---"
  ls -lt /data/audit/AUDIT_*.log 2>/dev/null | head -5 \
    || echo "  No audit logs yet"

  echo "=================================================="
} >> "$LOG"

# --- ALERTS ---
df -h | grep '/data' | awk '{gsub(/%/,"",$5); print $5, $6}' | while read usage mount; do
  if [ "$usage" -gt "$ALERT_DISK" ]; then
    echo "[ALERT $(date)] DISK ${usage}% on ${mount} — exceeded ${ALERT_DISK}% threshold" >> "$LOG"
  fi
done

FAILED_COUNT=$(grep 'Failed password' /var/log/auth.log 2>/dev/null \
  | grep "$(date +'%b %d %H')" | wc -l)
if [ "$FAILED_COUNT" -gt "$ALERT_LOGINS" ]; then
  echo "[ALERT $(date)] $FAILED_COUNT failed login attempts detected this hour" >> "$LOG"
fi
