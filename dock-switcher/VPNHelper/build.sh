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

# Detect best available signing identity
IDENTITY=$(security find-identity -v -p codesigning 2>/dev/null | grep -o '"[^"]*"' | head -1 | tr -d '"')
if [[ -n "$IDENTITY" ]]; then
    echo "Signing with: $IDENTITY"
    codesign --force --deep --sign "$IDENTITY" "$APP"
else
    echo "No developer certificate found — using ad-hoc signing"
    codesign --force --deep --sign - "$APP"
fi

echo "Built and signed: $APP"
echo ""
echo "Next: Add VPNHelper.app to Login Items:"
echo "  System Settings → General → Login Items & Extensions → +"
echo "  Select: $APP"
