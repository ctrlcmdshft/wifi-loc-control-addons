#!/usr/bin/env bash
set -e

REPO="https://github.com/ctrlcmdshft/wifi-loc-control-addons.git"
DEST="$HOME/wifi-loc-control-addons"

if [[ -d "$DEST/.git" ]]; then
    echo "Updating existing install..."
    git -C "$DEST" pull --quiet
else
    echo "Cloning wifi-loc-control-addons..."
    git clone --quiet "$REPO" "$DEST"
fi

exec "$DEST/dock-switcher/bootstrap.sh" "$@"
