#!/usr/bin/env bash
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

LOCATION="$1"
CONFIG="$HOME/.wifi-loc-control/display.conf"
[[ -f "$CONFIG" ]] || exit 0
source "$CONFIG"

KEY=$(echo "$LOCATION" | tr '[:lower:]' '[:upper:]' | tr ' ' '_')
_v="${KEY}_brightness"; brightness="${!_v}"
_v="${KEY}_night_shift"; night_shift="${!_v}"

if [[ -n "$brightness" ]] && command -v brightness &>/dev/null; then
    level=$(echo "scale=2; $brightness / 100" | bc)
    brightness "$level" 2>/dev/null || true
fi

if [[ -n "$night_shift" ]]; then
    if [[ "$night_shift" == "on" ]]; then
        osascript -e 'tell application "System Events" to tell appearance preferences to set night shift enabled to true' 2>/dev/null || true
    else
        osascript -e 'tell application "System Events" to tell appearance preferences to set night shift enabled to false' 2>/dev/null || true
    fi
fi
