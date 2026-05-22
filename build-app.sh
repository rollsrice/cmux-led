#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="cmux-led"
BUNDLE_ID="com.thirdintelligence.cmux-led"
VERSION="${VERSION:-0.1.0}"
BUILD_DIR="build"
APP_PATH="$BUILD_DIR/$APP_NAME.app"
ZIP_PATH="$BUILD_DIR/$APP_NAME.zip"

echo "==> swift build (release)"
swift build -c release

echo "==> assembling app bundle"
rm -rf "$APP_PATH" "$ZIP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS" "$APP_PATH/Contents/Resources"
cp ".build/release/$APP_NAME" "$APP_PATH/Contents/MacOS/$APP_NAME"
chmod +x "$APP_PATH/Contents/MacOS/$APP_NAME"

echo "==> generating icon"
ICONSET_DIR="$BUILD_DIR/AppIcon.iconset"
rm -rf "$ICONSET_DIR"
swift tools/make-icon.swift "$ICONSET_DIR"
iconutil -c icns "$ICONSET_DIR" -o "$BUILD_DIR/AppIcon.icns"
cp "$BUILD_DIR/AppIcon.icns" "$APP_PATH/Contents/Resources/AppIcon.icns"

cat > "$APP_PATH/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>$APP_NAME</string>
  <key>CFBundleDisplayName</key><string>cmux LED</string>
  <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleExecutable</key><string>$APP_NAME</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

echo "==> ad-hoc codesign"
codesign --force --deep --sign - "$APP_PATH"

echo "==> zipping"
( cd "$BUILD_DIR" && ditto -c -k --keepParent "$APP_NAME.app" "$APP_NAME.zip" )

SHA=$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')
echo
echo "artifact: $ZIP_PATH"
echo "sha256:   $SHA"
echo "version:  $VERSION"
