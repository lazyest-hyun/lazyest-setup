#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

require_python

restart_ui=1
while (($#)); do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      ;;
    --restart-ui)
      restart_ui=1
      ;;
    --no-restart-ui)
      restart_ui=0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 2
      ;;
  esac
  shift
done

remove_labels="$(printf '%s\n' "${DOCK_REMOVE_LABELS[@]}")"
export LAZYEST_SETUP_DOCK_REMOVE_LABELS="$remove_labels"
export LAZYEST_SETUP_DOCK_DRY_RUN="$DRY_RUN"
export LAZYEST_SETUP_BACKUP_DIR

echo "DOCK_CLEANUP"
echo "  dry-run: $(bool_label "$DRY_RUN")"
echo "  restart-ui: $(bool_label "$restart_ui")"

/usr/bin/python3 <<'PY'
import datetime
import os
import plistlib
import shutil
import sys

plist_path = os.path.expanduser("~/Library/Preferences/com.apple.dock.plist")
backup_dir = os.environ["LAZYEST_SETUP_BACKUP_DIR"]
dry_run = os.environ.get("LAZYEST_SETUP_DOCK_DRY_RUN") == "1"
def normalized(value):
    return " ".join(str(value).replace("\u00a0", " ").split()).strip()

remove_labels = {
    normalized(line)
    for line in os.environ.get("LAZYEST_SETUP_DOCK_REMOVE_LABELS", "").splitlines()
    if normalized(line)
}

if not os.path.exists(plist_path):
    print(f"  blocked: Dock plist not found: {plist_path}")
    sys.exit(1)

with open(plist_path, "rb") as handle:
    plist = plistlib.load(handle)

apps = plist.get("persistent-apps", [])
kept = []
removed = []

for item in apps:
    tile_data = item.get("tile-data", {})
    label = str(tile_data.get("file-label", "")).strip()
    if normalized(label) in remove_labels:
        removed.append(label or "<unknown>")
    else:
        kept.append(item)

print(f"  current Dock app items: {len(apps)}")
print(f"  matched remove items: {len(removed)}")
for label in removed:
    print(f"    remove: {label}")

if dry_run:
    print("  result: dry-run only; Dock plist not changed")
    sys.exit(0)

if not removed:
    print("  result: no matching Dock items; nothing changed")
    sys.exit(0)

os.makedirs(backup_dir, exist_ok=True)
stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
backup_path = os.path.join(backup_dir, f"com.apple.dock.{stamp}.plist")
shutil.copy2(plist_path, backup_path)

plist["persistent-apps"] = kept
with open(plist_path, "wb") as handle:
    plistlib.dump(plist, handle, fmt=plistlib.FMT_BINARY)

print(f"  backup: {backup_path}")
print(f"  result: removed {len(removed)} Dock item(s)")
PY

if ((DRY_RUN)); then
  exit 0
fi

if ((restart_ui)); then
  run_cmd killall Dock
else
  echo "  Dock restart skipped; pass --restart-ui or relaunch Dock to see changes"
fi
