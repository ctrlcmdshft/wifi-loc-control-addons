#!/usr/bin/env bash

INSTALL_DIR="$HOME/.wifi-loc-control"

echo "Uninstalling Loc Guard addon..."

rm -f "$INSTALL_DIR/apply.sh"
rm -f "$INSTALL_DIR/vpn-trigger"
for location in Home Work Remote Automatic; do
    rm -f "$INSTALL_DIR/$location"
done

echo "✓ Scripts removed"
echo ""
echo "Manual steps remaining:"
echo "  1. Remove VPNHelper.app from Login Items:"
echo "     System Settings → General → Login Items & Extensions"
echo "  2. Optionally remove settings.conf: rm ~/.wifi-loc-control/settings.conf"
echo "  3. Optionally remove sudoers entry for socketfilterfw:"
echo "     sudo visudo -f /etc/sudoers.d/wifi-loc-control"
