#!/bin/bash
# =============================================================
# Member 3 — audit_logger.sh
# Simulates audit log entries every minute
# Logs written to /data/audit/
# Scheduled via cron: * * * * *
# =============================================================

AUDIT_DIR="/data/audit"
LOG_FILE="/var/logs/branch/audit_ingest.log"
DATE=$(date +%Y%m%d)
TIME=$(date +%H%M%S)
FILENAME="AUDIT_${DATE}_${TIME}.log"

mkdir -p "$AUDIT_DIR"

ACTIONS=("LOGIN" "LOGOUT" "FILE_ACCESS" "TRANSFER" "REPORT_VIEW" "CONFIG_CHANGE" "FAILED_LOGIN")
USERS=("emp1" "emp2" "emp3" "mgr1" "mgr2" "audit1" "audit2" "itadmin")
STATUSES=("SUCCESS" "SUCCESS" "SUCCESS" "FAILED")

ACTION=${ACTIONS[$RANDOM % ${#ACTIONS[@]}]}
USER=${USERS[$RANDOM % ${#USERS[@]}]}
STATUS=${STATUSES[$RANDOM % ${#STATUSES[@]}]}
IP="192.168.1.$(( RANDOM % 50 + 100 ))"

{
  echo "Timestamp  : $(date)"
  echo "User       : $USER"
  echo "Action     : $ACTION"
  echo "Source IP  : $IP"
  echo "Status     : $STATUS"
  echo "Session ID : SESS$(( RANDOM % 90000 + 10000 ))"
} > "$AUDIT_DIR/$FILENAME"

echo "[$(date)] Logged: $FILENAME | $USER | $ACTION | $STATUS" >> "$LOG_FILE"
