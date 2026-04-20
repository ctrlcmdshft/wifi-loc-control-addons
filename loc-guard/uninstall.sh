#!/opt/homebrew/bin/bash
set -e

INSTALL_DIR="$HOME/.wifi-loc-control"
ADDON_DIR="$(cd "$(dirname "$0")" && pwd)"
VPNHELPER_APP="$ADDON_DIR/VPNHelper/VPNHelper.app"
SUDOERS_FILE="/etc/sudoers.d/wifi-loc-control"

# ── gum ───────────────────────────────────────────────────────────────────────
if ! command -v gum &>/dev/null; then
    echo "Installing gum..."
    brew install gum
fi
GUM=$(which gum)

ok()   { $GUM style --foreground 2   "✓ $*"; }
warn() { $GUM style --foreground 214 "⚠ $*"; }
info() { $GUM style --foreground 12  "→ $*"; }

$GUM style \
    --border rounded \
    --border-foreground 1 \
    --padding "0 2" \
    --bold \
    --foreground 1 \
    "Loc Guard — Uninstall"
echo ""

if ! $GUM confirm --default=no "Remove Loc Guard and all its installed files?"; then
    echo "Aborted."
    exit 0
fi
echo ""

# ── Stop VPNHelper ────────────────────────────────────────────────────────────
if pgrep -x VPNHelper &>/dev/null; then
    pkill -x VPNHelper 2>/dev/null || true
    ok "VPNHelper stopped"
fi

# ── Remove installed scripts ──────────────────────────────────────────────────
rm -f "$INSTALL_DIR/apply.sh"
rm -f "$INSTALL_DIR/vpn-trigger"
ok "apply.sh removed"

# Remove location dispatcher scripts
while IFS= read -r script; do
    rm -f "$script"
done < <(find "$INSTALL_DIR" -maxdepth 1 -type f -perm +0111 ! -name "*.sh" ! -name "*.conf" 2>/dev/null)
ok "Location scripts removed"

# Remove loc-guard hooks (leave other addons' hooks intact)
if [[ -d "$INSTALL_DIR/hooks" ]]; then
    find "$INSTALL_DIR/hooks" -name "01-loc-guard" -delete 2>/dev/null
    # Remove any now-empty location hook dirs
    find "$INSTALL_DIR/hooks" -mindepth 1 -maxdepth 1 -type d -empty -delete 2>/dev/null
    # Remove hooks dir itself if empty
    rmdir "$INSTALL_DIR/hooks" 2>/dev/null || true
    ok "loc-guard hooks removed"
fi

# ── Remove settings.conf ──────────────────────────────────────────────────────
if [[ -f "$INSTALL_DIR/settings.conf" ]]; then
    if $GUM confirm --default=no "Remove settings.conf? (your per-location config will be lost)"; then
        rm -f "$INSTALL_DIR/settings.conf"
        ok "settings.conf removed"
    else
        warn "Keeping settings.conf"
    fi
fi

# ── Remove sudoers entry ──────────────────────────────────────────────────────
if sudo grep -q "socketfilterfw" "$SUDOERS_FILE" 2>/dev/null; then
    sudo sed -i '' '/socketfilterfw/d' "$SUDOERS_FILE"
    ok "Firewall sudoers rule removed"
fi

# ── VPNHelper Login Item reminder ─────────────────────────────────────────────
if [[ -f "$VPNHELPER_APP/Contents/MacOS/VPNHelper" ]]; then
    echo ""
    warn "VPNHelper.app is still in Login Items — remove it manually:"
    info "System Settings → General → Login Items & Extensions"
    echo ""
    if $GUM confirm --default=yes "Open Login Items now?"; then
        open "x-apple.systempreferences:com.apple.LoginItems-Settings.extension"
    fi
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
$GUM style \
    --border rounded \
    --border-foreground 2 \
    --padding "1 4" \
    --bold \
    --foreground 2 \
    "Loc Guard uninstalled"
echo ""
