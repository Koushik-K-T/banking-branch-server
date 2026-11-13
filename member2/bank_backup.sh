#!/bin/bash
# =============================================================
# Member 2 — bank_backup.sh
# Incremental daily backup + weekly snapshot
# Scheduled via cron at 11:30 PM by member3/cron_setup.sh
# =============================================================

BACKUP_DAILY="/backup/branch/daily"
BACKUP_WEEKLY="/backup/branch/weekly"
SOURCES="/data/reports /data/audit"
DATE=$(date +%Y%m%d)
LOG="/var/logs/branch/backup_${DATE}.log"

mkdir -p "$BACKUP_DAILY" "$BACKUP_WEEKLY"

echo "[$(date)] ===== Backup Started =====" >> "$LOG"

for src in $SOURCES; do
  if [ -d "$src" ]; then
    rsync -av --delete "$src" "$BACKUP_DAILY/" >> "$LOG" 2>&1
    echo "[$(date)] Backed up: $src" >> "$LOG"
  else
    echo "[$(date)] WARNING: $src not found, skipping" >> "$LOG"
  fi
done

# Weekly snapshot every Sunday
if [ "$(date +%u)" -eq 7 ]; then
  SNAPSHOT="$BACKUP_WEEKLY/weekly_${DATE}.tar.gz"
  tar -czf "$SNAPSHOT" "$BACKUP_DAILY/" >> "$LOG" 2>&1
  echo "[$(date)] Weekly snapshot created: $SNAPSHOT" >> "$LOG"
fi

# Keep only last 7 daily backups
find "$BACKUP_DAILY" -type f -mtime +7 -delete
echo "[$(date)] Old backups cleaned (kept last 7 days)" >> "$LOG"

echo "[$(date)] ===== Backup Complete =====" >> "$LOG"
