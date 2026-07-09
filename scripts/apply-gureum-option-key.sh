#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=/dev/null
source "$ROOT_DIR/scripts/lib.sh"

parse_common_flags "$@"

echo "APPLY_GUREUM_OPTION_KEY"
echo "  setting: org.youknowone.Gureum OptionKeyBehavior = 0"
echo "  effect: use macOS Option-key special characters while typing with Gureum"

if [ ! -d "/Library/Input Methods/Gureum.app" ] && [ ! -d "$HOME/Library/Input Methods/Gureum.app" ]; then
  echo "  blocked: Gureum Input Method is not installed"
  exit 1
fi

run_cmd /usr/bin/defaults write org.youknowone.Gureum OptionKeyBehavior -int 0

if pgrep -x Gureum >/dev/null 2>&1; then
  run_cmd /usr/bin/killall Gureum
fi

echo "  result: Gureum Option-key special characters enabled"
