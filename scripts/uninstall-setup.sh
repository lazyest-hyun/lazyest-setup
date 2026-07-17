#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

parse_common_flags "$@"

setup_app="$(setup_app_path)"
echo "UNINSTALL_SETUP"
echo "  dry-run: $(bool_label "$DRY_RUN")"
echo "  setup app: $setup_app"

if [ -d "$setup_app" ]; then
  run_cmd rm -rf "$setup_app"
else
  echo "  setup app already absent"
fi
legacy_setup_app="/Applications/MacBootstrapSetup.app"
if [ -d "$legacy_setup_app" ]; then
  run_cmd rm -rf "$legacy_setup_app"
fi
echo "  note: this script does not quit a running setup app"
