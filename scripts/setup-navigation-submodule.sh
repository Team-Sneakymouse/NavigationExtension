#!/usr/bin/env bash
# Link this repo into Typewriter as a git submodule (one-time setup).
#
# Prerequisites:
#   1. Create an empty GitHub repo (e.g. NavigationExtension).
#   2. Push this extension repo:
#        git remote add origin git@github.com:<org>/NavigationExtension.git
#        git push -u origin main
#   3. Run this script:
#        ./scripts/setup-navigation-submodule.sh git@github.com:<org>/NavigationExtension.git
#
# After setup, commit extension work in this repo only.

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

if [[ -z "$REMOTE_URL" ]]; then
    die "usage: $0 <git-remote-url>"
fi

if [[ ! -f "$TYPEWRITER_ROOT/settings.toml" ]] || [[ ! -d "$TYPEWRITER_ROOT/engine" ]]; then
    die "Typewriter root not found at $TYPEWRITER_ROOT"
fi

if [[ ! -d "$EXT_DIR/.git" ]]; then
    die "$EXT_DIR is not a git repository"
fi

cd "$TYPEWRITER_ROOT"

if git config --file .gitmodules --get-regexp path 2>/dev/null | grep -q 'extensions/NavigationExtension'; then
    log "Submodule already registered in .gitmodules"
    exit 0
fi

log "Checking remote $REMOTE_URL"
if ! git ls-remote --exit-code "$REMOTE_URL" HEAD >/dev/null 2>&1; then
    die "cannot reach remote or repository not found — create the GitHub repo and push main first"
fi

TEMP_BACKUP="$(mktemp -d)"
trap 'rm -rf "$TEMP_BACKUP"' EXIT

if [[ -d "$EXT_DIR" ]]; then
    log "Backing up $EXT_DIR"
    mkdir -p "$TEMP_BACKUP/NavigationExtension"
    rsync -a --exclude .git "$EXT_DIR/" "$TEMP_BACKUP/NavigationExtension/"
    rm -rf "$EXT_DIR"
fi

log "Adding submodule $REMOTE_URL"
git submodule add "$REMOTE_URL" extensions/NavigationExtension

if [[ -d "$TEMP_BACKUP/NavigationExtension" ]]; then
    log "Copying local files into submodule checkout"
    rsync -a "$TEMP_BACKUP/NavigationExtension/" "$EXT_DIR/"
fi

log "Done. Next steps:"
echo "  cd extensions/NavigationExtension && git status"
echo "  git add -A && git commit -m '...' && git push"
echo "  cd $TYPEWRITER_ROOT && git add .gitmodules extensions/NavigationExtension && git commit -m 'Add NavigationExtension submodule'"
