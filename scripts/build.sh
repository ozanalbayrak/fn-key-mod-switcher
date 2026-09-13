#!/usr/bin/env bash
# Builds FnSwitcher.app into ./build. Pass --install to copy it to /Applications.
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release

APP="build/FnSwitcher.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/FnSwitcher "$APP/Contents/MacOS/"
cp Resources/Info.plist "$APP/Contents/"

# SwiftPM resource bundles (KeyboardShortcuts localizations).
for bundle in .build/release/*.bundle; do
    [ -e "$bundle" ] && cp -R "$bundle" "$APP/Contents/Resources/"
done

codesign --force --sign - "$APP"
echo "Built $APP"

if [[ "${1:-}" == "--install" ]]; then
    rm -rf /Applications/FnSwitcher.app
    cp -R "$APP" /Applications/
    echo "Installed /Applications/FnSwitcher.app"
fi
