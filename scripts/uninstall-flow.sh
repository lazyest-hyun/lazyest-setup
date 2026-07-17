#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

parse_common_flags "$@"

app="$(flow_app_path)"
plist="$(launch_agent_plist)"
echo "UNINSTALL_FLOW"
echo "  dry-run: $(bool_label "$DRY_RUN")"
echo "  app: $app"
echo "  plist: $plist"

process_name="LazyestFlow"
legacy_process_name="MacBootstrapAgent"
if pgrep -x "$process_name" >/dev/null 2>&1 || pgrep -x "$legacy_process_name" >/dev/null 2>&1; then
  if ((DRY_RUN)); then
    echo "[dry-run] ask Lazyest Flow to quit"
    echo "[dry-run] terminate remaining Lazyest Flow processes if needed"
  else
    /usr/bin/osascript -e 'tell application id "com.estaid.mac-bootstrap-agent" to quit' >/dev/null 2>&1 || true
    for _ in 1 2 3 4 5; do
      if ! pgrep -x "$process_name" >/dev/null 2>&1 && ! pgrep -x "$legacy_process_name" >/dev/null 2>&1; then
        break
      fi
      sleep 0.2
    done
    pkill -x "$process_name" >/dev/null 2>&1 || true
    pkill -x "$legacy_process_name" >/dev/null 2>&1 || true
  fi
else
  echo "  app process already stopped"
fi

if [ -d "$app" ]; then
  run_cmd rm -rf "$app"
else
  echo "  app already absent"
fi
legacy_app="/Applications/MacBootstrapAgent.app"
if [ -d "$legacy_app" ]; then
  run_cmd rm -rf "$legacy_app"
fi

if [ -f "$plist" ]; then
  run_cmd rm "$plist"
else
  echo "  plist already absent"
fi
if pgrep -x "$process_name" >/dev/null 2>&1 || pgrep -x "$legacy_process_name" >/dev/null 2>&1; then
  echo "  warning: Lazyest Flow is still running"
else
  echo "  process: stopped"
fi
echo "UNINSTALL_FLOW_OK"
echo "  note: Flow user settings were preserved"
