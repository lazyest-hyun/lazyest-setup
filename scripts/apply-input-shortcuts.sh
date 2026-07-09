#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

parse_common_flags "$@"

backup_dir="$HOME/.local/share/mac-bootstrap/backups"
hotkeys_plist="$HOME/Library/Preferences/com.apple.symbolichotkeys.plist"

echo "APPLY_INPUT_SHORTCUTS"
echo "  dry-run: $(bool_label "$DRY_RUN")"
echo "  previous input source: disabled"
echo "  next input source: F18"

if ((DRY_RUN)); then
  echo "[dry-run] set AppleSymbolicHotKeys 60, 64 and 65 disabled"
  echo "[dry-run] set AppleSymbolicHotKeys 61 enabled with F18"
  exit 0
fi

mkdir -p "$backup_dir"

/usr/bin/python3 <<'PY'
import datetime
import os
import plistlib
import shutil
import subprocess

backup_dir = os.path.expanduser("~/.local/share/mac-bootstrap/backups")
hotkeys_plist = os.path.expanduser("~/Library/Preferences/com.apple.symbolichotkeys.plist")

def backup(path, label):
    if os.path.exists(path):
        stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
        out = os.path.join(backup_dir, f"{label}.{stamp}.plist")
        shutil.copy2(path, out)
        print(f"  backup: {out}")

def defaults_export(domain):
    try:
        raw = subprocess.check_output(["defaults", "export", domain, "-"], stderr=subprocess.DEVNULL)
        return plistlib.loads(raw)
    except Exception:
        return {}

hotkeys = defaults_export("com.apple.symbolichotkeys")
symbolic = hotkeys.setdefault("AppleSymbolicHotKeys", {})
for key in ["60", "64", "65"]:
    symbolic[key] = {
        "enabled": False,
        "value": {"type": "standard", "parameters": [32, 49, 262144]},
    }
symbolic["61"] = {
    "enabled": True,
    "value": {"type": "standard", "parameters": [65535, 79, 8388608]},
}
backup(hotkeys_plist, "com.apple.symbolichotkeys")
raw = plistlib.dumps(hotkeys, fmt=plistlib.FMT_XML)
subprocess.run(["defaults", "import", "com.apple.symbolichotkeys", "-"], input=raw, check=True)
print("  result: input-source shortcuts applied")
PY

if [ -x /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings ]; then
  run_cmd /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
fi
