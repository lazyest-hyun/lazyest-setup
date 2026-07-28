#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

parse_common_flags "$@"

setup_binary="$(setup_binary_path)"
setup_app="$(setup_app_path)"
version="$(app_version)"
default_codesign_identity="MacBootstrap Local Code Signing"
codesign_identity="${MAC_BOOTSTRAP_CODESIGN_IDENTITY:-$default_codesign_identity}"

validate_setup_app_path() {
  case "$setup_app" in
    "/Applications/Lazyest Setup.app"|"$ROOT_DIR/dist/Lazyest Setup.app") ;;
    *)
      echo "Refusing to replace unexpected app path: $setup_app" >&2
      exit 1
      ;;
  esac
}

codesign_identity_available() {
  [ -n "$codesign_identity" ] || return 1
  security find-identity -v -p codesigning 2>/dev/null | grep -F "\"$codesign_identity\"" >/dev/null
}

sign_setup_app() {
  if codesign_identity_available; then
    echo "  codesign: $codesign_identity"
    if [[ "$codesign_identity" == Developer\ ID\ Application:* ]]; then
      if codesign --force --deep --options runtime --timestamp --sign "$codesign_identity" "$setup_app"; then
        return
      fi
    elif codesign --force --deep --options runtime --timestamp=none --sign "$codesign_identity" "$setup_app"; then
      return
    fi
    echo "  warning: stable codesign failed; falling back to ad-hoc signature"
  else
    echo "  codesign: ad-hoc (stable local identity not found; set MAC_BOOTSTRAP_CODESIGN_IDENTITY to override)"
  fi
  codesign --force --deep --options runtime --timestamp=none --sign - "$setup_app"
}

copy_runtime_payload() {
  local runtime_dir="$setup_app/Contents/Resources/Runtime"
  mkdir -p "$runtime_dir/config" "$runtime_dir/scripts"
  cp "$ROOT_DIR/bootstrap.sh" "$ROOT_DIR/VERSION" "$runtime_dir/"
  cp "$ROOT_DIR/config/bootstrap.conf" "$runtime_dir/config/"
  cp "$ROOT_DIR/scripts/"*.sh "$runtime_dir/scripts/"
  chmod +x "$runtime_dir/bootstrap.sh" "$runtime_dir/scripts/"*.sh
}

echo "INSTALL_SETUP"
echo "  dry-run: $(bool_label "$DRY_RUN")"
echo "  binary: $setup_binary"
echo "  setup app: $setup_app"
echo "  version: $version"
validate_setup_app_path

if [ ! -x "$setup_binary" ]; then
  echo "  blocked: setup binary not found; run ./bootstrap.sh build-setup first"
  exit 0
fi

if [ "$setup_app" = "/Applications/Lazyest Setup.app" ]; then
  for process_name in LazyestSetup MacBootstrapSetup; do
    if pgrep -x "$process_name" >/dev/null 2>&1; then
      if ((DRY_RUN)); then
        echo "[dry-run] stop the existing $process_name process"
      else
        pkill -x "$process_name" || true
        sleep 0.3
      fi
    fi
  done
fi

if [ -d "$setup_app" ]; then
  run_cmd rm -rf "$setup_app"
fi
legacy_setup_app="/Applications/MacBootstrapSetup.app"
if [ "$setup_app" = "/Applications/Lazyest Setup.app" ] && [ -d "$legacy_setup_app" ]; then
  run_cmd rm -rf "$legacy_setup_app"
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
  cp "$setup_binary" "$setup_app/Contents/MacOS/LazyestSetup"
  chmod +x "$setup_app/Contents/MacOS/LazyestSetup"
  if [ -f "$ROOT_DIR/setup/LazyestSetup/Assets/AppIcon.icns" ]; then
    cp "$ROOT_DIR/setup/LazyestSetup/Assets/AppIcon.icns" "$setup_app/Contents/Resources/AppIcon.icns"
  fi
  copy_runtime_payload
  printf '%s\n' "Runtime" >"$setup_app/Contents/Resources/ProjectRoot.txt"
  cat >"$setup_app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>LazyestSetup</string>
  <key>CFBundleIdentifier</key>
  <string>com.estaid.mac-bootstrap-setup</string>
  <key>CFBundleName</key>
  <string>Lazyest Setup</string>
  <key>CFBundleDisplayName</key>
  <string>Lazyest Setup</string>
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
  <key>LSMultipleInstancesProhibited</key>
  <true/>
</dict>
</plist>
PLIST
  printf 'APPL????' >"$setup_app/Contents/PkgInfo"
  sign_setup_app
fi

echo "  note: installed one-time setup app only; this does not launch it or apply settings"
