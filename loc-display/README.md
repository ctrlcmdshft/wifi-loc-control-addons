# Loc Display

An addon for [wifi-loc-control](https://github.com/vborodulin/wifi-loc-control) that automatically adjusts your display brightness and Night Shift when your Mac changes network location.

## Features

- Set screen brightness per location (0–100, or skip to leave unchanged)
- Enable or disable Night Shift per location

## Requirements

- macOS 14+
- [wifi-loc-control](https://github.com/vborodulin/wifi-loc-control) installed
- Install in any order — each addon sets up what it needs automatically
- [brightness](https://github.com/nriley/brightness) — installed automatically if needed

## Installation

**One-line install:**
```bash
curl -fsSL https://raw.githubusercontent.com/ctrlcmdshft/wifi-loc-control-addons/main/install.sh | bash -s loc-display
```

**Or clone and run manually:**
```bash
git clone https://github.com/ctrlcmdshft/wifi-loc-control-addons.git
cd wifi-loc-control-addons/loc-display
chmod +x bootstrap.sh
./bootstrap.sh
```

## Configuration

Settings are stored in `~/.wifi-loc-control/display.conf`:

```bash
HOME_brightness="75"
HOME_night_shift="off"
WORK_brightness="100"
WORK_night_shift="off"
REMOTE_brightness="50"
REMOTE_night_shift="on"
```

Leave `_brightness` empty to skip brightness control for that location. Leave `_night_shift` empty to leave Night Shift unchanged.

## Uninstall

```bash
cd wifi-loc-control-addons/loc-display
chmod +x uninstall.sh
./uninstall.sh
```
