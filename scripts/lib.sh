#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=/dev/null
source "$ROOT_DIR/config/bootstrap.conf"

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

effective_screenshot_dir() {
  local value="${1:-$SCREENSHOT_DIR}"
  if [ "$value" = "auto" ]; then
    local current_location
    current_location="$(defaults read com.apple.screencapture location 2>/dev/null || true)"
    if [ -n "$current_location" ]; then
      printf '%s\n' "$current_location"
    else
      printf '%s\n' "$HOME/Desktop"
    fi
  else
    printf '%s\n' "$value"
  fi
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

agent_package_dir() {
  echo "$ROOT_DIR/agent/MacBootstrapAgent"
}

agent_binary_path() {
  echo "$(agent_package_dir)/.build/release/MacBootstrapAgent"
}

agent_app_path() {
  echo "/Applications/MacBootstrapAgent.app"
}

setup_app_path() {
  echo "/Applications/MacBootstrapSetup.app"
}

launch_agent_plist() {
  echo "$HOME/Library/LaunchAgents/$AGENT_LABEL.plist"
}

print_hotkeys_summary() {
  local file="$ROOT_DIR/config/hotkeys.conf"
  if [ ! -f "$file" ]; then
    echo "  missing: $file"
    return
  fi

  awk -F'|' '
    /^[[:space:]]*#/ || /^[[:space:]]*$/ { next }
    NF >= 4 && $1 == "toggle-app" {
      printf "  app toggle: %s -> %s (%s)\n", $2, $3, $4
    }
  ' "$file"
}
