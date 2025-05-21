#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/connector.sh"

run_logs() {
  local HOSTS_FILE="hosts.yaml"
  local SELECTED_ONLY=false
  local SELECTED_FUNCTIONS=()
  JUMP_HOST=""  # initialize jump host variable

  # Parse arguments
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      -s)
        SELECTED_ONLY=true
        shift
        while [[ "$#" -gt 0 && "$1" != -* ]]; do
          SELECTED_FUNCTIONS+=("$1")
          shift
        done
        ;;
      -T)
        shift
        if [[ "$#" -eq 0 ]]; then
          echo "Error: Missing jump host after -T"
          return 1
        fi
        JUMP_HOST="$1"
        shift
        ;;
      *)
        echo "Usage: $0 --logs [-T jump_user@host] [-s function1 function2 ...]"
        return 1
        ;;
    esac
  done

  # Check if hosts.yaml exists
  if [[ ! -f "$HOSTS_FILE" ]]; then
    echo "Error: $HOSTS_FILE not found"
    return 1
  fi

  # Get function list
  if $SELECTED_ONLY; then
    FUNCTIONS=("${SELECTED_FUNCTIONS[@]}")
  else
    mapfile -t FUNCTIONS < <(yq e '.functions | keys | .[]' "$HOSTS_FILE")
  fi

  # Fetch logs for each function
  for FUNC in "${FUNCTIONS[@]}"; do
    USER=$(yq e ".functions.${FUNC}.user" "$HOSTS_FILE")
    HOST=$(yq e ".functions.${FUNC}.ip" "$HOSTS_FILE")
    LOG_PATH="/var/log/open5gs/${FUNC}.log"

    if [[ -n "$USER" && -n "$HOST" ]]; then
      echo -e "\e[1;34m====== ${FUNC^^} (${USER}@${HOST}) ======\e[0m"
      remote_exec "$USER" "$HOST" "tail -15 '$LOG_PATH'" || echo "Failed to fetch log for $FUNC"

      echo ""
    else
      echo "Warning: Could not retrieve user/host for function '$FUNC'"
    fi
  done
}
