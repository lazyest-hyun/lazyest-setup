#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

brew_status="missing"
if command -v brew >/dev/null 2>&1; then
  brew_status="present"
fi

echo "INSTALL_PLAN"
echo "  Homebrew: $brew_status"
echo "  policy: do not install Homebrew; do not force brew installs"
echo "  Raycast: optional install candidate only; no toolkit feature depends on Raycast"
echo "  Hammerspoon: excluded"
echo
echo "Reset-state app audit only:"
for app in "${RESET_STATE_APPS[@]}"; do
  if app_exists "$app"; then
    echo "  present: $app"
  else
    echo "  missing: $app"
  fi
done
echo
echo "Optional candidates:"
for app in "${INSTALL_CANDIDATES[@]}"; do
  case "$app" in
    Raycast)
      url="https://www.raycast.com/download"
      note="optional; no workflow dependency"
      status="missing"
      app_exists "$app" && status="present"
      ;;
    Claude)
      url="https://claude.ai/download"
      note="manual download recommended"
      status="missing"
      app_exists "$app" && status="present"
      ;;
    "Microsoft Teams")
      url="https://www.microsoft.com/microsoft-teams/download-app"
      note="already assumed optional for this toolkit"
      status="missing"
      app_exists "$app" && status="present"
      ;;
    Slack)
      url="https://slack.com/downloads/mac"
      note="optional team chat"
      status="missing"
      app_exists "$app" && status="present"
      ;;
    Karabiner-Elements)
      url="https://karabiner-elements.pqrs.org/"
      note="only if right Command -> F18 is required"
      status="missing"
      app_exists "$app" && status="present"
      ;;
    Gureum)
      url="https://gureum.io/"
      note="only if replacing Apple Korean input source"
      status="missing"
      if app_exists "$app" || [ -d "/Library/Input Methods/Gureum.app" ] || [ -d "$HOME/Library/Input Methods/Gureum.app" ]; then
        status="present"
      fi
      ;;
    LinearMouse)
      url="https://linearmouse.app/"
      note="reasonable exception for device-specific vertical scroll reversal"
      status="missing"
      app_exists "$app" && status="present"
      ;;
    Amphetamine)
      url="https://apps.apple.com/app/amphetamine/id937984704"
      note="optional App Store alternative; the separate Lazyest Flow project includes basic keep-awake mode"
      status="missing"
      app_exists "$app" && status="present"
      ;;
    *)
      url="<unknown>"
      note=""
      status="missing"
      app_exists "$app" && status="present"
      ;;
  esac
  printf '  %-18s %s\n' "$app:" "$status"
  echo "    url: $url"
  echo "    note: $note"
done
