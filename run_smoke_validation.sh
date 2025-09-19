#!/bin/zsh
set -euo pipefail

SCHEME="Septica"
PROJECT="Septica.xcodeproj"
DESTINATION="platform=iOS Simulator,name=iPhone 16 Pro"
DERIVED_DATA="DerivedData/SmokeBuild"
APP_BUNDLE_ID="dev.leanvibe.game.Septica"
SIM_NAME="iPhone 16 Pro"
TIMESTAMP=$(date +%Y%m%d%H%M%S)
SCREENSHOT_DIR="performance_screenshots/smoke"
SCREENSHOT_PATH="$SCREENSHOT_DIR/smoke_${TIMESTAMP}.png"

mkdir -p "$SCREENSHOT_DIR"

echo "🔨 Building $SCHEME for $DESTINATION"
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Debug -destination "$DESTINATION" -derivedDataPath "$DERIVED_DATA" build

APP_PATH="$DERIVED_DATA/Build/Products/Debug-iphonesimulator/Septica.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "❌ Failed to locate built app at $APP_PATH" >&2
  exit 1
fi

echo "📱 Booting simulator $SIM_NAME if needed"
xcrun simctl boot "$SIM_NAME" 2>/dev/null || true

# Ensure app is not running
xcrun simctl terminate "$SIM_NAME" "$APP_BUNDLE_ID" 2>/dev/null || true

echo "📦 Installing build"
xcrun simctl install "$SIM_NAME" "$APP_PATH"

echo "🚀 Launching app"
xcrun simctl launch "$SIM_NAME" "$APP_BUNDLE_ID"

sleep 5

echo "📸 Capturing screenshot -> $SCREENSHOT_PATH"
xcrun simctl io "$SIM_NAME" screenshot "$SCREENSHOT_PATH"

echo "✅ Smoke validation complete"
