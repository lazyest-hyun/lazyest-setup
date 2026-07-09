#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "APPLY_KOREAN_INPUT"
echo "  note: compatibility command; runs Gureum Option key, input sources, input shortcuts, and Globe/Fn key settings"
"$SCRIPT_DIR/apply-gureum-option-key.sh" "$@"
"$SCRIPT_DIR/apply-input-sources.sh" "$@"
"$SCRIPT_DIR/apply-input-shortcuts.sh" "$@"
"$SCRIPT_DIR/apply-globe-key.sh" "$@"
