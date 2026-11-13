#!/bin/bash
# =============================================================
# Member 2 — Storage & Backup Administrator
# lvm_setup.sh — LVM, mounts, permissions, UFW firewall
# Run AFTER member1/setup.sh
# Usage: sudo bash member2/lvm_setup.sh
# =============================================================

set -e
LOG="/var/logs/branch/member2_setup.log"
mkdir -p /var/logs/branch
echo "[$(date)] Member 2 setup started" | tee -a "$LOG"

# =============================================================
# TASK 3 — LVM STORAGE SETUP
# ⚠️  Run lsblk first — confirm DISK is correct before proceeding
# =============================================================

DISK="/dev/sdb"
echo "[$(date)] Checking disk $DISK..." | tee -a "$LOG"

if [ ! -b "$DISK" ]; then
  echo "ERROR: Disk $DISK not found."
  echo "Run 'lsblk' and update DISK variable in this script."
  exit 1
fi

echo "[$(date)] Creating Physical Volume..." | tee -a "$LOG"
pvcreate "$DISK"

echo "[$(date)] Creating Volume Group vg_branchdata..." | tee -a "$LOG"
vgcreate vg_branchdata "$DISK"

echo "[$(date)] Creating Logical Volumes..." | tee -a "$LOG"
lvcreate -L 10G -n lv_employee vg_branchdata
lvcreate -L 15G -n lv_audit    vg_branchdata
lvcreate -L 8G  -n lv_reports  vg_branchdata
lvcreate -L 5G  -n lv_logs     vg_branchdata

echo "[$(date)] Formatting volumes as ext4..." | tee -a "$LOG"
mkfs.ext4 /dev/vg_branchdata/lv_employee
mkfs.ext4 /dev/vg_branchdata/lv_audit
mkfs.ext4 /dev/vg_branchdata/lv_reports
mkfs.ext4 /dev/vg_branchdata/lv_logs

echo "[$(date)] Creating mount points..." | tee -a "$LOG"
mkdir -p /data/employee /data/audit /data/reports
mkdir -p /var/logs/branch

echo "[$(date)] Mounting volumes..." | tee -a "$LOG"
mount /dev/vg_branchdata/lv_employee /data/employee
mount /dev/vg_branchdata/lv_audit    /data/audit
mount /dev/vg_branchdata/lv_reports  /data/reports
mount /dev/vg_branchdata/lv_logs     /var/logs/branch

echo "[$(date)] Adding fstab entries for persistent mounts..." | tee -a "$LOG"
echo '/dev/vg_branchdata/lv_employee /data/employee ext4 defaults 0 2' >> /etc/fstab
echo '/dev/vg_branchdata/lv_audit    /data/audit    ext4 defaults 0 2' >> /etc/fstab
echo '/dev/vg_branchdata/lv_reports  /data/reports  ext4 defaults 0 2' >> /etc/fstab
echo '/dev/vg_branchdata/lv_logs     /var/logs/branch ext4 defaults 0 2' >> /etc/fstab

# =============================================================
# ASSIGN DIRECTORY PERMISSIONS
# =============================================================

echo "[$(date)] Setting ownership and permissions..." | tee -a "$LOG"

chown root:employees /data/employee
chmod 775 /data/employee
chmod +t  /data/employee

chown root:auditors /data/audit
chmod 770 /data/audit
chmod +t  /data/audit
# managers read-only on audit
setfacl -m g:managers:r-x /data/audit

chown root:managers /data/reports
chmod 770 /data/reports
chmod +t  /data/reports
# auditors read-only on reports
setfacl -m g:auditors:r-x /data/reports

chown root:itadmin /var/logs/branch 2>/dev/null || true
chmod 700 /var/logs/branch

echo "[$(date)] Creating backup directories..." | tee -a "$LOG"
mkdir -p /backup/branch/daily /backup/branch/weekly
chmod 700 /backup/branch

# =============================================================
# UFW FIREWALL
# =============================================================

echo "[$(date)] Configuring UFW firewall..." | tee -a "$LOG"
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 2222/tcp comment 'SSH non-default port'
ufw allow 80/tcp   comment 'Apache HTTP'
ufw --force enable

echo "[$(date)] Member 2 setup complete." | tee -a "$LOG"
echo ""
echo "============================================"
echo " MEMBER 2 DONE — Verification:"
echo "============================================"
df -h | grep -E 'Filesystem|/data|/var/logs/branch'
echo ""
lvdisplay | grep "LV Name"
echo ""
ufw status verbose
echo "============================================"
echo " ➜ Next: sudo bash member3/cron_setup.sh"
echo "============================================"
