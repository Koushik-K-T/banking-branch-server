#!/bin/bash
# =============================================================
# Member 1 — new_user.sh
# Bulk creates users from users.csv
# CSV format: username,group,role
# Usage: sudo bash setup/new_user.sh
# =============================================================

CSV_FILE="$(dirname "$0")/users.csv"
LOG="/var/logs/branch/user_creation.log"
mkdir -p /var/logs/branch

if [ ! -f "$CSV_FILE" ]; then
  echo "ERROR: users.csv not found at $CSV_FILE"
  exit 1
fi

echo "[$(date)] Bulk user creation started" >> "$LOG"

while IFS=',' read -r username group role; do
  [[ "$username" == "username" ]] && continue
  [[ -z "$username" ]] && continue

  if id "$username" &>/dev/null; then
    echo "[$(date)] SKIP: $username already exists" | tee -a "$LOG"
  else
    useradd -m -s /bin/bash -G "$group" "$username"
    echo "$username:Branch@2024" | chpasswd
    chage -d 0  "$username"
    chage -I 45 "$username"
    echo "[$(date)] CREATED: $username | group: $group | role: $role" | tee -a "$LOG"
  fi
done < "$CSV_FILE"

echo "[$(date)] Bulk user creation complete" >> "$LOG"
echo "Done. Check log: $LOG"
