#!/usr/bin/env bash
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

LOCATION="$1"
CONFIG="$HOME/.wifi-loc-control/audio.conf"
[[ -f "$CONFIG" ]] || exit 0
source "$CONFIG"

KEY=$(echo "$LOCATION" | tr '[:lower:]' '[:upper:]' | tr ' ' '_')
_v="${KEY}_device"; device="${!_v}"
_v="${KEY}_volume"; volume="${!_v}"

if [[ -n "$device" ]] && command -v SwitchAudioSource &>/dev/null; then
    SwitchAudioSource -s "$device" 2>/dev/null || true
fi

if [[ -n "$volume" ]]; then
    osascript -e "set volume output volume $volume" 2>/dev/null || true
fi
