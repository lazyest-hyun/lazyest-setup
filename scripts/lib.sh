#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=/dev/null
source "$ROOT_DIR/config/bootstrap.conf"

# Existing backups remain available for reset; all new installations use the brand path.
LAZYEST_SETUP_BACKUP_DIR="$HOME/Library/Application Support/Lazyest Setup/Backups"
if [ ! -d "$LAZYEST_SETUP_BACKUP_DIR" ] && [ -d "$HOME/.local/share/mac-bootstrap/backups" ]; then
  LAZYEST_SETUP_BACKUP_DIR="$HOME/.local/share/mac-bootstrap/backups"
fi
export LAZYEST_SETUP_BACKUP_DIR

DRY_RUN=0
RESTART_UI=0

parse_common_flags() {
  while (($#)); do
    case "$1" in
      --dry-run)
        DRY_RUN=1
        ;;
      --restart-ui)
        RESTART_UI=1
        ;;
      *)
        echo "Unknown option: $1" >&2
        exit 2
        ;;
    esac
    shift
  done
}

run_cmd() {
  if ((DRY_RUN)); then
    printf '[dry-run] '
    printf '%q ' "$@"
    printf '\n'
  else
    "$@"
  fi
}

read_default() {
  local domain="$1"
  local key="$2"
  defaults read "$domain" "$key" 2>/dev/null || printf '<unset>\n'
}

bool_label() {
  if [ "${1:-}" = "1" ] || [ "${1:-}" = "true" ] || [ "${1:-}" = "True" ]; then
    echo "yes"
  else
    echo "no"
  fi
}

app_version() {
  local version_file="$ROOT_DIR/VERSION"
  local version
  if [ ! -f "$version_file" ]; then
    echo "Missing version file: $version_file" >&2
    return 1
  fi
  version="$(tr -d '[:space:]' <"$version_file")"
  if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Invalid semantic version in $version_file: $version" >&2
    return 1
  fi
  printf '%s\n' "$version"
}

app_exists() {
  local name="$1"
  [ -d "/Applications/$name.app" ] || [ -d "$HOME/Applications/$name.app" ]
}

setup_package_dir() {
  echo "$ROOT_DIR/setup/LazyestSetup"
}

setup_binary_path() {
  echo "$(setup_package_dir)/.build/release/LazyestSetup"
}

flow_app_path() {
  echo "/Applications/Lazyest Flow.app"
}

setup_app_path() {
  echo "${LAZYEST_SETUP_APP_PATH:-/Applications/Lazyest Setup.app}"
}

launch_agent_plist() {
  echo "$HOME/Library/LaunchAgents/com.estaid.mac-bootstrap-agent.plist"
}

flow_release_page_url() {
  printf '%s\n' "$FLOW_RELEASE_PAGE_URL"
}

require_python() {
  if ! /usr/bin/xcrun --find python3 >/dev/null 2>&1; then
    echo "  blocked: Command Line Tools required; run xcode-select --install, then retry" >&2
    exit 1
  fi
}
