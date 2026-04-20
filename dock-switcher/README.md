# Dock Switcher

An addon for [wifi-loc-control](https://github.com/vborodulin/wifi-loc-control) that automatically switches your Mac's dock layout and system settings when your network location changes.

## Features

| Feature | Description |
|---------|-------------|
| **Dock** | Switches DockFlow presets per location |
| **Firewall** | Enables/disables macOS firewall |
| **Stealth Mode** | Hides your Mac from network probes |
| **AirDrop** | Enables/disables AirDrop |
| **VPN** | Connects/disconnects a WireGuard VPN profile |
| **Kill Apps** | Quits specified apps on location change |
| **Notifications** | Shows a summary banner on each switch |

## Requirements

- macOS 14+
- [wifi-loc-control](https://github.com/vborodulin/wifi-loc-control) installed
- [DockFlow](https://dockflow.app) _(optional — for dock switching)_
- Any VPN configured in **System Settings → VPN** _(optional — for VPN switching. Works with WireGuard, ProtonVPN, OpenVPN, L2TP, etc.)_
- `terminal-notifier` — installed automatically by bootstrap

## Installation

```bash
git clone https://github.com/ctrlcmdshft/wifi-loc-control-addons.git
cd wifi-loc-control-addons/dock-switcher
chmod +x bootstrap.sh
./bootstrap.sh
```

Then:
1. Edit `~/.wifi-loc-control/settings.conf` to match your locations and preferences
2. Add `VPNHelper.app` to Login Items: **System Settings → General → Login Items → +**

## Configuration

All configuration lives in `~/.wifi-loc-control/settings.conf`. Toggle features on/off per location — no script editing required.

```bash
# Change the VPN tunnel (must match name in System Settings → VPN)
WIREGUARD_TUNNEL="US-NJ-67"

# Per-location toggles
HOME_dockflow=on
HOME_dockflow_preset="Home"
HOME_firewall=off
HOME_stealth_mode=off
HOME_airdrop=on
HOME_wireguard=off
HOME_kill_apps=""
HOME_notification=on
```

### Adding a new location

1. Add your location's settings block to `settings.conf`:
```bash
CAFE_dockflow=on
CAFE_dockflow_preset="Minimal"
CAFE_firewall=on
CAFE_stealth_mode=on
CAFE_airdrop=off
CAFE_wireguard=on
CAFE_kill_apps=""
CAFE_notification=on
```

2. Create a location script in `~/.wifi-loc-control/`:
```bash
cat > ~/.wifi-loc-control/Cafe << 'EOF'
#!/usr/bin/env bash
exec 2>&1
"$(dirname "$0")/apply.sh" "Cafe"
EOF
chmod +x ~/.wifi-loc-control/Cafe
```

## How it works

```
Wi-Fi changes
    → wifi-loc-control switches macOS network location
    → runs ~/.wifi-loc-control/<Location>
    → apply.sh reads settings.conf and applies:
         DockFlow preset, firewall, stealth, AirDrop, kill apps, notification
         writes vpn-trigger file
    → VPNHelper.app (Login Item) sees trigger
    → connects/disconnects WireGuard VPN silently
```

## VPN Notes

VPN switching works with any VPN configured in **System Settings → VPN** — WireGuard, ProtonVPN, L2TP, IKEv2, etc. Set `WIREGUARD_TUNNEL` in `settings.conf` to the exact name shown in System Settings.

VPN switching uses a tiny invisible Login Item (`VPNHelper.app`) built from source during setup. It runs in the background at login with no dock icon, menu bar icon, or any UI. It watches for the trigger file written by `apply.sh` and calls `scutil --nc start/stop` with the proper macOS session access needed for Network Extensions.

## Uninstall

```bash
cd wifi-loc-control-addons/dock-switcher
chmod +x uninstall.sh
./uninstall.sh
```
