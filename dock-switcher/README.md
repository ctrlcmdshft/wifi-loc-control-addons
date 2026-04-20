# Dock Switcher

An addon for [wifi-loc-control](https://github.com/vborodulin/wifi-loc-control) that automatically applies security and network settings when your Mac switches network locations.

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
- Any VPN configured in **System Settings → VPN** _(optional — works with WireGuard, IKEv2, L2TP, etc.)_

## Installation

**One-line install:**

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/ctrlcmdshft/wifi-loc-control-addons/main/install.sh)"
```

**Or clone and run manually:**

```bash
git clone https://github.com/ctrlcmdshft/wifi-loc-control-addons.git
cd wifi-loc-control-addons/dock-switcher
chmod +x bootstrap.sh
./bootstrap.sh
```

The interactive installer will:
- Detect your macOS network locations
- Let you configure features per location
- Build and register `VPNHelper.app` (if VPN is needed)
- Guide you through adding it to Login Items (first install only)

Re-running `bootstrap.sh` updates your settings without rebuilding VPNHelper.

## Configuration

All configuration lives in `~/.wifi-loc-control/settings.conf`. Edit it directly — changes take effect on the next location switch.

```bash
HOME_firewall=off
HOME_stealth_mode=off
HOME_airdrop=on
HOME_wireguard=off
HOME_wireguard_tunnel=""
HOME_kill_apps=""
HOME_notification=on
```

The `wireguard_tunnel` value must match the tunnel name exactly as shown in **System Settings → VPN**.

### Adding a new location

1. Create the location in **System Settings → Network → Locations**
2. Re-run `bootstrap.sh` — it detects the new location and generates everything automatically

## How it works

```
Wi-Fi changes
    → wifi-loc-control detects SSID and switches macOS network location
    → runs ~/.wifi-loc-control/<Location>
    → apply.sh reads settings.conf and applies:
         firewall, stealth mode, AirDrop, kill apps, notification
         writes vpn-trigger file
    → VPNHelper.app (Login Item) sees the trigger
    → connects/disconnects VPN via scutil
```

## VPN Notes

VPN switching works with any VPN configured in **System Settings → VPN** — WireGuard, IKEv2, L2TP, etc.

VPN switching uses a small background app (`VPNHelper.app`) built from source during setup. It runs at login with no dock icon or menu bar. It watches for changes to the trigger file written by `apply.sh` and calls `scutil --nc start/stop`, which has the proper macOS session access needed to control Network Extensions.

The installer registers all detected VPN services across every network location so switching works regardless of which location is active.

## Logs

```bash
tail -f ~/Library/Logs/WiFiLocControl.log
```

## Uninstall

```bash
cd wifi-loc-control-addons/dock-switcher
chmod +x uninstall.sh
./uninstall.sh
```
