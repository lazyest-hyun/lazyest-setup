#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

parse_common_flags "$@"

binary="$(agent_binary_path)"
app="$(agent_app_path)"
plist="$(launch_agent_plist)"
codesign_identity="${MAC_BOOTSTRAP_CODESIGN_IDENTITY:-}"

codesign_identity_available() {
  [ -n "$codesign_identity" ] || return 1
  security find-identity -v -p codesigning 2>/dev/null | grep -F "\"$codesign_identity\"" >/dev/null
}

sign_agent_app() {
  if codesign_identity_available; then
    echo "  codesign: $codesign_identity"
    if codesign --force --deep --sign "$codesign_identity" "$app"; then
      return
    fi
    echo "  warning: stable codesign failed; falling back to ad-hoc signature"
    codesign --force --deep --sign - "$app"
  else
    echo "  codesign: ad-hoc (set MAC_BOOTSTRAP_CODESIGN_IDENTITY for a stable local signing identity)"
    codesign --force --deep --sign - "$app"
  fi
}

echo "INSTALL_AGENT"
echo "  dry-run: $(bool_label "$DRY_RUN")"
echo "  binary: $binary"
echo "  app: $app"

if [ ! -x "$binary" ]; then
  echo "  blocked: agent binary not found; run ./bootstrap.sh build-agent first"
  exit 0
fi

if pgrep -x MacBootstrapAgent >/dev/null 2>&1; then
  if ((DRY_RUN)); then
    echo "[dry-run] stop running MacBootstrapAgent before replacing app bundle"
  else
    pkill -x MacBootstrapAgent || true
    sleep 0.5
  fi
fi

if [ -d "$app" ]; then
  run_cmd rm -rf "$app"
fi
run_cmd mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources" "$AGENT_CONFIG_DIR"
if ((DRY_RUN)); then
  echo "[dry-run] copy agent binary into $app"
  echo "[dry-run] seed config/hotkeys.conf into $AGENT_CONFIG_DIR only if missing"
  echo "[dry-run] seed config/bootstrap.conf into $AGENT_CONFIG_DIR only if missing"
  echo "[dry-run] copy app icon into $app"
  echo "[dry-run] write app Info.plist"
  if codesign_identity_available; then
    echo "[dry-run] sign $app with $codesign_identity"
  else
    echo "[dry-run] ad-hoc sign $app (stable local identity not found)"
  fi
  if [ -f "$plist" ]; then
    echo "[dry-run] remove legacy LaunchAgent plist at $plist"
  fi
else
  cp "$binary" "$app/Contents/MacOS/MacBootstrapAgent"
  chmod +x "$app/Contents/MacOS/MacBootstrapAgent"
  if [ ! -f "$AGENT_CONFIG_DIR/hotkeys.conf" ]; then
    cp "$ROOT_DIR/config/hotkeys.conf" "$AGENT_CONFIG_DIR/hotkeys.conf"
  fi
  if [ ! -f "$AGENT_CONFIG_DIR/bootstrap.conf" ]; then
    cp "$ROOT_DIR/config/bootstrap.conf" "$AGENT_CONFIG_DIR/bootstrap.conf"
  fi
  if [ -f "$ROOT_DIR/agent/MacBootstrapAgent/Assets/AppIcon.icns" ]; then
    cp "$ROOT_DIR/agent/MacBootstrapAgent/Assets/AppIcon.icns" "$app/Contents/Resources/AppIcon.icns"
  fi
  cat >"$app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>MacBootstrapAgent</string>
  <key>CFBundleIdentifier</key>
  <string>$AGENT_LABEL</string>
  <key>CFBundleName</key>
  <string>MacBootstrapAgent</string>
  <key>CFBundleDisplayName</key>
  <string>MacBootstrapAgent</string>
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
  <key>LSUIElement</key>
  <true/>
</dict>
</plist>
PLIST
  printf 'APPL????' >"$app/Contents/PkgInfo"
  if [ -f "$plist" ]; then
    rm "$plist"
  fi
  sign_agent_app
fi

echo "  note: installed always-running menu bar app only; this script does not launch it"
