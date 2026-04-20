#!/opt/homebrew/bin/bash
set -e

ADDON_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="$HOME/.wifi-loc-control"
USERNAME=$(whoami)
DOCKFLOW="/Applications/DockFlow.app/Contents/MacOS/DockFlowCLI"
DRY_RUN=false

[[ "$1" == "--dry-run" ]] && DRY_RUN=true

# ── Colors ────────────────────────────────────────────────────────────────────
BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
RESET='\033[0m'

ok()      { echo -e "${GREEN}✓${RESET} $*"; }
warn()    { echo -e "${YELLOW}⚠${RESET} $*"; }
err()     { echo -e "${RED}✗${RESET} $*"; }
info()    { echo -e "${BLUE}→${RESET} $*"; }
dryrun()  { echo -e "${CYAN}[dry-run]${RESET} $*"; }
hr()      { echo -e "${DIM}────────────────────────────────────────${RESET}"; }

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
        echo -ne "${DIM}Choose (1–${#options[@]}):${RESET} "
        read -r choice
        choice="${choice//[^0-9]/}"
        if [[ -n "$choice" ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
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
$DRY_RUN && echo -e "  ${CYAN}${BOLD}DRY RUN — no files will be written${RESET}"
echo ""

# ── Check requirements ────────────────────────────────────────────────────────
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
    if $DRY_RUN; then
        warn "terminal-notifier not found — would install via Homebrew"
    else
        warn "terminal-notifier not found — installing via Homebrew..."
        brew install terminal-notifier
        ok "terminal-notifier installed"
    fi
fi

HAS_DOCKFLOW=false
if [[ -x "$DOCKFLOW" ]]; then
    ok "DockFlow"
    HAS_DOCKFLOW=true
else
    warn "DockFlow not found — dock switching will be disabled"
    info "Install DockFlow: https://dockflow.app then re-run this script"
    if ! ask "Continue without DockFlow?" "y"; then
        echo "Install DockFlow from https://dockflow.app and run bootstrap.sh again."
        exit 0
    fi
fi

HAS_VPN=false
VPN_TUNNELS=()
while IFS= read -r line; do
    tunnel=$(echo "$line" | grep -o '"[^"]*"' | tail -1 | tr -d '"')
    [[ -n "$tunnel" ]] && VPN_TUNNELS+=("$tunnel")
done < <(scutil --nc list 2>/dev/null | grep "VPN")
if [[ ${#VPN_TUNNELS[@]} -gt 0 ]]; then
    ok "VPN profiles found: ${VPN_TUNNELS[*]}"
    HAS_VPN=true
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
            LOC_VPN LOC_TUNNEL LOC_KILLAPPS LOC_NOTIFY

# ── DockFlow preset assignment (all locations at once) ────────────────────────
if [[ "$HAS_DOCKFLOW" == true ]]; then
    echo ""
    hr
    echo -e "${BOLD}Assign DockFlow presets:${RESET}"
    hr
    echo -ne "${DIM}Presets: "
    for i in "${!PRESETS[@]}"; do
        echo -ne "$((i+1))) ${PRESETS[$i]}  "
    done
    echo -e "${RESET}"
    echo ""
    for loc in "${LOCATIONS[@]}"; do
        while true; do
            echo -ne "  ${BOLD}$loc${RESET} ${DIM}(0 = skip):${RESET} "
            read -r choice
            choice="${choice//[^0-9]/}"
            if [[ "$choice" == "0" || -z "$choice" ]]; then
                LOC_DOCKFLOW[$loc]="off"
                LOC_PRESET[$loc]=""
                break
            elif [[ -n "$choice" ]] && (( choice >= 1 && choice <= ${#PRESETS[@]} )); then
                LOC_DOCKFLOW[$loc]="on"
                LOC_PRESET[$loc]="${PRESETS[$((choice-1))]}"
                break
            fi
            warn "Enter a number between 1 and ${#PRESETS[@]}, or 0 to skip."
        done
    done
else
    for loc in "${LOCATIONS[@]}"; do
        LOC_DOCKFLOW[$loc]="off"
        LOC_PRESET[$loc]=""
    done
fi

for loc in "${LOCATIONS[@]}"; do
    echo ""
    hr
    echo -e "${BOLD}Configure: $loc${RESET}"
    hr

    default_fw="n"; [[ "$loc" != "Home" ]] && default_fw="y"
    if ask "Enable firewall?" "$default_fw"; then
        LOC_FIREWALL[$loc]="on"
    else
        LOC_FIREWALL[$loc]="off"
    fi

    default_st="n"; [[ "$loc" == "Remote" || "$loc" == "Automatic" ]] && default_st="y"
    if ask "Enable stealth mode?" "$default_st"; then
        LOC_STEALTH[$loc]="on"
    else
        LOC_STEALTH[$loc]="off"
    fi

    default_ad="y"; [[ "$loc" != "Home" ]] && default_ad="n"
    if ask "Enable AirDrop?" "$default_ad"; then
        LOC_AIRDROP[$loc]="on"
    else
        LOC_AIRDROP[$loc]="off"
    fi

    if [[ "$HAS_VPN" == true && ${#VPN_TUNNELS[@]} -gt 0 ]]; then
        default_vpn="n"; [[ "$loc" == "Remote" || "$loc" == "Automatic" ]] && default_vpn="y"
        if ask "Enable VPN?" "$default_vpn"; then
            LOC_VPN[$loc]="on"
            if [[ ${#VPN_TUNNELS[@]} -eq 1 ]]; then
                LOC_TUNNEL[$loc]="${VPN_TUNNELS[0]}"
                ok "Using tunnel: ${VPN_TUNNELS[0]}"
            else
                echo -e "${BOLD}Available tunnels:${RESET}"
                for i in "${!VPN_TUNNELS[@]}"; do
                    echo -e "  ${DIM}$((i+1)))${RESET} ${VPN_TUNNELS[$i]}"
                done
                while true; do
                    echo -ne "${DIM}Choose (1–${#VPN_TUNNELS[@]}):${RESET} "
                    read -r tchoice
                    tchoice="${tchoice//[^0-9]/}"
                    if [[ -n "$tchoice" ]] && (( tchoice >= 1 && tchoice <= ${#VPN_TUNNELS[@]} )); then
                        LOC_TUNNEL[$loc]="${VPN_TUNNELS[$((tchoice-1))]}"
                        break
                    fi
                    warn "Invalid choice, try again."
                done
            fi
        else
            LOC_VPN[$loc]="off"
            LOC_TUNNEL[$loc]=""
        fi
    else
        LOC_VPN[$loc]="off"
        LOC_TUNNEL[$loc]=""
    fi

    echo -ne "${BOLD}Apps to quit on switch?${RESET} ${DIM}(comma-separated, or leave blank)${RESET} "
    read -r killapps
    LOC_KILLAPPS[$loc]="$killapps"

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
printf "%-14s %-12s %-10s %-10s %-10s %-20s %-6s\n" "Location" "Dock" "Firewall" "Stealth" "AirDrop" "VPN" "Notify"
printf "%-14s %-12s %-10s %-10s %-10s %-20s %-6s\n" "--------" "----" "--------" "-------" "-------" "---" "------"
for loc in "${LOCATIONS[@]}"; do
    dock_info="${LOC_DOCKFLOW[$loc]}"
    [[ "${LOC_DOCKFLOW[$loc]}" == "on" ]] && dock_info="${LOC_PRESET[$loc]}"
    vpn_info="${LOC_VPN[$loc]}"
    [[ "${LOC_VPN[$loc]}" == "on" ]] && vpn_info="${LOC_TUNNEL[$loc]}"
    printf "%-14s %-12s %-10s %-10s %-10s %-20s %-6s\n" \
        "$loc" "$dock_info" "${LOC_FIREWALL[$loc]}" "${LOC_STEALTH[$loc]}" \
        "${LOC_AIRDROP[$loc]}" "$vpn_info" "${LOC_NOTIFY[$loc]}"
done
echo ""

# ── Dry run: show generated files and exit ────────────────────────────────────
if $DRY_RUN; then
    hr
    echo -e "${CYAN}${BOLD}[dry-run] settings.conf preview:${RESET}"
    hr
    echo ""

    for loc in "${LOCATIONS[@]}"; do
        KEY=$(echo "$loc" | tr '[:lower:]' '[:upper:]' | tr ' ' '_')
        echo "# $loc"
        echo "${KEY}_dockflow=${LOC_DOCKFLOW[$loc]}"
        [[ "${LOC_DOCKFLOW[$loc]}" == "on" ]] && echo "${KEY}_dockflow_preset=\"${LOC_PRESET[$loc]}\""
        echo "${KEY}_firewall=${LOC_FIREWALL[$loc]}"
        echo "${KEY}_stealth_mode=${LOC_STEALTH[$loc]}"
        echo "${KEY}_airdrop=${LOC_AIRDROP[$loc]}"
        echo "${KEY}_wireguard=${LOC_VPN[$loc]}"
        echo "${KEY}_wireguard_tunnel=\"${LOC_TUNNEL[$loc]}\""
        echo "${KEY}_kill_apps=\"${LOC_KILLAPPS[$loc]}\""
        echo "${KEY}_notification=${LOC_NOTIFY[$loc]}"
        echo ""
    done

    hr
    echo -e "${CYAN}${BOLD}[dry-run] Location scripts that would be created:${RESET}"
    hr
    for loc in "${LOCATIONS[@]}"; do
        dryrun "$INSTALL_DIR/$loc"
    done
    dryrun "$INSTALL_DIR/apply.sh"
    dryrun "VPNHelper.app (built from source)"
    echo ""
    echo -e "${CYAN}Run without --dry-run to apply.${RESET}"
    exit 0
fi

if ! ask "Proceed with installation?" "y"; then
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

for loc in "${LOCATIONS[@]}"; do
    KEY=$(echo "$loc" | tr '[:lower:]' '[:upper:]' | tr ' ' '_')
    echo "# ── $loc ──────────────────────────────────────────────────────────────────────"
    echo "${KEY}_dockflow=${LOC_DOCKFLOW[$loc]}"
    [[ "${LOC_DOCKFLOW[$loc]}" == "on" ]] && echo "${KEY}_dockflow_preset=\"${LOC_PRESET[$loc]}\""
    echo "${KEY}_firewall=${LOC_FIREWALL[$loc]}"
    echo "${KEY}_stealth_mode=${LOC_STEALTH[$loc]}"
    echo "${KEY}_airdrop=${LOC_AIRDROP[$loc]}"
    echo "${KEY}_wireguard=${LOC_VPN[$loc]}"
    echo "${KEY}_wireguard_tunnel=\"${LOC_TUNNEL[$loc]}\""
    echo "${KEY}_kill_apps=\"${LOC_KILLAPPS[$loc]}\""
    echo "${KEY}_notification=${LOC_NOTIFY[$loc]}"
    echo ""
done
} > "$CONF_FILE"
ok "settings.conf → $CONF_FILE"

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
VPNHELPER_APP="$ADDON_DIR/VPNHelper/VPNHelper.app"
if [[ "$HAS_VPN" == true && -n "$SELECTED_TUNNEL" ]]; then
    echo ""
    info "Building VPNHelper.app..."
    bash "$ADDON_DIR/VPNHelper/build.sh"
    echo ""
    info "Opening System Settings → Login Items..."
    echo -e "  ${YELLOW}Click ${BOLD}+${RESET}${YELLOW} and select:${RESET}"
    echo -e "  ${BOLD}$VPNHELPER_APP${RESET}"
    echo ""
    read -rp "$(echo -e "${DIM}Press Enter when ready to open System Settings...${RESET}")"
    open "x-apple.systempreferences:com.apple.LoginItems-Settings.extension"
    echo ""
    read -rp "$(echo -e "${DIM}Press Enter once VPNHelper.app is added to Login Items...${RESET}")"
    ok "VPNHelper.app registered"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}${BOLD}║           Setup complete!                ║${RESET}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════╝${RESET}"
echo ""

echo -e "${BOLD}To adjust settings:${RESET}"
echo "  Edit ~/.wifi-loc-control/settings.conf"
echo ""
echo -e "${BOLD}Logs:${RESET}"
echo "  tail -f ~/Library/Logs/WiFiLocControl.log"
