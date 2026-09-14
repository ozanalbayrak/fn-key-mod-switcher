#!/usr/bin/env bash
# Builds FnSwitcher.app into ./build.
#
#   scripts/build.sh            build only
#   scripts/build.sh --install  also copy to /Applications
#   scripts/build.sh --zip      also produce build/FnSwitcher-<version>.zip
#
# Environment:
#   VERSION       CFBundleShortVersionString (default: 0.0.0-dev)
#   BUILD_NUMBER  CFBundleVersion            (default: 1)
#
# Uses xcodebuild rather than `swift build` because SwiftPM's generated
# resource-bundle accessor only looks for the KeyboardShortcuts bundle at
# Bundle.main.bundleURL (the .app root, which codesign rejects) or the
# absolute .build path — never Contents/Resources. xcodebuild's generated
# accessor checks Bundle.main.resourceURL first, which matches where we
# actually place the bundle below.
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${VERSION:-0.0.0-dev}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
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
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" \
                        -c "Set :CFBundleVersion $BUILD_NUMBER" \
                        "$APP/Contents/Info.plist"

# SwiftPM resource bundles (our menu bar PDFs, KeyboardShortcuts localizations).
for bundle in "$PRODUCTS"/*.bundle; do
    [ -e "$bundle" ] && cp -R "$bundle" "$APP/Contents/Resources/"
done

# App icon: the iconset PNGs are the committed source; iconutil ships with macOS.
iconutil -c icns Resources/AppIcon.iconset -o "$APP/Contents/Resources/AppIcon.icns"

codesign --force --sign - "$APP"
echo "Built $APP ($VERSION, build $BUILD_NUMBER)"

case "${1:-}" in
    --install)
        rm -rf /Applications/FnSwitcher.app
        cp -R "$APP" /Applications/
        rm -rf "$APP"
        echo "Installed /Applications/FnSwitcher.app"
        ;;
    --zip)
        # ditto keeps the bundle structure, symlinks and extended attributes intact,
        # which a plain `zip -r` does not.
        ZIP="build/FnSwitcher-$VERSION.zip"
        rm -f "$ZIP"
        ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"
        echo "Zipped $ZIP"
        ;;
    "")
        ;;
    *)
        echo "Unknown option: $1" >&2
        exit 2
        ;;
esac
