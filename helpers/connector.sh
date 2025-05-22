#!/bin/bash

# Config files
CONFIG_FILE=".config"          # target hosts config (INI-style)
GLOBAL_CONFIG_FILE="/.config" # global config (INI-style)

# Global jump host variable (set externally)
# Example values: "jumpuser@jumphost" or "jumpuser@jumphost:2222"
JUMP_HOST=""

# Get identity file from .hosts (INI-style)
get_ssh_identity() {
  local identity
  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Config file $CONFIG_FILE not found"
    return 1
  fi

  identity=$(grep -E '^identity_file' "$CONFIG_FILE" | awk -F'=' '{print $2}' | xargs)

  if [[ -z "$identity" ]]; then
    echo "Error: SSH identity_file not set in $CONFIG_FILE"
    return 1
  fi

  echo "$identity"
}

# Get jump identity file from global config (INI-style)
get_jump_ssh_identity() {
  local jump_identity=""
  if [[ -f "$GLOBAL_CONFIG_FILE" ]]; then
    jump_identity=$(grep -E '^jump_identity_file' "$GLOBAL_CONFIG_FILE" | awk -F'=' '{print $2}' | xargs)
  fi

  if [[ -z "$jump_identity" ]]; then
    # fallback to normal identity if jump-specific not set
    jump_identity=$(get_ssh_identity) || return 1
  fi

  echo "$jump_identity"
}

remote_exec() {
  if [ "$#" -ne 3 ]; then
    echo "Usage: remote_exec <username> <host> <script_or_command>"
    return 1
  fi

  local USER="$1"
  local HOST="$2"
  local SCRIPT="$3"

  # Get target host identity file
  local ID_FILE
  ID_FILE=$(get_ssh_identity)
  # Get jump host identity file if jump host specified
  local JUMP_ID_FILE=""
  if [[ -n "$JUMP_HOST" ]]; then
    JUMP_ID_FILE=$(get_jump_ssh_identity) || return 1
  fi

  # Build SSH command
  local SSH_CMD=(ssh -o StrictHostKeyChecking=no)

  # If jump host set, add jump with identity file
  # Supports optional port in $JUMP_HOST (e.g. user@host:2222)
  if [[ -n "$JUMP_HOST" ]]; then
    SSH_CMD+=("-J" "-i" "$JUMP_ID_FILE" "$JUMP_HOST")
  fi

  # Add identity for target host
  SSH_CMD+=("-i" "$ID_FILE" "${USER}@${HOST}")

  echo "Executing on ${USER}@${HOST} via ${JUMP_HOST:-direct}..."
  ${SSH_CMD[@]} 'bash -s' <<< "${SCRIPT}" EOF
  return 0
  
}
