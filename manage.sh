#!/opt/homebrew/bin/bash
set -e

INSTALL_DIR="$HOME/.wifi-loc-control"
HOOKS_DIR="$INSTALL_DIR/hooks"

# ── gum ───────────────────────────────────────────────────────────────────────
if ! command -v gum &>/dev/null; then
    echo "Installing gum..."
    brew install gum
fi
GUM=$(which gum)

ok()   { $GUM style --foreground 2   "✓ $*"; }
err()  { $GUM style --foreground 1   "✗ $*"; }

_GUM_TMP=$(mktemp)
trap 'rm -f "$_GUM_TMP"' EXIT

drain_tty() {
    stty -echo </dev/tty 2>/dev/null
    sleep 0.3
    while IFS= read -r -t 0.1 -n 1 _d </dev/tty 2>/dev/null; do :; done
    stty echo </dev/tty 2>/dev/null
}

choose_one() {
    local prompt="$1"; shift
    [[ -n "$prompt" ]] && printf '\033[38;5;212m%s\033[0m\n' "$prompt" >/dev/tty
    drain_tty
    COLORFGBG="15;0" $GUM choose "$@" >"$_GUM_TMP"
    drain_tty
    cat "$_GUM_TMP"
}

# ── Header ────────────────────────────────────────────────────────────────────
clear
$GUM style \
    --border rounded \
    --border-foreground 99 \
    --padding "0 2" \
    --bold \
    --foreground 99 \
    "Addon Manager"
echo ""

if [[ ! -d "$HOOKS_DIR" ]]; then
    err "No addons installed"
    exit 1
fi

# ── Helpers ───────────────────────────────────────────────────────────────────
discover_addons() {
    ADDON_NAMES=()
    declare -A _SEEN=()
    for hook_file in "$HOOKS_DIR"/*/[0-9][0-9]-*; do
        [[ -f "$hook_file" ]] || continue
        name=$(basename "$hook_file")
        if [[ -z "${_SEEN[$name]+_}" ]]; then
            ADDON_NAMES+=("$name")
            _SEEN[$name]=1
        fi
    done
    IFS=$'\n' ADDON_NAMES=($(sort <<<"${ADDON_NAMES[*]}")); unset IFS
}

is_enabled() {
    local first
    first=$(find "$HOOKS_DIR" -name "$1" -type f 2>/dev/null | head -1)
    [[ -n "$first" && -x "$first" ]]
}

toggle_addon() {
    local name="$1"
    if is_enabled "$name"; then
        find "$HOOKS_DIR" -name "$name" -type f -exec chmod -x {} \;
        ok "Disabled: $name"
    else
        find "$HOOKS_DIR" -name "$name" -type f -exec chmod +x {} \;
        ok "Enabled: $name"
    fi
}

# ── Main loop ─────────────────────────────────────────────────────────────────
while true; do
    discover_addons

    if [[ ${#ADDON_NAMES[@]} -eq 0 ]]; then
        err "No addons installed"
        exit 1
    fi

    OPTIONS=()
    for name in "${ADDON_NAMES[@]}"; do
        if is_enabled "$name"; then
            OPTIONS+=("✓  $name  [enabled]")
        else
            OPTIONS+=("✗  $name  [disabled]")
        fi
    done
    OPTIONS+=("── Done")

    CHOICE=$(choose_one "Select an addon to toggle:" "${OPTIONS[@]}")
    [[ "$CHOICE" == "── Done" ]] && break

    addon_name=$(echo "$CHOICE" | awk '{print $2}')
    echo ""
    toggle_addon "$addon_name"
    echo ""
done

echo ""
$GUM style \
    --border rounded \
    --border-foreground 2 \
    --padding "1 4" \
    --bold \
    --foreground 2 \
    "Done"
echo ""
