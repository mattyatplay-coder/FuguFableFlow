#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="${FUGUFABLEFLOW_APP_NAME:-FuguFableFlow}"
EXECUTABLE_NAME="FuguFableFlow"
BUNDLE_ID="${FUGUFABLEFLOW_BUNDLE_ID:-app.fugufableflow}"
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
ICON_FILE="FuguFableFlow.icns"
MENU_BAR_ICON_FILE="FuguFableFlow.png"
INSTALLED_APP="/Applications/$APP_NAME.app"

if [[ -z "$SIGN_IDENTITY" ]]; then
  SIGN_IDENTITY="$(/usr/bin/security find-identity -v -p codesigning 2>/dev/null | /usr/bin/awk -F '"' '/"/ { print $2; exit }')"
fi
SIGN_IDENTITY="${SIGN_IDENTITY:--}"

pkill -x "$EXECUTABLE_NAME" >/dev/null 2>&1 || true
pkill -x "PersonalFlow" >/dev/null 2>&1 || true

swift build --package-path "$ROOT_DIR"
BUILD_BINARY="$(swift build --package-path "$ROOT_DIR" --show-bin-path)/$EXECUTABLE_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"
cp "$ROOT_DIR/Resources/$ICON_FILE" "$APP_RESOURCES/$ICON_FILE"
cp "$ROOT_DIR/Resources/$MENU_BAR_ICON_FILE" "$APP_RESOURCES/$MENU_BAR_ICON_FILE"

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
  <string>$ICON_FILE</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSAppleEventsUsageDescription</key>
  <string>FuguFableFlow can paste dictated text into the active app.</string>
  <key>NSAppTransportSecurity</key>
  <dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
  </dict>
  <key>NSHumanReadableCopyright</key>
  <string>Personal use build.</string>
  <key>NSMicrophoneUsageDescription</key>
  <string>FuguFableFlow needs microphone access to capture dictation.</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
  <key>NSSpeechRecognitionUsageDescription</key>
  <string>FuguFableFlow uses speech recognition to turn dictation into text.</string>
</dict>
</plist>
PLIST

if [[ "$SIGN_IDENTITY" != "-" ]]; then
  /usr/bin/codesign --force --deep --sign "$SIGN_IDENTITY" "$APP_BUNDLE"
else
  /usr/bin/codesign --force --deep --sign - "$APP_BUNDLE"
fi

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

install_app() {
  rm -rf "$INSTALLED_APP"
  /usr/bin/ditto "$APP_BUNDLE" "$INSTALLED_APP"
  /usr/bin/xattr -dr com.apple.quarantine "$INSTALLED_APP" >/dev/null 2>&1 || true
  /usr/bin/open -n "$INSTALLED_APP"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$EXECUTABLE_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 1
    pgrep -x "$EXECUTABLE_NAME" >/dev/null
    ;;
  --install|install)
    install_app
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify|--install]" >&2
    exit 2
    ;;
esac
