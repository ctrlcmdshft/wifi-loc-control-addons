#!/usr/bin/env bash
set -e

ADDON_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="$HOME/.wifi-loc-control"
USERNAME=$(whoami)
DOCKFLOW="/Applications/DockFlow.app/Contents/MacOS/DockFlowCLI"

# ── Colors ────────────────────────────────────────────────────────────────────
BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
RESET='\033[0m'

ok()   { echo -e "${GREEN}✓${RESET} $*"; }
warn() { echo -e "${YELLOW}⚠${RESET} $*"; }
err()  { echo -e "${RED}✗${RESET} $*"; }
info() { echo -e "${BLUE}→${RESET} $*"; }
hr()   { echo -e "${DIM}────────────────────────────────────────${RESET}"; }

ask() {
    local prompt="$1" default="$2" reply
    local hint="[Y/n]"; [[ "$default" == "n" ]] && hint="[y/N]"
    echo -ne "${BOLD}$prompt${RESET} ${DIM}$hint${RESET} "
    read -r reply
    reply="${reply:-$default}"
    [[ "$reply" =~ ^[Yy] ]]
}

pick() {
    local prompt="$1"; shift
    local options=("$@")
    echo -e "${BOLD}$prompt${RESET}"
    for i in "${!options[@]}"; do
        echo -e "  ${DIM}$((i+1)))${RESET} ${options[$i]}"
    done
    while true; do
        echo -ne "${DIM}Enter number (1-${#options[@]}):${RESET} "
        read -r choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
            PICK_RESULT="${options[$((choice-1))]}"
            return
        fi
        warn "Invalid choice, try again."
    done
}

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║       Dock Switcher — Interactive Setup  ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${RESET}"
echo ""

# ── Check wifi-loc-control ────────────────────────────────────────────────────
hr
echo -e "${BOLD}Checking requirements...${RESET}"
hr

if [[ ! -f /usr/local/bin/wifi-loc-control.sh ]]; then
    err "wifi-loc-control is not installed."
    info "Install it first: https://github.com/vborodulin/wifi-loc-control"
    exit 1
fi
ok "wifi-loc-control"

if command -v terminal-notifier &>/dev/null; then
    ok "terminal-notifier"
else
    warn "terminal-notifier not found — installing via Homebrew..."
    brew install terminal-notifier
    ok "terminal-notifier installed"
fi

HAS_DOCKFLOW=false
if [[ -x "$DOCKFLOW" ]]; then
    ok "DockFlow"
    HAS_DOCKFLOW=true
else
    warn "DockFlow not found — dock switching will be disabled"
    info "Install DockFlow: https://dockflow.app"
fi

HAS_WIREGUARD=false
WG_TUNNELS=()
while IFS= read -r line; do
    tunnel=$(echo "$line" | grep -o '"[^"]*"' | tail -1 | tr -d '"')
    [[ -n "$tunnel" ]] && WG_TUNNELS+=("$tunnel")
done < <(scutil --nc list 2>/dev/null | grep "VPN")
if [[ ${#WG_TUNNELS[@]} -gt 0 ]]; then
    ok "VPN profiles found: ${WG_TUNNELS[*]}"
    HAS_WIREGUARD=true
else
    warn "No VPN profiles found — VPN switching will be disabled"
    info "Add a VPN in System Settings → VPN to enable this feature"
fi

# ── Read macOS network locations ──────────────────────────────────────────────
LOCATIONS=()
while IFS= read -r line; do
    loc=$(echo "$line" | sed 's/.*(\(.*\))/\1/')
    [[ -n "$loc" ]] && LOCATIONS+=("$loc")
done < <(scselect 2>/dev/null | grep -E '^\s+[\*]?\s+[A-F0-9-]+\s+\(' | sed 's/^ \* //' | sed 's/^   //')

# ── Read DockFlow presets ─────────────────────────────────────────────────────
PRESETS=()
if [[ "$HAS_DOCKFLOW" == true ]]; then
    while IFS= read -r line; do
        preset=$(echo "$line" | sed 's/^- \(.*\) (ID:.*/\1/')
        [[ -n "$preset" && "$preset" != "$line" ]] && PRESETS+=("$preset")
    done < <("$DOCKFLOW" list 2>/dev/null | grep "^-")
fi

echo ""
hr
echo -e "${BOLD}Found ${#LOCATIONS[@]} network location(s): ${LOCATIONS[*]}${RESET}"
hr
echo ""

# ── Per-location configuration ────────────────────────────────────────────────
declare -A LOC_DOCKFLOW LOC_PRESET LOC_FIREWALL LOC_STEALTH LOC_AIRDROP \
            LOC_WIREGUARD LOC_TUNNEL LOC_KILLAPPS LOC_NOTIFY

SELECTED_TUNNEL=""
if [[ "$HAS_WIREGUARD" == true && ${#WG_TUNNELS[@]} -gt 0 ]]; then
    echo ""
    if [[ ${#WG_TUNNELS[@]} -eq 1 ]]; then
        SELECTED_TUNNEL="${WG_TUNNELS[0]}"
        ok "Using WireGuard tunnel: ${BOLD}$SELECTED_TUNNEL${RESET}"
    else
        pick "Which WireGuard tunnel should be used?" "${WG_TUNNELS[@]}"
        SELECTED_TUNNEL="$PICK_RESULT"
    fi
fi

for loc in "${LOCATIONS[@]}"; do
    echo ""
    hr
    echo -e "${BOLD}Configure: $loc${RESET}"
    hr

    # DockFlow
    if [[ "$HAS_DOCKFLOW" == true ]]; then
        if ask "Enable dock switching?" "y"; then
            LOC_DOCKFLOW[$loc]="on"
            pick "Which DockFlow preset for $loc?" "${PRESETS[@]}"
            LOC_PRESET[$loc]="$PICK_RESULT"
        else
            LOC_DOCKFLOW[$loc]="off"
            LOC_PRESET[$loc]=""
        fi
    else
        LOC_DOCKFLOW[$loc]="off"
        LOC_PRESET[$loc]=""
    fi

    # Firewall
    default_fw="n"; [[ "$loc" != "Home" ]] && default_fw="y"
    if ask "Enable firewall?" "$default_fw"; then
        LOC_FIREWALL[$loc]="on"
    else
        LOC_FIREWALL[$loc]="off"
    fi

    # Stealth mode
    default_st="n"; [[ "$loc" == "Remote" || "$loc" == "Automatic" ]] && default_st="y"
    if ask "Enable stealth mode?" "$default_st"; then
        LOC_STEALTH[$loc]="on"
    else
        LOC_STEALTH[$loc]="off"
    fi

    # AirDrop
    default_ad="y"; [[ "$loc" != "Home" ]] && default_ad="n"
    if ask "Enable AirDrop?" "$default_ad"; then
        LOC_AIRDROP[$loc]="on"
    else
        LOC_AIRDROP[$loc]="off"
    fi

    # WireGuard VPN
    if [[ "$HAS_WIREGUARD" == true && -n "$SELECTED_TUNNEL" ]]; then
        default_wg="n"; [[ "$loc" == "Remote" || "$loc" == "Automatic" ]] && default_wg="y"
        if ask "Enable VPN ($SELECTED_TUNNEL)?" "$default_wg"; then
            LOC_WIREGUARD[$loc]="on"
        else
            LOC_WIREGUARD[$loc]="off"
        fi
    else
        LOC_WIREGUARD[$loc]="off"
    fi

    # Kill apps
    echo -ne "${BOLD}Apps to quit on switch?${RESET} ${DIM}(comma-separated, or leave blank)${RESET} "
    read -r killapps
    LOC_KILLAPPS[$loc]="$killapps"

    # Notifications
    if ask "Show notification on switch?" "y"; then
        LOC_NOTIFY[$loc]="on"
    else
        LOC_NOTIFY[$loc]="off"
    fi
done

# ── Review ────────────────────────────────────────────────────────────────────
echo ""
hr
echo -e "${BOLD}Review your configuration:${RESET}"
hr
printf "%-14s %-10s %-10s %-10s %-10s %-10s %-6s\n" "Location" "Dock" "Firewall" "Stealth" "AirDrop" "VPN" "Notify"
printf "%-14s %-10s %-10s %-10s %-10s %-10s %-6s\n" "--------" "----" "--------" "-------" "-------" "---" "------"
for loc in "${LOCATIONS[@]}"; do
    dock_info="${LOC_DOCKFLOW[$loc]}"
    [[ "${LOC_DOCKFLOW[$loc]}" == "on" ]] && dock_info="${LOC_PRESET[$loc]}"
    printf "%-14s %-10s %-10s %-10s %-10s %-10s %-6s\n" \
        "$loc" "$dock_info" "${LOC_FIREWALL[$loc]}" "${LOC_STEALTH[$loc]}" \
        "${LOC_AIRDROP[$loc]}" "${LOC_WIREGUARD[$loc]}" "${LOC_NOTIFY[$loc]}"
done
echo ""

if ! ask "Looks good? Proceed with installation?" "y"; then
    echo "Aborted."
    exit 0
fi

# ── Generate settings.conf ────────────────────────────────────────────────────
echo ""
info "Generating settings.conf..."

CONF_FILE="$INSTALL_DIR/settings.conf"
mkdir -p "$INSTALL_DIR"

{
echo "# Dock Switcher Settings — generated by bootstrap.sh"
echo "# Edit this file to adjust toggles. Changes take effect on next location switch."
echo ""

if [[ -n "$SELECTED_TUNNEL" ]]; then
    echo "# ── WireGuard Tunnel (change here if you switch servers) ─────────────────────"
    echo "WIREGUARD_TUNNEL=\"$SELECTED_TUNNEL\""
    echo ""
fi

for loc in "${LOCATIONS[@]}"; do
    KEY=$(echo "$loc" | tr '[:lower:]' '[:upper:]' | tr ' ' '_')
    echo "# ── $loc ──────────────────────────────────────────────────────────────────────"
    echo "${KEY}_dockflow=${LOC_DOCKFLOW[$loc]}"
    [[ "${LOC_DOCKFLOW[$loc]}" == "on" ]] && echo "${KEY}_dockflow_preset=\"${LOC_PRESET[$loc]}\""
    echo "${KEY}_firewall=${LOC_FIREWALL[$loc]}"
    echo "${KEY}_stealth_mode=${LOC_STEALTH[$loc]}"
    echo "${KEY}_airdrop=${LOC_AIRDROP[$loc]}"
    echo "${KEY}_wireguard=${LOC_WIREGUARD[$loc]}"
    echo "${KEY}_kill_apps=\"${LOC_KILLAPPS[$loc]}\""
    echo "${KEY}_notification=${LOC_NOTIFY[$loc]}"
    echo ""
done
} > "$CONF_FILE"

ok "settings.conf written to $CONF_FILE"

# ── Install scripts ───────────────────────────────────────────────────────────
info "Installing scripts..."

cp "$ADDON_DIR/scripts/apply.sh" "$INSTALL_DIR/apply.sh"
chmod +x "$INSTALL_DIR/apply.sh"
ok "apply.sh"

for loc in "${LOCATIONS[@]}"; do
    script="$INSTALL_DIR/$loc"
    cat > "$script" << EOF
#!/usr/bin/env bash
exec 2>&1
"\$(dirname "\$0")/apply.sh" "$loc"
EOF
    chmod +x "$script"
    ok "Location script: $loc"
done

# ── Sudoers ───────────────────────────────────────────────────────────────────
SUDOERS_FILE="/etc/sudoers.d/wifi-loc-control"
SUDOERS_LINE="$USERNAME ALL=(ALL) NOPASSWD: /usr/libexec/ApplicationFirewall/socketfilterfw"

if sudo grep -q "socketfilterfw" "$SUDOERS_FILE" 2>/dev/null; then
    ok "Firewall sudoers rule already set"
else
    info "Adding firewall sudoers rule (requires sudo)..."
    echo "$SUDOERS_LINE" | sudo tee -a "$SUDOERS_FILE" > /dev/null
    sudo visudo -c -f "$SUDOERS_FILE"
    ok "Firewall sudoers rule added"
fi

# ── Build VPNHelper.app ───────────────────────────────────────────────────────
if [[ "$HAS_WIREGUARD" == true && -n "$SELECTED_TUNNEL" ]]; then
    echo ""
    info "Building VPNHelper.app..."
    bash "$ADDON_DIR/VPNHelper/build.sh"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}${BOLD}║           Setup complete!                ║${RESET}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════╝${RESET}"
echo ""

if [[ "$HAS_WIREGUARD" == true && -n "$SELECTED_TUNNEL" ]]; then
    echo -e "${BOLD}Action required:${RESET}"
    echo "  Add VPNHelper.app to Login Items so VPN switching works at login:"
    echo -e "  ${BLUE}System Settings → General → Login Items & Extensions → +${RESET}"
    echo "  Select: $ADDON_DIR/VPNHelper/VPNHelper.app"
    echo ""
fi

echo -e "${BOLD}To adjust settings:${RESET}"
echo "  Edit ~/.wifi-loc-control/settings.conf"
echo ""
echo -e "${BOLD}Logs:${RESET}"
echo "  tail -f ~/Library/Logs/WiFiLocControl.log"
