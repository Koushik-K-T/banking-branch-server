#!/usr/bin/env bash
# manage_users.sh – CGI for minimal user admin (JSON output)
# Only whitelisted actions are allowed. Must be called via Apache CGI.

# Send HTTP header
echo -e "Content-Type: application/json\r\n"

# Parse query string or POST data
declare -A params
read_input() {
  if [[ "$REQUEST_METHOD" == "POST" ]]; then
    read -d '' -t 5 POST_DATA || POST_DATA=""
    raw="$POST_DATA"
  else
    raw="$QUERY_STRING"
  fi
  IFS='&' read -ra pairs <<< "$raw"
  for p in "${pairs[@]}"; do
    IFS='=' read -r k v <<< "$p"
    params["$k"]=$(printf '%b' "${v//%/\\x}")
  done
}
read_input

action="${params[action]}"
user="${params[user]}"

# Helper to return JSON and exit
json() { echo "$1"; exit 0; }

# Validate username (alphanum, dash, underscore only)
valid_user() {
  [[ -n "$1" && "$1" =~ ^[a-zA-Z0-9_-]+$ ]]
}

case "$action" in
  list)
    out=$(getent passwd | awk -F: '$3>=1000 {print $1}')
    # Convert newline list to JSON array
    json "{\"users\":[$(printf '%s' "$out" | sed 's/^/\"/;s/$/\"/;s/\n/\",\"/g')] }"
    ;;
  add)
    if ! valid_user "$user"; then json '{"error":"Invalid username"}'; fi
    if sudo /usr/sbin/adduser --disabled-password --gecos "" "$user" >/dev/null 2>&1; then
      json '{"result":"User added"}'
    else
      json '{"error":"Failed to add user"}'
    fi
    ;;
  del)
    if ! valid_user "$user"; then json '{"error":"Invalid username"}'; fi
    if sudo /usr/sbin/deluser "$user" >/dev/null 2>&1; then
      json '{"result":"User deleted"}'
    else
      json '{"error":"Failed to delete user"}'
    fi
    ;;
  groups)
    if ! valid_user "$user"; then json '{"error":"Invalid username"}'; fi
    info=$(id "$user" 2>/dev/null)
    if [[ -n "$info" ]]; then
      json "{\"info\":\"$info\"}"
    else
      json '{"error":"User not found"}'
    fi
    ;;
  *)
    json '{"error":"Invalid action"}'
    ;;
esac

