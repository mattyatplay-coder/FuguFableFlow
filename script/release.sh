#!/usr/bin/env bash
# Build a distributable, versioned, universal (arm64+x86_64) release .app and zip it.
# Usage: script/release.sh [version]   (default 0.1.0)
set -euo pipefail

VERSION="${1:-0.1.0}"
APP_NAME="FuguFableFlow"
EXECUTABLE_NAME="FuguFableFlow"
BUNDLE_ID="app.fugufableflow"
MIN_SYSTEM_VERSION="14.0"
SIGN_IDENTITY="${FUGUFABLEFLOW_CODESIGN_IDENTITY:-}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$EXECUTABLE_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
ZIP_PATH="$DIST_DIR/$APP_NAME-$VERSION.zip"

if [[ -z "$SIGN_IDENTITY" ]]; then
  SIGN_IDENTITY="$(/usr/bin/security find-identity -v -p codesigning 2>/dev/null | /usr/bin/awk -F '"' '/"/ { print $2; exit }')"
fi
SIGN_IDENTITY="${SIGN_IDENTITY:--}"

echo "==> Building universal release binary (arm64 + x86_64)"
swift build -c release --arch arm64 --arch x86_64 --package-path "$ROOT_DIR"
BUILD_BINARY="$(swift build -c release --arch arm64 --arch x86_64 --package-path "$ROOT_DIR" --show-bin-path)/$EXECUTABLE_NAME"

echo "==> Assembling $APP_NAME.app (v$VERSION)"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"
cp "$ROOT_DIR/Resources/FuguFableFlow.icns" "$APP_RESOURCES/FuguFableFlow.icns"
cp "$ROOT_DIR/Resources/FuguFableFlow.png" "$APP_RESOURCES/FuguFableFlow.png"

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$EXECUTABLE_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleIconFile</key>
  <string>FuguFableFlow.icns</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleVersion</key>
  <string>$VERSION</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSAppleEventsUsageDescription</key>
  <string>FuguFableFlow can paste dictated text into the active app.</string>
  <key>NSHumanReadableCopyright</key>
  <string>Licensed under Apache 2.0.</string>
  <key>NSMicrophoneUsageDescription</key>
  <string>FuguFableFlow needs microphone access to capture dictation.</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
  <key>NSSpeechRecognitionUsageDescription</key>
  <string>FuguFableFlow uses speech recognition to turn dictation into text.</string>
</dict>
</plist>
PLIST

echo "==> Signing (identity: $SIGN_IDENTITY)"
/usr/bin/codesign --force --deep --sign "$SIGN_IDENTITY" "$APP_BUNDLE"

echo "==> Zipping -> $ZIP_PATH"
rm -f "$ZIP_PATH"
/usr/bin/ditto -c -k --keepParent "$APP_BUNDLE" "$ZIP_PATH"

echo "==> Done: $ZIP_PATH"
lipo -info "$APP_BINARY"
