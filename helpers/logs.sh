#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/connector.sh"

run_logs() {
  local HOSTS_FILE="hosts.yaml"
  local SELECTED_ONLY=false
  local SELECTED_FUNCTIONS=()

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
      *)
        echo "Usage: $0 --logs [-s function1 function2 ...]"
        return 1
        ;;
    esac
  done

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
    LOG_PATH="/var/logs/open5gs/${FUNC}.log"

    if [[ -n "$USER" && -n "$HOST" ]]; then
      echo "====== ${FUNC^^} (${USER}@${HOST}) ======"
      remote_exec "$USER" "$HOST" "cat '$LOG_PATH'" || echo "Failed to fetch log for $FUNC"
      echo ""
    else
      echo "Warning: Could not retrieve user/host for function '$FUNC'"
    fi
  done
}
