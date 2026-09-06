#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

parse_common_flags "$@"

setup_binary="$(setup_binary_path)"
setup_app="$(setup_app_path)"
version="$(app_version)"
codesign_identity="${LAZYEST_CODESIGN_IDENTITY:--}"

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
  "$ROOT_DIR/scripts/prepare-release-binary.sh" "$setup_app/Contents/MacOS/LazyestSetup"
  if codesign_identity_available; then
    echo "  codesign: $codesign_identity"
    if [[ "$codesign_identity" == Developer\ ID\ Application:* ]]; then
      if codesign --force --deep --options runtime --timestamp --sign "$codesign_identity" "$setup_app"; then
        return
      fi
    elif codesign --force --deep --options runtime --timestamp=none --sign "$codesign_identity" "$setup_app"; then
      return
    fi
    echo "  blocked: requested code signing failed" >&2
    return 1
  elif [ "$codesign_identity" != "-" ]; then
    echo "  blocked: requested signing identity is not available" >&2
    return 1
  else
    echo "  codesign: ad-hoc (local build; use LAZYEST_CODESIGN_IDENTITY for distribution)"
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

# Every install builds current source, including a fresh clone and UI edits.
# Build and sign away from the installed copy so a failure leaves it usable.
"$SCRIPT_DIR/build-setup.sh" "$@"
if ((!DRY_RUN)) && [ ! -x "$setup_binary" ]; then
  echo "  blocked: setup build did not produce an executable" >&2
  exit 1
fi

target_app="$setup_app"
staging_root=""
cleanup_staging() {
  if [ -n "$staging_root" ] && [ -d "$staging_root" ]; then
    rm -rf "$staging_root"
  fi
}
trap cleanup_staging EXIT
if ((!DRY_RUN)); then
  mkdir -p "$(dirname "$target_app")"
  staging_root="$(mktemp -d "$(dirname "$target_app")/.lazyest-setup-install.XXXXXX")"
  setup_app="$staging_root/Lazyest Setup.app"
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
  <string>com.lazyest.setup</string>
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
  <key>NSAppleEventsUsageDescription</key>
  <string>선택한 데스크톱 설정을 적용하고 앱 설치를 Terminal에서 시작합니다.</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSMultipleInstancesProhibited</key>
  <true/>
</dict>
</plist>
PLIST
  printf 'APPL????' >"$setup_app/Contents/PkgInfo"
  sign_setup_app
  codesign --verify --deep --strict "$setup_app"

  if [ "$target_app" = "/Applications/Lazyest Setup.app" ]; then
    # The source build is complete before replacing only this application.
    pkill -x LazyestSetup >/dev/null 2>&1 || true
  fi
  previous_app="$staging_root/previous.app"
  if [ -d "$target_app" ]; then
    mv "$target_app" "$previous_app"
  fi
  if ! mv "$setup_app" "$target_app"; then
    if [ -d "$previous_app" ]; then mv "$previous_app" "$target_app"; fi
    echo "  blocked: could not install app; previous version restored" >&2
    exit 1
  fi
  if [ "$target_app" = "/Applications/Lazyest Setup.app" ]; then
    "$SCRIPT_DIR/migrate-legacy-install.sh"
  fi
fi

echo "  note: installed one-time setup app only; this does not launch it or apply settings"
