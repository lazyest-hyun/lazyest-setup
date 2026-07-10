#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

echo "AGENT_PLAN"
echo "  package: $(agent_package_dir)"
echo "  binary: $(agent_binary_path)"
echo "  app bundle: $(agent_app_path)"
echo "  setup app bundle: $(setup_app_path)"
echo "  legacy launch agent plist: $(launch_agent_plist)"
echo "  status: buildable menu bar app; Dock anchoring live-tested on a multi-display setup"
echo
echo "Capabilities implemented:"
echo "  app toggle by bundle id"
echo "  user-managed app bindings with no default hotkeys"
echo "  screenshot file watcher for normal macOS screenshot shortcuts"
echo "  saved screenshot image copy to clipboard"
echo "  sleep-prevention mode through macOS power assertions"
echo "  Dock anchoring through the menu bar agent"
echo "  status-bar process plus settings window"
echo "  fresh-install runtime defaults: all off until enabled in the Agent UI"
echo
echo "One-time setup app:"
echo "  preview/apply native defaults"
echo "  review optional install plan"
echo "  review manual checks"
echo "  removable after setup; managed separately by install-setup/uninstall-setup"
echo
echo "Hotkeys:"
print_hotkeys_summary
echo
echo "Permission/manual checks:"
echo "  Accessibility permission may be required for app activation/hiding."
echo "  Accessibility permission is required for Dock anchoring."
echo "  Screen Recording permission is not required; screenshot copy reads the saved image file."
echo "  Add and test user hotkeys from Settings or config/hotkeys.conf."
