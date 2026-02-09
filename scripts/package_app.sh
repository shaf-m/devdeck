#!/bin/bash
set -e

# Ensure we are in the project root
cd "$(dirname "$0")/.."

# Build the app first
./scripts/build_app.sh

APP_NAME="DevDeck"
APP_BUNDLE="${APP_NAME}.app"
DMG_NAME="${APP_NAME}.dmg"
VOL_NAME="${APP_NAME}"

# Remove existing DMG
rm -f "${DMG_NAME}"

# Create a temporary directory for DMG contents
mkdir -p dist
cp -r "${APP_BUNDLE}" dist/
ln -s /Applications dist/Applications

# Create DMG
echo "Creating DMG..."
hdiutil create -volname "${VOL_NAME}" -srcfolder dist -ov -format UDZO "${DMG_NAME}"

# Clean up
rm -rf dist

echo "Done! DMG created at ./${DMG_NAME}"
