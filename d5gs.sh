#!/bin/bash

HELPERS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/helpers" && pwd)"
LOGS_SH="${HELPERS_DIR}/logs.sh"
STATUS_SH="${HELPERS_DIR}/status.sh"

case "$1" in
  -l|--logs)
    shift
    source "$LOGS_SH"
    run_logs "$@"
    ;;
  -S|--status)
    shift
    source "$STATUS_SH"
    check_service_status "$@"
    ;;
  *)
    echo "Usage: $0 [--logs|-l] [--status|-S] [-s func1 func2 ...] [-T jump_user@host]"
    exit 1
    ;;
esac
