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

# Validate usernames (alphanum, dash, underscore) and group names (alphanum, dash, underscore)
valid_name(){
  [[ -n "$1" && "$1" =~ ^[a-zA-Z0-9_-]+$ ]]
}

json() { echo "$1"; exit 0; }

# Validate username (alphanum, dash, underscore only)
valid_user() {
  [[ -n "$1" && "$1" =~ ^[a-zA-Z0-9_-]+$ ]]
}

case "$action" in
  list)
    out=$(getent passwd | awk -F: '$3>=1000 {print $1}')
    json "{\"users\":[$(printf '%s' "$out" | sed 's/^/\"/;s/$/\"/;s/\n/\",\"/g')] }"
    ;;
  add)
    if ! valid_name "$user"; then json '{"error":"Invalid username"}'; fi
    if sudo /usr/sbin/adduser --disabled-password --gecos "" "$user" >/dev/null 2>&1; then
      json '{"result":"User added"}'
    else
      json '{"error":"Failed to add user"}'
    fi
    ;;
  del)
    if ! valid_name "$user"; then json '{"error":"Invalid username"}'; fi
    if sudo /usr/sbin/deluser "$user" >/dev/null 2>&1; then
      json '{"result":"User deleted"}'
    else
      json '{"error":"Failed to delete user"}'
    fi
    ;;
  groups)
    if ! valid_name "$user"; then json '{"error":"Invalid username"}'; fi
    info=$(id "$user" 2>/dev/null)
    if [[ -n "$info" ]]; then
      json "{\"info\":\"$info\"}"
    else
      json '{"error":"User not found"}'
    fi
    ;;
  group_list)
    out=$(getent group | awk -F: '{print $1}')
    json "{\"groups\":[$(printf '%s' "$out" | sed 's/^/\"/;s/$/\"/;s/\n/\",\"/g')] }"
    ;;
  group_add)
    grp="$user"
    if ! valid_name "$grp"; then json '{"error":"Invalid group name"}'; fi
    if sudo /usr/sbin/groupadd "$grp" >/dev/null 2>&1; then
      json '{"result":"Group added"}'
    else
      json '{"error":"Failed to add group"}'
    fi
    ;;
  group_del)
    grp="$user"
    if ! valid_name "$grp"; then json '{"error":"Invalid group name"}'; fi
    if sudo /usr/sbin/groupdel "$grp" >/dev/null 2>&1; then
      json '{"result":"Group deleted"}'
    else
      json '{"error":"Failed to delete group"}'
    fi
    ;;
  add_to_group)
    u="$user"
    g="$params[group]"
    if ! valid_name "$u" || ! valid_name "$g"; then json '{"error":"Invalid user or group"}'; fi
    if sudo /usr/sbin/usermod -a -G "$g" "$u" >/dev/null 2>&1; then
      json '{"result":"User added to group"}'
    else
      json '{"error":"Failed to add user to group"}'
    fi
    ;;
  remove_from_group)
    u="$user"
    g="$params[group]"
    if ! valid_name "$u" || ! valid_name "$g"; then json '{"error":"Invalid user or group"}'; fi
    # Remove user from group by editing /etc/group via gpasswd -d
    if sudo /usr/sbin/gpasswd -d "$u" "$g" >/dev/null 2>&1; then
      json '{"result":"User removed from group"}'
    else
      json '{"error":"Failed to remove user from group"}'
    fi
    ;;
  *)
    json '{"error":"Invalid action"}'
    ;;
esac
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

