#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

echo "MAC_BOOTSTRAP_PLAN"
echo
echo "Native defaults planned by apply-defaults:"
if [ "$APPLY_SCREENSHOT_LOCATION" = "1" ]; then
  echo "  screenshot folder/location: $(effective_screenshot_dir)"
else
  echo "  screenshot folder/location: skipped by config"
fi
if [ "$APPLY_TEXT_AUTOMATION_DEFAULTS" = "1" ]; then
  echo "  text automation: disable spelling correction, double-space period, inline prediction"
else
  echo "  text automation: skipped by config"
fi
if [ "$APPLY_CLICK_DESKTOP_DEFAULT" = "1" ]; then
  echo "  click wallpaper to show desktop: set to Stage Manager only behavior where supported"
else
  echo "  click wallpaper to show desktop: skipped by config"
fi
if [ "$APPLY_BLACK_WALLPAPER" = "1" ]; then
  echo "  wallpaper: create/apply black wallpaper at $BLACK_WALLPAPER"
else
  echo "  wallpaper: skipped by config"
fi
echo
echo "Dock plan:"
echo "  keep labels:"
printf '    %s\n' "${DOCK_KEEP_LABELS[@]}"
echo "  remove labels:"
printf '    %s\n' "${DOCK_REMOVE_LABELS[@]}"
echo "  apply command: ./bootstrap.sh dock-cleanup"
echo "  safety: creates a timestamped backup before changing the Dock plist"
echo
echo "Agent hotkeys from config/hotkeys.conf:"
print_hotkeys_summary
echo "  screenshot clipboard: uses normal macOS screenshot shortcuts; watches saved files and copies images to clipboard"
echo
echo "Manual checks:"
echo "  Gureum input source add/remove"
echo "  Karabiner right Command -> F18 enablement"
echo "  Keyboard input-source shortcut conflict check"
echo "  LinearMouse vertical mouse scroll reversal while keeping trackpad natural"
echo "  Horizontal scroll behavior"
