# Loc Wallpaper

An addon for [wifi-loc-control](https://github.com/vborodulin/wifi-loc-control) that automatically switches your desktop wallpaper when your Mac changes network location.

## Requirements

- macOS 14+
- [wifi-loc-control](https://github.com/vborodulin/wifi-loc-control) installed
- Install in any order — each addon sets up what it needs automatically

## Installation

**One-line install:**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/ctrlcmdshft/wifi-loc-control-addons/main/install.sh)" -- loc-wallpaper
```

**Or clone and run manually:**
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
