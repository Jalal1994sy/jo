
#!/bin/bash

# ============================================
# iOS IPA Build Script — Jouw Driver
# ============================================
# Usage: bash capacitor-ios-build.sh
# Requires: macOS + Xcode 15+

set -e

echo "========================================"
echo "  Jouw Driver — iOS Build"
echo "========================================"

# Check macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
  echo "ERROR: iOS builds require macOS."
  exit 1
fi

# Check Xcode
if ! command -v xcodebuild &> /dev/null; then
  echo "ERROR: Xcode not found. Install from App Store."
  exit 1
fi

# Check CocoaPods
if ! command -v pod &> /dev/null; then
  echo "CocoaPods not found. Installing..."
  sudo gem install cocoapods
fi

# Step 1: Sync Capacitor (server mode — no static export needed)
echo ""
echo "[1/3] Syncing Capacitor assets..."
npx cap sync ios

# Step 2: Install CocoaPods
echo ""
echo "[2/3] Installing CocoaPods dependencies..."
cd ios/App
pod install
cd ../..

# Step 3: Open Xcode
echo ""
echo "[3/3] Opening Xcode..."
npx cap open ios

echo ""
echo "========================================"
echo "  Xcode is now open."
echo ""
echo "  To build IPA:"
echo "  1. Select 'Any iOS Device (arm64)' as target"
echo "  2. Product > Archive"
echo "  3. Window > Organizer"
echo "  4. Click 'Distribute App'"
echo "  5. Choose: App Store Connect OR Ad Hoc"
echo "  6. Export IPA"
echo ""
echo "  Bundle ID: com.jouwdriver.app"
echo "  App Name: Jouw Driver"
echo "========================================"
