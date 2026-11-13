#!/bin/bash
# =============================================================
# Member 1 — Linux System Administrator
# setup.sh — System config, packages, users, groups
# Run as: sudo bash member1/setup.sh
# =============================================================

set -e
LOG="/tmp/member1_setup.log"
echo "[$(date)] Member 1 setup started" | tee -a "$LOG"

# =============================================================
# TASK 1 — SYSTEM CONFIGURATION
# =============================================================

echo "[$(date)] Setting hostname..." | tee -a "$LOG"
hostnamectl set-hostname bank-branch01
echo "127.0.1.1 bank-branch01" >> /etc/hosts

echo "[$(date)] Configuring static IP..." | tee -a "$LOG"
# ⚠️  CHANGE THIS IP to match your network before running
STATIC_IP="192.168.1.100"
GATEWAY="192.168.1.1"
IFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | head -1)

cat > /etc/netplan/00-installer-config.yaml <<EOF
network:
  version: 2
  ethernets:
    ${IFACE}:
      dhcp4: no
      addresses: [${STATIC_IP}/24]
      gateway4: ${GATEWAY}
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
EOF
netplan apply || echo "[WARN] Netplan apply failed — check IP config manually" | tee -a "$LOG"

echo "[$(date)] Updating OS and installing packages..." | tee -a "$LOG"
apt update -y >> "$LOG" 2>&1
apt upgrade -y >> "$LOG" 2>&1
apt install -y openssh-server apache2 curl wget rsync \
  tar gzip vim nano net-tools lvm2 cron ufw cryptsetup acl >> "$LOG" 2>&1

echo "[$(date)] Enabling services..." | tee -a "$LOG"
systemctl enable apache2 ssh cron
systemctl start  apache2 ssh cron

# =============================================================
# TASK 2 — USER & GROUP ADMINISTRATION
# =============================================================

echo "[$(date)] Creating groups..." | tee -a "$LOG"
for grp in employees managers auditors; do
  groupadd "$grp" 2>/dev/null && echo "  Created group: $grp" | tee -a "$LOG" \
    || echo "  Group already exists: $grp" | tee -a "$LOG"
done

echo "[$(date)] Creating users..." | tee -a "$LOG"
declare -A USERS=(
  [emp1]="employees"
  [emp2]="employees"
  [emp3]="employees"
  [mgr1]="managers"
  [mgr2]="managers"
  [audit1]="auditors"
  [audit2]="auditors"
  [itadmin]="sudo"
)

for user in "${!USERS[@]}"; do
  group="${USERS[$user]}"
  if id "$user" &>/dev/null; then
    echo "  User already exists: $user" | tee -a "$LOG"
  else
    useradd -m -s /bin/bash -G "$group" "$user"
    echo "$user:Branch@2024" | chpasswd
    chage -d 0  "$user"    # force password change on first login
    chage -I 45 "$user"    # lock after 45 days inactivity
    echo "  Created: $user (group: $group)" | tee -a "$LOG"
  fi
done

echo "[$(date)] Creating log directory..." | tee -a "$LOG"
mkdir -p /var/logs/branch
chown root:itadmin /var/logs/branch 2>/dev/null || true
chmod 700 /var/logs/branch

echo "[$(date)] Member 1 setup complete." | tee -a "$LOG"
echo ""
echo "============================================"
echo " MEMBER 1 DONE — Verification:"
echo "============================================"
echo " Hostname  : $(hostname)"
echo " Services  : $(systemctl is-active apache2) apache2 | $(systemctl is-active ssh) ssh | $(systemctl is-active cron) cron"
echo " Users     : $(awk -F: '$3>=1000 && $1!="nobody"{print $1}' /etc/passwd | tr '\n' ' ')"
echo " Groups    : $(getent group employees managers auditors | awk -F: '{print $1}' | tr '\n' ' ')"
echo "============================================"
echo " ➜ Next: sudo bash member2/lvm_setup.sh"
echo "============================================"
