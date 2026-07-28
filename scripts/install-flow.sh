#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

parse_common_flags "$@"

release_page_url="$(flow_release_page_url)"
echo "OPEN_FLOW_RELEASE"
echo "  repository: $FLOW_REPOSITORY"
echo "  release page: $release_page_url"

if ((DRY_RUN)); then
  echo "[dry-run] open $release_page_url"
  exit 0
fi

if ! command -v open >/dev/null 2>&1; then
  echo "  blocked: macOS open command not found; visit $release_page_url" >&2
  exit 1
fi

open "$release_page_url"
echo "OPEN_FLOW_RELEASE_OK"
