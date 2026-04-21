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
    "Loc Display — Uninstall"
echo ""

if ! $GUM confirm --default=no "Remove Loc Display and its installed files?"; then
    echo "Aborted."
    exit 0
fi
echo ""

rm -f "$INSTALL_DIR/display-apply.sh"
ok "display-apply.sh removed"

if [[ -f "$INSTALL_DIR/display.conf" ]]; then
    if $GUM confirm --default=no "Remove display.conf? (your per-location display config will be lost)"; then
        rm -f "$INSTALL_DIR/display.conf"
        ok "display.conf removed"
    else
        warn "Keeping display.conf"
    fi
fi

find "$INSTALL_DIR/hooks" -name "04-display" -delete 2>/dev/null || true
ok "Hooks removed"

echo ""
$GUM style \
    --border rounded \
    --border-foreground 2 \
    --padding "1 4" \
    --bold \
    --foreground 2 \
    "Loc Display uninstalled"
echo ""
