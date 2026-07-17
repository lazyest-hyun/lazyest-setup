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

if ! command -v swift >/dev/null 2>&1; then
  echo "  blocked: swift toolchain not found"
  exit 0
fi

echo "  swift: $(swift --version | head -1)"
if ((DRY_RUN)); then
  echo "[dry-run] swift build --package-path $pkg -c release --product LazyestSetup"
else
  module_cache="/private/tmp/mac-bootstrap-setup-module-cache"
  if CLANG_MODULE_CACHE_PATH="$module_cache" SWIFTPM_MODULECACHE_OVERRIDE="$module_cache" \
    swift build --package-path "$pkg" -c release --product LazyestSetup; then
    exit 0
  fi

  fallback_sdk="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"
  if [ ! -d "$fallback_sdk" ]; then
    echo "  blocked: the active Swift compiler and macOS SDK are incompatible"
    exit 1
  fi
  target="$(uname -m)-apple-macosx13.0"
  echo "  warning: active SDK is incompatible; retrying with $fallback_sdk"
  SDKROOT="$fallback_sdk" \
    CLANG_MODULE_CACHE_PATH="$module_cache" \
    SWIFTPM_MODULECACHE_OVERRIDE="$module_cache" \
    swift build \
      --disable-sandbox \
      --package-path "$pkg" \
      -c release \
      --product LazyestSetup \
      --sdk "$fallback_sdk" \
      --triple "$target"
fi
