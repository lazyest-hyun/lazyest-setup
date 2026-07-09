#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

parse_common_flags "$@"

echo "APPLY_GLOBE_KEY"
echo "  dry-run: $(bool_label "$DRY_RUN")"
echo "  setting: press Globe/Fn key = do nothing"

if ((DRY_RUN)); then
  echo "[dry-run] defaults write com.apple.HIToolbox AppleFnUsageType -int 0"
  exit 0
fi

run_cmd defaults write com.apple.HIToolbox AppleFnUsageType -int 0
echo "  result: Globe/Fn key action set to do nothing"
