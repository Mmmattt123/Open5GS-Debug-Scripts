#!/bin/bash

HELPERS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/helpers" && pwd)"
LOGS_SH="${HELPERS_DIR}/logs.sh"

if [[ "$1" == "-l" || "$1" == "--logs" ]]; then
  shift
  source "$LOGS_SH"
  run_logs "$@"
else
  echo "Usage: $0 --logs [-s function1 function2 ...]"
  exit 1
fi
