#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

parse_common_flags "$@"

echo "Applying minimal native macOS settings"
echo "  dry-run: $(bool_label "$DRY_RUN")"
echo "  restart-ui: $(bool_label "$RESTART_UI")"

run_cmd mkdir -p "$SCREENSHOT_DIR"
run_cmd defaults write com.apple.screencapture location -string "$SCREENSHOT_DIR"

# Text automation preferences. Values are deliberately scoped to global domain
# keys that are commonly stable across recent macOS versions.
run_cmd defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false
run_cmd defaults write -g NSAutomaticPeriodSubstitutionEnabled -bool false
run_cmd defaults write -g NSAutomaticInlinePredictionEnabled -bool false

# "Click wallpaper to reveal desktop": false corresponds to "Only in Stage Manager"
# behavior on recent macOS versions.
run_cmd defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false

if [ -f "$BLACK_WALLPAPER" ]; then
  run_cmd osascript -e "tell application \"System Events\" to tell every desktop to set picture to POSIX file \"$BLACK_WALLPAPER\""
else
  echo "System black wallpaper was not found at $BLACK_WALLPAPER; skipping wallpaper assignment."
fi

if ((RESTART_UI)); then
  run_cmd killall SystemUIServer
else
  echo "Skipped UI restart. Re-run with --restart-ui or log out/in to fully apply some settings."
fi
