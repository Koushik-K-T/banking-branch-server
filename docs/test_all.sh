#!/bin/bash
# =============================================================
# Member 4 — test_all.sh
# Full verification of all project components
# Usage: sudo bash docs/test_all.sh
# =============================================================

PASS=0; FAIL=0
LOG="/var/logs/branch/test_$(date +%Y%m%d_%H%M%S).log"
mkdir -p /var/logs/branch

check() {
  local desc="$1"; local cmd="$2"
  if eval "$cmd" >> "$LOG" 2>&1; then
    echo "  ✅ PASS: $desc"
    PASS=$((PASS+1))
  else
    echo "  ❌ FAIL: $desc"
    FAIL=$((FAIL+1))
  fi
}

echo ""
echo "============================================"
echo " BANKING BRANCH — FULL TEST SUITE"
echo " $(date)"
echo "============================================"

echo ""
echo "--- TEST 1: MEMBER 1 — System & Users ---"
check "Hostname is bank-branch01"        "[ \"$(hostname)\" = 'bank-branch01' ]"
check "Apache2 is active"                "systemctl is-active --quiet apache2"
check "SSH is active"                    "systemctl is-active --quiet ssh"
check "Cron is active"                   "systemctl is-active --quiet cron"
check "User emp1 exists"                 "id emp1"
check "User mgr1 exists"                 "id mgr1"
check "User audit1 exists"               "id audit1"
check "User itadmin exists"              "id itadmin"
check "Group employees exists"           "getent group employees"
check "Group managers exists"            "getent group managers"
check "Group auditors exists"            "getent group auditors"
check "itadmin has sudo"                 "groups itadmin | grep -q sudo"
check "emp1 cannot sudo"                 "! sudo -l -U emp1 2>&1 | grep -q '(ALL)'"

echo ""
echo "--- TEST 2: MEMBER 2 — Storage & Permissions ---"
check "/data/employee is mounted"        "mountpoint -q /data/employee"
check "/data/audit is mounted"           "mountpoint -q /data/audit"
check "/data/reports is mounted"         "mountpoint -q /data/reports"
check "/var/logs/branch is mounted"      "mountpoint -q /var/logs/branch"
check "fstab has lv_employee"            "grep -q lv_employee /etc/fstab"
check "fstab has lv_audit"               "grep -q lv_audit /etc/fstab"
check "/backup/branch/daily exists"      "[ -d /backup/branch/daily ]"
check "emp1 can write /data/employee"    "sudo -u emp1 touch /data/employee/test_emp.txt"
check "emp1 cannot write /data/reports"  "! sudo -u emp1 touch /data/reports/test.txt 2>/dev/null"
check "audit1 cannot write /data/reports" "! sudo -u audit1 touch /data/reports/test.txt 2>/dev/null"
check "UFW is active"                    "ufw status | grep -q 'Status: active'"
check "Port 2222 allowed in UFW"         "ufw status | grep -q 2222"
check "Port 80 allowed in UFW"           "ufw status | grep -q '80'"

echo ""
echo "--- TEST 3: MEMBER 3 — Scripts & Security ---"
check "audit_logger.sh is executable"    "[ -x /scripts/audit_logger.sh ]"
check "audit_report.sh is executable"    "[ -x /scripts/audit_report.sh ]"
check "bank_backup.sh is executable"     "[ -x /scripts/bank_backup.sh ]"
check "Cron file exists"                 "[ -f /etc/cron.d/banking-branch ]"
check "audit_logger cron entry"          "grep -q audit_logger /etc/cron.d/banking-branch"
check "audit_report cron entry"          "grep -q audit_report /etc/cron.d/banking-branch"
check "bank_backup cron entry"           "grep -q bank_backup /etc/cron.d/banking-branch"
check "SSH on port 2222"                 "ss -tlnp | grep -q 2222"
check "Root SSH login disabled"          "grep -q 'PermitRootLogin no' /etc/ssh/sshd_config"
check "SSH AllowGroups set to sudo"      "grep -q 'AllowGroups sudo' /etc/ssh/sshd_config"

echo ""
echo "--- TEST 4: MEMBER 3 — Script Execution ---"
bash /scripts/audit_logger.sh
check "audit_logger creates log file"    "ls /data/audit/AUDIT_*.log | head -1 | grep -q AUDIT"
check "audit_ingest.log updated"         "[ -f /var/logs/branch/audit_ingest.log ]"
bash /scripts/branch_health.sh
check "branch_health log created"        "ls /var/logs/branch/health_*.log | head -1 | grep -q health"
bash /scripts/bank_backup.sh
check "Backup ran without error"         "ls /backup/branch/daily/ | head -1 | wc -c | grep -qv '^0'"

echo ""
echo "--- TEST 5: MEMBER 4 — Health Script ---"
check "branch_health.sh is executable"  "[ -x /scripts/branch_health.sh ]"
check "Health log file created"         "ls /var/logs/branch/health_$(date +%Y%m%d).log"

echo ""
echo "--- TEST 6: WEBSITE ---"
check "index.html exists"               "[ -f /var/www/html/index.html ]"
check "Apache serves index.html"        "curl -s -o /dev/null -w '%{http_code}' http://localhost | grep -q 200"
check "CGI status.sh is executable"     "[ -x /var/www/html/cgi-bin/status.sh ]"

echo ""
echo "--- TEST 7: BACKUP RESTORATION ---"
# Create a test file, delete it, restore it
echo "test restore content" > /data/reports/restore_test.txt
bash /scripts/bank_backup.sh
rm /data/reports/restore_test.txt
rsync -a /backup/branch/daily/reports/ /data/reports/
check "File restored from backup"       "[ -f /data/reports/restore_test.txt ]"
rm -f /data/reports/restore_test.txt

echo ""
echo "============================================"
echo " TEST RESULTS"
echo "============================================"
echo "  ✅ Passed : $PASS"
echo "  ❌ Failed : $FAIL"
echo "  Total     : $((PASS+FAIL))"
echo ""
echo "  Full log  : $LOG"
echo "============================================"

[ "$FAIL" -eq 0 ] && echo " 🎉 ALL TESTS PASSED — Project is ready!" \
                  || echo " ⚠️  Some tests failed — check log for details"
echo "============================================"
