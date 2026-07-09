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

def is_same_rule(candidate):
    text = json.dumps(candidate, sort_keys=True).lower()
    return "right_command" in text and "f18" in text

for profile in config.get("profiles", []):
    simple_modifications = profile.get("simple_modifications")
    if isinstance(simple_modifications, list):
        simple_modifications[:] = [
            item for item in simple_modifications
            if item.get("from", {}).get("key_code") != "right_command"
        ]
    rules = profile.get("complex_modifications", {}).get("rules")
    if isinstance(rules, list):
        rules[:] = [item for item in rules if not is_same_rule(item)]

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
