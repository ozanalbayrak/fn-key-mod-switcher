#!/usr/bin/env bash
# Builds FnSwitcher.app into ./build. Pass --install to copy it to /Applications.
#
# Uses xcodebuild rather than `swift build` because SwiftPM's generated
# resource-bundle accessor only looks for the KeyboardShortcuts bundle at
# Bundle.main.bundleURL (the .app root, which codesign rejects) or the
# absolute .build path — never Contents/Resources. xcodebuild's generated
# accessor checks Bundle.main.resourceURL first, which matches where we
# actually place the bundle below.
set -euo pipefail
cd "$(dirname "$0")/.."

DERIVED_DATA="build/DerivedData"
PRODUCTS="$DERIVED_DATA/Build/Products/Release"

xcodebuild -scheme FnSwitcher -configuration Release \
    -destination 'platform=macOS' -derivedDataPath "$DERIVED_DATA" \
    -quiet build

APP="build/FnSwitcher.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$PRODUCTS/FnSwitcher" "$APP/Contents/MacOS/"
cp Resources/Info.plist "$APP/Contents/"

# SwiftPM resource bundles (KeyboardShortcuts localizations).
for bundle in "$PRODUCTS"/*.bundle; do
    [ -e "$bundle" ] && cp -R "$bundle" "$APP/Contents/Resources/"
done

codesign --force --sign - "$APP"
echo "Built $APP"

if [[ "${1:-}" == "--install" ]]; then
    rm -rf /Applications/FnSwitcher.app
    cp -R "$APP" /Applications/
    rm -rf "$APP"
    echo "Installed /Applications/FnSwitcher.app"
fi
