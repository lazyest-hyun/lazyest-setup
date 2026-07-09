#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

parse_common_flags "$@"

setup_binary="$(agent_package_dir)/.build/release/MacBootstrapSetup"
setup_app="$(setup_app_path)"

echo "INSTALL_SETUP"
echo "  dry-run: $(bool_label "$DRY_RUN")"
echo "  binary: $setup_binary"
echo "  setup app: $setup_app"

if [ ! -x "$setup_binary" ]; then
  echo "  blocked: setup binary not found; run ./bootstrap.sh build-agent first"
  exit 0
fi

if [ -d "$setup_app" ]; then
  run_cmd rm -rf "$setup_app"
fi
run_cmd mkdir -p "$setup_app/Contents/MacOS" "$setup_app/Contents/Resources"
if ((DRY_RUN)); then
  echo "[dry-run] copy setup binary into $setup_app"
  echo "[dry-run] copy app icon into $setup_app"
  echo "[dry-run] write setup Info.plist"
else
  cp "$setup_binary" "$setup_app/Contents/MacOS/MacBootstrapSetup"
  chmod +x "$setup_app/Contents/MacOS/MacBootstrapSetup"
  if [ -f "$ROOT_DIR/agent/MacBootstrapAgent/Assets/AppIcon.icns" ]; then
    cp "$ROOT_DIR/agent/MacBootstrapAgent/Assets/AppIcon.icns" "$setup_app/Contents/Resources/AppIcon.icns"
  fi
  printf '%s\n' "$ROOT_DIR" >"$setup_app/Contents/Resources/ProjectRoot.txt"
  cat >"$setup_app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>MacBootstrapSetup</string>
  <key>CFBundleIdentifier</key>
  <string>com.estaid.mac-bootstrap-setup</string>
  <key>CFBundleName</key>
  <string>MacBootstrapSetup</string>
  <key>CFBundleDisplayName</key>
  <string>MacBootstrapSetup</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
</dict>
</plist>
PLIST
  printf 'APPL????' >"$setup_app/Contents/PkgInfo"
fi

echo "  note: installed one-time setup app only; remove it after setup"

