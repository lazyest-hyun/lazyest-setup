#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

parse_common_flags "$@"

backup_dir="$HOME/.local/share/mac-bootstrap/backups"
hitoolbox_plist="$HOME/Library/Preferences/com.apple.HIToolbox.plist"

echo "APPLY_INPUT_SOURCES"
echo "  dry-run: $(bool_label "$DRY_RUN")"
echo "  input source: Gureum / Han 2set"
echo "  fallback: keep Apple Korean 2-set until Gureum / Han 2set is registered"

if ((DRY_RUN)); then
  echo "[dry-run] register Gureum / Han 2set input source"
  echo "[dry-run] keep Apple Korean 2-set fallback until Gureum is registered"
  exit 0
fi

if [ ! -d "/Library/Input Methods/Gureum.app" ] && [ ! -d "$HOME/Library/Input Methods/Gureum.app" ]; then
  echo "  blocked: Gureum Input Method is not installed"
  exit 1
fi

mkdir -p "$backup_dir"

if command -v swift >/dev/null 2>&1; then
  tis_status_file="$(mktemp /tmp/mac-bootstrap-gureum-tis.XXXXXX)"
  TIS_STATUS_FILE="$tis_status_file" swift - <<'SWIFT'
import Carbon
import Foundation

let statusPath = ProcessInfo.processInfo.environment["TIS_STATUS_FILE"] ?? ""

func stringProp(_ source: TISInputSource, _ key: CFString) -> String {
    guard let raw = TISGetInputSourceProperty(source, key) else { return "" }
    return Unmanaged<CFString>.fromOpaque(raw).takeUnretainedValue() as String
}

let appURL = URL(fileURLWithPath: "/Library/Input Methods/Gureum.app") as CFURL
_ = TISRegisterInputSource(appURL)

let sources = TISCreateInputSourceList(nil, true)?.takeRetainedValue() as? [TISInputSource] ?? []
let wantedIDs = [
    "org.youknowone.inputmethod.Korean",
    "org.youknowone.inputmethod.Gureum.system",
    "org.youknowone.inputmethod.Gureum.han2",
]
var enabled = 0
for id in wantedIDs {
    if let source = sources.first(where: { stringProp($0, kTISPropertyInputSourceID) == id }) {
        let status = TISEnableInputSource(source)
        if status == noErr { enabled += 1 }
    }
}
if enabled == 0 {
    fputs("  blocked: Gureum input sources were not visible to macOS TIS\n", stderr)
    exit(1)
}
let registeredSources = TISCreateInputSourceList(nil, false)?.takeRetainedValue() as? [TISInputSource] ?? []
let registered = registeredSources.contains {
    stringProp($0, kTISPropertyInputSourceID) == "org.youknowone.inputmethod.Gureum.han2" &&
        stringProp($0, kTISPropertyBundleID) == "org.youknowone.inputmethod.Gureum"
}
if registered && !statusPath.isEmpty {
    try? "visible\n".write(toFile: statusPath, atomically: true, encoding: .utf8)
}
print("  result: Gureum input sources enabled through macOS TIS")
SWIFT
  export GUREUM_TIS_VISIBLE="$(cat "$tis_status_file" 2>/dev/null || true)"
  rm -f "$tis_status_file"
else
  echo "  note: swift not found; falling back to HIToolbox defaults only"
  export GUREUM_TIS_VISIBLE=""
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

def has_same_source(a, b):
    keys = ["Bundle ID", "Input Mode", "InputSource ID", "InputSourceKind"]
    return all(a.get(key) == b.get(key) for key in keys)

apple_korean_base = {
    "Bundle ID": "com.apple.inputmethod.Korean",
    "InputSourceKind": "Keyboard Input Method",
}

apple_korean_han2 = {
    "Bundle ID": "com.apple.inputmethod.Korean",
    "Input Mode": "com.apple.inputmethod.Korean.2SetKorean",
    "InputSourceKind": "Input Mode",
}

gureum_base = {
    "Bundle ID": "org.youknowone.inputmethod.Gureum",
    "InputSource ID": "org.youknowone.inputmethod.Korean",
    "InputSourceKind": "Keyboard Input Method",
    "LocalizedName": "Gureum",
}

gureum_system = {
    "Bundle ID": "org.youknowone.inputmethod.Gureum",
    "Input Mode": "org.youknowone.inputmethod.Gureum.system",
    "InputSource ID": "org.youknowone.inputmethod.Gureum.system",
    "InputSourceKind": "Input Mode",
    "LocalizedName": "Gureum",
}

gureum = {
    "Bundle ID": "org.youknowone.inputmethod.Gureum",
    "Input Mode": "org.youknowone.inputmethod.Gureum.han2",
    "InputSource ID": "org.youknowone.inputmethod.Gureum.han2",
    "InputSourceKind": "Input Mode",
    "KeyboardLayout": "com.apple.inputmethod.Korean.2SetKorean",
    "LocalizedName": "Gureum",
}

hitoolbox = defaults_export("com.apple.HIToolbox")
gureum_visible = os.environ.get("GUREUM_TIS_VISIBLE") == "visible"
for key in ["AppleEnabledInputSources", "AppleInputSourceHistory"]:
    items = hitoolbox.get(key, [])
    if key == "AppleEnabledInputSources" and not gureum_visible:
        if not any(has_same_source(item, apple_korean_base) for item in items):
            items.append(dict(apple_korean_base))
        if not any(has_same_source(item, apple_korean_han2) for item in items):
            items.append(dict(apple_korean_han2))
    if gureum_visible:
        items = [item for item in items if not has_same_source(item, apple_korean_base)]
        items = [item for item in items if not has_same_source(item, apple_korean_han2)]
    items = [item for item in items if not has_same_source(item, gureum_base)]
    items = [item for item in items if not has_same_source(item, gureum_system)]
    items = [item for item in items if not has_same_source(item, gureum)]
    if key == "AppleEnabledInputSources":
        items.append(dict(gureum_base))
        items.append(dict(gureum_system))
        items.append(dict(gureum))
    hitoolbox[key] = items

selected = hitoolbox.get("AppleSelectedInputSources", [])
if gureum_visible:
    selected = [item for item in selected if not has_same_source(item, apple_korean_base)]
    selected = [item for item in selected if not has_same_source(item, apple_korean_han2)]
selected = [item for item in selected if not has_same_source(item, gureum_base)]
selected.append(dict(gureum_base))
if not any(has_same_source(item, gureum) for item in selected):
    selected.append(dict(gureum))
hitoolbox["AppleSelectedInputSources"] = selected

backup(hitoolbox_plist, "com.apple.HIToolbox")
defaults_import("com.apple.HIToolbox", hitoolbox)
print("  result: Gureum / Han 2set input source applied")
if not gureum_visible:
    print("  warning: kept Apple Korean 2-set fallback until Gureum / Han 2set is registered")
PY

if command -v swift >/dev/null 2>&1; then
  swift - <<'SWIFT'
import Carbon
import Foundation

func stringProp(_ source: TISInputSource, _ key: CFString) -> String {
    guard let raw = TISGetInputSourceProperty(source, key) else { return "" }
    return Unmanaged<CFString>.fromOpaque(raw).takeUnretainedValue() as String
}

let sources = TISCreateInputSourceList(nil, true)?.takeRetainedValue() as? [TISInputSource] ?? []
let appURL = URL(fileURLWithPath: "/Library/Input Methods/Gureum.app") as CFURL
_ = TISRegisterInputSource(appURL)
for id in ["org.youknowone.inputmethod.Korean", "org.youknowone.inputmethod.Gureum.system", "org.youknowone.inputmethod.Gureum.han2"] {
    if let source = sources.first(where: { stringProp($0, kTISPropertyInputSourceID) == id }) {
        _ = TISEnableInputSource(source)
    }
}
print("  result: Gureum input sources refreshed through macOS TIS")
SWIFT
fi
