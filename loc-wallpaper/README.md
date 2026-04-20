# Loc Wallpaper

An addon for [wifi-loc-control](https://github.com/vborodulin/wifi-loc-control) that automatically switches your desktop wallpaper when your Mac changes network location.

## Requirements

- macOS 14+
- [wifi-loc-control](https://github.com/vborodulin/wifi-loc-control) installed
- [loc-guard](../loc-guard) installed first (provides the hook dispatcher)

## Installation

```bash
git clone https://github.com/ctrlcmdshft/wifi-loc-control-addons.git
cd wifi-loc-control-addons/loc-wallpaper
chmod +x bootstrap.sh
./bootstrap.sh
```

The installer will open a native macOS file picker for each location. Cancel to skip a location.

## Configuration

Settings are stored in `~/.wifi-loc-control/wallpaper.conf`:

```bash
HOME_wallpaper="/Users/you/Pictures/home.jpg"
WORK_wallpaper="/Users/you/Pictures/work.jpg"
REMOTE_wallpaper=""
```

Leave a value empty to skip wallpaper switching for that location.

## Uninstall

```bash
cd wifi-loc-control-addons/loc-wallpaper
chmod +x uninstall.sh
./uninstall.sh
```
