#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

parse_common_flags "$@"

echo "APPLY_FUNCTION_KEYS"
echo "  dry-run: $(bool_label "$DRY_RUN")"
echo "  setting: use F1, F2, etc. keys as standard function keys"

if ((DRY_RUN)); then
  echo "[dry-run] defaults write NSGlobalDomain com.apple.keyboard.fnState -bool true"
  exit 0
fi

run_cmd defaults write NSGlobalDomain com.apple.keyboard.fnState -bool true
echo "  result: standard function keys enabled"
