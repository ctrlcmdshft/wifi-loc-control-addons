# wifi-loc-control Addons

Addons for [wifi-loc-control](https://github.com/vborodulin/wifi-loc-control) — automatically apply per-location settings when your Mac switches networks.

## Addons

| Addon | What it does |
|-------|-------------|
| [loc-guard](./loc-guard) | Firewall, stealth mode, AirDrop, VPN |
| [loc-wallpaper](./loc-wallpaper) | Desktop wallpaper |
| [loc-audio](./loc-audio) | Audio output device and volume |

Install any addon on its own — no specific order required.

## Install

```bash
# loc-guard
curl -fsSL https://raw.githubusercontent.com/ctrlcmdshft/wifi-loc-control-addons/main/install.sh | bash

# loc-wallpaper
curl -fsSL https://raw.githubusercontent.com/ctrlcmdshft/wifi-loc-control-addons/main/install.sh | bash -s loc-wallpaper

# loc-audio
curl -fsSL https://raw.githubusercontent.com/ctrlcmdshft/wifi-loc-control-addons/main/install.sh | bash -s loc-audio
```

## Requirements

- macOS 14+
- [wifi-loc-control](https://github.com/vborodulin/wifi-loc-control) installed
