#!/usr/bin/env bash
# Build Typewriter + extensions into ./server and run a local Paper test server.
#
# Run from anywhere:
#   extensions/NavigationExtension/scripts/dev-server.sh
#
# Usage:
#   ./scripts/dev-server.sh          # build plugins, then start server
#   ./scripts/dev-server.sh build    # build/copy plugins only
#   ./scripts/dev-server.sh run      # start server (skip build)
#
# Environment:
#   DEV_EXTENSIONS   comma-separated extension module names (default: Basic,RoadNetwork,Navigation)
#   PAPER_VERSION    Paper Fill version key (default: 26.2)
#   DEV_PANEL_SOURCE   local = build panel from app/ (needs Flutter); modrinth = donor JAR (default)
#   DEV_SKIP_PANEL     set to 1 to skip bundling web panel assets (/connect won't work)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TYPEWRITER_ROOT="$(cd "$EXT_DIR/../.." && pwd)"
SERVER_DIR="$TYPEWRITER_ROOT/server"
PLUGINS_DIR="$SERVER_DIR/plugins"
EXTENSIONS_DIR="$PLUGINS_DIR/Typewriter/extensions"
USER_AGENT="TypeWriter-dev-server/1.0 (local)"
DEFAULT_EXTENSIONS="BasicExtension,RoadNetworkExtension,NavigationExtension"
DEFAULT_PAPER_VERSION="26.2"

log() {
    printf '==> %s\n' "$*"
}

die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

require_typewriter_root() {
    if [[ ! -f "$TYPEWRITER_ROOT/settings.toml" ]] || [[ ! -d "$TYPEWRITER_ROOT/engine" ]]; then
        die "Typewriter root not found at $TYPEWRITER_ROOT (is NavigationExtension at extensions/NavigationExtension?)"
    fi
}

read_settings() {
    python3 - "$TYPEWRITER_ROOT/settings.toml" <<'PY'
import sys
import tomllib
from pathlib import Path

settings = tomllib.loads(Path(sys.argv[1]).read_text())
print(settings["java"])
PY
}

read_paper_version() {
    if [[ -n "${PAPER_VERSION:-}" ]]; then
        echo "$PAPER_VERSION"
        return
    fi

    echo "$DEFAULT_PAPER_VERSION"
}

download_file() {
    local url="$1"
    local dest="$2"
    if [[ -f "$dest" ]]; then
        return 0
    fi
    log "Downloading $(basename "$dest")"
    curl -fsSL -H "User-Agent: $USER_AGENT" -o "$dest" "$url"
}

fetch_paper_url() {
    local version="$1"
    curl -fsSL -H "User-Agent: $USER_AGENT" \
        "https://fill.papermc.io/v3/projects/paper/versions/${version}/builds/latest" \
        | python3 -c "import sys, json; print(json.load(sys.stdin)['downloads']['server:default']['url'])"
}

fetch_packetevents_url() {
    curl -fsSL -G "https://api.modrinth.com/v2/project/packetevents/version" \
        --data-urlencode 'loaders=["paper"]' \
        --data-urlencode "game_versions=[\"${PAPER_VERSION}\"]" \
        | python3 -c "import sys, json; versions=json.load(sys.stdin); print(versions[0]['files'][0]['url'])"
}

ensure_server_files() {
    local paper_version="$1"
    mkdir -p "$PLUGINS_DIR" "$EXTENSIONS_DIR"

    if [[ ! -f "$SERVER_DIR/eula.txt" ]]; then
        log "Accepting Minecraft EULA"
        echo "eula=true" >"$SERVER_DIR/eula.txt"
    fi

    if [[ ! -f "$SERVER_DIR/server.properties" ]]; then
        log "Creating server.properties"
        cat >"$SERVER_DIR/server.properties" <<'EOF'
motd=Typewriter Dev Server
online-mode=false
gamemode=creative
difficulty=easy
spawn-protection=0
view-distance=10
max-players=20
EOF
    fi

    local paper_url
    paper_url="$(fetch_paper_url "$paper_version")"
    local paper_marker="$SERVER_DIR/.paper-version"
    if [[ ! -f "$paper_marker" ]] || [[ "$(cat "$paper_marker")" != "$paper_url" ]]; then
        log "Fetching Paper $paper_version"
        curl -fsSL -H "User-Agent: $USER_AGENT" -o "$SERVER_DIR/paper.jar" "$paper_url"
        echo "$paper_url" >"$paper_marker"
    fi

    local packetevents_url
    packetevents_url="$(fetch_packetevents_url)"
    download_file "$packetevents_url" "$PLUGINS_DIR/packetevents.jar"
    ensure_typewriter_config
}

ensure_typewriter_config() {
    local config="$PLUGINS_DIR/Typewriter/config.yml"
    mkdir -p "$(dirname "$config")"

    if [[ ! -f "$config" ]]; then
        log "Creating Typewriter config with panel enabled"
        cat >"$config" <<'EOF'
enabled: true
hostname: 127.0.0.1
panel:
  enabled: true
  port: 8080
websocket:
  port: 9092
  auth: session
EOF
        return
    fi

    python3 - "$config" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text()
text = re.sub(r"^enabled:\s*false\s*$", "enabled: true", text, count=1, flags=re.MULTILINE)
text = re.sub(
    r"(panel:\s*\n(?:\s+.+\n)*?\s+)enabled:\s*false",
    r"\1enabled: true",
    text,
    count=1,
)
path.write_text(text)
PY
}

read_typewriter_version() {
    python3 - "$TYPEWRITER_ROOT/settings.toml" <<'PY'
import sys
import tomllib
from pathlib import Path

settings = tomllib.loads(Path(sys.argv[1]).read_text())
print(settings["version"].split("-")[0])
PY
}

merge_panel_web_assets() {
    if [[ "${DEV_PANEL_SOURCE:-modrinth}" == "local" ]]; then
        merge_panel_web_local
        return
    fi
    merge_panel_web_modrinth
}

merge_panel_web_modrinth() {
    local dest="$PLUGINS_DIR/Typewriter.jar"
    local cache_dir="$SERVER_DIR/.cache"
    local donor_jar="$cache_dir/typewriter-web-donor.jar"
    local donor_key_file="$cache_dir/typewriter-web-donor.key"
    # Web UI only — engine version comes from the locally built Typewriter.jar.
    local donor_url="https://cdn.modrinth.com/data/Vm7B3ymm/versions/NWX8MGts/Typewriter-0.9.0-beta-175.jar"
    local donor_key="web-donor:0.9.0-beta-175"

    mkdir -p "$cache_dir"

    if [[ ! -f "$donor_key_file" ]] || [[ "$(cat "$donor_key_file")" != "$donor_key" ]] || [[ ! -f "$donor_jar" ]]; then
        log "Downloading web panel assets (engine stays local $(read_typewriter_version))"
        curl -fsSL -H "User-Agent: $USER_AGENT" -o "$donor_jar" "$donor_url"
        echo "$donor_key" >"$donor_key_file"
    fi

    local tmp
    tmp="$(mktemp -d)"
    (cd "$tmp" && jar xf "$donor_jar" web)
    (cd "$tmp" && jar uf "$dest" web)
    rm -rf "$tmp"
    log "Bundled web panel into Typewriter.jar"
}

merge_panel_web_local() {
    local dest="$PLUGINS_DIR/Typewriter.jar"
    local app_dir="$TYPEWRITER_ROOT/app"
    local web_dir="$app_dir/build/web"
    local flutter_bin="${FLUTTER_ROOT:-$HOME/development/flutter}/bin/flutter"

    if [[ ! -x "$flutter_bin" ]]; then
        die "DEV_PANEL_SOURCE=local but Flutter not found at $flutter_bin (set FLUTTER_ROOT)"
    fi

    log "Building local panel web from app/ (fixes panel bugs vs Modrinth donor)"
    (cd "$app_dir" && "$flutter_bin" pub get && "$flutter_bin" build web --no-tree-shake-icons)

    [[ -d "$web_dir" ]] || die "Flutter web build missing at $web_dir"

    local tmp
    tmp="$(mktemp -d)"
    cp -a "$web_dir" "$tmp/web"
    (cd "$tmp" && jar uf "$dest" web)
    rm -rf "$tmp"
    log "Bundled local web panel into Typewriter.jar"
}

build_typewriter_engine() {
    local version
    version="$(read_typewriter_version)"
    local marker="$SERVER_DIR/.typewriter-plugin-source"
    local source_key="local:${version}"

    log "Building local Typewriter engine $version"
    (cd "$TYPEWRITER_ROOT/engine" && ./gradlew :engine-paper:buildAndMove --console=plain -q)
    echo "$source_key" >"$marker"

    if [[ "${DEV_SKIP_PANEL:-}" == "1" ]]; then
        log "Skipping web panel (set DEV_SKIP_PANEL=0 or unset to enable /connect)"
        return
    fi

    merge_panel_web_assets
}

build_plugins() {
    local extensions="${DEV_EXTENSIONS:-$DEFAULT_EXTENSIONS}"

    build_typewriter_engine

    log "Building extensions: $extensions"
    IFS=',' read -ra extension_modules <<<"$extensions"
    for extension in "${extension_modules[@]}"; do
        extension="${extension//[[:space:]]/}"
        [[ -n "$extension" ]] || continue
        (cd "$TYPEWRITER_ROOT/extensions" && ./gradlew ":${extension}:buildAndMove" --console=plain -q)
    done

    log "Plugins ready in $PLUGINS_DIR"
}

run_server() {
    local java_version
    java_version="$(read_settings)"

    if [[ -n "${JAVA_HOME:-}" ]]; then
        export PATH="$JAVA_HOME/bin:$PATH"
    fi

    command -v java >/dev/null || die "java not found (need Java $java_version)"

    log "Starting Paper (connect on localhost:25565)"
    cd "$SERVER_DIR"
    exec java -Xms1G -Xmx2G -jar paper.jar nogui
}

main() {
    require_typewriter_root

    local mode="${1:-start}"
    PAPER_VERSION="$(read_paper_version)"

    case "$mode" in
        build)
            build_plugins
            ;;
        run)
            ensure_server_files "$PAPER_VERSION"
            run_server
            ;;
        start|"")
            ensure_server_files "$PAPER_VERSION"
            build_plugins
            run_server
            ;;
        *)
            die "unknown command: $mode (use: build, run, or start)"
            ;;
    esac
}

main "${1:-start}"
