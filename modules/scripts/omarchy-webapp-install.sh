#!/usr/bin/env bash
# Install a website as a frameless Firefox PWA via firefoxpwa.
# Inspired by Omarchy's "Install > Web App" flow, but Firefox-based.
#
# Two-stage strategy: firefoxpwa's CLI requires a real web app manifest.
#   1. If the page advertises one via <link rel="manifest">, use that.
#   2. Otherwise synthesize a minimal manifest and serve it over a one-shot
#      localhost HTTP server (the CLI doesn't accept data:/file: URLs).
set -euo pipefail

ROFI_THEME="$HOME/.config/rofi/launcher.rasi"

if ! command -v firefoxpwa >/dev/null 2>&1; then
    notify-send "Omarchy Web App" "firefoxpwa not on PATH — run nixswitch?" \
        --app-name="Omarchy" --urgency=critical
    exit 1
fi

LOG=/tmp/omarchy-webapp-install.log
: >"$LOG"
log() { printf '[omarchy] %s\n' "$*" | tee -a "$LOG" >&2; }

# Pango-escape user-typed strings before we substitute them into a -mesg
# template that uses <b>...</b> markup.
pango_esc() {
    printf '%s' "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'
}

# Single-line text input. Shows the launcher theme's chrome but with a guidance
# message above and an empty list below.
prompt() {
    local label="$1" mesg="$2" prefill="${3:-}"
    local extra=()
    [[ -n "$prefill" ]] && extra=(-filter "$prefill")
    echo -n | rofi -dmenu \
        -p "$label" \
        -mesg "$mesg" \
        -markup-rows \
        -theme "$ROFI_THEME" \
        -theme-str '
            mainbox  { children: [ "message", "inputbar" ]; }
            window   { width: 600px; }
            entry    { placeholder: ""; }
            message  { padding: 12px 4px; }
            textbox  { markup: true; }
        ' \
        "${extra[@]}"
}

# Two-option Yes/No picker, also using -mesg as a context line.
confirm() {
    local mesg="$1"
    printf '%s\n%s\n' '✓  Install' '✗  Cancel' | rofi -dmenu \
        -p "Confirm" \
        -mesg "$mesg" \
        -markup-rows \
        -theme "$ROFI_THEME" \
        -theme-str '
            mainbox  { children: [ "message", "inputbar", "listview" ]; }
            window   { width: 600px; }
            listview { lines: 2; fixed-height: false; }
            message  { padding: 12px 4px; }
            textbox  { markup: true; }
        '
}

NAME=$(prompt "Name" "<b>Step 1 of 3</b> — Web app name. Examples: <i>ChatGPT</i>, <i>Linear</i>, <i>HEY</i>") || exit 0
[[ -z "$NAME" ]] && exit 0

URL=$(prompt "URL" "<b>Step 2 of 3</b> — Site URL. Example: <i>https://chat.openai.com/</i>" "https://") || exit 0
[[ -z "$URL" ]] && exit 0
[[ "$URL" =~ ^https?:// ]] || URL="https://$URL"

ICON=$(prompt "Icon" "<b>Step 3 of 3</b> — Icon: URL, local file path, or blank for auto-detect.
<i>Try https://dashboardicons.com for clean brand icons.</i>") || true

# Discover a good icon URL from the page itself. Prefers apple-touch-icon
# (typically 180x180 PNG), then any rel="icon", then /favicon.ico.
# Never returns failure: when scraping is blocked (Cloudflare etc.) we fall
# straight through to /favicon.ico, which most sites have.
discover_icon() {
    local site_url="$1"
    local html best=""
    html=$(curl -fsSL --max-time 8 -A "Mozilla/5.0" "$site_url" 2>/dev/null || true)

    if [[ -n "$html" ]]; then
        # apple-touch-icon first (sharp, square, what mobile installs use)
        best=$(printf '%s' "$html" \
            | grep -oiE '<link[^>]+rel="apple-touch-icon[^"]*"[^>]*>' \
            | head -1 \
            | grep -oiE 'href="[^"]+"' \
            | head -1 \
            | sed -E 's/^href="//I; s/"$//' || true)

        if [[ -z "$best" ]]; then
            best=$(printf '%s' "$html" \
                | grep -oiE '<link[^>]+rel="(shortcut )?icon"[^>]*>' \
                | head -1 \
                | grep -oiE 'href="[^"]+"' \
                | head -1 \
                | sed -E 's/^href="//I; s/"$//' || true)
        fi
    fi

    [[ -z "$best" ]] && best="/favicon.ico"

    # Resolve relative against site_url
    case "$best" in
        http://*|https://*) printf '%s' "$best" ;;
        //*)                printf 'https:%s' "$best" ;;
        /*)
            local origin="${site_url%%://*}://${site_url#*://}"
            origin="${origin%%/*}"
            # rebuild scheme+host
            local sch="${site_url%%://*}"
            local rest="${site_url#*://}"
            local host="${rest%%/*}"
            printf '%s://%s%s' "$sch" "$host" "$best"
            ;;
        *)  printf '%s%s' "${site_url%/*}/" "$best" ;;
    esac
}

ICON_ARGS=()
ICON_LOCAL=""   # if set, we serve this file from the synth http server below
if [[ -n "$ICON" ]]; then
    if [[ "$ICON" =~ ^https?:// ]]; then
        ICON_ARGS=(--icon-url "$ICON")
        log "icon: explicit URL $ICON"
    elif [[ -f "$ICON" ]]; then
        ICON_LOCAL=$(realpath "$ICON")
        log "icon: local file $ICON_LOCAL"
    else
        notify-send "✗ Icon not usable" "$ICON is neither a URL nor an existing file" \
            --app-name="Omarchy" --urgency=critical
        exit 1
    fi
else
    if AUTO_ICON=$(discover_icon "$URL") && [[ -n "$AUTO_ICON" ]]; then
        ICON_ARGS=(--icon-url "$AUTO_ICON")
        log "icon: auto-detected $AUTO_ICON"
    else
        log "icon: none found, firefoxpwa will generate one"
    fi
fi

# Detect an existing install with the same name (case-insensitive). If found,
# let the user replace, install another anyway, or cancel — installing twice
# silently is the most common footgun with this CLI.
DUPLICATE_ID=$(firefoxpwa profile list 2>/dev/null \
    | sed -nE 's/^- (.+): .* \(([0-9A-Z]{26})\)$/\2\t\1/p' \
    | awk -F'\t' -v name="$NAME" 'tolower($2)==tolower(name) {print $1; exit}' \
    || true)

if [[ -n "$DUPLICATE_ID" ]]; then
    DUP_CHOICE=$(printf '%s\n%s\n%s\n' \
            '↻  Replace existing' \
            '+  Install another anyway' \
            '✗  Cancel' \
        | rofi -dmenu \
            -p "Already installed" \
            -mesg "<b>$(pango_esc "$NAME") is already installed.</b>
<i>What would you like to do?</i>" \
            -markup-rows \
            -theme "$ROFI_THEME" \
            -theme-str '
                mainbox  { children: [ "message", "inputbar", "listview" ]; }
                window   { width: 600px; }
                listview { lines: 3; fixed-height: false; }
                message  { padding: 12px 4px; }
                textbox  { markup: true; }
            ')
    case "$DUP_CHOICE" in
        *Replace*)
            log "replacing existing install $DUPLICATE_ID"
            firefoxpwa site uninstall --quiet "$DUPLICATE_ID" >>"$LOG" 2>&1 \
                || { notify-send "✗ Could not remove existing $NAME" --urgency=critical; exit 1; }
            ;;
        *another*)
            log "user chose to install a duplicate of $NAME"
            ;;
        *)
            notify-send "Cancelled" "$NAME was not installed" --app-name="Omarchy"
            exit 0
            ;;
    esac
fi

CHOICE=$(confirm "<b>Install $(pango_esc "$NAME")?</b>
<i>$(pango_esc "$URL")</i>") || exit 0
case "$CHOICE" in
    *Install*) ;;
    *) notify-send "Cancelled" "$NAME was not installed" --app-name="Omarchy"; exit 0 ;;
esac

notify-send "Installing $NAME…" "Looking up the manifest" --app-name="Omarchy"

# --- Stage 1: try to discover a real manifest from the page's HTML ----------
discover_manifest() {
    local site_url="$1"
    local html href origin base
    html=$(curl -fsSL --max-time 8 -A "Mozilla/5.0" "$site_url" 2>/dev/null) || return 1

    # Grab the first <link rel="manifest" href="..."> (rel may appear before or after href).
    href=$(printf '%s' "$html" \
        | grep -oiE '<link[^>]+(rel="manifest"[^>]+href="[^"]+"|href="[^"]+"[^>]+rel="manifest")' \
        | head -1 \
        | grep -oiE 'href="[^"]+"' \
        | head -1 \
        | sed -E 's/^href="//I; s/"$//')
    [[ -z "$href" ]] && return 1

    # Resolve relative URLs against site_url
    if [[ "$href" =~ ^https?:// ]]; then
        printf '%s' "$href"
    elif [[ "$href" =~ ^// ]]; then
        printf 'https:%s' "$href"
    elif [[ "$href" =~ ^/ ]]; then
        origin=$(printf '%s' "$site_url" | grep -oE '^https?://[^/]+')
        printf '%s%s' "$origin" "$href"
    else
        base="${site_url%/*}/"
        printf '%s%s' "$base" "$href"
    fi
}

MANIFEST_URL=""
if MANIFEST_URL=$(discover_manifest "$URL") && [[ -n "$MANIFEST_URL" ]]; then
    log "discovered manifest: $MANIFEST_URL"

    # Verify it actually parses as JSON. Sites sometimes advertise a manifest
    # that 404s, redirects to HTML, or is gated behind auth — in that case
    # fall back to the synthetic manifest path instead of letting firefoxpwa
    # error out with "expected value at line 1 column 1".
    if ! curl -fsSL --max-time 5 -A "Mozilla/5.0" "$MANIFEST_URL" 2>/dev/null \
            | jq empty >/dev/null 2>&1; then
        log "manifest URL did not return valid JSON — falling back to synthetic"
        MANIFEST_URL=""
    fi
fi
[[ -z "$MANIFEST_URL" ]] && log "no usable upstream manifest — will synthesize"

# --- Stage 2: spin up a one-shot localhost HTTP server when we need to serve
# either a synthesized manifest or a local icon file. firefoxpwa's CLI only
# accepts http(s) URLs (no data:/file:), so we host them ourselves.
TMPDIR=""
SERVER_PID=""
SERVER_PORT=""
cleanup() {
    [[ -n "$SERVER_PID" ]] && kill "$SERVER_PID" 2>/dev/null || true
    [[ -n "$TMPDIR" && -d "$TMPDIR" ]] && rm -rf "$TMPDIR"
}
trap cleanup EXIT

ensure_server() {
    [[ -n "$SERVER_PID" ]] && return 0
    TMPDIR=$(mktemp -d)
    SERVER_PORT=$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1]); s.close()')
    python3 -m http.server "$SERVER_PORT" --bind 127.0.0.1 --directory "$TMPDIR" >/dev/null 2>&1 &
    SERVER_PID=$!
    for _ in 1 2 3 4 5 6 7 8 9 10; do
        curl -fsS --max-time 1 "http://127.0.0.1:$SERVER_PORT/" >/dev/null 2>&1 && return 0
        sleep 0.1
    done
    log "ERROR: localhost server failed to start on port $SERVER_PORT"
    notify-send "✗ Local server failed" "Could not start the manifest/icon helper" \
        --app-name="Omarchy" --urgency=critical
    return 1
}

if [[ -z "$MANIFEST_URL" ]]; then
    # Derive scope = "<scheme>://<host>/" via parameter expansion. Avoid grep
    # in command substitution: with set -euo pipefail, a no-match aborts the
    # whole script silently when the user types a URL without a trailing slash.
    SCHEME="${URL%%://*}"
    REST="${URL#*://}"
    HOST="${REST%%/*}"
    SCOPE="${SCHEME}://${HOST}/"
    log "scope: $SCOPE"

    ensure_server
    jq -nc \
        --arg name "$NAME" \
        --arg start "$URL" \
        --arg scope "$SCOPE" \
        '{name: $name, short_name: $name, start_url: $start, scope: $scope, display: "standalone"}' \
        > "$TMPDIR/manifest.json"
    MANIFEST_URL="http://127.0.0.1:$SERVER_PORT/manifest.json"
    log "synthesized manifest served at $MANIFEST_URL"
fi

if [[ -n "$ICON_LOCAL" ]]; then
    ensure_server
    EXT="${ICON_LOCAL##*.}"
    [[ "$EXT" == "$ICON_LOCAL" ]] && EXT="png"   # no extension → assume png
    cp -- "$ICON_LOCAL" "$TMPDIR/icon.$EXT"
    ICON_ARGS=(--icon-url "http://127.0.0.1:$SERVER_PORT/icon.$EXT")
    log "icon: serving local file at ${ICON_ARGS[1]}"
fi

log "running: firefoxpwa site install --document-url $URL --start-url $URL --name $NAME $MANIFEST_URL"

# Capture firefoxpwa's own exit status — `... | tee` would hide it.
set +e
firefoxpwa site install \
    --document-url "$URL" \
    --start-url "$URL" \
    --name "$NAME" \
    "${ICON_ARGS[@]}" \
    "$MANIFEST_URL" >>"$LOG" 2>&1
RC=$?
set -e

if [[ $RC -eq 0 ]]; then
    notify-send "✓ $NAME installed" \
        "Open it from your launcher (Super+Space) or with: firefoxpwa site launch <id>" \
        --app-name="Omarchy"
else
    notify-send "✗ $NAME install failed" "See $LOG (exit $RC)" \
        --app-name="Omarchy" --urgency=critical
    exit "$RC"
fi
