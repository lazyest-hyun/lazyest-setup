#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
Usage:
  ./bootstrap.sh help
  ./bootstrap.sh version
  ./bootstrap.sh audit
  ./bootstrap.sh plan
  ./bootstrap.sh install-plan
  ./bootstrap.sh apply-defaults [--dry-run] [--restart-ui]
  ./bootstrap.sh apply-korean-input [--dry-run]
  ./bootstrap.sh apply-gureum-option-key [--dry-run]
  ./bootstrap.sh apply-input-sources [--dry-run]
  ./bootstrap.sh reset-input-sources [--dry-run]
  ./bootstrap.sh apply-input-shortcuts [--dry-run]
  ./bootstrap.sh reset-input-shortcuts [--dry-run]
  ./bootstrap.sh apply-key-repeat [--dry-run]
  ./bootstrap.sh apply-press-and-hold [--dry-run]
  ./bootstrap.sh apply-function-keys [--dry-run]
  ./bootstrap.sh apply-globe-key [--dry-run]
  ./bootstrap.sh apply-karabiner [--dry-run]
  ./bootstrap.sh reset-karabiner [--dry-run]
  ./bootstrap.sh dock-apply [--dry-run] [--no-restart-ui]
  ./bootstrap.sh dock-cleanup [--dry-run] [--no-restart-ui]
  ./bootstrap.sh agent-plan
  ./bootstrap.sh build-agent [--dry-run]
  ./bootstrap.sh install-agent [--dry-run]
  ./bootstrap.sh uninstall-agent [--dry-run]
  ./bootstrap.sh install-setup [--dry-run]
  ./bootstrap.sh uninstall-setup [--dry-run]

Commands:
  help              Show this help.
  version           Print the source version used by both app bundles.
  audit             Read-only state summary.
  plan              Read-only native defaults and Dock plan.
  install-plan      Read-only optional app install plan and official links.
  apply-defaults    Apply native macOS defaults only.
  apply-korean-input Apply Gureum input source and F18 input-source shortcut.
  apply-gureum-option-key Enable Gureum Option-key special characters.
  apply-input-sources Apply only Gureum Dubeolsik and remove Apple Korean 2-set.
  reset-input-sources Restore Apple Korean 2-set and remove Gureum Dubeolsik.
  apply-input-shortcuts Disable previous input-source shortcut and set next to F18.
  reset-input-shortcuts Restore macOS input-source shortcut defaults.
  apply-key-repeat Set key repeat speed and delay to fastest values.
  apply-press-and-hold Disable press-and-hold accent picker.
  apply-function-keys Use F1, F2, etc. as standard function keys.
  apply-globe-key    Set Globe/Fn key action to do nothing.
  apply-karabiner   Apply right Command to F18 Karabiner rule.
  reset-karabiner   Remove right Command to F18 Karabiner rule.
  dock-cleanup      Remove configured default Dock icons, with plist backup.
  dock-apply        Apply an explicit default-app Dock checklist, with plist backup.
  agent-plan        Read-only MacBootstrapAgent capability and config summary.
  build-agent       Build the Swift agent, or preview with --dry-run.
  install-agent     Install only the always-running MacBootstrapAgent.app.
  uninstall-agent   Remove only MacBootstrapAgent.app.
  install-setup     Install only the one-time MacBootstrapSetup.app.
  uninstall-setup   Remove only MacBootstrapSetup.app.
EOF
}

cmd="${1:-}"
shift || true

case "$cmd" in
  version)
    tr -d '[:space:]' <"$ROOT_DIR/VERSION"
    printf '\n'
    ;;
  audit)
    exec "$ROOT_DIR/scripts/audit.sh" "$@"
    ;;
  plan)
    exec "$ROOT_DIR/scripts/plan.sh" "$@"
    ;;
  install-plan)
    exec "$ROOT_DIR/scripts/install-plan.sh" "$@"
    ;;
  apply-defaults)
    exec "$ROOT_DIR/scripts/apply-defaults.sh" "$@"
    ;;
  apply-korean-input)
    exec "$ROOT_DIR/scripts/apply-korean-input.sh" "$@"
    ;;
  apply-gureum-option-key)
    exec "$ROOT_DIR/scripts/apply-gureum-option-key.sh" "$@"
    ;;
  apply-input-sources)
    exec "$ROOT_DIR/scripts/apply-input-sources.sh" "$@"
    ;;
  reset-input-sources)
    exec "$ROOT_DIR/scripts/reset-input-sources.sh" "$@"
    ;;
  apply-input-shortcuts)
    exec "$ROOT_DIR/scripts/apply-input-shortcuts.sh" "$@"
    ;;
  reset-input-shortcuts)
    exec "$ROOT_DIR/scripts/reset-input-shortcuts.sh" "$@"
    ;;
  apply-key-repeat)
    exec "$ROOT_DIR/scripts/apply-key-repeat.sh" "$@"
    ;;
  apply-press-and-hold)
    exec "$ROOT_DIR/scripts/apply-press-and-hold.sh" "$@"
    ;;
  apply-function-keys)
    exec "$ROOT_DIR/scripts/apply-function-keys.sh" "$@"
    ;;
  apply-globe-key)
    exec "$ROOT_DIR/scripts/apply-globe-key.sh" "$@"
    ;;
  apply-karabiner)
    exec "$ROOT_DIR/scripts/apply-karabiner.sh" "$@"
    ;;
  reset-karabiner)
    exec "$ROOT_DIR/scripts/reset-karabiner.sh" "$@"
    ;;
  dock-cleanup)
    exec "$ROOT_DIR/scripts/dock-cleanup.sh" "$@"
    ;;
  dock-apply)
    exec "$ROOT_DIR/scripts/dock-apply.sh" "$@"
    ;;
  agent-plan)
    exec "$ROOT_DIR/scripts/agent-plan.sh" "$@"
    ;;
  build-agent)
    exec "$ROOT_DIR/scripts/build-agent.sh" "$@"
    ;;
  install-agent)
    exec "$ROOT_DIR/scripts/install-agent.sh" "$@"
    ;;
  uninstall-agent)
    exec "$ROOT_DIR/scripts/uninstall-agent.sh" "$@"
    ;;
  install-setup)
    exec "$ROOT_DIR/scripts/install-setup.sh" "$@"
    ;;
  uninstall-setup)
    exec "$ROOT_DIR/scripts/uninstall-setup.sh" "$@"
    ;;
  ""|-h|--help|help)
    usage
    ;;
  *)
    echo "Unknown command: $cmd" >&2
    usage >&2
    exit 2
    ;;
esac
