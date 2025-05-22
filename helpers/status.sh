#!/bin/bash

# Load connector script for remote_exec and identity functions
source "$(dirname "${BASH_SOURCE[0]}")/connector.sh"

check_service_status() {
  local HOSTS_FILE="hosts.yaml"
  local SELECTED_ONLY=false
  local SELECTED_FUNCTIONS=()
  JUMP_HOST=""  # Reset jump host for this context

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
        export JUMP_HOST
        shift
        ;;
      *)
        echo "Usage: $0 [-T jump_user@host] [-s service1 service2 ...]"
        return 1
        ;;
    esac
  done

  # Check if hosts file exists
  if [[ ! -f "$HOSTS_FILE" ]]; then
    echo "Error: $HOSTS_FILE not found"
    return 1
  fi

  # Get list of services/functions
  if $SELECTED_ONLY; then
    FUNCTIONS=("${SELECTED_FUNCTIONS[@]}")
  else
    mapfile -t FUNCTIONS < <(yq e '.functions | keys | .[]' "$HOSTS_FILE")
  fi

  if [[ ${#FUNCTIONS[@]} -eq 0 ]]; then
    echo "No services to check."
    return 1
  fi

  # Run systemctl status for each service
  for FUNC in "${FUNCTIONS[@]}"; do
    USER=$(yq e ".functions.${FUNC}.user" "$HOSTS_FILE")
    HOST=$(yq e ".functions.${FUNC}.ip" "$HOSTS_FILE")

    if [[ -n "$USER" && -n "$HOST" ]]; then
      echo -e "\e[1;32m--- SYSTEMCTL STATUS: ${FUNC^^} (${USER}@${HOST}) ---\e[0m"
      remote_exec "$USER" "$HOST" "systemctl status open5gs-${FUNC}d | head -n 10" || echo "Failed to get status for $FUNC"
      echo ""
    else
      echo "Warning: Missing user/host for function '$FUNC'"
    fi
  done
}

# Call the function if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  check_service_status "$@"
fi
