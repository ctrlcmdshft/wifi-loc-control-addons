#!/opt/homebrew/bin/bash
set -e

ADDON_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="$HOME/.wifi-loc-control"
USERNAME=$(whoami)
DRY_RUN=false

[[ "$1" == "--dry-run" ]] && DRY_RUN=true

# ── Install gum if needed ─────────────────────────────────────────────────────
if ! command -v gum &>/dev/null; then
    echo "Installing gum (required for interactive setup)..."
    brew install gum
fi

GUM=$(which gum)

# ── Helpers ───────────────────────────────────────────────────────────────────
header() {
    echo ""
    $GUM style \
        --border rounded \
        --border-foreground 99 \
        --padding "0 2" \
        --bold \
        --foreground 99 \
        "$1"
    echo ""
}

section() {
    echo ""
    $GUM style --foreground 212 --bold "── $1"
}

ok()   { $GUM style --foreground 2   "✓ $*"; }
warn() { $GUM style --foreground 214 "⚠ $*"; }
err()  { $GUM style --foreground 1   "✗ $*"; }
info() { $GUM style --foreground 12  "→ $*"; }

confirm() {
    local prompt="$1" default="${2:-y}"
    local flag="--default=yes"
    [[ "$default" == "n" ]] && flag="--default=no"
    $GUM confirm $flag "$prompt"
}

drain_tty() {
    stty -echo </dev/tty 2>/dev/null
    sleep 0.3
    while IFS= read -r -t 0.1 -n 1 _d </dev/tty 2>/dev/null; do :; done
    stty echo </dev/tty 2>/dev/null
}

_GUM_TMP=$(mktemp)
trap 'rm -f "$_GUM_TMP"' EXIT

choose_one() {
    local prompt="$1"; shift
    if [[ -n "$prompt" ]]; then
        $GUM style --foreground 212 "$prompt" >/dev/tty
        drain_tty
    fi
    $GUM choose "$@" >"$_GUM_TMP"
    cat "$_GUM_TMP"
}

choose_many() {
    local prompt="$1"; shift
    if [[ -n "$prompt" ]]; then
        $GUM style --foreground 212 "$prompt" >/dev/tty
        drain_tty
    fi
    $GUM choose --no-limit "$@" >"$_GUM_TMP"
    cat "$_GUM_TMP"
}

# ── Header ────────────────────────────────────────────────────────────────────
clear
header "Loc Guard — Interactive Setup"
$DRY_RUN && $GUM style --foreground 214 --bold "  DRY RUN — no files will be written"

# ── Requirements ──────────────────────────────────────────────────────────────
section "Checking requirements"

# wifi-loc-control
if [[ ! -f /usr/local/bin/wifi-loc-control.sh ]]; then
    err "wifi-loc-control is not installed (required)"
    echo ""
    $GUM style --faint "  This addon requires wifi-loc-control to detect network location changes."
    echo ""
    WLCACTION=$(choose_one "What would you like to do?" \
        "Open install page in browser (https://github.com/vborodulin/wifi-loc-control)" \
        "Exit and install manually")
    if [[ "$WLCACTION" == "Open"* ]]; then
        open "https://github.com/vborodulin/wifi-loc-control"
        echo ""
        $GUM style --faint "  Install wifi-loc-control, then re-run this script."
    fi
    exit 1
fi
ok "wifi-loc-control"

# terminal-notifier
if command -v terminal-notifier &>/dev/null; then
    ok "terminal-notifier"
else
    warn "terminal-notifier not found"
    if $DRY_RUN; then
        info "Would install via: brew install terminal-notifier"
    else
        if confirm "Install terminal-notifier via Homebrew? (needed for notifications)"; then
            $GUM spin --spinner dot --title "Installing terminal-notifier..." -- brew install terminal-notifier
            ok "terminal-notifier installed"
        else
            warn "Skipping — notifications will not work"
        fi
    fi
fi

# VPN profiles
HAS_VPN=false
VPN_TUNNELS=()

load_vpn_tunnels() {
    VPN_TUNNELS=()
    while IFS= read -r line; do
        # Try proper quoted match first; fall back for scutil-truncated names (no closing ")
        tunnel=$(echo "$line" | sed -n 's/.*[[:space:]]"\([^"]*\)".*/\1/p')
        if [[ -z "$tunnel" ]]; then
            tunnel=$(echo "$line" | sed -n 's/.*[[:space:]]"\([^[]*\)[[:space:]]*\[VPN.*/\1/p' | sed 's/[[:space:]]*$//')
        fi
        if [[ -n "$tunnel" ]]; then
            VPN_TUNNELS+=("$tunnel")
        fi
    done < <(scutil --nc list 2>/dev/null | grep "\[VPN")
}

load_vpn_tunnels
if [[ ${#VPN_TUNNELS[@]} -gt 0 ]]; then
    ok "VPN profiles: ${VPN_TUNNELS[*]}"
    HAS_VPN=true
else
    warn "No VPN profiles found — VPN switching will be disabled"
    echo ""
    $GUM style --faint "  Add a VPN in System Settings → VPN to enable this feature."
    if confirm "Open System Settings → VPN now?" n; then
        open "x-apple.systempreferences:com.apple.NetworkExtensionSettingsUI.NESettingsUIExtension"
        echo ""
        info "Add a VPN profile, then press Enter to re-check."
        read -rp ""
        load_vpn_tunnels
        if [[ ${#VPN_TUNNELS[@]} -gt 0 ]]; then
            ok "VPN profiles: ${VPN_TUNNELS[*]}"
            HAS_VPN=true
        else
            warn "Still no VPN profiles — VPN switching will be disabled"
        fi
    fi
fi

# ── Read macOS network locations ──────────────────────────────────────────────
section "Detecting network locations"

LOCATIONS=()
ACTIVE_LOC=""
while IFS= read -r line; do
    loc=$(echo "$line" | sed 's/.*(\(.*\))/\1/')
    [[ -z "$loc" ]] && continue
    LOCATIONS+=("$loc")
    echo "$line" | grep -q '^\s*\*' && ACTIVE_LOC="$loc"
done < <(scselect 2>/dev/null | grep -E '^\s+\*?\s+[A-F0-9-]+')

if [[ ${#LOCATIONS[@]} -eq 0 ]]; then
    err "No macOS network locations found"
    info "Create locations in System Settings → Network → Locations"
    exit 1
fi

for loc in "${LOCATIONS[@]}"; do
    if [[ "$loc" == "$ACTIVE_LOC" ]]; then
        ok "$loc  (current)"
    else
        ok "$loc"
    fi
done

# ── VPNHelper install state ───────────────────────────────────────────────────
VPNHELPER_APP="$ADDON_DIR/VPNHelper/VPNHelper.app"
VPNHELPER_INSTALLED=false

if [[ "$HAS_VPN" == true ]] && [[ -f "$VPNHELPER_APP/Contents/MacOS/VPNHelper" ]]; then
    VPNHELPER_INSTALLED=true
fi

# ── Per-location configuration ────────────────────────────────────────────────
declare -A LOC_FIREWALL LOC_STEALTH LOC_AIRDROP LOC_VPN LOC_TUNNEL LOC_KILLAPPS LOC_NOTIFY

# Per-location feature toggles
section "Location Features"
$GUM style --faint "Select features to enable for each location"

FEATURE_LIST=("Firewall" "Stealth mode" "AirDrop" "Notifications")
[[ "$HAS_VPN" == true ]] && FEATURE_LIST+=("VPN")

PREV_LOC=""

for loc in "${LOCATIONS[@]}"; do
    echo ""
    $GUM style --foreground 99 --bold --border normal --padding "0 1" --border-foreground 99 "Configure: $loc"
    echo ""
    drain_tty  # flush OSC background-color + cursor-position responses from border above

    if [[ -n "$PREV_LOC" ]]; then
        if $GUM confirm --default=no "Copy settings from '$PREV_LOC'?"; then
            LOC_FIREWALL[$loc]="${LOC_FIREWALL[$PREV_LOC]}"
            LOC_STEALTH[$loc]="${LOC_STEALTH[$PREV_LOC]}"
            LOC_AIRDROP[$loc]="${LOC_AIRDROP[$PREV_LOC]}"
            LOC_VPN[$loc]="${LOC_VPN[$PREV_LOC]}"
            LOC_TUNNEL[$loc]="${LOC_TUNNEL[$PREV_LOC]}"
            LOC_KILLAPPS[$loc]="${LOC_KILLAPPS[$PREV_LOC]}"
            LOC_NOTIFY[$loc]="${LOC_NOTIFY[$PREV_LOC]}"
            ok "Copied from $PREV_LOC"
            PREV_LOC="$loc"
            continue
        fi
        drain_tty  # flush OSC responses from confirm
    fi

    # Smart defaults: current/active location = home-like, others = away-like
    DEFAULTS=()
    if [[ "$loc" == "$ACTIVE_LOC" ]]; then
        DEFAULTS+=("AirDrop")
    else
        DEFAULTS+=("Firewall")
    fi
    DEFAULTS+=("Notifications")
    [[ "$HAS_VPN" == true && "$loc" != "$ACTIVE_LOC" ]] && DEFAULTS+=("VPN")

    DEFAULT_STR=$(IFS=','; echo "${DEFAULTS[*]}")

    SELECTED=$(choose_many "Features (↑↓ navigate, space select, enter confirm):" \
        --selected="$DEFAULT_STR" \
        "${FEATURE_LIST[@]}")

    LOC_FIREWALL[$loc]="off"
    LOC_STEALTH[$loc]="off"
    LOC_AIRDROP[$loc]="off"
    LOC_NOTIFY[$loc]="off"
    LOC_VPN[$loc]="off"
    LOC_TUNNEL[$loc]=""

    while IFS= read -r feature; do
        case "$feature" in
            "Firewall")      LOC_FIREWALL[$loc]="on" ;;
            "Stealth mode")  LOC_STEALTH[$loc]="on" ;;
            "AirDrop")       LOC_AIRDROP[$loc]="on" ;;
            "Notifications") LOC_NOTIFY[$loc]="on" ;;
            "VPN")           LOC_VPN[$loc]="on" ;;
        esac
    done <<< "$SELECTED"

    if [[ "${LOC_VPN[$loc]}" == "on" ]]; then
        echo ""
        LOC_TUNNEL[$loc]=$(choose_one "Select VPN tunnel for $loc:" "${VPN_TUNNELS[@]}")
    fi

    # Kill apps
    echo ""
    drain_tty
    $GUM style --foreground 212 "  Apps to quit on switch for $loc (comma-separated, or leave blank):" >/dev/tty
    IFS= read -r KILLAPPS </dev/tty
    LOC_KILLAPPS[$loc]="$KILLAPPS"

    PREV_LOC="$loc"
done

# ── Review ────────────────────────────────────────────────────────────────────
section "Review"
echo ""
printf "%-14s %-10s %-10s %-10s %-20s %-8s\n" \
    "Location" "Firewall" "Stealth" "AirDrop" "VPN" "Notify"
$GUM style --faint "$(printf '%.0s─' {1..76})"
for loc in "${LOCATIONS[@]}"; do
    vpn_info="off"
    [[ "${LOC_VPN[$loc]}" == "on" ]] && vpn_info="${LOC_TUNNEL[$loc]}"
    printf "%-14s %-10s %-10s %-10s %-20s %-8s\n" \
        "$loc" "${LOC_FIREWALL[$loc]}" "${LOC_STEALTH[$loc]}" \
        "${LOC_AIRDROP[$loc]}" "$vpn_info" "${LOC_NOTIFY[$loc]}"
done
echo ""

# ── Dry run ───────────────────────────────────────────────────────────────────
if $DRY_RUN; then
    section "Dry Run — Generated settings.conf"
    echo ""
    for loc in "${LOCATIONS[@]}"; do
        KEY=$(echo "$loc" | tr '[:lower:]' '[:upper:]' | tr ' ' '_')
        $GUM style --foreground 212 "# $loc"
        echo "${KEY}_firewall=${LOC_FIREWALL[$loc]}"
        echo "${KEY}_stealth_mode=${LOC_STEALTH[$loc]}"
        echo "${KEY}_airdrop=${LOC_AIRDROP[$loc]}"
        echo "${KEY}_wireguard=${LOC_VPN[$loc]}"
        echo "${KEY}_wireguard_tunnel=\"${LOC_TUNNEL[$loc]}\""
        echo "${KEY}_kill_apps=\"${LOC_KILLAPPS[$loc]}\""
        echo "${KEY}_notification=${LOC_NOTIFY[$loc]}"
        echo ""
    done
    info "Run without --dry-run to apply"
    exit 0
fi

if ! confirm "Proceed with installation?"; then
    echo "Aborted."
    exit 0
fi

# ── Generate settings.conf ────────────────────────────────────────────────────
section "Installing"
mkdir -p "$INSTALL_DIR"

{
echo "# Settings — generated by bootstrap.sh"
echo "# Edit this file to adjust toggles. Changes take effect on next location switch."
echo ""
for loc in "${LOCATIONS[@]}"; do
    KEY=$(echo "$loc" | tr '[:lower:]' '[:upper:]' | tr ' ' '_')
    echo "# ── $loc ──────────────────────────────────────────────────────────────────────"
    echo "${KEY}_firewall=${LOC_FIREWALL[$loc]}"
    echo "${KEY}_stealth_mode=${LOC_STEALTH[$loc]}"
    echo "${KEY}_airdrop=${LOC_AIRDROP[$loc]}"
    echo "${KEY}_wireguard=${LOC_VPN[$loc]}"
    echo "${KEY}_wireguard_tunnel=\"${LOC_TUNNEL[$loc]}\""
    echo "${KEY}_kill_apps=\"${LOC_KILLAPPS[$loc]}\""
    echo "${KEY}_notification=${LOC_NOTIFY[$loc]}"
    echo ""
done
} > "$INSTALL_DIR/settings.conf"
ok "settings.conf"

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
    echo "$SUDOERS_LINE" | sudo tee -a "$SUDOERS_FILE" > /dev/null
    sudo visudo -c -f "$SUDOERS_FILE"
    ok "Firewall sudoers rule added"
fi

# ── Register VPN services in all network locations ────────────────────────────
if [[ "$HAS_VPN" == true ]]; then
    SCUTIL_CMDS=$(python3 - <<'PYEOF'
import plistlib
with open("/Library/Preferences/SystemConfiguration/preferences.plist", "rb") as f:
    p = plistlib.load(f)
ns = p.get("NetworkServices", {})
vpn_uuids = [u for u, s in ns.items() if s.get("Interface", {}).get("Type") in ("VPN", "PPP")]
lines = []
for set_id, set_data in p.get("Sets", {}).items():
    svcs = set_data.get("Network", {}).get("Service", {})
    for uuid in vpn_uuids:
        if uuid not in svcs:
            lines.append(f"set /Sets/{set_id}/Network/Service/{uuid} /NetworkServices/{uuid}")
if lines:
    print("\n".join(lines))
    print("commit")
    print("apply")
    print("CHANGED")
PYEOF
)
    if [[ "$SCUTIL_CMDS" == *"CHANGED"* ]]; then
        echo "${SCUTIL_CMDS%CHANGED}" | sudo scutil --prefs
        ok "VPN services registered in all network locations"
    else
        ok "VPN services already registered in all network locations"
    fi
fi

# ── Build VPNHelper.app ───────────────────────────────────────────────────────
if [[ "$HAS_VPN" == true ]]; then
    if [[ "$VPNHELPER_INSTALLED" == true ]]; then
        ok "VPNHelper.app already built — skipping rebuild"
    else
        echo ""
        $GUM spin --spinner dot --title "Building VPNHelper.app..." -- bash -c "
            mkdir -p '$VPNHELPER_APP/Contents/MacOS' '$VPNHELPER_APP/Contents/Resources'
            cp '$ADDON_DIR/VPNHelper/Info.plist' '$VPNHELPER_APP/Contents/Info.plist'
            swiftc '$ADDON_DIR/VPNHelper/main.swift' -o '$VPNHELPER_APP/Contents/MacOS/VPNHelper' -framework Cocoa
            codesign --force --deep --sign - '$VPNHELPER_APP'
        "
        ok "VPNHelper.app built (ad-hoc signed)"
    fi

    # Always verify VPNHelper is running; if not, prompt to add to Login Items
    if pgrep -x VPNHelper &>/dev/null; then
        ok "VPNHelper is running"
    else
        echo ""
        $GUM style --foreground 214 --bold "One manual step required:"
        $GUM style "Add VPNHelper.app to Login Items so VPN switching works at login."
        echo ""
        $GUM style --faint "  Path: $VPNHELPER_APP"
        echo ""
        $GUM style --faint "Press Enter to open System Settings..." >/dev/tty
        drain_tty
        read -r </dev/tty
        open "x-apple.systempreferences:com.apple.LoginItems-Settings.extension"
        echo ""
        $GUM style --faint "Press Enter once VPNHelper.app is added to Login Items..." >/dev/tty
        drain_tty
        read -r </dev/tty
        ok "VPNHelper registered"
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
    "Setup complete!"
echo ""
$GUM style --bold "To adjust settings:"
$GUM style --faint "  Edit ~/.wifi-loc-control/settings.conf"
echo ""
$GUM style --bold "Logs:"
$GUM style --faint "  tail -f ~/Library/Logs/WiFiLocControl.log"
echo ""
