#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

parse_common_flags "$@"

config_path="$HOME/.config/karabiner/karabiner.json"
asset_path="$HOME/.config/karabiner/assets/complex_modifications/right_command_to_f18.json"
backup_dir="$HOME/.local/share/mac-bootstrap/backups"

echo "RESET_KARABINER"
echo "  dry-run: $(bool_label "$DRY_RUN")"
echo "  config: $config_path"

if ((DRY_RUN)); then
  echo "[dry-run] remove right Command -> F18 Karabiner rule"
  echo "[dry-run] remove $asset_path"
  exit 0
fi

mkdir -p "$backup_dir"

if [ ! -f "$config_path" ]; then
  echo "  config already absent"
else
  /usr/bin/python3 <<'PY'
import datetime
import json
import os
import shutil

config_path = os.path.expanduser("~/.config/karabiner/karabiner.json")
backup_dir = os.path.expanduser("~/.local/share/mac-bootstrap/backups")

stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
backup_path = os.path.join(backup_dir, f"karabiner.{stamp}.json")
shutil.copy2(config_path, backup_path)
print(f"  backup: {backup_path}")

with open(config_path, "r", encoding="utf-8") as handle:
    config = json.load(handle)

owned_rule_description = "MacBootstrap: right_command to F18"

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

for profile in config.get("profiles", []):
    if not isinstance(profile, dict):
        continue
    remove_legacy_simple_mappings(profile)
    for device in profile.get("devices", []):
        if isinstance(device, dict):
            remove_legacy_simple_mappings(device)
    rules = profile.get("complex_modifications", {}).get("rules")
    if isinstance(rules, list):
        rules[:] = [
            item for item in rules
            if not isinstance(item, dict) or item.get("description") != owned_rule_description
        ]

with open(config_path, "w", encoding="utf-8") as handle:
    json.dump(config, handle, ensure_ascii=False, indent=2)
    handle.write("\n")

print("  result: right Command -> F18 rule removed")
PY
fi

if [ -f "$asset_path" ]; then
  run_cmd rm "$asset_path"
else
  echo "  asset already absent"
fi
