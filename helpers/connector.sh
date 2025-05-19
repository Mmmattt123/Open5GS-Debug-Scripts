#!/bin/bash

# Load SSH identity file from .hosts config
CONFIG_FILE=".hosts"

get_ssh_identity() {
  local identity
  identity=$(yq e '.ssh.identity_file' "$CONFIG_FILE" 2>/dev/null)

  if [[ -z "$identity" || "$identity" == "null" ]]; then
    echo "Error: SSH identity_file not set in $CONFIG_FILE"
    return 1
  fi

  echo "$identity"
}

remote_exec() {
  local USER="$1"
  local HOST="$2"
  local SCRIPT="$3"
  local ID_FILE

  ID_FILE=$(get_ssh_identity) || return 1

  echo "Executing on ${USER}@${HOST} using key $ID_FILE..."
  ssh -i "$ID_FILE" -o StrictHostKeyChecking=no "${USER}@${HOST}" "bash -s" <<EOF
${SCRIPT}
EOF
}
#!/bin/bash
remote_exec() {
  if [ "$#" -ne 3 ]; then
    echo "Usage: remote_exec <username> <host> <script_or_command>"
    return 1
  fi

  local USER="$1"
  local HOST="$2"
  local SCRIPT="$3"

  ssh "${USER}@${HOST}" "bash -s" <<EOF
${SCRIPT}
EOF
}