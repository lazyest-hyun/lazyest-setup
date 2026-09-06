#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

parse_common_flags "$@"

pkg="$(setup_package_dir)"
echo "BUILD_SETUP"
echo "  dry-run: $(bool_label "$DRY_RUN")"
echo "  package: $pkg"

if ! /usr/bin/xcrun --find swift >/dev/null 2>&1; then
  echo "  blocked: install Apple Command Line Tools with xcode-select --install, then retry" >&2
  exit 1
fi

echo "  swift: $(swift --version | head -1)"
if ((DRY_RUN)); then
  echo "[dry-run] swift build --package-path $pkg -c release --product LazyestSetup"
else
  # Keep caches scoped to the checkout. Never select a machine-specific older SDK.
  module_cache="$pkg/.build/ModuleCache"
  CLANG_MODULE_CACHE_PATH="$module_cache" SWIFTPM_MODULECACHE_OVERRIDE="$module_cache" \
    /usr/bin/xcrun swift build --disable-sandbox --package-path "$pkg" -c release --product LazyestSetup -Xswiftc -gnone -Xswiftc -file-prefix-map -Xswiftc "$ROOT_DIR=."
fi
