#!/opt/homebrew/bin/bash
set -e

INSTALL_DIR="$HOME/.wifi-loc-control"

if ! command -v gum &>/dev/null; then
    echo "Installing gum..."
    brew install gum
fi
GUM=$(which gum)

ok()   { $GUM style --foreground 2   "✓ $*"; }
warn() { $GUM style --foreground 214 "⚠ $*"; }

$GUM style \
    --border rounded \
    --border-foreground 1 \
    --padding "0 2" \
    --bold \
    --foreground 1 \
    "Loc Audio — Uninstall"
echo ""

if ! $GUM confirm --default=no "Remove Loc Audio and its installed files?"; then
    echo "Aborted."
    exit 0
fi
echo ""

rm -f "$INSTALL_DIR/audio-apply.sh"
ok "audio-apply.sh removed"

if [[ -f "$INSTALL_DIR/audio.conf" ]]; then
    if $GUM confirm --default=no "Remove audio.conf? (your per-location audio config will be lost)"; then
        rm -f "$INSTALL_DIR/audio.conf"
        ok "audio.conf removed"
    else
        warn "Keeping audio.conf"
    fi
fi

find "$INSTALL_DIR/hooks" -name "03-audio" -delete 2>/dev/null || true
ok "Hooks removed"

echo ""
$GUM style \
    --border rounded \
    --border-foreground 2 \
    --padding "1 4" \
    --bold \
    --foreground 2 \
    "Loc Audio uninstalled"
echo ""
