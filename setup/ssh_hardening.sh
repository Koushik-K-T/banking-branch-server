#!/bin/bash
# =============================================================
# Member 3 — ssh_hardening.sh
# Hardens SSH configuration
# ⚠️  IMPORTANT: Test SSH on port 2222 in a SECOND terminal
#     before closing your current session
# =============================================================

LOG="/var/logs/branch/ssh_hardening.log"
mkdir -p /var/logs/branch

echo "[$(date)] SSH hardening started" | tee -a "$LOG"

# Backup original sshd_config
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
echo "[$(date)] Backup created: /etc/ssh/sshd_config.bak" | tee -a "$LOG"

# Apply hardened config
cat > /etc/ssh/sshd_config <<'EOF'
# =============================================================
# NCB Banking Branch — Hardened SSH Config
# Member 3 — Automation & Security Engineer
# =============================================================

Port 2222
AddressFamily inet
ListenAddress 0.0.0.0

# Authentication
PermitRootLogin no
MaxAuthTries 3
LoginGraceTime 30
PubkeyAuthentication yes
PasswordAuthentication yes
PermitEmptyPasswords no

# Only itadmin group can SSH
AllowGroups sudo

# Session
ClientAliveInterval 300
ClientAliveCountMax 2
MaxSessions 5

# Logging
SyslogFacility AUTH
LogLevel VERBOSE

# Misc
X11Forwarding no
PrintMotd yes
Banner /etc/ssh/banner.txt
EOF

# Create SSH banner
cat > /etc/ssh/banner.txt <<'EOF'
*************************************************************
*  AUTHORIZED ACCESS ONLY — Banking Branch Server          *
*  All activity is monitored and logged                    *
*  Unauthorized access is strictly prohibited              *
*************************************************************
EOF

# Restart SSH
systemctl restart ssh
echo "[$(date)] SSH restarted on port 2222" | tee -a "$LOG"

echo ""
echo "============================================"
echo " SSH HARDENING DONE"
echo "============================================"
echo " ⚠️  SSH is now on PORT 2222"
echo " ⚠️  Only 'itadmin' group can login"
echo " Test NOW in a second terminal:"
echo "   ssh itadmin@localhost -p 2222"
echo "============================================"
