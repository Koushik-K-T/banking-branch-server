#!/bin/bash
# =============================================================
# Member 3 — cron_setup.sh
# Deploys all scripts to /scripts/ and registers cron jobs
# Run AFTER setup/lvm_setup.sh
# Usage: sudo bash setup/cron_setup.sh
# =============================================================

set -e
LOG="/var/logs/branch/cron_setup.log"
mkdir -p /var/logs/branch /scripts
echo "[$(date)] Member 3 setup started" | tee -a "$LOG"

# Detect project root (works from any directory)
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "[$(date)] Deploying scripts to /scripts/..." | tee -a "$LOG"
cp "$SCRIPT_DIR/setup/new_user.sh"      /scripts/
cp "$SCRIPT_DIR/scripts/bank_backup.sh"   /scripts/
cp "$SCRIPT_DIR/scripts/audit_logger.sh"  /scripts/
cp "$SCRIPT_DIR/scripts/audit_report.sh"  /scripts/
cp "$SCRIPT_DIR/scripts/branch_health.sh" /scripts/

chmod +x /scripts/*.sh
echo "[$(date)] All scripts made executable" | tee -a "$LOG"

echo "[$(date)] Registering cron jobs..." | tee -a "$LOG"

# Write cron file
cat > /etc/cron.d/banking-branch <<'EOF'
# ============================================================
# Banking Branch Server — Cron Schedule
# Member 3 — Automation & Security Engineer
# ============================================================
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Audit log every minute
* * * * * root /scripts/audit_logger.sh >> /var/logs/branch/cron.log 2>&1

# Daily audit report at 6:00 PM
0 18 * * * root /scripts/audit_report.sh >> /var/logs/branch/cron.log 2>&1

# Hourly health monitor
0 * * * * root /scripts/branch_health.sh >> /var/logs/branch/cron.log 2>&1

# Nightly backup at 11:30 PM
30 23 * * * root /scripts/bank_backup.sh >> /var/logs/branch/cron.log 2>&1
EOF

chmod 644 /etc/cron.d/banking-branch
systemctl restart cron
echo "[$(date)] Cron jobs registered at /etc/cron.d/banking-branch" | tee -a "$LOG"

echo "[$(date)] Running SSH hardening..." | tee -a "$LOG"
bash "$SCRIPT_DIR/setup/ssh_hardening.sh" | tee -a "$LOG"

echo "[$(date)] Member 3 setup complete." | tee -a "$LOG"
echo ""
echo "============================================"
echo " MEMBER 3 DONE — Verification:"
echo "============================================"
echo " Cron jobs:"
cat /etc/cron.d/banking-branch
echo ""
echo " Scripts in /scripts/:"
ls -la /scripts/
echo "============================================"
echo " ➜ Next: sudo bash docs/test_all.sh"
echo "============================================"
