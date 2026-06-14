
#!/bin/bash

# ============================================
# Android APK/AAB Build Script — Jouw Driver
# ============================================
# Usage: bash capacitor-build.sh [debug|release|aab]
# Default: debug

set -e

BUILD_TYPE=${1:-debug}
APP_NAME="JouwDriver"

echo "========================================"
echo "  Jouw Driver — Android Build"
echo "  Type: $BUILD_TYPE"
echo "========================================"

# Step 1: Sync Capacitor (server mode — no static export needed)
echo ""
echo "[1/3] Syncing Capacitor assets..."
npx cap sync android

# Step 2: Build Android
echo ""
echo "[2/3] Building Android..."
cd android

if [ "$BUILD_TYPE" = "release" ]; then
  echo "Building Release APK..."
  ./gradlew assembleRelease
  OUTPUT_PATH="app/build/outputs/apk/release/app-release-unsigned.apk"
  echo ""
  echo "[3/3] APK built successfully!"
  echo "Output: android/$OUTPUT_PATH"
  echo ""
  echo "Next steps to sign the APK:"
  echo "  1. Generate keystore (if not done):"
  echo "     keytool -genkey -v -keystore jouwdriver.keystore -alias jouwdriver -keyalg RSA -keysize 2048 -validity 10000"
  echo "  2. Sign: jarsigner -keystore jouwdriver.keystore $OUTPUT_PATH jouwdriver"
  echo "  3. Align: zipalign -v 4 $OUTPUT_PATH ../jouwdriver-release.apk"

elif [ "$BUILD_TYPE" = "aab" ]; then
  echo "Building Release AAB (Google Play)..."
  ./gradlew bundleRelease
  OUTPUT_PATH="app/build/outputs/bundle/release/app-release.aab"
  echo ""
  echo "[3/3] AAB built successfully!"
  echo "Output: android/$OUTPUT_PATH"
  echo "Upload this file to Google Play Console."

else
  echo "Building Debug APK..."
  ./gradlew assembleDebug
  OUTPUT_PATH="app/build/outputs/apk/debug/app-debug.apk"
  echo ""
  echo "[3/3] Debug APK built successfully!"
  echo "Output: android/$OUTPUT_PATH"
  echo ""
  echo "Install on connected device:"
  echo "  adb install android/$OUTPUT_PATH"
fi

cd ..
echo ""
echo "========================================"
echo "  Build Complete!"
echo "========================================"
