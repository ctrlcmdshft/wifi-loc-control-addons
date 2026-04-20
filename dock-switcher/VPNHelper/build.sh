#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP="$SCRIPT_DIR/VPNHelper.app"

echo "Building VPNHelper.app..."

mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$SCRIPT_DIR/Info.plist" "$APP/Contents/Info.plist"

swiftc "$SCRIPT_DIR/main.swift" \
    -o "$APP/Contents/MacOS/VPNHelper" \
    -framework Cocoa

codesign --force --deep --sign - "$APP"

echo "Built and signed: $APP"
echo ""
echo "Next: Add VPNHelper.app to Login Items:"
echo "  System Settings → General → Login Items & Extensions → +"
echo "  Select: $APP"
