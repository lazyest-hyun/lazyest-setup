#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

parse_common_flags "$@"

echo "APPLY_KEY_REPEAT"
echo "  dry-run: $(bool_label "$DRY_RUN")"
echo "  setting: fastest key repeat and shortest repeat delay"

if ((DRY_RUN)); then
  echo "[dry-run] defaults write NSGlobalDomain KeyRepeat -int 1"
  echo "[dry-run] defaults write NSGlobalDomain InitialKeyRepeat -int 10"
  exit 0
fi

run_cmd defaults write NSGlobalDomain KeyRepeat -int 1
run_cmd defaults write NSGlobalDomain InitialKeyRepeat -int 10
echo "  result: key repeat set"
