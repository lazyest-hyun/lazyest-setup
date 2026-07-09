#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

parse_common_flags "$@"

app="$(agent_app_path)"
plist="$(launch_agent_plist)"
echo "UNINSTALL_AGENT"
echo "  dry-run: $(bool_label "$DRY_RUN")"
echo "  app: $app"
echo "  plist: $plist"

if pgrep -x MacBootstrapAgent >/dev/null 2>&1; then
  if ((DRY_RUN)); then
    echo "[dry-run] ask MacBootstrapAgent to quit"
    echo "[dry-run] terminate remaining MacBootstrapAgent processes if needed"
  else
    /usr/bin/osascript -e 'tell application id "com.estaid.mac-bootstrap-agent" to quit' >/dev/null 2>&1 || true
    for _ in 1 2 3 4 5; do
      if ! pgrep -x MacBootstrapAgent >/dev/null 2>&1; then
        break
      fi
      sleep 0.2
    done
    if pgrep -x MacBootstrapAgent >/dev/null 2>&1; then
      pkill -x MacBootstrapAgent || true
    fi
  fi
else
  echo "  app process already stopped"
fi

if [ -d "$app" ]; then
  run_cmd rm -rf "$app"
else
  echo "  app already absent"
fi

if [ -f "$plist" ]; then
  run_cmd rm "$plist"
else
  echo "  plist already absent"
fi
if pgrep -x MacBootstrapAgent >/dev/null 2>&1; then
  echo "  warning: MacBootstrapAgent is still running"
else
  echo "  process: stopped"
fi
