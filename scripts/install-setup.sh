#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

parse_common_flags "$@"

setup_binary="$(agent_package_dir)/.build/release/MacBootstrapSetup"
setup_app="$(setup_app_path)"
version="$(app_version)"
default_codesign_identity="MacBootstrap Local Code Signing"
codesign_identity="${MAC_BOOTSTRAP_CODESIGN_IDENTITY:-$default_codesign_identity}"

codesign_identity_available() {
  [ -n "$codesign_identity" ] || return 1
  security find-identity -v -p codesigning 2>/dev/null | grep -F "\"$codesign_identity\"" >/dev/null
}

sign_setup_app() {
  if codesign_identity_available; then
    echo "  codesign: $codesign_identity"
    if codesign --force --deep --sign "$codesign_identity" "$setup_app"; then
      return
    fi
    echo "  warning: stable codesign failed; falling back to ad-hoc signature"
  else
    echo "  codesign: ad-hoc (stable local identity not found; set MAC_BOOTSTRAP_CODESIGN_IDENTITY to override)"
  fi
  codesign --force --deep --sign - "$setup_app"
}

echo "INSTALL_SETUP"
echo "  dry-run: $(bool_label "$DRY_RUN")"
echo "  binary: $setup_binary"
echo "  setup app: $setup_app"
echo "  version: $version"

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
  if codesign_identity_available; then
    echo "[dry-run] sign $setup_app with $codesign_identity"
  else
    echo "[dry-run] ad-hoc sign $setup_app (stable local identity not found)"
  fi
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
  <string>$version</string>
  <key>CFBundleVersion</key>
  <string>$version</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
</dict>
</plist>
PLIST
  printf 'APPL????' >"$setup_app/Contents/PkgInfo"
  sign_setup_app
fi

echo "  note: installed one-time setup app only; this does not launch it or apply settings"
