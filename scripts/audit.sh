#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

echo "READ_ONLY_AUDIT_OK"
echo
echo "Project"
echo "  root: $ROOT_DIR"
echo "  files:"
find "$ROOT_DIR" -maxdepth 3 -type f | sed "s#^$ROOT_DIR/#    #"
echo

echo "Screenshots"
screenshot_dir="$(effective_screenshot_dir)"
if [ -d "$screenshot_dir" ]; then
  echo "  folder: exists ($screenshot_dir)"
else
  echo "  folder: missing ($screenshot_dir)"
fi
echo "  location: $(read_default com.apple.screencapture location)"
echo

echo "Applications"
for app in \
  "Google Chrome" \
  "Codex" \
  "Claude" \
  "Microsoft Teams" \
  "Slack" \
  "Karabiner-Elements" \
  "Gureum" \
  "Amphetamine" \
  "LinearMouse" \
  "DockAnchor" \
  "Hammerspoon" \
  "Raycast" \
  "Rectangle" \
  "MonitorControl" \
  "Hidden Bar"; do
  if app_exists "$app"; then
    printf '  present: %s\n' "$app"
  else
    printf '  missing: %s\n' "$app"
  fi
done

echo "  input methods:"
find "/Library/Input Methods" "$HOME/Library/Input Methods" -maxdepth 1 -name '*.app' 2>/dev/null \
  | sed "s#^#    #" || true
echo

echo "Karabiner"
karabiner_config="$HOME/.config/karabiner/karabiner.json"
if [ -f "$karabiner_config" ]; then
  echo "  config: present"
  /usr/bin/python3 - "$karabiner_config" <<'PY'
import json, sys
path = sys.argv[1]
try:
    data = json.load(open(path))
    text = json.dumps(data).lower()
    print(f"  right_command_mentions: {text.count('right_command')}")
    print(f"  f18_mentions: {text.count('f18')}")
    print(f"  right_command_to_f18_likely: {'yes' if 'right_command' in text and 'f18' in text else 'no'}")
except Exception:
    print("  summary: unreadable")
PY
else
  echo "  config: missing"
fi
echo

echo "Text and input defaults"
echo "  ApplePressAndHoldEnabled: $(read_default -g ApplePressAndHoldEnabled)"
echo "  NSAutomaticSpellingCorrectionEnabled: $(read_default -g NSAutomaticSpellingCorrectionEnabled)"
echo "  NSAutomaticPeriodSubstitutionEnabled: $(read_default -g NSAutomaticPeriodSubstitutionEnabled)"
echo "  NSAutomaticInlinePredictionEnabled: $(read_default -g NSAutomaticInlinePredictionEnabled)"
/usr/bin/python3 <<'PY'
import plistlib, subprocess, re
try:
    raw = subprocess.check_output(["defaults", "export", "com.apple.HIToolbox", "-"], stderr=subprocess.DEVNULL)
    data = plistlib.loads(raw)
    for key in ["AppleSelectedInputSources", "AppleEnabledInputSources"]:
        items = data.get(key, [])
        print(f"  {key}: {len(items)} item(s)")
        for item in items:
            label = " / ".join(str(v) for v in [
                item.get("LocalizedName"),
                item.get("InputSourceKind"),
                item.get("Bundle ID"),
                item.get("InputSource ID"),
                item.get("KeyboardLayout Name"),
            ] if v)
            if re.search(r"Gureum|구름|2-Set|Dubeolsik|두벌|Korean|Hangul|ABC|com\.apple\.keylayout", label, re.I):
                print(f"    {label}")
except Exception:
    print("  HIToolbox: unreadable")
PY
echo

echo "Input source hotkeys"
/usr/bin/python3 <<'PY'
import plistlib, subprocess
try:
    raw = subprocess.check_output(["defaults", "export", "com.apple.symbolichotkeys", "-"], stderr=subprocess.DEVNULL)
    data = plistlib.loads(raw)
    keys = data.get("AppleSymbolicHotKeys", {})
    for key in ["60", "61"]:
        item = keys.get(key, {})
        print(f"  {key}: enabled={item.get('enabled', '<missing>')} params={item.get('value', {}).get('parameters', '<missing>')}")
except Exception:
    print("  symbolichotkeys: unreadable")
PY
echo

echo "Dock"
/usr/bin/python3 <<'PY'
import plistlib, subprocess
try:
    raw = subprocess.check_output(["defaults", "export", "com.apple.dock", "-"], stderr=subprocess.DEVNULL)
    data = plistlib.loads(raw)
    apps = data.get("persistent-apps", [])
    print(f"  persistent apps: {len(apps)}")
    for item in apps:
        label = item.get("tile-data", {}).get("file-label") or item.get("tile-data", {}).get("bundle-identifier") or "<unknown>"
        print(f"    {label}")
except Exception:
    print("  persistent apps: unreadable")
PY
echo

echo "WindowManager and wallpaper"
echo "  EnableStandardClickToShowDesktop: $(read_default com.apple.WindowManager EnableStandardClickToShowDesktop)"
echo "  Dock autohide: $(read_default com.apple.dock autohide)"
echo "  Stage Manager GloballyEnabled: $(read_default com.apple.WindowManager GloballyEnabled)"
db="$HOME/Library/Application Support/Dock/desktoppicture.db"
if [ -f "$db" ]; then
  sqlite3 "$db" 'select distinct value from data where value is not null and value != "" limit 5;' 2>/dev/null \
    | sed "s#^#  wallpaper: #" || echo "  wallpaper: unreadable"
else
  echo "  wallpaper: desktop picture db missing"
fi
