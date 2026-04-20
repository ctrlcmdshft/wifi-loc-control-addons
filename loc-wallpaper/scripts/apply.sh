#!/usr/bin/env bash
LOCATION="$1"
CONFIG="$HOME/.wifi-loc-control/wallpaper.conf"
[[ -f "$CONFIG" ]] || exit 0
source "$CONFIG"
KEY=$(echo "$LOCATION" | tr '[:lower:]' '[:upper:]' | tr ' ' '_')
_v="${KEY}_wallpaper"
wallpaper="${!_v}"
[[ -n "$wallpaper" && -f "$wallpaper" ]] || exit 0
osascript -e "tell application \"System Events\" to set picture of every desktop to POSIX file \"$wallpaper\""
