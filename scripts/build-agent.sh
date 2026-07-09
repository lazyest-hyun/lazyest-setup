#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

parse_common_flags "$@"

pkg="$(agent_package_dir)"
echo "BUILD_AGENT"
echo "  dry-run: $(bool_label "$DRY_RUN")"
echo "  package: $pkg"

if ! command -v swift >/dev/null 2>&1; then
  echo "  blocked: swift toolchain not found"
  exit 0
fi

echo "  swift: $(swift --version | head -1)"
if ((DRY_RUN)); then
  echo "[dry-run] cd $pkg && swift build -c release"
else
  run_cmd swift build --package-path "$pkg" -c release
fi
