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
import json
import sys

path = sys.argv[1]

def is_right_command_to_f18(candidate):
    if not isinstance(candidate, dict):
        return False
    source = candidate.get("from")
    targets = candidate.get("to")
    return (
        isinstance(source, dict)
        and source.get("key_code") == "right_command"
        and isinstance(targets, list)
        and any(isinstance(target, dict) and target.get("key_code") == "f18" for target in targets)
    )

def has_legacy_simple_mapping(profile):
    containers = [profile]
    containers.extend(item for item in profile.get("devices", []) if isinstance(item, dict))
    for container in containers:
        mappings = container.get("simple_modifications")
        if isinstance(mappings, list) and any(is_right_command_to_f18(item) for item in mappings):
            return True
    return False

try:
    with open(path, "r", encoding="utf-8") as handle:
        data = json.load(handle)
    profiles = data.get("profiles", [])
    selected = next((item for item in profiles if isinstance(item, dict) and item.get("selected")), None)
    if selected is None:
        selected = next((item for item in profiles if isinstance(item, dict)), None)
    if selected is None:
        raise ValueError("no Karabiner profile")

    rules = selected.get("complex_modifications", {}).get("rules", [])
    complex_applied = any(
        isinstance(rule, dict)
        and rule.get("description") == "MacBootstrap: right_command to F18"
        and any(
            isinstance(manipulator, dict)
            and manipulator.get("type") == "basic"
            and is_right_command_to_f18(manipulator)
            for manipulator in rule.get("manipulators", [])
        )
        for rule in rules
    )
    legacy_simple = has_legacy_simple_mapping(selected)
    print(f"  right_command_to_f18_complex: {'yes' if complex_applied else 'no'}")
    print(f"  legacy_simple_mapping_present: {'yes' if legacy_simple else 'no'}")
    print(f"  right_command_to_f18_applied: {'yes' if complex_applied and not legacy_simple else 'no'}")
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
