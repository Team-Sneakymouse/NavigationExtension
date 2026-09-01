#!/usr/bin/env bash
# Link this repo into Typewriter as a git submodule (one-time setup).
#
# 1. Create an empty GitHub repo (e.g. NavigationExtension) — no README/license.
# 2. Push this extension repo:
#      git remote add origin https://github.com/<you>/NavigationExtension.git
#      git push -u origin main
# 3. Register the submodule in Typewriter (from this script):
#      ./scripts/setup-navigation-submodule.sh https://github.com/<you>/NavigationExtension.git
#
# After setup, commit extension work in this repo only.
# Pull Typewriter updates from upstream develop in the parent repo.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TYPEWRITER_ROOT="$(cd "$EXT_DIR/../.." && pwd)"
REMOTE_URL="${1:-}"

if [[ -z "$REMOTE_URL" ]]; then
    echo "Usage: $0 <git-remote-url>" >&2
    echo "Example: $0 https://github.com/you/NavigationExtension.git" >&2
    exit 1
fi

if [[ ! -f "$TYPEWRITER_ROOT/settings.toml" ]] || [[ ! -d "$TYPEWRITER_ROOT/engine" ]]; then
    echo "error: Typewriter root not found at $TYPEWRITER_ROOT" >&2
    exit 1
fi

if [[ ! -d "$EXT_DIR/.git" ]]; then
    echo "error: $EXT_DIR is not a git repository" >&2
    exit 1
fi

cd "$TYPEWRITER_ROOT"

if git config --file .gitmodules --get-regexp path 2>/dev/null | grep -q 'extensions/NavigationExtension'; then
    echo "Submodule already registered in .gitmodules"
    exit 0
fi

if [[ -d "$EXT_DIR" ]] && [[ ! -f "$EXT_DIR/.git" ]] && [[ ! -d "$EXT_DIR/.git" ]]; then
    echo "error: $EXT_DIR exists but is not a git repo" >&2
    exit 1
fi

TEMP_BACKUP="$(mktemp -d)"
if [[ -d "$EXT_DIR" ]]; then
    echo "==> Temporarily moving existing NavigationExtension"
    mv "$EXT_DIR" "$TEMP_BACKUP/NavigationExtension"
fi

echo "==> Adding submodule $REMOTE_URL"
git submodule add "$REMOTE_URL" extensions/NavigationExtension

if [[ -d "$TEMP_BACKUP/NavigationExtension" ]]; then
    echo "==> Restoring local files into submodule checkout"
    rsync -a --exclude .git "$TEMP_BACKUP/NavigationExtension/" "$EXT_DIR/"
    rm -rf "$TEMP_BACKUP"
fi

echo "==> Done. Next steps:"
echo "  cd extensions/NavigationExtension && git status"
echo "  git add -A && git commit -m '...' && git push"
echo "  cd $TYPEWRITER_ROOT && git add .gitmodules extensions/NavigationExtension && git commit -m 'Add NavigationExtension submodule'"
