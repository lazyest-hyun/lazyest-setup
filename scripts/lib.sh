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
  echo "$ROOT_DIR/setup/MacBootstrapSetup"
}

setup_binary_path() {
  echo "$(setup_package_dir)/.build/release/MacBootstrapSetup"
}

agent_app_path() {
  echo "/Applications/MacBootstrapAgent.app"
}

setup_app_path() {
  echo "/Applications/MacBootstrapSetup.app"
}

launch_agent_plist() {
  echo "$HOME/Library/LaunchAgents/com.estaid.mac-bootstrap-agent.plist"
}

agent_archive_url() {
  printf '%s/archive/%s.tar.gz\n' "$AGENT_REPOSITORY" "$AGENT_REF"
}
