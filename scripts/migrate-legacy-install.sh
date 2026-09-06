#!/usr/bin/env bash
set -euo pipefail
# Compatibility only: clean the recognized predecessor after the new app is safely installed.
legacy_app="/Applications/MacBootstrapSetup.app"
if [ -d "$legacy_app" ]; then
  identity="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$legacy_app/Contents/Info.plist" 2>/dev/null || true)"
  if [ "$identity" = "com.estaid.mac-bootstrap-setup" ]; then
    /usr/bin/pkill -x MacBootstrapSetup >/dev/null 2>&1 || true
    /bin/rm -rf "$legacy_app"
  fi
fi
