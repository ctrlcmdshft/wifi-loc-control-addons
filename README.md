# wifi-loc-control Addons

A collection of addons for [wifi-loc-control](https://github.com/vborodulin/wifi-loc-control) — each one extends what happens when your Mac switches network locations.

## Addons

| Addon | Description |
|-------|-------------|
| [dock-switcher](./dock-switcher) | Switch dock layouts, firewall, stealth mode, AirDrop, and VPN per location |

## Usage

Each addon is self-contained with its own `bootstrap.sh`:

```bash
git clone https://github.com/ctrlcmdshft/wifi-loc-control-addons.git
cd wifi-loc-control-addons/<addon-name>
chmod +x bootstrap.sh
./bootstrap.sh
```

## Requirements

- macOS 14+
- [wifi-loc-control](https://github.com/vborodulin/wifi-loc-control) installed
