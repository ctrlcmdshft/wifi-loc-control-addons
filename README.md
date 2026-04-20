# wifi-loc-control Addons

A collection of addons for [wifi-loc-control](https://github.com/vborodulin/wifi-loc-control) — each one extends what happens when your Mac switches network locations.

## Addons

| Addon | Description |
|-------|-------------|
| [loc-guard](./loc-guard) | Switch firewall, stealth mode, AirDrop, VPN, and more per location |

## Quick Install

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/ctrlcmdshft/wifi-loc-control-addons/main/install.sh)"
```

Or clone and run manually:

```bash
git clone https://github.com/ctrlcmdshft/wifi-loc-control-addons.git
cd wifi-loc-control-addons/<addon-name>
chmod +x bootstrap.sh
./bootstrap.sh
```

## Requirements

- macOS 14+
- [wifi-loc-control](https://github.com/vborodulin/wifi-loc-control) installed
