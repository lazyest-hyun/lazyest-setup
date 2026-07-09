#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

parse_common_flags "$@"

echo "APPLY_PRESS_AND_HOLD"
echo "  dry-run: $(bool_label "$DRY_RUN")"
echo "  setting: press-and-hold accents disabled"

if ((DRY_RUN)); then
  echo "[dry-run] defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false"
  exit 0
fi

run_cmd defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
echo "  result: press-and-hold accents disabled"
