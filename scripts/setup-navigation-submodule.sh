#!/usr/bin/env bash
# Link this repo into Typewriter as a git submodule (one-time setup).
#
# Prerequisites:
#   1. Create an empty GitHub repo and push this extension:
#        git remote add origin git@github.com:<org>/NavigationExtension.git
#        git push -u origin main
#   2. Run from Typewriter repo root (or this script auto-detects paths):
#        extensions/NavigationExtension/scripts/setup-navigation-submodule.sh \
#          git@github.com:<org>/NavigationExtension.git
#
# If local and remote histories diverged (e.g. GitHub added a README), force-push
# local main before running this script.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TYPEWRITER_ROOT="$(cd "$EXT_DIR/../.." && pwd)"
REMOTE_URL="${1:-}"

log() {
    printf '==> %s\n' "$*"
}

die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

remove_extension_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        return 0
    fi
    # rm -rf can fail on some mounted filesystems; find -delete is more reliable.
    find "$dir" -mindepth 1 -delete 2>/dev/null || true
    rmdir "$dir" 2>/dev/null || rm -rf "$dir"
}

if [[ -z "$REMOTE_URL" ]]; then
    die "usage: $0 <git-remote-url>"
fi

if [[ ! -f "$TYPEWRITER_ROOT/settings.toml" ]] || [[ ! -d "$TYPEWRITER_ROOT/engine" ]]; then
    die "Typewriter root not found at $TYPEWRITER_ROOT"
fi

cd "$TYPEWRITER_ROOT"

if git config --file .gitmodules --get-regexp path 2>/dev/null | grep -q 'extensions/NavigationExtension'; then
    log "Submodule already registered in .gitmodules"
    exit 0
fi

log "Checking remote $REMOTE_URL"
if ! git ls-remote --exit-code "$REMOTE_URL" HEAD >/dev/null 2>&1; then
    die "cannot reach remote — create the repo and push main first (use SSH URL if HTTPS gives 403)"
fi

if [[ -d "$EXT_DIR" ]]; then
    log "Removing existing $EXT_DIR (will re-clone via submodule)"
    remove_extension_dir "$EXT_DIR"
fi

log "Adding submodule $REMOTE_URL"
git submodule add "$REMOTE_URL" extensions/NavigationExtension

log "Done. Commit in Typewriter parent:"
echo "  cd $TYPEWRITER_ROOT"
echo "  git add .gitmodules extensions/NavigationExtension"
echo "  git commit -m 'Add NavigationExtension submodule'"
