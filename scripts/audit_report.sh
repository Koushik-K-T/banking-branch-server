#!/bin/bash
# =============================================================
# Member 3 — audit_report.sh
# Processes daily audit logs and generates summary report
# Scheduled via cron: 0 18 * * *
# =============================================================

AUDIT_DIR="/data/audit"
REPORT_DIR="/data/reports"
DATE=$(date +%Y%m%d)
LOG_FILE="/var/logs/branch/audit_${DATE}.log"
REPORT_FILE="$REPORT_DIR/AUDIT_REPORT_${DATE}.txt"

mkdir -p "$REPORT_DIR"

echo "[$(date)] Audit report generation started" >> "$LOG_FILE"

TOTAL=0; SUCCESS=0; FAILED=0
declare -A ACTION_COUNT
declare -A USER_COUNT

for file in "$AUDIT_DIR"/AUDIT_*.log; do
  [ -f "$file" ] || continue
  TOTAL=$((TOTAL + 1))

  status=$(grep 'Status' "$file" | awk '{print $3}')
  user=$(grep 'User' "$file" | awk '{print $3}')
  action=$(grep 'Action' "$file" | awk '{print $3}')

  [ "$status" = "SUCCESS" ] && SUCCESS=$((SUCCESS + 1)) || FAILED=$((FAILED + 1))
  ACTION_COUNT[$action]=$(( ${ACTION_COUNT[$action]:-0} + 1 ))
  USER_COUNT[$user]=$(( ${USER_COUNT[$user]:-0} + 1 ))

  # Compress and move processed log
  gzip "$file"
  mv "${file}.gz" "$REPORT_DIR/"
done

{
  echo "=================================================="
  echo "  BANKING BRANCH — DAILY AUDIT REPORT"
  echo "  Date    : $(date +%Y-%m-%d)"
  echo "  Server  : $(hostname)"
  echo "=================================================="
  echo ""
  echo "  SUMMARY"
  echo "  -------"
  echo "  Total Events   : $TOTAL"
  echo "  Successful     : $SUCCESS"
  echo "  Failed         : $FAILED"
  echo ""
  echo "  EVENTS BY ACTION"
  echo "  ----------------"
  for action in "${!ACTION_COUNT[@]}"; do
    printf "  %-20s : %s\n" "$action" "${ACTION_COUNT[$action]}"
  done
  echo ""
  echo "  EVENTS BY USER"
  echo "  --------------"
  for user in "${!USER_COUNT[@]}"; do
    printf "  %-20s : %s\n" "$user" "${USER_COUNT[$user]}"
  done
  echo ""
  echo "=================================================="
} > "$REPORT_FILE"

echo "[$(date)] Report saved to $REPORT_FILE" >> "$LOG_FILE"
echo "[$(date)] Processed $TOTAL audit events" >> "$LOG_FILE"
