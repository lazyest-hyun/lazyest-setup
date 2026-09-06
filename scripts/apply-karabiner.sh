#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

require_python

parse_common_flags "$@"

config_dir="$HOME/.config/karabiner"
config_path="$config_dir/karabiner.json"
asset_path="$config_dir/assets/complex_modifications/right_command_to_f18.json"
backup_dir="$LAZYEST_SETUP_BACKUP_DIR"

echo "APPLY_KARABINER"
echo "  dry-run: $(bool_label "$DRY_RUN")"
echo "  config: $config_path"
echo "  asset: $asset_path"

if ((DRY_RUN)); then
  echo "[dry-run] create/update right Command -> F18 complex modification"
  exit 0
fi

if ! app_exists "Karabiner-Elements"; then
  echo "  blocked: Karabiner-Elements.app is not installed"
  exit 1
fi

mkdir -p "$(dirname "$asset_path")" "$backup_dir"

/usr/bin/python3 <<'PY'
import datetime
import json
import os
import shutil

config_path = os.path.expanduser("~/.config/karabiner/karabiner.json")
asset_path = os.path.expanduser("~/.config/karabiner/assets/complex_modifications/right_command_to_f18.json")
backup_dir = os.environ["LAZYEST_SETUP_BACKUP_DIR"]

rule = {
    "description": "Lazyest Setup: right_command to F18",
    "manipulators": [
        {
            "type": "basic",
            "from": {
                "key_code": "right_command",
                "modifiers": {"optional": ["any"]},
            },
            "to": [{"key_code": "f18"}],
        }
    ],
}

asset = {
    "title": "Lazyest Setup",
    "rules": [rule],
}

os.makedirs(os.path.dirname(config_path), exist_ok=True)
os.makedirs(os.path.dirname(asset_path), exist_ok=True)
os.makedirs(backup_dir, exist_ok=True)

if os.path.exists(config_path):
    stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    backup_path = os.path.join(backup_dir, f"karabiner.{stamp}.json")
    shutil.copy2(config_path, backup_path)
    with open(config_path, "r", encoding="utf-8") as handle:
        config = json.load(handle)
    print(f"  backup: {backup_path}")
else:
    config = {
        "global": {"show_in_menu_bar": False},
        "profiles": [
            {
                "name": "Default profile",
                "selected": True,
                "complex_modifications": {"rules": []},
            }
        ],
    }
    print("  backup: none; created new config")

profiles = config.setdefault("profiles", [])
if not profiles:
    profiles.append({"name": "Default profile", "selected": True, "complex_modifications": {"rules": []}})

profile = next((item for item in profiles if item.get("selected")), profiles[0])
simple_modifications = profile.get("simple_modifications")
if not isinstance(simple_modifications, list):
    simple_modifications = []
    profile["simple_modifications"] = simple_modifications

complex_modifications = profile.get("complex_modifications")
if not isinstance(complex_modifications, dict):
    complex_modifications = {}
    profile["complex_modifications"] = complex_modifications

rules = complex_modifications.get("rules")
if not isinstance(rules, list):
    rules = []
    complex_modifications["rules"] = rules

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

def remove_legacy_simple_mappings(container):
    mappings = container.get("simple_modifications")
    if isinstance(mappings, list):
        mappings[:] = [item for item in mappings if not is_right_command_to_f18(item)]

owned_rule_descriptions = {
    rule["description"],
    "MacBootstrap: right_command to F18",
}
rules[:] = [
    item for item in rules
    if not isinstance(item, dict) or item.get("description") not in owned_rule_descriptions
]

remove_legacy_simple_mappings(profile)
for device in profile.get("devices", []):
    if isinstance(device, dict):
        remove_legacy_simple_mappings(device)

rules.insert(0, rule)

with open(asset_path, "w", encoding="utf-8") as handle:
    json.dump(asset, handle, ensure_ascii=False, indent=2)
    handle.write("\n")

with open(config_path, "w", encoding="utf-8") as handle:
    json.dump(config, handle, ensure_ascii=False, indent=2)
    handle.write("\n")

print("  result: right Command -> F18 rule applied")
PY
