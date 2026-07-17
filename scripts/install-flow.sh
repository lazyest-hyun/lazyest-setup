#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

parse_common_flags "$@"

echo "INSTALL_EXTERNAL_FLOW"
echo "  dry-run: $(bool_label "$DRY_RUN")"
echo "  repository: $FLOW_REPOSITORY"
echo "  ref: $FLOW_REF"

if [ -n "${LAZYEST_FLOW_SOURCE_DIR:-}" ]; then
  source_dir="$LAZYEST_FLOW_SOURCE_DIR"
  if [ ! -x "$source_dir/bootstrap.sh" ]; then
    echo "  blocked: Flow bootstrap not found at $source_dir/bootstrap.sh" >&2
    exit 1
  fi
  echo "  source override: $source_dir"
  if ((DRY_RUN)); then
    "$source_dir/bootstrap.sh" install --dry-run
  else
    "$source_dir/bootstrap.sh" install
  fi
  exit 0
fi

archive_url="$(flow_archive_url)"
if ((DRY_RUN)); then
  echo "[dry-run] download $archive_url"
  echo "[dry-run] extract the separate lazyest-flow project"
  echo "[dry-run] run its ./bootstrap.sh install"
  exit 0
fi

if ! command -v swift >/dev/null 2>&1; then
  echo "  blocked: Swift toolchain not found" >&2
  exit 1
fi

temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/lazyest-flow.XXXXXX")"
cleanup() {
  rm -rf "$temp_dir"
}
trap cleanup EXIT

archive="$temp_dir/agent.tar.gz"
/usr/bin/curl --fail --location --silent --show-error --retry 2 "$archive_url" --output "$archive"
/usr/bin/tar -xzf "$archive" -C "$temp_dir"
source_dir="$(find "$temp_dir" -mindepth 1 -maxdepth 1 -type d -name 'lazyest-flow-*' -print -quit)"
if [ -z "$source_dir" ] || [ ! -x "$source_dir/bootstrap.sh" ]; then
  echo "  blocked: downloaded Flow source is invalid" >&2
  exit 1
fi

"$source_dir/bootstrap.sh" install
echo "INSTALL_FLOW_OK"
