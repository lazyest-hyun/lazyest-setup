#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

echo "Desired Dock keep labels:"
printf '  %s\n' "${DOCK_KEEP_LABELS[@]}"
echo
echo "Desired Dock remove labels:"
printf '  %s\n' "${DOCK_REMOVE_LABELS[@]}"
echo

if command -v dockutil >/dev/null 2>&1; then
  echo "dockutil is available. A stable Dock cleanup can be added with explicit apply confirmation."
else
  echo "dockutil is not installed."
  echo "No-install path: use a plist-edit script with careful backup, then restart Dock only after confirmation."
fi

echo
echo "Current Dock labels:"
/usr/bin/python3 <<'PY'
import plistlib, subprocess
try:
    raw = subprocess.check_output(["defaults", "export", "com.apple.dock", "-"], stderr=subprocess.DEVNULL)
    data = plistlib.loads(raw)
    for item in data.get("persistent-apps", []):
        print("  " + (item.get("tile-data", {}).get("file-label") or "<unknown>"))
except Exception:
    print("  unreadable")
PY

