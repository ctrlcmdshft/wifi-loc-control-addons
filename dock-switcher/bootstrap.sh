#!/usr/bin/env bash
set -e

ADDON_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="$HOME/.wifi-loc-control"
USERNAME=$(whoami)

echo "╔══════════════════════════════════════════╗"
echo "║       Dock Switcher Addon — Setup        ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ── Check wifi-loc-control ────────────────────────────────────────────────────
if [[ ! -f /usr/local/bin/wifi-loc-control.sh ]]; then
    echo "✗ wifi-loc-control is not installed."
    echo "  Install it first: https://github.com/vborodulin/wifi-loc-control"
    exit 1
fi
echo "✓ wifi-loc-control found"

# ── Check dependencies ────────────────────────────────────────────────────────
if command -v terminal-notifier &>/dev/null; then
    echo "✓ terminal-notifier found"
else
    echo "⚠ terminal-notifier not found — installing via Homebrew..."
    brew install terminal-notifier
fi

if [[ -x "/Applications/DockFlow.app/Contents/MacOS/DockFlowCLI" ]]; then
    echo "✓ DockFlow found"
else
    echo "⚠ DockFlow not found — dock switching will be skipped"
    echo "  Install DockFlow: https://dockflow.app"
fi

if scutil --nc list 2>/dev/null | grep -q "com.wireguard"; then
    echo "✓ WireGuard VPN profile found"
else
    echo "⚠ No WireGuard VPN profile found — VPN switching will be skipped"
    echo "  Import a WireGuard config in WireGuard.app or System Settings → VPN"
fi

echo ""

# ── Install scripts ───────────────────────────────────────────────────────────
echo "Installing scripts to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"

cp "$ADDON_DIR/scripts/apply.sh" "$INSTALL_DIR/apply.sh"
chmod +x "$INSTALL_DIR/apply.sh"

for location in "$ADDON_DIR/locations/"*; do
    name=$(basename "$location")
    cp "$location" "$INSTALL_DIR/$name"
    chmod +x "$INSTALL_DIR/$name"
    echo "  ✓ $name"
done

# ── Install settings.conf (don't overwrite existing) ─────────────────────────
if [[ -f "$INSTALL_DIR/settings.conf" ]]; then
    echo "⚠ settings.conf already exists — skipping (your settings are preserved)"
else
    cp "$ADDON_DIR/settings.conf" "$INSTALL_DIR/settings.conf"
    echo "✓ settings.conf installed — edit it to configure your locations"
fi

# ── Sudoers for firewall ──────────────────────────────────────────────────────
SUDOERS_FILE="/etc/sudoers.d/wifi-loc-control"
SUDOERS_LINE="$USERNAME ALL=(ALL) NOPASSWD: /usr/libexec/ApplicationFirewall/socketfilterfw"

if sudo grep -q "socketfilterfw" "$SUDOERS_FILE" 2>/dev/null; then
    echo "✓ Firewall sudoers rule already set"
else
    echo "Adding firewall sudoers rule (requires sudo)..."
    echo "$SUDOERS_LINE" | sudo tee -a "$SUDOERS_FILE" > /dev/null
    sudo visudo -c -f "$SUDOERS_FILE"
    echo "✓ Firewall sudoers rule added"
fi

# ── Build VPNHelper.app ───────────────────────────────────────────────────────
echo ""
echo "Building VPNHelper.app (invisible Login Item for VPN switching)..."
bash "$ADDON_DIR/VPNHelper/build.sh"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║            Setup complete!               ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "  1. Edit ~/.wifi-loc-control/settings.conf to configure your locations"
echo "  2. Add VPNHelper.app to Login Items:"
echo "     System Settings → General → Login Items & Extensions → +"
echo "     Select: $ADDON_DIR/VPNHelper/VPNHelper.app"
echo "  3. Switch Wi-Fi networks to test"
echo ""
echo "Logs:"
echo "  wifi-loc-control : ~/Library/Logs/WiFiLocControl.log"
