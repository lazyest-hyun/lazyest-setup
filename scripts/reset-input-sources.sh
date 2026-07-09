#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

parse_common_flags "$@"

backup_dir="$HOME/.local/share/mac-bootstrap/backups"
hitoolbox_plist="$HOME/Library/Preferences/com.apple.HIToolbox.plist"

echo "RESET_INPUT_SOURCES"
echo "  dry-run: $(bool_label "$DRY_RUN")"
echo "  input source: Apple Korean 2-set"
echo "  reset: remove Gureum / Han 2set from enabled and selected input sources"

if ((DRY_RUN)); then
  echo "[dry-run] enable Apple Korean 2-set through macOS TIS"
  echo "[dry-run] remove Gureum / Han 2set from HIToolbox enabled and selected input sources"
  exit 0
fi

mkdir -p "$backup_dir"

if command -v swift >/dev/null 2>&1; then
  swift - <<'SWIFT'
import Carbon
import Foundation

func stringProp(_ source: TISInputSource, _ key: CFString) -> String {
    guard let raw = TISGetInputSourceProperty(source, key) else { return "" }
    return Unmanaged<CFString>.fromOpaque(raw).takeUnretainedValue() as String
}

let sources = TISCreateInputSourceList(nil, true)?.takeRetainedValue() as? [TISInputSource] ?? []
let enableIDs = [
    "com.apple.inputmethod.Korean",
    "com.apple.inputmethod.Korean.2SetKorean",
]
let disableIDs = [
    "org.youknowone.inputmethod.Korean",
    "org.youknowone.inputmethod.Gureum.system",
    "org.youknowone.inputmethod.Gureum.han2",
]
for id in enableIDs {
    if let source = sources.first(where: { stringProp($0, kTISPropertyInputSourceID) == id }) {
        _ = TISEnableInputSource(source)
    }
}
for id in disableIDs {
    if let source = sources.first(where: { stringProp($0, kTISPropertyInputSourceID) == id }) {
        _ = TISDisableInputSource(source)
    }
}
print("  result: Apple Korean 2-set enabled through macOS TIS")
SWIFT
else
  echo "  note: swift not found; falling back to HIToolbox defaults only"
fi

/usr/bin/python3 <<'PY'
import datetime
import os
import plistlib
import shutil
import subprocess

backup_dir = os.path.expanduser("~/.local/share/mac-bootstrap/backups")
hitoolbox_plist = os.path.expanduser("~/Library/Preferences/com.apple.HIToolbox.plist")

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

def defaults_import(domain, data):
    raw = plistlib.dumps(data, fmt=plistlib.FMT_XML)
    subprocess.run(["defaults", "import", domain, "-"], input=raw, check=True)

def same_source(a, b):
    keys = ["Bundle ID", "Input Mode", "InputSource ID", "InputSourceKind"]
    return all(a.get(key) == b.get(key) for key in keys)

def is_gureum(item):
    return item.get("Bundle ID") == "org.youknowone.inputmethod.Gureum" or \
        str(item.get("Input Mode", "")).startswith("org.youknowone.inputmethod.Gureum") or \
        str(item.get("InputSource ID", "")).startswith("org.youknowone.inputmethod.Gureum") or \
        item.get("InputSource ID") == "org.youknowone.inputmethod.Korean"

apple_korean_base = {
    "Bundle ID": "com.apple.inputmethod.Korean",
    "InputSource ID": "com.apple.inputmethod.Korean",
    "InputSourceKind": "Keyboard Input Method",
}

apple_korean_han2 = {
    "Bundle ID": "com.apple.inputmethod.Korean",
    "Input Mode": "com.apple.inputmethod.Korean.2SetKorean",
    "InputSource ID": "com.apple.inputmethod.Korean.2SetKorean",
    "InputSourceKind": "Input Mode",
}

hitoolbox = defaults_export("com.apple.HIToolbox")
for key in ["AppleEnabledInputSources", "AppleInputSourceHistory"]:
    items = [item for item in hitoolbox.get(key, []) if not is_gureum(item)]
    if not any(same_source(item, apple_korean_base) for item in items):
        items.append(dict(apple_korean_base))
    if not any(same_source(item, apple_korean_han2) for item in items):
        items.append(dict(apple_korean_han2))
    hitoolbox[key] = items

selected = [item for item in hitoolbox.get("AppleSelectedInputSources", []) if not is_gureum(item)]
selected = [item for item in selected if not same_source(item, apple_korean_base)]
selected = [item for item in selected if not same_source(item, apple_korean_han2)]
selected.append(dict(apple_korean_base))
selected.append(dict(apple_korean_han2))
hitoolbox["AppleSelectedInputSources"] = selected

backup(hitoolbox_plist, "com.apple.HIToolbox")
defaults_import("com.apple.HIToolbox", hitoolbox)
print("  result: Apple Korean 2-set input source reset")
PY

if [ -x /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings ]; then
  run_cmd /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
fi
