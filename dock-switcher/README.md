# Dock Switcher

An addon for [wifi-loc-control](https://github.com/vborodulin/wifi-loc-control) that automatically switches your Mac's dock layout and system settings when your network location changes.

## Features

| Feature | Description |
|---------|-------------|
| **Firewall** | Enables/disables macOS firewall |
| **Stealth Mode** | Hides your Mac from network probes |
| **AirDrop** | Enables/disables AirDrop |
| **VPN** | Connects/disconnects a VPN profile |
| **Kill Apps** | Quits specified apps on location change |
| **Notifications** | Shows a summary banner on each switch |

## Requirements

- macOS 14+
- [wifi-loc-control](https://github.com/vborodulin/wifi-loc-control) installed
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
# Per-location toggles
HOME_firewall=off
HOME_stealth_mode=off
HOME_airdrop=on
HOME_wireguard=off
HOME_wireguard_tunnel=""
HOME_kill_apps=""
HOME_notification=on
```

### Adding a new location

1. Add a location in **System Settings → Network → Locations** then re-run `bootstrap.sh` — it will detect the new location and generate everything automatically.

2. Or add the settings block manually to `settings.conf` and create the location script:
```bash
CAFE_firewall=on
CAFE_stealth_mode=on
CAFE_airdrop=off
CAFE_wireguard=on
CAFE_wireguard_tunnel="MY-TUNNEL"
CAFE_kill_apps=""
CAFE_notification=on
```

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
