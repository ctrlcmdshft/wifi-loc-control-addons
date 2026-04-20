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
    "Loc Wallpaper — Uninstall"
echo ""

if ! $GUM confirm --default=no "Remove Loc Wallpaper and its installed files?"; then
    echo "Aborted."
    exit 0
fi
echo ""

rm -f "$INSTALL_DIR/wallpaper-apply.sh"
ok "wallpaper-apply.sh removed"

if [[ -f "$INSTALL_DIR/wallpaper.conf" ]]; then
    if $GUM confirm --default=no "Remove wallpaper.conf? (your per-location wallpaper config will be lost)"; then
        rm -f "$INSTALL_DIR/wallpaper.conf"
        ok "wallpaper.conf removed"
    else
        warn "Keeping wallpaper.conf"
    fi
fi

find "$INSTALL_DIR/hooks" -name "02-wallpaper" -delete 2>/dev/null || true
ok "Hooks removed"

echo ""
$GUM style \
    --border rounded \
    --border-foreground 2 \
    --padding "1 4" \
    --bold \
    --foreground 2 \
    "Loc Wallpaper uninstalled"
echo ""
