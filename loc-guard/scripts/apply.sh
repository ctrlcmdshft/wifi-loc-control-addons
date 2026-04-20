#!/usr/bin/env bash
exec 2>&1

# Ensure Homebrew tools are available when run via LaunchAgent (stripped PATH)
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

LOCATION="$1"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="$SCRIPT_DIR/settings.conf"
FIREWALL="/usr/libexec/ApplicationFirewall/socketfilterfw"

source "$CONFIG"

# Build config key: uppercase, spaces to underscores
KEY=$(echo "$LOCATION" | tr '[:lower:]' '[:upper:]' | tr ' ' '_')

val() { local _v="${KEY}_${1}"; echo "${!_v}"; }

# ── Firewall ──────────────────────────────────────────────────────────────────
if [[ "$(val firewall)" == "on" ]]; then
    sudo "$FIREWALL" --setglobalstate on
else
    sudo "$FIREWALL" --setglobalstate off
fi

# ── Stealth Mode ──────────────────────────────────────────────────────────────
if [[ "$(val stealth_mode)" == "on" ]]; then
    sudo "$FIREWALL" --setstealthmode on
else
    sudo "$FIREWALL" --setstealthmode off
fi

# ── AirDrop ───────────────────────────────────────────────────────────────────
if [[ "$(val airdrop)" == "on" ]]; then
    defaults write com.apple.NetworkBrowser DisableAirDrop -bool false
else
    defaults write com.apple.NetworkBrowser DisableAirDrop -bool true
fi

# ── WireGuard VPN ─────────────────────────────────────────────────────────────
if [[ "$(val wireguard)" == "on" ]]; then
    echo "on:$(val wireguard_tunnel):$(date +%s)" > "$SCRIPT_DIR/vpn-trigger"
else
    echo "off:$(val wireguard_tunnel):$(date +%s)" > "$SCRIPT_DIR/vpn-trigger"
fi

# ── Kill Apps ─────────────────────────────────────────────────────────────────
kill_apps="$(val kill_apps)"
if [[ -n "$kill_apps" ]]; then
    IFS=',' read -ra apps <<< "$kill_apps"
    for app in "${apps[@]}"; do
        app="${app#"${app%%[![:space:]]*}"}"
        app="${app%"${app##*[![:space:]]}"}"
        pkill -x "$app" 2>/dev/null || true
    done
fi

# ── Notification ──────────────────────────────────────────────────────────────
if [[ "$(val notification)" == "on" ]] && command -v terminal-notifier &>/dev/null; then
    summary=()
    [[ "$(val firewall)"     == "on" ]] && summary+=("Firewall on")
    [[ "$(val stealth_mode)" == "on" ]] && summary+=("Stealth on")
    if [[ "$(val airdrop)" == "on" ]]; then summary+=("AirDrop on"); else summary+=("AirDrop off"); fi
    [[ "$(val wireguard)"    == "on" ]] && summary+=("VPN on")
    body=$(IFS=" · "; echo "${summary[*]}")
    terminal-notifier \
        -title "WiFi Location" \
        -subtitle "Switched to $LOCATION" \
        -message "$body" \
        -sound "Glass" \
        -group "wifi-location"
fi
