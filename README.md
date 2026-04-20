# wifi-loc-control Addons

A collection of addons for [wifi-loc-control](https://github.com/vborodulin/wifi-loc-control) — each one extends what happens when your Mac switches network locations.

## Addons

| Addon | Description |
|-------|-------------|
| [loc-guard](./loc-guard) | Switch firewall, stealth mode, AirDrop, VPN, and more per location |
| [loc-wallpaper](./loc-wallpaper) | Switch desktop wallpaper per location |
| [loc-audio](./loc-audio) | Switch audio output device and volume per location |

## Quick Install

**loc-guard** (install this first):
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/ctrlcmdshft/wifi-loc-control-addons/main/install.sh)"
```

**loc-wallpaper:**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/ctrlcmdshft/wifi-loc-control-addons/main/install.sh)" -- loc-wallpaper
```

**loc-audio:**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/ctrlcmdshft/wifi-loc-control-addons/main/install.sh)" -- loc-audio
```

## Requirements

- macOS 14+
- [wifi-loc-control](https://github.com/vborodulin/wifi-loc-control) installed
