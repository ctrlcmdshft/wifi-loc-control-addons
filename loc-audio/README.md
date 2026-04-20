# Loc Audio

An addon for [wifi-loc-control](https://github.com/vborodulin/wifi-loc-control) that automatically switches your audio output device and volume when your Mac changes network location.

## Features

- Switch default audio output device (e.g. speakers at home, headphones at work)
- Set volume level per location (0–100, or skip to leave unchanged)

## Requirements

- macOS 14+
- [wifi-loc-control](https://github.com/vborodulin/wifi-loc-control) installed
- [loc-guard](../loc-guard) installed first (provides the hook dispatcher)
- [SwitchAudioSource](https://github.com/deweller/switchaudio-osx) — installed automatically if needed

## Installation

```bash
git clone https://github.com/ctrlcmdshft/wifi-loc-control-addons.git
cd wifi-loc-control-addons/loc-audio
chmod +x bootstrap.sh
./bootstrap.sh
```

The installer lists your available output devices and lets you pick one per location, then choose a volume level.

## Configuration

Settings are stored in `~/.wifi-loc-control/audio.conf`:

```bash
HOME_device="MacBook Pro Speakers"
HOME_volume="50"
WORK_device="AirPods Pro"
WORK_volume="40"
REMOTE_device=""
REMOTE_volume="25"
```

Leave `_device` empty to skip device switching for that location. Leave `_volume` empty to leave volume unchanged.

## Uninstall

```bash
cd wifi-loc-control-addons/loc-audio
chmod +x uninstall.sh
./uninstall.sh
```
