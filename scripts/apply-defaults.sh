#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

parse_common_flags "$@"

echo "APPLY_DEFAULTS"
echo "  dry-run: $(bool_label "$DRY_RUN")"
echo "  restart-ui: $(bool_label "$RESTART_UI")"

effective_screenshot_dir="${MAC_BOOTSTRAP_SCREENSHOT_DIR:-$SCREENSHOT_DIR}"
if [ "$effective_screenshot_dir" = "auto" ]; then
  current_location="$(defaults read com.apple.screencapture location 2>/dev/null || true)"
  if [ -n "$current_location" ]; then
    effective_screenshot_dir="$current_location"
  else
    effective_screenshot_dir="$HOME/Desktop/screenshots"
  fi
fi

if [ "$APPLY_SCREENSHOT_LOCATION" = "1" ]; then
  run_cmd mkdir -p "$effective_screenshot_dir"
  run_cmd defaults write com.apple.screencapture location -string "$effective_screenshot_dir"
  run_cmd killall SystemUIServer
  run_cmd killall screencaptureui 2>/dev/null || true
else
  echo "  screenshot location skipped by config"
fi

if [ "$APPLY_TEXT_AUTOMATION_DEFAULTS" = "1" ]; then
  run_cmd defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false
  run_cmd defaults write -g NSAutomaticPeriodSubstitutionEnabled -bool false
  run_cmd defaults write -g NSAutomaticInlinePredictionEnabled -bool false
else
  echo "  text automation defaults skipped by config"
fi

if [ "$APPLY_CLICK_DESKTOP_DEFAULT" = "1" ]; then
  run_cmd defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false
else
  echo "  click-desktop default skipped by config"
fi

if [ "$APPLY_BLACK_WALLPAPER" = "1" ]; then
  if [ -f "$BLACK_WALLPAPER" ]; then
    run_cmd osascript -e "tell application \"System Events\" to tell every desktop to set picture to POSIX file \"$BLACK_WALLPAPER\""
  else
    echo "  black wallpaper skipped; system Black.png not found at $BLACK_WALLPAPER"
  fi
else
  echo "  black wallpaper skipped by config"
fi

if ((RESTART_UI)); then
  run_cmd killall SystemUIServer
else
  echo "  skipped extra UI restart; screenshot service refresh runs when screenshot location changes"
fi
