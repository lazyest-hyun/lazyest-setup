#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

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

export MAC_BOOTSTRAP_DOCK_DRY_RUN="$DRY_RUN"
export MAC_BOOTSTRAP_BACKUP_DIR="$HOME/.local/share/mac-bootstrap/backups"

echo "DOCK_APPLY"
echo "  dry-run: $(bool_label "$DRY_RUN")"
echo "  restart-ui: $(bool_label "$restart_ui")"

dock_booted_out=0
dock_uid="$(id -u)"
restart_dock_agent() {
  if ((dock_booted_out)); then
    launchctl bootstrap "gui/$dock_uid" /System/Library/LaunchAgents/com.apple.Dock.plist 2>/dev/null || true
    launchctl kickstart -k "gui/$dock_uid/com.apple.Dock.agent" 2>/dev/null || true
    dock_booted_out=0
  fi
}

if ((!DRY_RUN)) && ((restart_ui)); then
  # Dock can write its in-memory icon list back to preferences when it exits.
  # Temporarily unload the agent so the imported preference state wins.
  if launchctl bootout "gui/$dock_uid/com.apple.Dock.agent" 2>/dev/null; then
    dock_booted_out=1
    trap restart_dock_agent EXIT
  else
    killall Dock 2>/dev/null || true
  fi
  sleep 1
fi

/usr/bin/python3 <<'PY'
import datetime
import os
import plistlib
import shutil
import subprocess
import sys
from urllib.parse import quote

plist_path = os.path.expanduser("~/Library/Preferences/com.apple.dock.plist")
backup_dir = os.environ["MAC_BOOTSTRAP_BACKUP_DIR"]
dry_run = os.environ.get("MAC_BOOTSTRAP_DOCK_DRY_RUN") == "1"

catalog = [
    ("Apps", ["Apps", "앱", "Launchpad"], "/System/Applications/Apps.app"),
    ("Safari", ["Safari"], "/Applications/Safari.app"),
    ("Notes", ["Notes", "메모"], "/System/Applications/Notes.app"),
    ("System Settings", ["System Settings", "시스템 설정"], "/System/Applications/System Settings.app"),
    ("Calendar", ["Calendar", "캘린더"], "/System/Applications/Calendar.app"),
    ("Messages", ["Messages", "메시지"], "/System/Applications/Messages.app"),
    ("Mail", ["Mail", "메일"], "/System/Applications/Mail.app"),
    ("Maps", ["Maps", "지도"], "/System/Applications/Maps.app"),
    ("Photos", ["Photos", "사진"], "/System/Applications/Photos.app"),
    ("FaceTime", ["FaceTime"], "/System/Applications/FaceTime.app"),
    ("Phone", ["Phone", "전화"], "/System/Applications/Phone.app"),
    ("Contacts", ["Contacts", "연락처"], "/System/Applications/Contacts.app"),
    ("Reminders", ["Reminders", "미리 알림"], "/System/Applications/Reminders.app"),
    ("TV", ["TV"], "/System/Applications/TV.app"),
    ("Music", ["Music", "음악"], "/System/Applications/Music.app"),
    ("Freeform", ["Freeform", "무한 캔버스"], "/System/Applications/Freeform.app"),
    ("App Store", ["App Store"], "/System/Applications/App Store.app"),
    ("iPhone Mirroring", ["iPhone Mirroring", "iPhone 미러링"], "/System/Applications/iPhone Mirroring.app"),
]

def normalized(value):
    return " ".join(str(value).replace("\u00a0", " ").split()).casefold().strip()

keep_labels = {
    normalized(line)
    for line in os.environ.get("MAC_BOOTSTRAP_DOCK_KEEP_LABELS", "").splitlines()
    if normalized(line)
}
if not keep_labels:
    print("  blocked: MAC_BOOTSTRAP_DOCK_KEEP_LABELS is empty")
    sys.exit(2)

managed_aliases = {
    normalized(alias)
    for _, aliases, _ in catalog
    for alias in aliases
}
selected_app_count = sum(
    1
    for _, aliases, _ in catalog
    if not keep_labels.isdisjoint({normalized(alias) for alias in aliases})
)

if not os.path.exists(plist_path):
    print(f"  blocked: Dock plist not found: {plist_path}")
    sys.exit(1)

with open(plist_path, "rb") as handle:
    plist = plistlib.load(handle)

apps = plist.get("persistent-apps", [])
recent_apps = plist.get("recent-apps", [])
kept_items = []
removed = []
kept_recent_items = []
removed_recent = []
present = set()

def item_label(item):
    tile_data = item.get("tile-data", {})
    return str(tile_data.get("file-label", "")).strip()

def should_keep_managed_label(label):
    label_key = normalized(label)
    return label_key in keep_labels

for item in apps:
    label = item_label(item)
    label_key = normalized(label)
    if label_key in managed_aliases:
        if should_keep_managed_label(label):
            kept_items.append(item)
            present.add(label_key)
        else:
            removed.append(label or "<unknown>")
    else:
        kept_items.append(item)

for item in recent_apps:
    label = item_label(item)
    label_key = normalized(label)
    if label_key in managed_aliases and not should_keep_managed_label(label):
        removed_recent.append(label or "<unknown>")
    else:
        kept_recent_items.append(item)

added = []
for canonical, aliases, path in catalog:
    alias_keys = {normalized(alias) for alias in aliases}
    if keep_labels.isdisjoint(alias_keys):
        continue
    if not present.isdisjoint(alias_keys):
        continue
    if not os.path.exists(path):
        print(f"  skip missing app: {canonical} ({path})")
        continue
    added.append(canonical)
    url = "file://" + quote(path)
    kept_items.append({
        "tile-data": {
            "file-data": {
                "_CFURLString": url,
                "_CFURLStringType": 15,
            },
            "file-label": canonical,
            "file-mod-date": 0,
            "file-type": 41,
            "parent-mod-date": 0,
        },
        "tile-type": "file-tile",
    })

print(f"  current Dock app items: {len(apps)}")
print(f"  selected managed apps: {selected_app_count}")
print(f"  remove items: {len(removed)}")
for label in removed:
    print(f"    remove: {label}")
print(f"  remove recent items: {len(removed_recent)}")
for label in removed_recent:
    print(f"    remove recent: {label}")
print(f"  add items: {len(added)}")
for label in added:
    print(f"    add: {label}")

if dry_run:
    print("  result: dry-run only; Dock plist not changed")
    sys.exit(0)

if not removed and not removed_recent and not added:
    print("  result: Dock already matches selection")
    sys.exit(0)

os.makedirs(backup_dir, exist_ok=True)
stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
backup_path = os.path.join(backup_dir, f"com.apple.dock.{stamp}.plist")
shutil.copy2(plist_path, backup_path)

plist["persistent-apps"] = kept_items
plist["recent-apps"] = kept_recent_items
with open(plist_path, "wb") as handle:
    plistlib.dump(plist, handle, fmt=plistlib.FMT_BINARY)
subprocess.run(["defaults", "import", "com.apple.dock", plist_path], check=True)

print(f"  backup: {backup_path}")
print(f"  result: removed {len(removed)} pinned item(s), removed {len(removed_recent)} recent item(s), added {len(added)} item(s)")
PY

if ((DRY_RUN)); then
  exit 0
fi

if ((restart_ui)); then
  if ((dock_booted_out)); then
    restart_dock_agent
    trap - EXIT
  else
    run_cmd killall Dock
  fi
else
  echo "  Dock restart skipped; pass --restart-ui or relaunch Dock to see changes"
fi
